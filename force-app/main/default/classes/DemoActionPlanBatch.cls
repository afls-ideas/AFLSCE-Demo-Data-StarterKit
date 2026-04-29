public without sharing class DemoActionPlanBatch implements Database.Batchable<SObject> {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';
    private static final Schema.SObjectType AP_TYPE = Schema.getGlobalDescribe().get('ActionPlan');

    private Map<String, Id> templateVersionMap;
    private Date startDate;

    public DemoActionPlanBatch(Map<String, Id> templateVersionMap, Date startDate) {
        this.templateVersionMap = templateVersionMap;
        this.startDate = startDate;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String tag = DEMO_TAG;
        return Database.getQueryLocator(
            'SELECT Id, Name, AccountPlan.OwnerId, AccountPlan.Account.BillingCountryCode FROM AccountPlanObjective WHERE SourceSystemName = :tag'
        );
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<SObject> actionPlans = new List<SObject>();
        Map<Integer, Id> indexToOwner = new Map<Integer, Id>();

        for (SObject obj : scope) {
            Id ownerId = (Id) obj.getSObject('AccountPlan').get('OwnerId');
            String countryCode = (String) obj.getSObject('AccountPlan').getSObject('Account').get('BillingCountryCode');
            List<String> tplNames = DemoAccountPlanLocale.getTemplateNames(countryCode);
            for (String tplName : tplNames) {
                Id tvId = this.templateVersionMap.get(tplName);
                if (tvId == null) continue;
                SObject ap = AP_TYPE.newSObject();
                ap.put('Name', tplName);
                ap.put('ActionPlanState', 'Not Started');
                ap.put('ActionPlanType', 'KAM');
                ap.put('TargetId', obj.Id);
                ap.put('OwnerId', ownerId);
                ap.put('StartDate', this.startDate);
                ap.put('ActionPlanTemplateVersionId', tvId);
                ap.put('SourceSystemName', DEMO_TAG);
                indexToOwner.put(actionPlans.size(), ownerId);
                actionPlans.add(ap);
            }
        }

        if (actionPlans.isEmpty()) return;

        Database.SaveResult[] results = Database.insert(actionPlans, false);

        Set<Id> insertedApIds = new Set<Id>();
        Map<Id, Id> apToOwner = new Map<Id, Id>();
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                insertedApIds.add(results[i].getId());
                apToOwner.put(results[i].getId(), indexToOwner.get(i));
            }
        }

        if (insertedApIds.isEmpty()) return;

        List<AssessmentTask> tasks = [
            SELECT Id, ReferenceRecordId FROM AssessmentTask
            WHERE ReferenceRecordId IN :insertedApIds
        ];
        if (!tasks.isEmpty()) {
            for (AssessmentTask t : tasks) {
                t.OwnerId = apToOwner.get(t.ReferenceRecordId);
            }
            Database.update(tasks, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
}
