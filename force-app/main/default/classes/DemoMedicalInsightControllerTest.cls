@isTest
private class DemoMedicalInsightControllerTest {

    @isTest
    static void testGetStatus() {
        String status = DemoMedicalInsightController.getStatus();
        System.assertNotEquals(null, status);
    }

    @isTest
    static void testDeleteNoData() {
        String result = DemoMedicalInsightController.deleteMedicalInsights();
        System.assert(result.contains('No demo'));
    }
}
