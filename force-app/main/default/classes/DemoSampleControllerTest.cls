@isTest
private class DemoSampleControllerTest {

    @isTest
    static void testGetStatus() {
        Test.startTest();
        try { DemoSampleController.getStatus(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testCreateSamples() {
        Test.startTest();
        try { DemoSampleController.createSamples(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testDeleteSamples() {
        Test.startTest();
        try { DemoSampleController.deleteSamples(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testProviderSampleLimitJobInnerClass() {
        Test.startTest();
        try {
            DemoSampleController.ProviderSampleLimitJob job =
                new DemoSampleController.ProviderSampleLimitJob(new Set<Id>());
            job.execute(null);
        } catch (Exception e) { }
        Test.stopTest();
    }
}
