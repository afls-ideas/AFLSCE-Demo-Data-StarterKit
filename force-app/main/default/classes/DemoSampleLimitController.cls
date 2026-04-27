public without sharing class DemoSampleLimitController {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';
    private static final Integer PER_VISIT_QUOTA = 2;
    private static final Integer PER_PERIOD_QUOTA = 10;
    private static final String TEMPLATE_DEV_NAME = 'lsc4ce_GenericTemplate';
    private static final Integer BATCH_SIZE = 220;

    private static final Map<String, String> COUNTRY_TERRITORY = new Map<String, String>{
        'US' => 'US_COUNTRY', 'GB' => 'GB_COUNTRY', 'FR' => 'FR_COUNTRY',
        'DE' => 'DE_COUNTRY', 'IT' => 'IT_COUNTRY', 'ES' => 'ES_COUNTRY',
        'JP' => 'JP_COUNTRY', 'KR' => 'KR_COUNTRY', 'BR' => 'BR_COUNTRY',
        'MX' => 'MX_COUNTRY', 'AR' => 'AR_COUNTRY'
    };

    @AuraEnabled(cacheable=true)
    public static String getStatus() {
        try {
            List<String> parts = new List<String>();

            Integer currentYear = Date.today().year();
            String periodName = 'Sample Period ' + currentYear;
            Integer tpCount = [SELECT COUNT() FROM TimePeriod WHERE Name = :periodName];
            parts.add('TimePeriod (' + currentYear + '): ' + (tpCount > 0 ? 'Yes' : 'No'));

            if (!objectExists('ProviderSampleLimit') || !objectExists('LifeSciMarketableProduct')) {
                parts.add('ProviderSampleLimit: object not available');
                return String.join(parts, ', ');
            }

            Set<Id> allMpIds = getAllMarketableProductIds();

            if (allMpIds.isEmpty()) {
                parts.add('Sample Limits: 0 (no sample products found)');
            } else {
                Integer pslCount = Database.countQuery(
                    'SELECT COUNT() FROM ProviderSampleLimit WHERE ProductId IN :allMpIds'
                );
                parts.add('Sample Limits: ' + pslCount);
            }

            Set<Id> brandMpIds = getBrandMarketableProductIds();
            Integer assignCount = 0;
            if (!brandMpIds.isEmpty()) {
                assignCount = Database.countQuery(
                    'SELECT COUNT() FROM ProviderSmplLmtTmplAssignment WHERE ProductId IN :brandMpIds'
                );
            }
            parts.add('Template Assignments: ' + assignCount);

            Integer hcpCount = [SELECT COUNT() FROM Account
                WHERE IsPersonAccount = true AND Site = :DEMO_TAG];
            parts.add('HCPs: ' + hcpCount);
            parts.add('Expected: ' + (hcpCount * allMpIds.size()));

            return String.join(parts, ', ');
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String createSampleLimits() {
        List<String> details = new List<String>();
        List<String> errors = new List<String>();

        try {
            if (!objectExists('ProviderSampleLimit') || !objectExists('LifeSciMarketableProduct')) {
                throw new AuraHandledException('ProviderSampleLimit or LifeSciMarketableProduct object not available in this org.');
            }

            details.add('HEADER:Step 1 — TimePeriod');
            ensureTimePeriod(details, errors);

            details.add('HEADER:Step 2 — Template lookup');
            Id templateId = getTemplateId();
            if (templateId == null) {
                throw new AuraHandledException('ProviderSampleLimitTemplate "' + TEMPLATE_DEV_NAME + '" not found or inactive.');
            }
            details.add('SUCCESS:Found template: ' + TEMPLATE_DEV_NAME);

            details.add('HEADER:Step 3 — Sample marketable products');
            Set<Id> brandMpIds = getBrandMarketableProductIds();
            Set<Id> allMpIds = getAllMarketableProductIds();
            details.add('Found ' + allMpIds.size() + ' marketable products (' + brandMpIds.size() + ' Brand + ' + (allMpIds.size() - brandMpIds.size()) + ' Sample)');

            if (allMpIds.isEmpty()) {
                throw new AuraHandledException('No sample LifeSciMarketableProducts found. Run Product Alignment and Samples tabs first.');
            }

            details.add('HEADER:Step 4 — Template Assignments & Sharing');
            createTemplateAssignments(brandMpIds, templateId, details, errors);

            details.add('HEADER:Step 5 — HCP accounts');
            List<Account> hcpAccounts = [
                SELECT Id FROM Account
                WHERE IsPersonAccount = true AND Site = :DEMO_TAG
                ORDER BY Id
            ];
            details.add('Found ' + hcpAccounts.size() + ' HCP accounts');
            if (hcpAccounts.isEmpty()) {
                throw new AuraHandledException('No HCP accounts found. Run Accounts & Providers tab first.');
            }

            details.add('HEADER:Step 6 — Batch ProviderSampleLimit creation');
            Integer totalExpected = hcpAccounts.size() * allMpIds.size();
            details.add('Total expected: ' + hcpAccounts.size() + ' HCPs x ' + allMpIds.size() + ' products = ' + totalExpected + ' limits');
            details.add('Rule: ' + PER_VISIT_QUOTA + ' per visit, ' + PER_PERIOD_QUOTA + ' per period (current year)');

            try {
                Database.executeBatch(new DemoSampleLimitCreateBatch(new List<Id>(allMpIds), new List<Id>(brandMpIds), templateId), BATCH_SIZE);
                details.add('SUCCESS:Batch job started — limits will be created in batches of ' + BATCH_SIZE + ' HCPs');
            } catch (Exception be) {
                errors.add('Could not start batch: ' + be.getMessage());
            }

            String summary = errors.isEmpty()
                ? 'Sample limit creation enqueued for ' + hcpAccounts.size() + ' HCPs (' + totalExpected + ' limits). Check status in ~30 seconds.'
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
    public static String deleteSampleLimits() {
        try {
            if (!objectExists('ProviderSampleLimit') || !objectExists('LifeSciMarketableProduct')) {
                return 'ProviderSampleLimit object not available.';
            }

            Set<Id> allMpIds = getAllMarketableProductIds();
            if (allMpIds.isEmpty()) {
                List<TimePeriod> tps = [SELECT Id FROM TimePeriod WHERE Name LIKE 'Sample Period %'];
                if (!tps.isEmpty()) {
                    Database.delete(tps, false);
                }
                return 'No sample products found. Cleaned up TimePeriods only.';
            }

            Integer total = Database.countQuery(
                'SELECT COUNT() FROM ProviderSampleLimit WHERE ProductId IN :allMpIds'
            );

            if (total == 0) {
                List<TimePeriod> tps = [SELECT Id FROM TimePeriod WHERE Name LIKE 'Sample Period %'];
                Integer tpDel = 0;
                if (!tps.isEmpty()) {
                    Database.DeleteResult[] results = Database.delete(tps, false);
                    for (Database.DeleteResult r : results) { if (r.isSuccess()) tpDel++; }
                }
                return 'No sample limits to delete. Deleted ' + tpDel + ' TimePeriod(s).';
            }

            Database.executeBatch(new DemoSampleLimitDeleteBatch(new List<Id>(allMpIds)), 2000);

            return 'Delete batch started for ' + total + ' sample limit records. Check status in ~30 seconds.';
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting: ' + e.getMessage());
        }
    }

    private static void createTemplateAssignments(Set<Id> brandMpIds, Id templateId,
            List<String> details, List<String> errors) {
        Set<Id> existingProductIds = new Set<Id>();
        for (SObject a : Database.query(
            'SELECT ProductId FROM ProviderSmplLmtTmplAssignment WHERE ProductId IN :brandMpIds'
        )) {
            existingProductIds.add((Id) a.get('ProductId'));
        }

        Integer currentYear = Date.today().year();
        String ruleCondition = '{"PerPeriodLimit":{"name":"PerPeriodLimit","label":"Maximum Quantity per Period","strategy":"SKU","quota":' + PER_PERIOD_QUOTA
            + ',"calculation":"SamplesInPeriod","period":{"type":"SampleLimitDateRangePeriod","params":{"starts":"' + currentYear + '-01-01","ends":"' + currentYear + '-12-31"}}}'
            + ',"PerVisitLimit":{"name":"PerVisitLimit","label":"Maximum Quantity per Visit","strategy":"SKU","quota":' + PER_VISIT_QUOTA
            + ',"calculation":"SamplesPerVisit","period":{"type":"SampleLimitDateRangePeriod","params":{"starts":"' + currentYear + '-01-01","ends":"' + currentYear + '-12-31"}}}}';

        Schema.SObjectType assignType = Schema.getGlobalDescribe().get('ProviderSmplLmtTmplAssignment');
        if (assignType == null) {
            errors.add('ProviderSmplLmtTmplAssignment object not found');
            return;
        }

        List<SObject> newAssigns = new List<SObject>();
        for (Id mpId : brandMpIds) {
            if (existingProductIds.contains(mpId)) continue;
            SObject a = assignType.newSObject();
            a.put('ProductId', mpId);
            a.put('PrvdSampleLimitTemplateId', templateId);
            a.put('RuleCondition', ruleCondition);
            a.put('SourceSystemName', DEMO_TAG);
            newAssigns.add(a);
        }

        List<Id> createdAssignIds = new List<Id>();
        if (!newAssigns.isEmpty()) {
            Database.SaveResult[] results = Database.insert(newAssigns, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    createdAssignIds.add(results[i].getId());
                } else if (errors.size() < 15) {
                    errors.add('TemplateAssignment: ' + results[i].getErrors()[0].getMessage());
                }
            }
            details.add('SUCCESS:Created ' + createdAssignIds.size() + ' template assignments');
        } else {
            details.add('Template assignments already exist — skipping creation');
        }

        List<Id> allAssignIds = new List<Id>();
        allAssignIds.addAll(createdAssignIds);
        for (SObject a : Database.query(
            'SELECT Id FROM ProviderSmplLmtTmplAssignment WHERE ProductId IN :brandMpIds'
        )) {
            if (!createdAssignIds.contains(a.Id)) {
                allAssignIds.add(a.Id);
            }
        }

        Set<Id> repUserIds = new Set<Id>();
        for (UserTerritory2Association uta : [
            SELECT UserId FROM UserTerritory2Association
            WHERE Territory2.DeveloperName IN :COUNTRY_TERRITORY.values()
        ]) {
            repUserIds.add(uta.UserId);
        }
        details.add('Found ' + repUserIds.size() + ' rep users for sharing');

        if (allAssignIds.isEmpty() || repUserIds.isEmpty()) return;

        Schema.SObjectType shareType = Schema.getGlobalDescribe().get('ProviderSmplLmtTmplAssignmentShare');
        if (shareType == null) {
            errors.add('ProviderSmplLmtTmplAssignmentShare object not found');
            return;
        }

        Set<Id> assignIdSet = new Set<Id>(allAssignIds);
        Set<String> existingShareKeys = new Set<String>();
        for (SObject s : Database.query(
            'SELECT ParentId, UserOrGroupId FROM ProviderSmplLmtTmplAssignmentShare WHERE ParentId IN :assignIdSet AND RowCause = \'Manual\''
        )) {
            existingShareKeys.add((Id) s.get('ParentId') + ':' + (Id) s.get('UserOrGroupId'));
        }

        List<SObject> shares = new List<SObject>();
        for (Id assignId : allAssignIds) {
            for (Id userId : repUserIds) {
                if (existingShareKeys.contains(assignId + ':' + userId)) continue;
                SObject share = shareType.newSObject();
                share.put('ParentId', assignId);
                share.put('UserOrGroupId', userId);
                share.put('AccessLevel', 'Read');
                share.put('RowCause', 'Manual');
                shares.add(share);
            }
        }

        if (!shares.isEmpty()) {
            Database.SaveResult[] results = Database.insert(shares, false);
            Integer created = 0;
            for (Database.SaveResult r : results) {
                if (r.isSuccess()) { created++; }
                else if (errors.size() < 15) { errors.add('AssignmentShare: ' + r.getErrors()[0].getMessage()); }
            }
            details.add('SUCCESS:Created ' + created + ' template assignment shares');
        } else {
            details.add('All shares already exist — skipping');
        }
    }

    private static Set<Id> getAllMarketableProductIds() {
        Set<Id> ids = new Set<Id>();
        ids.addAll(getSampleMarketableProductIds());
        ids.addAll(getBrandMarketableProductIds());
        return ids;
    }

    private static Set<Id> getSampleMarketableProductIds() {
        Set<Id> ids = new Set<Id>();
        for (SObject mp : Database.query(
            'SELECT Id FROM LifeSciMarketableProduct WHERE SourceSystem = \'' + DEMO_TAG + '\' AND ProductSpecificationType = \'LSSampleProduct\''
        )) {
            ids.add(mp.Id);
        }
        return ids;
    }

    private static Set<Id> getBrandMarketableProductIds() {
        Set<Id> ids = new Set<Id>();
        for (SObject mp : Database.query(
            'SELECT Id FROM LifeSciMarketableProduct WHERE SourceSystem = \'' + DEMO_TAG + '\' AND Type = \'Brand\''
        )) {
            ids.add(mp.Id);
        }
        return ids;
    }

    private static Id getTemplateId() {
        for (SObject t : Database.query(
            'SELECT Id FROM ProviderSampleLimitTemplate WHERE DeveloperName = \'' + TEMPLATE_DEV_NAME + '\' AND IsActive = true LIMIT 1'
        )) {
            return t.Id;
        }
        return null;
    }

    private static void ensureTimePeriod(List<String> details, List<String> errors) {
        Integer currentYear = Date.today().year();
        String periodName = 'Sample Period ' + currentYear;

        List<TimePeriod> existing = [SELECT Id FROM TimePeriod WHERE Name = :periodName];
        if (!existing.isEmpty()) {
            details.add('TimePeriod "' + periodName + '" already exists — skipping');
            return;
        }

        TimePeriod tp = new TimePeriod(
            Name = periodName,
            StartDate = Datetime.newInstance(currentYear, 1, 1),
            EndDate = Datetime.newInstance(currentYear, 12, 31)
        );

        try {
            insert tp;
            details.add('SUCCESS:Created TimePeriod "' + periodName + '" (Jan 1 – Dec 31, ' + currentYear + ')');
        } catch (Exception e) {
            errors.add('TimePeriod: ' + e.getMessage());
        }
    }

    private static String buildRuleMiddle(String startDate, String endDate, String productType) {
        return '":{"rules":{"PerVisitLimit":{"starts":"' + startDate
            + '","label":"Maximum Quantity per Visit","remaining":' + PER_VISIT_QUOTA + ',"calculation":"SamplesPerVisit","strategy":"SKU","ends":"' + endDate
            + '","period":{"params":{},"type":"SampleLimitDateRangePeriod"},"quota":' + PER_VISIT_QUOTA + '},"PerPeriodLimit":{"starts":"' + startDate
            + '","label":"Maximum Quantity per Period","remaining":' + PER_PERIOD_QUOTA + ',"calculation":"SamplesInPeriod","strategy":"SKU","ends":"' + endDate
            + '","period":{"params":{},"type":"SampleLimitDateRangePeriod"},"quota":' + PER_PERIOD_QUOTA + '}},"info":{"annualAllocations":{},"excludedChildProducts":[],"productType":"' + productType + '"}}}';
    }

    private static Boolean objectExists(String objectName) {
        return Schema.getGlobalDescribe().containsKey(objectName);
    }
}
