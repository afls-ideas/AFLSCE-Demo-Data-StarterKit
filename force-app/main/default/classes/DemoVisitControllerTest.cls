@isTest
private class DemoVisitControllerTest {

    @isTest
    static void testGetStatus() {
        Test.startTest();
        String status = DemoVisitController.getStatus();
        Test.stopTest();
        System.assertNotEquals(null, status);
        System.assert(status.contains('Visits:'));
    }

    @isTest
    static void testGetTerritories() {
        Test.startTest();
        List<Map<String, String>> territories = DemoVisitController.getTerritories();
        Test.stopTest();
        System.assertNotEquals(null, territories);
    }

    @isTest
    static void testDeleteVisits() {
        Test.startTest();
        Map<String, Object> result = DemoVisitController.deleteVisitBatch();
        Test.stopTest();
        System.assertNotEquals(null, result);
        System.assert(result.containsKey('remaining'));
    }

    @isTest
    static void testCreateVisitsInvalidTerritory() {
        Test.startTest();
        try {
            DemoVisitController.createVisits(null);
            System.assert(false, 'Expected exception');
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }
}
