public without sharing class DemoMedicalInsightController {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';
    private static final String TAG_PREFIX = '[AFLSCE-Demo] ';

    private static final String[] BRAND_NAMES = new String[]{ 'Immunexis', 'Immunonco' };

    private static final Map<String, String> COUNTRY_NAMES = new Map<String, String>{
        'US' => 'United States', 'GB' => 'United Kingdom', 'FR' => 'France',
        'DE' => 'Germany', 'IT' => 'Italy', 'ES' => 'Spain',
        'JP' => 'Japan', 'KR' => 'South Korea', 'BR' => 'Brazil',
        'MX' => 'Mexico', 'AR' => 'Argentina'
    };

    private static final List<Map<String, String>> IMMUNEXIS_INSIGHTS = new List<Map<String, String>>{
        new Map<String, String>{
            'Name' => 'Zelanumab ACR50 response impresses rheumatologist',
            'Content' => 'Dr noted that the 68% ACR50 at Week 24 from SHIELD-RA is significantly higher than what they see with current IL-17A monotherapy. Asked for head-to-head data vs secukinumab. Wants to present at next P&T committee meeting.'
        },
        new Map<String, String>{
            'Name' => 'HCP concerned about infection risk in elderly RA patients',
            'Content' => 'Physician expressed hesitation about biologic use in patients over 70 with recurrent UTIs. Reassured by 1.8/100 PY serious infection rate and no mandatory lab monitoring. Requested the SHIELD-RA subgroup analysis for elderly population.'
        },
        new Map<String, String>{
            'Name' => 'Dual IL-23/IL-17A blockade mechanism resonates with immunologist',
            'Content' => 'Dr was particularly interested in the dual-pathway approach. Said most of their refractory PsA patients have failed sequential monotherapy and the bispecific mechanism addressing upstream and downstream inflammation simultaneously is a compelling differentiator.'
        },
        new Map<String, String>{
            'Name' => 'Patient switching from adalimumab reports morning stiffness improvement',
            'Content' => 'HCP shared that a patient who switched from adalimumab to zelanumab reported near-complete resolution of morning stiffness within 6 weeks. Cited PRISM Registry data showing 74% reported meaningful daily activity improvement at 12 months.'
        },
        new Map<String, String>{
            'Name' => 'Prefilled pen convenience driving treatment adherence',
            'Content' => 'Nurse practitioner reported that patients strongly prefer the room-temperature stable prefilled pen. The Q4W dosing vs Q2W for competitor products is reducing injection fatigue. Two patients who previously missed doses are now fully adherent.'
        },
        new Map<String, String>{
            'Name' => 'Formulary committee requesting real-world evidence',
            'Content' => 'Hospital pharmacy director indicated P&T committee wants 12-month real-world data beyond the Phase 3 trial before considering formulary addition. Requested PRISM Registry outcomes report and cost-effectiveness analysis vs current JAK inhibitor pathway.'
        },
        new Map<String, String>{
            'Name' => 'Rheumatologist identifies early radiographic progression candidates',
            'Content' => 'During chart review, physician flagged 4 patients with moderate RA showing early radiographic progression despite methotrexate. Agreed these are ideal zelanumab candidates per the csDMARD inadequate response positioning. Will discuss at next multidisciplinary meeting.'
        },
        new Map<String, String>{
            'Name' => 'KOL interested in speaking program participation',
            'Content' => 'Department head expressed interest in joining the peer-to-peer speaker program after reviewing the dual IL-23/IL-17A mechanism data. Has published on biologic sequencing in PsA and could influence regional prescribing patterns. Requested formal speaker invitation.'
        },
        new Map<String, String>{
            'Name' => 'Dermatologist exploring off-label use in psoriasis',
            'Content' => 'Dermatology colleague asked whether zelanumab is being studied in moderate-to-severe plaque psoriasis given the IL-17A component. Clarified current approved indications are RA and PsA only. Noted upcoming Phase 2 psoriasis trial enrollment.'
        },
        new Map<String, String>{
            'Name' => 'Payer pushback on step therapy requirement',
            'Content' => 'HCP frustrated that regional payer requires failure on two TNF inhibitors before approving zelanumab. Believes bispecific mechanism warrants earlier access for csDMARD-IR patients. Requested assistance with prior authorization appeal and supporting clinical documentation.'
        }
    };

    private static final List<Map<String, String>> IMMUNONCO_INSIGHTS = new List<Map<String, String>>{
        new Map<String, String>{
            'Name' => 'BEACON-LUNG PFS data reshaping first-line IO discussion',
            'Content' => 'Medical oncologist said the 11.2-month median PFS vs 5.4 months with pembro alone is practice-changing for PD-L1 >=50% NSCLC. Plans to present BEACON-LUNG at next tumor board. Asked about biomarker-driven subgroup analyses for PD-L1 1-49% patients.'
        },
        new Map<String, String>{
            'Name' => 'Oncologist managing irAEs with standard steroid protocols',
            'Content' => 'Dr reported two patients experiencing Grade 2 colitis at Week 8, both resolved with standard prednisone taper within 2 weeks. Noted the 18% Grade >=3 irAE rate is manageable and consistent with the BEACON-LUNG safety profile. No treatment discontinuations needed.'
        },
        new Map<String, String>{
            'Name' => 'TIGIT+ NK cell reinvigoration observed in PD-L1-low tumor',
            'Content' => 'Translational research-focused oncologist excited about responses in PD-L1-low patients. Believes dual PD-1/TIGIT blockade overcoming adaptive resistance is the key differentiator. Requested access to the correlative biomarker data from BEACON-LUNG.'
        },
        new Map<String, String>{
            'Name' => 'Second-line HCC patient showing durable response at 14 months',
            'Content' => 'Hepatologist shared case of post-atezo-bev HCC patient achieving partial response on vorastinib at 14 months and counting. Noted the 28% ORR in BEACON-HCC fills a critical unmet need where no approved second-line IO exists. Wants to submit case report.'
        },
        new Map<String, String>{
            'Name' => 'Fixed-dose IV simplifying infusion chair scheduling',
            'Content' => 'Infusion center manager noted that the fixed-dose Q3W administration without weight-based dosing significantly simplifies scheduling and reduces pharmacy preparation time. The 30-minute infusion after first cycle frees up chairs compared to longer infusion competitors.'
        },
        new Map<String, String>{
            'Name' => 'Tumor board presentation secured for BEACON-LUNG review',
            'Content' => 'Thoracic oncology lead agreed to a 30-minute tumor board slot to review BEACON-LUNG data next month. Will focus on first-line PD-L1 >=50% positioning and patient selection criteria. Expects 8-10 oncologists to attend including two community practice referrers.'
        },
        new Map<String, String>{
            'Name' => 'Molecular profiling identifying vorastinib candidates',
            'Content' => 'Oncologist reviewing molecular profiling reports identified 3 advanced NSCLC patients with PD-L1 >=50% who are treatment-naive. Flagged one additional patient progressing on current IO monotherapy. Will discuss vorastinib at next multidisciplinary tumor board.'
        },
        new Map<String, String>{
            'Name' => 'Community oncologist asking about combination with chemo',
            'Content' => 'Community practice oncologist asked about vorastinib combined with platinum-doublet chemotherapy for PD-L1 <50%. Explained current approval is IO monotherapy for PD-L1 >=50%. Mentioned ongoing Phase 2 chemo-IO combination trial enrolling at regional sites.'
        },
        new Map<String, String>{
            'Name' => 'Pathologist requesting companion diagnostic guidance',
            'Content' => 'Pathology department head asked whether TIGIT expression testing is needed alongside PD-L1 for vorastinib patient selection. Clarified that current labeling requires only PD-L1 >=50% by 22C3 assay. TIGIT testing is investigational and not required for prescribing.'
        },
        new Map<String, String>{
            'Name' => 'Patient access program inquiry for uninsured patient',
            'Content' => 'Social worker at cancer center asked about patient assistance programs for an uninsured NSCLC patient who is a strong vorastinib candidate. Provided information on the manufacturer copay card and free drug program. Patient enrollment paperwork submitted same day.'
        }
    };

    @AuraEnabled(cacheable=true)
    public static String getStatus() {
        try {
            List<String> parts = new List<String>();
            if (!objectExists('MedicalInsight')) return 'MedicalInsight not available in this org.';

            String namePattern = TAG_PREFIX + '%';
            Set<Id> demoInsightIds = new Set<Id>();
            for (SObject mi : Database.query(
                'SELECT Id FROM MedicalInsight WHERE Name LIKE :namePattern'
            )) {
                demoInsightIds.add(mi.Id);
            }
            parts.add('Insights: ' + demoInsightIds.size());

            if (objectExists('MedicalInsightAccount') && !demoInsightIds.isEmpty()) {
                Integer miaCount = Database.countQuery(
                    'SELECT COUNT() FROM MedicalInsightAccount WHERE MedicalInsightId IN :demoInsightIds'
                );
                parts.add('Account Links: ' + miaCount);
            }

            if (objectExists('MedicalInsightProduct') && !demoInsightIds.isEmpty()) {
                Integer mipCount = Database.countQuery(
                    'SELECT COUNT() FROM MedicalInsightProduct WHERE MedicalInsightId IN :demoInsightIds'
                );
                parts.add('Product Links: ' + mipCount);
            }

            return String.join(parts, ', ');
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String createMedicalInsights() {
        List<String> details = new List<String>();
        List<String> errors = new List<String>();

        try {
            String namePattern = TAG_PREFIX + '%';
            Integer existing = Database.countQuery(
                'SELECT COUNT() FROM MedicalInsight WHERE Name LIKE :namePattern'
            );
            if (existing > 0) {
                throw new AuraHandledException('Demo insights already exist (' + existing + '). Delete first.');
            }

            details.add('HEADER:Step 1 — Loading territory and account data');
            List<Territory2> allTerrs = [
                SELECT Id, Name, ParentTerritory2Id FROM Territory2
                WHERE Territory2Model.State = 'Active'
            ];
            Set<Id> parentIds = new Set<Id>();
            for (Territory2 t : allTerrs) {
                if (t.ParentTerritory2Id != null) parentIds.add(t.ParentTerritory2Id);
            }
            List<Territory2> leafTerrs = new List<Territory2>();
            for (Territory2 t : allTerrs) {
                if (!parentIds.contains(t.Id)) leafTerrs.add(t);
            }
            details.add('SUCCESS:Found ' + leafTerrs.size() + ' leaf territories');

            Map<Id, Id> terrToOwner = new Map<Id, Id>();
            Set<Id> leafIds = new Set<Id>();
            for (Territory2 t : leafTerrs) leafIds.add(t.Id);
            for (UserTerritory2Association uta : [
                SELECT Territory2Id, UserId FROM UserTerritory2Association
                WHERE Territory2Id IN :leafIds ORDER BY Territory2Id
            ]) {
                if (!terrToOwner.containsKey(uta.Territory2Id)) {
                    terrToOwner.put(uta.Territory2Id, uta.UserId);
                }
            }

            String demoTag = DEMO_TAG;
            List<Account> demoHcps = [
                SELECT Id, Name, BillingCity, BillingCountryCode
                FROM Account
                WHERE Site = :demoTag AND IsPersonAccount = true
                ORDER BY Name
            ];
            details.add('SUCCESS:Found ' + demoHcps.size() + ' demo HCPs');

            Map<Id, List<Id>> terrToHcpIds = new Map<Id, List<Id>>();
            Set<Id> hcpIds = new Set<Id>();
            for (Account a : demoHcps) hcpIds.add(a.Id);
            for (ObjectTerritory2Association ota : [
                SELECT ObjectId, Territory2Id FROM ObjectTerritory2Association
                WHERE Territory2Id IN :leafIds AND ObjectId IN :hcpIds
            ]) {
                if (!terrToHcpIds.containsKey(ota.Territory2Id)) {
                    terrToHcpIds.put(ota.Territory2Id, new List<Id>());
                }
                terrToHcpIds.get(ota.Territory2Id).add(ota.ObjectId);
            }

            details.add('HEADER:Step 2 — Loading brand products');
            Map<String, List<Id>> countryBrands = loadBrandsByCountry();
            Integer brandCount = 0;
            for (List<Id> ids : countryBrands.values()) brandCount += ids.size();
            details.add('SUCCESS:Found ' + brandCount + ' country brand products');

            details.add('HEADER:Step 3 — Building medical insights');
            Schema.SObjectType miType = Schema.getGlobalDescribe().get('MedicalInsight');
            List<SObject> insightRecords = new List<SObject>();
            List<InsightContext> contexts = new List<InsightContext>();
            Integer seed = Date.today().dayOfYear() * 7;
            Integer seqNum = 0;

            for (Territory2 terr : leafTerrs) {
                String cc = extractCountryCode(terr.Name);
                if (cc == null) continue;
                List<Id> brandIds = countryBrands.get(cc);
                if (brandIds == null || brandIds.isEmpty()) continue;
                List<Id> terrHcps = terrToHcpIds.get(terr.Id);
                if (terrHcps == null || terrHcps.isEmpty()) continue;
                Id ownerId = terrToOwner.get(terr.Id);
                if (ownerId == null) ownerId = UserInfo.getUserId();

                for (Id brandId : brandIds) {
                    String brandName = getBrandNameForId(brandId);
                    List<Map<String, String>> templates = brandName == 'Immunexis'
                        ? IMMUNEXIS_INSIGHTS : IMMUNONCO_INSIGHTS;

                    Integer numInsights = 1 + pseudoRandom(seed + seqNum, 2);
                    for (Integer i = 0; i < numInsights; i++) {
                        Integer templateIdx = pseudoRandom(seed + seqNum + i * 31, templates.size());
                        Map<String, String> tmpl = templates[templateIdx];
                        seqNum++;

                        Integer hcpIdx = pseudoRandom(seed + seqNum, terrHcps.size());
                        Id accountId = terrHcps[hcpIdx];

                        SObject mi = miType.newSObject();
                        String insightName = TAG_PREFIX + tmpl.get('Name');
                        if (insightName.length() > 80) insightName = insightName.substring(0, 80);
                        mi.put('Name', insightName);
                        mi.put('Content', tmpl.get('Content'));
                        mi.put('SourceType', 'Visit');
                        mi.put('OwnerId', ownerId);
                        insightRecords.add(mi);
                        contexts.add(new InsightContext(accountId, brandId, cc, terr.Id));
                    }
                }
            }
            details.add('SUCCESS:Built ' + insightRecords.size() + ' insight records');

            details.add('HEADER:Step 4 — Inserting insights');
            Database.SaveResult[] miResults = Database.insert(insightRecords, false);
            Integer miSuccess = 0;
            for (Database.SaveResult sr : miResults) {
                if (sr.isSuccess()) miSuccess++;
                else if (errors.size() < 15) errors.add('Insight: ' + sr.getErrors()[0].getMessage());
            }
            details.add('SUCCESS:Inserted ' + miSuccess + ' of ' + insightRecords.size());

            details.add('HEADER:Step 5 — Linking to accounts');
            Schema.SObjectType miaType = Schema.getGlobalDescribe().get('MedicalInsightAccount');
            List<SObject> accountLinks = new List<SObject>();
            for (Integer i = 0; i < miResults.size(); i++) {
                if (!miResults[i].isSuccess()) continue;
                SObject mia = miaType.newSObject();
                mia.put('MedicalInsightId', miResults[i].getId());
                mia.put('AccountId', contexts[i].accountId);
                accountLinks.add(mia);
            }
            Database.SaveResult[] miaResults = Database.insert(accountLinks, false);
            Integer miaSuccess = 0;
            for (Database.SaveResult sr : miaResults) {
                if (sr.isSuccess()) miaSuccess++;
                else if (errors.size() < 15) errors.add('Account Link: ' + sr.getErrors()[0].getMessage());
            }
            details.add('SUCCESS:Created ' + miaSuccess + ' account links');

            details.add('HEADER:Step 6 — Linking to products');
            Schema.SObjectType mipType = Schema.getGlobalDescribe().get('MedicalInsightProduct');
            List<SObject> productLinks = new List<SObject>();
            for (Integer i = 0; i < miResults.size(); i++) {
                if (!miResults[i].isSuccess()) continue;
                SObject mip = mipType.newSObject();
                mip.put('MedicalInsightId', miResults[i].getId());
                mip.put('ProductId', contexts[i].brandId);
                productLinks.add(mip);
            }
            Database.SaveResult[] mipResults = Database.insert(productLinks, false);
            Integer mipSuccess = 0;
            for (Database.SaveResult sr : mipResults) {
                if (sr.isSuccess()) mipSuccess++;
                else if (errors.size() < 15) errors.add('Product Link: ' + sr.getErrors()[0].getMessage());
            }
            details.add('SUCCESS:Created ' + mipSuccess + ' product links');

            details.add('HEADER:Step 7 — Sharing with territory groups');
            shareInsightsWithTerritoryGroups(insightRecords, miResults, contexts, details, errors);

            String summary = 'Created ' + miSuccess + ' insights, ' + miaSuccess + ' account links, ' + mipSuccess + ' product links.';
            return JSON.serialize(new Map<String, Object>{
                'summary' => summary, 'details' => details, 'errors' => errors
            });
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }

    @AuraEnabled
    public static String deleteMedicalInsights() {
        try {
            List<String> deleted = new List<String>();
            String namePattern = TAG_PREFIX + '%';

            List<SObject> insights = Database.query(
                'SELECT Id FROM MedicalInsight WHERE Name LIKE :namePattern LIMIT 10000'
            );
            if (insights.isEmpty()) return 'No demo medical insights to delete.';

            Set<Id> insightIds = new Set<Id>();
            for (SObject mi : insights) insightIds.add(mi.Id);

            if (objectExists('MedicalInsightProduct')) {
                List<SObject> mips = Database.query(
                    'SELECT Id FROM MedicalInsightProduct WHERE MedicalInsightId IN :insightIds LIMIT 10000'
                );
                if (!mips.isEmpty()) {
                    Database.delete(mips, false);
                    deleted.add(mips.size() + ' product links');
                }
            }

            if (objectExists('MedicalInsightAccount')) {
                List<SObject> mias = Database.query(
                    'SELECT Id FROM MedicalInsightAccount WHERE MedicalInsightId IN :insightIds LIMIT 10000'
                );
                if (!mias.isEmpty()) {
                    Database.delete(mias, false);
                    deleted.add(mias.size() + ' account links');
                }
            }

            Database.delete(insights, false);
            deleted.add(insights.size() + ' insights');

            return 'Deleted ' + String.join(deleted, ', ') + '.';
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    private static void shareInsightsWithTerritoryGroups(
        List<SObject> insightRecords, Database.SaveResult[] miResults,
        List<InsightContext> contexts, List<String> details, List<String> errors
    ) {
        Set<Id> allTerrIds = new Set<Id>();
        for (InsightContext ctx : contexts) allTerrIds.add(ctx.territoryId);

        Map<Id, Id> terrToGroup = new Map<Id, Id>();
        for (Group g : [SELECT Id, RelatedId FROM Group WHERE Type = 'Territory' AND RelatedId IN :allTerrIds]) {
            terrToGroup.put(g.RelatedId, g.Id);
        }

        Schema.SObjectType shareType = Schema.getGlobalDescribe().get('MedicalInsightShare');
        if (shareType == null) {
            errors.add('MedicalInsightShare object not found');
            return;
        }

        List<SObject> shares = new List<SObject>();
        for (Integer i = 0; i < miResults.size(); i++) {
            if (!miResults[i].isSuccess()) continue;
            Id groupId = terrToGroup.get(contexts[i].territoryId);
            if (groupId == null) continue;
            SObject s = shareType.newSObject();
            s.put('ParentId', miResults[i].getId());
            s.put('UserOrGroupId', groupId);
            s.put('AccessLevel', 'Edit');
            s.put('RowCause', 'Manual');
            shares.add(s);
        }

        if (!shares.isEmpty()) {
            Database.SaveResult[] shareResults = Database.insert(shares, false);
            Integer ok = 0;
            for (Database.SaveResult sr : shareResults) {
                if (sr.isSuccess()) ok++;
                else if (errors.size() < 15) errors.add('Share: ' + sr.getErrors()[0].getMessage());
            }
            details.add('SUCCESS:Shared with ' + ok + ' territory groups');
        }
    }

    private static Map<String, List<Id>> loadBrandsByCountry() {
        Map<String, List<Id>> countryToBrandIds = new Map<String, List<Id>>();
        List<SObject> brands = Database.query(
            'SELECT Id, Name FROM LifeSciMarketableProduct ' +
            'WHERE Type = \'Brand\' AND IsActive = true ORDER BY Name');
        for (SObject brand : brands) {
            String name = (String) brand.get('Name');
            for (String baseName : BRAND_NAMES) {
                String countryPattern = baseName + ' (';
                if (name.startsWith(countryPattern) && name.endsWith(')')) {
                    String cc = name.substring(countryPattern.length(), name.length() - 1);
                    if (!countryToBrandIds.containsKey(cc)) {
                        countryToBrandIds.put(cc, new List<Id>());
                    }
                    countryToBrandIds.get(cc).add(brand.Id);
                }
            }
        }
        return countryToBrandIds;
    }

    private static String extractCountryCode(String territoryName) {
        if (String.isBlank(territoryName)) return null;
        Integer dash = territoryName.indexOf('-');
        if (dash > 0) return territoryName.substring(0, dash);
        return null;
    }

    private static String getBrandNameForId(Id brandId) {
        SObject brand = Database.query(
            'SELECT Name FROM LifeSciMarketableProduct WHERE Id = :brandId LIMIT 1'
        )[0];
        String name = (String) brand.get('Name');
        for (String baseName : BRAND_NAMES) {
            if (name.startsWith(baseName)) return baseName;
        }
        return name;
    }

    private static Integer pseudoRandom(Integer seed, Integer maxVal) {
        if (maxVal <= 0) return 0;
        Long hash = Math.abs(((Long) seed * 6364136223846793005L + 1442695040888963407L));
        return (Integer) Math.mod(hash, maxVal);
    }

    private static Boolean objectExists(String objectName) {
        return Schema.getGlobalDescribe().containsKey(objectName);
    }

    private class InsightContext {
        public Id accountId;
        public Id brandId;
        public String countryCode;
        public Id territoryId;

        public InsightContext(Id accountId, Id brandId, String countryCode, Id territoryId) {
            this.accountId = accountId;
            this.brandId = brandId;
            this.countryCode = countryCode;
            this.territoryId = territoryId;
        }
    }
}
