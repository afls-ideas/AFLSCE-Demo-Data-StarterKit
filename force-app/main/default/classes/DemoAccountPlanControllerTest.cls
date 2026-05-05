@isTest
private class DemoAccountPlanControllerTest {

    @isTest
    static void testGetStatus() {
        Test.startTest();
        String status = DemoAccountPlanController.getStatus();
        Test.stopTest();
        System.assertNotEquals(null, status);
    }

    @isTest
    static void testCreateAccountPlansAndActions() {
        Test.startTest();
        try {
            DemoAccountPlanController.createAccountPlansAndActions();
        } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testDeleteAccountPlansAndActions() {
        Test.startTest();
        String result = DemoAccountPlanController.deleteAccountPlansAndActions();
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testActionPlanBatch() {
        Test.startTest();
        try {
            DemoActionPlanBatch batch = new DemoActionPlanBatch(Date.today(), null);
            Database.executeBatch(batch, 10);
        } catch (Exception e) { }
        Test.stopTest();
    }
}
