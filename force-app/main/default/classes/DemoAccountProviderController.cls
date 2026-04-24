/**
 * DemoAccountProviderController
 * Creates realistic demo data for Accounts and Healthcare Providers across 6 countries.
 * All created records are tagged with 'AFLSCE-Demo-Data' in the Description field
 * for easy identification and cleanup.
 */
public with sharing class DemoAccountProviderController {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';

    // ---------------------------------------------------------------------------
    // AuraEnabled entry points
    // ---------------------------------------------------------------------------

    @AuraEnabled
    public static String createAccountsAndProviders() {
        try {
            List<Account> accounts = buildAccounts();
            Database.SaveResult[] acctResults = Database.insert(accounts, false);

            Map<String, Id> acctNameToId = new Map<String, Id>();
            for (Integer i = 0; i < accounts.size(); i++) {
                if (acctResults[i].isSuccess()) {
                    acctNameToId.put(accounts[i].Name, acctResults[i].getId());
                }
            }
            Integer acctSuccess = acctNameToId.size();

            // Healthcare Provider objects (Health Cloud)
            Integer hcpSuccess = 0;
            Integer npiSuccess = 0;
            Integer specSuccess = 0;
            Integer afflSuccess = 0;

            Boolean hasHCP = Schema.getGlobalDescribe().containsKey('healthcareprovider');
            Boolean hasNpi = Schema.getGlobalDescribe().containsKey('healthcareprovidernpi');
            Boolean hasSpec = Schema.getGlobalDescribe().containsKey('healthcareproviderspecialty');
            Boolean hasAffl = Schema.getGlobalDescribe().containsKey('provideraffiliation');

            Map<String, Id> hcpNameToId = new Map<String, Id>();

            if (hasHCP) {
                List<SObject> hcpRecords = buildHealthcareProviders(acctNameToId);
                Database.SaveResult[] hcpResults = Database.insert(hcpRecords, false);
                for (Integer i = 0; i < hcpRecords.size(); i++) {
                    if (hcpResults[i].isSuccess()) {
                        hcpSuccess++;
                        hcpNameToId.put((String) hcpRecords[i].get('Name'), hcpResults[i].getId());
                    }
                }

                if (hasNpi) {
                    List<SObject> npiRecords = buildNpiRecords(hcpNameToId);
                    Database.SaveResult[] npiResults = Database.insert(npiRecords, false);
                    for (Database.SaveResult sr : npiResults) {
                        if (sr.isSuccess()) npiSuccess++;
                    }
                }

                if (hasSpec) {
                    List<SObject> specRecords = buildSpecialtyRecords(hcpNameToId);
                    Database.SaveResult[] specResults = Database.insert(specRecords, false);
                    for (Database.SaveResult sr : specResults) {
                        if (sr.isSuccess()) specSuccess++;
                    }
                }

                if (hasAffl) {
                    List<SObject> afflRecords = buildAffiliations(hcpNameToId, acctNameToId);
                    Database.SaveResult[] afflResults = Database.insert(afflRecords, false);
                    for (Database.SaveResult sr : afflResults) {
                        if (sr.isSuccess()) afflSuccess++;
                    }
                }
            }

            String result = 'Demo data created successfully. '
                + 'Accounts: ' + acctSuccess
                + ', HCPs: ' + hcpSuccess
                + ', NPIs: ' + npiSuccess
                + ', Specialties: ' + specSuccess
                + ', Affiliations: ' + afflSuccess;

            if (!hasHCP) {
                result += ' (HealthcareProvider objects not available in this org)';
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error creating demo data: ' + e.getMessage()
                + ' [' + e.getStackTraceString() + ']'
            );
        }
    }

    @AuraEnabled
    public static String getStatus() {
        try {
            Integer acctCount = [SELECT COUNT() FROM Account WHERE Description LIKE :('%' + DEMO_TAG + '%')];

            String result = 'Demo Accounts: ' + acctCount;

            if (Schema.getGlobalDescribe().containsKey('healthcareprovider')) {
                String soql = 'SELECT COUNT() FROM HealthcareProvider WHERE Description LIKE \'%' + DEMO_TAG + '%\'';
                result += ', HCPs: ' + Database.countQuery(soql);
            }
            if (Schema.getGlobalDescribe().containsKey('healthcareprovidernpi')) {
                String soql = 'SELECT COUNT() FROM HealthcareProviderNpi';
                result += ', NPIs: ' + Database.countQuery(soql);
            }
            if (Schema.getGlobalDescribe().containsKey('healthcareproviderspecialty')) {
                String soql = 'SELECT COUNT() FROM HealthcareProviderSpecialty WHERE Description LIKE \'%' + DEMO_TAG + '%\'';
                result += ', Specialties: ' + Database.countQuery(soql);
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

            // Delete child objects first (reverse order of creation)
            if (Schema.getGlobalDescribe().containsKey('provideraffiliation')) {
                // Affiliations reference HCPs that have our tag
                String soql = 'SELECT Id FROM ProviderAffiliation WHERE HealthcareProviderId IN '
                    + '(SELECT Id FROM HealthcareProvider WHERE Description LIKE \'%' + DEMO_TAG + '%\')';
                List<SObject> recs = Database.query(soql);
                if (!recs.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(recs, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }
            }

            if (Schema.getGlobalDescribe().containsKey('healthcareproviderspecialty')) {
                String soql = 'SELECT Id FROM HealthcareProviderSpecialty WHERE Description LIKE \'%' + DEMO_TAG + '%\'';
                List<SObject> recs = Database.query(soql);
                if (!recs.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(recs, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }
            }

            if (Schema.getGlobalDescribe().containsKey('healthcareprovidernpi')) {
                String soql = 'SELECT Id FROM HealthcareProviderNpi WHERE HealthcareProviderId IN '
                    + '(SELECT Id FROM HealthcareProvider WHERE Description LIKE \'%' + DEMO_TAG + '%\')';
                List<SObject> recs = Database.query(soql);
                if (!recs.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(recs, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }
            }

            if (Schema.getGlobalDescribe().containsKey('healthcareprovider')) {
                String soql = 'SELECT Id FROM HealthcareProvider WHERE Description LIKE \'%' + DEMO_TAG + '%\'';
                List<SObject> recs = Database.query(soql);
                if (!recs.isEmpty()) {
                    Database.DeleteResult[] dr = Database.delete(recs, false);
                    for (Database.DeleteResult r : dr) { if (r.isSuccess()) deleted++; }
                }
            }

            List<Account> accts = [SELECT Id FROM Account WHERE Description LIKE :('%' + DEMO_TAG + '%')];
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
    // Account builders
    // ---------------------------------------------------------------------------

    private static List<Account> buildAccounts() {
        List<Account> accts = new List<Account>();

        // ---- United States ----
        accts.add(makeAccount('Massachusetts General Hospital', '55 Fruit Street', 'Boston', 'MA', '02114', 'US', '+1 (617) 726-2000', 'https://www.massgeneral.org', 'Hospital', 'Premier academic medical center and teaching hospital of Harvard Medical School.'));
        accts.add(makeAccount('Johns Hopkins Hospital', '1800 Orleans Street', 'Baltimore', 'MD', '21287', 'US', '+1 (410) 955-5000', 'https://www.hopkinsmedicine.org', 'Hospital', 'World-renowned research and teaching hospital.'));
        accts.add(makeAccount('Cleveland Clinic', '9500 Euclid Avenue', 'Cleveland', 'OH', '44195', 'US', '+1 (216) 444-2200', 'https://www.clevelandclinic.org', 'Hospital', 'Nonprofit multispecialty academic medical center.'));
        accts.add(makeAccount('Mayo Clinic', '200 First Street SW', 'Rochester', 'MN', '55905', 'US', '+1 (507) 284-2511', 'https://www.mayoclinic.org', 'Hospital', 'Academic medical center focused on integrated health care, education, and research.'));
        accts.add(makeAccount('Memorial Sloan Kettering Cancer Center', '1275 York Avenue', 'New York', 'NY', '10065', 'US', '+1 (212) 639-2000', 'https://www.mskcc.org', 'Hospital', 'World-leading cancer treatment and research center.'));
        accts.add(makeAccount('MD Anderson Cancer Center', '1515 Holcombe Boulevard', 'Houston', 'TX', '77030', 'US', '+1 (713) 792-2121', 'https://www.mdanderson.org', 'Hospital', 'Leading cancer center ranked #1 in cancer care.'));
        accts.add(makeAccount('Kaiser Permanente', '1 Kaiser Plaza', 'Oakland', 'CA', '94612', 'US', '+1 (510) 271-5910', 'https://www.kaiserpermanente.org', 'Insurance', 'Largest managed care organization in the United States.'));
        accts.add(makeAccount('UnitedHealth Group', '9900 Bren Road East', 'Minnetonka', 'MN', '55343', 'US', '+1 (952) 936-1300', 'https://www.unitedhealthgroup.com', 'Insurance', 'Diversified health care company and largest health insurer in the US.'));
        accts.add(makeAccount('CVS Health', '1 CVS Drive', 'Woonsocket', 'RI', '02895', 'US', '+1 (401) 765-1500', 'https://www.cvshealth.com', 'Pharmacy', 'Largest pharmacy health care provider in the United States.'));
        accts.add(makeAccount('Midtown Oncology Associates', '450 East 63rd Street', 'New York', 'NY', '10065', 'US', '+1 (212) 305-5098', 'https://www.midtownoncology.com', 'Clinic', 'Specialized oncology clinic offering comprehensive cancer care.'));

        // ---- United Kingdom ----
        accts.add(makeAccount('Royal London Hospital', 'Whitechapel Road', 'London', 'England', 'E1 1FR', 'GB', '+44 20 7377 7000', 'https://www.bartshealth.nhs.uk', 'Hospital', 'Major teaching hospital and part of Barts Health NHS Trust.'));
        accts.add(makeAccount('St Thomas\' Hospital', 'Westminster Bridge Road', 'London', 'England', 'SE1 7EH', 'GB', '+44 20 7188 7188', 'https://www.guysandstthomas.nhs.uk', 'Hospital', 'Leading NHS foundation trust teaching hospital.'));
        accts.add(makeAccount('Addenbrooke\'s Hospital', 'Hills Road', 'Cambridge', 'England', 'CB2 0QQ', 'GB', '+44 1223 245151', 'https://www.cuh.nhs.uk', 'Hospital', 'Major university teaching hospital affiliated with Cambridge University.'));
        accts.add(makeAccount('NHS England', 'Skipton House, 80 London Road', 'London', 'England', 'SE1 6LH', 'GB', '+44 300 311 2233', 'https://www.england.nhs.uk', 'Insurance', 'National health commissioning body for England.'));
        accts.add(makeAccount('BUPA', '1 Angel Court', 'London', 'England', 'EC2R 7HJ', 'GB', '+44 345 600 8822', 'https://www.bupa.co.uk', 'Insurance', 'International healthcare group providing private medical insurance.'));
        accts.add(makeAccount('Boots UK', 'Thane Road', 'Nottingham', 'England', 'NG2 3AA', 'GB', '+44 115 950 6111', 'https://www.boots.com', 'Pharmacy', 'Largest pharmacy chain in the United Kingdom.'));

        // ---- France ----
        accts.add(makeAccount('Hôpital Pitié-Salpêtrière', '47-83 Boulevard de l\'Hôpital', 'Paris', 'Île-de-France', '75013', 'FR', '+33 1 42 16 00 00', 'https://www.aphp.fr/pitie-salpetriere', 'Hospital', 'Largest teaching hospital in France, part of AP-HP.'));
        accts.add(makeAccount('Hôpital Européen Georges-Pompidou', '20 Rue Leblanc', 'Paris', 'Île-de-France', '75015', 'FR', '+33 1 56 09 20 00', 'https://www.aphp.fr/hegp', 'Hospital', 'Modern university hospital specializing in cardiovascular care.'));
        accts.add(makeAccount('Centre Hospitalier Universitaire de Lyon', '3 Quai des Célestins', 'Lyon', 'Auvergne-Rhône-Alpes', '69002', 'FR', '+33 4 72 11 69 11', 'https://www.chu-lyon.fr', 'Hospital', 'Major university hospital center in Lyon.'));
        accts.add(makeAccount('Institut Gustave Roussy', '114 Rue Édouard-Vaillant', 'Villejuif', 'Île-de-France', '94805', 'FR', '+33 1 42 11 42 11', 'https://www.gustaveroussy.fr', 'Hospital', 'Leading European cancer research and treatment center.'));
        accts.add(makeAccount('Assurance Maladie (CNAM)', '50 Avenue du Professeur André Lemierre', 'Paris', 'Île-de-France', '75020', 'FR', '+33 1 72 60 10 00', 'https://www.ameli.fr', 'Insurance', 'French national health insurance fund.'));
        accts.add(makeAccount('Pharmacie du Forum des Halles', '101 Rue Berger', 'Paris', 'Île-de-France', '75001', 'FR', '+33 1 42 36 00 00', 'https://www.pharmacieforum.fr', 'Pharmacy', 'Large central Paris pharmacy.'));

        // ---- Germany ----
        accts.add(makeAccount('Charité - Universitätsmedizin Berlin', 'Charitéplatz 1', 'Berlin', 'Berlin', '10117', 'DE', '+49 30 450 50', 'https://www.charite.de', 'Hospital', 'Largest university hospital in Europe.'));
        accts.add(makeAccount('Universitätsklinikum Heidelberg', 'Im Neuenheimer Feld 672', 'Heidelberg', 'Baden-Württemberg', '69120', 'DE', '+49 6221 56 0', 'https://www.klinikum.uni-heidelberg.de', 'Hospital', 'Leading German university hospital with extensive research programs.'));
        accts.add(makeAccount('Universitätsklinikum Hamburg-Eppendorf', 'Martinistraße 52', 'Hamburg', 'Hamburg', '20246', 'DE', '+49 40 7410 0', 'https://www.uke.de', 'Hospital', 'Renowned university medical center in Hamburg.'));
        accts.add(makeAccount('Munich Heart Centre', 'Lazarettstraße 36', 'Munich', 'Bavaria', '80636', 'DE', '+49 89 1218 0', 'https://www.dhm.mhn.de', 'Clinic', 'Specialized cardiac center and clinic in Munich.'));
        accts.add(makeAccount('AOK - Die Gesundheitskasse', 'Rosenthaler Straße 31', 'Berlin', 'Berlin', '10178', 'DE', '+49 800 265 0800', 'https://www.aok.de', 'Insurance', 'Largest statutory health insurance provider in Germany.'));
        accts.add(makeAccount('DocMorris', 'Carl-Zeiss-Ring 4', 'Heerlen', 'North Rhine-Westphalia', '52078', 'DE', '+49 800 444 0200', 'https://www.docmorris.de', 'Pharmacy', 'Largest online pharmacy in Germany.'));

        // ---- Italy ----
        accts.add(makeAccount('Policlinico Agostino Gemelli', 'Largo Agostino Gemelli 8', 'Rome', 'Lazio', '00168', 'IT', '+39 06 3015 1', 'https://www.policlinicogemelli.it', 'Hospital', 'Leading Italian teaching hospital associated with Università Cattolica.'));
        accts.add(makeAccount('Ospedale San Raffaele', 'Via Olgettina 60', 'Milan', 'Lombardy', '20132', 'IT', '+39 02 2643 2643', 'https://www.hsr.it', 'Hospital', 'Renowned research hospital and university in Milan.'));
        accts.add(makeAccount('Istituto Europeo di Oncologia', 'Via Ripamonti 435', 'Milan', 'Lombardy', '20141', 'IT', '+39 02 5748 9001', 'https://www.ieo.it', 'Hospital', 'Comprehensive cancer center founded by Umberto Veronesi.'));
        accts.add(makeAccount('Azienda Ospedaliera di Padova', 'Via Giustiniani 2', 'Padua', 'Veneto', '35128', 'IT', '+39 049 821 1111', 'https://www.aopd.veneto.it', 'Hospital', 'Major university hospital in the Veneto region.'));
        accts.add(makeAccount('ASL Roma 1', 'Borgo Santo Spirito 3', 'Rome', 'Lazio', '00193', 'IT', '+39 06 6835 1', 'https://www.aslroma1.it', 'Insurance', 'Local health authority managing public health services in Rome.'));
        accts.add(makeAccount('Farmacia del Corso', 'Corso Buenos Aires 4', 'Milan', 'Lombardy', '20124', 'IT', '+39 02 2951 4380', 'https://www.farmaciadelcorso.it', 'Pharmacy', 'Historic pharmacy in central Milan.'));

        // ---- Spain ----
        accts.add(makeAccount('Hospital Clínic de Barcelona', 'Carrer de Villarroel 170', 'Barcelona', 'Catalonia', '08036', 'ES', '+34 93 227 54 00', 'https://www.clinicbarcelona.org', 'Hospital', 'Top-ranked Spanish university hospital and research center.'));
        accts.add(makeAccount('Hospital Universitario La Paz', 'Paseo de la Castellana 261', 'Madrid', 'Community of Madrid', '28046', 'ES', '+34 91 727 70 00', 'https://www.comunidad.madrid/hospital/lapaz', 'Hospital', 'Largest public hospital in Spain.'));
        accts.add(makeAccount('Hospital Universitario Vall d\'Hebron', 'Passeig de la Vall d\'Hebron 119-129', 'Barcelona', 'Catalonia', '08035', 'ES', '+34 93 274 60 00', 'https://www.vallhebron.com', 'Hospital', 'Major university hospital and research campus in Barcelona.'));
        accts.add(makeAccount('Centro Médico Teknon', 'Carrer de Vilana 12', 'Barcelona', 'Catalonia', '08022', 'ES', '+34 93 290 62 00', 'https://www.teknon.es', 'Clinic', 'Private medical center with comprehensive specialty services.'));
        accts.add(makeAccount('Sanitas', 'Ribera del Loira 52', 'Madrid', 'Community of Madrid', '28042', 'ES', '+34 91 585 29 00', 'https://www.sanitas.es', 'Insurance', 'Leading private health insurance provider in Spain.'));
        accts.add(makeAccount('Farmacia Ortopedia Gaztambide', 'Calle de Gaztambide 55', 'Madrid', 'Community of Madrid', '28015', 'ES', '+34 91 549 42 60', 'https://www.farmaciagaztambide.com', 'Pharmacy', 'Well-known pharmacy in central Madrid.'));

        return accts;
    }

    private static Account makeAccount(String name, String street, String city, String state, String postalCode, String country, String phone, String website, String acctType, String description) {
        Account a = new Account();
        a.Name = name;
        a.BillingStreet = street;
        a.BillingCity = city;
        a.BillingState = state;
        a.BillingPostalCode = postalCode;
        a.BillingCountry = country;
        a.Phone = phone;
        a.Website = website;
        a.Industry = 'Healthcare';
        a.Type = acctType;
        a.Description = description + ' [' + DEMO_TAG + ']';
        return a;
    }

    // ---------------------------------------------------------------------------
    // HealthcareProvider builders
    // ---------------------------------------------------------------------------

    private static List<SObject> buildHealthcareProviders(Map<String, Id> acctNameToId) {
        List<SObject> providers = new List<SObject>();
        Schema.SObjectType hcpType = Schema.getGlobalDescribe().get('healthcareprovider');

        // US Providers
        providers.add(makeHCP(hcpType, 'Dr. Sarah Mitchell', 'Oncology', acctNameToId.get('Massachusetts General Hospital')));
        providers.add(makeHCP(hcpType, 'Dr. James Patterson', 'Cardiology', acctNameToId.get('Johns Hopkins Hospital')));
        providers.add(makeHCP(hcpType, 'Dr. Emily Chen', 'Neurology', acctNameToId.get('Cleveland Clinic')));
        providers.add(makeHCP(hcpType, 'Dr. Michael Rodriguez', 'Internal Medicine', acctNameToId.get('Mayo Clinic')));
        providers.add(makeHCP(hcpType, 'Dr. Jennifer Goldstein', 'Oncology', acctNameToId.get('Memorial Sloan Kettering Cancer Center')));
        providers.add(makeHCP(hcpType, 'Dr. David Kumar', 'Oncology', acctNameToId.get('MD Anderson Cancer Center')));
        providers.add(makeHCP(hcpType, 'Dr. Robert Washington', 'Gastroenterology', acctNameToId.get('Midtown Oncology Associates')));

        // UK Providers
        providers.add(makeHCP(hcpType, 'Dr. William Hartley', 'Cardiology', acctNameToId.get('Royal London Hospital')));
        providers.add(makeHCP(hcpType, 'Dr. Eleanor Blackwood', 'Pulmonology', acctNameToId.get('St Thomas\' Hospital')));
        providers.add(makeHCP(hcpType, 'Dr. Oliver Pemberton', 'Endocrinology', acctNameToId.get('Addenbrooke\'s Hospital')));
        providers.add(makeHCP(hcpType, 'Dr. Charlotte Ainsworth', 'Dermatology', acctNameToId.get('Royal London Hospital')));
        providers.add(makeHCP(hcpType, 'Dr. George Whitfield', 'Orthopedics', acctNameToId.get('St Thomas\' Hospital')));

        // France Providers
        providers.add(makeHCP(hcpType, 'Dr. Pierre Lefèvre', 'Neurology', acctNameToId.get('Hôpital Pitié-Salpêtrière')));
        providers.add(makeHCP(hcpType, 'Dr. Marie-Claire Dubois', 'Cardiology', acctNameToId.get('Hôpital Européen Georges-Pompidou')));
        providers.add(makeHCP(hcpType, 'Dr. François Moreau', 'Internal Medicine', acctNameToId.get('Centre Hospitalier Universitaire de Lyon')));
        providers.add(makeHCP(hcpType, 'Dr. Camille Rousseau', 'Oncology', acctNameToId.get('Institut Gustave Roussy')));
        providers.add(makeHCP(hcpType, 'Dr. Jean-Luc Bernard', 'Immunology', acctNameToId.get('Hôpital Pitié-Salpêtrière')));

        // Germany Providers
        providers.add(makeHCP(hcpType, 'Dr. Klaus Müller', 'Oncology', acctNameToId.get('Charité - Universitätsmedizin Berlin')));
        providers.add(makeHCP(hcpType, 'Dr. Anna Schneider', 'Neurology', acctNameToId.get('Universitätsklinikum Heidelberg')));
        providers.add(makeHCP(hcpType, 'Dr. Stefan Weber', 'Cardiology', acctNameToId.get('Universitätsklinikum Hamburg-Eppendorf')));
        providers.add(makeHCP(hcpType, 'Dr. Katrin Fischer', 'Pediatrics', acctNameToId.get('Charité - Universitätsmedizin Berlin')));
        providers.add(makeHCP(hcpType, 'Dr. Hans-Peter Braun', 'Cardiology', acctNameToId.get('Munich Heart Centre')));

        // Italy Providers
        providers.add(makeHCP(hcpType, 'Dr. Marco Rossi', 'Gastroenterology', acctNameToId.get('Policlinico Agostino Gemelli')));
        providers.add(makeHCP(hcpType, 'Dr. Giulia Bianchi', 'Oncology', acctNameToId.get('Istituto Europeo di Oncologia')));
        providers.add(makeHCP(hcpType, 'Dr. Alessandro Conti', 'Cardiology', acctNameToId.get('Ospedale San Raffaele')));
        providers.add(makeHCP(hcpType, 'Dr. Francesca Romano', 'Dermatology', acctNameToId.get('Azienda Ospedaliera di Padova')));
        providers.add(makeHCP(hcpType, 'Dr. Luca Ferretti', 'Pulmonology', acctNameToId.get('Ospedale San Raffaele')));

        // Spain Providers
        providers.add(makeHCP(hcpType, 'Dr. Carlos García López', 'Immunology', acctNameToId.get('Hospital Clínic de Barcelona')));
        providers.add(makeHCP(hcpType, 'Dr. María Fernández Ruiz', 'Oncology', acctNameToId.get('Hospital Universitario La Paz')));
        providers.add(makeHCP(hcpType, 'Dr. Alejandro Martínez Soto', 'Neurology', acctNameToId.get('Hospital Universitario Vall d\'Hebron')));
        providers.add(makeHCP(hcpType, 'Dr. Isabel Navarro Díaz', 'Endocrinology', acctNameToId.get('Centro Médico Teknon')));
        providers.add(makeHCP(hcpType, 'Dr. Pablo Herrera Molina', 'Family Medicine', acctNameToId.get('Hospital Clínic de Barcelona')));

        return providers;
    }

    private static SObject makeHCP(Schema.SObjectType hcpType, String name, String specialty, Id accountId) {
        SObject hcp = hcpType.newSObject();
        hcp.put('Name', name);
        hcp.put('Description', specialty + ' specialist. [' + DEMO_TAG + ']');
        if (accountId != null) {
            hcp.put('AccountId', accountId);
        }
        return hcp;
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
            'Dr. Klaus Müller' => '4567890123',
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
                npi.put('Npi', npiMap.get(provName));
                npi.put('HealthcareProviderId', hcpId);
                npi.put('EffectiveDate', Date.newInstance(2020, 1, 1));
                npi.put('ExpirationDate', Date.newInstance(2030, 12, 31));
                npis.add(npi);
            }
        }

        return npis;
    }

    // ---------------------------------------------------------------------------
    // Specialty builders
    // ---------------------------------------------------------------------------

    private static List<SObject> buildSpecialtyRecords(Map<String, Id> hcpNameToId) {
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
            if (hcpId != null) {
                SObject spec = specType.newSObject();
                spec.put('Name', providerSpecialties.get(provName));
                spec.put('HealthcareProviderId', hcpId);
                spec.put('SpecialtyType', providerSpecialties.get(provName));
                spec.put('IsActive', true);
                spec.put('Description', provName + ' - ' + providerSpecialties.get(provName) + ' [' + DEMO_TAG + ']');
                specs.add(spec);
            }
        }

        return specs;
    }

    // ---------------------------------------------------------------------------
    // Affiliation builders
    // ---------------------------------------------------------------------------

    private static List<SObject> buildAffiliations(Map<String, Id> hcpNameToId, Map<String, Id> acctNameToId) {
        List<SObject> affls = new List<SObject>();
        Schema.SObjectType afflType = Schema.getGlobalDescribe().get('provideraffiliation');

        // Map provider -> primary account, practice location name
        List<List<String>> affiliationData = new List<List<String>>{
            new List<String>{'Dr. Sarah Mitchell', 'Massachusetts General Hospital', 'MGH Cancer Center'},
            new List<String>{'Dr. James Patterson', 'Johns Hopkins Hospital', 'Johns Hopkins Heart Institute'},
            new List<String>{'Dr. Emily Chen', 'Cleveland Clinic', 'Cleveland Clinic Neurology Institute'},
            new List<String>{'Dr. Michael Rodriguez', 'Mayo Clinic', 'Mayo Clinic Internal Medicine'},
            new List<String>{'Dr. Jennifer Goldstein', 'Memorial Sloan Kettering Cancer Center', 'MSK Breast Cancer Center'},
            new List<String>{'Dr. David Kumar', 'MD Anderson Cancer Center', 'MD Anderson Thoracic Center'},
            new List<String>{'Dr. Robert Washington', 'Midtown Oncology Associates', 'Midtown GI Suite'},
            new List<String>{'Dr. William Hartley', 'Royal London Hospital', 'Barts Heart Centre'},
            new List<String>{'Dr. Eleanor Blackwood', 'St Thomas\' Hospital', 'St Thomas\' Respiratory Unit'},
            new List<String>{'Dr. Oliver Pemberton', 'Addenbrooke\'s Hospital', 'Addenbrooke\'s Endocrine Centre'},
            new List<String>{'Dr. Charlotte Ainsworth', 'Royal London Hospital', 'Royal London Dermatology Dept'},
            new List<String>{'Dr. George Whitfield', 'St Thomas\' Hospital', 'St Thomas\' Orthopaedic Unit'},
            new List<String>{'Dr. Pierre Lefèvre', 'Hôpital Pitié-Salpêtrière', 'Service de Neurologie'},
            new List<String>{'Dr. Marie-Claire Dubois', 'Hôpital Européen Georges-Pompidou', 'Service de Cardiologie HEGP'},
            new List<String>{'Dr. François Moreau', 'Centre Hospitalier Universitaire de Lyon', 'CHU Lyon Médecine Interne'},
            new List<String>{'Dr. Camille Rousseau', 'Institut Gustave Roussy', 'IGR Département d\'Oncologie'},
            new List<String>{'Dr. Jean-Luc Bernard', 'Hôpital Pitié-Salpêtrière', 'Service d\'Immunologie Pitié'},
            new List<String>{'Dr. Klaus Müller', 'Charité - Universitätsmedizin Berlin', 'Charité Comprehensive Cancer Center'},
            new List<String>{'Dr. Anna Schneider', 'Universitätsklinikum Heidelberg', 'Heidelberg Neurologie Klinik'},
            new List<String>{'Dr. Stefan Weber', 'Universitätsklinikum Hamburg-Eppendorf', 'UKE Herz- und Gefäßzentrum'},
            new List<String>{'Dr. Katrin Fischer', 'Charité - Universitätsmedizin Berlin', 'Charité Kinder- und Jugendmedizin'},
            new List<String>{'Dr. Hans-Peter Braun', 'Munich Heart Centre', 'Deutsches Herzzentrum München'},
            new List<String>{'Dr. Marco Rossi', 'Policlinico Agostino Gemelli', 'Gemelli Gastroenterologia'},
            new List<String>{'Dr. Giulia Bianchi', 'Istituto Europeo di Oncologia', 'IEO Divisione Oncologia'},
            new List<String>{'Dr. Alessandro Conti', 'Ospedale San Raffaele', 'San Raffaele Centro Cardiologico'},
            new List<String>{'Dr. Francesca Romano', 'Azienda Ospedaliera di Padova', 'AO Padova Dermatologia'},
            new List<String>{'Dr. Luca Ferretti', 'Ospedale San Raffaele', 'San Raffaele Pneumologia'},
            new List<String>{'Dr. Carlos García López', 'Hospital Clínic de Barcelona', 'Clínic Servicio de Inmunología'},
            new List<String>{'Dr. María Fernández Ruiz', 'Hospital Universitario La Paz', 'La Paz Servicio de Oncología'},
            new List<String>{'Dr. Alejandro Martínez Soto', 'Hospital Universitario Vall d\'Hebron', 'Vall d\'Hebron Neurología'},
            new List<String>{'Dr. Isabel Navarro Díaz', 'Centro Médico Teknon', 'Teknon Endocrinología'},
            new List<String>{'Dr. Pablo Herrera Molina', 'Hospital Clínic de Barcelona', 'Clínic Medicina Familiar'}
        };

        for (List<String> row : affiliationData) {
            Id hcpId = hcpNameToId.get(row[0]);
            Id acctId = acctNameToId.get(row[1]);
            if (hcpId != null && acctId != null) {
                SObject affl = afflType.newSObject();
                affl.put('HealthcareProviderId', hcpId);
                affl.put('AccountId', acctId);
                affl.put('PracticeLocationName', row[2]);
                affl.put('IsPrimaryAffiliation', true);
                affls.add(affl);
            }
        }

        return affls;
    }
}