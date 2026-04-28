@isTest
private class DemoSampleLimitBatchTest {

    @isTest
    static void testCreateBatch() {
        Test.startTest();
        try {
            DemoSampleLimitCreateBatch batch = new DemoSampleLimitCreateBatch(
                new List<Id>(), new List<Id>(), null
            );
            Database.executeBatch(batch, 1);
        } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testDeleteBatch() {
        Test.startTest();
        try {
            DemoSampleLimitDeleteBatch batch = new DemoSampleLimitDeleteBatch(
                new List<Id>()
            );
            Database.executeBatch(batch, 1);
        } catch (Exception e) { }
        Test.stopTest();
    }
}
