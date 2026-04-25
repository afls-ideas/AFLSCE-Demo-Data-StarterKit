/**
 * DemoAccountProviderController
 * Creates realistic demo data for Accounts and Healthcare Providers across 6 countries.
 * Uses proper record types:
 *   - Health_Care_Organization for hospitals, clinics, pharmacies, payers
 *   - Health_Care_Provider (PersonAccount) for individual doctors
 * Tagging strategy:
 *   - Account.Site = 'AFLSCE-Demo-Data'
 *   - HealthcareProvider.SourceSystem = 'AFLSCE-Demo-Data'
 *   - HealthcareProviderNpi.SourceSystem = 'AFLSCE-Demo-Data'
 *   - HealthcareProviderSpecialty.SourceSystem = 'AFLSCE-Demo-Data'
 *   - ProviderAffiliation.SourceSystemName = 'AFLSCE-Demo-Data'
 *   - CareSpecialty.Description = 'AFLSCE-Demo-Data'
 */
public with sharing class DemoAccountProviderController {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';

    @AuraEnabled
    public static String createAccountsAndProviders() {
        try {
            Id hcoRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Health_Care_Organization').getRecordTypeId();
            Id hcpRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Health_Care_Provider').getRecordTypeId();

            // 1. Create organization accounts (hospitals, clinics, payers, pharmacies)
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.DuplicateRuleHeader.AllowSave = true;
            List<Account> orgAccounts = buildOrganizationAccounts(hcoRtId);
            Database.SaveResult[] orgResults = Database.insert(orgAccounts, dmlOpts);

            Map<String, Id> orgNameToId = new Map<String, Id>();
            List<String> errors = new List<String>();
            for (Integer i = 0; i < orgAccounts.size(); i++) {
                if (orgResults[i].isSuccess()) {
                    orgNameToId.put(orgAccounts[i].Name, orgResults[i].getId());
                } else if (errors.size() < 5) {
                    errors.add(orgAccounts[i].Name + ': ' + orgResults[i].getErrors()[0].getMessage());
                }
            }

            // 2. Create doctor PersonAccounts
            List<Account> doctorAccounts = buildDoctorAccounts(hcpRtId);
            Database.SaveResult[] docResults = Database.insert(doctorAccounts, dmlOpts);

            // PersonAccount Name = "FirstName LastName", key by full name
            Map<String, Id> doctorNameToId = new Map<String, Id>();
            for (Integer i = 0; i < doctorAccounts.size(); i++) {
                if (docResults[i].isSuccess()) {
                    String fullName = doctorAccounts[i].FirstName + ' ' + doctorAccounts[i].LastName;
                    doctorNameToId.put(fullName, docResults[i].getId());
                } else if (errors.size() < 5) {
                    errors.add(doctorAccounts[i].LastName + ': ' + docResults[i].getErrors()[0].getMessage());
                }
            }

            // Health Cloud objects
            Integer hcpSuccess = 0;
            Integer npiSuccess = 0;
            Integer specSuccess = 0;
            Integer afflSuccess = 0;

            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

            Map<String, Id> hcpNameToId = new Map<String, Id>();

            if (gd.containsKey('healthcareprovider')) {
                // 3. Create HealthcareProvider records linked to doctor PersonAccounts
                List<SObject> hcpRecords = buildHealthcareProviders(doctorNameToId);
                Database.SaveResult[] hcpResults = Database.insert(hcpRecords, false);
                for (Integer i = 0; i < hcpRecords.size(); i++) {
                    if (hcpResults[i].isSuccess()) {
                        hcpSuccess++;
                        hcpNameToId.put((String) hcpRecords[i].get('Name'), hcpResults[i].getId());
                    }
                }

                // 4. NPIs
                if (gd.containsKey('healthcareprovidernpi')) {
                    List<SObject> npiRecords = buildNpiRecords(hcpNameToId);
                    Database.SaveResult[] npiResults = Database.insert(npiRecords, false);
                    for (Integer i = 0; i < npiRecords.size(); i++) {
                        if (npiResults[i].isSuccess()) {
                            npiSuccess++;
                        } else if (errors.size() < 10) {
                            errors.add('NPI ' + npiRecords[i].get('Name') + ': ' + npiResults[i].getErrors()[0].getMessage());
                        }
                    }
                }

                // 5. Specialties
                if (gd.containsKey('healthcareproviderspecialty') && gd.containsKey('carespecialty')) {
                    Map<String, Id> specNameToId = createCareSpecialties();
                    List<SObject> specRecords = buildSpecialtyRecords(hcpNameToId, doctorNameToId, specNameToId);
                    Database.SaveResult[] specResults = Database.insert(specRecords, false);
                    for (Database.SaveResult sr : specResults) {
                        if (sr.isSuccess()) {
                            specSuccess++;
                        } else if (errors.size() < 10) {
                            errors.add('Specialty: ' + sr.getErrors()[0].getMessage());
                        }
                    }
                }

                // 6. Affiliations: doctor PersonAccount -> organization
                // Delegated to separate class due to Schema visibility issue
                try {
                    afflSuccess = DemoAffiliationHelper.createAffiliations(doctorNameToId, orgNameToId);
                } catch (Exception afflEx) {
                    errors.add('Affiliations: ' + afflEx.getMessage());
                }
            }

            String result = 'Demo data created. '
                + 'Orgs: ' + orgNameToId.size()
                + ', Doctors: ' + doctorNameToId.size()
                + ', HCPs: ' + hcpSuccess
                + ', NPIs: ' + npiSuccess
                + ', Specialties: ' + specSuccess
                + ', Affiliations: ' + afflSuccess;

            if (!errors.isEmpty()) {
                result += ' | Errors: ' + String.join(errors, '; ');
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error creating demo data: ' + e.getMessage()
                + ' [' + e.getStackTraceString() + ']'
            );
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getStatus() {
        try {
            Integer orgCount = [SELECT COUNT() FROM Account WHERE Site = :DEMO_TAG AND IsPersonAccount = false];
            Integer docCount = [SELECT COUNT() FROM Account WHERE Site = :DEMO_TAG AND IsPersonAccount = true];

            String result = 'Orgs: ' + orgCount + ', Doctors: ' + docCount;

            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            if (gd.containsKey('healthcareprovider')) {
                String soql = 'SELECT COUNT() FROM HealthcareProvider WHERE SourceSystem = \'' + String.escapeSingleQuotes(DEMO_TAG) + '\'';
                result += ', HCPs: ' + Database.countQuery(soql);
            }
            if (gd.containsKey('healthcareprovidernpi')) {
                String soql = 'SELECT COUNT() FROM HealthcareProviderNpi WHERE SourceSystem = \'' + String.escapeSingleQuotes(DEMO_TAG) + '\'';
                result += ', NPIs: ' + Database.countQuery(soql);
            }
            if (gd.containsKey('healthcareproviderspecialty')) {
                String soql = 'SELECT COUNT() FROM HealthcareProviderSpecialty WHERE SourceSystem = \'' + String.escapeSingleQuotes(DEMO_TAG) + '\'';
                result += ', Specialties: ' + Database.countQuery(soql);
            }
            if (gd.containsKey('provideracctterritoryinfo')) {
                String soql = 'SELECT COUNT() FROM ProviderAcctTerritoryInfo WHERE SourceSystemName = \'' + String.escapeSingleQuotes(DEMO_TAG) + '\'';
                result += ', PATI: ' + Database.countQuery(soql);
            }
            if (gd.containsKey('prvdaccountterritorysummary')) {
                String soql = 'SELECT COUNT() FROM PrvdAccountTerritorySummary WHERE SourceSystemName = \'' + String.escapeSingleQuotes(DEMO_TAG) + '\'';
                result += ', Summaries: ' + Database.countQuery(soql);
            }
            try {
                result += ', Affiliations: ' + DemoAffiliationHelper.countAffiliations();
            } catch (Exception e) {
                // Object not available
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting status: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String deleteAccountsAndProviders() {
        try {
            Integer deleted = 0;
            String escapedTag = String.escapeSingleQuotes(DEMO_TAG);

            // Delete child objects first (reverse order)
            try {
                deleted += DemoAffiliationHelper.deleteAffiliations();
            } catch (Exception e) { /* Object not available */ }

            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

            if (gd.containsKey('healthcareproviderspecialty')) {
                List<SObject> recs = Database.query('SELECT Id FROM HealthcareProviderSpecialty WHERE SourceSystem = \'' + escapedTag + '\'');
                if (!recs.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(recs, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }
            }

            if (gd.containsKey('healthcareprovidernpi')) {
                List<SObject> recs = Database.query('SELECT Id FROM HealthcareProviderNpi WHERE SourceSystem = \'' + escapedTag + '\'');
                if (!recs.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(recs, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }
            }

            if (gd.containsKey('healthcareprovider')) {
                List<SObject> recs = Database.query('SELECT Id FROM HealthcareProvider WHERE SourceSystem = \'' + escapedTag + '\'');
                if (!recs.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(recs, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }
            }

            if (gd.containsKey('prvdaccountterritorysummary')) {
                List<SObject> recs = Database.query('SELECT Id FROM PrvdAccountTerritorySummary WHERE SourceSystemName = \'' + escapedTag + '\'');
                if (!recs.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(recs, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }
            }

            if (gd.containsKey('provideracctterritoryinfo')) {
                List<SObject> recs = Database.query('SELECT Id FROM ProviderAcctTerritoryInfo WHERE SourceSystemName = \'' + escapedTag + '\'');
                if (!recs.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(recs, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }
            }

            if (gd.containsKey('carespecialty')) {
                List<SObject> recs = Database.query('SELECT Id FROM CareSpecialty WHERE Description = \'' + escapedTag + '\'');
                if (!recs.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(recs, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }
            }

            // Delete accounts last (both orgs and person accounts)
            List<Account> accts = [SELECT Id FROM Account WHERE Site = :DEMO_TAG];
            if (!accts.isEmpty()) {
                Database.DeleteResult[] dr = Database.delete(accts, false);
                for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
            }

            return 'Deleted ' + deleted + ' demo records.';
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting demo data: ' + e.getMessage());
        }
    }

    // ---------------------------------------------------------------------------
    // Organization Account builders (Health_Care_Organization record type)
    // ---------------------------------------------------------------------------

    private static List<Account> buildOrganizationAccounts(Id hcoRtId) {
        List<Account> accts = new List<Account>();

        // ---- United States (10) ----
        accts.add(makeOrg(hcoRtId, 'Massachusetts General Hospital', '55 Fruit Street', 'Boston', 'MA', '02114', 'US', '+1 (617) 726-2000', 'https://www.massgeneral.org', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Johns Hopkins Hospital', '1800 Orleans Street', 'Baltimore', 'MD', '21287', 'US', '+1 (410) 955-5000', 'https://www.hopkinsmedicine.org', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Cleveland Clinic', '9500 Euclid Avenue', 'Cleveland', 'OH', '44195', 'US', '+1 (216) 444-2200', 'https://www.clevelandclinic.org', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Mayo Clinic', '200 First Street SW', 'Rochester', 'MN', '55905', 'US', '+1 (507) 284-2511', 'https://www.mayoclinic.org', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Memorial Sloan Kettering Cancer Center', '1275 York Avenue', 'New York', 'NY', '10065', 'US', '+1 (212) 639-2000', 'https://www.mskcc.org', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'MD Anderson Cancer Center', '1515 Holcombe Boulevard', 'Houston', 'TX', '77030', 'US', '+1 (713) 792-2121', 'https://www.mdanderson.org', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Kaiser Permanente', '1 Kaiser Plaza', 'Oakland', 'CA', '94612', 'US', '+1 (510) 271-5910', 'https://www.kaiserpermanente.org', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'UnitedHealth Group', '9900 Bren Road East', 'Minnetonka', 'MN', '55343', 'US', '+1 (952) 936-1300', 'https://www.unitedhealthgroup.com', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'CVS Health', '1 CVS Drive', 'Woonsocket', 'RI', '02895', 'US', '+1 (401) 765-1500', 'https://www.cvshealth.com', 'Pharmacy'));
        accts.add(makeOrg(hcoRtId, 'Midtown Oncology Associates', '450 East 63rd Street', 'New York', 'NY', '10065', 'US', '+1 (212) 305-5098', 'https://www.midtownoncology.com', 'Clinic'));

        // ---- United Kingdom (10) ----
        accts.add(makeOrg(hcoRtId, 'Royal London Hospital', 'Whitechapel Road', 'London', null, 'E1 1FR', 'GB', '+44 20 7377 7000', 'https://www.bartshealth.nhs.uk', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'St Thomas\' Hospital', 'Westminster Bridge Road', 'London', null, 'SE1 7EH', 'GB', '+44 20 7188 7188', 'https://www.guysandstthomas.nhs.uk', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Addenbrooke\'s Hospital', 'Hills Road', 'Cambridge', null, 'CB2 0QQ', 'GB', '+44 1223 245151', 'https://www.cuh.nhs.uk', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Royal Papworth Hospital', 'Papworth Road', 'Cambridge', null, 'CB2 0AY', 'GB', '+44 1223 638000', 'https://www.royalpapworth.nhs.uk', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Great Ormond Street Hospital', 'Great Ormond Street', 'London', null, 'WC1N 3JH', 'GB', '+44 20 7405 9200', 'https://www.gosh.nhs.uk', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'The Christie NHS Foundation Trust', 'Wilmslow Road', 'Manchester', null, 'M20 4BX', 'GB', '+44 161 446 3000', 'https://www.christie.nhs.uk', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'NHS England', 'Skipton House, 80 London Road', 'London', null, 'SE1 6LH', 'GB', '+44 300 311 2233', 'https://www.england.nhs.uk', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'BUPA', '1 Angel Court', 'London', null, 'EC2R 7HJ', 'GB', '+44 345 600 8822', 'https://www.bupa.co.uk', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'Boots UK', 'Thane Road', 'Nottingham', null, 'NG2 3AA', 'GB', '+44 115 950 6111', 'https://www.boots.com', 'Pharmacy'));
        accts.add(makeOrg(hcoRtId, 'Harley Street Clinic', '35 Weymouth Street', 'London', null, 'W1G 8BJ', 'GB', '+44 20 7935 7700', 'https://www.theharleystreetclinic.co.uk', 'Clinic'));

        // ---- France (10) ----
        accts.add(makeOrg(hcoRtId, 'Hôpital Pitié-Salpêtrière', '47-83 Boulevard de l\'Hôpital', 'Paris', null, '75013', 'FR', '+33 1 42 16 00 00', 'https://www.aphp.fr/pitie-salpetriere', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hôpital Européen Georges-Pompidou', '20 Rue Leblanc', 'Paris', null, '75015', 'FR', '+33 1 56 09 20 00', 'https://www.aphp.fr/hegp', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Centre Hospitalier Universitaire de Lyon', '3 Quai des Célestins', 'Lyon', null, '69002', 'FR', '+33 4 72 11 69 11', 'https://www.chu-lyon.fr', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Institut Gustave Roussy', '114 Rue Édouard-Vaillant', 'Villejuif', null, '94805', 'FR', '+33 1 42 11 42 11', 'https://www.gustaveroussy.fr', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hôpital Necker-Enfants Malades', '149 Rue de Sèvres', 'Paris', null, '75015', 'FR', '+33 1 44 49 40 00', 'https://www.aphp.fr/necker', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'CHU de Toulouse', '2 Rue Viguerie', 'Toulouse', null, '31059', 'FR', '+33 5 61 77 22 33', 'https://www.chu-toulouse.fr', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Centre Léon Bérard', '28 Rue Laënnec', 'Lyon', null, '69008', 'FR', '+33 4 78 78 51 51', 'https://www.centreleonberard.fr', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Assurance Maladie (CNAM)', '50 Avenue du Professeur André Lemierre', 'Paris', null, '75020', 'FR', '+33 1 72 60 10 00', 'https://www.ameli.fr', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'Pharmacie du Forum des Halles', '101 Rue Berger', 'Paris', null, '75001', 'FR', '+33 1 42 36 00 00', 'https://www.pharmacieforum.fr', 'Pharmacy'));
        accts.add(makeOrg(hcoRtId, 'Clinique de la Muette', '46 Rue Nicolo', 'Paris', null, '75016', 'FR', '+33 1 45 04 67 67', 'https://www.cliniquemuette.fr', 'Clinic'));

        // ---- Germany (10) ----
        accts.add(makeOrg(hcoRtId, 'Charité - Universitätsmedizin Berlin', 'Charitéplatz 1', 'Berlin', null, '10117', 'DE', '+49 30 450 50', 'https://www.charite.de', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Universitätsklinikum Heidelberg', 'Im Neuenheimer Feld 672', 'Heidelberg', null, '69120', 'DE', '+49 6221 56 0', 'https://www.klinikum.uni-heidelberg.de', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Universitätsklinikum Hamburg-Eppendorf', 'Martinistraße 52', 'Hamburg', null, '20246', 'DE', '+49 40 7410 0', 'https://www.uke.de', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Klinikum der Universität München', 'Marchioninistraße 15', 'Munich', null, '81377', 'DE', '+49 89 4400 0', 'https://www.lmu-klinikum.de', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Universitätsklinikum Düsseldorf', 'Moorenstraße 5', 'Dusseldorf', null, '40225', 'DE', '+49 211 81 00', 'https://www.uniklinik-duesseldorf.de', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Universitätsklinikum Frankfurt', 'Theodor-Stern-Kai 7', 'Frankfurt', null, '60590', 'DE', '+49 69 6301 0', 'https://www.kgu.de', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Munich Heart Centre', 'Lazarettstraße 36', 'Munich', null, '80636', 'DE', '+49 89 1218 0', 'https://www.dhm.mhn.de', 'Clinic'));
        accts.add(makeOrg(hcoRtId, 'AOK - Die Gesundheitskasse', 'Rosenthaler Straße 31', 'Berlin', null, '10178', 'DE', '+49 800 265 0800', 'https://www.aok.de', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'Techniker Krankenkasse', 'Bramfelder Straße 140', 'Hamburg', null, '22305', 'DE', '+49 800 285 8585', 'https://www.tk.de', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'DocMorris', 'Carl-Zeiss-Ring 4', 'Heerlen', null, '52078', 'DE', '+49 800 444 0200', 'https://www.docmorris.de', 'Pharmacy'));

        // ---- Italy (10) ----
        accts.add(makeOrg(hcoRtId, 'Policlinico Agostino Gemelli', 'Largo Agostino Gemelli 8', 'Rome', 'RM', '00168', 'IT', '+39 06 3015 1', 'https://www.policlinicogemelli.it', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Ospedale San Raffaele', 'Via Olgettina 60', 'Milan', 'MI', '20132', 'IT', '+39 02 2643 2643', 'https://www.hsr.it', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Istituto Europeo di Oncologia', 'Via Ripamonti 435', 'Milan', 'MI', '20141', 'IT', '+39 02 5748 9001', 'https://www.ieo.it', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Azienda Ospedaliera di Padova', 'Via Giustiniani 2', 'Padua', 'PD', '35128', 'IT', '+39 049 821 1111', 'https://www.aopd.veneto.it', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Ospedale Pediatrico Bambino Gesù', 'Piazza Sant\'Onofrio 4', 'Rome', 'RM', '00165', 'IT', '+39 06 6859 1', 'https://www.ospedalebambinogesu.it', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Azienda Ospedaliera di Napoli', 'Via Sergio Pansini 5', 'Naples', 'NA', '80131', 'IT', '+39 081 746 1111', 'https://www.policlinico.unina.it', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Ospedale Careggi', 'Largo Brambilla 3', 'Florence', 'FI', '50134', 'IT', '+39 055 794 1', 'https://www.aou-careggi.toscana.it', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'ASL Roma 1', 'Borgo Santo Spirito 3', 'Rome', 'RM', '00193', 'IT', '+39 06 6835 1', 'https://www.aslroma1.it', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'Humanitas Research Hospital', 'Via Manzoni 56', 'Milan', 'MI', '20089', 'IT', '+39 02 8224 1', 'https://www.humanitas.it', 'Clinic'));
        accts.add(makeOrg(hcoRtId, 'Farmacia del Corso', 'Corso Buenos Aires 4', 'Milan', 'MI', '20124', 'IT', '+39 02 2951 4380', 'https://www.farmaciadelcorso.it', 'Pharmacy'));

        // ---- Spain (10) ----
        accts.add(makeOrg(hcoRtId, 'Hospital Clínic de Barcelona', 'Carrer de Villarroel 170', 'Barcelona', null, '08036', 'ES', '+34 93 227 54 00', 'https://www.clinicbarcelona.org', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital Universitario La Paz', 'Paseo de la Castellana 261', 'Madrid', null, '28046', 'ES', '+34 91 727 70 00', 'https://www.comunidad.madrid/hospital/lapaz', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital Universitario Vall d\'Hebron', 'Passeig de la Vall d\'Hebron 119-129', 'Barcelona', null, '08035', 'ES', '+34 93 274 60 00', 'https://www.vallhebron.com', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital Universitario 12 de Octubre', 'Avenida de Córdoba s/n', 'Madrid', null, '28041', 'ES', '+34 91 390 80 00', 'https://www.comunidad.madrid/hospital/12octubre', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital Virgen del Rocío', 'Avenida Manuel Siurot s/n', 'Seville', null, '41013', 'ES', '+34 955 01 20 00', 'https://www.hospitalvirgendelrocio.es', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital Clínico Universitario de Valencia', 'Avenida Blasco Ibáñez 17', 'Valencia', null, '46010', 'ES', '+34 96 386 26 00', 'https://www.incliva.es', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Centro Médico Teknon', 'Carrer de Vilana 12', 'Barcelona', null, '08022', 'ES', '+34 93 290 62 00', 'https://www.teknon.es', 'Clinic'));
        accts.add(makeOrg(hcoRtId, 'Sanitas', 'Ribera del Loira 52', 'Madrid', null, '28042', 'ES', '+34 91 585 29 00', 'https://www.sanitas.es', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'MAPFRE Salud', 'Carretera de Pozuelo 52', 'Madrid', null, '28222', 'ES', '+34 91 581 17 00', 'https://www.mapfre.es', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'Farmacia Ortopedia Gaztambide', 'Calle de Gaztambide 55', 'Madrid', null, '28015', 'ES', '+34 91 549 42 60', 'https://www.farmaciagaztambide.com', 'Pharmacy'));

        // ---- Japan (10) ----
        accts.add(makeOrg(hcoRtId, '東京大学医学部附属病院', '本郷7-3-1', 'Tokyo', '13', '113-8655', 'JP', '+81 3 3815 5411', 'https://www.h.u-tokyo.ac.jp', 'Hospital'));
        accts.add(makeOrg(hcoRtId, '大阪大学医学部附属病院', '山田丘2-15', 'Osaka', '27', '565-0871', 'JP', '+81 6 6879 5111', 'https://www.hosp.med.osaka-u.ac.jp', 'Hospital'));
        accts.add(makeOrg(hcoRtId, '慶應義塾大学病院', '信濃町35', 'Tokyo', '13', '160-8582', 'JP', '+81 3 3353 1211', 'https://www.hosp.keio.ac.jp', 'Hospital'));
        accts.add(makeOrg(hcoRtId, '国立がん研究センター中央病院', '築地5-1-1', 'Tokyo', '13', '104-0045', 'JP', '+81 3 3542 2511', 'https://www.ncc.go.jp', 'Hospital'));
        accts.add(makeOrg(hcoRtId, '名古屋大学医学部附属病院', '鶴舞町65', 'Nagoya', '23', '466-8560', 'JP', '+81 52 741 2111', 'https://www.med.nagoya-u.ac.jp/hospital', 'Hospital'));
        accts.add(makeOrg(hcoRtId, '京都大学医学部附属病院', '聖護院川原町54', 'Kyoto', '26', '606-8507', 'JP', '+81 75 751 3111', 'https://www.kuhp.kyoto-u.ac.jp', 'Hospital'));
        accts.add(makeOrg(hcoRtId, '聖路加国際病院', '明石町9-1', 'Tokyo', '13', '104-8560', 'JP', '+81 3 3541 5151', 'https://hospital.luke.ac.jp', 'Hospital'));
        accts.add(makeOrg(hcoRtId, '健康保険組合連合会', '霞が関1-2-1', 'Tokyo', '13', '100-8916', 'JP', '+81 3 3595 2550', 'https://www.kenporen.com', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'マツモトキヨシ', '日本橋4-1-1', 'Tokyo', '13', '103-8241', 'JP', '+81 3 3273 2000', 'https://www.matsukiyo.co.jp', 'Pharmacy'));
        accts.add(makeOrg(hcoRtId, '亀田メディカルセンター', '東町929', 'Kamogawa', '12', '296-8602', 'JP', '+81 4 7092 2211', 'https://www.kameda.com', 'Clinic'));

        // ---- South Korea (10) ----
        accts.add(makeOrg(hcoRtId, '서울대학교병원', '대학로 101', 'Seoul', '', '03080', 'KR', '+82 2 2072 2114', 'https://www.snuh.org', 'Hospital'));
        accts.add(makeOrg(hcoRtId, '삼성서울병원', '일원로 81', 'Seoul', '', '06351', 'KR', '+82 2 3410 2114', 'https://www.samsunghospital.com', 'Hospital'));
        accts.add(makeOrg(hcoRtId, '서울아산병원', '올림픽로43길 88', 'Seoul', '', '05505', 'KR', '+82 2 3010 3114', 'https://www.amc.seoul.kr', 'Hospital'));
        accts.add(makeOrg(hcoRtId, '세브란스병원', '연세로 50-1', 'Seoul', '', '03722', 'KR', '+82 2 2228 5800', 'https://www.severance.healthcare', 'Hospital'));
        accts.add(makeOrg(hcoRtId, '서울성모병원', '반포대로 222', 'Seoul', '', '06591', 'KR', '+82 2 1588 1511', 'https://www.cmcseoul.or.kr', 'Hospital'));
        accts.add(makeOrg(hcoRtId, '부산대학교병원', '구덕로 179', 'Busan', '', '49241', 'KR', '+82 51 240 7000', 'https://www.pnuh.or.kr', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'CHA 분당의료원', '야탑로 59', 'Seongnam', '', '13496', 'KR', '+82 31 780 5000', 'https://www.chamc.co.kr', 'Hospital'));
        accts.add(makeOrg(hcoRtId, '국민건강보험공단', '건강로 32', 'Wonju', '', '26464', 'KR', '+82 33 736 0000', 'https://www.nhis.or.kr', 'Insurance'));
        accts.add(makeOrg(hcoRtId, '올리브영', '퇴계로 18', 'Seoul', '', '04626', 'KR', '+82 2 6970 8114', 'https://www.oliveyoung.co.kr', 'Pharmacy'));
        accts.add(makeOrg(hcoRtId, '강남세브란스병원', '언주로 211', 'Seoul', '', '06273', 'KR', '+82 2 2019 3114', 'https://gs.severance.healthcare', 'Clinic'));

        // ---- Brazil (10) ----
        accts.add(makeOrg(hcoRtId, 'Hospital das Clínicas de São Paulo', 'Rua Dr. Ovídio Pires de Campos 225', 'São Paulo', 'SP', '05403-010', 'BR', '+55 11 2661 0000', 'https://www.hc.fm.usp.br', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital Sírio-Libanês', 'Rua Dona Adma Jafet 91', 'São Paulo', 'SP', '01308-050', 'BR', '+55 11 3155 0200', 'https://www.hospitalsiriolibanes.org.br', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital Albert Einstein', 'Avenida Albert Einstein 627', 'São Paulo', 'SP', '05652-900', 'BR', '+55 11 2151 1233', 'https://www.einstein.br', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Instituto Nacional de Câncer (INCA)', 'Praça Cruz Vermelha 23', 'Rio de Janeiro', 'RJ', '20230-130', 'BR', '+55 21 3207 1000', 'https://www.inca.gov.br', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital de Clínicas de Porto Alegre', 'Rua Ramiro Barcelos 2350', 'Porto Alegre', 'RS', '90035-903', 'BR', '+55 51 3359 8000', 'https://www.hcpa.edu.br', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital das Clínicas de Minas Gerais', 'Avenida Professor Alfredo Balena 110', 'Belo Horizonte', 'MG', '30130-100', 'BR', '+55 31 3307 9100', 'https://www.hc.ufmg.br', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital São Rafael', 'Avenida São Rafael 2152', 'Salvador', 'BA', '41253-190', 'BR', '+55 71 3281 6000', 'https://www.hospitalsaorafael.com.br', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'SUS - Sistema Único de Saúde', 'Esplanada dos Ministérios Bloco G', 'Brasília', null, '70058-900', 'BR', '+55 61 3315 2425', 'https://www.gov.br/saude', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'Drogasil', 'Avenida Corifeu de Azevedo Marques 3097', 'São Paulo', 'SP', '05339-900', 'BR', '+55 11 3003 4004', 'https://www.drogasil.com.br', 'Pharmacy'));
        accts.add(makeOrg(hcoRtId, 'Clínica Oncológica do ABC', 'Rua Piauí 421', 'São Paulo', 'SP', '01241-001', 'BR', '+55 11 3120 4700', 'https://www.oncoabc.com.br', 'Clinic'));

        // ---- Mexico (10) ----
        accts.add(makeOrg(hcoRtId, 'Instituto Nacional de Cancerología', 'Avenida San Fernando 22', 'Mexico City', '', '14080', 'MX', '+52 55 5628 0400', 'https://www.incan-mexico.org', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital General de México', 'Dr. Balmis 148', 'Mexico City', '', '06720', 'MX', '+52 55 2789 2000', 'https://www.hgm.salud.gob.mx', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Instituto Nacional de Cardiología', 'Juan Badiano 1', 'Mexico City', '', '14080', 'MX', '+52 55 5573 2911', 'https://www.cardiologia.org.mx', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital Civil de Guadalajara', 'Hospital 278', 'Guadalajara', '', '44280', 'MX', '+52 33 3614 5501', 'https://www.hcg.udg.mx', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital Universitario de Monterrey', 'Avenida Francisco I. Madero s/n', 'Monterrey', '', '64460', 'MX', '+52 81 8348 7200', 'https://www.medicina.uanl.mx/hu', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital Ángeles Puebla', 'Avenida Kepler 2143', 'Puebla', '', '72190', 'MX', '+52 222 309 7900', 'https://www.hospitalangeles.com/puebla', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Centro Médico Nacional Siglo XXI', 'Avenida Cuauhtémoc 330', 'Mexico City', '', '06720', 'MX', '+52 55 5627 6900', 'https://www.imss.gob.mx', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'IMSS - Instituto Mexicano del Seguro Social', 'Paseo de la Reforma 476', 'Mexico City', '', '06600', 'MX', '+52 55 5238 2700', 'https://www.imss.gob.mx', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'Farmacias del Ahorro', 'Avenida Insurgentes Sur 1106', 'Mexico City', '', '03720', 'MX', '+52 55 5340 1700', 'https://www.fahorro.com', 'Pharmacy'));
        accts.add(makeOrg(hcoRtId, 'Médica Sur', 'Puente de Piedra 150', 'Mexico City', '', '14050', 'MX', '+52 55 5424 7200', 'https://www.medicasur.com.mx', 'Clinic'));

        // ---- Argentina (10) ----
        accts.add(makeOrg(hcoRtId, 'Hospital Italiano de Buenos Aires', 'Juan D. Perón 4190', 'Buenos Aires', '', 'C1199ABB', 'AR', '+54 11 4959 0200', 'https://www.hospitalitaliano.org.ar', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital de Clínicas José de San Martín', 'Avenida Córdoba 2351', 'Buenos Aires', '', 'C1120AAR', 'AR', '+54 11 5950 8000', 'https://www.hospitaldeclinicas.uba.ar', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital Garrahan', 'Combate de los Pozos 1881', 'Buenos Aires', '', 'C1245AAM', 'AR', '+54 11 4122 6000', 'https://www.garrahan.gov.ar', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital Austral', 'Avenida Juan D. Perón 1500', 'Pilar', '', 'B1629AHJ', 'AR', '+54 11 2304 6000', 'https://www.hospitalaustral.edu.ar', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital Nacional de Córdoba', 'Bajada Pucará s/n', 'Córdoba', '', 'X5000', 'AR', '+54 351 433 4041', 'https://www.hospitalnacional.org.ar', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital Provincial del Centenario', 'Urquiza 3101', 'Rosario', '', 'S2000', 'AR', '+54 341 472 1111', 'https://www.hpc.org.ar', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Instituto Alexander Fleming', 'Crámer 1180', 'Buenos Aires', '', 'C1426ANZ', 'AR', '+54 11 6323 2900', 'https://www.alexanderfleming.org', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'OSDE', 'Avenida Leandro N. Alem 1067', 'Buenos Aires', '', 'C1001AAF', 'AR', '+54 11 4510 2700', 'https://www.osde.com.ar', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'Farmacity', 'Avenida Maipú 3030', 'Buenos Aires', '', 'B1636AGI', 'AR', '+54 11 4736 3600', 'https://www.farmacity.com', 'Pharmacy'));
        accts.add(makeOrg(hcoRtId, 'CEMIC', 'Avenida Galván 4102', 'Buenos Aires', '', 'C1431FWO', 'AR', '+54 11 5299 0100', 'https://www.cemic.edu.ar', 'Clinic'));

        return accts;
    }

    private static Account makeOrg(Id rtId, String name, String street, String city, String stateCode, String postalCode, String countryCode, String phone, String website, String acctType) {
        Account a = new Account();
        a.RecordTypeId = rtId;
        a.Name = name;
        a.BillingStreet = street;
        a.BillingCity = city;
        a.BillingPostalCode = postalCode;
        a.BillingCountryCode = countryCode;
        if (String.isNotBlank(stateCode)) {
            a.BillingStateCode = stateCode;
        }
        a.Phone = phone;
        a.Website = website;
        a.Industry = 'Healthcare';
        a.Type = acctType;
        a.Site = DEMO_TAG;
        a.IsActive = true;
        return a;
    }

    // ---------------------------------------------------------------------------
    // Doctor PersonAccount builders (Health_Care_Provider record type)
    // ---------------------------------------------------------------------------

    private static List<Account> buildDoctorAccounts(Id hcpRtId) {
        List<Account> docs = new List<Account>();

        // US Doctors (10)
        docs.add(makeDoctor(hcpRtId, 'Sarah', 'Mitchell', 'sarah.mitchell@massgeneral.example.com', '+1 (617) 726-2001', '55 Fruit Street', 'Boston', 'MA', '02114', 'US'));
        docs.add(makeDoctor(hcpRtId, 'James', 'Patterson', 'james.patterson@jhmi.example.com', '+1 (410) 955-5001', '1800 Orleans Street', 'Baltimore', 'MD', '21287', 'US'));
        docs.add(makeDoctor(hcpRtId, 'Emily', 'Chen', 'emily.chen@ccf.example.com', '+1 (216) 444-2201', '9500 Euclid Avenue', 'Cleveland', 'OH', '44195', 'US'));
        docs.add(makeDoctor(hcpRtId, 'Michael', 'Rodriguez', 'michael.rodriguez@mayo.example.com', '+1 (507) 284-2512', '200 First Street SW', 'Rochester', 'MN', '55905', 'US'));
        docs.add(makeDoctor(hcpRtId, 'Jennifer', 'Goldstein', 'jennifer.goldstein@mskcc.example.com', '+1 (212) 639-2001', '1275 York Avenue', 'New York', 'NY', '10065', 'US'));
        docs.add(makeDoctor(hcpRtId, 'David', 'Kumar', 'david.kumar@mdanderson.example.com', '+1 (713) 792-2122', '1515 Holcombe Boulevard', 'Houston', 'TX', '77030', 'US'));
        docs.add(makeDoctor(hcpRtId, 'Robert', 'Washington', 'robert.washington@midtownonc.example.com', '+1 (212) 305-5099', '450 East 63rd Street', 'New York', 'NY', '10065', 'US'));
        docs.add(makeDoctor(hcpRtId, 'Lisa', 'Thornton', 'lisa.thornton@kaiser.example.com', '+1 (510) 271-5911', '1 Kaiser Plaza', 'Oakland', 'CA', '94612', 'US'));
        docs.add(makeDoctor(hcpRtId, 'Andrew', 'Nakamura', 'andrew.nakamura@mayo.example.com', '+1 (507) 284-2513', '200 First Street SW', 'Rochester', 'MN', '55905', 'US'));
        docs.add(makeDoctor(hcpRtId, 'Rachel', 'Okonkwo', 'rachel.okonkwo@mskcc.example.com', '+1 (212) 639-2002', '1275 York Avenue', 'New York', 'NY', '10065', 'US'));

        // UK Doctors (10)
        docs.add(makeDoctor(hcpRtId, 'William', 'Hartley', 'william.hartley@nhs.example.com', '+44 20 7377 7001', 'Whitechapel Road', 'London', null, 'E1 1FR', 'GB'));
        docs.add(makeDoctor(hcpRtId, 'Eleanor', 'Blackwood', 'eleanor.blackwood@gstt.example.com', '+44 20 7188 7189', 'Westminster Bridge Road', 'London', null, 'SE1 7EH', 'GB'));
        docs.add(makeDoctor(hcpRtId, 'Oliver', 'Pemberton', 'oliver.pemberton@cuh.example.com', '+44 1223 245152', 'Hills Road', 'Cambridge', null, 'CB2 0QQ', 'GB'));
        docs.add(makeDoctor(hcpRtId, 'Charlotte', 'Ainsworth', 'charlotte.ainsworth@nhs.example.com', '+44 20 7377 7002', 'Whitechapel Road', 'London', null, 'E1 1FR', 'GB'));
        docs.add(makeDoctor(hcpRtId, 'George', 'Whitfield', 'george.whitfield@gstt.example.com', '+44 20 7188 7190', 'Westminster Bridge Road', 'London', null, 'SE1 7EH', 'GB'));
        docs.add(makeDoctor(hcpRtId, 'Fiona', 'MacLeod', 'fiona.macleod@papworth.example.com', '+44 1223 638001', 'Papworth Road', 'Cambridge', null, 'CB2 0AY', 'GB'));
        docs.add(makeDoctor(hcpRtId, 'James', 'Okafor', 'james.okafor@gosh.example.com', '+44 20 7405 9201', 'Great Ormond Street', 'London', null, 'WC1N 3JH', 'GB'));
        docs.add(makeDoctor(hcpRtId, 'Priya', 'Sharma', 'priya.sharma@christie.example.com', '+44 161 446 3001', 'Wilmslow Road', 'Manchester', null, 'M20 4BX', 'GB'));
        docs.add(makeDoctor(hcpRtId, 'Thomas', 'Brennan', 'thomas.brennan@nhs.example.com', '+44 20 7377 7003', 'Whitechapel Road', 'London', null, 'E1 1FR', 'GB'));
        docs.add(makeDoctor(hcpRtId, 'Sophie', 'Cartwright', 'sophie.cartwright@harleystreet.example.com', '+44 20 7935 7701', '35 Weymouth Street', 'London', null, 'W1G 8BJ', 'GB'));

        // France Doctors (10)
        docs.add(makeDoctor(hcpRtId, 'Pierre', 'Lefèvre', 'pierre.lefevre@aphp.example.com', '+33 1 42 16 00 01', '47 Boulevard de l\'Hôpital', 'Paris', null, '75013', 'FR'));
        docs.add(makeDoctor(hcpRtId, 'Marie-Claire', 'Dubois', 'marie.dubois@aphp.example.com', '+33 1 56 09 20 01', '20 Rue Leblanc', 'Paris', null, '75015', 'FR'));
        docs.add(makeDoctor(hcpRtId, 'François', 'Moreau', 'francois.moreau@chu-lyon.example.com', '+33 4 72 11 69 12', '3 Quai des Célestins', 'Lyon', null, '69002', 'FR'));
        docs.add(makeDoctor(hcpRtId, 'Camille', 'Rousseau', 'camille.rousseau@igr.example.com', '+33 1 42 11 42 12', '114 Rue Édouard-Vaillant', 'Villejuif', null, '94805', 'FR'));
        docs.add(makeDoctor(hcpRtId, 'Jean-Luc', 'Bernard', 'jeanluc.bernard@aphp.example.com', '+33 1 42 16 00 02', '47 Boulevard de l\'Hôpital', 'Paris', null, '75013', 'FR'));
        docs.add(makeDoctor(hcpRtId, 'Isabelle', 'Dupont', 'isabelle.dupont@necker.example.com', '+33 1 44 49 40 01', '149 Rue de Sèvres', 'Paris', null, '75015', 'FR'));
        docs.add(makeDoctor(hcpRtId, 'Antoine', 'Mercier', 'antoine.mercier@chu-toulouse.example.com', '+33 5 61 77 22 34', '2 Rue Viguerie', 'Toulouse', null, '31059', 'FR'));
        docs.add(makeDoctor(hcpRtId, 'Nathalie', 'Girard', 'nathalie.girard@clb.example.com', '+33 4 78 78 51 52', '28 Rue Laënnec', 'Lyon', null, '69008', 'FR'));
        docs.add(makeDoctor(hcpRtId, 'Olivier', 'Petit', 'olivier.petit@aphp.example.com', '+33 1 42 16 00 03', '47 Boulevard de l\'Hôpital', 'Paris', null, '75013', 'FR'));
        docs.add(makeDoctor(hcpRtId, 'Sophie', 'Martin', 'sophie.martin@muette.example.com', '+33 1 45 04 67 68', '46 Rue Nicolo', 'Paris', null, '75016', 'FR'));

        // Germany Doctors (10)
        docs.add(makeDoctor(hcpRtId, 'Klaus', 'Müller', 'klaus.mueller@charite.example.com', '+49 30 450 51', 'Charitéplatz 1', 'Berlin', null, '10117', 'DE'));
        docs.add(makeDoctor(hcpRtId, 'Anna', 'Schneider', 'anna.schneider@ukl-hd.example.com', '+49 6221 56 1', 'Im Neuenheimer Feld 672', 'Heidelberg', null, '69120', 'DE'));
        docs.add(makeDoctor(hcpRtId, 'Stefan', 'Weber', 'stefan.weber@uke.example.com', '+49 40 7410 1', 'Martinistraße 52', 'Hamburg', null, '20246', 'DE'));
        docs.add(makeDoctor(hcpRtId, 'Katrin', 'Fischer', 'katrin.fischer@charite.example.com', '+49 30 450 52', 'Charitéplatz 1', 'Berlin', null, '10117', 'DE'));
        docs.add(makeDoctor(hcpRtId, 'Hans-Peter', 'Braun', 'hp.braun@dhm.example.com', '+49 89 1218 1', 'Lazarettstraße 36', 'Munich', null, '80636', 'DE'));
        docs.add(makeDoctor(hcpRtId, 'Monika', 'Herrmann', 'monika.herrmann@lmu.example.com', '+49 89 4400 1', 'Marchioninistraße 15', 'Munich', null, '81377', 'DE'));
        docs.add(makeDoctor(hcpRtId, 'Thomas', 'Richter', 'thomas.richter@ukd.example.com', '+49 211 81 01', 'Moorenstraße 5', 'Dusseldorf', null, '40225', 'DE'));
        docs.add(makeDoctor(hcpRtId, 'Sabine', 'Wolf', 'sabine.wolf@kgu.example.com', '+49 69 6301 1', 'Theodor-Stern-Kai 7', 'Frankfurt', null, '60590', 'DE'));
        docs.add(makeDoctor(hcpRtId, 'Michael', 'Becker', 'michael.becker@uke.example.com', '+49 40 7410 2', 'Martinistraße 52', 'Hamburg', null, '20246', 'DE'));
        docs.add(makeDoctor(hcpRtId, 'Julia', 'Hoffmann', 'julia.hoffmann@charite.example.com', '+49 30 450 53', 'Charitéplatz 1', 'Berlin', null, '10117', 'DE'));

        // Italy Doctors (10)
        docs.add(makeDoctor(hcpRtId, 'Marco', 'Rossi', 'marco.rossi@gemelli.example.com', '+39 06 3015 2', 'Largo Agostino Gemelli 8', 'Rome', 'RM', '00168', 'IT'));
        docs.add(makeDoctor(hcpRtId, 'Giulia', 'Bianchi', 'giulia.bianchi@ieo.example.com', '+39 02 5748 9002', 'Via Ripamonti 435', 'Milan', 'MI', '20141', 'IT'));
        docs.add(makeDoctor(hcpRtId, 'Alessandro', 'Conti', 'alessandro.conti@hsr.example.com', '+39 02 2643 2644', 'Via Olgettina 60', 'Milan', 'MI', '20132', 'IT'));
        docs.add(makeDoctor(hcpRtId, 'Francesca', 'Romano', 'francesca.romano@aopd.example.com', '+39 049 821 1112', 'Via Giustiniani 2', 'Padua', 'PD', '35128', 'IT'));
        docs.add(makeDoctor(hcpRtId, 'Luca', 'Ferretti', 'luca.ferretti@hsr.example.com', '+39 02 2643 2645', 'Via Olgettina 60', 'Milan', 'MI', '20132', 'IT'));
        docs.add(makeDoctor(hcpRtId, 'Elena', 'Moretti', 'elena.moretti@bambinogesu.example.com', '+39 06 6859 2', 'Piazza Sant\'Onofrio 4', 'Rome', 'RM', '00165', 'IT'));
        docs.add(makeDoctor(hcpRtId, 'Paolo', 'Esposito', 'paolo.esposito@unina.example.com', '+39 081 746 1112', 'Via Sergio Pansini 5', 'Naples', 'NA', '80131', 'IT'));
        docs.add(makeDoctor(hcpRtId, 'Chiara', 'Colombo', 'chiara.colombo@careggi.example.com', '+39 055 794 2', 'Largo Brambilla 3', 'Florence', 'FI', '50134', 'IT'));
        docs.add(makeDoctor(hcpRtId, 'Giovanni', 'Russo', 'giovanni.russo@humanitas.example.com', '+39 02 8224 2', 'Via Manzoni 56', 'Milan', 'MI', '20089', 'IT'));
        docs.add(makeDoctor(hcpRtId, 'Valentina', 'Ricci', 'valentina.ricci@gemelli.example.com', '+39 06 3015 3', 'Largo Agostino Gemelli 8', 'Rome', 'RM', '00168', 'IT'));

        // Spain Doctors (10)
        docs.add(makeDoctor(hcpRtId, 'Carlos', 'García López', 'carlos.garcia@clinic.example.com', '+34 93 227 54 01', 'Carrer de Villarroel 170', 'Barcelona', null, '08036', 'ES'));
        docs.add(makeDoctor(hcpRtId, 'María', 'Fernández Ruiz', 'maria.fernandez@lapaz.example.com', '+34 91 727 70 01', 'Paseo de la Castellana 261', 'Madrid', null, '28046', 'ES'));
        docs.add(makeDoctor(hcpRtId, 'Alejandro', 'Martínez Soto', 'alejandro.martinez@vhebron.example.com', '+34 93 274 60 01', 'Passeig de la Vall d\'Hebron 119', 'Barcelona', null, '08035', 'ES'));
        docs.add(makeDoctor(hcpRtId, 'Isabel', 'Navarro Díaz', 'isabel.navarro@teknon.example.com', '+34 93 290 62 01', 'Carrer de Vilana 12', 'Barcelona', null, '08022', 'ES'));
        docs.add(makeDoctor(hcpRtId, 'Pablo', 'Herrera Molina', 'pablo.herrera@clinic.example.com', '+34 93 227 54 02', 'Carrer de Villarroel 170', 'Barcelona', null, '08036', 'ES'));
        docs.add(makeDoctor(hcpRtId, 'Ana', 'López Serrano', 'ana.lopez@12octubre.example.com', '+34 91 390 80 01', 'Avenida de Córdoba s/n', 'Madrid', null, '28041', 'ES'));
        docs.add(makeDoctor(hcpRtId, 'Javier', 'Ruiz Delgado', 'javier.ruiz@rocio.example.com', '+34 955 01 20 01', 'Avenida Manuel Siurot s/n', 'Seville', null, '41013', 'ES'));
        docs.add(makeDoctor(hcpRtId, 'Lucía', 'Moreno Gil', 'lucia.moreno@incliva.example.com', '+34 96 386 26 01', 'Avenida Blasco Ibáñez 17', 'Valencia', null, '46010', 'ES'));
        docs.add(makeDoctor(hcpRtId, 'Diego', 'Sánchez Ramos', 'diego.sanchez@lapaz.example.com', '+34 91 727 70 02', 'Paseo de la Castellana 261', 'Madrid', null, '28046', 'ES'));
        docs.add(makeDoctor(hcpRtId, 'Carmen', 'Torres Vega', 'carmen.torres@vhebron.example.com', '+34 93 274 60 02', 'Passeig de la Vall d\'Hebron 119', 'Barcelona', null, '08035', 'ES'));

        // Japan Doctors (10)
        docs.add(makeDoctor(hcpRtId, '健', '山本', 'takeshi.yamamoto@todai.example.com', '+81 3 3815 5412', '本郷7-3-1', 'Tokyo', '13', '113-8655', 'JP'));
        docs.add(makeDoctor(hcpRtId, '由紀', '田中', 'yuki.tanaka@osaka-u.example.com', '+81 6 6879 5112', '山田丘2-15', 'Osaka', '27', '565-0871', 'JP'));
        docs.add(makeDoctor(hcpRtId, '博', '鈴木', 'hiroshi.suzuki@keio.example.com', '+81 3 3353 1212', '信濃町35', 'Tokyo', '13', '160-8582', 'JP'));
        docs.add(makeDoctor(hcpRtId, '明子', '渡辺', 'akiko.watanabe@ncc.example.com', '+81 3 3542 2512', '築地5-1-1', 'Tokyo', '13', '104-0045', 'JP'));
        docs.add(makeDoctor(hcpRtId, '健二', '伊藤', 'kenji.ito@nagoya-u.example.com', '+81 52 741 2112', '鶴舞町65', 'Nagoya', '23', '466-8560', 'JP'));
        docs.add(makeDoctor(hcpRtId, '美香', '佐藤', 'mika.sato@kyoto-u.example.com', '+81 75 751 3112', '聖護院川原町54', 'Kyoto', '26', '606-8507', 'JP'));
        docs.add(makeDoctor(hcpRtId, '亮太', '中村', 'ryota.nakamura@luke.example.com', '+81 3 3541 5152', '明石町9-1', 'Tokyo', '13', '104-8560', 'JP'));
        docs.add(makeDoctor(hcpRtId, '遥', '小林', 'haruka.kobayashi@todai.example.com', '+81 3 3815 5413', '本郷7-3-1', 'Tokyo', '13', '113-8655', 'JP'));
        docs.add(makeDoctor(hcpRtId, '聡', '橋本', 'satoshi.hashimoto@osaka-u.example.com', '+81 6 6879 5113', '山田丘2-15', 'Osaka', '27', '565-0871', 'JP'));
        docs.add(makeDoctor(hcpRtId, '恵美', '小川', 'emi.ogawa@kameda.example.com', '+81 4 7092 2212', '東町929', 'Kamogawa', '12', '296-8602', 'JP'));

        // South Korea Doctors (10)
        docs.add(makeDoctor(hcpRtId, '준호', '김', 'joonho.kim@snuh.example.com', '+82 2 2072 2115', '대학로 101', 'Seoul', '', '03080', 'KR'));
        docs.add(makeDoctor(hcpRtId, '수연', '박', 'sooyeon.park@smc.example.com', '+82 2 3410 2115', '일원로 81', 'Seoul', '', '06351', 'KR'));
        docs.add(makeDoctor(hcpRtId, '민준', '이', 'minjun.lee@amc.example.com', '+82 2 3010 3115', '올림픽로43길 88', 'Seoul', '', '05505', 'KR'));
        docs.add(makeDoctor(hcpRtId, '혜진', '최', 'hyejin.choi@severance.example.com', '+82 2 2228 5801', '연세로 50-1', 'Seoul', '', '03722', 'KR'));
        docs.add(makeDoctor(hcpRtId, '성우', '정', 'sungwoo.jung@cmcseoul.example.com', '+82 2 1588 1512', '반포대로 222', 'Seoul', '', '06591', 'KR'));
        docs.add(makeDoctor(hcpRtId, '은비', '한', 'eunbi.han@pnuh.example.com', '+82 51 240 7001', '구덕로 179', 'Busan', '', '49241', 'KR'));
        docs.add(makeDoctor(hcpRtId, '동현', '윤', 'donghyun.yoon@chamc.example.com', '+82 31 780 5001', '야탑로 59', 'Seongnam', '', '13496', 'KR'));
        docs.add(makeDoctor(hcpRtId, '지연', '강', 'jiyeon.kang@snuh.example.com', '+82 2 2072 2116', '대학로 101', 'Seoul', '', '03080', 'KR'));
        docs.add(makeDoctor(hcpRtId, '태현', '신', 'taehyun.shin@smc.example.com', '+82 2 3410 2116', '일원로 81', 'Seoul', '', '06351', 'KR'));
        docs.add(makeDoctor(hcpRtId, '나영', '임', 'nayoung.lim@gs.example.com', '+82 2 2019 3115', '언주로 211', 'Seoul', '', '06273', 'KR'));

        // Brazil Doctors (10)
        docs.add(makeDoctor(hcpRtId, 'Ricardo', 'Silva', 'ricardo.silva@hcfmusp.example.com', '+55 11 2661 0001', 'Rua Dr. Ovídio Pires de Campos 225', 'São Paulo', 'SP', '05403-010', 'BR'));
        docs.add(makeDoctor(hcpRtId, 'Ana Paula', 'Santos', 'ana.santos@siriolibanes.example.com', '+55 11 3155 0201', 'Rua Dona Adma Jafet 91', 'São Paulo', 'SP', '01308-050', 'BR'));
        docs.add(makeDoctor(hcpRtId, 'Fernando', 'Oliveira', 'fernando.oliveira@einstein.example.com', '+55 11 2151 1234', 'Avenida Albert Einstein 627', 'São Paulo', 'SP', '05652-900', 'BR'));
        docs.add(makeDoctor(hcpRtId, 'Mariana', 'Costa', 'mariana.costa@inca.example.com', '+55 21 3207 1001', 'Praça Cruz Vermelha 23', 'Rio de Janeiro', 'RJ', '20230-130', 'BR'));
        docs.add(makeDoctor(hcpRtId, 'Carlos Eduardo', 'Pereira', 'carlos.pereira@hcpa.example.com', '+55 51 3359 8001', 'Rua Ramiro Barcelos 2350', 'Porto Alegre', 'RS', '90035-903', 'BR'));
        docs.add(makeDoctor(hcpRtId, 'Juliana', 'Almeida', 'juliana.almeida@hcufmg.example.com', '+55 31 3307 9101', 'Avenida Professor Alfredo Balena 110', 'Belo Horizonte', 'MG', '30130-100', 'BR'));
        docs.add(makeDoctor(hcpRtId, 'Roberto', 'Ferreira', 'roberto.ferreira@saorafael.example.com', '+55 71 3281 6001', 'Avenida São Rafael 2152', 'Salvador', 'BA', '41253-190', 'BR'));
        docs.add(makeDoctor(hcpRtId, 'Patrícia', 'Souza', 'patricia.souza@hcfmusp.example.com', '+55 11 2661 0002', 'Rua Dr. Ovídio Pires de Campos 225', 'São Paulo', 'SP', '05403-010', 'BR'));
        docs.add(makeDoctor(hcpRtId, 'Gustavo', 'Lima', 'gustavo.lima@einstein.example.com', '+55 11 2151 1235', 'Avenida Albert Einstein 627', 'São Paulo', 'SP', '05652-900', 'BR'));
        docs.add(makeDoctor(hcpRtId, 'Camila', 'Rodrigues', 'camila.rodrigues@oncoabc.example.com', '+55 11 3120 4701', 'Rua Piauí 421', 'São Paulo', 'SP', '01241-001', 'BR'));

        // Mexico Doctors (10)
        docs.add(makeDoctor(hcpRtId, 'Alejandro', 'Hernández Vega', 'alejandro.hernandez@incan.example.com', '+52 55 5628 0401', 'Avenida San Fernando 22', 'Mexico City', '', '14080', 'MX'));
        docs.add(makeDoctor(hcpRtId, 'Sofía', 'Ramírez Cruz', 'sofia.ramirez@hgm.example.com', '+52 55 2789 2001', 'Dr. Balmis 148', 'Mexico City', '', '06720', 'MX'));
        docs.add(makeDoctor(hcpRtId, 'Diego', 'Torres Medina', 'diego.torres@cardio.example.com', '+52 55 5573 2912', 'Juan Badiano 1', 'Mexico City', '', '14080', 'MX'));
        docs.add(makeDoctor(hcpRtId, 'Valentina', 'López Ortega', 'valentina.lopez@hcg.example.com', '+52 33 3614 5502', 'Hospital 278', 'Guadalajara', '', '44280', 'MX'));
        docs.add(makeDoctor(hcpRtId, 'Luis Miguel', 'García Ríos', 'luis.garcia@hu.example.com', '+52 81 8348 7201', 'Avenida Francisco I. Madero s/n', 'Monterrey', '', '64460', 'MX'));
        docs.add(makeDoctor(hcpRtId, 'María José', 'Sánchez Flores', 'mariajose.sanchez@angeles.example.com', '+52 222 309 7901', 'Avenida Kepler 2143', 'Puebla', '', '72190', 'MX'));
        docs.add(makeDoctor(hcpRtId, 'Carlos Alberto', 'Morales Díaz', 'carlos.morales@imss.example.com', '+52 55 5627 6901', 'Avenida Cuauhtémoc 330', 'Mexico City', '', '06720', 'MX'));
        docs.add(makeDoctor(hcpRtId, 'Daniela', 'Mendoza Ruiz', 'daniela.mendoza@medicasur.example.com', '+52 55 5424 7201', 'Puente de Piedra 150', 'Mexico City', '', '14050', 'MX'));
        docs.add(makeDoctor(hcpRtId, 'Fernando', 'Castillo Reyes', 'fernando.castillo@incan.example.com', '+52 55 5628 0402', 'Avenida San Fernando 22', 'Mexico City', '', '14080', 'MX'));
        docs.add(makeDoctor(hcpRtId, 'Andrea', 'Vargas Luna', 'andrea.vargas@hgm.example.com', '+52 55 2789 2002', 'Dr. Balmis 148', 'Mexico City', '', '06720', 'MX'));

        // Argentina Doctors (10)
        docs.add(makeDoctor(hcpRtId, 'Martín', 'González', 'martin.gonzalez@hital.example.com', '+54 11 4959 0201', 'Juan D. Perón 4190', 'Buenos Aires', '', 'C1199ABB', 'AR'));
        docs.add(makeDoctor(hcpRtId, 'Lucía', 'Fernández', 'lucia.fernandez@clinicas.example.com', '+54 11 5950 8001', 'Avenida Córdoba 2351', 'Buenos Aires', '', 'C1120AAR', 'AR'));
        docs.add(makeDoctor(hcpRtId, 'Santiago', 'Rodríguez', 'santiago.rodriguez@garrahan.example.com', '+54 11 4122 6001', 'Combate de los Pozos 1881', 'Buenos Aires', '', 'C1245AAM', 'AR'));
        docs.add(makeDoctor(hcpRtId, 'Valentina', 'Martínez', 'valentina.martinez@austral.example.com', '+54 11 2304 6001', 'Avenida Juan D. Perón 1500', 'Pilar', '', 'B1629AHJ', 'AR'));
        docs.add(makeDoctor(hcpRtId, 'Nicolás', 'López', 'nicolas.lopez@hncordoba.example.com', '+54 351 433 4042', 'Bajada Pucará s/n', 'Córdoba', '', 'X5000', 'AR'));
        docs.add(makeDoctor(hcpRtId, 'Camila', 'García', 'camila.garcia@hpc.example.com', '+54 341 472 1112', 'Urquiza 3101', 'Rosario', '', 'S2000', 'AR'));
        docs.add(makeDoctor(hcpRtId, 'Mateo', 'Álvarez', 'mateo.alvarez@fleming.example.com', '+54 11 6323 2901', 'Crámer 1180', 'Buenos Aires', '', 'C1426ANZ', 'AR'));
        docs.add(makeDoctor(hcpRtId, 'Florencia', 'Díaz', 'florencia.diaz@hital.example.com', '+54 11 4959 0202', 'Juan D. Perón 4190', 'Buenos Aires', '', 'C1199ABB', 'AR'));
        docs.add(makeDoctor(hcpRtId, 'Tomás', 'Romero', 'tomas.romero@cemic.example.com', '+54 11 5299 0101', 'Avenida Galván 4102', 'Buenos Aires', '', 'C1431FWO', 'AR'));
        docs.add(makeDoctor(hcpRtId, 'Agustina', 'Pereyra', 'agustina.pereyra@clinicas.example.com', '+54 11 5950 8002', 'Avenida Córdoba 2351', 'Buenos Aires', '', 'C1120AAR', 'AR'));

        return docs;
    }

    private static Account makeDoctor(Id rtId, String firstName, String lastName, String email, String phone, String street, String city, String stateCode, String postalCode, String countryCode) {
        Account a = new Account();
        a.RecordTypeId = rtId;
        a.Salutation = 'Dr.';
        a.FirstName = firstName;
        a.LastName = lastName;
        a.PersonEmail = email;
        a.Phone = phone;
        a.BillingStreet = street;
        a.BillingCity = city;
        a.BillingPostalCode = postalCode;
        a.BillingCountryCode = countryCode;
        a.PersonMailingStreet = street;
        a.PersonMailingCity = city;
        a.PersonMailingPostalCode = postalCode;
        a.PersonMailingCountryCode = countryCode;
        if (String.isNotBlank(stateCode)) {
            a.BillingStateCode = stateCode;
            a.PersonMailingStateCode = stateCode;
        }
        a.Site = DEMO_TAG;
        a.IsActive = true;
        return a;
    }

    // ---------------------------------------------------------------------------
    // HealthcareProvider builders (linked to doctor PersonAccounts)
    // ---------------------------------------------------------------------------

    private static List<SObject> buildHealthcareProviders(Map<String, Id> doctorNameToId) {
        List<SObject> providers = new List<SObject>();
        Schema.SObjectType hcpType = Schema.getGlobalDescribe().get('healthcareprovider');
        Map<String, Schema.SObjectField> hcpFields = hcpType.getDescribe().fields.getMap();

        for (String fullName : doctorNameToId.keySet()) {
            SObject hcp = hcpType.newSObject();
            hcp.put('Name', 'Dr. ' + fullName);
            if (hcpFields.containsKey('accountid')) hcp.put('AccountId', doctorNameToId.get(fullName));
            if (hcpFields.containsKey('sourcesystem')) hcp.put('SourceSystem', DEMO_TAG);
            providers.add(hcp);
        }

        return providers;
    }

    // ---------------------------------------------------------------------------
    // NPI builders
    // ---------------------------------------------------------------------------

    private static List<SObject> buildNpiRecords(Map<String, Id> hcpNameToId) {
        List<SObject> npis = new List<SObject>();
        Schema.SObjectType npiType = Schema.getGlobalDescribe().get('healthcareprovidernpi');
        Map<String, Schema.SObjectField> npiFields = npiType.getDescribe().fields.getMap();

        String hcpFieldName = npiFields.containsKey('healthcareproviderid') ? 'HealthcareProviderId'
                            : npiFields.containsKey('practitionerid') ? 'PractitionerId' : null;
        if (hcpFieldName == null) return npis;

        Map<String, String> npiMap = new Map<String, String>();
        Integer npiBase = 1000000000;
        for (String provName : hcpNameToId.keySet()) {
            npiMap.put(provName, String.valueOf(npiBase));
            npiBase++;
        }

        for (String provName : npiMap.keySet()) {
            Id hcpId = hcpNameToId.get(provName);
            if (hcpId != null) {
                SObject npi = npiType.newSObject();
                npi.put('Name', provName + ' NPI');
                npi.put('Npi', npiMap.get(provName));
                if (npiFields.containsKey('npitype')) npi.put('NpiType', 'Individual');
                npi.put(hcpFieldName, hcpId);
                if (npiFields.containsKey('effectivefrom')) npi.put('EffectiveFrom', Date.newInstance(2020, 1, 1));
                if (npiFields.containsKey('effectiveto')) npi.put('EffectiveTo', Date.newInstance(2030, 12, 31));
                if (npiFields.containsKey('isactive')) npi.put('IsActive', true);
                if (npiFields.containsKey('sourcesystem')) npi.put('SourceSystem', DEMO_TAG);
                npis.add(npi);
            }
        }

        return npis;
    }

    // ---------------------------------------------------------------------------
    // CareSpecialty + HealthcareProviderSpecialty builders
    // ---------------------------------------------------------------------------

    private static Map<String, Id> createCareSpecialties() {
        Map<String, Id> specNameToId = new Map<String, Id>();
        Schema.SObjectType csType = Schema.getGlobalDescribe().get('carespecialty');
        if (csType == null) return specNameToId;

        Set<String> specialtyNames = new Set<String>{
            'Oncology', 'Cardiology', 'Neurology', 'Internal Medicine',
            'Gastroenterology', 'Pulmonology', 'Endocrinology', 'Dermatology',
            'Orthopedics', 'Immunology', 'Pediatrics', 'Family Medicine'
        };

        List<SObject> careSpecs = new List<SObject>();
        for (String specName : specialtyNames) {
            SObject cs = csType.newSObject();
            cs.put('Name', specName);
            cs.put('IsActive', true);
            cs.put('Description', DEMO_TAG);
            careSpecs.add(cs);
        }

        Database.SaveResult[] results = Database.insert(careSpecs, false);
        for (Integer i = 0; i < careSpecs.size(); i++) {
            if (results[i].isSuccess()) {
                specNameToId.put((String) careSpecs[i].get('Name'), results[i].getId());
            }
        }

        return specNameToId;
    }

    private static List<SObject> buildSpecialtyRecords(Map<String, Id> hcpNameToId, Map<String, Id> doctorNameToId, Map<String, Id> specNameToId) {
        List<SObject> specs = new List<SObject>();
        Schema.SObjectType specType = Schema.getGlobalDescribe().get('healthcareproviderspecialty');

        List<String> specialtyRotation = new List<String>{
            'Oncology', 'Cardiology', 'Neurology', 'Internal Medicine',
            'Gastroenterology', 'Pulmonology', 'Endocrinology', 'Dermatology',
            'Immunology', 'Pediatrics', 'Orthopedics', 'Family Medicine'
        };
        Map<String, String> providerSpecialties = new Map<String, String>();
        Integer specIdx = 0;
        for (String provName : hcpNameToId.keySet()) {
            providerSpecialties.put(provName, specialtyRotation[Math.mod(specIdx, specialtyRotation.size())]);
            specIdx++;
        }

        Map<String, Schema.SObjectField> specFields = specType.getDescribe().fields.getMap();
        String hcpFieldName = specFields.containsKey('healthcareproviderid') ? 'HealthcareProviderId'
                            : specFields.containsKey('practitionerid') ? 'PractitionerId' : null;
        String specFieldName = specFields.containsKey('specialtyid') ? 'SpecialtyId'
                             : specFields.containsKey('carespecialtyid') ? 'CareSpecialtyId' : null;

        if (hcpFieldName == null || specFieldName == null) return specs;

        // PractitionerId references Contact, not HealthcareProvider.
        // Resolve PersonContactIds from doctor accounts when needed.
        Map<String, Id> practitionerIdMap = hcpNameToId;
        if (hcpFieldName == 'PractitionerId') {
            practitionerIdMap = new Map<String, Id>();
            // hcpNameToId keys are "Dr. FirstName LastName", doctorNameToId keys are "FirstName LastName"
            Map<Id, Id> acctToContactId = new Map<Id, Id>();
            Set<Id> acctIds = new Set<Id>(doctorNameToId.values());
            for (Account a : [SELECT Id, PersonContactId FROM Account WHERE Id IN :acctIds AND IsPersonAccount = true]) {
                acctToContactId.put(a.Id, a.PersonContactId);
            }
            for (String hcpName : hcpNameToId.keySet()) {
                // "Dr. FirstName LastName" → "FirstName LastName"
                String doctorName = hcpName.startsWith('Dr. ') ? hcpName.substring(4) : hcpName;
                Id acctId = doctorNameToId.get(doctorName);
                if (acctId != null && acctToContactId.containsKey(acctId)) {
                    practitionerIdMap.put(hcpName, acctToContactId.get(acctId));
                }
            }
        }

        for (String provName : providerSpecialties.keySet()) {
            Id linkId = practitionerIdMap.get(provName);
            String specName = providerSpecialties.get(provName);
            Id careSpecId = specNameToId.get(specName);
            if (linkId != null && careSpecId != null) {
                SObject spec = specType.newSObject();
                spec.put('Name', provName + ' - ' + specName);
                spec.put(hcpFieldName, linkId);
                spec.put(specFieldName, careSpecId);
                if (specFields.containsKey('isactive')) spec.put('IsActive', true);
                if (specFields.containsKey('isprimaryspecialty')) spec.put('IsPrimarySpecialty', true);
                if (specFields.containsKey('sourcesystem')) spec.put('SourceSystem', DEMO_TAG);
                specs.add(spec);
            }
        }

        return specs;
    }

    // ---------------------------------------------------------------------------
    // Territory Assignment
    // ---------------------------------------------------------------------------

    @AuraEnabled
    public static String assignTerritories() {
        try {
            List<Account> demoAccounts = [
                SELECT Id, Name, BillingCity, BillingCountryCode, IsPersonAccount
                FROM Account
                WHERE Site = :DEMO_TAG
            ];
            if (demoAccounts.isEmpty()) return 'No demo accounts found.';

            Map<String, Id> terrByDev = new Map<String, Id>();
            for (Territory2 t : [SELECT Id, DeveloperName FROM Territory2]) {
                terrByDev.put(t.DeveloperName, t.Id);
            }

            Set<Id> acctIds = new Set<Id>();
            for (Account a : demoAccounts) acctIds.add(a.Id);

            // Remove existing demo-account territory associations
            List<ObjectTerritory2Association> existingOta = [
                SELECT Id FROM ObjectTerritory2Association
                WHERE ObjectId IN :acctIds
            ];
            if (!existingOta.isEmpty()) Database.delete(existingOta, false);

            // Remove existing demo PATI and Summary records
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            String escapedTag = String.escapeSingleQuotes(DEMO_TAG);
            Boolean hasPati = gd.containsKey('provideracctterritoryinfo');
            if (hasPati) {
                List<SObject> existingPati = Database.query(
                    'SELECT Id FROM ProviderAcctTerritoryInfo WHERE SourceSystemName = \'' + escapedTag + '\''
                );
                if (!existingPati.isEmpty()) Database.delete(existingPati, false);
            }
            Boolean hasSummary = gd.containsKey('prvdaccountterritorysummary');
            if (hasSummary) {
                List<SObject> existingSummary = Database.query(
                    'SELECT Id FROM PrvdAccountTerritorySummary WHERE SourceSystemName = \'' + escapedTag + '\''
                );
                if (!existingSummary.isEmpty()) Database.delete(existingSummary, false);
            }

            Map<String, String> cityTerrMap = buildCityTerritoryMap();
            Map<String, String> countryTerrMap = new Map<String, String>{
                'US' => 'US_COUNTRY',
                'GB' => 'GB_COUNTRY',
                'FR' => 'FR_COUNTRY',
                'DE' => 'DE_COUNTRY',
                'IT' => 'IT_COUNTRY',
                'ES' => 'ES_COUNTRY',
                'JP' => 'JP_COUNTRY',
                'KR' => 'KR_COUNTRY',
                'BR' => 'BR_COUNTRY',
                'MX' => 'MX_COUNTRY',
                'AR' => 'AR_COUNTRY'
            };

            List<ObjectTerritory2Association> associations = new List<ObjectTerritory2Association>();
            // Track Account->Territory pairs for PATI creation
            List<Account> matchedAccounts = new List<Account>();
            List<Id> matchedTerritoryIds = new List<Id>();
            Integer matched = 0;
            Integer fallback = 0;

            for (Account acct : demoAccounts) {
                String city = acct.BillingCity;
                String country = acct.BillingCountryCode;
                String terrDev = null;

                if (String.isNotBlank(city)) {
                    String key = (String.isNotBlank(country) ? country : '') + ':' + city;
                    terrDev = cityTerrMap.get(key);
                }

                if (terrDev == null && String.isNotBlank(country)) {
                    terrDev = countryTerrMap.get(country);
                    if (terrDev != null) fallback++;
                } else if (terrDev != null) {
                    matched++;
                }

                if (terrDev != null && terrByDev.containsKey(terrDev)) {
                    Id terrId = terrByDev.get(terrDev);
                    ObjectTerritory2Association ota = new ObjectTerritory2Association();
                    ota.ObjectId = acct.Id;
                    ota.Territory2Id = terrId;
                    ota.AssociationCause = 'Territory2Manual';
                    associations.add(ota);
                    matchedAccounts.add(acct);
                    matchedTerritoryIds.add(terrId);
                }
            }

            if (associations.isEmpty()) return 'No territory matches found.';

            Database.SaveResult[] results = Database.insert(associations, false);
            Integer success = 0;
            List<String> errors = new List<String>();
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    success++;
                } else if (errors.size() < 5) {
                    errors.add(matchedAccounts[i].Name + ': ' + results[i].getErrors()[0].getMessage());
                }
            }

            String result = 'Territory assignments: ' + success + '/' + associations.size()
                + ' (city match: ' + matched + ', country fallback: ' + fallback + ')';
            if (!errors.isEmpty()) result += ' | Errors: ' + String.join(errors, '; ');

            // Create ProviderAcctTerritoryInfo records for each successful assignment
            if (hasPati) {
                String patiResult = createPatiRecords(matchedAccounts, matchedTerritoryIds, results);
                result += ' | ' + patiResult;
            }

            // Create PrvdAccountTerritorySummary records with realistic summaries
            if (hasSummary) {
                String summaryResult = createSummaryRecords(matchedAccounts, matchedTerritoryIds, results);
                result += ' | ' + summaryResult;
            }

            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error assigning territories: ' + e.getMessage());
        }
    }

    private static String createPatiRecords(List<Account> accounts, List<Id> territoryIds, Database.SaveResult[] otaResults) {
        Schema.SObjectType patiType = Schema.getGlobalDescribe().get('provideracctterritoryinfo');
        List<SObject> patiRecords = new List<SObject>();
        List<Id> patiTerritoryIds = new List<Id>();

        for (Integer i = 0; i < accounts.size(); i++) {
            if (!otaResults[i].isSuccess()) continue;

            SObject pati = patiType.newSObject();
            pati.put('AccountId', accounts[i].Id);
            pati.put('Territory2Id', territoryIds[i]);
            pati.put('IsTargetedAccount', true);
            pati.put('IsAvailableOffline', true);
            pati.put('IsActive', true);
            pati.put('SourceSystemName', DEMO_TAG);
            pati.put('SourceType', 'Manual');
            patiRecords.add(pati);
            patiTerritoryIds.add(territoryIds[i]);
        }

        if (patiRecords.isEmpty()) return 'PATI: 0 created';

        Database.SaveResult[] patiResults = Database.insert(patiRecords, false);
        Integer patiSuccess = 0;
        List<String> patiErrors = new List<String>();
        for (Integer i = 0; i < patiResults.size(); i++) {
            if (patiResults[i].isSuccess()) {
                patiSuccess++;
            } else if (patiErrors.size() < 5) {
                patiErrors.add(patiResults[i].getErrors()[0].getMessage());
            }
        }

        String patiResult = 'PATI: ' + patiSuccess + '/' + patiRecords.size();
        if (!patiErrors.isEmpty()) patiResult += ' (' + String.join(patiErrors, '; ') + ')';

        // Share PATI records with territory groups so reps can sync them
        Integer shareSuccess = sharePatiWithTerritories(patiResults, patiTerritoryIds);
        patiResult += ', Shares: ' + shareSuccess;

        return patiResult;
    }

    private static Integer sharePatiWithTerritories(Database.SaveResult[] patiResults, List<Id> territoryIds) {
        Set<Id> uniqueTerrIds = new Set<Id>(territoryIds);
        Map<Id, Id> terrToGroupId = new Map<Id, Id>();
        for (Group g : [SELECT Id, RelatedId FROM Group WHERE Type = 'Territory' AND RelatedId IN :uniqueTerrIds]) {
            terrToGroupId.put(g.RelatedId, g.Id);
        }

        Schema.SObjectType shareType = Schema.getGlobalDescribe().get('provideracctterritoryinfoshare');
        if (shareType == null) return 0;

        List<SObject> shares = new List<SObject>();
        for (Integer i = 0; i < patiResults.size(); i++) {
            if (!patiResults[i].isSuccess()) continue;
            Id groupId = terrToGroupId.get(territoryIds[i]);
            if (groupId == null) continue;

            SObject share = shareType.newSObject();
            share.put('ParentId', patiResults[i].getId());
            share.put('UserOrGroupId', groupId);
            share.put('AccessLevel', 'Edit');
            share.put('RowCause', 'LSC4CEAutoShare');
            shares.add(share);
        }

        if (shares.isEmpty()) return 0;

        Database.SaveResult[] shareResults = Database.insert(shares, false);
        Integer success = 0;
        for (Database.SaveResult sr : shareResults) {
            if (sr.isSuccess()) success++;
        }
        return success;
    }

    private static String createSummaryRecords(List<Account> accounts, List<Id> territoryIds, Database.SaveResult[] otaResults) {
        Schema.SObjectType summaryType = Schema.getGlobalDescribe().get('prvdaccountterritorysummary');
        List<SObject> summaryRecords = new List<SObject>();
        List<Id> summaryTerritoryIds = new List<Id>();

        // Build territory-to-user map (pick first user per territory)
        Set<Id> uniqueTerrIds = new Set<Id>(territoryIds);
        Map<Id, Id> terrToUserId = new Map<Id, Id>();
        for (UserTerritory2Association uta : [SELECT UserId, Territory2Id FROM UserTerritory2Association WHERE Territory2Id IN :uniqueTerrIds]) {
            if (!terrToUserId.containsKey(uta.Territory2Id)) {
                terrToUserId.put(uta.Territory2Id, uta.UserId);
            }
        }

        Map<String, List<String[]>> localizedTemplates = buildLocalizedSummaryTemplates();

        for (Integer i = 0; i < accounts.size(); i++) {
            if (!otaResults[i].isSuccess()) continue;

            Account acct = accounts[i];
            String country = acct.BillingCountryCode;
            List<String[]> templates = localizedTemplates.containsKey(country) ? localizedTemplates.get(country) : localizedTemplates.get('EN');
            Integer templateIdx = Math.mod(i, templates.size());
            String[] tmpl = templates[templateIdx];

            String summaryJson = '{"keyInfo":[{"sectionName":"Key Activities & Engagement","sectionData":[{"data":"'
                + tmpl[1] + '"},{"data":"' + tmpl[2] + '"},{"data":"' + tmpl[3] + '"}]},'
                + '{"sectionName":"Discussion Points","sectionData":[{"data":"'
                + tmpl[4] + '"},{"data":"' + tmpl[5] + '"}]}],'
                + '"changeInfo":[{"sectionName":"Affiliation Updates","sectionData":[{"data":"'
                + tmpl[6] + '"}]},'
                + '{"sectionName":"Recent Publications & Accreditations","sectionData":[{"data":"'
                + tmpl[7] + '"}]}]}';

            SObject summary = summaryType.newSObject();
            summary.put('AccountId', acct.Id);
            summary.put('Territory2Id', territoryIds[i]);
            Id userId = terrToUserId.get(territoryIds[i]);
            if (userId != null) {
                summary.put('UserId', userId);
            }
            summary.put('KeyInformationSummary', summaryJson);
            summary.put('KeyInfoSummaryDateTime', Datetime.now());
            summary.put('SourceSystemName', DEMO_TAG);
            summaryRecords.add(summary);
            summaryTerritoryIds.add(territoryIds[i]);
        }

        if (summaryRecords.isEmpty()) return 'Summaries: 0 created';

        Database.SaveResult[] summaryResults = Database.insert(summaryRecords, false);
        Integer summarySuccess = 0;
        List<String> summaryErrors = new List<String>();
        for (Integer i = 0; i < summaryResults.size(); i++) {
            if (summaryResults[i].isSuccess()) {
                summarySuccess++;
            } else if (summaryErrors.size() < 5) {
                summaryErrors.add(summaryResults[i].getErrors()[0].getMessage());
            }
        }

        String summaryResult = 'Summaries: ' + summarySuccess + '/' + summaryRecords.size();
        if (!summaryErrors.isEmpty()) summaryResult += ' (' + String.join(summaryErrors, '; ') + ')';

        Integer shareSuccess = shareSummariesWithTerritories(summaryResults, summaryTerritoryIds);
        summaryResult += ', SummaryShares: ' + shareSuccess;

        return summaryResult;
    }

    private static Integer shareSummariesWithTerritories(Database.SaveResult[] summaryResults, List<Id> territoryIds) {
        Set<Id> uniqueTerrIds = new Set<Id>(territoryIds);
        Map<Id, Id> terrToGroupId = new Map<Id, Id>();
        for (Group g : [SELECT Id, RelatedId FROM Group WHERE Type = 'Territory' AND RelatedId IN :uniqueTerrIds]) {
            terrToGroupId.put(g.RelatedId, g.Id);
        }

        Schema.SObjectType shareType = Schema.getGlobalDescribe().get('prvdaccountterritorysummaryshare');
        if (shareType == null) return 0;

        List<SObject> shares = new List<SObject>();
        for (Integer i = 0; i < summaryResults.size(); i++) {
            if (!summaryResults[i].isSuccess()) continue;
            Id groupId = terrToGroupId.get(territoryIds[i]);
            if (groupId == null) continue;

            SObject share = shareType.newSObject();
            share.put('ParentId', summaryResults[i].getId());
            share.put('UserOrGroupId', groupId);
            share.put('AccessLevel', 'Edit');
            share.put('RowCause', 'Manual');
            shares.add(share);
        }

        if (shares.isEmpty()) return 0;

        Database.SaveResult[] shareResults = Database.insert(shares, false);
        Integer success = 0;
        for (Database.SaveResult sr : shareResults) {
            if (sr.isSuccess()) success++;
        }
        return success;
    }

    private static Map<String, List<String[]>> buildLocalizedSummaryTemplates() {
        Map<String, List<String[]>> m = new Map<String, List<String[]>>();

        // English (US, GB)
        m.put('EN', new List<String[]>{
            new String[]{ 'Oncology',
                'The provider participated in 180 visits over the past year, indicating strong engagement with the oncology portfolio.',
                'High engagement with Oncolyra, discussed in 120 visits, followed by Tumorex in 40 visits.',
                'A recent clinical inquiry was submitted regarding Oncolyra, focusing on combination therapy for advanced solid tumors.',
                'Discuss the latest Phase III data for Oncolyra and explore interest in upcoming advisory board.',
                'Review the provider\'s patient volume for eligible indications and identify opportunities for Tumorex.',
                'The provider recently established an affiliation with a regional cancer center, expanding referral network.',
                'Published a recent article on immunotherapy combinations in the Journal of Clinical Oncology.' },
            new String[]{ 'Cardiology',
                'The provider had 150 visits over the past year, demonstrating consistent cardiology portfolio engagement.',
                'Primary focus on Cardiomex, discussed in 95 visits. Secondary interest in Vasculin, discussed in 35 visits.',
                'Submitted a medical information request regarding Cardiomex use in patients with renal comorbidities.',
                'Share new real-world evidence data on Cardiomex outcomes in heart failure with preserved ejection fraction.',
                'Explore the provider\'s perspective on emerging SGLT2 inhibitor data and positioning versus Cardiomex.',
                'Recently appointed as head of interventional cardiology at the affiliated hospital.',
                'Co-authored a meta-analysis on novel anticoagulants published in the European Heart Journal.' },
            new String[]{ 'Neurology',
                'The provider completed 130 visits, showing growing engagement with the neurology portfolio.',
                'Neurovex was the most discussed product in 85 visits. Synaptix was discussed in 30 visits.',
                'Requested additional information about Neurovex\'s mechanism of action in treatment-resistant epilepsy.',
                'Present updated long-term safety data for Neurovex and discuss patient selection criteria.',
                'Assess the provider\'s experience with Synaptix in early-onset neurological conditions.',
                'The provider was recently named principal investigator for a multi-center neurology trial.',
                'Presented research on biomarkers for disease progression at the American Academy of Neurology meeting.' },
            new String[]{ 'Immunology',
                'The provider participated in 160 visits, indicating strong immunology portfolio engagement.',
                'Immunexis was discussed in 110 visits. Rheumavex was discussed in 35 visits.',
                'Requested information on Immunexis biosimilar transition data and switching protocols.',
                'Discuss the provider\'s experience with Immunexis and address any biosimilar switching concerns.',
                'Review Rheumavex positioning for patients with inadequate response to conventional DMARDs.',
                'Appointed as lead investigator for a rheumatology registry study at their institution.',
                'Published research on treat-to-target strategies in rheumatoid arthritis in Annals of Rheumatic Diseases.' }
        });
        m.put('US', m.get('EN'));
        m.put('GB', m.get('EN'));

        // French
        m.put('FR', new List<String[]>{
            new String[]{ 'Oncologie',
                'Le praticien a participé à 180 visites au cours de l\'année écoulée, témoignant d\'un engagement soutenu avec le portefeuille oncologie.',
                'Fort engagement avec Oncolyra, discuté lors de 120 visites, suivi de Tumorex lors de 40 visites.',
                'Une demande d\'information clinique récente a été soumise concernant Oncolyra, portant sur la thérapie combinée pour les tumeurs solides avancées.',
                'Présenter les dernières données de Phase III d\'Oncolyra et explorer l\'intérêt pour le prochain comité consultatif.',
                'Évaluer le volume de patients du praticien pour les indications éligibles et identifier les opportunités pour Tumorex.',
                'Le praticien a récemment établi une affiliation avec un centre anticancéreux régional, élargissant son réseau de référence.',
                'Publication récente d\'un article sur les combinaisons d\'immunothérapie dans le Bulletin du Cancer.' },
            new String[]{ 'Cardiologie',
                'Le praticien a effectué 150 visites au cours de l\'année, démontrant un engagement constant avec le portefeuille cardiologie.',
                'Focus principal sur Cardiomex, discuté lors de 95 visites. Intérêt secondaire pour Vasculin, 35 visites.',
                'Demande d\'information médicale soumise concernant l\'utilisation de Cardiomex chez les patients présentant des comorbidités rénales.',
                'Partager les nouvelles données en vie réelle sur les résultats de Cardiomex dans l\'insuffisance cardiaque à fraction d\'éjection préservée.',
                'Explorer le point de vue du praticien sur les données émergentes des inhibiteurs SGLT2 par rapport à Cardiomex.',
                'Récemment nommé chef du service de cardiologie interventionnelle à l\'hôpital affilié.',
                'Co-auteur d\'une méta-analyse sur les nouveaux anticoagulants publiée dans les Archives des Maladies du Cœur.' },
            new String[]{ 'Neurologie',
                'Le praticien a réalisé 130 visites, montrant un engagement croissant avec le portefeuille neurologie.',
                'Neurovex a été le produit le plus discuté lors de 85 visites. Synaptix a été discuté lors de 30 visites.',
                'Demande d\'informations complémentaires sur le mécanisme d\'action de Neurovex dans l\'épilepsie résistante au traitement.',
                'Présenter les données de sécurité à long terme mises à jour pour Neurovex et discuter des critères de sélection des patients.',
                'Évaluer l\'expérience du praticien avec Synaptix dans les pathologies neurologiques précoces.',
                'Le praticien a été récemment désigné investigateur principal pour un essai neurologique multicentrique.',
                'Présentation de recherches sur les biomarqueurs de progression de la maladie au congrès de la Société Française de Neurologie.' },
            new String[]{ 'Immunologie',
                'Le praticien a participé à 160 visites, indiquant un fort engagement avec le portefeuille immunologie.',
                'Immunexis a été discuté lors de 110 visites. Rheumavex lors de 35 visites.',
                'Demande d\'information sur les données de transition biosimilaire d\'Immunexis et les protocoles de substitution.',
                'Discuter de l\'expérience du praticien avec Immunexis et répondre aux préoccupations liées à la substitution biosimilaire.',
                'Revoir le positionnement de Rheumavex pour les patients en réponse inadéquate aux DMARDs conventionnels.',
                'Nommé investigateur principal pour une étude de registre en rhumatologie dans son établissement.',
                'Publication de recherches sur les stratégies treat-to-target dans la polyarthrite rhumatoïde dans la Revue du Rhumatisme.' }
        });

        // German
        m.put('DE', new List<String[]>{
            new String[]{ 'Onkologie',
                'Der Arzt hat im vergangenen Jahr an 180 Besuchen teilgenommen, was ein starkes Engagement im Onkologie-Portfolio zeigt.',
                'Hohes Engagement bei Oncolyra, besprochen in 120 Besuchen, gefolgt von Tumorex in 40 Besuchen.',
                'Eine aktuelle klinische Anfrage wurde zu Oncolyra eingereicht, mit Fokus auf Kombinationstherapie bei fortgeschrittenen soliden Tumoren.',
                'Die neuesten Phase-III-Daten zu Oncolyra besprechen und Interesse am bevorstehenden Advisory Board erkunden.',
                'Das Patientenvolumen des Arztes für geeignete Indikationen prüfen und Chancen für Tumorex identifizieren.',
                'Der Arzt hat kürzlich eine Zusammenarbeit mit einem regionalen Krebszentrum aufgebaut und sein Überweisungsnetzwerk erweitert.',
                'Kürzlich einen Artikel über Immuntherapie-Kombinationen in der Deutschen Medizinischen Wochenschrift veröffentlicht.' },
            new String[]{ 'Kardiologie',
                'Der Arzt hatte 150 Besuche im vergangenen Jahr und zeigt ein konstantes Engagement im Kardiologie-Portfolio.',
                'Hauptfokus auf Cardiomex, besprochen in 95 Besuchen. Sekundäres Interesse an Vasculin mit 35 Besuchen.',
                'Medizinische Informationsanfrage zu Cardiomex bei Patienten mit renalen Komorbiditäten eingereicht.',
                'Neue Real-World-Evidence-Daten zu Cardiomex-Ergebnissen bei Herzinsuffizienz mit erhaltener Ejektionsfraktion teilen.',
                'Die Perspektive des Arztes zu neuen SGLT2-Inhibitor-Daten und Positionierung gegenüber Cardiomex erkunden.',
                'Kürzlich zum Leiter der interventionellen Kardiologie am angeschlossenen Krankenhaus ernannt.',
                'Mitautor einer Metaanalyse zu neuartigen Antikoagulanzien, veröffentlicht im European Heart Journal.' },
            new String[]{ 'Neurologie',
                'Der Arzt hat 130 Besuche absolviert und zeigt wachsendes Engagement im Neurologie-Portfolio.',
                'Neurovex war das am häufigsten besprochene Produkt in 85 Besuchen. Synaptix wurde in 30 Besuchen besprochen.',
                'Zusätzliche Informationen zum Wirkmechanismus von Neurovex bei therapieresistenter Epilepsie angefordert.',
                'Aktualisierte Langzeitsicherheitsdaten für Neurovex präsentieren und Patientenauswahlkriterien besprechen.',
                'Die Erfahrung des Arztes mit Synaptix bei früh einsetzenden neurologischen Erkrankungen bewerten.',
                'Der Arzt wurde kürzlich zum Hauptprüfer einer multizentrischen Neurologiestudie ernannt.',
                'Forschung zu Biomarkern für Krankheitsprogression auf der Jahrestagung der Deutschen Gesellschaft für Neurologie präsentiert.' },
            new String[]{ 'Immunologie',
                'Der Arzt hat an 160 Besuchen teilgenommen, was ein starkes Engagement im Immunologie-Portfolio zeigt.',
                'Immunexis wurde in 110 Besuchen besprochen. Rheumavex in 35 Besuchen.',
                'Informationen zu Immunexis-Biosimilar-Übergangsdaten und Umstellungsprotokollen angefordert.',
                'Die Erfahrung des Arztes mit Immunexis besprechen und Bedenken zur Biosimilar-Umstellung klären.',
                'Die Positionierung von Rheumavex für Patienten mit unzureichendem Ansprechen auf konventionelle DMARDs überprüfen.',
                'Als Hauptprüfer für eine rheumatologische Registerstudie an seiner Einrichtung ernannt.',
                'Forschung zu Treat-to-Target-Strategien bei rheumatoider Arthritis in der Zeitschrift für Rheumatologie veröffentlicht.' }
        });

        // Italian
        m.put('IT', new List<String[]>{
            new String[]{ 'Oncologia',
                'Il medico ha partecipato a 180 visite nell\'ultimo anno, dimostrando un forte coinvolgimento nel portafoglio oncologico.',
                'Alto coinvolgimento con Oncolyra, discusso in 120 visite, seguito da Tumorex in 40 visite.',
                'È stata presentata una recente richiesta di informazioni cliniche su Oncolyra, incentrata sulla terapia combinata per i tumori solidi avanzati.',
                'Discutere gli ultimi dati di Fase III di Oncolyra ed esplorare l\'interesse per il prossimo advisory board.',
                'Verificare il volume di pazienti del medico per le indicazioni ammissibili e identificare opportunità per Tumorex.',
                'Il medico ha recentemente stabilito un\'affiliazione con un centro oncologico regionale, ampliando la rete di riferimento.',
                'Pubblicazione recente di un articolo sulle combinazioni di immunoterapia nei Tumori.' },
            new String[]{ 'Cardiologia',
                'Il medico ha effettuato 150 visite nell\'ultimo anno, dimostrando un impegno costante nel portafoglio cardiologico.',
                'Focus principale su Cardiomex, discusso in 95 visite. Interesse secondario per Vasculin, 35 visite.',
                'Richiesta di informazioni mediche presentata riguardo l\'uso di Cardiomex in pazienti con comorbidità renali.',
                'Condividere nuovi dati real-world sugli esiti di Cardiomex nell\'insufficienza cardiaca con frazione di eiezione preservata.',
                'Esplorare il punto di vista del medico sui dati emergenti degli inibitori SGLT2 rispetto a Cardiomex.',
                'Recentemente nominato responsabile della cardiologia interventistica presso l\'ospedale affiliato.',
                'Coautore di una meta-analisi sui nuovi anticoagulanti pubblicata sul Giornale Italiano di Cardiologia.' },
            new String[]{ 'Neurologia',
                'Il medico ha completato 130 visite, mostrando un crescente coinvolgimento nel portafoglio neurologico.',
                'Neurovex è stato il prodotto più discusso in 85 visite. Synaptix è stato discusso in 30 visite.',
                'Richiesta di informazioni aggiuntive sul meccanismo d\'azione di Neurovex nell\'epilessia resistente al trattamento.',
                'Presentare i dati di sicurezza a lungo termine aggiornati per Neurovex e discutere i criteri di selezione dei pazienti.',
                'Valutare l\'esperienza del medico con Synaptix nelle condizioni neurologiche a esordio precoce.',
                'Il medico è stato recentemente nominato investigatore principale per uno studio neurologico multicentrico.',
                'Presentazione di ricerche sui biomarcatori della progressione della malattia al Congresso della Società Italiana di Neurologia.' },
            new String[]{ 'Immunologia',
                'Il medico ha partecipato a 160 visite, indicando un forte coinvolgimento nel portafoglio immunologico.',
                'Immunexis è stato discusso in 110 visite. Rheumavex in 35 visite.',
                'Richiesta di informazioni sui dati di transizione biosimilare di Immunexis e protocolli di sostituzione.',
                'Discutere l\'esperienza del medico con Immunexis e affrontare le preoccupazioni relative alla sostituzione biosimilare.',
                'Rivedere il posizionamento di Rheumavex per pazienti con risposta inadeguata ai DMARDs convenzionali.',
                'Nominato investigatore principale per uno studio di registro reumatologico presso la sua struttura.',
                'Pubblicazione di ricerche sulle strategie treat-to-target nell\'artrite reumatoide sulla Reumatismo.' }
        });

        // Spanish (ES, MX, AR)
        List<String[]> esTemplates = new List<String[]>{
            new String[]{ 'Oncología',
                'El médico participó en 180 visitas durante el último año, lo que indica un fuerte compromiso con el portafolio de oncología.',
                'Alto compromiso con Oncolyra, discutido en 120 visitas, seguido de Tumorex en 40 visitas.',
                'Se presentó una consulta clínica reciente sobre Oncolyra, centrada en la terapia combinada para tumores sólidos avanzados.',
                'Discutir los últimos datos de Fase III de Oncolyra y explorar el interés en el próximo comité asesor.',
                'Revisar el volumen de pacientes del médico para indicaciones elegibles e identificar oportunidades para Tumorex.',
                'El médico estableció recientemente una afiliación con un centro oncológico regional, ampliando su red de derivación.',
                'Publicación reciente de un artículo sobre combinaciones de inmunoterapia en la Revista Española de Oncología.' },
            new String[]{ 'Cardiología',
                'El médico realizó 150 visitas durante el último año, demostrando un compromiso constante con el portafolio de cardiología.',
                'Enfoque principal en Cardiomex, discutido en 95 visitas. Interés secundario en Vasculin, 35 visitas.',
                'Solicitud de información médica presentada sobre el uso de Cardiomex en pacientes con comorbilidades renales.',
                'Compartir nuevos datos de evidencia del mundo real sobre los resultados de Cardiomex en insuficiencia cardíaca con fracción de eyección preservada.',
                'Explorar la perspectiva del médico sobre los datos emergentes de inhibidores SGLT2 frente a Cardiomex.',
                'Recientemente nombrado jefe de cardiología intervencionista en el hospital afiliado.',
                'Coautor de un metaanálisis sobre nuevos anticoagulantes publicado en la Revista Española de Cardiología.' },
            new String[]{ 'Neurología',
                'El médico completó 130 visitas, mostrando un creciente compromiso con el portafolio de neurología.',
                'Neurovex fue el producto más discutido en 85 visitas. Synaptix se discutió en 30 visitas.',
                'Solicitud de información adicional sobre el mecanismo de acción de Neurovex en epilepsia resistente al tratamiento.',
                'Presentar datos de seguridad a largo plazo actualizados de Neurovex y discutir criterios de selección de pacientes.',
                'Evaluar la experiencia del médico con Synaptix en condiciones neurológicas de inicio temprano.',
                'El médico fue recientemente nombrado investigador principal de un ensayo neurológico multicéntrico.',
                'Presentación de investigación sobre biomarcadores de progresión de la enfermedad en el Congreso de la Sociedad Española de Neurología.' },
            new String[]{ 'Inmunología',
                'El médico participó en 160 visitas, indicando un fuerte compromiso con el portafolio de inmunología.',
                'Immunexis se discutió en 110 visitas. Rheumavex en 35 visitas.',
                'Solicitud de información sobre datos de transición biosimilar de Immunexis y protocolos de cambio.',
                'Discutir la experiencia del médico con Immunexis y abordar las preocupaciones sobre el cambio a biosimilares.',
                'Revisar el posicionamiento de Rheumavex para pacientes con respuesta inadecuada a DMARDs convencionales.',
                'Nombrado investigador principal de un estudio de registro de reumatología en su institución.',
                'Publicación de investigación sobre estrategias treat-to-target en artritis reumatoide en Reumatología Clínica.' }
        };
        m.put('ES', esTemplates);
        m.put('MX', esTemplates);
        m.put('AR', esTemplates);

        // Japanese
        m.put('JP', new List<String[]>{
            new String[]{ '腫瘍学',
                '過去1年間に180回の訪問に参加し、腫瘍学ポートフォリオへの強い関与を示しています。',
                'Oncolyraへの高い関与が120回の訪問で確認され、Tumorexは40回の訪問で議論されました。',
                '進行固形腫瘍に対する併用療法に焦点を当てたOncolyraに関する臨床問い合わせが最近提出されました。',
                'Oncolyraの最新のPhase IIIデータを議論し、今後のアドバイザリーボードへの関心を探る。',
                '適格な適応症における医師の患者数を確認し、Tumorexの機会を特定する。',
                '医師は最近、地域のがんセンターとの提携を確立し、紹介ネットワークを拡大しました。',
                '免疫療法の併用に関する論文を日本癌学会誌に最近発表しました。' },
            new String[]{ '循環器学',
                '過去1年間に150回の訪問を行い、循環器ポートフォリオへの一貫した関与を示しています。',
                'Cardiomexが95回の訪問で主な焦点でした。Vasculinは35回の訪問で二次的関心がありました。',
                '腎合併症を有する患者におけるCardiomexの使用に関する医療情報要請が提出されました。',
                '駆出率が保たれた心不全におけるCardiomexの転帰に関する新しいリアルワールドエビデンスデータを共有する。',
                '新たなSGLT2阻害薬データとCardiomexとの位置づけに関する医師の見解を探る。',
                '最近、関連病院の心臓血管インターベンション部門の部長に任命されました。',
                '新規抗凝固薬に関するメタ分析を日本循環器学会誌に共著で発表しました。' },
            new String[]{ '神経学',
                '130回の訪問を完了し、神経学ポートフォリオへの関与が高まっています。',
                'Neurovexが85回の訪問で最も議論された製品でした。Synaptixは30回の訪問で議論されました。',
                '治療抵抗性てんかんにおけるNeurovexの作用機序に関する追加情報が要請されました。',
                'Neurovexの最新の長期安全性データを提示し、患者選択基準を議論する。',
                '早期発症の神経疾患におけるSynaptixの医師の経験を評価する。',
                '医師は最近、多施設共同神経学試験の主任研究者に任命されました。',
                '日本神経学会学術大会で疾患進行のバイオマーカーに関する研究を発表しました。' },
            new String[]{ '免疫学',
                '160回の訪問に参加し、免疫学ポートフォリオへの強い関与を示しています。',
                'Immunexisが110回の訪問で議論されました。Rheumavexは35回の訪問で議論されました。',
                'Immunexisのバイオシミラー移行データおよび切替プロトコルに関する情報が要請されました。',
                'Immunexisに関する医師の経験を議論し、バイオシミラー切替への懸念に対応する。',
                '従来のDMARDsに対する不十分な反応を示す患者へのRheumavexの位置づけを見直す。',
                '自施設でのリウマチ学レジストリ研究の主任研究者に任命されました。',
                '関節リウマチにおけるtreat-to-target戦略に関する研究を日本リウマチ学会誌に発表しました。' }
        });

        // Korean
        m.put('KR', new List<String[]>{
            new String[]{ '종양학',
                '지난 1년간 180회 방문에 참여하여 종양학 포트폴리오에 대한 강한 참여를 보이고 있습니다.',
                'Oncolyra에 대한 높은 참여도가 120회 방문에서 확인되었으며, Tumorex는 40회 방문에서 논의되었습니다.',
                '진행성 고형 종양에 대한 병용요법에 초점을 맞춘 Oncolyra 관련 임상 문의가 최근 제출되었습니다.',
                'Oncolyra의 최신 Phase III 데이터를 논의하고 향후 자문위원회 참여 관심을 탐색합니다.',
                '적격 적응증에 대한 의사의 환자 규모를 검토하고 Tumorex 기회를 파악합니다.',
                '의사는 최근 지역 암센터와의 제휴를 구축하여 의뢰 네트워크를 확대했습니다.',
                '면역요법 병용에 관한 논문을 대한종양학회지에 최근 발표했습니다.' },
            new String[]{ '심장학',
                '지난 1년간 150회 방문을 수행하여 심장학 포트폴리오에 대한 일관된 참여를 보이고 있습니다.',
                'Cardiomex가 95회 방문에서 주요 초점이었습니다. Vasculin은 35회 방문에서 이차적 관심이 있었습니다.',
                '신장 동반질환이 있는 환자에서의 Cardiomex 사용에 관한 의학정보 요청이 제출되었습니다.',
                '박출률 보존 심부전에서의 Cardiomex 결과에 대한 새로운 실사용 근거 데이터를 공유합니다.',
                '새로운 SGLT2 억제제 데이터와 Cardiomex 대비 포지셔닝에 대한 의사의 관점을 탐색합니다.',
                '최근 소속 병원의 중재적 심장학 부문장으로 임명되었습니다.',
                '신규 항응고제에 관한 메타분석을 대한심장학회지에 공동 저술하여 발표했습니다.' },
            new String[]{ '신경학',
                '130회 방문을 완료하여 신경학 포트폴리오에 대한 참여가 증가하고 있습니다.',
                'Neurovex가 85회 방문에서 가장 많이 논의된 제품이었습니다. Synaptix는 30회 방문에서 논의되었습니다.',
                '치료 저항성 간질에서의 Neurovex 작용 기전에 대한 추가 정보가 요청되었습니다.',
                'Neurovex의 최신 장기 안전성 데이터를 제시하고 환자 선택 기준을 논의합니다.',
                '조기 발병 신경학적 질환에서의 Synaptix에 대한 의사의 경험을 평가합니다.',
                '의사는 최근 다기관 신경학 임상시험의 책임연구자로 지명되었습니다.',
                '대한신경과학회 학술대회에서 질병 진행 바이오마커에 관한 연구를 발표했습니다.' },
            new String[]{ '면역학',
                '160회 방문에 참여하여 면역학 포트폴리오에 대한 강한 참여를 보이고 있습니다.',
                'Immunexis가 110회 방문에서 논의되었습니다. Rheumavex는 35회 방문에서 논의되었습니다.',
                'Immunexis 바이오시밀러 전환 데이터 및 전환 프로토콜에 관한 정보가 요청되었습니다.',
                'Immunexis에 대한 의사의 경험을 논의하고 바이오시밀러 전환 관련 우려사항에 대응합니다.',
                '기존 DMARDs에 대한 반응이 불충분한 환자를 위한 Rheumavex 포지셔닝을 검토합니다.',
                '자기 기관에서의 류마티스학 레지스트리 연구 책임연구자로 임명되었습니다.',
                '류마티스 관절염에서의 treat-to-target 전략에 관한 연구를 대한류마티스학회지에 발표했습니다.' }
        });

        // Portuguese (Brazil)
        m.put('BR', new List<String[]>{
            new String[]{ 'Oncologia',
                'O médico participou de 180 visitas no último ano, indicando forte engajamento com o portfólio de oncologia.',
                'Alto engajamento com Oncolyra, discutido em 120 visitas, seguido por Tumorex em 40 visitas.',
                'Uma consulta clínica recente foi submetida sobre Oncolyra, com foco em terapia combinada para tumores sólidos avançados.',
                'Discutir os dados mais recentes de Fase III do Oncolyra e explorar interesse no próximo comitê consultivo.',
                'Revisar o volume de pacientes do médico para indicações elegíveis e identificar oportunidades para Tumorex.',
                'O médico estabeleceu recentemente uma afiliação com um centro oncológico regional, expandindo a rede de referência.',
                'Publicação recente de artigo sobre combinações de imunoterapia na Revista Brasileira de Oncologia Clínica.' },
            new String[]{ 'Cardiologia',
                'O médico realizou 150 visitas no último ano, demonstrando engajamento consistente com o portfólio de cardiologia.',
                'Foco principal em Cardiomex, discutido em 95 visitas. Interesse secundário em Vasculin, 35 visitas.',
                'Solicitação de informação médica sobre o uso de Cardiomex em pacientes com comorbidades renais.',
                'Compartilhar novos dados de evidência do mundo real sobre os desfechos do Cardiomex na insuficiência cardíaca com fração de ejeção preservada.',
                'Explorar a perspectiva do médico sobre os dados emergentes de inibidores de SGLT2 versus Cardiomex.',
                'Recentemente nomeado chefe de cardiologia intervencionista no hospital afiliado.',
                'Coautor de meta-análise sobre novos anticoagulantes publicada nos Arquivos Brasileiros de Cardiologia.' },
            new String[]{ 'Neurologia',
                'O médico completou 130 visitas, mostrando engajamento crescente com o portfólio de neurologia.',
                'Neurovex foi o produto mais discutido em 85 visitas. Synaptix foi discutido em 30 visitas.',
                'Solicitação de informações adicionais sobre o mecanismo de ação do Neurovex na epilepsia resistente ao tratamento.',
                'Apresentar dados atualizados de segurança de longo prazo do Neurovex e discutir critérios de seleção de pacientes.',
                'Avaliar a experiência do médico com Synaptix em condições neurológicas de início precoce.',
                'O médico foi recentemente nomeado investigador principal de um ensaio neurológico multicêntrico.',
                'Apresentação de pesquisa sobre biomarcadores de progressão da doença no Congresso Brasileiro de Neurologia.' },
            new String[]{ 'Imunologia',
                'O médico participou de 160 visitas, indicando forte engajamento com o portfólio de imunologia.',
                'Immunexis foi discutido em 110 visitas. Rheumavex em 35 visitas.',
                'Solicitação de informações sobre dados de transição de biossimilar do Immunexis e protocolos de troca.',
                'Discutir a experiência do médico com Immunexis e abordar preocupações sobre a troca para biossimilares.',
                'Revisar o posicionamento do Rheumavex para pacientes com resposta inadequada a DMARDs convencionais.',
                'Nomeado investigador principal de um estudo de registro de reumatologia em sua instituição.',
                'Publicação de pesquisa sobre estratégias treat-to-target na artrite reumatoide na Revista Brasileira de Reumatologia.' }
        });

        return m;
    }

    private static Map<String, String> buildCityTerritoryMap() {
        Map<String, String> m = new Map<String, String>();

        // US cities
        m.put('US:Boston', 'US_NE_Boston');
        m.put('US:Baltimore', 'US_NE_Washington_DC');
        m.put('US:Cleveland', 'US_MW_Chicago');
        m.put('US:Rochester', 'US_MW_Minneapolis');
        m.put('US:New York', 'US_NE_New_York');
        m.put('US:Houston', 'US_SE_Nashville');
        m.put('US:Oakland', 'US_W_San_Francisco');
        m.put('US:Minnetonka', 'US_MW_Minneapolis');
        m.put('US:Woonsocket', 'US_NE_Boston');

        // GB cities
        m.put('GB:London', 'GB_England_London');
        m.put('GB:Cambridge', 'GB_England_London');
        m.put('GB:Nottingham', 'GB_England_Birmingham');
        m.put('GB:Manchester', 'GB_England_Manchester');

        // FR cities
        m.put('FR:Paris', 'FR_Ile_de_France_Paris');
        m.put('FR:Villejuif', 'FR_Ile_de_France_Paris');
        m.put('FR:Lyon', 'FR_Auvergne_Lyon');
        m.put('FR:Toulouse', 'FR_Occitanie_Toulouse');

        // DE cities
        m.put('DE:Berlin', 'DE_Berlin_Berlin');
        m.put('DE:Heidelberg', 'DE_Hesse_Frankfurt');
        m.put('DE:Hamburg', 'DE_Hamburg_Hamburg');
        m.put('DE:Munich', 'DE_Bavaria_Munich');
        m.put('DE:Heerlen', 'DE_NRW_Dusseldorf');
        m.put('DE:Dusseldorf', 'DE_NRW_Dusseldorf');
        m.put('DE:Frankfurt', 'DE_Hesse_Frankfurt');

        // IT cities
        m.put('IT:Rome', 'IT_Lazio_Rome');
        m.put('IT:Milan', 'IT_Lombardy_Milan');
        m.put('IT:Padua', 'IT_Veneto_Venice');
        m.put('IT:Naples', 'IT_Campania_Naples');
        m.put('IT:Florence', 'IT_Tuscany_Florence');

        // ES cities
        m.put('ES:Barcelona', 'ES_Catalonia_Barcelona');
        m.put('ES:Madrid', 'ES_Madrid_Madrid');
        m.put('ES:Seville', 'ES_Andalusia_Seville');
        m.put('ES:Valencia', 'ES_Valencia_Valencia');

        // JP cities
        m.put('JP:Tokyo', 'JP_Kanto_Tokyo');
        m.put('JP:Osaka', 'JP_Kansai_Osaka');
        m.put('JP:Nagoya', 'JP_Chubu_Nagoya');
        m.put('JP:Yokohama', 'JP_Kanto_Yokohama');
        m.put('JP:Kyoto', 'JP_Kansai_Kyoto');
        m.put('JP:Kamogawa', 'JP_Kanto_Tokyo');

        // KR cities
        m.put('KR:Seoul', 'KR_Seoul_Seoul');
        m.put('KR:Busan', 'KR_Busan_Busan');
        m.put('KR:Seongnam', 'KR_Gyeonggi_Seongnam');
        m.put('KR:Wonju', 'KR_Seoul_Seoul');
        m.put('KR:Incheon', 'KR_Incheon_Incheon');

        // BR cities
        m.put('BR:São Paulo', 'BR_SP_Sao_Paulo');
        m.put('BR:Rio de Janeiro', 'BR_RJ_Rio_de_Janeiro');
        m.put('BR:Porto Alegre', 'BR_RS_Porto_Alegre');
        m.put('BR:Belo Horizonte', 'BR_MG_Belo_Horizonte');
        m.put('BR:Salvador', 'BR_BA_Salvador');
        m.put('BR:Brasília', 'BR_SP_Sao_Paulo');

        // MX cities
        m.put('MX:Mexico City', 'MX_CDMX_Mexico_City');
        m.put('MX:Guadalajara', 'MX_Jalisco_Guadalajara');
        m.put('MX:Monterrey', 'MX_NuevoLeon_Monterrey');
        m.put('MX:Puebla', 'MX_Puebla_Puebla');

        // AR cities
        m.put('AR:Buenos Aires', 'AR_CABA_Buenos_Aires');
        m.put('AR:Pilar', 'AR_BuenosAires_La_Plata');
        m.put('AR:Córdoba', 'AR_Cordoba_Cordoba');
        m.put('AR:Rosario', 'AR_SantaFe_Rosario');

        return m;
    }

}
