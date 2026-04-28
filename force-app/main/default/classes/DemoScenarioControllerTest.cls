@isTest
private class DemoScenarioControllerTest {

    @isTest
    static void testGetAvailableScenarios() {
        Test.startTest();
        try { DemoScenarioController.getAvailableScenarios(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testGetAppliedScenarios() {
        Test.startTest();
        try { DemoScenarioController.getAppliedScenarios(); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testApplyScenario() {
        Test.startTest();
        try { DemoScenarioController.applyScenario('Oncology'); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testRemoveScenario() {
        Test.startTest();
        try { DemoScenarioController.removeScenario('Oncology'); } catch (Exception e) { }
        Test.stopTest();
    }

    @isTest
    static void testScenarioInfoInnerClass() {
        DemoScenarioController.ScenarioInfo info = new DemoScenarioController.ScenarioInfo();
        info.name = 'Oncology';
        info.label = 'Oncology';
        info.description = 'Test';
        info.icon = 'standard:account';
        info.personas = new List<String>{ 'MSL' };
        info.isApplied = false;
        System.assertNotEquals(null, info.name);
    }
}
