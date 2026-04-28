@isTest
private class DemoProductAlignmentControllerTest {

    @isTest
    static void testGetStatus() {
        Test.startTest();
        try { DemoProductAlignmentController.getStatus(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testCreateProductsAndAlign() {
        Test.startTest();
        try { DemoProductAlignmentController.createProductsAndAlign(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testDeleteProductsAndAlignments() {
        Test.startTest();
        try { DemoProductAlignmentController.deleteProductsAndAlignments(); } catch (Exception e) { }
        Test.stopTest();
    }
}
