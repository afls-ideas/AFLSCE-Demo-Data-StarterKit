public without sharing class DemoProductAlignmentController {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';

    private static final List<String> COUNTRY_CODES = new List<String>{
        'US', 'GB', 'FR', 'DE', 'IT', 'ES', 'JP', 'KR', 'BR', 'MX', 'AR'
    };

    private static final Map<String, String> COUNTRY_TERRITORY = new Map<String, String>{
        'US' => 'US_COUNTRY', 'GB' => 'GB_COUNTRY', 'FR' => 'FR_COUNTRY',
        'DE' => 'DE_COUNTRY', 'IT' => 'IT_COUNTRY', 'ES' => 'ES_COUNTRY',
        'JP' => 'JP_COUNTRY', 'KR' => 'KR_COUNTRY', 'BR' => 'BR_COUNTRY',
        'MX' => 'MX_COUNTRY', 'AR' => 'AR_COUNTRY'
    };

    // LifeSciMarketableProduct is not visible via Schema.getGlobalDescribe() or Type.forName()
    // from compiled classes. We construct SObjects via JSON deserialization instead.
    private static SObject newProduct(Map<String, Object> fields) {
        fields.put('attributes', new Map<String, Object>{ 'type' => 'LifeSciMarketableProduct' });
        return (SObject) JSON.deserialize(JSON.serialize(fields), SObject.class);
    }

    private static SObject newPTA(Map<String, Object> fields) {
        fields.put('attributes', new Map<String, Object>{ 'type' => 'ProductTerritoryAvailability' });
        return (SObject) JSON.deserialize(JSON.serialize(fields), SObject.class);
    }

    private static Boolean objectExists(String objectName) {
        try {
            Database.query('SELECT Id FROM ' + objectName + ' LIMIT 0');
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getStatus() {
        try {
            List<String> parts = new List<String>();
            String escapedTag = String.escapeSingleQuotes(DEMO_TAG);

            if (objectExists('LifeSciMarketableProduct')) {
                Integer cnt = Database.countQuery(
                    'SELECT COUNT() FROM LifeSciMarketableProduct WHERE SourceSystem = \'' + escapedTag + '\''
                );
                parts.add('Products: ' + cnt);
            }

            if (objectExists('ProductTerritoryAvailability')) {
                Set<Id> taggedProductIds = getTaggedProductIds();
                if (!taggedProductIds.isEmpty()) {
                    List<SObject> ptas = Database.query(
                        'SELECT Id FROM ProductTerritoryAvailability WHERE ProductId IN :taggedProductIds'
                    );
                    parts.add('PTAs: ' + ptas.size());
                } else {
                    parts.add('PTAs: 0');
                }
            }

            if (objectExists('ProductTerrDtlAvailability')) {
                Set<Id> taggedProductIds = getTaggedProductIds();
                if (!taggedProductIds.isEmpty()) {
                    List<SObject> ptdas = Database.query(
                        'SELECT Id FROM ProductTerrDtlAvailability WHERE ProductId IN :taggedProductIds'
                    );
                    parts.add('PTDAs: ' + ptdas.size());
                } else {
                    parts.add('PTDAs: 0');
                }
            }

            return parts.isEmpty() ? 'LifeSciMarketableProduct not available in this org.' : String.join(parts, ', ');
        } catch (Exception e) {
            throw new AuraHandledException('Error getting status: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String createProductsAndAlign() {
        try {
            if (!objectExists('LifeSciMarketableProduct')) {
                throw new AuraHandledException('LifeSciMarketableProduct is not available in this org.');
            }
            String escapedTag = String.escapeSingleQuotes(DEMO_TAG);
            List<String> errors = new List<String>();

            // 1. Find or create parent hierarchy nodes
            Map<String, Id> existingByName = new Map<String, Id>();
            for (SObject mp : Database.query(
                'SELECT Id, Name, Type FROM LifeSciMarketableProduct'
            )) {
                existingByName.put((String) mp.get('Name'), mp.Id);
            }

            Id autoimmuneMktId = existingByName.get('Autoimmune Disorders');
            Id oncologyMktId = existingByName.get('Oncology Market');
            Id immunexisBrandId = existingByName.get('Immunexis');

            if (autoimmuneMktId == null) {
                SObject mkt = newProduct(new Map<String, Object>{
                    'Name' => 'Autoimmune Disorders',
                    'Type' => 'Market',
                    'IsActive' => true,
                    'SourceSystem' => DEMO_TAG
                });
                Database.SaveResult sr = Database.insert(mkt, false);
                if (sr.isSuccess()) autoimmuneMktId = sr.getId();
                else errors.add('Autoimmune Disorders Market: ' + sr.getErrors()[0].getMessage());
            }

            if (oncologyMktId == null) {
                SObject mkt = newProduct(new Map<String, Object>{
                    'Name' => 'Oncology Market',
                    'Type' => 'Market',
                    'IsActive' => true,
                    'SourceSystem' => DEMO_TAG
                });
                Database.SaveResult sr = Database.insert(mkt, false);
                if (sr.isSuccess()) oncologyMktId = sr.getId();
                else errors.add('Oncology Market: ' + sr.getErrors()[0].getMessage());
            }

            if (immunexisBrandId == null && autoimmuneMktId != null) {
                SObject brand = newProduct(new Map<String, Object>{
                    'Name' => 'Immunexis',
                    'Type' => 'Brand',
                    'ParentProductId' => autoimmuneMktId,
                    'IsActive' => true,
                    'SourceSystem' => DEMO_TAG
                });
                Database.SaveResult sr = Database.insert(brand, false);
                if (sr.isSuccess()) immunexisBrandId = sr.getId();
                else errors.add('Immunexis Brand: ' + sr.getErrors()[0].getMessage());
            }

            Id immunoncoBrandId = existingByName.get('Immunonco');
            if (immunoncoBrandId == null && oncologyMktId != null) {
                SObject brand = newProduct(new Map<String, Object>{
                    'Name' => 'Immunonco',
                    'Type' => 'Brand',
                    'ParentProductId' => oncologyMktId,
                    'IsActive' => true,
                    'SourceSystem' => DEMO_TAG
                });
                Database.SaveResult sr = Database.insert(brand, false);
                if (sr.isSuccess()) immunoncoBrandId = sr.getId();
                else errors.add('Immunonco Brand: ' + sr.getErrors()[0].getMessage());
            }

            // 2. Check existing per-country products to avoid duplicates
            Set<String> existingTaggedNames = new Set<String>();
            for (SObject mp : Database.query(
                'SELECT Name FROM LifeSciMarketableProduct WHERE SourceSystem = \'' + escapedTag + '\''
            )) {
                existingTaggedNames.add((String) mp.get('Name'));
            }

            // 3. Create per-country Brand products
            List<SObject> countryProducts = new List<SObject>();
            List<String> countryProductKeys = new List<String>();

            for (String cc : COUNTRY_CODES) {
                String ixName = 'Immunexis (' + cc + ')';
                if (!existingTaggedNames.contains(ixName) && immunexisBrandId != null) {
                    countryProducts.add(newProduct(new Map<String, Object>{
                        'Name' => ixName,
                        'Type' => 'Brand',
                        'ParentProductId' => autoimmuneMktId,
                        'ParentBrandProductId' => immunexisBrandId,
                        'IsActive' => true,
                        'SourceSystem' => DEMO_TAG
                    }));
                    countryProductKeys.add('Immunexis:' + cc);
                }

                String ionName = 'Immunonco (' + cc + ')';
                if (!existingTaggedNames.contains(ionName) && immunoncoBrandId != null) {
                    countryProducts.add(newProduct(new Map<String, Object>{
                        'Name' => ionName,
                        'Type' => 'Brand',
                        'ParentProductId' => oncologyMktId,
                        'ParentBrandProductId' => immunoncoBrandId,
                        'IsActive' => true,
                        'SourceSystem' => DEMO_TAG
                    }));
                    countryProductKeys.add('Immunonco:' + cc);
                }
            }

            Integer productSuccess = 0;
            Map<String, Id> countryProductIdMap = new Map<String, Id>();
            if (!countryProducts.isEmpty()) {
                Database.SaveResult[] results = Database.insert(countryProducts, false);
                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        productSuccess++;
                        countryProductIdMap.put(countryProductKeys[i], results[i].getId());
                    } else if (errors.size() < 5) {
                        errors.add(countryProductKeys[i] + ': ' + results[i].getErrors()[0].getMessage());
                    }
                }
            }

            // Also include already-existing tagged products for PTA creation
            for (SObject mp : Database.query(
                'SELECT Id, Name FROM LifeSciMarketableProduct WHERE SourceSystem = \'' + escapedTag + '\' AND Name LIKE \'%(__)%\''
            )) {
                String name = (String) mp.get('Name');
                Integer openParen = name.lastIndexOf('(');
                Integer closeParen = name.lastIndexOf(')');
                if (openParen > 0 && closeParen > openParen) {
                    String drug = name.substring(0, openParen).trim();
                    String cc = name.substring(openParen + 1, closeParen);
                    String key = drug + ':' + cc;
                    if (!countryProductIdMap.containsKey(key)) {
                        countryProductIdMap.put(key, mp.Id);
                    }
                }
            }

            // 4. Create PTAs
            if (!objectExists('ProductTerritoryAvailability')) {
                String result = 'Products: ' + productSuccess + '. ProductTerritoryAvailability not available.';
                if (!errors.isEmpty()) result += ' | Errors: ' + String.join(errors, '; ');
                return result;
            }

            Map<String, Id> terrByDev = new Map<String, Id>();
            for (Territory2 t : [SELECT Id, DeveloperName FROM Territory2 WHERE DeveloperName IN :COUNTRY_TERRITORY.values()]) {
                terrByDev.put(t.DeveloperName, t.Id);
            }

            // Check for existing PTAs to avoid duplicates
            Set<Id> taggedProductIds = new Set<Id>(countryProductIdMap.values());
            Set<String> existingPtaKeys = new Set<String>();
            if (!taggedProductIds.isEmpty()) {
                for (SObject pta : Database.query(
                    'SELECT ProductId, TerritoryId FROM ProductTerritoryAvailability WHERE ProductId IN :taggedProductIds'
                )) {
                    existingPtaKeys.add((Id) pta.get('ProductId') + ':' + (Id) pta.get('TerritoryId'));
                }
            }

            List<SObject> ptas = new List<SObject>();

            for (String key : countryProductIdMap.keySet()) {
                List<String> parts = key.split(':');
                String cc = parts[1];
                String terrDev = COUNTRY_TERRITORY.get(cc);
                Id terrId = terrByDev.get(terrDev);
                Id productId = countryProductIdMap.get(key);

                if (terrId != null && productId != null) {
                    String ptaKey = productId + ':' + terrId;
                    if (!existingPtaKeys.contains(ptaKey)) {
                        ptas.add(newPTA(new Map<String, Object>{
                            'ProductId' => productId,
                            'TerritoryId' => terrId,
                            'AlignmentType' => 'Territory and Subordinates Inclusion',
                            'Status' => 'Draft',
                            'Purpose' => 'Visit',
                            'UsageType' => 'LifeSciences'
                        }));
                    }
                }
            }

            Integer ptaSuccess = 0;
            if (!ptas.isEmpty()) {
                Database.SaveResult[] ptaResults = Database.insert(ptas, false);
                for (Integer i = 0; i < ptaResults.size(); i++) {
                    if (ptaResults[i].isSuccess()) {
                        ptaSuccess++;
                    } else if (errors.size() < 10) {
                        errors.add('PTA: ' + ptaResults[i].getErrors()[0].getMessage());
                    }
                }
            }

            String result = 'Products: ' + productSuccess + ', PTAs: ' + ptaSuccess
                + '. Run Product Alignment Job from Admin Console to generate detail records (PTDAs).';
            if (!errors.isEmpty()) result += ' | Errors: ' + String.join(errors, '; ');
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating products: ' + e.getMessage()
                + ' [' + e.getStackTraceString() + ']');
        }
    }

    @AuraEnabled
    public static String deleteProductsAndAlignments() {
        try {
            String escapedTag = String.escapeSingleQuotes(DEMO_TAG);
            Integer deleted = 0;

            Set<Id> taggedProductIds = getTaggedProductIds();

            if (objectExists('ProductTerrDtlAvailability') && !taggedProductIds.isEmpty()) {
                List<SObject> ptdas = Database.query(
                    'SELECT Id FROM ProductTerrDtlAvailability WHERE ProductId IN :taggedProductIds'
                );
                if (!ptdas.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(ptdas, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }
            }

            if (objectExists('ProductTerritoryAvailability') && !taggedProductIds.isEmpty()) {
                List<SObject> ptas = Database.query(
                    'SELECT Id FROM ProductTerritoryAvailability WHERE ProductId IN :taggedProductIds'
                );
                if (!ptas.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(ptas, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }
            }

            if (objectExists('LifeSciMarketableProduct')) {
                List<SObject> mps = Database.query(
                    'SELECT Id FROM LifeSciMarketableProduct WHERE SourceSystem = \'' + escapedTag + '\''
                );
                if (!mps.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(mps, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }
            }

            return 'Deleted ' + deleted + ' product alignment records.';
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting products: ' + e.getMessage());
        }
    }

    private static Set<Id> getTaggedProductIds() {
        Set<Id> ids = new Set<Id>();
        if (objectExists('LifeSciMarketableProduct')) {
            String escapedTag = String.escapeSingleQuotes(DEMO_TAG);
            for (SObject mp : Database.query(
                'SELECT Id FROM LifeSciMarketableProduct WHERE SourceSystem = \'' + escapedTag + '\''
            )) {
                ids.add(mp.Id);
            }
        }
        return ids;
    }
}
