public without sharing class DemoCampaignController {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';

    private static final List<Map<String, String>> CAMPAIGNS = new List<Map<String, String>>{
        new Map<String, String>{
            'Name' => 'Immunexis RA Awareness Email Series',
            'Type' => 'Email',
            'Description' => 'Multi-touch email nurture educating rheumatologists on Immunexis efficacy data for moderate-to-severe RA'
        },
        new Map<String, String>{
            'Name' => 'Immunexis MOA Webinar — Q1 2026',
            'Type' => 'Seminar / Conference',
            'Description' => 'Live webinar featuring KOL presentation on Immunexis mechanism of action and Phase III results'
        },
        new Map<String, String>{
            'Name' => 'ASCO 2026 Congress Follow-Up',
            'Type' => 'Seminar / Conference',
            'Description' => 'Post-congress outreach to oncologists met at ASCO booth with Immunonco clinical data'
        },
        new Map<String, String>{
            'Name' => 'Immunexis Product Launch Announcement',
            'Type' => 'Email',
            'Description' => 'Single-send announcement of Immunexis new indication approval for psoriatic arthritis'
        },
        new Map<String, String>{
            'Name' => 'Immunonco Real-World Evidence Newsletter',
            'Type' => 'Email',
            'Description' => 'Quarterly newsletter sharing real-world outcomes data and case studies for Immunonco'
        },
        new Map<String, String>{
            'Name' => 'HCP Peer-to-Peer Speaker Program Invite',
            'Type' => 'Seminar / Conference',
            'Description' => 'Invitation to local peer-to-peer dinner events featuring Immunexis clinical experience sharing'
        },
        new Map<String, String>{
            'Name' => 'Immunexis Patient Support Hub Enrollment',
            'Type' => 'Email',
            'Description' => 'Targeted outreach encouraging HCPs to enroll patients in the Immunexis Hub support program'
        }
    };

    private static final List<String> EMAIL_STATUSES = new List<String>{
        'Sent', 'Opened', 'Clicked', 'Registered', 'Attended', 'No Show'
    };

    private static final List<String> JOURNEY_STATUSES = new List<String>{
        'Unaware', 'Aware', 'Interested', 'Trial', 'Adopter', 'Advocate'
    };

    private static final Map<String, String> COUNTRY_NAMES = new Map<String, String>{
        'US' => 'United States', 'GB' => 'United Kingdom', 'FR' => 'France',
        'DE' => 'Germany', 'IT' => 'Italy', 'ES' => 'Spain',
        'JP' => 'Japan', 'KR' => 'South Korea', 'BR' => 'Brazil',
        'MX' => 'Mexico', 'AR' => 'Argentina'
    };

    @AuraEnabled(cacheable=true)
    public static String getStatus() {
        try {
            String extPattern = DEMO_TAG + '-CAMP-%';
            List<Campaign> demoCamps = [SELECT Id FROM Campaign WHERE External_ID__c LIKE :extPattern];
            Integer campCount = demoCamps.size();
            Integer memberCount = 0;
            if (!demoCamps.isEmpty()) {
                Set<Id> cIds = new Map<Id, Campaign>(demoCamps).keySet();
                memberCount = [SELECT COUNT() FROM CampaignMember WHERE CampaignId IN :cIds];
            }
            return 'Campaigns: ' + campCount + ', Campaign Members: ' + memberCount;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String createCampaigns() {
        List<String> details = new List<String>();
        List<String> errors = new List<String>();

        try {
            String extPattern = DEMO_TAG + '-CAMP-%';
            Integer existing = [SELECT COUNT() FROM Campaign WHERE External_ID__c LIKE :extPattern];
            if (existing > 0) {
                throw new AuraHandledException('Demo campaigns already exist (' + existing + '). Delete first.');
            }

            details.add('HEADER:Step 1 — Loading demo HCPs');
            List<Account> hcps = [
                SELECT Id, PersonContactId, BillingCountryCode
                FROM Account
                WHERE Site = :DEMO_TAG AND IsPersonAccount = true AND PersonContactId != null
                ORDER BY Name
            ];
            details.add('SUCCESS:Found ' + hcps.size() + ' HCPs');

            // Group HCPs by country
            Map<String, List<Account>> hcpsByCountry = new Map<String, List<Account>>();
            for (Account a : hcps) {
                String cc = a.BillingCountryCode;
                if (cc == null) continue;
                if (!hcpsByCountry.containsKey(cc)) hcpsByCountry.put(cc, new List<Account>());
                hcpsByCountry.get(cc).add(a);
            }
            details.add('HCPs across ' + hcpsByCountry.size() + ' countries');

            details.add('HEADER:Step 2 — Creating journey campaigns (one per country)');
            Date today = Date.today();
            List<Campaign> journeyCamps = new List<Campaign>();
            List<String> journeyCountryCodes = new List<String>();
            Integer idx = 0;
            for (String cc : hcpsByCountry.keySet()) {
                String countryName = COUNTRY_NAMES.containsKey(cc) ? COUNTRY_NAMES.get(cc) : cc;
                Campaign c = new Campaign();
                c.Name = 'Immunexis HCP Adoption Journey — ' + countryName;
                c.Type = 'Other';
                c.Description = 'HCP journey moving providers from Unaware to Advocate for Immunexis in ' + countryName;
                c.External_ID__c = DEMO_TAG + '-CAMP-J-' + cc;
                c.IsActive = true;
                c.Status = 'In Progress';
                c.StartDate = Date.newInstance(today.year(), 1, 1);
                c.EndDate = Date.newInstance(today.year(), 12, 31);
                journeyCamps.add(c);
                journeyCountryCodes.add(cc);
                idx++;
            }

            Database.SaveResult[] jResults = Database.insert(journeyCamps, false);
            Map<String, Id> countryToJourneyCampId = new Map<String, Id>();
            List<Id> journeyCampIds = new List<Id>();
            for (Integer i = 0; i < jResults.size(); i++) {
                if (jResults[i].isSuccess()) {
                    countryToJourneyCampId.put(journeyCountryCodes[i], jResults[i].getId());
                    journeyCampIds.add(jResults[i].getId());
                } else if (errors.size() < 10) {
                    errors.add('Journey Campaign: ' + jResults[i].getErrors()[0].getMessage());
                }
            }
            details.add('SUCCESS:Created ' + journeyCampIds.size() + ' journey campaigns');

            details.add('HEADER:Step 3 — Creating marketing campaigns');
            List<Campaign> marketingCamps = new List<Campaign>();
            for (Integer i = 0; i < CAMPAIGNS.size(); i++) {
                Map<String, String> cd = CAMPAIGNS[i];
                Campaign c = new Campaign();
                c.Name = cd.get('Name');
                c.Type = cd.get('Type');
                c.Description = cd.get('Description');
                c.External_ID__c = DEMO_TAG + '-CAMP-M-' + i;
                c.IsActive = true;
                c.Status = (Math.mod(i, 3) == 0) ? 'Completed' : 'In Progress';
                c.StartDate = today.addDays(-90 + (i * 10));
                c.EndDate = today.addDays(-30 + (i * 10));
                marketingCamps.add(c);
            }

            Database.SaveResult[] mResults = Database.insert(marketingCamps, false);
            List<Id> marketingCampIds = new List<Id>();
            for (Integer i = 0; i < mResults.size(); i++) {
                if (mResults[i].isSuccess()) {
                    marketingCampIds.add(mResults[i].getId());
                } else if (errors.size() < 10) {
                    errors.add('Marketing Campaign: ' + mResults[i].getErrors()[0].getMessage());
                }
            }
            details.add('SUCCESS:Created ' + marketingCampIds.size() + ' marketing campaigns');

            details.add('HEADER:Step 4 — Adding custom member statuses');
            addJourneyStatuses(journeyCampIds, details, errors);
            addEmailStatuses(marketingCampIds, details, errors);

            details.add('HEADER:Step 5 — Adding HCPs to journey campaigns (all HCPs per country)');
            Integer totalJourneyMembers = 0;
            Integer seed = today.dayOfYear() * 13;
            for (String cc : countryToJourneyCampId.keySet()) {
                Id campId = countryToJourneyCampId.get(cc);
                List<Account> countryHcps = hcpsByCountry.get(cc);
                if (countryHcps == null || countryHcps.isEmpty()) continue;

                List<CampaignMember> members = new List<CampaignMember>();
                for (Integer m = 0; m < countryHcps.size(); m++) {
                    Account hcp = countryHcps[m];
                    String status = pickJourneyStatus(seed + cc.hashCode() + m * 17);
                    CampaignMember cm = new CampaignMember();
                    cm.CampaignId = campId;
                    cm.ContactId = hcp.PersonContactId;
                    cm.Status = status;
                    members.add(cm);
                }

                Database.SaveResult[] memResults = Database.insert(members, false);
                Integer inserted = 0;
                for (Database.SaveResult sr : memResults) {
                    if (sr.isSuccess()) inserted++;
                    else if (errors.size() < 20) {
                        errors.add('Journey Member (' + cc + '): ' + sr.getErrors()[0].getMessage());
                    }
                }
                totalJourneyMembers += inserted;
            }
            details.add('SUCCESS:Created ' + totalJourneyMembers + ' journey campaign members');

            details.add('HEADER:Step 6 — Adding HCPs to marketing campaigns (40-80% random)');
            Integer totalMarketingMembers = 0;
            for (Integer ci = 0; ci < marketingCampIds.size(); ci++) {
                Id campId = marketingCampIds[ci];
                Integer memberCount = (Integer) Math.round(hcps.size() * (0.4 + (pseudoRandom(seed + ci * 31, 40) / 100.0)));
                List<CampaignMember> members = new List<CampaignMember>();

                for (Integer m = 0; m < memberCount && m < hcps.size(); m++) {
                    Integer hcpIdx = pseudoRandom(seed + ci * 97 + m * 7, hcps.size());
                    Account hcp = hcps[hcpIdx];
                    String status = pickEmailStatus(seed + ci * 53 + m * 11);
                    CampaignMember cm = new CampaignMember();
                    cm.CampaignId = campId;
                    cm.ContactId = hcp.PersonContactId;
                    cm.Status = status;
                    members.add(cm);
                }

                Map<Id, CampaignMember> dedupedMap = new Map<Id, CampaignMember>();
                for (CampaignMember cm : members) {
                    dedupedMap.put(cm.ContactId, cm);
                }
                List<CampaignMember> deduped = dedupedMap.values();

                Database.SaveResult[] memResults = Database.insert(deduped, false);
                Integer inserted = 0;
                for (Database.SaveResult sr : memResults) {
                    if (sr.isSuccess()) inserted++;
                    else if (errors.size() < 20) {
                        errors.add('Marketing Member: ' + sr.getErrors()[0].getMessage());
                    }
                }
                totalMarketingMembers += inserted;
            }
            details.add('SUCCESS:Created ' + totalMarketingMembers + ' marketing campaign members');

            Integer totalCamps = journeyCampIds.size() + marketingCampIds.size();
            Integer totalMembers = totalJourneyMembers + totalMarketingMembers;
            String summary = errors.isEmpty()
                ? 'Created ' + totalCamps + ' campaigns with ' + totalMembers + ' total members.'
                : 'Completed with ' + errors.size() + ' error(s).';
            return JSON.serialize(new Map<String, Object>{
                'summary' => summary, 'details' => details, 'errors' => errors
            });
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    @AuraEnabled
    public static String deleteCampaigns() {
        try {
            String extPattern = DEMO_TAG + '-CAMP-%';
            List<Campaign> camps = [SELECT Id FROM Campaign WHERE External_ID__c LIKE :extPattern LIMIT 2000];
            if (camps.isEmpty()) return 'No demo campaigns to delete.';

            Set<Id> campIds = new Set<Id>();
            for (Campaign c : camps) campIds.add(c.Id);

            List<CampaignMember> members = [SELECT Id FROM CampaignMember WHERE CampaignId IN :campIds LIMIT 10000];
            if (!members.isEmpty()) {
                Database.delete(members, false);
            }

            Database.DeleteResult[] results = Database.delete(camps, false);
            Integer deleted = 0;
            for (Database.DeleteResult dr : results) {
                if (dr.isSuccess()) deleted++;
            }
            return 'Deleted ' + deleted + ' campaigns and ' + members.size() + ' members.';
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    private static void addJourneyStatuses(List<Id> campIds, List<String> details, List<String> errors) {
        Map<Id, Set<String>> existingStatuses = new Map<Id, Set<String>>();
        for (CampaignMemberStatus cms : [
            SELECT CampaignId, Label FROM CampaignMemberStatus WHERE CampaignId IN :campIds
        ]) {
            if (!existingStatuses.containsKey(cms.CampaignId)) {
                existingStatuses.put(cms.CampaignId, new Set<String>());
            }
            existingStatuses.get(cms.CampaignId).add(cms.Label);
        }

        List<CampaignMemberStatus> toInsert = new List<CampaignMemberStatus>();
        for (Id campId : campIds) {
            Set<String> existing = existingStatuses.containsKey(campId) ? existingStatuses.get(campId) : new Set<String>();
            Integer sortBase = existing.size() + 1;
            for (Integer i = 0; i < JOURNEY_STATUSES.size(); i++) {
                String label = JOURNEY_STATUSES[i];
                if (existing.contains(label)) continue;
                CampaignMemberStatus cms = new CampaignMemberStatus();
                cms.CampaignId = campId;
                cms.Label = label;
                cms.SortOrder = sortBase + i;
                cms.HasResponded = (label == 'Adopter' || label == 'Advocate');
                cms.IsDefault = false;
                toInsert.add(cms);
            }
        }

        if (!toInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(toInsert, false);
            Integer created = 0;
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) created++;
                else if (errors.size() < 10) {
                    errors.add('Journey Status: ' + sr.getErrors()[0].getMessage());
                }
            }
            details.add('SUCCESS:Added ' + created + ' journey statuses');
        }
    }

    private static void addEmailStatuses(List<Id> campIds, List<String> details, List<String> errors) {
        Map<Id, Set<String>> existingStatuses = new Map<Id, Set<String>>();
        for (CampaignMemberStatus cms : [
            SELECT CampaignId, Label FROM CampaignMemberStatus WHERE CampaignId IN :campIds
        ]) {
            if (!existingStatuses.containsKey(cms.CampaignId)) {
                existingStatuses.put(cms.CampaignId, new Set<String>());
            }
            existingStatuses.get(cms.CampaignId).add(cms.Label);
        }

        List<CampaignMemberStatus> toInsert = new List<CampaignMemberStatus>();
        for (Id campId : campIds) {
            Set<String> existing = existingStatuses.containsKey(campId) ? existingStatuses.get(campId) : new Set<String>();
            Integer sortBase = existing.size() + 1;
            for (Integer i = 0; i < EMAIL_STATUSES.size(); i++) {
                String label = EMAIL_STATUSES[i];
                if (existing.contains(label)) continue;
                CampaignMemberStatus cms = new CampaignMemberStatus();
                cms.CampaignId = campId;
                cms.Label = label;
                cms.SortOrder = sortBase + i;
                cms.HasResponded = (label == 'Attended' || label == 'Clicked' || label == 'Registered');
                cms.IsDefault = false;
                toInsert.add(cms);
            }
        }

        if (!toInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(toInsert, false);
            Integer created = 0;
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) created++;
                else if (errors.size() < 10) {
                    errors.add('Email Status: ' + sr.getErrors()[0].getMessage());
                }
            }
            details.add('SUCCESS:Added ' + created + ' email statuses');
        }
    }

    private static String pickJourneyStatus(Integer seed) {
        // Distribution weighted toward earlier stages: 25% Unaware, 25% Aware, 20% Interested, 15% Trial, 10% Adopter, 5% Advocate
        Integer r = pseudoRandom(seed, 100);
        if (r < 5) return 'Advocate';
        if (r < 15) return 'Adopter';
        if (r < 30) return 'Trial';
        if (r < 50) return 'Interested';
        if (r < 75) return 'Aware';
        return 'Unaware';
    }

    private static String pickEmailStatus(Integer seed) {
        Integer r = pseudoRandom(seed, 100);
        if (r < 5) return 'No Show';
        if (r < 10) return 'Attended';
        if (r < 20) return 'Registered';
        if (r < 40) return 'Clicked';
        if (r < 65) return 'Opened';
        return 'Sent';
    }

    private static Integer pseudoRandom(Integer seed, Integer maxVal) {
        if (maxVal <= 0) return 0;
        Long hash = Math.abs(((Long) seed * 6364136223846793005L + 1442695040888963407L));
        return (Integer) Math.mod(hash, maxVal);
    }
}
