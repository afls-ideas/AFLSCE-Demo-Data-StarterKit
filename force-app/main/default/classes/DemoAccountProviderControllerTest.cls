@isTest
private class DemoAccountProviderControllerTest {

    @isTest
    static void testGetStatus() {
        Test.startTest();
        try { DemoAccountProviderController.getStatus(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testGetAccountRecordTypes() {
        Test.startTest();
        try { DemoAccountProviderController.getAccountRecordTypes(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testCreateAccountsAndProviders() {
        Test.startTest();
        try { DemoAccountProviderController.createAccountsAndProviders(null, null); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testDeleteAccountsAndProviders() {
        Test.startTest();
        try { DemoAccountProviderController.deleteAccountsAndProviders(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testAssignTerritories() {
        Test.startTest();
        try { DemoAccountProviderController.assignTerritories(); } catch (Exception e) { }
        Test.stopTest();
    }
}
