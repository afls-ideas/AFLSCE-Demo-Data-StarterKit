public without sharing class DemoActivityPlanController {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';

    private static final List<String> BRAND_NAMES = new List<String>{
        'Immunexis', 'Immunonco'
    };

    @AuraEnabled(cacheable=true)
    public static String getStatus() {
        try {
            List<String> parts = new List<String>();
            String escaped = String.escapeSingleQuotes(DEMO_TAG);

            Integer tpCount = Database.countQuery(
                'SELECT COUNT() FROM TimePeriod WHERE Name LIKE \'%' + escaped + '%\'');
            parts.add('Time Periods: ' + tpCount);

            Integer apCount = Database.countQuery(
                'SELECT COUNT() FROM ActivityPlan WHERE SourceSystemName = \'' + escaped + '\'');
            parts.add('Activity Plans: ' + apCount);

            Integer aptCount = Database.countQuery(
                'SELECT COUNT() FROM ActivityPlanTerritory WHERE ActivityPlan.SourceSystemName = \'' + escaped + '\'');
            parts.add('Activity Plan Territories: ' + aptCount);

            Integer pagCount = Database.countQuery(
                'SELECT COUNT() FROM ProviderActivityGoal WHERE SourceSystemName = \'' + escaped + '\'');
            parts.add('Provider Activity Goals: ' + pagCount);

            Integer pagmCount = Database.countQuery(
                'SELECT COUNT() FROM ProviderActivityGoalMeasure WHERE SourceSystemName = \'' + escaped + '\'');
            parts.add('Goal Measures: ' + pagmCount);

            return String.join(parts, ', ');
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String createProviderActivityPlans() {
        List<String> details = new List<String>();
        List<String> errors = new List<String>();

        try {
            String escaped = String.escapeSingleQuotes(DEMO_TAG);
            Integer existingCount = Database.countQuery(
                'SELECT COUNT() FROM ActivityPlan WHERE SourceSystemName = \'' + escaped + '\'');
            if (existingCount > 0) {
                throw new AuraHandledException(
                    'Provider Activity Plans already exist (' + existingCount + '). Delete first to re-create.');
            }

            details.add('HEADER:Step 1 — Gathering territory and account data');
            Map<Id, TerritoryInfo> terrInfoMap = gatherTerritoryData(details, errors);
            if (terrInfoMap.isEmpty()) {
                throw new AuraHandledException('No territories with assigned users and demo accounts found.');
            }

            details.add('HEADER:Step 2 — Creating Time Period');
            Date startDate = Date.newInstance(Date.today().year(), 1, 1);
            Date endDate = Date.newInstance(Date.today().year(), 12, 31);
            Id timePeriodId = ensureTimePeriod(startDate, endDate, details);

            details.add('HEADER:Step 3 — Loading Activity Measure Types');
            List<SObject> visitMeasureTypes = Database.query(
                'SELECT Id, DeveloperName, MasterLabel, DisplayOrder FROM ProviderActivityMeasureType ' +
                'WHERE IsActive = true AND ActivityObject = \'Visit\' ORDER BY DisplayOrder');
            if (visitMeasureTypes.isEmpty()) {
                throw new AuraHandledException('No active Visit-level ProviderActivityMeasureType records found.');
            }
            details.add('SUCCESS:Found ' + visitMeasureTypes.size() + ' visit measure types: ' +
                buildMeasureTypeLabels(visitMeasureTypes));

            List<SObject> productMeasureTypes = Database.query(
                'SELECT Id, DeveloperName, MasterLabel, DisplayOrder FROM ProviderActivityMeasureType ' +
                'WHERE IsActive = true AND ActivityObject = \'ProviderVisitProdDetailing\' ORDER BY DisplayOrder');
            details.add('SUCCESS:Found ' + productMeasureTypes.size() + ' product measure types: ' +
                buildMeasureTypeLabels(productMeasureTypes));

            details.add('HEADER:Step 4 — Loading brand products by country');
            Map<String, List<Id>> countryToBrandIds = loadBrandsByCountry(details, errors);

            details.add('HEADER:Step 5 — Creating Activity Plans');
            Map<Id, Id> terrToActivityPlan = createActivityPlans(terrInfoMap, timePeriodId, details, errors);

            details.add('HEADER:Step 6 — Creating Provider Activity Goals');
            Boolean hasProducts = !productMeasureTypes.isEmpty() && !countryToBrandIds.isEmpty();
            Map<Id, List<Id>> terrToGoalIds = createProviderActivityGoals(
                terrInfoMap, terrToActivityPlan, hasProducts, details, errors);

            details.add('HEADER:Step 7 — Creating Visit Goal Measures');
            Integer visitMeasureCount = createGoalMeasures(terrToGoalIds, visitMeasureTypes, false, details, errors);

            Integer productMeasureCount = 0;
            if (hasProducts) {
                details.add('HEADER:Step 8 — Creating Product Goal Measures');
                productMeasureCount = createProductGoalMeasures(
                    terrInfoMap, terrToGoalIds, productMeasureTypes, countryToBrandIds, details, errors);
            }

            details.add('HEADER:Step ' + (hasProducts ? '9' : '8') + ' — Activating Activity Plans');
            activateActivityPlans(terrToActivityPlan, details, errors);

            Integer totalMeasures = visitMeasureCount + productMeasureCount;
            String summary = errors.isEmpty()
                ? 'Created ' + terrToActivityPlan.size() + ' activity plans, '
                    + countGoals(terrToGoalIds) + ' goals, '
                    + totalMeasures + ' measures (' + visitMeasureCount + ' visit + ' + productMeasureCount + ' product).'
                : 'Completed with ' + errors.size() + ' error(s).';
            Map<String, Object> result = new Map<String, Object>{
                'summary' => summary,
                'details' => details,
                'errors' => errors
            };
            return JSON.serialize(result);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    @AuraEnabled
    public static String deleteProviderActivityPlans() {
        try {
            Integer deleted = 0;
            String escaped = String.escapeSingleQuotes(DEMO_TAG);

            List<SObject> measures = Database.query(
                'SELECT Id FROM ProviderActivityGoalMeasure WHERE SourceSystemName = \'' + escaped + '\' LIMIT 9500');
            if (!measures.isEmpty()) {
                Database.delete(measures, false);
                deleted += measures.size();
            }

            List<SObject> goals = Database.query(
                'SELECT Id FROM ProviderActivityGoal WHERE SourceSystemName = \'' + escaped + '\' LIMIT 9500');
            if (!goals.isEmpty()) {
                Database.delete(goals, false);
                deleted += goals.size();
            }

            List<SObject> plans = Database.query(
                'SELECT Id FROM ActivityPlan WHERE SourceSystemName = \'' + escaped + '\' LIMIT 9500');
            if (!plans.isEmpty()) {
                Database.delete(plans, false);
                deleted += plans.size();
            }

            List<SObject> tps = Database.query(
                'SELECT Id FROM TimePeriod WHERE Name LIKE \'%' + escaped + '%\' LIMIT 100');
            if (!tps.isEmpty()) {
                Database.delete(tps, false);
                deleted += tps.size();
            }

            Integer remaining = Database.countQuery(
                'SELECT COUNT() FROM ActivityPlan WHERE SourceSystemName = \'' + escaped + '\'')
                + Database.countQuery(
                'SELECT COUNT() FROM ProviderActivityGoal WHERE SourceSystemName = \'' + escaped + '\'');
            String msg = 'Deleted ' + deleted + ' records.';
            if (remaining > 0) {
                msg += ' More records remain — click delete again.';
            }
            return msg;
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String clearActivityPlanJobStatus() {
        try {
            List<SObject> records = Database.query(
                'SELECT Id, Name, TextValue FROM LifeSciMetadataFieldValue WHERE Name IN (\'JobStatus\', \'JobId\')');
            if (records.isEmpty()) {
                return 'No JobStatus/JobId records found.';
            }
            Integer updated = 0;
            for (SObject rec : records) {
                String name = (String) rec.get('Name');
                String val = (String) rec.get('TextValue');
                if (name == 'JobStatus' && val != null) {
                    rec.put('TextValue', null);
                    updated++;
                } else if (name == 'JobId' && val != null) {
                    rec.put('TextValue', null);
                    updated++;
                }
            }
            if (updated > 0) {
                Database.update(records, false);
                return 'Cleared ' + updated + ' record(s) (JobStatus + JobId reset to null).';
            }
            return 'No stuck jobs found — JobStatus and JobId are already clear.';
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    // ── Data gathering ──

    private class TerritoryInfo {
        public Id territoryId;
        public String territoryName;
        public String countryCode;
        public Id ownerId;
        public List<Id> hcpAccountIds;

        public TerritoryInfo() {
            hcpAccountIds = new List<Id>();
        }
    }

    private static Map<Id, TerritoryInfo> gatherTerritoryData(
            List<String> details, List<String> errors) {

        Set<Id> leafTerrIds = getLeafTerritoryIds();
        details.add('Found ' + leafTerrIds.size() + ' leaf territories');

        Map<Id, Id> terrToOwner = new Map<Id, Id>();
        for (UserTerritory2Association uta : [
            SELECT Territory2Id, UserId FROM UserTerritory2Association
            WHERE Territory2Id IN :leafTerrIds ORDER BY Territory2Id
        ]) {
            if (!terrToOwner.containsKey(uta.Territory2Id)) {
                terrToOwner.put(uta.Territory2Id, uta.UserId);
            }
        }

        Set<Id> demoHcpIds = new Set<Id>();
        for (Account a : [SELECT Id FROM Account
                WHERE Site = :DEMO_TAG AND IsPersonAccount = true]) {
            demoHcpIds.add(a.Id);
        }
        details.add('Found ' + demoHcpIds.size() + ' demo HCP accounts');

        Map<Id, TerritoryInfo> terrInfoMap = new Map<Id, TerritoryInfo>();
        Map<Id, String> terrNames = new Map<Id, String>();
        for (Territory2 t : [SELECT Id, Name FROM Territory2 WHERE Id IN :leafTerrIds]) {
            terrNames.put(t.Id, t.Name);
        }

        for (ObjectTerritory2Association ota : [
            SELECT ObjectId, Territory2Id FROM ObjectTerritory2Association
            WHERE Territory2Id IN :leafTerrIds AND ObjectId IN :demoHcpIds
        ]) {
            TerritoryInfo ti = terrInfoMap.get(ota.Territory2Id);
            if (ti == null) {
                ti = new TerritoryInfo();
                ti.territoryId = ota.Territory2Id;
                ti.territoryName = terrNames.get(ota.Territory2Id);
                ti.countryCode = extractCountryCode(ti.territoryName);
                ti.ownerId = terrToOwner.get(ota.Territory2Id);
                terrInfoMap.put(ota.Territory2Id, ti);
            }
            ti.hcpAccountIds.add(ota.ObjectId);
        }

        Integer noOwner = 0;
        for (Id tId : new List<Id>(terrInfoMap.keySet())) {
            if (terrInfoMap.get(tId).ownerId == null) {
                terrInfoMap.remove(tId);
                noOwner++;
            }
        }
        if (noOwner > 0) {
            details.add('WARNING:Skipped ' + noOwner + ' territories with no assigned user');
        }

        Integer totalHcps = 0;
        for (TerritoryInfo ti : terrInfoMap.values()) {
            totalHcps += ti.hcpAccountIds.size();
        }
        details.add('SUCCESS:' + terrInfoMap.size() + ' territories with ' + totalHcps + ' HCP accounts');
        return terrInfoMap;
    }

    private static String extractCountryCode(String territoryName) {
        if (String.isBlank(territoryName)) return null;
        Integer dash = territoryName.indexOf('-');
        if (dash > 0) return territoryName.substring(0, dash);
        return null;
    }

    private static Set<Id> getLeafTerritoryIds() {
        List<Territory2> allTerrs = [
            SELECT Id, ParentTerritory2Id FROM Territory2
            WHERE Territory2Model.State = 'Active'
        ];
        Set<Id> parentIds = new Set<Id>();
        for (Territory2 t : allTerrs) {
            if (t.ParentTerritory2Id != null) parentIds.add(t.ParentTerritory2Id);
        }
        Set<Id> leafIds = new Set<Id>();
        for (Territory2 t : allTerrs) {
            if (!parentIds.contains(t.Id)) leafIds.add(t.Id);
        }
        return leafIds;
    }

    // ── Brand Products ──

    private static Map<String, List<Id>> loadBrandsByCountry(
            List<String> details, List<String> errors) {

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

        Integer totalBrands = 0;
        for (List<Id> ids : countryToBrandIds.values()) {
            totalBrands += ids.size();
        }
        details.add('SUCCESS:Found ' + totalBrands + ' country brand products across ' +
            countryToBrandIds.size() + ' countries');
        return countryToBrandIds;
    }

    // ── TimePeriod ──

    private static Id ensureTimePeriod(Date startDate, Date endDate, List<String> details) {
        String tpName = Date.today().year() + ' Activity Plan (' + DEMO_TAG + ')';
        Datetime startDt = Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
        Datetime endDt = Datetime.newInstance(endDate, Time.newInstance(23, 59, 59, 0));

        List<SObject> existing = Database.query(
            'SELECT Id FROM TimePeriod WHERE Name = \'' + String.escapeSingleQuotes(tpName) + '\' LIMIT 1');
        if (!existing.isEmpty()) {
            details.add('SUCCESS:Reusing existing TimePeriod: ' + tpName);
            return existing[0].Id;
        }

        Schema.SObjectType tpType = Schema.getGlobalDescribe().get('TimePeriod');
        SObject tp = tpType.newSObject();
        tp.put('Name', tpName);
        tp.put('StartDate', startDt);
        tp.put('EndDate', endDt);
        insert tp;
        details.add('SUCCESS:Created TimePeriod: ' + tpName + ' (Jan 1 – Dec 31 ' + Date.today().year() + ')');
        return tp.Id;
    }

    // ── ActivityPlan + ActivityPlanTerritory ──

    private static Map<Id, Id> createActivityPlans(Map<Id, TerritoryInfo> terrInfoMap,
            Id timePeriodId, List<String> details, List<String> errors) {

        Schema.SObjectType apType = Schema.getGlobalDescribe().get('ActivityPlan');
        List<SObject> plans = new List<SObject>();
        List<Id> planTerrIds = new List<Id>();

        for (TerritoryInfo ti : terrInfoMap.values()) {
            SObject ap = apType.newSObject();
            ap.put('Name', ti.territoryName + ' ' + Date.today().year());
            ap.put('TimePeriodId', timePeriodId);
            ap.put('Type', 'AccountGoal');
            ap.put('UsageType', 'ProviderPlanCycle');
            ap.put('Status', 'InProgress');
            ap.put('IsActive', false);
            ap.put('OwnerId', ti.ownerId);
            ap.put('TerritoryList', (String) ti.territoryId);
            ap.put('ActivityChgRvwThresholdPct', 50);
            ap.put('TotalActvtyChgThresholdPct', 50);
            ap.put('TotalAcctChgThresholdPct', 50);
            ap.put('SourceSystemName', DEMO_TAG);
            plans.add(ap);
            planTerrIds.add(ti.territoryId);
        }

        Map<Id, Id> terrToActivityPlan = new Map<Id, Id>();
        Database.SaveResult[] results = Database.insert(plans, false);
        Integer created = 0;
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                terrToActivityPlan.put(planTerrIds[i], results[i].getId());
                created++;
            } else if (errors.size() < 20) {
                errors.add('ActivityPlan: ' + results[i].getErrors()[0].getMessage());
            }
        }
        details.add('SUCCESS:Created ' + created + ' activity plans');

        Schema.SObjectType aptType = Schema.getGlobalDescribe().get('ActivityPlanTerritory');
        List<SObject> apts = new List<SObject>();
        for (Id terrId : terrToActivityPlan.keySet()) {
            SObject apt = aptType.newSObject();
            apt.put('ActivityPlanId', terrToActivityPlan.get(terrId));
            apt.put('TerritoryId', terrId);
            apts.add(apt);
        }
        if (!apts.isEmpty()) {
            Database.SaveResult[] aptResults = Database.insert(apts, false);
            Integer aptCreated = 0;
            for (Database.SaveResult sr : aptResults) {
                if (sr.isSuccess()) aptCreated++;
            }
            details.add('SUCCESS:Created ' + aptCreated + ' activity plan territory links');
        }

        return terrToActivityPlan;
    }

    // ── ProviderActivityGoal ──

    private static Map<Id, List<Id>> createProviderActivityGoals(
            Map<Id, TerritoryInfo> terrInfoMap,
            Map<Id, Id> terrToActivityPlan,
            Boolean hasProducts,
            List<String> details, List<String> errors) {

        Schema.SObjectType pagType = Schema.getGlobalDescribe().get('ProviderActivityGoal');
        List<SObject> goals = new List<SObject>();
        List<Id> goalTerrIds = new List<Id>();

        List<Integer> goalValues = new List<Integer>{ 60, 40, 30, 20, 15, 10, 10, 8 };

        for (Id terrId : terrToActivityPlan.keySet()) {
            TerritoryInfo ti = terrInfoMap.get(terrId);
            Id activityPlanId = terrToActivityPlan.get(terrId);
            if (ti == null || activityPlanId == null) continue;

            for (Integer i = 0; i < ti.hcpAccountIds.size(); i++) {
                Integer goalVal = i < goalValues.size() ? goalValues[i] : 8;
                Integer nonProdGoal = hasProducts ? (Integer) Math.round(goalVal * 0.6) : goalVal;
                Integer prodGoal = hasProducts ? goalVal - nonProdGoal : 0;

                SObject pag = pagType.newSObject();
                pag.put('ActivityPlanId', activityPlanId);
                pag.put('AccountId', ti.hcpAccountIds[i]);
                pag.put('OverallGoal', goalVal);
                pag.put('NonProductGoal', nonProdGoal);
                pag.put('ProductLevelGoal', prodGoal);
                pag.put('SourceSystemName', DEMO_TAG);
                goals.add(pag);
                goalTerrIds.add(terrId);
            }
        }

        Map<Id, List<Id>> terrToGoalIds = new Map<Id, List<Id>>();
        Database.SaveResult[] results = Database.insert(goals, false);
        Integer created = 0;
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                Id terrId = goalTerrIds[i];
                if (!terrToGoalIds.containsKey(terrId)) {
                    terrToGoalIds.put(terrId, new List<Id>());
                }
                terrToGoalIds.get(terrId).add(results[i].getId());
                created++;
            } else if (errors.size() < 20) {
                errors.add('ProviderActivityGoal: ' + results[i].getErrors()[0].getMessage());
            }
        }
        details.add('SUCCESS:Created ' + created + ' provider activity goals');
        return terrToGoalIds;
    }

    // ── Visit-level GoalMeasures ──

    private static Integer createGoalMeasures(
            Map<Id, List<Id>> terrToGoalIds,
            List<SObject> measureTypes,
            Boolean isProduct,
            List<String> details, List<String> errors) {

        Schema.SObjectType pagmType = Schema.getGlobalDescribe().get('ProviderActivityGoalMeasure');
        if (pagmType == null) {
            errors.add('ProviderActivityGoalMeasure object not found in schema');
            return 0;
        }

        Set<Id> allGoalIds = new Set<Id>();
        for (List<Id> ids : terrToGoalIds.values()) {
            allGoalIds.addAll(ids);
        }
        String goalField = isProduct ? 'ProductLevelGoal' : 'NonProductGoal';
        Map<Id, Decimal> goalMap = new Map<Id, Decimal>();
        for (SObject pag : Database.query(
            'SELECT Id, ' + goalField + ' FROM ProviderActivityGoal WHERE Id IN :allGoalIds'
        )) {
            goalMap.put(pag.Id, (Decimal) pag.get(goalField));
        }

        List<Decimal> splits;
        if (measureTypes.size() == 3) {
            splits = new List<Decimal>{ 0.45, 0.35, 0.20 };
        } else if (measureTypes.size() == 2) {
            splits = new List<Decimal>{ 0.60, 0.40 };
        } else {
            splits = new List<Decimal>();
            for (Integer i = 0; i < measureTypes.size(); i++) {
                splits.add(1.0 / measureTypes.size());
            }
        }

        List<SObject> measures = new List<SObject>();
        for (List<Id> goalIds : terrToGoalIds.values()) {
            for (Id goalId : goalIds) {
                Decimal goalVal = goalMap.get(goalId);
                if (goalVal == null) goalVal = 0;

                for (Integer m = 0; m < measureTypes.size(); m++) {
                    Integer measureGoal = (Integer) Math.round(goalVal * splits[m]);

                    SObject pagm = pagmType.newSObject();
                    pagm.put('ProviderActivityGoalId', goalId);
                    pagm.put('ProviderActivityMeasureTypeId', measureTypes[m].Id);
                    pagm.put('OverallGoal', measureGoal);
                    pagm.put('Type', 'Goal');
                    pagm.put('SourceSystemName', DEMO_TAG);
                    measures.add(pagm);
                }
            }
        }

        Database.SaveResult[] results = Database.insert(measures, false);
        Integer created = 0;
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                created++;
            } else if (errors.size() < 20) {
                errors.add('GoalMeasure: ' + sr.getErrors()[0].getMessage());
            }
        }
        String label = isProduct ? 'product' : 'visit';
        details.add('SUCCESS:Created ' + created + ' ' + label + ' goal measures');
        return created;
    }

    // ── Product-level GoalMeasures ──

    private static Integer createProductGoalMeasures(
            Map<Id, TerritoryInfo> terrInfoMap,
            Map<Id, List<Id>> terrToGoalIds,
            List<SObject> productMeasureTypes,
            Map<String, List<Id>> countryToBrandIds,
            List<String> details, List<String> errors) {

        Schema.SObjectType pagmType = Schema.getGlobalDescribe().get('ProviderActivityGoalMeasure');
        if (pagmType == null) {
            errors.add('ProviderActivityGoalMeasure object not found in schema');
            return 0;
        }

        Set<Id> allGoalIds = new Set<Id>();
        for (List<Id> ids : terrToGoalIds.values()) {
            allGoalIds.addAll(ids);
        }
        Map<Id, Decimal> goalProdMap = new Map<Id, Decimal>();
        for (SObject pag : Database.query(
            'SELECT Id, ProductLevelGoal FROM ProviderActivityGoal WHERE Id IN :allGoalIds'
        )) {
            goalProdMap.put(pag.Id, (Decimal) pag.get('ProductLevelGoal'));
        }

        List<Decimal> splits;
        if (productMeasureTypes.size() == 3) {
            splits = new List<Decimal>{ 0.45, 0.35, 0.20 };
        } else if (productMeasureTypes.size() == 2) {
            splits = new List<Decimal>{ 0.60, 0.40 };
        } else {
            splits = new List<Decimal>();
            for (Integer i = 0; i < productMeasureTypes.size(); i++) {
                splits.add(1.0 / productMeasureTypes.size());
            }
        }

        List<SObject> measures = new List<SObject>();
        for (Id terrId : terrToGoalIds.keySet()) {
            TerritoryInfo ti = terrInfoMap.get(terrId);
            if (ti == null || ti.countryCode == null) continue;

            List<Id> brandIds = countryToBrandIds.get(ti.countryCode);
            if (brandIds == null || brandIds.isEmpty()) continue;

            String productListValue = ';' + String.join(brandIds, ';') + ';';

            for (Id goalId : terrToGoalIds.get(terrId)) {
                Decimal prodGoal = goalProdMap.get(goalId);
                if (prodGoal == null || prodGoal == 0) continue;

                for (Integer m = 0; m < productMeasureTypes.size(); m++) {
                    Integer measureGoal = (Integer) Math.round(prodGoal * splits[m]);

                    SObject pagm = pagmType.newSObject();
                    pagm.put('ProviderActivityGoalId', goalId);
                    pagm.put('ProviderActivityMeasureTypeId', productMeasureTypes[m].Id);
                    pagm.put('OverallGoal', measureGoal);
                    pagm.put('ProductList', productListValue);
                    pagm.put('Type', 'Goal');
                    pagm.put('SourceSystemName', DEMO_TAG);
                    measures.add(pagm);
                }
            }
        }

        Database.SaveResult[] results = Database.insert(measures, false);
        Integer created = 0;
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                created++;
            } else if (errors.size() < 20) {
                errors.add('ProductGoalMeasure: ' + sr.getErrors()[0].getMessage());
            }
        }
        details.add('SUCCESS:Created ' + created + ' product goal measures across ' +
            countryToBrandIds.size() + ' countries');
        return created;
    }

    // ── Activate ──

    private static void activateActivityPlans(Map<Id, Id> terrToActivityPlan,
            List<String> details, List<String> errors) {

        Schema.SObjectType apType = Schema.getGlobalDescribe().get('ActivityPlan');
        List<SObject> toUpdate = new List<SObject>();
        for (Id apId : terrToActivityPlan.values()) {
            SObject upd = apType.newSObject(apId);
            upd.put('IsActive', true);
            upd.put('Status', 'Submitted');
            toUpdate.add(upd);
        }
        Database.SaveResult[] results = Database.update(toUpdate, false);
        Integer activated = 0;
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                activated++;
            } else if (errors.size() < 20) {
                errors.add('Activate: ' + sr.getErrors()[0].getMessage());
            }
        }
        details.add('SUCCESS:Activated ' + activated + ' activity plans (Status=Submitted)');
    }

    // ── Helpers ──

    private static String buildMeasureTypeLabels(List<SObject> types) {
        List<String> labels = new List<String>();
        for (SObject t : types) {
            labels.add((String) t.get('MasterLabel'));
        }
        return String.join(labels, ', ');
    }

    private static Integer countGoals(Map<Id, List<Id>> terrToGoalIds) {
        Integer count = 0;
        for (List<Id> ids : terrToGoalIds.values()) {
            count += ids.size();
        }
        return count;
    }
}
