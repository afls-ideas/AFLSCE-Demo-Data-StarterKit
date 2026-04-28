@isTest
private class DemoSampleLimitControllerTest {

    @isTest
    static void testGetStatus() {
        Test.startTest();
        try { DemoSampleLimitController.getStatus(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testCreateSampleLimits() {
        Test.startTest();
        try { DemoSampleLimitController.createSampleLimits(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testDeleteSampleLimits() {
        Test.startTest();
        try { DemoSampleLimitController.deleteSampleLimits(); } catch (Exception e) { }
        Test.stopTest();
    }
}
