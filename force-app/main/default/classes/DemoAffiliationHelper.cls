/**
 * Separate class for ProviderAffiliation operations.
 * Schema.getGlobalDescribe() does not return 'provideraffiliation' when called
 * from DemoAccountProviderController (public with sharing). This standalone
 * class resolves that visibility issue.
 *
 * Affiliations are created dynamically: each HCP doctor is affiliated with
 * every HCO (hospital/clinic/medical center) in the same city plus one
 * neighboring city in the same country. This produces realistic many-to-many
 * relationships across territories.
 */
public without sharing class DemoAffiliationHelper {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';

    public static Integer createAffiliations(Map<String, Id> doctorNameToId, Map<String, Id> orgNameToId) {
        return createAffiliations(doctorNameToId, orgNameToId, new Map<String, String>());
    }

    public static Integer createAffiliations(Map<String, Id> doctorNameToId, Map<String, Id> orgNameToId, Map<String, String> cityTerrMap) {
        Schema.SObjectType afflType = Schema.getGlobalDescribe().get('provideraffiliation');
        if (afflType == null) return 0;

        Map<String, Schema.SObjectField> afflFields = afflType.getDescribe().fields.getMap();

        // Build territory name -> first assigned userId
        Map<String, Id> terrNameToUser = new Map<String, Id>();
        if (!cityTerrMap.isEmpty()) {
            Set<String> terrDevNames = new Set<String>(cityTerrMap.values());
            Map<Id, String> terrIdToName = new Map<Id, String>();
            for (Territory2 t : [SELECT Id, DeveloperName FROM Territory2
                                 WHERE DeveloperName IN :terrDevNames
                                   AND Territory2Model.State = 'Active']) {
                terrIdToName.put(t.Id, t.DeveloperName);
            }
            for (UserTerritory2Association uta : [SELECT UserId, Territory2Id
                                                  FROM UserTerritory2Association
                                                  WHERE Territory2Id IN :terrIdToName.keySet()]) {
                String devName = terrIdToName.get(uta.Territory2Id);
                if (!terrNameToUser.containsKey(devName)) {
                    terrNameToUser.put(devName, uta.UserId);
                }
            }
        }

        // Query all demo accounts to get city info
        Set<Id> allIds = new Set<Id>();
        allIds.addAll(doctorNameToId.values());
        allIds.addAll(orgNameToId.values());

        Map<Id, Account> acctMap = new Map<Id, Account>([
            SELECT Id, Name, BillingCity, BillingStateCode, BillingCountryCode,
                   IsPersonAccount, Type
            FROM Account
            WHERE Id IN :allIds
        ]);

        // Build city key -> list of org IDs (hospitals/clinics only)
        Map<String, List<Id>> cityToOrgs = new Map<String, List<Id>>();
        // country code -> list of city keys (for cross-city affiliations)
        Map<String, List<String>> countryToCityKeys = new Map<String, List<String>>();
        for (Id orgId : orgNameToId.values()) {
            Account org = acctMap.get(orgId);
            if (org == null || String.isBlank(org.BillingCity)) continue;
            String orgType = org.Type != null ? org.Type.toLowerCase() : '';
            if (!orgType.contains('hospital') && !orgType.contains('clinic') &&
                !orgType.contains('medical center') && !orgType.contains('health system')) continue;
            String cityKey = buildCityKey(org.BillingCity, org.BillingStateCode, org.BillingCountryCode);
            if (!cityToOrgs.containsKey(cityKey)) {
                cityToOrgs.put(cityKey, new List<Id>());
                String cc = String.isNotBlank(org.BillingCountryCode) ? org.BillingCountryCode : 'XX';
                if (!countryToCityKeys.containsKey(cc)) {
                    countryToCityKeys.put(cc, new List<String>());
                }
                countryToCityKeys.get(cc).add(cityKey);
            }
            cityToOrgs.get(cityKey).add(orgId);
        }

        // For each doctor, affiliate with orgs in same city + one neighboring city
        List<SObject> affls = new List<SObject>();
        Set<String> dedupeKeys = new Set<String>();
        for (Id doctorId : doctorNameToId.values()) {
            Account doc = acctMap.get(doctorId);
            if (doc == null || String.isBlank(doc.BillingCity)) continue;

            String cityKey = buildCityKey(doc.BillingCity, doc.BillingStateCode, doc.BillingCountryCode);
            String cc = String.isNotBlank(doc.BillingCountryCode) ? doc.BillingCountryCode : 'XX';

            // Collect org IDs: same city + one neighboring city in the same country
            List<Id> targetOrgs = new List<Id>();
            if (cityToOrgs.containsKey(cityKey)) {
                targetOrgs.addAll(cityToOrgs.get(cityKey));
            }
            List<String> siblingKeys = countryToCityKeys.get(cc);
            if (siblingKeys != null) {
                Integer idx = siblingKeys.indexOf(cityKey);
                if (idx >= 0) {
                    String neighborKey = siblingKeys[Math.mod(idx + 1, siblingKeys.size())];
                    if (neighborKey != cityKey && cityToOrgs.containsKey(neighborKey)) {
                        targetOrgs.addAll(cityToOrgs.get(neighborKey));
                    }
                }
            }
            if (targetOrgs.isEmpty()) continue;

            // Resolve territory user for this doctor's city (keys are 'CC:City')
            Id ownerId = null;
            String mapKey = (String.isNotBlank(doc.BillingCountryCode) ? doc.BillingCountryCode : '') + ':' + doc.BillingCity;
            String terrDevName = cityTerrMap.get(mapKey);
            if (terrDevName != null) {
                ownerId = terrNameToUser.get(terrDevName);
            }

            Boolean isFirst = true;
            for (Id orgId : targetOrgs) {
                String dedupeKey = doctorId + '-' + orgId;
                if (dedupeKeys.contains(dedupeKey)) continue;
                dedupeKeys.add(dedupeKey);

                SObject affl = afflType.newSObject();
                affl.put('AccountId', doctorId);
                affl.put('RelatedAccountId', orgId);
                if (ownerId != null) affl.put('OwnerId', ownerId);
                if (afflFields.containsKey('role')) affl.put('Role', 'Affiliated Practice-Doctor-AAR');
                if (afflFields.containsKey('isprimary')) affl.put('IsPrimary', isFirst);
                if (afflFields.containsKey('isactive')) affl.put('IsActive', true);
                if (afflFields.containsKey('isinstitutiondoctoraffl')) affl.put('IsInstitutionDoctorAffl', true);
                if (afflFields.containsKey('isautogenerated')) affl.put('IsAutoGenerated', false);
                if (afflFields.containsKey('sourcesystemname')) affl.put('SourceSystemName', DEMO_TAG);
                affls.add(affl);
                isFirst = false;
            }
        }

        Integer success = 0;
        if (!affls.isEmpty()) {
            Database.SaveResult[] results = Database.insert(affls, false);
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) success++;
            }
        }
        return success;
    }

    private static String buildCityKey(String city, String stateCode, String countryCode) {
        String key = city.toLowerCase().trim();
        if (String.isNotBlank(stateCode)) key += '|' + stateCode.toLowerCase();
        if (String.isNotBlank(countryCode)) key += '|' + countryCode.toLowerCase();
        return key;
    }

    public static Integer deleteAffiliations() {
        Integer deleted = 0;
        String soql = 'SELECT Id FROM ProviderAffiliation WHERE SourceSystemName = \'' + String.escapeSingleQuotes(DEMO_TAG) + '\'';
        List<SObject> recs = Database.query(soql);
        if (!recs.isEmpty()) {
            Database.DeleteResult[] dr = Database.delete(recs, false);
            for (Database.DeleteResult r : dr) {
                if (r.isSuccess()) deleted++;
            }
        }
        return deleted;
    }

    public static Integer countAffiliations() {
        String soql = 'SELECT COUNT() FROM ProviderAffiliation WHERE SourceSystemName = \'' + String.escapeSingleQuotes(DEMO_TAG) + '\'';
        return Database.countQuery(soql);
    }
}
