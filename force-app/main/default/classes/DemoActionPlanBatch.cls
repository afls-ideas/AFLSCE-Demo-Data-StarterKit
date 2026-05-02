public without sharing class DemoActionPlanBatch implements Database.Batchable<SObject> {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';
    private static final Schema.SObjectType AP_TYPE = Schema.getGlobalDescribe().get('ActionPlan');

    private Date startDate;
    private Id defaultTemplateVersionId;

    public DemoActionPlanBatch(Date startDate, Id defaultTemplateVersionId) {
        this.startDate = startDate;
        this.defaultTemplateVersionId = defaultTemplateVersionId;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String tag = DEMO_TAG;
        return Database.getQueryLocator(
            'SELECT Id, Name, AccountPlan.OwnerId, AccountPlan.Account.BillingCountryCode FROM AccountPlanObjective WHERE SourceSystemName = :tag'
        );
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<String> kamTemplates = DemoAccountPlanController.KAM_TEMPLATES;

        List<SObject> actionPlans = new List<SObject>();
        List<Id> apOwners = new List<Id>();
        List<String> apEngNames = new List<String>();

        for (SObject obj : scope) {
            Id ownerId = (Id) obj.getSObject('AccountPlan').get('OwnerId');
            String countryCode = (String) obj.getSObject('AccountPlan').getSObject('Account').get('BillingCountryCode');

            List<String> localNames = DemoAccountPlanLocale.getTemplateNames(countryCode);

            for (Integer t = 0; t < kamTemplates.size(); t++) {
                String displayName = (localNames != null && t < localNames.size()) ? localNames[t] : kamTemplates[t];

                SObject ap = AP_TYPE.newSObject();
                ap.put('Name', displayName);
                ap.put('ActionPlanState', 'Not Started');
                ap.put('ActionPlanType', 'KAM');
                ap.put('TargetId', obj.Id);
                ap.put('OwnerId', ownerId);
                ap.put('StartDate', this.startDate);
                ap.put('ActionPlanTemplateVersionId', this.defaultTemplateVersionId);
                ap.put('SourceSystemName', DEMO_TAG);
                actionPlans.add(ap);
                apOwners.add(ownerId);
                apEngNames.add(kamTemplates[t]);
            }
        }

        if (actionPlans.isEmpty()) return;

        Database.SaveResult[] results = Database.insert(actionPlans, false);

        // The template auto-creates AssessmentTasks — replace them with our custom ones
        Set<Id> insertedApIds = new Set<Id>();
        Map<Id, Id> apToOwner = new Map<Id, Id>();
        Map<Id, String> apToEngName = new Map<Id, String>();
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                Id apId = results[i].getId();
                insertedApIds.add(apId);
                apToOwner.put(apId, apOwners[i]);
                apToEngName.put(apId, apEngNames[i]);
            }
        }

        if (insertedApIds.isEmpty()) return;

        List<AssessmentTask> autoTasks = [
            SELECT Id, ReferenceRecordId FROM AssessmentTask
            WHERE ReferenceRecordId IN :insertedApIds
        ];
        if (!autoTasks.isEmpty()) {
            Database.delete(autoTasks, false);
        }

        List<AssessmentTask> tasks = new List<AssessmentTask>();
        for (Id apId : insertedApIds) {
            Id ownerId = apToOwner.get(apId);
            String engName = apToEngName.get(apId);

            List<String> taskNames = DemoAccountPlanData.KAM_TASKS.get(engName);
            if (taskNames == null || taskNames.isEmpty()) continue;

            for (String taskName : taskNames) {
                AssessmentTask task = new AssessmentTask();
                task.Name = taskName;
                task.ReferenceRecordId = apId;
                task.OwnerId = ownerId;
                task.TaskType = 'Other';
                task.Status = 'NotStarted';
                tasks.add(task);
            }
        }

        if (!tasks.isEmpty()) {
            Database.insert(tasks, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
}
