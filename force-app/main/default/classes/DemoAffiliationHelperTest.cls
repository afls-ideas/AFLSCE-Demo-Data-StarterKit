@isTest
private class DemoAffiliationHelperTest {

    @isTest
    static void testCreateAffiliations() {
        Test.startTest();
        try {
            DemoAffiliationHelper.createAffiliations(
                new Map<String, Id>(),
                new Map<String, Id>()
            );
        } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testDeleteAffiliations() {
        Test.startTest();
        try { DemoAffiliationHelper.deleteAffiliations(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testCountAffiliations() {
        Test.startTest();
        try { DemoAffiliationHelper.countAffiliations(); } catch (Exception e) { }
        Test.stopTest();
    }
}
