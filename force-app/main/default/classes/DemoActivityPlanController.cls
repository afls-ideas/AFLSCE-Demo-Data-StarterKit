public without sharing class DemoActivityPlanController {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';

    private static final Map<String, String> COUNTRY_TERRITORY = new Map<String, String>{
        'US' => 'US_COUNTRY', 'GB' => 'GB_COUNTRY', 'FR' => 'FR_COUNTRY',
        'DE' => 'DE_COUNTRY', 'IT' => 'IT_COUNTRY', 'ES' => 'ES_COUNTRY',
        'JP' => 'JP_COUNTRY', 'KR' => 'KR_COUNTRY', 'BR' => 'BR_COUNTRY',
        'MX' => 'MX_COUNTRY', 'AR' => 'AR_COUNTRY'
    };

    public static final List<String> KAM_TEMPLATES = new List<String>{
        'Market Access & Contracting',
        'Supply Chain & Distribution Readiness',
        'P&T Committee Prep: Proactive Partnership for Formulary',
        'Field Readiness & Pull-Through',
        'Analyse Diagnostic Gaps for Rheumatoid Arthritis',
        'Implement & Monitor new Diagnostic Protocols'
    };

    private static final Schema.SObjectType ACCOUNT_PLAN_TYPE = Schema.getGlobalDescribe().get('AccountPlan');
    private static final Schema.SObjectType OBJECTIVE_TYPE = Schema.getGlobalDescribe().get('AccountPlanObjective');

    @AuraEnabled(cacheable=true)
    public static String getStatus() {
        try {
            List<String> parts = new List<String>();

            Integer planCount = [SELECT COUNT() FROM AccountPlan
                WHERE SourceSystemName = :DEMO_TAG];
            parts.add('Account Plans: ' + planCount);

            Integer objCount = [SELECT COUNT() FROM AccountPlanObjective
                WHERE SourceSystemName = :DEMO_TAG];
            parts.add('Objectives: ' + objCount);

            Integer apCount = [SELECT COUNT() FROM ActionPlan
                WHERE SourceSystemName = :DEMO_TAG AND ActionPlanType = 'KAM'];
            parts.add('Action Plans: ' + apCount);

            Integer taskCount = [SELECT COUNT() FROM AssessmentTask
                WHERE ReferenceRecordId IN (
                    SELECT Id FROM ActionPlan
                    WHERE SourceSystemName = :DEMO_TAG AND ActionPlanType = 'KAM')];
            parts.add('Assessment Tasks: ' + taskCount);

            return String.join(parts, ', ');
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String getBatchProgress() {
        try {
            List<AsyncApexJob> jobs = [
                SELECT Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
                FROM AsyncApexJob
                WHERE ApexClass.Name = 'DemoActionPlanBatch'
                AND Status IN ('Queued', 'Preparing', 'Processing', 'Holding')
                ORDER BY CreatedDate DESC LIMIT 1
            ];
            if (jobs.isEmpty()) {
                return 'DONE';
            }
            AsyncApexJob j = jobs[0];

            Integer apCount = [SELECT COUNT() FROM ActionPlan
                WHERE SourceSystemName = :DEMO_TAG AND ActionPlanType = 'KAM'];
            Integer taskCount = [SELECT COUNT() FROM AssessmentTask
                WHERE ReferenceRecordId IN (
                    SELECT Id FROM ActionPlan
                    WHERE SourceSystemName = :DEMO_TAG AND ActionPlanType = 'KAM')];

            return j.Status + '|' + j.JobItemsProcessed + '|' + j.TotalJobItems + '|' + apCount + '|' + taskCount;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String createActivityPlans() {
        List<String> details = new List<String>();
        List<String> errors = new List<String>();

        try {
            Integer existingCount = [SELECT COUNT() FROM AccountPlan
                WHERE SourceSystemName = :DEMO_TAG];
            if (existingCount > 0) {
                throw new AuraHandledException(
                    'Activity Plans already exist (' + existingCount + ' account plans). Delete first to re-create.');
            }

            details.add('HEADER:Step 1 — Gathering territory and account data');
            Map<Id, AccountInfo> accountInfoMap = new Map<Id, AccountInfo>();
            Map<Id, TerritoryInfo> terrInfoMap = gatherTerritoryData(accountInfoMap, details, errors);
            if (terrInfoMap.isEmpty()) {
                throw new AuraHandledException('No territories with demo accounts found. Run Accounts & Providers setup first.');
            }

            details.add('HEADER:Step 2 — Loading KAM action plan templates');
            Map<String, Id> templateVersionMap = loadTemplateVersions(details, errors);

            details.add('HEADER:Step 3 — Creating Account Plans');
            Date startDate = Date.newInstance(Date.today().year(), 1, 1);
            Date endDate = Date.newInstance(Date.today().year(), 12, 31);
            Map<Id, Id> acctToAccountPlan = createAccountPlans(terrInfoMap, accountInfoMap, startDate, endDate, details, errors);

            details.add('HEADER:Step 4 — Creating Account Plan Objectives');
            Integer objCount = createObjectives(acctToAccountPlan, accountInfoMap, startDate, endDate, details, errors);

            details.add('HEADER:Step 5 — Queuing Action Plan creation (batch)');
            Map<String, String> localNameMap = buildLocalNameMap();
            Map<String, List<String>> localTaskMap = buildLocalTaskMap();
            Database.executeBatch(new DemoActionPlanBatch(templateVersionMap, startDate, localNameMap, localTaskMap), 10);
            Integer expectedAPs = objCount * templateVersionMap.size();
            details.add('SUCCESS:Batch queued — will create ~' + expectedAPs + ' action plans asynchronously');
            details.add('Refresh the page in a minute to see the final Action Plans count');

            String summary = errors.isEmpty()
                ? 'Created ' + acctToAccountPlan.size() + ' account plans and ' + objCount + ' objectives. Action plans creating in background.'
                : 'Completed with ' + errors.size() + ' error(s).';
            Map<String, Object> result = new Map<String, Object>{
                'summary' => summary,
                'details' => details,
                'errors' => errors
            };
            return JSON.serialize(result);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    @AuraEnabled
    public static String deleteActivityPlans() {
        try {
            String tag = DEMO_TAG;
            Integer deleted = 0;
            Integer lim = 9500;

            List<AssessmentTask> tasks = [SELECT Id FROM AssessmentTask
                WHERE ReferenceRecordId IN (SELECT Id FROM ActionPlan
                    WHERE SourceSystemName = :tag AND ActionPlanType = 'KAM') LIMIT :lim];
            if (!tasks.isEmpty()) {
                Database.delete(tasks, false);
                deleted += tasks.size();
                lim -= tasks.size();
            }

            if (lim > 0) {
                List<ActionPlan> aps = [SELECT Id FROM ActionPlan
                    WHERE SourceSystemName = :tag AND ActionPlanType = 'KAM' LIMIT :lim];
                if (!aps.isEmpty()) {
                    Database.delete(aps, false);
                    deleted += aps.size();
                    lim -= aps.size();
                }
            }

            if (lim > 0) {
                List<AccountPlanObjective> objs = [SELECT Id FROM AccountPlanObjective
                    WHERE SourceSystemName = :tag LIMIT :lim];
                if (!objs.isEmpty()) {
                    Database.delete(objs, false);
                    deleted += objs.size();
                    lim -= objs.size();
                }
            }

            if (lim > 0) {
                List<AccountPlan> plans = [SELECT Id FROM AccountPlan
                    WHERE SourceSystemName = :tag LIMIT :lim];
                if (!plans.isEmpty()) {
                    Database.delete(plans, false);
                    deleted += plans.size();
                }
            }

            Integer remaining = [SELECT COUNT() FROM AccountPlan WHERE SourceSystemName = :tag]
                + [SELECT COUNT() FROM ActionPlan WHERE SourceSystemName = :tag AND ActionPlanType = 'KAM'];
            String msg = 'Deleted ' + deleted + ' records.';
            if (remaining > 0) {
                msg += ' More records remain — click delete again.';
            }
            return msg;
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting: ' + e.getMessage());
        }
    }

    public class AccountInfo {
        public String name;
        public String countryCode;
        public String accountType;
        public Boolean isPersonAccount;
        public String mapKey;
        public Integer archetypeIndex;
    }

    private class TerritoryInfo {
        public Id territoryId;
        public String territoryName;
        public Id ownerId;
        public List<Id> accountIds;

        public TerritoryInfo() {
            accountIds = new List<Id>();
        }
    }

    private static Map<Id, TerritoryInfo> gatherTerritoryData(
            Map<Id, AccountInfo> accountInfoMap, List<String> details, List<String> errors) {

        Set<String> countryDevNames = new Set<String>(COUNTRY_TERRITORY.values());
        Map<Id, String> countryTerrIds = new Map<Id, String>();
        for (Territory2 t : [SELECT Id, DeveloperName FROM Territory2 WHERE DeveloperName IN :countryDevNames]) {
            countryTerrIds.put(t.Id, t.DeveloperName);
        }

        Map<Id, Id> allTerrToCountry = new Map<Id, Id>();
        for (Id tId : countryTerrIds.keySet()) {
            allTerrToCountry.put(tId, tId);
        }
        Set<Id> currentLevel = countryTerrIds.keySet();
        Map<Id, Territory2> allTerritories = new Map<Id, Territory2>();
        for (Territory2 t : [SELECT Id, Name, DeveloperName, ParentTerritory2Id FROM Territory2 WHERE Id IN :currentLevel]) {
            allTerritories.put(t.Id, t);
        }

        for (Integer depth = 0; depth < 5 && !currentLevel.isEmpty(); depth++) {
            List<Territory2> children = [SELECT Id, Name, DeveloperName, ParentTerritory2Id
                FROM Territory2 WHERE ParentTerritory2Id IN :currentLevel];
            Set<Id> nextLevel = new Set<Id>();
            for (Territory2 child : children) {
                nextLevel.add(child.Id);
                allTerrToCountry.put(child.Id, allTerrToCountry.get(child.ParentTerritory2Id));
                allTerritories.put(child.Id, child);
            }
            currentLevel = nextLevel;
        }

        Set<Id> parentIds = new Set<Id>();
        for (Territory2 t : allTerritories.values()) {
            if (t.ParentTerritory2Id != null) {
                parentIds.add(t.ParentTerritory2Id);
            }
        }
        Set<Id> leafTerrIds = new Set<Id>();
        for (Id tId : allTerritories.keySet()) {
            if (!parentIds.contains(tId)) {
                leafTerrIds.add(tId);
            }
        }
        details.add('Found ' + leafTerrIds.size() + ' leaf territories');

        Map<Id, Id> terrToOwner = new Map<Id, Id>();
        for (UserTerritory2Association uta : [
            SELECT Territory2Id, UserId
            FROM UserTerritory2Association
            WHERE Territory2Id IN :leafTerrIds
            ORDER BY Territory2Id
        ]) {
            if (!terrToOwner.containsKey(uta.Territory2Id)) {
                terrToOwner.put(uta.Territory2Id, uta.UserId);
            }
        }

        Map<Id, Account> demoAccounts = new Map<Id, Account>([
            SELECT Id, Name, BillingCountryCode, Type, IsPersonAccount
            FROM Account
            WHERE Site = :DEMO_TAG
        ]);
        Integer hcpCount = 0;
        Integer hcoCount = 0;
        for (Account a : demoAccounts.values()) {
            AccountInfo ai = new AccountInfo();
            ai.name = a.Name;
            ai.countryCode = a.BillingCountryCode;
            ai.accountType = a.Type;
            ai.isPersonAccount = a.IsPersonAccount;
            ai.mapKey = DemoAccountPlanData.getAccountTypeKey(
                a.BillingCountryCode, a.Type, a.IsPersonAccount);
            accountInfoMap.put(a.Id, ai);
            if (a.IsPersonAccount) { hcpCount++; } else { hcoCount++; }
        }
        details.add('Found ' + hcpCount + ' demo HCPs and ' + hcoCount + ' demo HCOs');

        Map<Id, TerritoryInfo> terrInfoMap = new Map<Id, TerritoryInfo>();
        for (ObjectTerritory2Association ota : [
            SELECT ObjectId, Territory2Id
            FROM ObjectTerritory2Association
            WHERE Territory2Id IN :leafTerrIds AND ObjectId IN :demoAccounts.keySet()
        ]) {
            TerritoryInfo ti = terrInfoMap.get(ota.Territory2Id);
            if (ti == null) {
                ti = new TerritoryInfo();
                ti.territoryId = ota.Territory2Id;
                Territory2 terr = allTerritories.get(ota.Territory2Id);
                ti.territoryName = terr != null ? terr.Name : 'Unknown';
                ti.ownerId = terrToOwner.get(ota.Territory2Id);
                terrInfoMap.put(ota.Territory2Id, ti);
            }
            ti.accountIds.add(ota.ObjectId);
        }

        Integer noOwner = 0;
        for (Id tId : new List<Id>(terrInfoMap.keySet())) {
            if (terrInfoMap.get(tId).ownerId == null) {
                terrInfoMap.remove(tId);
                noOwner++;
            }
        }
        if (noOwner > 0) {
            details.add('WARNING: Skipped ' + noOwner + ' territories with no assigned user');
        }

        Integer totalAccounts = 0;
        for (TerritoryInfo ti : terrInfoMap.values()) {
            totalAccounts += ti.accountIds.size();
        }
        details.add('SUCCESS:' + terrInfoMap.size() + ' territories with ' + totalAccounts + ' accounts');
        return terrInfoMap;
    }

    private static Map<String, Id> loadTemplateVersions(List<String> details, List<String> errors) {
        Map<String, Id> engMap = new Map<String, Id>();
        Set<String> engNames = new Set<String>(KAM_TEMPLATES);
        for (ActionPlanTemplateVersion tv : [
            SELECT Id, Name FROM ActionPlanTemplateVersion
            WHERE Name IN :engNames AND Status = 'Final'
        ]) {
            engMap.put(tv.Name.trim(), tv.Id);
        }

        for (String name : KAM_TEMPLATES) {
            if (!engMap.containsKey(name)) {
                errors.add('Template not found (or not Final): ' + name);
            }
        }

        details.add('SUCCESS:Loaded ' + engMap.size() + '/' + KAM_TEMPLATES.size() + ' English Final templates');
        return engMap;
    }

    private static Map<String, String> buildLocalNameMap() {
        Map<String, String> result = new Map<String, String>();
        for (String langKey : DemoAccountPlanLocale.KAM_TEMPLATES_BY_LANG.keySet()) {
            List<String> localNames = DemoAccountPlanLocale.KAM_TEMPLATES_BY_LANG.get(langKey);
            List<String> countryCodes = DemoAccountPlanLocale.getCountriesForLang(langKey);
            for (String cc : countryCodes) {
                for (Integer i = 0; i < KAM_TEMPLATES.size(); i++) {
                    result.put(cc + '|' + KAM_TEMPLATES[i], localNames[i]);
                }
            }
        }
        return result;
    }

    private static Map<String, List<String>> buildLocalTaskMap() {
        Map<String, List<String>> result = new Map<String, List<String>>();
        Set<String> localNames = new Set<String>();
        for (List<String> langNames : DemoAccountPlanLocale.KAM_TEMPLATES_BY_LANG.values()) {
            localNames.addAll(langNames);
        }

        Map<String, List<String>> tasksByTplName = new Map<String, List<String>>();
        Map<Id, String> versionToName = new Map<Id, String>();
        for (ActionPlanTemplateVersion tv : [
            SELECT Id, Name FROM ActionPlanTemplateVersion WHERE Name IN :localNames
        ]) {
            versionToName.put(tv.Id, tv.Name.trim());
        }
        for (ActionPlanTemplateItem item : [
            SELECT Name, ActionPlanTemplateVersionId FROM ActionPlanTemplateItem
            WHERE ActionPlanTemplateVersionId IN :versionToName.keySet() ORDER BY Name
        ]) {
            String tplName = versionToName.get(item.ActionPlanTemplateVersionId);
            if (!tasksByTplName.containsKey(tplName)) tasksByTplName.put(tplName, new List<String>());
            tasksByTplName.get(tplName).add(item.Name);
        }

        for (String langKey : DemoAccountPlanLocale.KAM_TEMPLATES_BY_LANG.keySet()) {
            List<String> langTplNames = DemoAccountPlanLocale.KAM_TEMPLATES_BY_LANG.get(langKey);
            List<String> countryCodes = DemoAccountPlanLocale.getCountriesForLang(langKey);
            for (String cc : countryCodes) {
                for (Integer i = 0; i < KAM_TEMPLATES.size(); i++) {
                    String key = cc + '|' + KAM_TEMPLATES[i];
                    List<String> tasks = tasksByTplName.get(langTplNames[i]);
                    if (tasks != null) {
                        result.put(key, tasks);
                    }
                }
            }
        }
        return result;
    }

    private static Map<Id, Id> createAccountPlans(Map<Id, TerritoryInfo> terrInfoMap,
            Map<Id, AccountInfo> accountInfoMap,
            Date startDate, Date endDate, List<String> details, List<String> errors) {

        List<SObject> plans = new List<SObject>();
        List<Id> planAcctIds = new List<Id>();

        for (TerritoryInfo ti : terrInfoMap.values()) {
            Map<String, Integer> typeCounters = new Map<String, Integer>();
            Integer hcpCount = 0;
            Integer hcoCount = 0;
            for (Id acctId : ti.accountIds) {
                AccountInfo ai = accountInfoMap.get(acctId);
                if (ai == null) continue;
                if (ai.isPersonAccount) {
                    if (hcpCount >= 1) continue;
                    hcpCount++;
                } else {
                    if (hcoCount >= 2) continue;
                    hcoCount++;
                }

                String baseType = DemoAccountPlanData.getBaseType(ai.mapKey);
                List<String> archetypes = DemoAccountPlanLocale.getArchetypes(ai.countryCode, baseType);
                if (archetypes == null || archetypes.isEmpty()) continue;

                Integer counter = typeCounters.containsKey(baseType) ? typeCounters.get(baseType) : 0;
                Integer archIdx = Math.mod(counter, archetypes.size());
                typeCounters.put(baseType, counter + 1);
                ai.archetypeIndex = archIdx;

                String planName = DemoAccountPlanLocale.formatArchetype(archetypes[archIdx], ai.name);

                SObject plan = ACCOUNT_PLAN_TYPE.newSObject();
                plan.put('Name', planName.left(255));
                plan.put('AccountId', acctId);
                plan.put('OwnerId', ti.ownerId);
                plan.put('StartDate', startDate);
                plan.put('EndDate', endDate);
                plan.put('Status', 'Active');
                plan.put('SourceSystemName', DEMO_TAG);
                plans.add(plan);
                planAcctIds.add(acctId);
            }
        }

        Map<Id, Id> acctToAccountPlan = new Map<Id, Id>();
        Database.SaveResult[] results = Database.insert(plans, false);
        Integer created = 0;
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                acctToAccountPlan.put(planAcctIds[i], results[i].getId());
                created++;
            } else if (errors.size() < 20) {
                errors.add('AccountPlan: ' + results[i].getErrors()[0].getMessage());
            }
        }
        details.add('SUCCESS:Created ' + created + ' account plans');
        return acctToAccountPlan;
    }

    private static Integer createObjectives(Map<Id, Id> acctToAccountPlan,
            Map<Id, AccountInfo> accountInfoMap,
            Date startDate, Date endDate, List<String> details, List<String> errors) {

        List<SObject> objectives = new List<SObject>();

        for (Id acctId : acctToAccountPlan.keySet()) {
            Id planId = acctToAccountPlan.get(acctId);
            AccountInfo ai = accountInfoMap.get(acctId);
            if (ai == null) continue;

            String baseType = DemoAccountPlanData.getBaseType(ai.mapKey);
            String objKey = baseType + '_' + (ai.archetypeIndex != null ? ai.archetypeIndex : 0);
            List<String> objNames = DemoAccountPlanLocale.getObjectives(ai.countryCode, objKey);
            if (objNames == null || objNames.isEmpty()) continue;

            for (String objName : objNames) {
                SObject obj = OBJECTIVE_TYPE.newSObject();
                obj.put('Name', objName.left(255));
                obj.put('AccountPlanId', planId);
                obj.put('Description', objName);
                obj.put('StartDate', startDate);
                obj.put('EndDate', endDate);
                obj.put('SourceSystemName', DEMO_TAG);
                objectives.add(obj);
            }
        }

        Database.SaveResult[] results = Database.insert(objectives, false);
        Integer created = 0;
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                created++;
            } else if (errors.size() < 20) {
                errors.add('Objective: ' + results[i].getErrors()[0].getMessage());
            }
        }
        details.add('SUCCESS:Created ' + created + ' objectives');
        return created;
    }

}
