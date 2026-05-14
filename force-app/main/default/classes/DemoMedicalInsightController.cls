public without sharing class DemoMedicalInsightController {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';
    private static final String NAME_SUFFIX = ' #AFLSCE';

    private static final String[] BRAND_NAMES = new String[]{ 'Immunexis', 'Immunonco' };

    @AuraEnabled(cacheable=true)
    public static String getStatus() {
        try {
            List<String> parts = new List<String>();
            if (!objectExists('MedicalInsight')) return 'MedicalInsight not available in this org.';

            String namePattern = '%' + NAME_SUFFIX;
            Set<Id> demoInsightIds = new Set<Id>();
            for (SObject mi : Database.query(
                'SELECT Id FROM MedicalInsight WHERE Name LIKE :namePattern'
            )) {
                demoInsightIds.add(mi.Id);
            }
            parts.add('Insights: ' + demoInsightIds.size());

            if (objectExists('MedicalInsightAccount') && !demoInsightIds.isEmpty()) {
                Integer miaCount = Database.countQuery(
                    'SELECT COUNT() FROM MedicalInsightAccount WHERE MedicalInsightId IN :demoInsightIds'
                );
                parts.add('Account Links: ' + miaCount);
            }

            if (objectExists('MedicalInsightProduct') && !demoInsightIds.isEmpty()) {
                Integer mipCount = Database.countQuery(
                    'SELECT COUNT() FROM MedicalInsightProduct WHERE MedicalInsightId IN :demoInsightIds'
                );
                parts.add('Product Links: ' + mipCount);
            }

            return String.join(parts, ', ');
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTerritories() {
        try {
            List<Territory2> allTerrs = [
                SELECT Id, Name, ParentTerritory2Id FROM Territory2
                WHERE Territory2Model.State = 'Active'
            ];
            Set<Id> parentIds = new Set<Id>();
            for (Territory2 t : allTerrs) {
                if (t.ParentTerritory2Id != null) parentIds.add(t.ParentTerritory2Id);
            }
            Set<Id> leafIds = new Set<Id>();
            Map<Id, String> leafNames = new Map<Id, String>();
            for (Territory2 t : allTerrs) {
                if (!parentIds.contains(t.Id)) {
                    leafIds.add(t.Id);
                    leafNames.put(t.Id, t.Name);
                }
            }

            Map<Id, Id> terrToOwner = new Map<Id, Id>();
            for (UserTerritory2Association uta : [
                SELECT Territory2Id, UserId FROM UserTerritory2Association
                WHERE Territory2Id IN :leafIds ORDER BY Territory2Id
            ]) {
                if (!terrToOwner.containsKey(uta.Territory2Id)) {
                    terrToOwner.put(uta.Territory2Id, uta.UserId);
                }
            }

            Set<Id> demoHcpIds = new Set<Id>();
            String demoTag = DEMO_TAG;
            for (Account a : [SELECT Id FROM Account
                    WHERE Site = :demoTag AND IsPersonAccount = true]) {
                demoHcpIds.add(a.Id);
            }

            Set<Id> terrsWithHcps = new Set<Id>();
            for (ObjectTerritory2Association ota : [
                SELECT Territory2Id FROM ObjectTerritory2Association
                WHERE Territory2Id IN :leafIds AND ObjectId IN :demoHcpIds
            ]) {
                terrsWithHcps.add(ota.Territory2Id);
            }

            List<Map<String, String>> result = new List<Map<String, String>>();
            List<String> sortedNames = new List<String>(leafNames.values());
            sortedNames.sort();
            Map<String, Id> nameToId = new Map<String, Id>();
            for (Id tId : leafNames.keySet()) nameToId.put(leafNames.get(tId), tId);

            for (String tName : sortedNames) {
                Id tId = nameToId.get(tName);
                if (!terrToOwner.containsKey(tId)) continue;
                if (!terrsWithHcps.contains(tId)) continue;
                result.add(new Map<String, String>{
                    'label' => tName,
                    'value' => tId
                });
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error loading territories: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String createInsightsForTerritory(Id territoryId) {
        List<String> details = new List<String>();
        List<String> errors = new List<String>();

        try {
            Territory2 terr = [SELECT Id, Name FROM Territory2 WHERE Id = :territoryId LIMIT 1];
            String countryCode = extractCountryCode(terr.Name);
            details.add('HEADER:' + terr.Name + ' (' + countryCode + ')');

            Map<String, List<Id>> countryBrands = loadBrandsByCountry();
            List<Id> brandIds = countryBrands.get(countryCode);
            if (brandIds == null || brandIds.isEmpty()) {
                return JSON.serialize(new Map<String, Object>{
                    'summary' => terr.Name + ': no brands found for ' + countryCode,
                    'details' => details, 'errors' => errors,
                    'insightCount' => 0, 'accountLinkCount' => 0, 'productLinkCount' => 0
                });
            }

            Map<Id, String> brandIdToName = new Map<Id, String>();
            for (Id bId : brandIds) brandIdToName.put(bId, getBrandNameForId(bId));

            Id ownerId;
            List<UserTerritory2Association> utas = [
                SELECT UserId FROM UserTerritory2Association
                WHERE Territory2Id = :territoryId ORDER BY Territory2Id LIMIT 1
            ];
            ownerId = utas.isEmpty() ? UserInfo.getUserId() : utas[0].UserId;

            String demoTag = DEMO_TAG;
            Map<Id, String> hcpNames = new Map<Id, String>();
            for (Account a : [
                SELECT Id, Name FROM Account
                WHERE Site = :demoTag AND IsPersonAccount = true AND BillingCountryCode = :countryCode
            ]) {
                hcpNames.put(a.Id, a.Name);
            }
            Set<Id> hcpIds = hcpNames.keySet();

            Set<Id> leafSet = new Set<Id>{ territoryId };
            List<Id> terrHcps = new List<Id>();
            for (ObjectTerritory2Association ota : [
                SELECT ObjectId FROM ObjectTerritory2Association
                WHERE Territory2Id IN :leafSet AND ObjectId IN :hcpIds
            ]) {
                terrHcps.add(ota.ObjectId);
            }
            details.add('SUCCESS:Found ' + terrHcps.size() + ' HCPs');

            if (terrHcps.isEmpty()) {
                return JSON.serialize(new Map<String, Object>{
                    'summary' => terr.Name + ': no HCPs', 'details' => details, 'errors' => errors,
                    'insightCount' => 0, 'accountLinkCount' => 0, 'productLinkCount' => 0
                });
            }

            Map<String, List<Map<String, String>>> localInsights = DemoMedicalInsightLocale.getInsights(countryCode);

            Schema.SObjectType miType = Schema.getGlobalDescribe().get('MedicalInsight');
            List<SObject> insightRecords = new List<SObject>();
            List<InsightContext> contexts = new List<InsightContext>();
            Integer seed = Date.today().dayOfYear() * 7 + terr.Name.hashCode();
            Integer seqNum = 0;

            for (Id hcpId : terrHcps) {
                for (Id brandId : brandIds) {
                    String brandName = brandIdToName.get(brandId);
                    List<Map<String, String>> templates = localInsights.get(brandName);
                    if (templates == null || templates.isEmpty()) continue;

                    Integer numInsights = 1 + pseudoRandom(seed + seqNum, 2);
                    for (Integer i = 0; i < numInsights; i++) {
                        Integer templateIdx = pseudoRandom(seed + seqNum + i * 31, templates.size());
                        Map<String, String> tmpl = templates[templateIdx];
                        seqNum++;

                        SObject mi = miType.newSObject();
                        String baseName = tmpl.get('Name');
                        Integer maxBase = 80 - NAME_SUFFIX.length();
                        if (baseName.length() > maxBase) baseName = baseName.substring(0, maxBase);
                        mi.put('Name', baseName + NAME_SUFFIX);
                        mi.put('Content', tmpl.get('Content'));
                        mi.put('SourceType', 'Visit');
                        mi.put('OwnerId', ownerId);
                        insightRecords.add(mi);
                        contexts.add(new InsightContext(hcpId, brandId, countryCode, territoryId));
                    }
                }
            }
            if (countryCode == 'US') {
                for (Id hcpId : terrHcps) {
                    for (Id brandId : brandIds) {
                        String brandName = brandIdToName.get(brandId);
                        String hcpName = hcpNames.get(hcpId);
                        if (hcpName == null) hcpName = 'HCP';
                        seqNum++;
                        SObject mi = miType.newSObject();
                        mi.put('Name', buildRxName(brandName, hcpName));
                        mi.put('Content', buildRxContent(brandName, hcpName, seed + seqNum));
                        mi.put('SourceType', 'Account');
                        mi.put('OwnerId', ownerId);
                        insightRecords.add(mi);
                        contexts.add(new InsightContext(hcpId, brandId, countryCode, territoryId));
                    }
                }
            }

            details.add('SUCCESS:Built ' + insightRecords.size() + ' insights');

            Database.SaveResult[] miResults = Database.insert(insightRecords, false);
            Integer miSuccess = 0;
            for (Database.SaveResult sr : miResults) {
                if (sr.isSuccess()) miSuccess++;
                else if (errors.size() < 10) errors.add('Insight: ' + sr.getErrors()[0].getMessage());
            }

            Schema.SObjectType miaType = Schema.getGlobalDescribe().get('MedicalInsightAccount');
            List<SObject> accountLinks = new List<SObject>();
            for (Integer i = 0; i < miResults.size(); i++) {
                if (!miResults[i].isSuccess()) continue;
                SObject mia = miaType.newSObject();
                mia.put('MedicalInsightId', miResults[i].getId());
                mia.put('AccountId', contexts[i].accountId);
                accountLinks.add(mia);
            }
            Database.SaveResult[] miaResults = Database.insert(accountLinks, false);
            Integer miaSuccess = 0;
            for (Database.SaveResult sr : miaResults) {
                if (sr.isSuccess()) miaSuccess++;
                else if (errors.size() < 10) errors.add('Account Link: ' + sr.getErrors()[0].getMessage());
            }

            Schema.SObjectType mipType = Schema.getGlobalDescribe().get('MedicalInsightProduct');
            List<SObject> productLinks = new List<SObject>();
            for (Integer i = 0; i < miResults.size(); i++) {
                if (!miResults[i].isSuccess()) continue;
                SObject mip = mipType.newSObject();
                mip.put('MedicalInsightId', miResults[i].getId());
                mip.put('ProductId', contexts[i].brandId);
                productLinks.add(mip);
            }
            Database.SaveResult[] mipResults = Database.insert(productLinks, false);
            Integer mipSuccess = 0;
            for (Database.SaveResult sr : mipResults) {
                if (sr.isSuccess()) mipSuccess++;
                else if (errors.size() < 10) errors.add('Product Link: ' + sr.getErrors()[0].getMessage());
            }

            shareInsightsWithTerritoryGroups(insightRecords, miResults, contexts, errors);

            details.add('SUCCESS:' + miSuccess + ' insights, ' + miaSuccess + ' account links, ' + mipSuccess + ' product links');

            return JSON.serialize(new Map<String, Object>{
                'summary' => terr.Name + ': ' + miSuccess + ' insights',
                'details' => details, 'errors' => errors,
                'insightCount' => miSuccess, 'accountLinkCount' => miaSuccess, 'productLinkCount' => mipSuccess
            });
        } catch (Exception e) {
            throw new AuraHandledException(territoryId + ' error: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }

    @AuraEnabled
    public static String deleteMedicalInsights() {
        try {
            List<String> deleted = new List<String>();
            String namePattern = '%' + NAME_SUFFIX;

            List<SObject> insights = Database.query(
                'SELECT Id FROM MedicalInsight WHERE Name LIKE :namePattern LIMIT 10000'
            );
            if (insights.isEmpty()) return 'No demo medical insights to delete.';

            Set<Id> insightIds = new Set<Id>();
            for (SObject mi : insights) insightIds.add(mi.Id);

            if (objectExists('MedicalInsightProduct')) {
                List<SObject> mips = Database.query(
                    'SELECT Id FROM MedicalInsightProduct WHERE MedicalInsightId IN :insightIds LIMIT 10000'
                );
                if (!mips.isEmpty()) {
                    Database.delete(mips, false);
                    deleted.add(mips.size() + ' product links');
                }
            }

            if (objectExists('MedicalInsightAccount')) {
                List<SObject> mias = Database.query(
                    'SELECT Id FROM MedicalInsightAccount WHERE MedicalInsightId IN :insightIds LIMIT 10000'
                );
                if (!mias.isEmpty()) {
                    Database.delete(mias, false);
                    deleted.add(mias.size() + ' account links');
                }
            }

            Database.delete(insights, false);
            deleted.add(insights.size() + ' insights');

            return 'Deleted ' + String.join(deleted, ', ') + '.';
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String deleteMedicalInsightsForTerritory(Id territoryId) {
        try {
            List<UserTerritory2Association> utas = [
                SELECT UserId FROM UserTerritory2Association
                WHERE Territory2Id = :territoryId ORDER BY Territory2Id LIMIT 1
            ];
            if (utas.isEmpty()) return 'No rep assigned to this territory.';
            Id repId = utas[0].UserId;

            List<String> deleted = new List<String>();
            String namePattern = '%' + NAME_SUFFIX;

            List<SObject> insights = Database.query(
                'SELECT Id FROM MedicalInsight WHERE Name LIKE :namePattern AND OwnerId = :repId LIMIT 10000'
            );
            if (insights.isEmpty()) return 'No demo medical insights for this territory.';

            Set<Id> insightIds = new Set<Id>();
            for (SObject mi : insights) insightIds.add(mi.Id);

            if (objectExists('MedicalInsightProduct')) {
                List<SObject> mips = Database.query(
                    'SELECT Id FROM MedicalInsightProduct WHERE MedicalInsightId IN :insightIds LIMIT 10000'
                );
                if (!mips.isEmpty()) {
                    Database.delete(mips, false);
                    deleted.add(mips.size() + ' product links');
                }
            }

            if (objectExists('MedicalInsightAccount')) {
                List<SObject> mias = Database.query(
                    'SELECT Id FROM MedicalInsightAccount WHERE MedicalInsightId IN :insightIds LIMIT 10000'
                );
                if (!mias.isEmpty()) {
                    Database.delete(mias, false);
                    deleted.add(mias.size() + ' account links');
                }
            }

            Database.delete(insights, false);
            deleted.add(insights.size() + ' insights');

            return 'Deleted ' + String.join(deleted, ', ') + '.';
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    private static void shareInsightsWithTerritoryGroups(
        List<SObject> insightRecords, Database.SaveResult[] miResults,
        List<InsightContext> contexts, List<String> errors
    ) {
        Set<Id> allTerrIds = new Set<Id>();
        for (InsightContext ctx : contexts) allTerrIds.add(ctx.territoryId);

        Map<Id, Id> terrToGroup = new Map<Id, Id>();
        for (Group g : [SELECT Id, RelatedId FROM Group WHERE Type = 'Territory' AND RelatedId IN :allTerrIds]) {
            terrToGroup.put(g.RelatedId, g.Id);
        }

        Schema.SObjectType shareType = Schema.getGlobalDescribe().get('MedicalInsightShare');
        if (shareType == null) return;

        List<SObject> shares = new List<SObject>();
        for (Integer i = 0; i < miResults.size(); i++) {
            if (!miResults[i].isSuccess()) continue;
            Id groupId = terrToGroup.get(contexts[i].territoryId);
            if (groupId == null) continue;
            SObject s = shareType.newSObject();
            s.put('ParentId', miResults[i].getId());
            s.put('UserOrGroupId', groupId);
            s.put('AccessLevel', 'Edit');
            s.put('RowCause', 'Manual');
            shares.add(s);
        }

        if (!shares.isEmpty()) {
            Database.SaveResult[] shareResults = Database.insert(shares, false);
            for (Database.SaveResult sr : shareResults) {
                if (!sr.isSuccess() && errors.size() < 10) errors.add('Share: ' + sr.getErrors()[0].getMessage());
            }
        }
    }

    private static Map<String, List<Id>> loadBrandsByCountry() {
        Map<String, List<Id>> countryToBrandIds = new Map<String, List<Id>>();
        List<SObject> brands = Database.query(
            'SELECT Id, Name FROM LifeSciMarketableProduct ' +
            'WHERE Type = \'Brand\' AND IsActive = true ORDER BY Name');
        for (SObject brand : brands) {
            String name = (String) brand.get('Name');
            for (String baseName : BRAND_NAMES) {
                String countryPattern = baseName + ' (';
                if (name.startsWith(countryPattern) && name.endsWith(')')) {
                    String cc = name.substring(countryPattern.length(), name.length() - 1);
                    if (!countryToBrandIds.containsKey(cc)) {
                        countryToBrandIds.put(cc, new List<Id>());
                    }
                    countryToBrandIds.get(cc).add(brand.Id);
                }
            }
        }
        return countryToBrandIds;
    }

    private static String extractCountryCode(String territoryName) {
        if (String.isBlank(territoryName)) return null;
        Integer dash = territoryName.indexOf('-');
        if (dash > 0) return territoryName.substring(0, dash);
        return null;
    }

    private static String getBrandNameForId(Id brandId) {
        SObject brand = Database.query(
            'SELECT Name FROM LifeSciMarketableProduct WHERE Id = :brandId LIMIT 1'
        )[0];
        String name = (String) brand.get('Name');
        for (String baseName : BRAND_NAMES) {
            if (name.startsWith(baseName)) return baseName;
        }
        return name;
    }

    private static final String[] RX_BEHAVIORS = new String[]{
        'Does not prescribe', 'Started prescribing', 'Regular prescriber', 'Brand advocate'
    };
    private static final String[] RX_TRENDS = new String[]{ 'trending up', 'trending down', 'flat' };

    private static String buildRxName(String brandName, String hcpName) {
        String base = hcpName + ' ' + brandName + ' Rx profile';
        Integer maxBase = 80 - NAME_SUFFIX.length();
        if (base.length() > maxBase) base = base.substring(0, maxBase);
        return base + NAME_SUFFIX;
    }

    private static String buildRxContent(String brandName, String hcpName, Integer seed) {
        Integer behaviorIdx = pseudoRandom(seed, RX_BEHAVIORS.size());
        String behavior = RX_BEHAVIORS[behaviorIdx];

        Boolean isOnco = brandName == 'Immunonco';
        Integer nrx;
        Integer trx;
        String trend;
        if (behaviorIdx == 0) {
            nrx = 0;
            trx = 0;
            trend = 'flat';
        } else if (behaviorIdx == 1) {
            nrx = isOnco ? 5 + pseudoRandom(seed + 1, 6) : 10 + pseudoRandom(seed + 1, 11);
            trx = nrx + 2 + pseudoRandom(seed + 2, 5);
            trend = 'trending up';
        } else if (behaviorIdx == 2) {
            nrx = isOnco ? 15 + pseudoRandom(seed + 1, 16) : 30 + pseudoRandom(seed + 1, 31);
            trx = nrx + 5 + pseudoRandom(seed + 2, 16);
            Integer trendIdx = pseudoRandom(seed + 3, RX_TRENDS.size());
            trend = RX_TRENDS[trendIdx];
        } else {
            nrx = isOnco ? 25 + pseudoRandom(seed + 1, 16) : 50 + pseudoRandom(seed + 1, 31);
            trx = nrx + 10 + pseudoRandom(seed + 2, 21);
            Integer trendIdx = pseudoRandom(seed + 3, 2);
            trend = trendIdx == 0 ? 'trending up' : 'flat';
        }

        return hcpName + ' — ' + brandName + ' prescribing status: ' + behavior + '. '
            + 'Monthly Rx: NRx ' + nrx + ', TRx ' + trx + ' (' + trend + '). '
            + (behaviorIdx == 0
                ? 'No current prescriptions for ' + brandName + '. Opportunity to educate on clinical data and patient outcomes.'
              : behaviorIdx == 1
                ? 'Recently started writing ' + brandName + '. Early adoption phase — reinforce efficacy messaging and provide patient support materials.'
              : behaviorIdx == 2
                ? 'Consistent ' + brandName + ' prescriber. Maintain relationship, share latest real-world evidence, and explore formulary expansion opportunities.'
              : 'Strong ' + brandName + ' advocate. Leverage for peer-to-peer education, speaker bureau, and advisory board participation.');
    }

    private static Integer pseudoRandom(Integer seed, Integer maxVal) {
        if (maxVal <= 0) return 0;
        Long hash = Math.abs(((Long) seed * 6364136223846793005L + 1442695040888963407L));
        return (Integer) Math.mod(hash, maxVal);
    }

    private static Boolean objectExists(String objectName) {
        return Schema.getGlobalDescribe().containsKey(objectName);
    }

    private class InsightContext {
        public Id accountId;
        public Id brandId;
        public String countryCode;
        public Id territoryId;

        public InsightContext(Id accountId, Id brandId, String countryCode, Id territoryId) {
            this.accountId = accountId;
            this.brandId = brandId;
            this.countryCode = countryCode;
            this.territoryId = territoryId;
        }
    }
}
