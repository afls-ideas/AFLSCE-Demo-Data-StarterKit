/**
 * DemoScenarioController
 *
 * Layers therapy-area and persona-specific demo data on top of existing base data
 * for Agentforce for Life Sciences demos. Each scenario creates tagged HCPs,
 * specialty accounts, affiliations, and specialties that can be independently
 * applied and removed.
 */
public with sharing class DemoScenarioController {

    private static final String TAG_PREFIX = 'AFLSCE-Demo-Data:';

    // ---------------------------------------------------------------------------
    // Inner class
    // ---------------------------------------------------------------------------
    public class ScenarioInfo {
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String description;
        @AuraEnabled public String icon;
        @AuraEnabled public List<String> personas;
        @AuraEnabled public Boolean isApplied;
    }

    // ---------------------------------------------------------------------------
    // Public AuraEnabled methods
    // ---------------------------------------------------------------------------

    /**
     * Returns the catalog of available scenarios with their applied status.
     */
    @AuraEnabled(cacheable=true)
    public static List<ScenarioInfo> getAvailableScenarios() {
        Set<String> applied = getAppliedScenarioNames();
        List<ScenarioInfo> scenarios = new List<ScenarioInfo>();

        ScenarioInfo onc = new ScenarioInfo();
        onc.name = 'oncology';
        onc.label = 'Oncology Company';
        onc.description = 'Medical & surgical oncologists, cancer centers, KOLs, clinical trial sites, and oncology product data.';
        onc.icon = 'standard:medicine';
        onc.personas = new List<String>{ 'Medical Rep', 'MSL', 'KAM' };
        onc.isApplied = applied.contains('oncology');
        scenarios.add(onc);

        ScenarioInfo card = new ScenarioInfo();
        card.name = 'cardiology';
        card.label = 'Cardiology Company';
        card.description = 'Cardiologists, heart centers, cath labs, and medical device accounts.';
        card.icon = 'standard:pulse';
        card.personas = new List<String>{ 'Med Rep', 'KAM', 'Field Medical' };
        card.isApplied = applied.contains('cardiology');
        scenarios.add(card);

        ScenarioInfo imm = new ScenarioInfo();
        imm.name = 'immunology';
        imm.label = 'Immunology Company';
        imm.description = 'Rheumatologists, dermatologists, specialty clinics, infusion centers, and payer relationships.';
        imm.icon = 'standard:shield';
        imm.personas = new List<String>{ 'Med Rep', 'Market Access', 'MSL' };
        imm.isApplied = applied.contains('immunology');
        scenarios.add(imm);

        ScenarioInfo neuro = new ScenarioInfo();
        neuro.name = 'neurology';
        neuro.label = 'Neurology Company';
        neuro.description = 'Neurologists, movement disorder & MS specialists, neuroscience research centers, patient support programs.';
        neuro.icon = 'standard:brain';
        neuro.personas = new List<String>{ 'Med Rep', 'MSL', 'Field Medical' };
        neuro.isApplied = applied.contains('neurology');
        scenarios.add(neuro);

        ScenarioInfo rare = new ScenarioInfo();
        rare.name = 'rare_disease';
        rare.label = 'Rare Disease Company';
        rare.description = 'Geneticists, metabolic disease specialists, Centers of Excellence, patient advocacy organizations, diagnostic labs.';
        rare.icon = 'standard:connect';
        rare.personas = new List<String>{ 'MSL', 'Field Medical', 'Market Access' };
        rare.isApplied = applied.contains('rare_disease');
        scenarios.add(rare);

        return scenarios;
    }

    /**
     * Returns the set of scenario names that have already been applied.
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getAppliedScenarios() {
        return new List<String>(getAppliedScenarioNames());
    }

    /**
     * Applies the given scenario by creating tagged demo records.
     */
    @AuraEnabled
    public static String applyScenario(String scenarioName) {
        try {
            if (getAppliedScenarioNames().contains(scenarioName)) {
                return 'Scenario "' + scenarioName + '" is already applied.';
            }

            String tag = TAG_PREFIX + scenarioName;

            switch on scenarioName {
                when 'oncology' {
                    applyOncology(tag);
                }
                when 'cardiology' {
                    applyCardiology(tag);
                }
                when 'immunology' {
                    applyImmunology(tag);
                }
                when 'neurology' {
                    applyNeurology(tag);
                }
                when 'rare_disease' {
                    applyRareDisease(tag);
                }
                when else {
                    return 'Unknown scenario: ' + scenarioName;
                }
            }

            return 'Scenario "' + scenarioName + '" applied successfully.';
        } catch (Exception e) {
            return 'Error applying scenario "' + scenarioName + '": ' + e.getMessage();
        }
    }

    /**
     * Removes only demo records tagged with the given scenario.
     * Base records are never deleted.
     */
    @AuraEnabled
    public static String removeScenario(String scenarioName) {
        try {
            String tag = TAG_PREFIX + scenarioName;

            // Delete child records first to respect referential integrity
            List<HealthcareProviderSpecialty> specialties = [
                SELECT Id FROM HealthcareProviderSpecialty
                WHERE Account.Description = :tag
                LIMIT 2000
            ];
            if (!specialties.isEmpty()) {
                Database.delete(specialties, false);
            }

            // Delete affiliations where either side is tagged
            List<SObject> affiliations = Database.query(
                'SELECT Id FROM HealthcareProviderAffiliation ' +
                'WHERE Practitioner.Description = \'' + String.escapeSingleQuotes(tag) + '\' ' +
                'OR Account.Description = \'' + String.escapeSingleQuotes(tag) + '\' ' +
                'LIMIT 2000'
            );
            if (!affiliations.isEmpty()) {
                Database.delete(affiliations, false);
            }

            // Delete tagged HCP (Account with IsPersonAccount or individual) records
            List<Account> taggedAccounts = [
                SELECT Id FROM Account
                WHERE Description = :tag
                LIMIT 2000
            ];
            if (!taggedAccounts.isEmpty()) {
                Database.delete(taggedAccounts, false);
            }

            return 'Scenario "' + scenarioName + '" removed successfully.';
        } catch (Exception e) {
            return 'Error removing scenario "' + scenarioName + '": ' + e.getMessage();
        }
    }

    // ---------------------------------------------------------------------------
    // Private helpers — status check
    // ---------------------------------------------------------------------------

    private static Set<String> getAppliedScenarioNames() {
        Set<String> applied = new Set<String>();
        List<String> allTags = new List<String>{
            TAG_PREFIX + 'oncology',
            TAG_PREFIX + 'cardiology',
            TAG_PREFIX + 'immunology',
            TAG_PREFIX + 'neurology',
            TAG_PREFIX + 'rare_disease'
        };

        // Use AggregateResult grouping for efficiency
        for (AggregateResult ar : [
            SELECT Description, COUNT(Id) cnt
            FROM Account
            WHERE Description IN :allTags
            GROUP BY Description
        ]) {
            String desc = (String) ar.get('Description');
            if (desc != null && desc.startsWith(TAG_PREFIX)) {
                applied.add(desc.substringAfter(TAG_PREFIX));
            }
        }
        return applied;
    }

    // ---------------------------------------------------------------------------
    // Private helpers — bulk insert with error collection
    // ---------------------------------------------------------------------------

    private static List<Account> insertAccounts(List<Account> accs) {
        Database.SaveResult[] results = Database.insert(accs, false);
        List<Account> inserted = new List<Account>();
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                accs[i].Id = results[i].getId();
                inserted.add(accs[i]);
            }
        }
        return inserted;
    }

    private static void insertSObjects(List<SObject> records) {
        if (!records.isEmpty()) {
            Database.insert(records, false);
        }
    }

    private static Account hcp(String firstName, String lastName, String specialty, String tag) {
        Account a = new Account();
        a.FirstName = firstName;
        a.LastName = lastName;
        a.Description = tag;
        // Specialty stored via standard field or tagging
        a.put('RecordTypeId', getPersonAccountRecordTypeId());
        return a;
    }

    private static Account orgAccount(String name, String accType, String tag) {
        Account a = new Account();
        a.Name = name;
        a.Type = accType;
        a.Description = tag;
        return a;
    }

    private static Id personAccountRtId;
    private static Id getPersonAccountRecordTypeId() {
        if (personAccountRtId == null) {
            List<RecordType> rts = [
                SELECT Id FROM RecordType
                WHERE SObjectType = 'Account'
                AND IsPersonType = true
                AND IsActive = true
                LIMIT 1
            ];
            if (!rts.isEmpty()) {
                personAccountRtId = rts[0].Id;
            }
        }
        return personAccountRtId;
    }

    private static Id businessAccountRtId;
    private static Id getBusinessAccountRecordTypeId() {
        if (businessAccountRtId == null) {
            List<RecordType> rts = [
                SELECT Id FROM RecordType
                WHERE SObjectType = 'Account'
                AND IsPersonType = false
                AND IsActive = true
                LIMIT 1
            ];
            if (!rts.isEmpty()) {
                businessAccountRtId = rts[0].Id;
            }
        }
        return businessAccountRtId;
    }

    private static List<Account> getExistingHospitals() {
        return [
            SELECT Id, Name FROM Account
            WHERE Type = 'Hospital'
            AND Description != :TAG_PREFIX + 'oncology'
            AND Description != :TAG_PREFIX + 'cardiology'
            AND Description != :TAG_PREFIX + 'immunology'
            AND Description != :TAG_PREFIX + 'neurology'
            AND Description != :TAG_PREFIX + 'rare_disease'
            LIMIT 10
        ];
    }

    private static void createAffiliations(List<Account> hcps, List<Account> facilities, String tag) {
        List<SObject> affiliations = new List<SObject>();
        Integer facilityCount = facilities.size();
        if (facilityCount == 0) {
            return;
        }
        for (Integer i = 0; i < hcps.size(); i++) {
            if (hcps[i].Id == null) continue;
            Account facility = facilities[Math.mod(i, facilityCount)];
            if (facility.Id == null) continue;

            SObject aff = Schema.getGlobalDescribe().get('HealthcareProviderAffiliation').newSObject();
            aff.put('PractitionerId', hcps[i].Id);
            aff.put('AccountId', facility.Id);
            affiliations.add(aff);
        }
        insertSObjects(affiliations);
    }

    private static void createSpecialties(List<Account> hcps, Map<Id, String> hcpSpecialtyMap) {
        List<SObject> specialties = new List<SObject>();
        for (Account hcpAcc : hcps) {
            if (hcpAcc.Id == null) continue;
            String specName = hcpSpecialtyMap.get(hcpAcc.Id);
            if (specName == null) continue;

            SObject spec = Schema.getGlobalDescribe().get('HealthcareProviderSpecialty').newSObject();
            spec.put('AccountId', hcpAcc.Id);
            spec.put('Name', specName);
            specialties.add(spec);
        }
        insertSObjects(specialties);
    }

    // ---------------------------------------------------------------------------
    // Scenario: Oncology
    // ---------------------------------------------------------------------------

    private static void applyOncology(String tag) {
        // HCPs — realistic US/GB/FR/DE/IT/ES names
        List<Account> hcps = new List<Account>();
        Map<Id, String> specMap = new Map<Id, String>();
        List<String[]> hcpData = new List<String[]>{
            new String[]{ 'James', 'Morrison', 'Medical Oncology' },
            new String[]{ 'Sarah', 'Chen', 'Surgical Oncology' },
            new String[]{ 'Michael', 'O\'Brien', 'Radiation Oncology' },
            new String[]{ 'Elena', 'Rodriguez', 'Hematology-Oncology' },
            new String[]{ 'Pierre', 'Dubois', 'Medical Oncology' },
            new String[]{ 'Hans', 'Mueller', 'Surgical Oncology' },
            new String[]{ 'Giulia', 'Rossi', 'Radiation Oncology' },
            new String[]{ 'Charlotte', 'Williams', 'Hematology-Oncology' },
            new String[]{ 'Thomas', 'Hartmann', 'Medical Oncology' },
            new String[]{ 'Maria', 'Garcia', 'Hematology-Oncology' },
            new String[]{ 'David', 'Campbell', 'Surgical Oncology' },
            new String[]{ 'Sophie', 'Laurent', 'Radiation Oncology' }
        };
        for (String[] d : hcpData) {
            hcps.add(hcp(d[0], d[1], d[2], tag));
        }
        List<Account> insertedHcps = insertAccounts(hcps);

        // Build specialty map
        for (Integer i = 0; i < insertedHcps.size(); i++) {
            for (Integer j = 0; j < hcpData.size(); j++) {
                if (insertedHcps[i].FirstName == hcpData[j][0] && insertedHcps[i].LastName == hcpData[j][1]) {
                    specMap.put(insertedHcps[i].Id, hcpData[j][2]);
                    break;
                }
            }
        }

        // KOLs — flag in Description (append KOL marker)
        // First 3 HCPs are KOLs — update their description to include KOL flag
        List<Account> kolUpdates = new List<Account>();
        for (Integer i = 0; i < Math.min(3, insertedHcps.size()); i++) {
            Account upd = new Account(Id = insertedHcps[i].Id);
            upd.Description = tag + '|KOL';
            kolUpdates.add(upd);
        }
        Database.update(kolUpdates, false);

        // Specialty accounts — cancer centers, clinical trial sites
        List<Account> orgAccounts = new List<Account>{
            orgAccount('Memorial Oncology Center', 'Hospital', tag),
            orgAccount('Pacific Cancer Institute', 'Hospital', tag),
            orgAccount('European Oncology Research Network', 'Clinical Trial Site', tag),
            orgAccount('North Atlantic Cancer Clinical Trials', 'Clinical Trial Site', tag),
            orgAccount('Oncology Therapeutics Inc.', 'Partner', tag)
        };
        Id bizRtId = getBusinessAccountRecordTypeId();
        if (bizRtId != null) {
            for (Account oa : orgAccounts) {
                oa.RecordTypeId = bizRtId;
            }
        }
        List<Account> insertedOrgs = insertAccounts(orgAccounts);

        // Affiliations — link HCPs to cancer centers and existing hospitals
        List<Account> allFacilities = new List<Account>();
        allFacilities.addAll(insertedOrgs);
        allFacilities.addAll(getExistingHospitals());
        createAffiliations(insertedHcps, allFacilities, tag);

        // Specialties
        createSpecialties(insertedHcps, specMap);
    }

    // ---------------------------------------------------------------------------
    // Scenario: Cardiology
    // ---------------------------------------------------------------------------

    private static void applyCardiology(String tag) {
        List<Account> hcps = new List<Account>();
        Map<Id, String> specMap = new Map<Id, String>();
        List<String[]> hcpData = new List<String[]>{
            new String[]{ 'Robert', 'Anderson', 'Cardiology' },
            new String[]{ 'Catherine', 'Park', 'Interventional Cardiology' },
            new String[]{ 'William', 'Thompson', 'Cardiac Surgery' },
            new String[]{ 'Isabelle', 'Martin', 'Electrophysiology' },
            new String[]{ 'Friedrich', 'Weber', 'Cardiology' },
            new String[]{ 'Emma', 'Davies', 'Interventional Cardiology' },
            new String[]{ 'Antonio', 'Bianchi', 'Cardiac Surgery' },
            new String[]{ 'Carlos', 'Fernandez', 'Electrophysiology' },
            new String[]{ 'Jean', 'Moreau', 'Cardiology' },
            new String[]{ 'Margaret', 'Stewart', 'Interventional Cardiology' },
            new String[]{ 'Klaus', 'Schneider', 'Cardiac Surgery' },
            new String[]{ 'Laura', 'Colombo', 'Electrophysiology' },
            new String[]{ 'Andrew', 'Wilson', 'Cardiology' }
        };
        for (String[] d : hcpData) {
            hcps.add(hcp(d[0], d[1], d[2], tag));
        }
        List<Account> insertedHcps = insertAccounts(hcps);

        for (Integer i = 0; i < insertedHcps.size(); i++) {
            for (Integer j = 0; j < hcpData.size(); j++) {
                if (insertedHcps[i].FirstName == hcpData[j][0] && insertedHcps[i].LastName == hcpData[j][1]) {
                    specMap.put(insertedHcps[i].Id, hcpData[j][2]);
                    break;
                }
            }
        }

        List<Account> orgAccounts = new List<Account>{
            orgAccount('National Heart & Vascular Center', 'Hospital', tag),
            orgAccount('Advanced Cardiac Catheterization Lab', 'Hospital', tag),
            orgAccount('HeartCare Device Solutions', 'Partner', tag),
            orgAccount('European Cardiac Research Institute', 'Hospital', tag),
            orgAccount('Cardiovascular Medical Devices GmbH', 'Partner', tag)
        };
        Id bizRtId = getBusinessAccountRecordTypeId();
        if (bizRtId != null) {
            for (Account oa : orgAccounts) {
                oa.RecordTypeId = bizRtId;
            }
        }
        List<Account> insertedOrgs = insertAccounts(orgAccounts);

        List<Account> allFacilities = new List<Account>();
        allFacilities.addAll(insertedOrgs);
        allFacilities.addAll(getExistingHospitals());
        createAffiliations(insertedHcps, allFacilities, tag);
        createSpecialties(insertedHcps, specMap);
    }

    // ---------------------------------------------------------------------------
    // Scenario: Immunology
    // ---------------------------------------------------------------------------

    private static void applyImmunology(String tag) {
        List<Account> hcps = new List<Account>();
        Map<Id, String> specMap = new Map<Id, String>();
        List<String[]> hcpData = new List<String[]>{
            new String[]{ 'Jennifer', 'Lewis', 'Rheumatology' },
            new String[]{ 'Philippe', 'Renard', 'Dermatology' },
            new String[]{ 'Anna', 'Schmidt', 'Gastroenterology' },
            new String[]{ 'Daniel', 'Hughes', 'Rheumatology' },
            new String[]{ 'Chiara', 'Ferrari', 'Dermatology' },
            new String[]{ 'Alejandro', 'Morales', 'Gastroenterology' },
            new String[]{ 'Rebecca', 'Clarke', 'Rheumatology' },
            new String[]{ 'Matthias', 'Fischer', 'Dermatology' },
            new String[]{ 'Nathalie', 'Petit', 'Gastroenterology' },
            new String[]{ 'Richard', 'Taylor', 'Rheumatology' },
            new String[]{ 'Francesca', 'Conti', 'Dermatology' },
            new String[]{ 'Pablo', 'Ruiz', 'Gastroenterology' },
            new String[]{ 'Victoria', 'Brown', 'Rheumatology' },
            new String[]{ 'Stefan', 'Braun', 'Gastroenterology' }
        };
        for (String[] d : hcpData) {
            hcps.add(hcp(d[0], d[1], d[2], tag));
        }
        List<Account> insertedHcps = insertAccounts(hcps);

        for (Integer i = 0; i < insertedHcps.size(); i++) {
            for (Integer j = 0; j < hcpData.size(); j++) {
                if (insertedHcps[i].FirstName == hcpData[j][0] && insertedHcps[i].LastName == hcpData[j][1]) {
                    specMap.put(insertedHcps[i].Id, hcpData[j][2]);
                    break;
                }
            }
        }

        List<Account> orgAccounts = new List<Account>{
            orgAccount('Midwest Infusion Center', 'Hospital', tag),
            orgAccount('BioTherapy Specialty Clinic', 'Hospital', tag),
            orgAccount('National Specialty Pharmacy Network', 'Partner', tag),
            orgAccount('Autoimmune Center of Excellence', 'Hospital', tag),
            orgAccount('Payer Solutions Alliance', 'Partner', tag)
        };
        Id bizRtId = getBusinessAccountRecordTypeId();
        if (bizRtId != null) {
            for (Account oa : orgAccounts) {
                oa.RecordTypeId = bizRtId;
            }
        }
        List<Account> insertedOrgs = insertAccounts(orgAccounts);

        List<Account> allFacilities = new List<Account>();
        allFacilities.addAll(insertedOrgs);
        allFacilities.addAll(getExistingHospitals());
        createAffiliations(insertedHcps, allFacilities, tag);
        createSpecialties(insertedHcps, specMap);
    }

    // ---------------------------------------------------------------------------
    // Scenario: Neurology
    // ---------------------------------------------------------------------------

    private static void applyNeurology(String tag) {
        List<Account> hcps = new List<Account>();
        Map<Id, String> specMap = new Map<Id, String>();
        List<String[]> hcpData = new List<String[]>{
            new String[]{ 'Jonathan', 'Mitchell', 'Neurology' },
            new String[]{ 'Marie', 'Lefevre', 'Movement Disorders' },
            new String[]{ 'Oliver', 'Barrett', 'Multiple Sclerosis' },
            new String[]{ 'Sabine', 'Keller', 'Epileptology' },
            new String[]{ 'Marco', 'De Luca', 'Neurology' },
            new String[]{ 'Carmen', 'Navarro', 'Movement Disorders' },
            new String[]{ 'Patrick', 'Robinson', 'Multiple Sclerosis' },
            new String[]{ 'Helene', 'Girard', 'Epileptology' },
            new String[]{ 'Sebastian', 'Wolf', 'Neurology' },
            new String[]{ 'Emily', 'Foster', 'Movement Disorders' },
            new String[]{ 'Alessandro', 'Romano', 'Multiple Sclerosis' },
            new String[]{ 'Teresa', 'Sanchez', 'Epileptology' }
        };
        for (String[] d : hcpData) {
            hcps.add(hcp(d[0], d[1], d[2], tag));
        }
        List<Account> insertedHcps = insertAccounts(hcps);

        for (Integer i = 0; i < insertedHcps.size(); i++) {
            for (Integer j = 0; j < hcpData.size(); j++) {
                if (insertedHcps[i].FirstName == hcpData[j][0] && insertedHcps[i].LastName == hcpData[j][1]) {
                    specMap.put(insertedHcps[i].Id, hcpData[j][2]);
                    break;
                }
            }
        }

        List<Account> orgAccounts = new List<Account>{
            orgAccount('National Neuroscience Research Center', 'Hospital', tag),
            orgAccount('Advanced Brain & Spine Institute', 'Hospital', tag),
            orgAccount('MS Comprehensive Care Center', 'Hospital', tag),
            orgAccount('NeuroLife Patient Support Program', 'Partner', tag)
        };
        Id bizRtId = getBusinessAccountRecordTypeId();
        if (bizRtId != null) {
            for (Account oa : orgAccounts) {
                oa.RecordTypeId = bizRtId;
            }
        }
        List<Account> insertedOrgs = insertAccounts(orgAccounts);

        List<Account> allFacilities = new List<Account>();
        allFacilities.addAll(insertedOrgs);
        allFacilities.addAll(getExistingHospitals());
        createAffiliations(insertedHcps, allFacilities, tag);
        createSpecialties(insertedHcps, specMap);
    }

    // ---------------------------------------------------------------------------
    // Scenario: Rare Disease
    // ---------------------------------------------------------------------------

    private static void applyRareDisease(String tag) {
        List<Account> hcps = new List<Account>();
        Map<Id, String> specMap = new Map<Id, String>();
        List<String[]> hcpData = new List<String[]>{
            new String[]{ 'Elizabeth', 'Crawford', 'Clinical Genetics' },
            new String[]{ 'Francois', 'Bernard', 'Metabolic Disease' },
            new String[]{ 'Katharina', 'Richter', 'Clinical Genetics' },
            new String[]{ 'Luca', 'Martini', 'Metabolic Disease' },
            new String[]{ 'Isabel', 'Ortega', 'Clinical Genetics' },
            new String[]{ 'Christopher', 'Ward', 'Metabolic Disease' },
            new String[]{ 'Amelie', 'Roux', 'Clinical Genetics' },
            new String[]{ 'Markus', 'Lehmann', 'Metabolic Disease' },
            new String[]{ 'Valentina', 'Greco', 'Clinical Genetics' },
            new String[]{ 'Benjamin', 'Hall', 'Metabolic Disease' },
            new String[]{ 'Claire', 'Dumont', 'Clinical Genetics' },
            new String[]{ 'Stephen', 'Murray', 'Metabolic Disease' },
            new String[]{ 'Andrea', 'Marino', 'Clinical Genetics' }
        };
        for (String[] d : hcpData) {
            hcps.add(hcp(d[0], d[1], d[2], tag));
        }
        List<Account> insertedHcps = insertAccounts(hcps);

        for (Integer i = 0; i < insertedHcps.size(); i++) {
            for (Integer j = 0; j < hcpData.size(); j++) {
                if (insertedHcps[i].FirstName == hcpData[j][0] && insertedHcps[i].LastName == hcpData[j][1]) {
                    specMap.put(insertedHcps[i].Id, hcpData[j][2]);
                    break;
                }
            }
        }

        List<Account> orgAccounts = new List<Account>{
            orgAccount('Center of Excellence for Rare Diseases', 'Hospital', tag),
            orgAccount('National Rare Disease Alliance', 'Partner', tag),
            orgAccount('GenomeDx Diagnostic Laboratories', 'Partner', tag),
            orgAccount('Rare Disease Patient Advocacy Foundation', 'Partner', tag),
            orgAccount('European Metabolic Disease Research Network', 'Hospital', tag)
        };
        Id bizRtId = getBusinessAccountRecordTypeId();
        if (bizRtId != null) {
            for (Account oa : orgAccounts) {
                oa.RecordTypeId = bizRtId;
            }
        }
        List<Account> insertedOrgs = insertAccounts(orgAccounts);

        List<Account> allFacilities = new List<Account>();
        allFacilities.addAll(insertedOrgs);
        allFacilities.addAll(getExistingHospitals());
        createAffiliations(insertedHcps, allFacilities, tag);
        createSpecialties(insertedHcps, specMap);
    }
}
