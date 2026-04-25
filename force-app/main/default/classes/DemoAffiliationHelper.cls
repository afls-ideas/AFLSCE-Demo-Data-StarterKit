/**
 * Separate class for ProviderAffiliation operations.
 * Schema.getGlobalDescribe() does not return 'provideraffiliation' when called
 * from DemoAccountProviderController (public with sharing). This standalone
 * class resolves that visibility issue.
 */
public without sharing class DemoAffiliationHelper {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';

    public static Integer createAffiliations(Map<String, Id> doctorNameToId, Map<String, Id> orgNameToId) {
        Schema.SObjectType afflType = Schema.getGlobalDescribe().get('provideraffiliation');
        if (afflType == null) return 0;

        List<List<String>> affiliationData = new List<List<String>>{
            // US
            new List<String>{'Sarah Mitchell', 'Massachusetts General Hospital'},
            new List<String>{'James Patterson', 'Johns Hopkins Hospital'},
            new List<String>{'Emily Chen', 'Cleveland Clinic'},
            new List<String>{'Michael Rodriguez', 'Mayo Clinic'},
            new List<String>{'Jennifer Goldstein', 'Memorial Sloan Kettering Cancer Center'},
            new List<String>{'David Kumar', 'MD Anderson Cancer Center'},
            new List<String>{'Robert Washington', 'Midtown Oncology Associates'},
            // Additional US affiliations
            new List<String>{'Thomas Brennan', 'Brigham and Women\'s Hospital'},
            new List<String>{'Margaret Sullivan', 'Dana-Farber Cancer Institute'},
            new List<String>{'Christopher O\'Malley', 'Boston Children\'s Hospital'},
            new List<String>{'Priya Patel', 'Dana-Farber Cancer Institute'},
            new List<String>{'Samuel Greenberg', 'NYU Langone Health'},
            new List<String>{'Diana Chow', 'NewYork-Presbyterian Hospital'},
            new List<String>{'Marcus Thompson', 'Mount Sinai Hospital'},
            new List<String>{'Elizabeth Harper', 'Hospital of the University of Pennsylvania'},
            new List<String>{'Daniel Rivera', 'Children\'s Hospital of Philadelphia'},
            new List<String>{'Karen Whitfield', 'Thomas Jefferson University Hospital'},
            new List<String>{'Jason Kim', 'Hospital of the University of Pennsylvania'},
            new List<String>{'Andrea Simmons', 'Rittenhouse Oncology Associates'},
            new List<String>{'William Foster', 'MedStar Georgetown University Hospital'},
            new List<String>{'Catherine Morales', 'George Washington University Hospital'},
            new List<String>{'Richard Allen', 'Walter Reed National Military Medical Center'},
            new List<String>{'Sophia Bennett', 'Johns Hopkins Hospital'},
            new List<String>{'Gregory Park', 'MedStar Georgetown University Hospital'},
            new List<String>{'Michelle Banks', 'Emory University Hospital'},
            new List<String>{'Terrence Williams', 'Grady Memorial Hospital'},
            new List<String>{'Nicole Davis', 'Piedmont Atlanta Hospital'},
            new List<String>{'Kevin Jackson', 'Emory University Hospital'},
            new List<String>{'Amanda Stewart', 'Atlanta Cancer Care'},
            new List<String>{'Carlos Mendez', 'Jackson Memorial Hospital'},
            new List<String>{'Maria Santos', 'Baptist Health South Florida'},
            new List<String>{'Roberto Cruz', 'University of Miami Hospital'},
            new List<String>{'Ana Delgado', 'Miami Cancer Institute'},
            new List<String>{'Luis Fernandez', 'Jackson Memorial Hospital'},
            new List<String>{'Patricia Reynolds', 'Atrium Health Carolinas Medical Center'},
            new List<String>{'Brian Coleman', 'Novant Health Presbyterian'},
            new List<String>{'Lauren Mitchell', 'Levine Cancer Institute'},
            new List<String>{'Steven Harris', 'Atrium Health Carolinas Medical Center'},
            new List<String>{'Heather Ross', 'Charlotte Gastroenterology Associates'},
            new List<String>{'Jonathan Clark', 'Vanderbilt University Medical Center'},
            new List<String>{'Sharon Wright', 'St. Jude Children\'s Research Hospital'},
            new List<String>{'Timothy Baker', 'Vanderbilt University Medical Center'},
            new List<String>{'Rebecca Moore', 'Sarah Cannon Cancer Institute'},
            new List<String>{'Eric Nelson', 'MD Anderson Cancer Center'},
            new List<String>{'Christine Walsh', 'Northwestern Memorial Hospital'},
            new List<String>{'Raymond Lee', 'Rush University Medical Center'},
            new List<String>{'Susan Chen', 'University of Chicago Medicine'},
            new List<String>{'Patrick O\'Brien', 'Robert H. Lurie Cancer Center'},
            new List<String>{'Angela Martinez', 'Cleveland Clinic'},
            new List<String>{'Mark Henderson', 'Henry Ford Hospital'},
            new List<String>{'Sandra Cooper', 'Beaumont Hospital Royal Oak'},
            new List<String>{'Jeffrey Phillips', 'Michigan Medicine'},
            new List<String>{'Laura Taylor', 'Karmanos Cancer Institute'},
            new List<String>{'Robert Campbell', 'Henry Ford Hospital'},
            new List<String>{'Amy Anderson', 'Abbott Northwestern Hospital'},
            new List<String>{'Brian Larson', 'University of Minnesota Medical Center'},
            new List<String>{'Jennifer Olson', 'Masonic Cancer Center'},
            new List<String>{'David Morgan', 'University of Kansas Medical Center'},
            new List<String>{'Nancy Wilson', 'Saint Luke\'s Hospital'},
            new List<String>{'Michael Evans', 'Children\'s Mercy Kansas City'},
            new List<String>{'Stephanie Hall', 'University of Kansas Medical Center'},
            new List<String>{'Ryan Peterson', 'Kansas City Cancer Center'},
            new List<String>{'Jessica Stone', 'Cedars-Sinai Medical Center'},
            new List<String>{'Anthony Nguyen', 'UCLA Medical Center'},
            new List<String>{'Katherine Adams', 'City of Hope'},
            new List<String>{'Benjamin Ramirez', 'Cedars-Sinai Medical Center'},
            new List<String>{'Victoria Wu', 'LA Cancer Associates'},
            new List<String>{'Matthew Wong', 'UCSF Medical Center'},
            new List<String>{'Natalie Brooks', 'Stanford Health Care'},
            new List<String>{'Peter Chang', 'Sutter Health CPMC'},
            new List<String>{'Diane Yamamoto', 'Pacific Oncology Associates'},
            new List<String>{'James Murphy', 'UW Medical Center'},
            new List<String>{'Emily Johnson', 'Swedish Medical Center'},
            new List<String>{'Alexander Scott', 'Seattle Children\'s Hospital'},
            new List<String>{'Rachel Green', 'Fred Hutchinson Cancer Center'},
            new List<String>{'Kevin Lewis', 'UW Medical Center'},
            new List<String>{'Sarah Miller', 'UCHealth University of Colorado Hospital'},
            new List<String>{'Christopher Taylor', 'Denver Health Medical Center'},
            new List<String>{'Jennifer Anderson', 'National Jewish Health'},
            new List<String>{'Daniel Martinez', 'Rocky Mountain Cancer Centers'},
            new List<String>{'Michelle Roberts', 'UCHealth University of Colorado Hospital'},
            // UK
            new List<String>{'William Hartley', 'Royal London Hospital'},
            new List<String>{'Eleanor Blackwood', 'St Thomas\' Hospital'},
            new List<String>{'Oliver Pemberton', 'Addenbrooke\'s Hospital'},
            new List<String>{'Charlotte Ainsworth', 'Royal London Hospital'},
            new List<String>{'George Whitfield', 'St Thomas\' Hospital'},
            // France
            new List<String>{'Pierre Lefèvre', 'Hôpital Pitié-Salpêtrière'},
            new List<String>{'Marie-Claire Dubois', 'Hôpital Européen Georges-Pompidou'},
            new List<String>{'François Moreau', 'Centre Hospitalier Universitaire de Lyon'},
            new List<String>{'Camille Rousseau', 'Institut Gustave Roussy'},
            new List<String>{'Jean-Luc Bernard', 'Hôpital Pitié-Salpêtrière'},
            // Germany
            new List<String>{'Klaus Müller', 'Charité - Universitätsmedizin Berlin'},
            new List<String>{'Anna Schneider', 'Universitätsklinikum Heidelberg'},
            new List<String>{'Stefan Weber', 'Universitätsklinikum Hamburg-Eppendorf'},
            new List<String>{'Katrin Fischer', 'Charité - Universitätsmedizin Berlin'},
            new List<String>{'Hans-Peter Braun', 'Munich Heart Centre'},
            // Italy
            new List<String>{'Marco Rossi', 'Policlinico Agostino Gemelli'},
            new List<String>{'Giulia Bianchi', 'Istituto Europeo di Oncologia'},
            new List<String>{'Alessandro Conti', 'Ospedale San Raffaele'},
            new List<String>{'Francesca Romano', 'Azienda Ospedaliera di Padova'},
            new List<String>{'Luca Ferretti', 'Ospedale San Raffaele'},
            // Spain
            new List<String>{'Carlos García López', 'Hospital Clínic de Barcelona'},
            new List<String>{'María Fernández Ruiz', 'Hospital Universitario La Paz'},
            new List<String>{'Alejandro Martínez Soto', 'Hospital Universitario Vall d\'Hebron'},
            new List<String>{'Isabel Navarro Díaz', 'Centro Médico Teknon'},
            new List<String>{'Pablo Herrera Molina', 'Hospital Clínic de Barcelona'}
        };

        Map<String, Schema.SObjectField> afflFields = afflType.getDescribe().fields.getMap();
        List<SObject> affls = new List<SObject>();
        for (List<String> row : affiliationData) {
            Id doctorAcctId = doctorNameToId.get(row[0]);
            Id orgAcctId = orgNameToId.get(row[1]);
            if (doctorAcctId != null && orgAcctId != null) {
                SObject affl = afflType.newSObject();
                affl.put('AccountId', doctorAcctId);
                affl.put('RelatedAccountId', orgAcctId);
                if (afflFields.containsKey('role')) affl.put('Role', 'Affiliated Practice-Doctor-AAR');
                if (afflFields.containsKey('isprimary')) affl.put('IsPrimary', true);
                if (afflFields.containsKey('isactive')) affl.put('IsActive', true);
                if (afflFields.containsKey('isinstitutiondoctoraffl')) affl.put('IsInstitutionDoctorAffl', true);
                if (afflFields.containsKey('isautogenerated')) affl.put('IsAutoGenerated', false);
                if (afflFields.containsKey('sourcesystemname')) affl.put('SourceSystemName', DEMO_TAG);
                affls.add(affl);
            }
        }

        Integer success = 0;
        if (!affls.isEmpty()) {
            Database.SaveResult[] results = Database.insert(affls, false);
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) success++;
            }
        }
        return success;
    }

    public static Integer deleteAffiliations() {
        Integer deleted = 0;
        String soql = 'SELECT Id FROM ProviderAffiliation WHERE SourceSystemName = \'' + String.escapeSingleQuotes(DEMO_TAG) + '\'';
        List<SObject> recs = Database.query(soql);
        if (!recs.isEmpty()) {
            Database.DeleteResult[] dr = Database.delete(recs, false);
            for (Database.DeleteResult r : dr) {
                if (r.isSuccess()) deleted++;
            }
        }
        return deleted;
    }

    public static Integer countAffiliations() {
        String soql = 'SELECT COUNT() FROM ProviderAffiliation WHERE SourceSystemName = \'' + String.escapeSingleQuotes(DEMO_TAG) + '\'';
        return Database.countQuery(soql);
    }
}
