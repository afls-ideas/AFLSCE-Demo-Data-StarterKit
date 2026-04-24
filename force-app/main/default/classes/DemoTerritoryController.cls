/**
 * DemoTerritoryController
 * Creates a complete Territory2 hierarchy for demo orgs.
 * Callable from LWC via @AuraEnabled methods.
 */
public with sharing class DemoTerritoryController {

    private static final String MODEL_NAME = 'LSC Territory Model';
    private static final String MODEL_DEV_NAME = 'LSCTerritoryModel';

    // ── Public AuraEnabled Methods ──────────────────────────────────────

    @AuraEnabled
    public static String createTerritoryHierarchy() {
        try {
            Territory2Model model = ensureActiveModel();
            Map<String, Territory2Type> typesByName = ensureTypes();
            buildHierarchy(model.Id, typesByName);
            return 'SUCCESS: Territory hierarchy created successfully.';
        } catch (Exception e) {
            return 'ERROR: ' + e.getMessage() + ' | ' + e.getStackTraceString();
        }
    }

    @AuraEnabled
    public static String getStatus() {
        try {
            Integer modelCount = [SELECT COUNT() FROM Territory2Model WHERE DeveloperName = :MODEL_DEV_NAME];
            Integer territoryCount = [SELECT COUNT() FROM Territory2];
            Integer typeCount = [SELECT COUNT() FROM Territory2Type];
            return 'Models: ' + modelCount + ', Types: ' + typeCount + ', Territories: ' + territoryCount;
        } catch (Exception e) {
            return 'ERROR: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static String deleteAllTerritories() {
        try {
            // Delete territories (children first via bottom-up query)
            List<Territory2> territories = [
                SELECT Id FROM Territory2
                WHERE Territory2Model.DeveloperName = :MODEL_DEV_NAME
                ORDER BY Territory2.ParentTerritory2Id DESC NULLS LAST
            ];
            if (!territories.isEmpty()) {
                // Delete leaf nodes first, then parents
                List<Territory2> leaves = new List<Territory2>();
                List<Territory2> mids = new List<Territory2>();
                List<Territory2> roots = new List<Territory2>();
                for (Territory2 t : territories) {
                    if (t.ParentTerritory2Id == null) {
                        roots.add(t);
                    } else {
                        // We'll just delete all in reverse-depth order
                        mids.add(t);
                    }
                }
                if (!mids.isEmpty()) {
                    Database.delete(mids, false);
                }
                if (!roots.isEmpty()) {
                    Database.delete(roots, false);
                }
            }

            // Deactivate and delete the model
            List<Territory2Model> models = [
                SELECT Id FROM Territory2Model WHERE DeveloperName = :MODEL_DEV_NAME
            ];
            if (!models.isEmpty()) {
                for (Territory2Model m : models) {
                    m.put('State', 'Inactive');
                }
                update models;
                delete models;
            }

            return 'SUCCESS: All territories and model deleted.';
        } catch (Exception e) {
            return 'ERROR: ' + e.getMessage();
        }
    }

    // ── Model & Type Helpers ────────────────────────────────────────────

    private static Territory2Model ensureActiveModel() {
        List<Territory2Model> models = [
            SELECT Id, State FROM Territory2Model
            WHERE DeveloperName = :MODEL_DEV_NAME
            LIMIT 1
        ];
        Territory2Model model;
        if (models.isEmpty()) {
            model = new Territory2Model();
            model.DeveloperName = MODEL_DEV_NAME;
            model.MasterLabel = MODEL_NAME;
            insert model;
        } else {
            model = models[0];
        }
        // Activate if not already active
        if ((String) model.get('State') != 'Active') {
            model.put('State', 'Active');
            update model;
        }
        return model;
    }

    private static Map<String, Territory2Type> ensureTypes() {
        List<String> requiredTypes = new List<String>{ 'Geographical', 'Medical', 'KAM' };
        Map<String, Territory2Type> typesByName = new Map<String, Territory2Type>();

        for (Territory2Type t : [SELECT Id, DeveloperName, MasterLabel FROM Territory2Type]) {
            typesByName.put(t.MasterLabel, t);
        }

        List<Territory2Type> toInsert = new List<Territory2Type>();
        for (String typeName : requiredTypes) {
            if (!typesByName.containsKey(typeName)) {
                Territory2Type tt = new Territory2Type();
                tt.DeveloperName = typeName;
                tt.MasterLabel = typeName;
                tt.Priority = 1;
                toInsert.add(tt);
            }
        }
        if (!toInsert.isEmpty()) {
            Database.insert(toInsert, false);
            // Re-query to get Ids
            for (Territory2Type t : [SELECT Id, DeveloperName, MasterLabel FROM Territory2Type]) {
                typesByName.put(t.MasterLabel, t);
            }
        }
        return typesByName;
    }

    // ── Hierarchy Builder ───────────────────────────────────────────────

    private static void buildHierarchy(Id modelId, Map<String, Territory2Type> typesByName) {
        Id geoTypeId = typesByName.get('Geographical').Id;
        Id medTypeId = typesByName.get('Medical').Id;
        Id kamTypeId = typesByName.get('KAM').Id;

        // Check for existing territories to avoid duplicates
        Set<String> existingDevNames = new Set<String>();
        for (Territory2 t : [SELECT DeveloperName FROM Territory2 WHERE Territory2ModelId = :modelId]) {
            existingDevNames.add(t.DeveloperName);
        }

        // ── Level 0: GLOBAL root ──
        Id globalId = insertIfMissing('GLOBAL', 'GLOBAL', geoTypeId, modelId, null, existingDevNames);

        // ── Geographical: US ──
        Id usId = insertIfMissing('US_COUNTRY', 'US-COUNTRY', geoTypeId, modelId, globalId, existingDevNames);
        buildUSRegions(modelId, geoTypeId, usId, existingDevNames);

        // ── Geographical: GB ──
        Id gbId = insertIfMissing('GB_COUNTRY', 'GB-COUNTRY', geoTypeId, modelId, globalId, existingDevNames);
        buildCountryLeaves(modelId, geoTypeId, gbId, existingDevNames, new List<String[]>{
            new String[]{ 'GB_England_London',     'GB-England-London' },
            new String[]{ 'GB_England_Manchester',  'GB-England-Manchester' },
            new String[]{ 'GB_England_Birmingham',  'GB-England-Birmingham' },
            new String[]{ 'GB_Scotland_Edinburgh',  'GB-Scotland-Edinburgh' },
            new String[]{ 'GB_Wales_Cardiff',       'GB-Wales-Cardiff' }
        });

        // ── Geographical: FR ──
        Id frId = insertIfMissing('FR_COUNTRY', 'FR-COUNTRY', geoTypeId, modelId, globalId, existingDevNames);
        buildCountryLeaves(modelId, geoTypeId, frId, existingDevNames, new List<String[]>{
            new String[]{ 'FR_Ile_de_France_Paris',   'FR-Ile-de-France-Paris' },
            new String[]{ 'FR_Auvergne_Lyon',         'FR-Auvergne-Lyon' },
            new String[]{ 'FR_PACA_Marseille',         'FR-PACA-Marseille' },
            new String[]{ 'FR_Occitanie_Toulouse',     'FR-Occitanie-Toulouse' },
            new String[]{ 'FR_Hauts_de_France_Lille',  'FR-Hauts-de-France-Lille' }
        });

        // ── Geographical: DE ──
        Id deId = insertIfMissing('DE_COUNTRY', 'DE-COUNTRY', geoTypeId, modelId, globalId, existingDevNames);
        buildCountryLeaves(modelId, geoTypeId, deId, existingDevNames, new List<String[]>{
            new String[]{ 'DE_Bavaria_Munich',    'DE-Bavaria-Munich' },
            new String[]{ 'DE_Berlin_Berlin',     'DE-Berlin-Berlin' },
            new String[]{ 'DE_Hesse_Frankfurt',   'DE-Hesse-Frankfurt' },
            new String[]{ 'DE_NRW_Dusseldorf',    'DE-NRW-Dusseldorf' },
            new String[]{ 'DE_Hamburg_Hamburg',    'DE-Hamburg-Hamburg' }
        });

        // ── Geographical: IT ──
        Id itId = insertIfMissing('IT_COUNTRY', 'IT-COUNTRY', geoTypeId, modelId, globalId, existingDevNames);
        buildCountryLeaves(modelId, geoTypeId, itId, existingDevNames, new List<String[]>{
            new String[]{ 'IT_Lazio_Rome',       'IT-Lazio-Rome' },
            new String[]{ 'IT_Lombardy_Milan',   'IT-Lombardy-Milan' },
            new String[]{ 'IT_Campania_Naples',  'IT-Campania-Naples' },
            new String[]{ 'IT_Veneto_Venice',    'IT-Veneto-Venice' },
            new String[]{ 'IT_Tuscany_Florence', 'IT-Tuscany-Florence' }
        });

        // ── Geographical: ES ──
        Id esId = insertIfMissing('ES_COUNTRY', 'ES-COUNTRY', geoTypeId, modelId, globalId, existingDevNames);
        buildCountryLeaves(modelId, geoTypeId, esId, existingDevNames, new List<String[]>{
            new String[]{ 'ES_Madrid_Madrid',        'ES-Madrid-Madrid' },
            new String[]{ 'ES_Catalonia_Barcelona',  'ES-Catalonia-Barcelona' },
            new String[]{ 'ES_Andalusia_Seville',    'ES-Andalusia-Seville' },
            new String[]{ 'ES_Valencia_Valencia',     'ES-Valencia-Valencia' },
            new String[]{ 'ES_Basque_Bilbao',         'ES-Basque-Bilbao' }
        });

        // ── Medical hierarchy ──
        Id medRootId = insertIfMissing('MEDICAL', 'MEDICAL', medTypeId, modelId, globalId, existingDevNames);
        buildMedicalHierarchy(modelId, medTypeId, medRootId, existingDevNames);

        // ── KAM hierarchy ──
        Id kamRootId = insertIfMissing('KAM', 'KAM', kamTypeId, modelId, globalId, existingDevNames);
        buildKAMHierarchy(modelId, kamTypeId, kamRootId, existingDevNames);
    }

    // ── US Regions ──────────────────────────────────────────────────────

    private static void buildUSRegions(Id modelId, Id typeId, Id usId, Set<String> existing) {
        // Northeast
        Id neId = insertIfMissing('US_Northeast', 'US-Northeast', typeId, modelId, usId, existing);
        buildCountryLeaves(modelId, typeId, neId, existing, new List<String[]>{
            new String[]{ 'US_NE_New_York',       'US-NE-New York' },
            new String[]{ 'US_NE_Boston',          'US-NE-Boston' },
            new String[]{ 'US_NE_Philadelphia',    'US-NE-Philadelphia' },
            new String[]{ 'US_NE_Washington_DC',   'US-NE-Washington DC' }
        });

        // Southeast
        Id seId = insertIfMissing('US_Southeast', 'US-Southeast', typeId, modelId, usId, existing);
        buildCountryLeaves(modelId, typeId, seId, existing, new List<String[]>{
            new String[]{ 'US_SE_Atlanta',    'US-SE-Atlanta' },
            new String[]{ 'US_SE_Miami',      'US-SE-Miami' },
            new String[]{ 'US_SE_Charlotte',  'US-SE-Charlotte' },
            new String[]{ 'US_SE_Nashville',  'US-SE-Nashville' }
        });

        // Midwest
        Id mwId = insertIfMissing('US_Midwest', 'US-Midwest', typeId, modelId, usId, existing);
        buildCountryLeaves(modelId, typeId, mwId, existing, new List<String[]>{
            new String[]{ 'US_MW_Chicago',      'US-MW-Chicago' },
            new String[]{ 'US_MW_Detroit',      'US-MW-Detroit' },
            new String[]{ 'US_MW_Minneapolis',  'US-MW-Minneapolis' },
            new String[]{ 'US_MW_Kansas_City',  'US-MW-Kansas City' }
        });

        // West
        Id wId = insertIfMissing('US_West', 'US-West', typeId, modelId, usId, existing);
        buildCountryLeaves(modelId, typeId, wId, existing, new List<String[]>{
            new String[]{ 'US_W_Los_Angeles',    'US-W-Los Angeles' },
            new String[]{ 'US_W_San_Francisco',  'US-W-San Francisco' },
            new String[]{ 'US_W_Seattle',        'US-W-Seattle' },
            new String[]{ 'US_W_Denver',         'US-W-Denver' }
        });
    }

    // ── Medical Hierarchy ───────────────────────────────────────────────

    private static void buildMedicalHierarchy(Id modelId, Id typeId, Id medRootId, Set<String> existing) {
        // Oncology
        Id oncId = insertIfMissing('MED_Oncology', 'MED-Oncology', typeId, modelId, medRootId, existing);
        buildCountryLeaves(modelId, typeId, oncId, existing, new List<String[]>{
            new String[]{ 'MED_ONC_Solid_Tumors',      'MED-ONC-Solid Tumors' },
            new String[]{ 'MED_ONC_Hematology',         'MED-ONC-Hematology' },
            new String[]{ 'MED_ONC_Immuno_Oncology',    'MED-ONC-Immuno-Oncology' }
        });

        // Cardiology
        Id cardId = insertIfMissing('MED_Cardiology', 'MED-Cardiology', typeId, modelId, medRootId, existing);
        buildCountryLeaves(modelId, typeId, cardId, existing, new List<String[]>{
            new String[]{ 'MED_CARD_Heart_Failure',      'MED-CARD-Heart Failure' },
            new String[]{ 'MED_CARD_Interventional',     'MED-CARD-Interventional' },
            new String[]{ 'MED_CARD_Electrophysiology',  'MED-CARD-Electrophysiology' }
        });

        // Neurology
        Id neuroId = insertIfMissing('MED_Neurology', 'MED-Neurology', typeId, modelId, medRootId, existing);
        buildCountryLeaves(modelId, typeId, neuroId, existing, new List<String[]>{
            new String[]{ 'MED_NEURO_Movement_Disorders',  'MED-NEURO-Movement Disorders' },
            new String[]{ 'MED_NEURO_Multiple_Sclerosis',  'MED-NEURO-Multiple Sclerosis' },
            new String[]{ 'MED_NEURO_Epilepsy',            'MED-NEURO-Epilepsy' }
        });

        // Immunology
        Id immId = insertIfMissing('MED_Immunology', 'MED-Immunology', typeId, modelId, medRootId, existing);
        buildCountryLeaves(modelId, typeId, immId, existing, new List<String[]>{
            new String[]{ 'MED_IMM_Rheumatology',      'MED-IMM-Rheumatology' },
            new String[]{ 'MED_IMM_Dermatology',        'MED-IMM-Dermatology' },
            new String[]{ 'MED_IMM_Gastroenterology',   'MED-IMM-Gastroenterology' }
        });

        // Primary Care
        Id pcId = insertIfMissing('MED_Primary_Care', 'MED-Primary Care', typeId, modelId, medRootId, existing);
        buildCountryLeaves(modelId, typeId, pcId, existing, new List<String[]>{
            new String[]{ 'MED_PC_Internal_Medicine',  'MED-PC-Internal Medicine' },
            new String[]{ 'MED_PC_Family_Medicine',    'MED-PC-Family Medicine' },
            new String[]{ 'MED_PC_Pediatrics',         'MED-PC-Pediatrics' }
        });
    }

    // ── KAM Hierarchy ───────────────────────────────────────────────────

    private static void buildKAMHierarchy(Id modelId, Id typeId, Id kamRootId, Set<String> existing) {
        // Academic Medical Centers
        Id amcId = insertIfMissing('KAM_Academic_Medical_Centers', 'KAM-Academic Medical Centers', typeId, modelId, kamRootId, existing);
        buildCountryLeaves(modelId, typeId, amcId, existing, new List<String[]>{
            new String[]{ 'KAM_AMC_Research_Universities',  'KAM-AMC-Research Universities' },
            new String[]{ 'KAM_AMC_Teaching_Hospitals',      'KAM-AMC-Teaching Hospitals' }
        });

        // Hospital Systems
        Id hsId = insertIfMissing('KAM_Hospital_Systems', 'KAM-Hospital Systems', typeId, modelId, kamRootId, existing);
        buildCountryLeaves(modelId, typeId, hsId, existing, new List<String[]>{
            new String[]{ 'KAM_HS_Large_Health_Systems',  'KAM-HS-Large Health Systems' },
            new String[]{ 'KAM_HS_Regional_Networks',      'KAM-HS-Regional Networks' }
        });

        // Payer-Insurance
        Id payId = insertIfMissing('KAM_Payer_Insurance', 'KAM-Payer-Insurance', typeId, modelId, kamRootId, existing);
        buildCountryLeaves(modelId, typeId, payId, existing, new List<String[]>{
            new String[]{ 'KAM_PAY_Commercial',        'KAM-PAY-Commercial' },
            new String[]{ 'KAM_PAY_Medicare_Medicaid',  'KAM-PAY-Medicare-Medicaid' },
            new String[]{ 'KAM_PAY_PBM',               'KAM-PAY-PBM' }
        });

        // IDN
        Id idnId = insertIfMissing('KAM_IDN', 'KAM-IDN', typeId, modelId, kamRootId, existing);
        buildCountryLeaves(modelId, typeId, idnId, existing, new List<String[]>{
            new String[]{ 'KAM_IDN_National',  'KAM-IDN-National' },
            new String[]{ 'KAM_IDN_Regional',  'KAM-IDN-Regional' }
        });

        // Government-VA
        Id govId = insertIfMissing('KAM_Government_VA', 'KAM-Government-VA', typeId, modelId, kamRootId, existing);
        buildCountryLeaves(modelId, typeId, govId, existing, new List<String[]>{
            new String[]{ 'KAM_GOV_VA_Medical_Centers',  'KAM-GOV-VA Medical Centers' },
            new String[]{ 'KAM_GOV_Military',             'KAM-GOV-Military' }
        });
    }

    // ── Shared Insert Helpers ───────────────────────────────────────────

    private static void buildCountryLeaves(
        Id modelId, Id typeId, Id parentId, Set<String> existing, List<String[]> nodes
    ) {
        List<Territory2> toInsert = new List<Territory2>();
        for (String[] node : nodes) {
            String devName = node[0];
            String label = node[1];
            if (!existing.contains(devName)) {
                toInsert.add(buildTerritory(devName, label, typeId, modelId, parentId));
            }
        }
        if (!toInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(toInsert, false);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'Territory insert error: ' + err.getMessage());
                    }
                }
            }
        }
    }

    private static Id insertIfMissing(
        String devName, String label, Id typeId, Id modelId, Id parentId, Set<String> existing
    ) {
        if (existing.contains(devName)) {
            // Already exists, query its Id
            List<Territory2> matches = [
                SELECT Id FROM Territory2
                WHERE DeveloperName = :devName AND Territory2ModelId = :modelId
                LIMIT 1
            ];
            return matches.isEmpty() ? null : matches[0].Id;
        }

        Territory2 t = buildTerritory(devName, label, typeId, modelId, parentId);
        Database.SaveResult sr = Database.insert(t, false);
        if (sr.isSuccess()) {
            existing.add(devName);
            return sr.getId();
        } else {
            String errMsg = '';
            for (Database.Error err : sr.getErrors()) {
                errMsg += err.getMessage() + '; ';
            }
            throw new TerritoryException('Failed to insert territory "' + label + '": ' + errMsg);
        }
    }

    private static Territory2 buildTerritory(
        String devName, String label, Id typeId, Id modelId, Id parentId
    ) {
        Territory2 t = new Territory2();
        t.DeveloperName = devName;
        t.Name = label;
        t.Territory2TypeId = typeId;
        t.Territory2ModelId = modelId;
        if (parentId != null) {
            t.ParentTerritory2Id = parentId;
        }
        return t;
    }

    public class TerritoryException extends Exception {}
}
