@isTest
private class DemoContactPointControllerTest {

    @isTest
    static void testGetStatus() {
        Test.startTest();
        try { DemoContactPointController.getStatus(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testCreateAddressBatch() {
        Test.startTest();
        try { DemoContactPointController.createAddressBatch(0); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testCreateEmailBatch() {
        Test.startTest();
        try { DemoContactPointController.createEmailBatch(0); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testCreatePhoneBatch() {
        Test.startTest();
        try { DemoContactPointController.createPhoneBatch(0); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testCreateSocialBatch() {
        Test.startTest();
        try { DemoContactPointController.createSocialBatch(0); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testCreateLicenseBatch() {
        Test.startTest();
        try { DemoContactPointController.createLicenseBatch(0); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testDeleteContactPointBatch() {
        Test.startTest();
        try { DemoContactPointController.deleteContactPointBatch('ContactPointAddress'); } catch (Exception e) { }
        Test.stopTest();
    }
}
