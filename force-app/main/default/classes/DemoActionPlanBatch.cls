public without sharing class DemoActionPlanBatch implements Database.Batchable<SObject> {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';
    private static final Schema.SObjectType AP_TYPE = Schema.getGlobalDescribe().get('ActionPlan');

    private Map<String, Id> engTemplateMap;
    private List<String> engTemplateNames;
    private Map<String, String> engToLocalName;
    private Map<String, List<String>> engToLocalTasks;
    private Date startDate;

    public DemoActionPlanBatch(Map<String, Id> engTemplateMap, Date startDate,
            Map<String, String> engToLocalName, Map<String, List<String>> engToLocalTasks) {
        this.engTemplateMap = engTemplateMap;
        this.engTemplateNames = new List<String>(engTemplateMap.keySet());
        this.startDate = startDate;
        this.engToLocalName = engToLocalName;
        this.engToLocalTasks = engToLocalTasks;
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
        Map<Integer, String> indexToEngName = new Map<Integer, String>();
        Map<Integer, String> indexToCountry = new Map<Integer, String>();

        for (SObject obj : scope) {
            Id ownerId = (Id) obj.getSObject('AccountPlan').get('OwnerId');
            String countryCode = (String) obj.getSObject('AccountPlan').getSObject('Account').get('BillingCountryCode');

            for (String engName : engTemplateNames) {
                Id tvId = engTemplateMap.get(engName);
                if (tvId == null) continue;

                String localKey = countryCode + '|' + engName;
                String displayName = engToLocalName.containsKey(localKey) ? engToLocalName.get(localKey) : engName;

                SObject ap = AP_TYPE.newSObject();
                ap.put('Name', displayName);
                ap.put('ActionPlanState', 'Not Started');
                ap.put('ActionPlanType', 'KAM');
                ap.put('TargetId', obj.Id);
                ap.put('OwnerId', ownerId);
                ap.put('StartDate', this.startDate);
                ap.put('ActionPlanTemplateVersionId', tvId);
                ap.put('SourceSystemName', DEMO_TAG);
                indexToOwner.put(actionPlans.size(), ownerId);
                indexToEngName.put(actionPlans.size(), engName);
                indexToCountry.put(actionPlans.size(), countryCode);
                actionPlans.add(ap);
            }
        }

        if (actionPlans.isEmpty()) return;

        Database.SaveResult[] results = Database.insert(actionPlans, false);

        Set<Id> insertedApIds = new Set<Id>();
        Map<Id, Id> apToOwner = new Map<Id, Id>();
        Map<Id, String> apToLocalKey = new Map<Id, String>();
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                Id apId = results[i].getId();
                insertedApIds.add(apId);
                apToOwner.put(apId, indexToOwner.get(i));
                apToLocalKey.put(apId, indexToCountry.get(i) + '|' + indexToEngName.get(i));
            }
        }

        if (insertedApIds.isEmpty()) return;

        List<AssessmentTask> tasks = [
            SELECT Id, Name, ReferenceRecordId FROM AssessmentTask
            WHERE ReferenceRecordId IN :insertedApIds
        ];
        if (!tasks.isEmpty()) {
            Map<Id, List<AssessmentTask>> tasksByAp = new Map<Id, List<AssessmentTask>>();
            for (AssessmentTask t : tasks) {
                if (!tasksByAp.containsKey(t.ReferenceRecordId)) {
                    tasksByAp.put(t.ReferenceRecordId, new List<AssessmentTask>());
                }
                tasksByAp.get(t.ReferenceRecordId).add(t);
            }

            for (AssessmentTask t : tasks) {
                t.OwnerId = apToOwner.get(t.ReferenceRecordId);
                String localKey = apToLocalKey.get(t.ReferenceRecordId);
                if (localKey != null && engToLocalTasks.containsKey(localKey)) {
                    List<String> localNames = engToLocalTasks.get(localKey);
                    List<AssessmentTask> apTasks = tasksByAp.get(t.ReferenceRecordId);
                    Integer idx = apTasks.indexOf(t);
                    if (idx >= 0 && idx < localNames.size()) {
                        t.Name = localNames[idx];
                    }
                }
            }
            Database.update(tasks, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
}
