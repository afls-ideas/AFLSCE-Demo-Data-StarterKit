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
            'SELECT Id, Name, AccountPlan.OwnerId FROM AccountPlanObjective WHERE SourceSystemName = :tag'
        );
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<SObject> actionPlans = new List<SObject>();

        for (SObject obj : scope) {
            Id ownerId = (Id) obj.getSObject('AccountPlan').get('OwnerId');
            for (String tplName : DemoActivityPlanController.KAM_TEMPLATES) {
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
                actionPlans.add(ap);
            }
        }

        if (!actionPlans.isEmpty()) {
            Database.insert(actionPlans, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
}
