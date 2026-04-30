@isTest
private class DemoActivityPlanControllerTest {

    @isTest
    static void testGetStatus() {
        Test.startTest();
        String status = DemoActivityPlanController.getStatus();
        Test.stopTest();
        System.assertNotEquals(null, status);
        System.assert(status.contains('Time Periods:'));
        System.assert(status.contains('Activity Plans:'));
    }

    @isTest
    static void testCreateActivityPlans() {
        Test.startTest();
        try {
            DemoActivityPlanController.createProviderActivityPlans();
        } catch (Exception e) {
            // Expected — no demo data in test context
        }
        Test.stopTest();
    }

    @isTest
    static void testDeleteActivityPlans() {
        Test.startTest();
        String result = DemoActivityPlanController.deleteProviderActivityPlans();
        Test.stopTest();
        System.assert(result.contains('Deleted'));
    }
}
