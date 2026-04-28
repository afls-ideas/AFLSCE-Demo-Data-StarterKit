@isTest
private class DemoReplenishmentControllerTest {

    @isTest
    static void testGetStatus() {
        Test.startTest();
        try { DemoReplenishmentController.getStatus(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testCreateReplenishment() {
        Test.startTest();
        try { DemoReplenishmentController.createReplenishment(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testDeleteReplenishment() {
        Test.startTest();
        try { DemoReplenishmentController.deleteReplenishment(); } catch (Exception e) { }
        Test.stopTest();
    }
}
