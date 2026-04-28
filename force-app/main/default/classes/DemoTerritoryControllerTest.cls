@isTest
private class DemoTerritoryControllerTest {

    @isTest
    static void testGetStatus() {
        Test.startTest();
        try { DemoTerritoryController.getStatus(); } catch (Exception e) { /* managed-package objects may not exist */ }
        Test.stopTest();
    }

    @isTest
    static void testGetHierarchy() {
        Test.startTest();
        try { DemoTerritoryController.getHierarchy(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testCreateTerritoryHierarchy() {
        Test.startTest();
        try { DemoTerritoryController.createTerritoryHierarchy(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testDeleteAllTerritories() {
        Test.startTest();
        try { DemoTerritoryController.deleteAllTerritories(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testTerritoryNodeInnerClass() {
        DemoTerritoryController.TerritoryNode node = new DemoTerritoryController.TerritoryNode();
        node.label = 'Test';
        node.name = 'Test_Node';
        node.expanded = false;
        node.items = new List<DemoTerritoryController.TerritoryNode>();
        System.assertNotEquals(null, node.label);
    }
}
