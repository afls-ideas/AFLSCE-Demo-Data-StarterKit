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

                Set<Id> piIds = new Set<Id>();
                for (ProductItem pi : [SELECT Id FROM ProductItem WHERE Product2Id IN :sampleProductIds]) {
                    piIds.add(pi.Id);
                }
                if (!piIds.isEmpty()) {
                    Integer pbiCount = [SELECT COUNT() FROM ProductBatchItem WHERE ProductItemId IN :piIds];
                    parts.add('Batch Items: ' + pbiCount);
                } else {
                    parts.add('Batch Items: 0');
                }
            } else {
                parts.add('Product Items: 0');
                parts.add('Batch Items: 0');
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

            if (objectExists('ProviderSampleLimit') && objectExists('LifeSciMarketableProduct')) {
                Set<Id> allMpIds = getSampleMarketableProductIds();
                for (SObject mp : Database.query(
                    'SELECT Id FROM LifeSciMarketableProduct WHERE Name LIKE \'Immunexis (%)\' AND Type = \'Brand\''
                )) {
                    allMpIds.add(mp.Id);
                }
                if (!allMpIds.isEmpty()) {
                    Integer pslCount = Database.countQuery(
                        'SELECT COUNT() FROM ProviderSampleLimit WHERE ProductId IN :allMpIds'
                    );
                    parts.add('Sample Limits: ' + pslCount);
                } else {
                    parts.add('Sample Limits: 0');
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
            List<String> details = new List<String>();

            // ── Step 0: Ensure all reps have User Inventory Locations ──
            details.add('HEADER:Step 0 — User Inventory Locations');
            details.add('Each rep needs a Location record (LocationType=User Inventory, IsInventoryLocation=true) to hold sample inventory');
            createUserInventoryLocations(errors);
            details.add('SUCCESS:User Inventory Locations verified for all territory reps');

            // ── Step 1: Create Product2 records ──
            details.add('HEADER:Step 1 — Product2 (Sample Products)');
            details.add('Creating Product2 records with RecordType=LSC_Sample, Family=Sample for ' + COUNTRY_CODES.size() + ' countries x ' + DOSAGES.size() + ' dosages');

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
            if (!products.isEmpty()) {
                Database.SaveResult[] results = Database.insert(products, false);
                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        productSuccess++;
                    } else if (errors.size() < 5) {
                        errors.add(products[i].ProductCode + ': ' + results[i].getErrors()[0].getMessage());
                    }
                }
                details.add('SUCCESS:Created ' + productSuccess + ' Product2 records (e.g., Immunexis US 10mg Sample)');
            } else {
                details.add('All ' + existingCodes.size() + ' Product2 records already exist — skipping');
            }

            Map<String, Id> codeToProduct2Id = new Map<String, Id>();
            for (Product2 p : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode LIKE 'IMMUNEXIS-%-SMPL' AND Family = 'Sample']) {
                codeToProduct2Id.put(p.ProductCode, p.Id);
            }

            // ── Step 2: Create ProductionBatch records ──
            details.add('HEADER:Step 2 — ProductionBatch');
            details.add('Creating 2 ProductionBatch per Product2 (expiring in 1 year and 2 years) with UniqueIdentificationNumber (e.g., IMX-US101000) — this is the batch ID shown in the visit dropdown');

            Set<Id> allProduct2Ids = new Set<Id>(codeToProduct2Id.values());
            Set<Id> productsWithBatches = new Set<Id>();
            for (ProductionBatch pb : [SELECT ProductId FROM ProductionBatch WHERE ProductId IN :allProduct2Ids]) {
                productsWithBatches.add(pb.ProductId);
            }

            // Build reverse map: Product2Id → code for batch naming
            Map<Id, String> product2IdToCode = new Map<Id, String>();
            for (String code : codeToProduct2Id.keySet()) {
                product2IdToCode.put(codeToProduct2Id.get(code), code);
            }

            List<ProductionBatch> batches = new List<ProductionBatch>();
            Datetime expiry1 = Datetime.now().addYears(1);
            Datetime expiry2 = Datetime.now().addYears(2);
            Integer batchSeq = 1000;
            for (Id pid : allProduct2Ids) {
                if (!productsWithBatches.contains(pid)) {
                    String code = product2IdToCode.get(pid);
                    String cc = code != null ? code.split('-')[1] : '';
                    String dose = code != null ? code.split('-')[2] : '';
                    String batchPrefix = 'IMX-' + cc + dose.replace('mg', '');
                    batches.add(new ProductionBatch(
                        ProductId = pid, IsActive = true, ExpirationDate = expiry1,
                        UniqueIdentificationNumber = batchPrefix + String.valueOf(batchSeq++)
                    ));
                    batches.add(new ProductionBatch(
                        ProductId = pid, IsActive = true, ExpirationDate = expiry2,
                        UniqueIdentificationNumber = batchPrefix + String.valueOf(batchSeq++)
                    ));
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
                details.add('SUCCESS:Created ' + batchSuccess + ' ProductionBatch records');
            } else {
                details.add('ProductionBatch records already exist — skipping');
            }

            // ── Step 2b: Share ProductionBatch records with territory groups ──
            if (!insertedBatches.isEmpty()) {
                details.add('HEADER:Step 2b — ProductionBatch Sharing');
                details.add('OWD is Private — creating ProductionBatchShare records for each batch, shared with territory groups at leaf level (walks hierarchy 3 levels deep)');
                shareBatchesWithTerritoryGroups(insertedBatches, codeToProduct2Id, errors);
                details.add('SUCCESS:ProductionBatch sharing complete');
            }

            // ── Step 2c: Create ProductItem records ──
            details.add('HEADER:Step 2c — ProductItem (Inventory)');
            details.add('ProductItem links a Product2 to a rep\'s inventory Location — the visit page queries: ProductItem WHERE LocationId IN (SELECT Id FROM Location WHERE PrimaryUserId = :repId AND LocationType = \'User Inventory\')');
            details.add('OWD is Private — also creating ProductItemShare records for leaf territory groups');
            createProductItems(codeToProduct2Id, errors);
            details.add('SUCCESS:ProductItem records and sharing verified for all reps');

            // ── Step 2d: Create ProductBatchItem records ──
            details.add('HEADER:Step 2d — ProductBatchItem (Batch ↔ Inventory link)');
            details.add('ProductBatchItem is the junction between ProductItem and ProductionBatch — without it, the production batch dropdown on the visit is empty');
            details.add('OWD is Private — also creating ProductBatchItemShare records for leaf territory groups');
            createProductBatchItems(codeToProduct2Id, errors);
            details.add('SUCCESS:ProductBatchItem records and sharing verified');

            // ── Step 3: Create LifeSciMarketableProduct records ──
            details.add('HEADER:Step 3 — LifeSciMarketableProduct');
            if (!objectExists('LifeSciMarketableProduct')) {
                details.add('ERROR:LifeSciMarketableProduct not available in this org');
                return buildCreateResult(productSuccess, batchSuccess, 0, 0, errors, details, '');
            }

            details.add('Creating LifeSciMarketableProduct with Type=Product, ProductSpecificationType=LSSampleProduct, DistributionMethod=Drop');
            details.add('Each sample product is linked to its country-level brand (e.g., ParentBrandProductId → Immunexis (FR)) — the visit filters by this brand');

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

            Id autoimmuneMktId = null;
            for (SObject mp : Database.query(
                'SELECT Id FROM LifeSciMarketableProduct WHERE Name = \'Autoimmune Disorders\' AND Type = \'Market\' LIMIT 1'
            )) {
                autoimmuneMktId = mp.Id;
            }

            if (countryBrandIds.isEmpty()) {
                details.add('ERROR:No country-level Immunexis brands found — run Product Alignment first');
                return buildCreateResult(productSuccess, batchSuccess, 0, 0, errors, details, '');
            }

            details.add('Found country brands: ' + String.join(new List<String>(countryBrandIds.keySet()), ', '));

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
                details.add('SUCCESS:Created ' + mpSuccess + ' LifeSciMarketableProduct records');
            } else {
                details.add('LifeSciMarketableProduct records already exist — skipping');
            }

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

            // ── Step 4: Create PTAs ──
            details.add('HEADER:Step 4 — ProductTerritoryAvailability (PTA)');
            if (!objectExists('ProductTerritoryAvailability')) {
                details.add('ERROR:ProductTerritoryAvailability not available in this org');
                return buildCreateResult(productSuccess, batchSuccess, mpSuccess, 0, errors, details, '');
            }

            details.add('Creating PTAs with AlignmentType=Territory and Subordinates Inclusion, Purpose=Visit — this controls which samples appear on visits in each territory');

            Map<String, Id> terrByDev = new Map<String, Id>();
            for (Territory2 t : [SELECT Id, DeveloperName FROM Territory2 WHERE DeveloperName IN :COUNTRY_TERRITORY.values()]) {
                terrByDev.put(t.DeveloperName, t.Id);
            }

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
                details.add('SUCCESS:Created ' + ptaSuccess + ' PTA records');
            } else {
                details.add('PTA records already exist — skipping');
            }

            // ── Step 4b: Share PTAs with territory groups ──
            if (!insertedPtas.isEmpty()) {
                details.add('HEADER:Step 4b — PTA Sharing');
                details.add('OWD is Private — creating ProductTerritoryAvailabilityShare for each PTA, walking territory hierarchy to share with leaf territory groups');
                sharePtasWithTerritoryGroups(insertedPtas, errors);
                details.add('SUCCESS:PTA sharing complete');
            }

            // ── Step 5: Trigger alignment job ──
            details.add('HEADER:Step 5 — Alignment Job');
            details.add('Publishing Draft PTAs triggers the alignment batch job, which generates ProductTerrDtlAvailability (PTDA) records for leaf territories');
            String alignmentStatus = '';
            if (ptaSuccess > 0) {
                try {
                    Invocable.Action action = Invocable.Action.createCustomAction(
                        'batchJobAction', 'lsc4ce_flow__PublishDraftProductTerritoryAlignment'
                    );
                    List<Invocable.Action.Result> actionResults = action.invoke();
                    if (!actionResults.isEmpty() && actionResults[0].isSuccess()) {
                        alignmentStatus = 'Alignment job submitted (PTDAs will be generated shortly).';
                        details.add('SUCCESS:Alignment job submitted — PTDAs for leaf territories will be generated asynchronously');
                    } else {
                        alignmentStatus = 'Alignment job failed — run manually from Product Alignment Jobs.';
                        details.add('ERROR:Alignment job failed — run manually from Admin Console > Product > Product Alignment Jobs');
                    }
                } catch (Exception ae) {
                    alignmentStatus = 'Could not trigger alignment job: ' + ae.getMessage();
                    details.add('ERROR:' + alignmentStatus);
                }
            } else {
                details.add('No new PTAs — alignment job not needed');
            }

            // ── Step 6: Create TimePeriod ──
            details.add('HEADER:Step 6 — TimePeriod');
            details.add('TimePeriod defines date ranges for sample quota tracking (TerritoryProdtQtyAllocation references it)');
            Integer tpCreated = createTimePeriods(errors);
            if (tpCreated > 0) {
                details.add('SUCCESS:Created ' + tpCreated + ' TimePeriod records');
            } else {
                details.add('TimePeriod records already exist — skipping');
            }

            // ── Step 7: ProviderSampleLimit (async) ──
            details.add('HEADER:Step 7 — ProviderSampleLimit (async)');
            details.add('ProviderSampleLimit controls how many samples a rep can drop per HCP per visit and per period — without it, sample enforcement may block drops entirely');
            details.add('Each HCP Account gets one ProviderSampleLimit per LifeSciMarketableProduct (sample type), linked to the lsc4ce_GenericTemplate');
            details.add('This step runs as an async Queueable job to avoid DML row limits in the main transaction');
            try {
                System.enqueueJob(new ProviderSampleLimitJob(new Set<Id>(codeToMpId.values())));
                details.add('SUCCESS:ProviderSampleLimit Queueable job enqueued — records will be created shortly');
            } catch (Exception qe) {
                details.add('ERROR:Could not enqueue ProviderSampleLimit job: ' + qe.getMessage());
            }

            details.add('HEADER:Summary');
            details.add('The full sample pipeline is: Product2 → ProductionBatch → ProductItem → ProductBatchItem → LifeSciMarketableProduct → PTA → (alignment job) → PTDA → ProviderSampleLimit');
            details.add('For mobile sync: verify DbSchema_ProductTerritoryAvailability filter = AlignmentType = \'Territory and Subordinates Inclusion\'');

            return buildCreateResult(productSuccess, batchSuccess, mpSuccess, ptaSuccess, errors, details, alignmentStatus);
        } catch (Exception e) {
            throw new AuraHandledException('Error creating samples: ' + e.getMessage()
                + ' [' + e.getStackTraceString() + ']');
        }
    }

    private static String buildCreateResult(Integer products, Integer batches, Integer mps, Integer ptas,
            List<String> errors, List<String> details, String alignmentStatus) {
        Map<String, Object> result = new Map<String, Object>{
            'summary' => 'Products: ' + products + ', Batches: ' + batches
                + ', Marketable Products: ' + mps + ', PTAs: ' + ptas
                + (String.isNotBlank(alignmentStatus) ? '. ' + alignmentStatus : ''),
            'details' => details,
            'errors' => errors
        };
        return JSON.serialize(result);
    }

    @AuraEnabled
    public static String deleteSamples() {
        try {
            Integer deleted = 0;
            String escapedTag = String.escapeSingleQuotes(DEMO_TAG);

            // 0. Delete ProviderSampleLimit records linked to our sample marketable products
            if (objectExists('ProviderSampleLimit') && objectExists('LifeSciMarketableProduct')) {
                Set<Id> sampleMpIds = getSampleMarketableProductIds();
                // Also include brand-level MPs
                for (SObject mp : Database.query(
                    'SELECT Id FROM LifeSciMarketableProduct WHERE Name LIKE \'Immunexis (%)\' AND Type = \'Brand\''
                )) {
                    sampleMpIds.add(mp.Id);
                }
                if (!sampleMpIds.isEmpty()) {
                    List<SObject> psls = Database.query(
                        'SELECT Id FROM ProviderSampleLimit WHERE ProductId IN :sampleMpIds'
                    );
                    if (!psls.isEmpty()) {
                        Database.DeleteResult[] dr = Database.delete(psls, false);
                        for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                    }
                }
            }

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

            // 3. Delete ProductBatchItem and ProductItem records
            Set<Id> sampleProductIds = getSampleProductIds();
            if (!sampleProductIds.isEmpty()) {
                List<ProductItem> pitems = [SELECT Id FROM ProductItem WHERE Product2Id IN :sampleProductIds];
                if (!pitems.isEmpty()) {
                    Set<Id> piIds = new Set<Id>();
                    for (ProductItem pi : pitems) { piIds.add(pi.Id); }
                    List<ProductBatchItem> pbis = [SELECT Id FROM ProductBatchItem WHERE ProductItemId IN :piIds];
                    if (!pbis.isEmpty()) {
                        Database.DeleteResult[] dr = Database.delete(pbis, false);
                        for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                    }
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

            // 6. Delete demo TimePeriod records
            List<TimePeriod> timePeriods = [SELECT Id FROM TimePeriod WHERE Name LIKE 'Sample Period %'];
            if (!timePeriods.isEmpty()) {
                Database.DeleteResult[] dr = Database.delete(timePeriods, false);
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
        List<Set<String>> itemCountries = new List<Set<String>>();
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
                            QuantityOnHand = 100,
                            QuantityUnitOfMeasure = 'Each'
                        ));
                        itemCountries.add(new Set<String>{ cc });
                        existingPiKeys.add(piKey);
                    }
                }
            }
        }

        List<ProductItem> insertedItems = new List<ProductItem>();
        List<Set<String>> insertedCountries = new List<Set<String>>();
        if (!items.isEmpty()) {
            Database.SaveResult[] results = Database.insert(items, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    insertedItems.add(items[i]);
                    insertedCountries.add(itemCountries[i]);
                } else if (errors.size() < 15) {
                    errors.add('ProductItem: ' + results[i].getErrors()[0].getMessage());
                }
            }
        }

        if (!insertedItems.isEmpty()) {
            shareProductItems(insertedItems, insertedCountries, errors);
        }
    }

    private static void shareProductItems(List<ProductItem> piRecords, List<Set<String>> countrySets, List<String> errors) {
        Map<String, Id> terrByDev = new Map<String, Id>();
        for (Territory2 t : [SELECT Id, DeveloperName FROM Territory2 WHERE DeveloperName IN :COUNTRY_TERRITORY.values()]) {
            terrByDev.put(t.DeveloperName, t.Id);
        }

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

        Set<Id> allTerritoryIds = new Set<Id>();
        for (Set<Id> children : parentToAllChildren.values()) {
            allTerritoryIds.addAll(children);
        }
        Map<Id, Id> terrToGroup = new Map<Id, Id>();
        for (Group g : [SELECT Id, RelatedId FROM Group WHERE Type = 'Territory' AND RelatedId IN :allTerritoryIds]) {
            terrToGroup.put(g.RelatedId, g.Id);
        }

        Schema.SObjectType shareType = Schema.getGlobalDescribe().get('ProductItemShare');
        if (shareType == null) return;

        List<SObject> shares = new List<SObject>();
        for (Integer i = 0; i < piRecords.size(); i++) {
            Id piId = piRecords[i].Id;
            Set<String> countries = countrySets[i];

            for (String cc : countries) {
                String terrDev = COUNTRY_TERRITORY.get(cc);
                Id countryTerrId = terrByDev.get(terrDev);
                if (countryTerrId == null) continue;
                Set<Id> allTerrs = parentToAllChildren.get(countryTerrId);
                if (allTerrs == null) continue;

                for (Id terrId : allTerrs) {
                    Id groupId = terrToGroup.get(terrId);
                    if (groupId != null) {
                        SObject share = shareType.newSObject();
                        share.put('ParentId', piId);
                        share.put('UserOrGroupId', groupId);
                        share.put('AccessLevel', 'Read');
                        share.put('RowCause', 'Manual');
                        shares.add(share);
                    }
                }
            }
        }

        if (!shares.isEmpty()) {
            Database.SaveResult[] shareResults = Database.insert(shares, false);
            for (Integer i = 0; i < shareResults.size(); i++) {
                if (!shareResults[i].isSuccess() && errors.size() < 15) {
                    errors.add('PI Share: ' + shareResults[i].getErrors()[0].getMessage());
                }
            }
        }
    }

    private static void createProductBatchItems(Map<String, Id> codeToProduct2Id, List<String> errors) {
        Set<Id> allProduct2Ids = new Set<Id>(codeToProduct2Id.values());

        List<ProductItem> productItems = [
            SELECT Id, Product2Id FROM ProductItem
            WHERE Product2Id IN :allProduct2Ids
        ];
        if (productItems.isEmpty()) return;

        Map<Id, List<ProductionBatch>> batchesByProduct = new Map<Id, List<ProductionBatch>>();
        for (ProductionBatch pb : [
            SELECT Id, ProductId FROM ProductionBatch
            WHERE ProductId IN :allProduct2Ids AND IsActive = true
        ]) {
            if (!batchesByProduct.containsKey(pb.ProductId)) {
                batchesByProduct.put(pb.ProductId, new List<ProductionBatch>());
            }
            batchesByProduct.get(pb.ProductId).add(pb);
        }

        Set<Id> allPiIds = new Set<Id>();
        for (ProductItem pi : productItems) { allPiIds.add(pi.Id); }
        Set<String> existingPbiKeys = new Set<String>();
        for (ProductBatchItem pbi : [
            SELECT ProductItemId, ProductionBatchId FROM ProductBatchItem
            WHERE ProductItemId IN :allPiIds
        ]) {
            existingPbiKeys.add(pbi.ProductItemId + ':' + pbi.ProductionBatchId);
        }

        // Track which Product2Id each new PBI belongs to (for sharing)
        List<ProductBatchItem> items = new List<ProductBatchItem>();
        List<Id> itemProduct2Ids = new List<Id>();
        for (ProductItem pi : productItems) {
            List<ProductionBatch> batches = batchesByProduct.get(pi.Product2Id);
            if (batches == null) continue;
            for (ProductionBatch pb : batches) {
                String pbiKey = pi.Id + ':' + pb.Id;
                if (!existingPbiKeys.contains(pbiKey)) {
                    items.add(new ProductBatchItem(
                        ProductItemId = pi.Id,
                        ProductionBatchId = pb.Id,
                        IsActive = true,
                        RemainingQuantity = 1000
                    ));
                    itemProduct2Ids.add(pi.Product2Id);
                    existingPbiKeys.add(pbiKey);
                }
            }
        }

        List<ProductBatchItem> insertedItems = new List<ProductBatchItem>();
        List<Id> insertedProduct2Ids = new List<Id>();
        if (!items.isEmpty()) {
            Database.SaveResult[] results = Database.insert(items, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    insertedItems.add(items[i]);
                    insertedProduct2Ids.add(itemProduct2Ids[i]);
                } else if (errors.size() < 15) {
                    errors.add('ProductBatchItem: ' + results[i].getErrors()[0].getMessage());
                }
            }
        }

        if (!insertedItems.isEmpty()) {
            shareProductBatchItems(insertedItems, insertedProduct2Ids, codeToProduct2Id, errors);
        }
    }

    private static void shareProductBatchItems(List<ProductBatchItem> pbiRecords, List<Id> product2Ids, Map<String, Id> codeToProduct2Id, List<String> errors) {
        // Reverse map: Product2Id → country codes
        Map<Id, Set<String>> product2ToCountries = new Map<Id, Set<String>>();
        for (String code : codeToProduct2Id.keySet()) {
            Id p2Id = codeToProduct2Id.get(code);
            String cc = code.split('-')[1];
            if (!product2ToCountries.containsKey(p2Id)) {
                product2ToCountries.put(p2Id, new Set<String>());
            }
            product2ToCountries.get(p2Id).add(cc);
        }

        Map<String, Id> terrByDev = new Map<String, Id>();
        for (Territory2 t : [SELECT Id, DeveloperName FROM Territory2 WHERE DeveloperName IN :COUNTRY_TERRITORY.values()]) {
            terrByDev.put(t.DeveloperName, t.Id);
        }

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

        Set<Id> allTerritoryIds = new Set<Id>();
        for (Set<Id> children : parentToAllChildren.values()) {
            allTerritoryIds.addAll(children);
        }
        Map<Id, Id> terrToGroup = new Map<Id, Id>();
        for (Group g : [SELECT Id, RelatedId FROM Group WHERE Type = 'Territory' AND RelatedId IN :allTerritoryIds]) {
            terrToGroup.put(g.RelatedId, g.Id);
        }

        // Use dynamic SObject to create ProductBatchItemShare
        Schema.SObjectType shareType = Schema.getGlobalDescribe().get('ProductBatchItemShare');
        if (shareType == null) return;

        List<SObject> shares = new List<SObject>();
        for (Integer i = 0; i < pbiRecords.size(); i++) {
            Id pbiId = pbiRecords[i].Id;
            Id p2Id = product2Ids[i];
            Set<String> countries = product2ToCountries.get(p2Id);
            if (countries == null) continue;

            for (String cc : countries) {
                String terrDev = COUNTRY_TERRITORY.get(cc);
                Id countryTerrId = terrByDev.get(terrDev);
                if (countryTerrId == null) continue;
                Set<Id> allTerrs = parentToAllChildren.get(countryTerrId);
                if (allTerrs == null) continue;

                for (Id terrId : allTerrs) {
                    Id groupId = terrToGroup.get(terrId);
                    if (groupId != null) {
                        SObject share = shareType.newSObject();
                        share.put('ParentId', pbiId);
                        share.put('UserOrGroupId', groupId);
                        share.put('AccessLevel', 'Read');
                        share.put('RowCause', 'Manual');
                        shares.add(share);
                    }
                }
            }
        }

        if (!shares.isEmpty()) {
            Database.SaveResult[] shareResults = Database.insert(shares, false);
            for (Integer i = 0; i < shareResults.size(); i++) {
                if (!shareResults[i].isSuccess() && errors.size() < 15) {
                    errors.add('PBI Share: ' + shareResults[i].getErrors()[0].getMessage());
                }
            }
        }
    }

    private static String buildRuleMiddle(String startDate, String endDate, String productType) {
        return '":{"rules":{"PerVisitLimit":{"starts":"' + startDate
            + '","label":"Maximum Quantity per Visit","remaining":2,"calculation":"SamplesPerVisit","strategy":"SKU","ends":"' + endDate
            + '","period":{"params":{},"type":"SampleLimitDateRangePeriod"},"quota":2},"PerPeriodLimit":{"starts":"' + startDate
            + '","label":"Maximum Quantity per Period","remaining":10,"calculation":"SamplesInPeriod","strategy":"SKU","ends":"' + endDate
            + '","period":{"params":{},"type":"SampleLimitDateRangePeriod"},"quota":10}},"info":{"annualAllocations":{},"excludedChildProducts":[],"productType":"' + productType + '"}}}';
    }

    private static Integer createTimePeriods(List<String> errors) {
        // Create two TimePeriods: current year full and next year full
        Integer currentYear = Date.today().year();
        List<String> periodNames = new List<String>{
            'Sample Period ' + currentYear,
            'Sample Period ' + (currentYear + 1)
        };
        Set<String> existingNames = new Set<String>();
        for (TimePeriod tp : [SELECT Name FROM TimePeriod WHERE Name IN :periodNames]) {
            existingNames.add(tp.Name);
        }

        List<TimePeriod> periods = new List<TimePeriod>();
        if (!existingNames.contains(periodNames[0])) {
            periods.add(new TimePeriod(
                Name = periodNames[0],
                StartDate = Datetime.newInstance(currentYear, 1, 1),
                EndDate = Datetime.newInstance(currentYear, 12, 31)
            ));
        }
        if (!existingNames.contains(periodNames[1])) {
            periods.add(new TimePeriod(
                Name = periodNames[1],
                StartDate = Datetime.newInstance(currentYear + 1, 1, 1),
                EndDate = Datetime.newInstance(currentYear + 1, 12, 31)
            ));
        }

        Integer created = 0;
        if (!periods.isEmpty()) {
            Database.SaveResult[] results = Database.insert(periods, false);
            for (Database.SaveResult r : results) {
                if (r.isSuccess()) {
                    created++;
                } else if (errors.size() < 15) {
                    errors.add('TimePeriod: ' + r.getErrors()[0].getMessage());
                }
            }
        }
        return created;
    }

    public class ProviderSampleLimitJob implements Queueable {
        private Set<Id> sampleMpIds;

        public ProviderSampleLimitJob(Set<Id> sampleMpIds) {
            this.sampleMpIds = sampleMpIds;
        }

        public void execute(QueueableContext ctx) {
            Schema.SObjectType pslType = Schema.getGlobalDescribe().get('ProviderSampleLimit');
            if (pslType == null) return;

            Id templateId = null;
            String templateDevName = 'lsc4ce_GenericTemplate';
            for (SObject t : Database.query(
                'SELECT Id FROM ProviderSampleLimitTemplate WHERE DeveloperName = \'' + templateDevName + '\' AND IsActive = true LIMIT 1'
            )) {
                templateId = t.Id;
            }
            if (templateId == null) return;

            List<Account> hcpAccounts = [
                SELECT Id FROM Account
                WHERE IsPersonAccount = true
                AND Id IN (SELECT AccountId FROM HealthcareProvider)
            ];
            if (hcpAccounts.isEmpty()) return;

            Set<Id> hcpAccountIds = new Set<Id>();
            for (Account a : hcpAccounts) { hcpAccountIds.add(a.Id); }

            Set<Id> sampleMpIds = this.sampleMpIds;
            Set<Id> brandMpIds = new Set<Id>();
            Set<Id> brandAndProductMpIds = new Set<Id>();
            brandAndProductMpIds.addAll(sampleMpIds);
            for (SObject mp : Database.query(
                'SELECT Id, Type FROM LifeSciMarketableProduct WHERE Id IN :sampleMpIds OR (Name LIKE \'Immunexis (%)\' AND Type = \'Brand\')'
            )) {
                brandAndProductMpIds.add(mp.Id);
                if ((String) mp.get('Type') == 'Brand') {
                    brandMpIds.add(mp.Id);
                }
            }

            Set<String> existingPslKeys = new Set<String>();
            for (SObject psl : Database.query(
                'SELECT AccountId, ProductId FROM ProviderSampleLimit WHERE AccountId IN :hcpAccountIds AND ProductId IN :brandAndProductMpIds'
            )) {
                existingPslKeys.add((Id) psl.get('AccountId') + ':' + (Id) psl.get('ProductId'));
            }

            Integer currentYear = Date.today().year();
            String startDate = currentYear + '-01-01';
            String endDate = currentYear + '-12-31';
            String rulePrefix = '{"products":{"';
            String brandRuleMid = buildRuleMiddle(startDate, endDate, 'Brand');
            String productRuleMid = buildRuleMiddle(startDate, endDate, 'LSSampleProduct');
            String ruleSuffix = ',"template":{"operations":[{"operation":"RULE","rule":"PerVisitLimit"},{"operation":"RULE","rule":"PerPeriodLimit"},{"operation":"AND"}],"name":"' + templateDevName + '","label":"Generic Template","blockType":"Error"}}';

            List<SObject> batch = new List<SObject>();
            for (Account acct : hcpAccounts) {
                for (Id mpId : brandAndProductMpIds) {
                    if (existingPslKeys.contains(acct.Id + ':' + mpId)) continue;
                    String mid = brandMpIds.contains(mpId) ? brandRuleMid : productRuleMid;
                    SObject psl = pslType.newSObject();
                    psl.put('AccountId', acct.Id);
                    psl.put('ProductId', mpId);
                    psl.put('PrvdSampleLimitTemplateId', templateId);
                    psl.put('Rule', rulePrefix + mpId + mid + ruleSuffix);
                    batch.add(psl);
                }
                if (batch.size() >= 200) {
                    Database.insert(batch, false);
                    batch = new List<SObject>();
                }
            }
            if (!batch.isEmpty()) {
                Database.insert(batch, false);
            }
        }
    }

    private static final Map<String, Map<String, String>> INVENTORY_ADDRESSES = new Map<String, Map<String, String>>{
        'US' => new Map<String, String>{ 'Street' => '100 Park Avenue', 'City' => 'New York', 'PostalCode' => '10017', 'StateCode' => 'NY' },
        'GB' => new Map<String, String>{ 'Street' => '42 Harley Street', 'City' => 'London', 'PostalCode' => 'W1G 9PR' },
        'FR' => new Map<String, String>{ 'Street' => '55 Rue du Faubourg Saint-Honore', 'City' => 'Paris', 'PostalCode' => '75008' },
        'DE' => new Map<String, String>{ 'Street' => 'Friedrichstrasse 76', 'City' => 'Berlin', 'PostalCode' => '10117' },
        'IT' => new Map<String, String>{ 'Street' => 'Via Montenapoleone 8', 'City' => 'Milan', 'PostalCode' => '20121' },
        'ES' => new Map<String, String>{ 'Street' => 'Paseo de la Castellana 89', 'City' => 'Madrid', 'PostalCode' => '28046' },
        'JP' => new Map<String, String>{ 'Street' => '1-1 Marunouchi', 'City' => 'Tokyo', 'PostalCode' => '100-0005', 'StateCode' => '13' },
        'KR' => new Map<String, String>{ 'Street' => '231 Teheran-ro', 'City' => 'Seoul', 'PostalCode' => '06142' },
        'BR' => new Map<String, String>{ 'Street' => '1578 Avenida Paulista', 'City' => 'Sao Paulo', 'PostalCode' => '01310-200', 'StateCode' => 'SP' },
        'MX' => new Map<String, String>{ 'Street' => 'Av. Paseo de la Reforma 250', 'City' => 'Mexico City', 'PostalCode' => '06600' },
        'AR' => new Map<String, String>{ 'Street' => 'Av. 9 de Julio 1925', 'City' => 'Buenos Aires', 'PostalCode' => 'C1073ABA' }
    };

    private static void createUserInventoryLocations(List<String> errors) {
        List<UserTerritory2Association> utas = [
            SELECT UserId, User.Name, Territory2.DeveloperName FROM UserTerritory2Association
            WHERE Territory2.DeveloperName IN :COUNTRY_TERRITORY.values()
        ];
        Set<Id> repIds = new Set<Id>();
        Map<Id, String> repNames = new Map<Id, String>();
        Map<Id, String> repCountry = new Map<Id, String>();
        for (UserTerritory2Association uta : utas) {
            repIds.add(uta.UserId);
            repNames.put(uta.UserId, uta.User.Name);
            for (String cc : COUNTRY_TERRITORY.keySet()) {
                if (COUNTRY_TERRITORY.get(cc) == uta.Territory2.DeveloperName) {
                    repCountry.put(uta.UserId, cc);
                    break;
                }
            }
        }

        Map<Id, Id> repToLocId = new Map<Id, Id>();
        Set<Id> locsWithAddress = new Set<Id>();
        for (Schema.Location loc : [
            SELECT PrimaryUserId, Id, (SELECT Id FROM Addresses LIMIT 1)
            FROM Location
            WHERE PrimaryUserId IN :repIds AND IsInventoryLocation = true AND LocationType = 'User Inventory'
        ]) {
            repToLocId.put(loc.PrimaryUserId, loc.Id);
            if (loc.Addresses != null && !loc.Addresses.isEmpty()) {
                locsWithAddress.add(loc.Id);
            }
        }

        List<Schema.Location> locs = new List<Schema.Location>();
        List<Id> newLocRepIds = new List<Id>();
        for (Id repId : repIds) {
            if (!repToLocId.containsKey(repId)) {
                Schema.Location loc = new Schema.Location();
                loc.Name = repNames.get(repId) + ' Inventory';
                loc.LocationType = 'User Inventory';
                loc.IsInventoryLocation = true;
                loc.PrimaryUserId = repId;
                locs.add(loc);
                newLocRepIds.add(repId);
            }
        }

        if (!locs.isEmpty()) {
            Database.SaveResult[] results = Database.insert(locs, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    repToLocId.put(newLocRepIds[i], results[i].getId());
                } else if (errors.size() < 15) {
                    errors.add('Location: ' + results[i].getErrors()[0].getMessage());
                }
            }
        }

        List<Schema.Address> addrs = new List<Schema.Address>();
        for (Id repId : repToLocId.keySet()) {
            Id locId = repToLocId.get(repId);
            if (locsWithAddress.contains(locId)) continue;
            String cc = repCountry.get(repId);
            if (cc == null || !INVENTORY_ADDRESSES.containsKey(cc)) continue;
            Map<String, String> ai = INVENTORY_ADDRESSES.get(cc);
            Schema.Address addr = new Schema.Address();
            addr.ParentId = locId;
            addr.Street = ai.get('Street');
            addr.City = ai.get('City');
            addr.PostalCode = ai.get('PostalCode');
            addr.CountryCode = cc;
            if (ai.containsKey('StateCode')) {
                addr.StateCode = ai.get('StateCode');
            }
            addr.LocationType = 'User Inventory';
            addrs.add(addr);
        }

        if (!addrs.isEmpty()) {
            Database.SaveResult[] results = Database.insert(addrs, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess() && errors.size() < 15) {
                    errors.add('Address: ' + results[i].getErrors()[0].getMessage());
                }
            }
        }
    }
}
