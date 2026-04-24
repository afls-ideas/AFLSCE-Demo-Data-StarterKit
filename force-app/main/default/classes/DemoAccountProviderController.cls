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
            List<Account> orgAccounts = buildOrganizationAccounts(hcoRtId);
            Database.SaveResult[] orgResults = Database.insert(orgAccounts, false);

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
            Database.SaveResult[] docResults = Database.insert(doctorAccounts, false);

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
                    List<SObject> specRecords = buildSpecialtyRecords(hcpNameToId, specNameToId);
                    Database.SaveResult[] specResults = Database.insert(specRecords, false);
                    for (Database.SaveResult sr : specResults) {
                        if (sr.isSuccess()) specSuccess++;
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

        // ---- United States ----
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

        // ---- United Kingdom ----
        accts.add(makeOrg(hcoRtId, 'Royal London Hospital', 'Whitechapel Road', 'London', null, 'E1 1FR', 'GB', '+44 20 7377 7000', 'https://www.bartshealth.nhs.uk', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'St Thomas\' Hospital', 'Westminster Bridge Road', 'London', null, 'SE1 7EH', 'GB', '+44 20 7188 7188', 'https://www.guysandstthomas.nhs.uk', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Addenbrooke\'s Hospital', 'Hills Road', 'Cambridge', null, 'CB2 0QQ', 'GB', '+44 1223 245151', 'https://www.cuh.nhs.uk', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'NHS England', 'Skipton House, 80 London Road', 'London', null, 'SE1 6LH', 'GB', '+44 300 311 2233', 'https://www.england.nhs.uk', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'BUPA', '1 Angel Court', 'London', null, 'EC2R 7HJ', 'GB', '+44 345 600 8822', 'https://www.bupa.co.uk', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'Boots UK', 'Thane Road', 'Nottingham', null, 'NG2 3AA', 'GB', '+44 115 950 6111', 'https://www.boots.com', 'Pharmacy'));

        // ---- France ----
        accts.add(makeOrg(hcoRtId, 'Hôpital Pitié-Salpêtrière', '47-83 Boulevard de l\'Hôpital', 'Paris', null, '75013', 'FR', '+33 1 42 16 00 00', 'https://www.aphp.fr/pitie-salpetriere', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hôpital Européen Georges-Pompidou', '20 Rue Leblanc', 'Paris', null, '75015', 'FR', '+33 1 56 09 20 00', 'https://www.aphp.fr/hegp', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Centre Hospitalier Universitaire de Lyon', '3 Quai des Célestins', 'Lyon', null, '69002', 'FR', '+33 4 72 11 69 11', 'https://www.chu-lyon.fr', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Institut Gustave Roussy', '114 Rue Édouard-Vaillant', 'Villejuif', null, '94805', 'FR', '+33 1 42 11 42 11', 'https://www.gustaveroussy.fr', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Assurance Maladie (CNAM)', '50 Avenue du Professeur André Lemierre', 'Paris', null, '75020', 'FR', '+33 1 72 60 10 00', 'https://www.ameli.fr', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'Pharmacie du Forum des Halles', '101 Rue Berger', 'Paris', null, '75001', 'FR', '+33 1 42 36 00 00', 'https://www.pharmacieforum.fr', 'Pharmacy'));

        // ---- Germany ----
        accts.add(makeOrg(hcoRtId, 'Charité - Universitätsmedizin Berlin', 'Charitéplatz 1', 'Berlin', null, '10117', 'DE', '+49 30 450 50', 'https://www.charite.de', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Universitätsklinikum Heidelberg', 'Im Neuenheimer Feld 672', 'Heidelberg', null, '69120', 'DE', '+49 6221 56 0', 'https://www.klinikum.uni-heidelberg.de', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Universitätsklinikum Hamburg-Eppendorf', 'Martinistraße 52', 'Hamburg', null, '20246', 'DE', '+49 40 7410 0', 'https://www.uke.de', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Munich Heart Centre', 'Lazarettstraße 36', 'Munich', null, '80636', 'DE', '+49 89 1218 0', 'https://www.dhm.mhn.de', 'Clinic'));
        accts.add(makeOrg(hcoRtId, 'AOK - Die Gesundheitskasse', 'Rosenthaler Straße 31', 'Berlin', null, '10178', 'DE', '+49 800 265 0800', 'https://www.aok.de', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'DocMorris', 'Carl-Zeiss-Ring 4', 'Heerlen', null, '52078', 'DE', '+49 800 444 0200', 'https://www.docmorris.de', 'Pharmacy'));

        // ---- Italy ----
        accts.add(makeOrg(hcoRtId, 'Policlinico Agostino Gemelli', 'Largo Agostino Gemelli 8', 'Rome', 'RM', '00168', 'IT', '+39 06 3015 1', 'https://www.policlinicogemelli.it', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Ospedale San Raffaele', 'Via Olgettina 60', 'Milan', 'MI', '20132', 'IT', '+39 02 2643 2643', 'https://www.hsr.it', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Istituto Europeo di Oncologia', 'Via Ripamonti 435', 'Milan', 'MI', '20141', 'IT', '+39 02 5748 9001', 'https://www.ieo.it', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Azienda Ospedaliera di Padova', 'Via Giustiniani 2', 'Padua', 'PD', '35128', 'IT', '+39 049 821 1111', 'https://www.aopd.veneto.it', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'ASL Roma 1', 'Borgo Santo Spirito 3', 'Rome', 'RM', '00193', 'IT', '+39 06 6835 1', 'https://www.aslroma1.it', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'Farmacia del Corso', 'Corso Buenos Aires 4', 'Milan', 'MI', '20124', 'IT', '+39 02 2951 4380', 'https://www.farmaciadelcorso.it', 'Pharmacy'));

        // ---- Spain ----
        accts.add(makeOrg(hcoRtId, 'Hospital Clínic de Barcelona', 'Carrer de Villarroel 170', 'Barcelona', null, '08036', 'ES', '+34 93 227 54 00', 'https://www.clinicbarcelona.org', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital Universitario La Paz', 'Paseo de la Castellana 261', 'Madrid', null, '28046', 'ES', '+34 91 727 70 00', 'https://www.comunidad.madrid/hospital/lapaz', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Hospital Universitario Vall d\'Hebron', 'Passeig de la Vall d\'Hebron 119-129', 'Barcelona', null, '08035', 'ES', '+34 93 274 60 00', 'https://www.vallhebron.com', 'Hospital'));
        accts.add(makeOrg(hcoRtId, 'Centro Médico Teknon', 'Carrer de Vilana 12', 'Barcelona', null, '08022', 'ES', '+34 93 290 62 00', 'https://www.teknon.es', 'Clinic'));
        accts.add(makeOrg(hcoRtId, 'Sanitas', 'Ribera del Loira 52', 'Madrid', null, '28042', 'ES', '+34 91 585 29 00', 'https://www.sanitas.es', 'Insurance'));
        accts.add(makeOrg(hcoRtId, 'Farmacia Ortopedia Gaztambide', 'Calle de Gaztambide 55', 'Madrid', null, '28015', 'ES', '+34 91 549 42 60', 'https://www.farmaciagaztambide.com', 'Pharmacy'));

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
        return a;
    }

    // ---------------------------------------------------------------------------
    // Doctor PersonAccount builders (Health_Care_Provider record type)
    // ---------------------------------------------------------------------------

    private static List<Account> buildDoctorAccounts(Id hcpRtId) {
        List<Account> docs = new List<Account>();

        // US Doctors
        docs.add(makeDoctor(hcpRtId, 'Sarah', 'Mitchell', 'sarah.mitchell@massgeneral.example.com', '+1 (617) 726-2001', 'Boston', 'MA', '02114', 'US'));
        docs.add(makeDoctor(hcpRtId, 'James', 'Patterson', 'james.patterson@jhmi.example.com', '+1 (410) 955-5001', 'Baltimore', 'MD', '21287', 'US'));
        docs.add(makeDoctor(hcpRtId, 'Emily', 'Chen', 'emily.chen@ccf.example.com', '+1 (216) 444-2201', 'Cleveland', 'OH', '44195', 'US'));
        docs.add(makeDoctor(hcpRtId, 'Michael', 'Rodriguez', 'michael.rodriguez@mayo.example.com', '+1 (507) 284-2512', 'Rochester', 'MN', '55905', 'US'));
        docs.add(makeDoctor(hcpRtId, 'Jennifer', 'Goldstein', 'jennifer.goldstein@mskcc.example.com', '+1 (212) 639-2001', 'New York', 'NY', '10065', 'US'));
        docs.add(makeDoctor(hcpRtId, 'David', 'Kumar', 'david.kumar@mdanderson.example.com', '+1 (713) 792-2122', 'Houston', 'TX', '77030', 'US'));
        docs.add(makeDoctor(hcpRtId, 'Robert', 'Washington', 'robert.washington@midtownonc.example.com', '+1 (212) 305-5099', 'New York', 'NY', '10065', 'US'));

        // UK Doctors
        docs.add(makeDoctor(hcpRtId, 'William', 'Hartley', 'william.hartley@nhs.example.com', '+44 20 7377 7001', 'London', null, 'E1 1FR', 'GB'));
        docs.add(makeDoctor(hcpRtId, 'Eleanor', 'Blackwood', 'eleanor.blackwood@gstt.example.com', '+44 20 7188 7189', 'London', null, 'SE1 7EH', 'GB'));
        docs.add(makeDoctor(hcpRtId, 'Oliver', 'Pemberton', 'oliver.pemberton@cuh.example.com', '+44 1223 245152', 'Cambridge', null, 'CB2 0QQ', 'GB'));
        docs.add(makeDoctor(hcpRtId, 'Charlotte', 'Ainsworth', 'charlotte.ainsworth@nhs.example.com', '+44 20 7377 7002', 'London', null, 'E1 1FR', 'GB'));
        docs.add(makeDoctor(hcpRtId, 'George', 'Whitfield', 'george.whitfield@gstt.example.com', '+44 20 7188 7190', 'London', null, 'SE1 7EH', 'GB'));

        // France Doctors
        docs.add(makeDoctor(hcpRtId, 'Pierre', 'Lefèvre', 'pierre.lefevre@aphp.example.com', '+33 1 42 16 00 01', 'Paris', null, '75013', 'FR'));
        docs.add(makeDoctor(hcpRtId, 'Marie-Claire', 'Dubois', 'marie.dubois@aphp.example.com', '+33 1 56 09 20 01', 'Paris', null, '75015', 'FR'));
        docs.add(makeDoctor(hcpRtId, 'François', 'Moreau', 'francois.moreau@chu-lyon.example.com', '+33 4 72 11 69 12', 'Lyon', null, '69002', 'FR'));
        docs.add(makeDoctor(hcpRtId, 'Camille', 'Rousseau', 'camille.rousseau@igr.example.com', '+33 1 42 11 42 12', 'Villejuif', null, '94805', 'FR'));
        docs.add(makeDoctor(hcpRtId, 'Jean-Luc', 'Bernard', 'jeanluc.bernard@aphp.example.com', '+33 1 42 16 00 02', 'Paris', null, '75013', 'FR'));

        // Germany Doctors
        docs.add(makeDoctor(hcpRtId, 'Klaus', 'Müller', 'klaus.mueller@charite.example.com', '+49 30 450 51', 'Berlin', null, '10117', 'DE'));
        docs.add(makeDoctor(hcpRtId, 'Anna', 'Schneider', 'anna.schneider@ukl-hd.example.com', '+49 6221 56 1', 'Heidelberg', null, '69120', 'DE'));
        docs.add(makeDoctor(hcpRtId, 'Stefan', 'Weber', 'stefan.weber@uke.example.com', '+49 40 7410 1', 'Hamburg', null, '20246', 'DE'));
        docs.add(makeDoctor(hcpRtId, 'Katrin', 'Fischer', 'katrin.fischer@charite.example.com', '+49 30 450 52', 'Berlin', null, '10117', 'DE'));
        docs.add(makeDoctor(hcpRtId, 'Hans-Peter', 'Braun', 'hp.braun@dhm.example.com', '+49 89 1218 1', 'Munich', null, '80636', 'DE'));

        // Italy Doctors
        docs.add(makeDoctor(hcpRtId, 'Marco', 'Rossi', 'marco.rossi@gemelli.example.com', '+39 06 3015 2', 'Rome', 'RM', '00168', 'IT'));
        docs.add(makeDoctor(hcpRtId, 'Giulia', 'Bianchi', 'giulia.bianchi@ieo.example.com', '+39 02 5748 9002', 'Milan', 'MI', '20141', 'IT'));
        docs.add(makeDoctor(hcpRtId, 'Alessandro', 'Conti', 'alessandro.conti@hsr.example.com', '+39 02 2643 2644', 'Milan', 'MI', '20132', 'IT'));
        docs.add(makeDoctor(hcpRtId, 'Francesca', 'Romano', 'francesca.romano@aopd.example.com', '+39 049 821 1112', 'Padua', 'PD', '35128', 'IT'));
        docs.add(makeDoctor(hcpRtId, 'Luca', 'Ferretti', 'luca.ferretti@hsr.example.com', '+39 02 2643 2645', 'Milan', 'MI', '20132', 'IT'));

        // Spain Doctors
        docs.add(makeDoctor(hcpRtId, 'Carlos', 'García López', 'carlos.garcia@clinic.example.com', '+34 93 227 54 01', 'Barcelona', null, '08036', 'ES'));
        docs.add(makeDoctor(hcpRtId, 'María', 'Fernández Ruiz', 'maria.fernandez@lapaz.example.com', '+34 91 727 70 01', 'Madrid', null, '28046', 'ES'));
        docs.add(makeDoctor(hcpRtId, 'Alejandro', 'Martínez Soto', 'alejandro.martinez@vhebron.example.com', '+34 93 274 60 01', 'Barcelona', null, '08035', 'ES'));
        docs.add(makeDoctor(hcpRtId, 'Isabel', 'Navarro Díaz', 'isabel.navarro@teknon.example.com', '+34 93 290 62 01', 'Barcelona', null, '08022', 'ES'));
        docs.add(makeDoctor(hcpRtId, 'Pablo', 'Herrera Molina', 'pablo.herrera@clinic.example.com', '+34 93 227 54 02', 'Barcelona', null, '08036', 'ES'));

        return docs;
    }

    private static Account makeDoctor(Id rtId, String firstName, String lastName, String email, String phone, String city, String stateCode, String postalCode, String countryCode) {
        Account a = new Account();
        a.RecordTypeId = rtId;
        a.Salutation = 'Dr.';
        a.FirstName = firstName;
        a.LastName = lastName;
        a.PersonEmail = email;
        a.Phone = phone;
        a.BillingCity = city;
        a.BillingPostalCode = postalCode;
        a.BillingCountryCode = countryCode;
        if (String.isNotBlank(stateCode)) {
            a.BillingStateCode = stateCode;
        }
        a.Site = DEMO_TAG;
        return a;
    }

    // ---------------------------------------------------------------------------
    // HealthcareProvider builders (linked to doctor PersonAccounts)
    // ---------------------------------------------------------------------------

    private static List<SObject> buildHealthcareProviders(Map<String, Id> doctorNameToId) {
        List<SObject> providers = new List<SObject>();
        Schema.SObjectType hcpType = Schema.getGlobalDescribe().get('healthcareprovider');

        // Each HCP record is named "Dr. FirstName LastName" and linked to the PersonAccount
        for (String fullName : doctorNameToId.keySet()) {
            SObject hcp = hcpType.newSObject();
            hcp.put('Name', 'Dr. ' + fullName);
            hcp.put('AccountId', doctorNameToId.get(fullName));
            hcp.put('SourceSystem', DEMO_TAG);
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

        Map<String, String> npiMap = new Map<String, String>{
            'Dr. Sarah Mitchell' => '1234567890',
            'Dr. James Patterson' => '1234567891',
            'Dr. Emily Chen' => '1234567892',
            'Dr. Michael Rodriguez' => '1234567893',
            'Dr. Jennifer Goldstein' => '1234567894',
            'Dr. David Kumar' => '1234567895',
            'Dr. Robert Washington' => '1234567896',
            'Dr. William Hartley' => '2345678901',
            'Dr. Eleanor Blackwood' => '2345678902',
            'Dr. Oliver Pemberton' => '2345678903',
            'Dr. Charlotte Ainsworth' => '2345678904',
            'Dr. George Whitfield' => '2345678905',
            'Dr. Pierre Lefèvre' => '3456789012',
            'Dr. Marie-Claire Dubois' => '3456789013',
            'Dr. François Moreau' => '3456789014',
            'Dr. Camille Rousseau' => '3456789015',
            'Dr. Jean-Luc Bernard' => '3456789016',
            'Dr. Klaus Müller' => '4567890128',
            'Dr. Anna Schneider' => '4567890124',
            'Dr. Stefan Weber' => '4567890125',
            'Dr. Katrin Fischer' => '4567890126',
            'Dr. Hans-Peter Braun' => '4567890127',
            'Dr. Marco Rossi' => '5678901234',
            'Dr. Giulia Bianchi' => '5678901235',
            'Dr. Alessandro Conti' => '5678901236',
            'Dr. Francesca Romano' => '5678901237',
            'Dr. Luca Ferretti' => '5678901238',
            'Dr. Carlos García López' => '6789012345',
            'Dr. María Fernández Ruiz' => '6789012346',
            'Dr. Alejandro Martínez Soto' => '6789012347',
            'Dr. Isabel Navarro Díaz' => '6789012348',
            'Dr. Pablo Herrera Molina' => '6789012349'
        };

        for (String provName : npiMap.keySet()) {
            Id hcpId = hcpNameToId.get(provName);
            if (hcpId != null) {
                SObject npi = npiType.newSObject();
                npi.put('Name', provName + ' NPI');
                npi.put('Npi', npiMap.get(provName));
                npi.put('NpiType', 'Individual');
                npi.put('HealthcareProviderId', hcpId);
                npi.put('EffectiveFrom', Date.newInstance(2020, 1, 1));
                npi.put('EffectiveTo', Date.newInstance(2030, 12, 31));
                npi.put('IsActive', true);
                npi.put('SourceSystem', DEMO_TAG);
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

    private static List<SObject> buildSpecialtyRecords(Map<String, Id> hcpNameToId, Map<String, Id> specNameToId) {
        List<SObject> specs = new List<SObject>();
        Schema.SObjectType specType = Schema.getGlobalDescribe().get('healthcareproviderspecialty');

        Map<String, String> providerSpecialties = new Map<String, String>{
            'Dr. Sarah Mitchell' => 'Oncology',
            'Dr. James Patterson' => 'Cardiology',
            'Dr. Emily Chen' => 'Neurology',
            'Dr. Michael Rodriguez' => 'Internal Medicine',
            'Dr. Jennifer Goldstein' => 'Oncology',
            'Dr. David Kumar' => 'Oncology',
            'Dr. Robert Washington' => 'Gastroenterology',
            'Dr. William Hartley' => 'Cardiology',
            'Dr. Eleanor Blackwood' => 'Pulmonology',
            'Dr. Oliver Pemberton' => 'Endocrinology',
            'Dr. Charlotte Ainsworth' => 'Dermatology',
            'Dr. George Whitfield' => 'Orthopedics',
            'Dr. Pierre Lefèvre' => 'Neurology',
            'Dr. Marie-Claire Dubois' => 'Cardiology',
            'Dr. François Moreau' => 'Internal Medicine',
            'Dr. Camille Rousseau' => 'Oncology',
            'Dr. Jean-Luc Bernard' => 'Immunology',
            'Dr. Klaus Müller' => 'Oncology',
            'Dr. Anna Schneider' => 'Neurology',
            'Dr. Stefan Weber' => 'Cardiology',
            'Dr. Katrin Fischer' => 'Pediatrics',
            'Dr. Hans-Peter Braun' => 'Cardiology',
            'Dr. Marco Rossi' => 'Gastroenterology',
            'Dr. Giulia Bianchi' => 'Oncology',
            'Dr. Alessandro Conti' => 'Cardiology',
            'Dr. Francesca Romano' => 'Dermatology',
            'Dr. Luca Ferretti' => 'Pulmonology',
            'Dr. Carlos García López' => 'Immunology',
            'Dr. María Fernández Ruiz' => 'Oncology',
            'Dr. Alejandro Martínez Soto' => 'Neurology',
            'Dr. Isabel Navarro Díaz' => 'Endocrinology',
            'Dr. Pablo Herrera Molina' => 'Family Medicine'
        };

        for (String provName : providerSpecialties.keySet()) {
            Id hcpId = hcpNameToId.get(provName);
            String specName = providerSpecialties.get(provName);
            Id careSpecId = specNameToId.get(specName);
            if (hcpId != null && careSpecId != null) {
                SObject spec = specType.newSObject();
                spec.put('Name', provName + ' - ' + specName);
                spec.put('HealthcareProviderId', hcpId);
                spec.put('SpecialtyId', careSpecId);
                spec.put('IsActive', true);
                spec.put('IsPrimarySpecialty', true);
                spec.put('SourceSystem', DEMO_TAG);
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
                SELECT Id, Name, BillingCity, BillingCountryCode
                FROM Account
                WHERE Site = :DEMO_TAG
            ];
            if (demoAccounts.isEmpty()) return 'No demo accounts found.';

            // Build territory lookup: DeveloperName -> Id
            Map<String, Id> terrByDev = new Map<String, Id>();
            for (Territory2 t : [SELECT Id, DeveloperName FROM Territory2]) {
                terrByDev.put(t.DeveloperName, t.Id);
            }

            // Remove existing demo-account territory associations
            Set<Id> acctIds = new Set<Id>();
            for (Account a : demoAccounts) acctIds.add(a.Id);
            List<ObjectTerritory2Association> existing = [
                SELECT Id FROM ObjectTerritory2Association
                WHERE ObjectId IN :acctIds
            ];
            if (!existing.isEmpty()) Database.delete(existing, false);

            // Build city->territory mapping
            Map<String, String> cityTerrMap = buildCityTerritoryMap();

            // Country fallback mapping
            Map<String, String> countryTerrMap = new Map<String, String>{
                'US' => 'US_COUNTRY',
                'GB' => 'GB_COUNTRY',
                'FR' => 'FR_COUNTRY',
                'DE' => 'DE_COUNTRY',
                'IT' => 'IT_COUNTRY',
                'ES' => 'ES_COUNTRY'
            };

            List<ObjectTerritory2Association> associations = new List<ObjectTerritory2Association>();
            Integer matched = 0;
            Integer fallback = 0;

            for (Account acct : demoAccounts) {
                String city = acct.BillingCity;
                String country = acct.BillingCountryCode;
                String terrDev = null;

                // Try city-level match
                if (String.isNotBlank(city)) {
                    String key = (String.isNotBlank(country) ? country : '') + ':' + city;
                    terrDev = cityTerrMap.get(key);
                }

                // Fallback to country level
                if (terrDev == null && String.isNotBlank(country)) {
                    terrDev = countryTerrMap.get(country);
                    if (terrDev != null) fallback++;
                } else if (terrDev != null) {
                    matched++;
                }

                if (terrDev != null && terrByDev.containsKey(terrDev)) {
                    ObjectTerritory2Association ota = new ObjectTerritory2Association();
                    ota.ObjectId = acct.Id;
                    ota.Territory2Id = terrByDev.get(terrDev);
                    ota.AssociationCause = 'Territory2Manual';
                    associations.add(ota);
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
                    errors.add(demoAccounts[i].Name + ': ' + results[i].getErrors()[0].getMessage());
                }
            }

            String result = 'Territory assignments: ' + success + '/' + associations.size()
                + ' (city match: ' + matched + ', country fallback: ' + fallback + ')';
            if (!errors.isEmpty()) result += ' | Errors: ' + String.join(errors, '; ');
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error assigning territories: ' + e.getMessage());
        }
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

        // FR cities
        m.put('FR:Paris', 'FR_Ile_de_France_Paris');
        m.put('FR:Villejuif', 'FR_Ile_de_France_Paris');
        m.put('FR:Lyon', 'FR_Auvergne_Lyon');

        // DE cities
        m.put('DE:Berlin', 'DE_Berlin_Berlin');
        m.put('DE:Heidelberg', 'DE_Hesse_Frankfurt');
        m.put('DE:Hamburg', 'DE_Hamburg_Hamburg');
        m.put('DE:Munich', 'DE_Bavaria_Munich');
        m.put('DE:Heerlen', 'DE_NRW_Dusseldorf');

        // IT cities
        m.put('IT:Rome', 'IT_Lazio_Rome');
        m.put('IT:Milan', 'IT_Lombardy_Milan');
        m.put('IT:Padua', 'IT_Veneto_Venice');

        // ES cities
        m.put('ES:Barcelona', 'ES_Catalonia_Barcelona');
        m.put('ES:Madrid', 'ES_Madrid_Madrid');

        return m;
    }

}
