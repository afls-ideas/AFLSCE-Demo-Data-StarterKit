public without sharing class DemoSampleLimitDeleteBatch implements Database.Batchable<SObject> {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';
    private List<Id> allMpIds;

    public DemoSampleLimitDeleteBatch(List<Id> allMpIds) {
        this.allMpIds = allMpIds;
    }

    public Database.QueryLocator start(Database.BatchableContext ctx) {
        Set<Id> mpSet = new Set<Id>(allMpIds);
        return Database.getQueryLocator([
            SELECT Id FROM ProviderSampleLimit WHERE ProductId IN :mpSet
        ]);
    }

    public void execute(Database.BatchableContext ctx, List<SObject> scope) {
        Database.delete(scope, false);
    }

    public void finish(Database.BatchableContext ctx) {
        List<SObject> assigns = Database.query(
            'SELECT Id FROM ProviderSmplLmtTmplAssignment WHERE SourceSystemName = \'' + DEMO_TAG + '\''
        );
        if (!assigns.isEmpty()) {
            Database.delete(assigns, false);
        }

        List<TimePeriod> tps = [SELECT Id FROM TimePeriod WHERE Name LIKE 'Sample Period %'];
        if (!tps.isEmpty()) {
            Database.delete(tps, false);
        }
    }
}
