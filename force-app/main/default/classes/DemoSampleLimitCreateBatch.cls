public without sharing class DemoSampleLimitCreateBatch implements Database.Batchable<SObject> {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';
    private static final Integer PER_VISIT_QUOTA = 2;
    private static final Integer PER_PERIOD_QUOTA = 10;
    private static final String TEMPLATE_DEV_NAME = 'lsc4ce_GenericTemplate';

    private List<Id> allMpIds;
    private List<Id> brandMpIds;
    private Id templateId;

    public DemoSampleLimitCreateBatch(List<Id> allMpIds, List<Id> brandMpIds, Id templateId) {
        this.allMpIds = allMpIds;
        this.brandMpIds = brandMpIds;
        this.templateId = templateId;
    }

    public Database.QueryLocator start(Database.BatchableContext ctx) {
        return Database.getQueryLocator([
            SELECT Id FROM Account
            WHERE IsPersonAccount = true AND Site = :DEMO_TAG
            ORDER BY Id
        ]);
    }

    public void execute(Database.BatchableContext ctx, List<Account> scope) {
        Schema.SObjectType pslType = Schema.getGlobalDescribe().get('ProviderSampleLimit');
        if (pslType == null) return;

        Set<Id> brandSet = new Set<Id>(brandMpIds);

        Integer currentYear = Date.today().year();
        String startDate = currentYear + '-01-01';
        String endDate = currentYear + '-12-31';
        String rulePrefix = '{"products":{"';
        String brandRuleMid = buildRuleMiddle(startDate, endDate, 'Brand');
        String productRuleMid = buildRuleMiddle(startDate, endDate, 'LSSampleProduct');
        String ruleSuffix = ',"template":{"operations":[{"operation":"RULE","rule":"PerVisitLimit"},{"operation":"RULE","rule":"PerPeriodLimit"},{"operation":"AND"}],"name":"'
            + TEMPLATE_DEV_NAME + '","label":"Generic Template","blockType":"Error"}}';

        Set<Id> scopeIds = new Set<Id>();
        for (Account a : scope) scopeIds.add(a.Id);

        Set<Id> allMpSet = new Set<Id>(allMpIds);
        Set<String> existingKeys = new Set<String>();
        for (SObject psl : Database.query(
            'SELECT AccountId, ProductId FROM ProviderSampleLimit WHERE AccountId IN :scopeIds AND ProductId IN :allMpSet'
        )) {
            existingKeys.add((Id) psl.get('AccountId') + ':' + (Id) psl.get('ProductId'));
        }

        List<SObject> records = new List<SObject>();
        for (Account acct : scope) {
            for (Id mpId : allMpIds) {
                if (existingKeys.contains(acct.Id + ':' + mpId)) continue;
                String mid = brandSet.contains(mpId) ? brandRuleMid : productRuleMid;
                SObject psl = pslType.newSObject();
                psl.put('AccountId', acct.Id);
                psl.put('ProductId', mpId);
                psl.put('PrvdSampleLimitTemplateId', templateId);
                psl.put('PrvdSampleLmtTemplateName', TEMPLATE_DEV_NAME);
                psl.put('Rule', rulePrefix + mpId + mid + ruleSuffix);
                records.add(psl);
            }
        }

        if (!records.isEmpty()) {
            Database.insert(records, false);
        }
    }

    public void finish(Database.BatchableContext ctx) {
    }

    private static String buildRuleMiddle(String startDate, String endDate, String productType) {
        return '":{"rules":{"PerVisitLimit":{"starts":"' + startDate
            + '","label":"Maximum Quantity per Visit","remaining":' + PER_VISIT_QUOTA + ',"calculation":"SamplesPerVisit","strategy":"SKU","ends":"' + endDate
            + '","period":{"params":{},"type":"SampleLimitDateRangePeriod"},"quota":' + PER_VISIT_QUOTA + '},"PerPeriodLimit":{"starts":"' + startDate
            + '","label":"Maximum Quantity per Period","remaining":' + PER_PERIOD_QUOTA + ',"calculation":"SamplesInPeriod","strategy":"SKU","ends":"' + endDate
            + '","period":{"params":{},"type":"SampleLimitDateRangePeriod"},"quota":' + PER_PERIOD_QUOTA + '}},"info":{"annualAllocations":{},"excludedChildProducts":[],"productType":"' + productType + '"}}}';
    }
}
