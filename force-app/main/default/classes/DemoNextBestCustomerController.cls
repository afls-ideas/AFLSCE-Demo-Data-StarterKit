public without sharing class DemoNextBestCustomerController {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';

    @AuraEnabled(cacheable=true)
    public static String getStatus() {
        try {
            if (!objectExists('TerritoryAccountScore')) {
                return 'TerritoryAccountScore not available in this org.';
            }
            String tag = DEMO_TAG;
            Integer count = Database.countQuery(
                'SELECT COUNT() FROM TerritoryAccountScore WHERE SourceSystemName = :tag'
            );
            return 'Scores: ' + count;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTerritories() {
        try {
            List<Territory2> allTerrs = [
                SELECT Id, Name, ParentTerritory2Id FROM Territory2
                WHERE Territory2Model.State = 'Active'
            ];
            Set<Id> parentIds = new Set<Id>();
            for (Territory2 t : allTerrs) {
                if (t.ParentTerritory2Id != null) parentIds.add(t.ParentTerritory2Id);
            }
            Set<Id> leafIds = new Set<Id>();
            Map<Id, String> leafNames = new Map<Id, String>();
            for (Territory2 t : allTerrs) {
                if (!parentIds.contains(t.Id)) {
                    leafIds.add(t.Id);
                    leafNames.put(t.Id, t.Name);
                }
            }

            String demoTag = DEMO_TAG;
            Set<Id> demoHcpIds = new Set<Id>();
            for (Account a : [SELECT Id FROM Account
                    WHERE Site = :demoTag AND IsPersonAccount = true]) {
                demoHcpIds.add(a.Id);
            }

            Set<Id> terrsWithHcps = new Set<Id>();
            for (ObjectTerritory2Association ota : [
                SELECT Territory2Id FROM ObjectTerritory2Association
                WHERE Territory2Id IN :leafIds AND ObjectId IN :demoHcpIds
            ]) {
                terrsWithHcps.add(ota.Territory2Id);
            }

            List<String> sortedNames = new List<String>(leafNames.values());
            sortedNames.sort();
            Map<String, Id> nameToId = new Map<String, Id>();
            for (Id tId : leafNames.keySet()) nameToId.put(leafNames.get(tId), tId);

            List<Map<String, String>> result = new List<Map<String, String>>();
            for (String tName : sortedNames) {
                Id tId = nameToId.get(tName);
                if (!terrsWithHcps.contains(tId)) continue;
                result.add(new Map<String, String>{ 'label' => tName, 'value' => tId });
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error loading territories: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String createScoresForTerritory(Id territoryId) {
        List<String> details = new List<String>();
        List<String> errors = new List<String>();

        try {
            if (!objectExists('TerritoryAccountScore')) {
                throw new AuraHandledException('TerritoryAccountScore not available in this org.');
            }

            Territory2 terr = [SELECT Id, Name FROM Territory2 WHERE Id = :territoryId LIMIT 1];
            details.add('HEADER:' + terr.Name);

            Id ownerId;
            List<UserTerritory2Association> utas = [
                SELECT UserId FROM UserTerritory2Association
                WHERE Territory2Id = :territoryId ORDER BY Territory2Id LIMIT 1
            ];
            ownerId = utas.isEmpty() ? UserInfo.getUserId() : utas[0].UserId;

            String demoTag = DEMO_TAG;
            Set<Id> hcpIds = new Set<Id>();
            for (Account a : [SELECT Id FROM Account
                    WHERE Site = :demoTag AND IsPersonAccount = true]) {
                hcpIds.add(a.Id);
            }

            Set<Id> leafSet = new Set<Id>{ territoryId };
            Set<Id> terrHcpIds = new Set<Id>();
            for (ObjectTerritory2Association ota : [
                SELECT ObjectId FROM ObjectTerritory2Association
                WHERE Territory2Id IN :leafSet AND ObjectId IN :hcpIds
            ]) {
                terrHcpIds.add(ota.ObjectId);
            }

            if (terrHcpIds.isEmpty()) {
                return JSON.serialize(new Map<String, Object>{
                    'summary' => terr.Name + ': no HCPs', 'details' => details, 'errors' => errors,
                    'scoreCount' => 0
                });
            }

            List<Account> hcps = [
                SELECT Id, Name FROM Account WHERE Id IN :terrHcpIds ORDER BY Name
            ];
            details.add('SUCCESS:Found ' + hcps.size() + ' HCPs');

            // Delete existing demo scores for this territory to avoid duplicate ranks
            String tag = DEMO_TAG;
            List<SObject> existing = Database.query(
                'SELECT Id FROM TerritoryAccountScore ' +
                'WHERE SourceSystemName = :tag AND TerritoryId = :territoryId LIMIT 10000'
            );
            if (!existing.isEmpty()) {
                Database.delete(existing, false);
                details.add('SUCCESS:Cleared ' + existing.size() + ' existing demo scores');
            }

            Schema.SObjectType tasType = Schema.getGlobalDescribe().get('TerritoryAccountScore');
            Map<String, Schema.SObjectField> tasFields = tasType.getDescribe().fields.getMap();
            String summaryFieldName = null;
            for (String candidate : new String[]{ 'Score_Summary__c', 'LSDO_Score_Summary__c' }) {
                if (tasFields.containsKey(candidate.toLowerCase())) {
                    summaryFieldName = candidate;
                    break;
                }
            }

            List<SObject> scores = new List<SObject>();
            Integer rank = 1;
            Integer seed = terr.Name.hashCode();

            for (Account hcp : hcps) {
                Integer totalScore = scoreForRank(rank);
                Integer perRecordSeed = seed + rank;
                String explain = buildExplainability(hcp.Name, rank, totalScore, perRecordSeed);
                String insight = buildInsightSummary(hcp.Name, perRecordSeed);

                SObject s = tasType.newSObject();
                s.put('AccountId', hcp.Id);
                s.put('TerritoryId', territoryId);
                s.put('TotalScore', totalScore);
                s.put('Rank', rank);
                s.put('OwnerId', ownerId);
                s.put('ScoreExplainabilityInfo', explain);
                s.put('SourceSystemName', DEMO_TAG);
                s.put('SourceSystemIdentifier', 'TAS-' + territoryId + '-' + hcp.Id);
                if (summaryFieldName != null) s.put(summaryFieldName, insight);
                scores.add(s);
                rank++;
            }

            Database.SaveResult[] results = Database.insert(scores, false);
            Integer successCount = 0;
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) successCount++;
                else if (errors.size() < 10) errors.add('Score: ' + sr.getErrors()[0].getMessage());
            }
            details.add('SUCCESS:Inserted ' + successCount + ' Territory Account Scores');

            return JSON.serialize(new Map<String, Object>{
                'summary' => terr.Name + ': ' + successCount + ' scores',
                'details' => details, 'errors' => errors,
                'scoreCount' => successCount
            });
        } catch (Exception e) {
            throw new AuraHandledException(territoryId + ' error: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }

    @AuraEnabled
    public static String deleteScoresForTerritory(Id territoryId) {
        try {
            if (!objectExists('TerritoryAccountScore')) {
                return 'TerritoryAccountScore not available in this org.';
            }
            String tag = DEMO_TAG;
            List<SObject> scores = Database.query(
                'SELECT Id FROM TerritoryAccountScore ' +
                'WHERE SourceSystemName = :tag AND TerritoryId = :territoryId LIMIT 10000'
            );
            if (scores.isEmpty()) return 'No demo scores for this territory.';
            Database.delete(scores, false);
            return 'Deleted ' + scores.size() + ' scores.';
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String deleteAllScores() {
        try {
            if (!objectExists('TerritoryAccountScore')) {
                return 'TerritoryAccountScore not available in this org.';
            }
            String tag = DEMO_TAG;
            List<SObject> scores = Database.query(
                'SELECT Id FROM TerritoryAccountScore WHERE SourceSystemName = :tag LIMIT 10000'
            );
            if (scores.isEmpty()) return 'No demo scores to delete.';
            Database.delete(scores, false);
            return 'Deleted ' + scores.size() + ' scores.';
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    private static Integer scoreForRank(Integer rank) {
        Integer s = 100 - (rank - 1) * 5;
        return s < 30 ? 30 : s;
    }

    private static final String[] SPECIALTIES = new String[]{
        'Rheumatology', 'Oncology', 'Cardiology', 'Neurology', 'Immunology',
        'Internal Medicine', 'Hematology', 'Endocrinology'
    };

    private static String buildExplainability(String hcpName, Integer rank, Integer totalScore, Integer seed) {
        String tier = rank <= 3 ? 'Tier A High Priority' : (rank <= 8 ? 'Tier B' : 'Tier C');
        String specialty = SPECIALTIES[Math.mod(Math.abs(seed), SPECIALTIES.size())];

        // Distribute totalScore across six metrics so the sum matches TotalScore (per docs).
        Integer base = totalScore / 6;
        Integer rem = totalScore - base * 6;
        Integer s1 = base + (rem > 0 ? 1 : 0);
        Integer s2 = base + (rem > 1 ? 1 : 0);
        Integer s3 = base + (rem > 2 ? 1 : 0);
        Integer s4 = base + (rem > 3 ? 1 : 0);
        Integer s5 = base + (rem > 4 ? 1 : 0);
        Integer s6 = base;

        Integer daysSinceVisit = 7 + pseudoRandom(seed + 1, 60);
        Integer trxPct = 5 + pseudoRandom(seed + 2, 20);
        Integer nrxPct = 3 + pseudoRandom(seed + 3, 15);
        Integer newStarts = 2 + pseudoRandom(seed + 4, 8);
        Integer interactions90 = 1 + pseudoRandom(seed + 5, 12);
        String trend = pseudoRandom(seed + 6, 3) == 0 ? 'down' : 'up';
        String trxDir = trend == 'up' ? '+' : '-';

        Map<String, Object> scores = new Map<String, Object>{
            'Specialty' => s1,
            'Target' => s2,
            'Last Visit' => s3,
            'TRx Growth' => s4,
            'Patient Initiations' => s5,
            'Interactions (90d)' => s6
        };
        Map<String, Object> metrics = new Map<String, Object>{
            'Specialty' => specialty,
            'Target' => tier,
            'Last Visit' => 'Visited ' + daysSinceVisit + ' days ago',
            'TRx Growth' => trxDir + trxPct + '% vs previous quarter (NRx ' + trxDir + nrxPct + '%)',
            'Patient Initiations' => newStarts + ' new starts in the last 30 days',
            'Interactions (90d)' => interactions90 + ' engagements recorded'
        };

        Map<String, Object> payload = new Map<String, Object>{
            'scores' => scores,
            'metrics' => metrics
        };
        return JSON.serialize(payload);
    }

    private static final String[] INSIGHT_TEMPLATES = new String[]{
        'High-volume prescriber with rising patient initiation trend over the last 60 days.',
        'KOL in regional society — strong influence on peer prescribing decisions.',
        'Recently attended our webinar on novel pathways in autoimmune treatment.',
        'Under-engaged account with high growth opportunity this cycle.',
        'No visit in the past 90 days despite favorable formulary access.',
        'Strong clinical fit with increasing activity signals and Tier 1 payer access.',
        'Pharmacy Director — high influence on P&T Committee formulary decisions.',
        'Specializes in complex autoimmune cases with high biologic utilization.',
        'Momentum increased following recent congress attendance and peer interactions.',
        'Opened and clicked the latest product update email within the past week.',
        'Co-authored a recent regional review article with another top-ranked HCP.',
        'New KOL identified in the last 90 days — emerging adoption potential.'
    };

    private static String buildInsightSummary(String hcpName, Integer seed) {
        Integer idx = Math.mod(Math.abs(seed), INSIGHT_TEMPLATES.size());
        return INSIGHT_TEMPLATES[idx];
    }

    private static Integer pseudoRandom(Integer seed, Integer maxVal) {
        if (maxVal <= 0) return 0;
        Long hash = Math.abs(((Long) seed * 6364136223846793005L + 1442695040888963407L));
        return (Integer) Math.mod(hash, maxVal);
    }

    private static Boolean objectExists(String objectName) {
        return Schema.getGlobalDescribe().containsKey(objectName);
    }
}
