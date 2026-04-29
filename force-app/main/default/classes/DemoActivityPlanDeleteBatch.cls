public without sharing class DemoActivityPlanDeleteBatch implements Database.Batchable<SObject>, Database.Stateful {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';
    private Integer stage;

    public DemoActivityPlanDeleteBatch() {
        this.stage = 0;
    }

    private DemoActivityPlanDeleteBatch(Integer stage) {
        this.stage = stage;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String tag = DEMO_TAG;
        if (stage == 0) {
            return Database.getQueryLocator(
                'SELECT Id FROM ActionPlan WHERE SourceSystemName = :tag AND ActionPlanType = \'KAM\''
            );
        } else if (stage == 1) {
            return Database.getQueryLocator(
                'SELECT Id FROM AccountPlanObjective WHERE SourceSystemName = :tag'
            );
        } else {
            return Database.getQueryLocator(
                'SELECT Id FROM AccountPlan WHERE SourceSystemName = :tag'
            );
        }
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        if (stage == 0) {
            Set<Id> apIds = new Set<Id>();
            for (SObject s : scope) { apIds.add(s.Id); }
            Database.delete([SELECT Id FROM AssessmentTask WHERE ReferenceRecordId IN :apIds], false);
            Database.delete(scope, false);
        } else {
            Database.delete(scope, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (stage < 2) {
            Database.executeBatch(new DemoActivityPlanDeleteBatch(stage + 1), 2000);
        }
    }
}
