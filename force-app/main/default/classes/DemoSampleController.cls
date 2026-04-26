public without sharing class DemoSampleController {

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

    private static final List<String> DOSAGES = new List<String>{ '10mg', '15mg' };

    private static SObject newMarketableProduct(Map<String, Object> fields) {
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

            Integer productCount = [
                SELECT COUNT() FROM Product2
                WHERE ProductCode LIKE 'IMMUNEXIS-%-SMPL'
                AND Family = 'Sample'
            ];
            parts.add('Products: ' + productCount);

            Set<Id> sampleProductIds = getSampleProductIds();

            Integer batchCount = 0;
            if (!sampleProductIds.isEmpty()) {
                batchCount = [
                    SELECT COUNT() FROM ProductionBatch
                    WHERE ProductId IN :sampleProductIds
                ];
            }
            parts.add('Batches: ' + batchCount);

            if (!sampleProductIds.isEmpty()) {
                Integer piCount = [SELECT COUNT() FROM ProductItem WHERE Product2Id IN :sampleProductIds];
                parts.add('Product Items: ' + piCount);
            } else {
                parts.add('Product Items: 0');
            }

            if (objectExists('LifeSciMarketableProduct')) {
                String escapedTag = String.escapeSingleQuotes(DEMO_TAG);
                Integer mpCount = Database.countQuery(
                    'SELECT COUNT() FROM LifeSciMarketableProduct WHERE SourceSystem = \'' + escapedTag + '\' AND ProductSpecificationType = \'LSSampleProduct\''
                );
                parts.add('Marketable Products: ' + mpCount);
            }

            if (objectExists('ProductTerritoryAvailability') && objectExists('LifeSciMarketableProduct')) {
                Set<Id> sampleMpIds = getSampleMarketableProductIds();
                if (!sampleMpIds.isEmpty()) {
                    List<SObject> ptas = Database.query(
                        'SELECT Id FROM ProductTerritoryAvailability WHERE ProductId IN :sampleMpIds'
                    );
                    parts.add('PTAs: ' + ptas.size());
                } else {
                    parts.add('PTAs: 0');
                }
            }

            return String.join(parts, ', ');
        } catch (Exception e) {
            throw new AuraHandledException('Error getting status: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String createSamples() {
        try {
            List<String> errors = new List<String>();

            // ── Step 0: Ensure all reps have User Inventory Locations ──
            createUserInventoryLocations(errors);

            // ── Step 1: Create Product2 records ──
            Id sampleRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName()
                .get('LSC_Sample').getRecordTypeId();

            Set<String> existingCodes = new Set<String>();
            for (Product2 p : [SELECT ProductCode FROM Product2 WHERE ProductCode LIKE 'IMMUNEXIS-%-SMPL']) {
                existingCodes.add(p.ProductCode);
            }

            List<Product2> products = new List<Product2>();
            for (String cc : COUNTRY_CODES) {
                for (String dose : DOSAGES) {
                    String code = 'IMMUNEXIS-' + cc + '-' + dose + '-SMPL';
                    if (!existingCodes.contains(code)) {
                        products.add(new Product2(
                            Name = 'Immunexis ' + cc + ' ' + dose + ' Sample',
                            ProductCode = code,
                            IsActive = true,
                            Family = 'Sample',
                            RecordTypeId = sampleRecordTypeId
                        ));
                    }
                }
            }

            Integer productSuccess = 0;
            List<Product2> insertedProducts = new List<Product2>();
            if (!products.isEmpty()) {
                Database.SaveResult[] results = Database.insert(products, false);
                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        productSuccess++;
                        insertedProducts.add(products[i]);
                    } else if (errors.size() < 5) {
                        errors.add(products[i].ProductCode + ': ' + results[i].getErrors()[0].getMessage());
                    }
                }
            }

            // Also gather previously created sample products
            Map<String, Id> codeToProduct2Id = new Map<String, Id>();
            for (Product2 p : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode LIKE 'IMMUNEXIS-%-SMPL' AND Family = 'Sample']) {
                codeToProduct2Id.put(p.ProductCode, p.Id);
            }

            // ── Step 2: Create ProductionBatch records ──
            Set<Id> allProduct2Ids = new Set<Id>(codeToProduct2Id.values());
            Set<Id> productsWithBatches = new Set<Id>();
            for (ProductionBatch pb : [SELECT ProductId FROM ProductionBatch WHERE ProductId IN :allProduct2Ids]) {
                productsWithBatches.add(pb.ProductId);
            }

            List<ProductionBatch> batches = new List<ProductionBatch>();
            Datetime expiry1 = Datetime.now().addYears(1);
            Datetime expiry2 = Datetime.now().addYears(2);
            for (Id pid : allProduct2Ids) {
                if (!productsWithBatches.contains(pid)) {
                    batches.add(new ProductionBatch(ProductId = pid, IsActive = true, ExpirationDate = expiry1));
                    batches.add(new ProductionBatch(ProductId = pid, IsActive = true, ExpirationDate = expiry2));
                }
            }

            Integer batchSuccess = 0;
            List<ProductionBatch> insertedBatches = new List<ProductionBatch>();
            if (!batches.isEmpty()) {
                Database.SaveResult[] batchResults = Database.insert(batches, false);
                for (Integer i = 0; i < batchResults.size(); i++) {
                    if (batchResults[i].isSuccess()) {
                        batchSuccess++;
                        insertedBatches.add(batches[i]);
                    } else if (errors.size() < 10) {
                        errors.add('Batch: ' + batchResults[i].getErrors()[0].getMessage());
                    }
                }
            }

            // ── Step 2b: Share ProductionBatch records with territory groups ──
            if (!insertedBatches.isEmpty()) {
                shareBatchesWithTerritoryGroups(insertedBatches, codeToProduct2Id, errors);
            }

            // ── Step 2c: Create ProductItem records (link Product2 → rep inventory Location) ──
            createProductItems(codeToProduct2Id, errors);

            // ── Step 3: Create LifeSciMarketableProduct records for each sample ──
            if (!objectExists('LifeSciMarketableProduct')) {
                String result = 'Products: ' + productSuccess + ', Batches: ' + batchSuccess
                    + '. LifeSciMarketableProduct not available — samples created but not aligned to territories.';
                if (!errors.isEmpty()) result += ' | Errors: ' + String.join(errors, '; ');
                return result;
            }

            // Find country-level Immunexis brand marketable products: Immunexis (US), Immunexis (FR), etc.
            String escapedTag = String.escapeSingleQuotes(DEMO_TAG);
            Map<String, Id> countryBrandIds = new Map<String, Id>();
            for (SObject mp : Database.query(
                'SELECT Id, Name FROM LifeSciMarketableProduct WHERE Name LIKE \'Immunexis (%)\' AND Type = \'Brand\''
            )) {
                String name = (String) mp.get('Name');
                Integer open = name.indexOf('(');
                Integer close = name.indexOf(')');
                if (open > 0 && close > open) {
                    countryBrandIds.put(name.substring(open + 1, close), mp.Id);
                }
            }

            // Also find the Autoimmune Disorders market for ParentProductId
            Id autoimmuneMktId = null;
            for (SObject mp : Database.query(
                'SELECT Id FROM LifeSciMarketableProduct WHERE Name = \'Autoimmune Disorders\' AND Type = \'Market\' LIMIT 1'
            )) {
                autoimmuneMktId = mp.Id;
            }

            if (countryBrandIds.isEmpty()) {
                String result = 'Products: ' + productSuccess + ', Batches: ' + batchSuccess
                    + '. No country-level Immunexis brands found — run Product Alignment first.';
                if (!errors.isEmpty()) result += ' | Errors: ' + String.join(errors, '; ');
                return result;
            }

            // Check ALL marketable products linked to our Product2 IDs (any SourceSystem)
            Set<Id> allProduct2IdsSet = new Set<Id>(codeToProduct2Id.values());
            Set<Id> existingMpProduct2Ids = new Set<Id>();
            for (SObject mp : Database.query(
                'SELECT ProductId FROM LifeSciMarketableProduct WHERE ProductId IN :allProduct2IdsSet'
            )) {
                existingMpProduct2Ids.add((Id) mp.get('ProductId'));
            }

            List<SObject> marketableProducts = new List<SObject>();
            List<String> mpKeys = new List<String>();
            for (String code : codeToProduct2Id.keySet()) {
                Id product2Id = codeToProduct2Id.get(code);
                if (!existingMpProduct2Ids.contains(product2Id)) {
                    String cc = code.split('-')[1];
                    Id countryBrandId = countryBrandIds.get(cc);
                    if (countryBrandId == null) continue;
                    marketableProducts.add(newMarketableProduct(new Map<String, Object>{
                        'Name' => code.replace('-SMPL', ' Sample').replace('-', ' ').replace('IMMUNEXIS', 'Immunexis'),
                        'Type' => 'Product',
                        'ProductSpecificationType' => 'LSSampleProduct',
                        'ProductId' => product2Id,
                        'ParentProductId' => autoimmuneMktId,
                        'ParentBrandProductId' => countryBrandId,
                        'DistributionMethod' => 'Drop',
                        'IsActive' => true,
                        'SourceSystem' => DEMO_TAG
                    }));
                    mpKeys.add(code);
                }
            }

            Integer mpSuccess = 0;
            Map<String, Id> codeToMpId = new Map<String, Id>();
            if (!marketableProducts.isEmpty()) {
                Database.SaveResult[] mpResults = Database.insert(marketableProducts, false);
                for (Integer i = 0; i < mpResults.size(); i++) {
                    if (mpResults[i].isSuccess()) {
                        mpSuccess++;
                        codeToMpId.put(mpKeys[i], mpResults[i].getId());
                    } else if (errors.size() < 10) {
                        errors.add('MP ' + mpKeys[i] + ': ' + mpResults[i].getErrors()[0].getMessage());
                    }
                }
            }

            // Also include existing marketable products (any SourceSystem) for PTA creation
            for (SObject mp : Database.query(
                'SELECT Id, ProductId FROM LifeSciMarketableProduct WHERE ProductId IN :allProduct2IdsSet'
            )) {
                Id product2Id = (Id) mp.get('ProductId');
                for (String code : codeToProduct2Id.keySet()) {
                    if (codeToProduct2Id.get(code) == product2Id && !codeToMpId.containsKey(code)) {
                        codeToMpId.put(code, mp.Id);
                    }
                }
            }

            // ── Step 4: Create PTAs for each sample marketable product ──
            if (!objectExists('ProductTerritoryAvailability')) {
                String result = 'Products: ' + productSuccess + ', Batches: ' + batchSuccess
                    + ', Marketable Products: ' + mpSuccess + '. PTA not available.';
                if (!errors.isEmpty()) result += ' | Errors: ' + String.join(errors, '; ');
                return result;
            }

            Map<String, Id> terrByDev = new Map<String, Id>();
            for (Territory2 t : [SELECT Id, DeveloperName FROM Territory2 WHERE DeveloperName IN :COUNTRY_TERRITORY.values()]) {
                terrByDev.put(t.DeveloperName, t.Id);
            }

            // Check existing PTAs
            Set<Id> allMpIds = new Set<Id>(codeToMpId.values());
            Set<String> existingPtaKeys = new Set<String>();
            if (!allMpIds.isEmpty()) {
                for (SObject pta : Database.query(
                    'SELECT ProductId, TerritoryId FROM ProductTerritoryAvailability WHERE ProductId IN :allMpIds'
                )) {
                    existingPtaKeys.add((Id) pta.get('ProductId') + ':' + (Id) pta.get('TerritoryId'));
                }
            }

            List<SObject> ptas = new List<SObject>();
            for (String code : codeToMpId.keySet()) {
                String cc = code.split('-')[1];
                String terrDev = COUNTRY_TERRITORY.get(cc);
                Id terrId = terrByDev.get(terrDev);
                Id mpId = codeToMpId.get(code);

                if (terrId != null && mpId != null) {
                    String ptaKey = mpId + ':' + terrId;
                    if (!existingPtaKeys.contains(ptaKey)) {
                        ptas.add(newPTA(new Map<String, Object>{
                            'ProductId' => mpId,
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
            List<SObject> insertedPtas = new List<SObject>();
            if (!ptas.isEmpty()) {
                Database.SaveResult[] ptaResults = Database.insert(ptas, false);
                for (Integer i = 0; i < ptaResults.size(); i++) {
                    if (ptaResults[i].isSuccess()) {
                        ptaSuccess++;
                        insertedPtas.add(ptas[i]);
                    } else if (errors.size() < 15) {
                        errors.add('PTA: ' + ptaResults[i].getErrors()[0].getMessage());
                    }
                }
            }

            // ── Step 4b: Share PTAs with territory groups ──
            if (!insertedPtas.isEmpty()) {
                sharePtasWithTerritoryGroups(insertedPtas, errors);
            }

            // ── Step 5: Trigger alignment job to publish Draft PTAs → generate PTDAs ──
            String alignmentStatus = '';
            if (ptaSuccess > 0) {
                try {
                    Invocable.Action action = Invocable.Action.createCustomAction(
                        'batchJobAction', 'lsc4ce_flow__PublishDraftProductTerritoryAlignment'
                    );
                    List<Invocable.Action.Result> actionResults = action.invoke();
                    if (!actionResults.isEmpty() && actionResults[0].isSuccess()) {
                        alignmentStatus = 'Alignment job submitted (PTDAs will be generated shortly).';
                    } else {
                        alignmentStatus = 'Alignment job failed — run manually from Product Alignment Jobs.';
                    }
                } catch (Exception ae) {
                    alignmentStatus = 'Could not trigger alignment job: ' + ae.getMessage();
                }
            }

            String result = 'Products: ' + productSuccess + ', Batches: ' + batchSuccess
                + ', Marketable Products: ' + mpSuccess + ', PTAs: ' + ptaSuccess
                + '. ' + alignmentStatus;
            if (!errors.isEmpty()) result += ' | Errors: ' + String.join(errors, '; ');
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating samples: ' + e.getMessage()
                + ' [' + e.getStackTraceString() + ']');
        }
    }

    @AuraEnabled
    public static String deleteSamples() {
        try {
            Integer deleted = 0;
            String escapedTag = String.escapeSingleQuotes(DEMO_TAG);

            // 1. Delete PTAs for sample marketable products
            if (objectExists('ProductTerritoryAvailability') && objectExists('LifeSciMarketableProduct')) {
                Set<Id> sampleMpIds = getSampleMarketableProductIds();
                if (!sampleMpIds.isEmpty()) {
                    List<SObject> ptas = Database.query(
                        'SELECT Id FROM ProductTerritoryAvailability WHERE ProductId IN :sampleMpIds'
                    );
                    if (!ptas.isEmpty()) {
                        Database.DeleteResult[] dr = Database.delete(ptas, false);
                        for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                    }
                }
            }

            // 2. Delete sample LifeSciMarketableProduct records
            if (objectExists('LifeSciMarketableProduct')) {
                List<SObject> mps = Database.query(
                    'SELECT Id FROM LifeSciMarketableProduct WHERE SourceSystem = \'' + escapedTag + '\' AND ProductSpecificationType = \'LSSampleProduct\''
                );
                if (!mps.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(mps, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }
            }

            // 3. Delete ProductItem records
            Set<Id> sampleProductIds = getSampleProductIds();
            if (!sampleProductIds.isEmpty()) {
                List<ProductItem> pitems = [SELECT Id FROM ProductItem WHERE Product2Id IN :sampleProductIds];
                if (!pitems.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(pitems, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }
            }

            // 4. Delete ProductionBatch records
            if (!sampleProductIds.isEmpty()) {
                List<ProductionBatch> pbatches = [SELECT Id FROM ProductionBatch WHERE ProductId IN :sampleProductIds];
                if (!pbatches.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(pbatches, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }
            }

            // 5. Delete Product2 records
            List<Product2> products = [SELECT Id FROM Product2 WHERE ProductCode LIKE 'IMMUNEXIS-%-SMPL' AND Family = 'Sample'];
            if (!products.isEmpty()) {
                Database.DeleteResult[] dr = Database.delete(products, false);
                for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
            }

            return 'Deleted ' + deleted + ' sample records.';
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting samples: ' + e.getMessage());
        }
    }

    private static Set<Id> getSampleProductIds() {
        Set<Id> ids = new Set<Id>();
        for (Product2 p : [SELECT Id FROM Product2 WHERE ProductCode LIKE 'IMMUNEXIS-%-SMPL' AND Family = 'Sample']) {
            ids.add(p.Id);
        }
        return ids;
    }

    private static Set<Id> getSampleMarketableProductIds() {
        Set<Id> ids = new Set<Id>();
        if (objectExists('LifeSciMarketableProduct')) {
            String escapedTag = String.escapeSingleQuotes(DEMO_TAG);
            for (SObject mp : Database.query(
                'SELECT Id FROM LifeSciMarketableProduct WHERE SourceSystem = \'' + escapedTag + '\' AND ProductSpecificationType = \'LSSampleProduct\''
            )) {
                ids.add(mp.Id);
            }
        }
        return ids;
    }

    private static void sharePtasWithTerritoryGroups(List<SObject> ptaRecords, List<String> errors) {
        Set<Id> parentTerritoryIds = new Set<Id>();
        for (SObject pta : ptaRecords) {
            parentTerritoryIds.add((Id) pta.get('TerritoryId'));
        }

        // Collect all child territories under each PTA territory
        Map<Id, Set<Id>> parentToAllChildren = new Map<Id, Set<Id>>();
        for (Id parentId : parentTerritoryIds) {
            parentToAllChildren.put(parentId, new Set<Id>{ parentId });
        }
        // Walk down 3 levels (country → region/FSR → city)
        Set<Id> currentLevel = parentTerritoryIds;
        for (Integer depth = 0; depth < 3 && !currentLevel.isEmpty(); depth++) {
            Set<Id> nextLevel = new Set<Id>();
            for (Territory2 child : [SELECT Id, ParentTerritory2Id FROM Territory2 WHERE ParentTerritory2Id IN :currentLevel]) {
                nextLevel.add(child.Id);
                for (Id parentId : parentTerritoryIds) {
                    if (parentToAllChildren.get(parentId).contains(child.ParentTerritory2Id)) {
                        parentToAllChildren.get(parentId).add(child.Id);
                    }
                }
            }
            currentLevel = nextLevel;
        }

        // Get Territory groups for all territories (parent + children)
        Set<Id> allTerritoryIds = new Set<Id>();
        for (Set<Id> children : parentToAllChildren.values()) {
            allTerritoryIds.addAll(children);
        }
        Map<Id, Id> terrToGroup = new Map<Id, Id>();
        for (Group g : [SELECT Id, RelatedId FROM Group WHERE Type = 'Territory' AND RelatedId IN :allTerritoryIds]) {
            terrToGroup.put(g.RelatedId, g.Id);
        }

        List<ProductTerritoryAvailabilityShare> shares = new List<ProductTerritoryAvailabilityShare>();
        for (SObject pta : ptaRecords) {
            Id ptaTerritoryId = (Id) pta.get('TerritoryId');
            Set<Id> allTerrs = parentToAllChildren.get(ptaTerritoryId);
            if (allTerrs == null) continue;
            for (Id terrId : allTerrs) {
                Id groupId = terrToGroup.get(terrId);
                if (groupId != null) {
                    ProductTerritoryAvailabilityShare share = new ProductTerritoryAvailabilityShare();
                    share.ParentId = pta.Id;
                    share.UserOrGroupId = groupId;
                    share.AccessLevel = 'Read';
                    share.RowCause = Schema.ProductTerritoryAvailabilityShare.RowCause.Manual;
                    shares.add(share);
                }
            }
        }

        if (!shares.isEmpty()) {
            Database.SaveResult[] shareResults = Database.insert(shares, false);
            for (Integer i = 0; i < shareResults.size(); i++) {
                if (!shareResults[i].isSuccess() && errors.size() < 15) {
                    errors.add('PTA Share: ' + shareResults[i].getErrors()[0].getMessage());
                }
            }
        }
    }

    private static void shareBatchesWithTerritoryGroups(List<ProductionBatch> batchRecords, Map<String, Id> codeToProduct2Id, List<String> errors) {
        // Build reverse map: Product2Id → country code
        Map<Id, String> product2IdToCountry = new Map<Id, String>();
        for (String code : codeToProduct2Id.keySet()) {
            String cc = code.split('-')[1];
            product2IdToCountry.put(codeToProduct2Id.get(code), cc);
        }

        // Get country territory IDs
        Map<String, Id> terrByDev = new Map<String, Id>();
        for (Territory2 t : [SELECT Id, DeveloperName FROM Territory2 WHERE DeveloperName IN :COUNTRY_TERRITORY.values()]) {
            terrByDev.put(t.DeveloperName, t.Id);
        }

        // Walk hierarchy to find all leaf territories under each country
        Set<Id> countryTerritoryIds = new Set<Id>(terrByDev.values());
        Map<Id, Set<Id>> parentToAllChildren = new Map<Id, Set<Id>>();
        for (Id parentId : countryTerritoryIds) {
            parentToAllChildren.put(parentId, new Set<Id>{ parentId });
        }
        Set<Id> currentLevel = countryTerritoryIds;
        for (Integer depth = 0; depth < 3 && !currentLevel.isEmpty(); depth++) {
            Set<Id> nextLevel = new Set<Id>();
            for (Territory2 child : [SELECT Id, ParentTerritory2Id FROM Territory2 WHERE ParentTerritory2Id IN :currentLevel]) {
                nextLevel.add(child.Id);
                for (Id parentId : countryTerritoryIds) {
                    if (parentToAllChildren.get(parentId).contains(child.ParentTerritory2Id)) {
                        parentToAllChildren.get(parentId).add(child.Id);
                    }
                }
            }
            currentLevel = nextLevel;
        }

        // Get Territory groups for all territories
        Set<Id> allTerritoryIds = new Set<Id>();
        for (Set<Id> children : parentToAllChildren.values()) {
            allTerritoryIds.addAll(children);
        }
        Map<Id, Id> terrToGroup = new Map<Id, Id>();
        for (Group g : [SELECT Id, RelatedId FROM Group WHERE Type = 'Territory' AND RelatedId IN :allTerritoryIds]) {
            terrToGroup.put(g.RelatedId, g.Id);
        }

        // Create shares: each batch → all leaf territory groups for its country
        List<ProductionBatchShare> batchShares = new List<ProductionBatchShare>();
        for (ProductionBatch batch : batchRecords) {
            String cc = product2IdToCountry.get(batch.ProductId);
            if (cc == null) continue;
            String terrDev = COUNTRY_TERRITORY.get(cc);
            Id countryTerrId = terrByDev.get(terrDev);
            if (countryTerrId == null) continue;

            Set<Id> allTerrs = parentToAllChildren.get(countryTerrId);
            if (allTerrs == null) continue;
            for (Id terrId : allTerrs) {
                Id groupId = terrToGroup.get(terrId);
                if (groupId != null) {
                    ProductionBatchShare share = new ProductionBatchShare();
                    share.ParentId = batch.Id;
                    share.UserOrGroupId = groupId;
                    share.AccessLevel = 'Read';
                    share.RowCause = Schema.ProductionBatchShare.RowCause.Manual;
                    batchShares.add(share);
                }
            }
        }

        if (!batchShares.isEmpty()) {
            Database.SaveResult[] shareResults = Database.insert(batchShares, false);
            for (Integer i = 0; i < shareResults.size(); i++) {
                if (!shareResults[i].isSuccess() && errors.size() < 15) {
                    errors.add('Batch Share: ' + shareResults[i].getErrors()[0].getMessage());
                }
            }
        }
    }

    private static void createProductItems(Map<String, Id> codeToProduct2Id, List<String> errors) {
        // Find all rep User Inventory Locations assigned to country territories
        Map<Id, Schema.Location> repLocations = new Map<Id, Schema.Location>();
        Map<Id, Set<String>> repCountries = new Map<Id, Set<String>>();

        // Get reps and their country assignments
        for (UserTerritory2Association uta : [
            SELECT UserId, Territory2.DeveloperName FROM UserTerritory2Association
            WHERE Territory2.DeveloperName IN :COUNTRY_TERRITORY.values()
        ]) {
            if (!repCountries.containsKey(uta.UserId)) {
                repCountries.put(uta.UserId, new Set<String>());
            }
            for (String cc : COUNTRY_TERRITORY.keySet()) {
                if (COUNTRY_TERRITORY.get(cc) == uta.Territory2.DeveloperName) {
                    repCountries.get(uta.UserId).add(cc);
                }
            }
        }

        Set<Id> repIds = repCountries.keySet();
        for (Schema.Location loc : [
            SELECT Id, PrimaryUserId FROM Location
            WHERE PrimaryUserId IN :repIds AND IsInventoryLocation = true AND LocationType = 'User Inventory'
        ]) {
            repLocations.put(loc.PrimaryUserId, loc);
        }

        // Find existing ProductItems to avoid duplicates
        Set<Id> allLocationIds = new Set<Id>();
        for (Schema.Location loc : repLocations.values()) {
            allLocationIds.add(loc.Id);
        }
        Set<Id> allProduct2Ids = new Set<Id>(codeToProduct2Id.values());
        Set<String> existingPiKeys = new Set<String>();
        if (!allLocationIds.isEmpty() && !allProduct2Ids.isEmpty()) {
            for (ProductItem pi : [
                SELECT Product2Id, LocationId FROM ProductItem
                WHERE LocationId IN :allLocationIds AND Product2Id IN :allProduct2Ids
            ]) {
                existingPiKeys.add(pi.Product2Id + ':' + pi.LocationId);
            }
        }

        List<ProductItem> items = new List<ProductItem>();
        for (Id repId : repLocations.keySet()) {
            Schema.Location loc = repLocations.get(repId);
            Set<String> countries = repCountries.get(repId);
            if (countries == null) continue;

            for (String code : codeToProduct2Id.keySet()) {
                String cc = code.split('-')[1];
                if (countries.contains(cc)) {
                    Id product2Id = codeToProduct2Id.get(code);
                    String piKey = product2Id + ':' + loc.Id;
                    if (!existingPiKeys.contains(piKey)) {
                        items.add(new ProductItem(
                            Product2Id = product2Id,
                            LocationId = loc.Id,
                            QuantityOnHand = 100
                        ));
                        existingPiKeys.add(piKey);
                    }
                }
            }
        }

        if (!items.isEmpty()) {
            Database.SaveResult[] results = Database.insert(items, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess() && errors.size() < 15) {
                    errors.add('ProductItem: ' + results[i].getErrors()[0].getMessage());
                }
            }
        }
    }

    private static void createUserInventoryLocations(List<String> errors) {
        List<UserTerritory2Association> utas = [
            SELECT UserId, User.Name FROM UserTerritory2Association
            WHERE Territory2.DeveloperName IN :COUNTRY_TERRITORY.values()
        ];
        Set<Id> repIds = new Set<Id>();
        Map<Id, String> repNames = new Map<Id, String>();
        for (UserTerritory2Association uta : utas) {
            repIds.add(uta.UserId);
            repNames.put(uta.UserId, uta.User.Name);
        }

        Set<Id> repsWithLocation = new Set<Id>();
        for (Schema.Location loc : [SELECT PrimaryUserId FROM Location WHERE PrimaryUserId IN :repIds AND IsInventoryLocation = true AND LocationType = 'User Inventory']) {
            repsWithLocation.add(loc.PrimaryUserId);
        }

        List<Schema.Location> locs = new List<Schema.Location>();
        for (Id repId : repIds) {
            if (!repsWithLocation.contains(repId)) {
                Schema.Location loc = new Schema.Location();
                loc.Name = repNames.get(repId) + ' Inventory';
                loc.LocationType = 'User Inventory';
                loc.IsInventoryLocation = true;
                loc.PrimaryUserId = repId;
                locs.add(loc);
            }
        }

        if (!locs.isEmpty()) {
            Database.SaveResult[] results = Database.insert(locs, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess() && errors.size() < 15) {
                    errors.add('Location: ' + results[i].getErrors()[0].getMessage());
                }
            }
        }
    }
}
