@isTest
private class DemoMedicalInsightControllerTest {

    @isTest
    static void testGetStatus() {
        String status = DemoMedicalInsightController.getStatus();
        System.assertNotEquals(null, status);
    }

    @isTest
    static void testGetTerritories() {
        Test.startTest();
        List<Map<String, String>> territories = DemoMedicalInsightController.getTerritories();
        Test.stopTest();
        System.assertNotEquals(null, territories);
    }

    @isTest
    static void testCreateInsightsForTerritory() {
        Test.startTest();
        try { DemoMedicalInsightController.createInsightsForTerritory(null); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testDeleteNoData() {
        String result = DemoMedicalInsightController.deleteMedicalInsights();
        System.assert(result.contains('No demo'));
    }

    @isTest
    static void testDeleteForTerritory() {
        Test.startTest();
        try { DemoMedicalInsightController.deleteMedicalInsightsForTerritory(null); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testLocaleGetInsights() {
        String[] countryCodes = new String[]{ 'US', 'GB', 'FR', 'DE', 'IT', 'ES', 'JP', 'KR', 'BR' };
        for (String code : countryCodes) {
            Map<String, List<Map<String, String>>> insights = DemoMedicalInsightLocale.getInsights(code);
            System.assertNotEquals(null, insights, 'Insights should not be null for ' + code);
            System.assert(insights.containsKey('Immunexis'), 'Missing Immunexis for ' + code);
            System.assert(insights.containsKey('Immunonco'), 'Missing Immunonco for ' + code);
            System.assert(insights.get('Immunexis').size() >= 10, 'Expected 10+ Immunexis insights for ' + code);
            System.assert(insights.get('Immunonco').size() >= 10, 'Expected 10+ Immunonco insights for ' + code);
        }
    }
}
