public without sharing class DemoVisitController {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';

    private static final List<String> BRAND_NAMES = new List<String>{
        'Immunexis', 'Immunonco'
    };

    private static final Map<String, String> COUNTRY_TIMEZONE = new Map<String, String>{
        'US' => 'America/Chicago',
        'GB' => 'Europe/London',
        'FR' => 'Europe/Paris',
        'DE' => 'Europe/Berlin',
        'IT' => 'Europe/Rome',
        'ES' => 'Europe/Madrid',
        'JP' => 'Asia/Tokyo',
        'KR' => 'Asia/Seoul',
        'BR' => 'America/Sao_Paulo',
        'MX' => 'America/Mexico_City',
        'AR' => 'America/Argentina/Buenos_Aires'
    };

    @AuraEnabled(cacheable=true)
    public static String getStatus() {
        try {
            String escaped = String.escapeSingleQuotes(DEMO_TAG);
            List<String> parts = new List<String>();

            Integer visitCount = [SELECT COUNT() FROM Visit WHERE InstructionDescription = :DEMO_TAG];
            parts.add('Visits: ' + visitCount);

            Integer pvpdCount = Database.countQuery(
                'SELECT COUNT() FROM ProviderVisitProdDetailing WHERE SourceSystemName = \'' + escaped + '\'');
            parts.add('Product Detailing: ' + pvpdCount);

            return String.join(parts, ', ');
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTerritories() {
        try {
            Set<Id> leafIds = getLeafTerritoryIds();

            Map<Id, Id> terrToOwner = new Map<Id, Id>();
            for (UserTerritory2Association uta : [
                SELECT Territory2Id, UserId FROM UserTerritory2Association
                WHERE Territory2Id IN :leafIds ORDER BY Territory2Id
            ]) {
                if (!terrToOwner.containsKey(uta.Territory2Id)) {
                    terrToOwner.put(uta.Territory2Id, uta.UserId);
                }
            }

            Set<Id> demoHcpIds = new Set<Id>();
            for (Account a : [SELECT Id FROM Account
                    WHERE Site = :DEMO_TAG AND IsPersonAccount = true]) {
                demoHcpIds.add(a.Id);
            }

            Set<Id> terrsWithHcps = new Set<Id>();
            for (ObjectTerritory2Association ota : [
                SELECT Territory2Id FROM ObjectTerritory2Association
                WHERE Territory2Id IN :leafIds AND ObjectId IN :demoHcpIds
            ]) {
                terrsWithHcps.add(ota.Territory2Id);
            }

            List<Map<String, String>> result = new List<Map<String, String>>();
            for (Territory2 t : [SELECT Id, Name FROM Territory2 WHERE Id IN :leafIds ORDER BY Name]) {
                if (!terrToOwner.containsKey(t.Id) || !terrsWithHcps.contains(t.Id)) continue;
                result.add(new Map<String, String>{
                    'value' => t.Id,
                    'label' => t.Name
                });
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String createVisits(String territoryId) {
        List<String> details = new List<String>();
        List<String> errors = new List<String>();

        try {
            String escaped = String.escapeSingleQuotes(DEMO_TAG);

            Territory2 terr = [SELECT Id, Name FROM Territory2 WHERE Id = :territoryId LIMIT 1];
            String countryCode = extractCountryCode(terr.Name);
            details.add('HEADER:Step 1 — Territory: ' + terr.Name + ' (country: ' + countryCode + ')');

            Id ownerId;
            for (UserTerritory2Association uta : [
                SELECT UserId FROM UserTerritory2Association
                WHERE Territory2Id = :territoryId LIMIT 1
            ]) {
                ownerId = uta.UserId;
            }
            if (ownerId == null) {
                throw new AuraHandledException('No user assigned to territory ' + terr.Name);
            }
            details.add('SUCCESS:Territory owner found');

            Set<Id> demoHcpIds = new Set<Id>();
            for (Account a : [SELECT Id FROM Account
                    WHERE Site = :DEMO_TAG AND IsPersonAccount = true]) {
                demoHcpIds.add(a.Id);
            }

            List<Id> hcpIds = new List<Id>();
            for (ObjectTerritory2Association ota : [
                SELECT ObjectId FROM ObjectTerritory2Association
                WHERE Territory2Id = :territoryId AND ObjectId IN :demoHcpIds
            ]) {
                hcpIds.add(ota.ObjectId);
            }
            if (hcpIds.isEmpty()) {
                throw new AuraHandledException('No demo HCP accounts in territory ' + terr.Name);
            }
            details.add('SUCCESS:Found ' + hcpIds.size() + ' HCP accounts');

            details.add('HEADER:Step 2 — Loading ContactPointAddresses');
            Map<Id, Id> accountToCpa = new Map<Id, Id>();
            for (ContactPointAddress cpa : [
                SELECT Id, ParentId FROM ContactPointAddress
                WHERE ParentId IN :hcpIds AND IsActive = true
                ORDER BY ParentId
            ]) {
                if (!accountToCpa.containsKey(cpa.ParentId)) {
                    accountToCpa.put(cpa.ParentId, cpa.Id);
                }
            }
            details.add('SUCCESS:Found CPAs for ' + accountToCpa.size() + ' accounts');

            List<Id> usableHcpIds = new List<Id>();
            for (Id hcpId : hcpIds) {
                if (accountToCpa.containsKey(hcpId)) {
                    usableHcpIds.add(hcpId);
                }
            }
            if (usableHcpIds.isEmpty()) {
                throw new AuraHandledException('No HCPs with active ContactPointAddress in territory');
            }

            details.add('HEADER:Step 3 — Loading brand products for ' + countryCode);
            Map<String, List<Id>> countryToBrandIds = loadBrandsByCountry();
            List<Id> brandIds = countryToBrandIds.get(countryCode);
            if (brandIds == null || brandIds.isEmpty()) {
                details.add('WARNING:No brand products found for country ' + countryCode + ' — skipping product detailing');
            } else {
                details.add('SUCCESS:Found ' + brandIds.size() + ' brand products');
            }

            details.add('HEADER:Step 4 — Building visit records');
            Date today = Date.today();
            Date startDate = today.addDays(-30);

            List<Date> weekdays = new List<Date>();
            Date d = startDate;
            while (d < today) {
                Datetime dt = Datetime.newInstance(d, Time.newInstance(0, 0, 0, 0));
                String dayName = dt.format('EEEE');
                if (dayName != 'Saturday' && dayName != 'Sunday') {
                    weekdays.add(d);
                }
                d = d.addDays(1);
            }
            details.add('Found ' + weekdays.size() + ' weekdays in last 30 days');

            Schema.SObjectType visitType = Schema.getGlobalDescribe().get('Visit');
            Schema.SObjectType pvType = Schema.getGlobalDescribe().get('ProviderVisit');
            Schema.SObjectType pvpdType = Schema.getGlobalDescribe().get('ProviderVisitProdDetailing');

            String tz = COUNTRY_TIMEZONE.get(countryCode);
            if (tz == null) tz = 'America/Chicago';
            TimeZone localTz = TimeZone.getTimeZone(tz);
            details.add('Using timezone: ' + tz);

            List<SObject> allVisits = new List<SObject>();
            List<Datetime> allVisitStartTimes = new List<Datetime>();
            Integer hcpIndex = 0;
            Integer seed = Date.today().dayOfYear();

            for (Date weekday : weekdays) {
                Integer visitsToday = 3 + Math.mod(seed + weekday.dayOfYear(), 4);
                List<Integer> slotMinutes = generateSlotMinutes(visitsToday, seed + weekday.dayOfYear());

                for (Integer slot = 0; slot < visitsToday; slot++) {
                    Id hcpId = usableHcpIds[Math.mod(hcpIndex, usableHcpIds.size())];
                    hcpIndex++;
                    Id placeId = accountToCpa.get(hcpId);
                    Integer localHour = 8 + (slotMinutes[slot] / 60);
                    Integer localMin = Math.mod(slotMinutes[slot], 60);
                    Datetime localDt = Datetime.newInstance(weekday, Time.newInstance(localHour, localMin, 0, 0));
                    Integer offsetMs = localTz.getOffset(localDt);
                    Datetime startDt = localDt.addSeconds(-offsetMs / 1000);
                    Integer duration = 20 + Math.mod(seed + slot, 16);
                    Datetime endDt = startDt.addMinutes(duration);

                    SObject v = visitType.newSObject();
                    v.put('AccountId', hcpId);
                    v.put('OwnerId', ownerId);
                    v.put('PlaceId', placeId);
                    v.put('TerritoryId', territoryId);
                    v.put('Channel', 'In-Person');
                    v.put('PlannedVisitStartTime', startDt);
                    v.put('PlannedVisitEndTime', endDt);
                    v.put('ActualVisitStartTime', startDt);
                    v.put('ActualVisitEndTime', endDt);
                    v.put('Status', 'Completed');
                    v.put('InstructionDescription', DEMO_TAG);
                    allVisits.add(v);
                    allVisitStartTimes.add(startDt);
                }
            }

            details.add('HEADER:Step 5 — Inserting ' + allVisits.size() + ' visits (single DML)');
            Database.SaveResult[] vResults = Database.insert(allVisits, false);
            Integer totalVisits = 0;
            List<SObject> allPvs = new List<SObject>();
            for (Integer i = 0; i < vResults.size(); i++) {
                if (vResults[i].isSuccess()) {
                    totalVisits++;
                    SObject pv = pvType.newSObject();
                    pv.put('VisitId', vResults[i].getId());
                    pv.put('OwnerId', ownerId);
                    pv.put('VisitSubmitDateTime', allVisitStartTimes[i].addMinutes(25));
                    pv.put('SourceSystemName', DEMO_TAG);
                    allPvs.add(pv);
                } else if (errors.size() < 20) {
                    errors.add('Visit: ' + vResults[i].getErrors()[0].getMessage());
                }
            }
            details.add('SUCCESS:Created ' + totalVisits + ' visits');

            details.add('HEADER:Step 6 — Inserting ' + allPvs.size() + ' provider visits');
            Integer totalPv = 0;
            Integer totalPvpd = 0;
            Database.SaveResult[] pvResults = Database.insert(allPvs, false);
            List<SObject> allPvpds = new List<SObject>();
            for (Integer i = 0; i < pvResults.size(); i++) {
                if (pvResults[i].isSuccess()) {
                    totalPv++;
                    if (brandIds != null && !brandIds.isEmpty()) {
                        Id pvId = pvResults[i].getId();
                        Integer priority = 1;
                        for (Id brandId : brandIds) {
                            SObject pvpd = pvpdType.newSObject();
                            pvpd.put('ProviderVisitId', pvId);
                            pvpd.put('ProductId', brandId);
                            pvpd.put('Priority', priority);
                            pvpd.put('SourceSystemName', DEMO_TAG);
                            allPvpds.add(pvpd);
                            priority++;
                        }
                    }
                } else if (errors.size() < 20) {
                    errors.add('ProviderVisit: ' + pvResults[i].getErrors()[0].getMessage());
                }
            }
            details.add('SUCCESS:Created ' + totalPv + ' provider visits');

            if (!allPvpds.isEmpty()) {
                details.add('HEADER:Step 7 — Inserting ' + allPvpds.size() + ' product detailing records');
                Database.SaveResult[] pdResults = Database.insert(allPvpds, false);
                for (Database.SaveResult sr : pdResults) {
                    if (sr.isSuccess()) totalPvpd++;
                    else if (errors.size() < 20) {
                        errors.add('ProdDetailing: ' + sr.getErrors()[0].getMessage());
                    }
                }
                details.add('SUCCESS:Created ' + totalPvpd + ' product detailing records');
            }

            String summary = errors.isEmpty()
                ? 'Created ' + totalVisits + ' visits, ' + totalPv + ' provider visits, '
                    + totalPvpd + ' product detailing for ' + terr.Name + '.'
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
    public static String deleteVisits() {
        try {
            Integer deleted = 0;
            String escaped = String.escapeSingleQuotes(DEMO_TAG);

            List<Visit> visits = [SELECT Id FROM Visit
                WHERE InstructionDescription = :DEMO_TAG LIMIT 9500];
            Set<Id> visitIds = new Set<Id>();
            for (Visit v : visits) visitIds.add(v.Id);

            if (!visitIds.isEmpty()) {
                List<SObject> pvpds = Database.query(
                    'SELECT Id FROM ProviderVisitProdDetailing WHERE VisitId IN :visitIds LIMIT 9500');
                if (!pvpds.isEmpty()) {
                    Database.delete(pvpds, false);
                    deleted += pvpds.size();
                }

                List<SObject> pvs = Database.query(
                    'SELECT Id FROM ProviderVisit WHERE VisitId IN :visitIds LIMIT 9500');
                if (!pvs.isEmpty()) {
                    Database.delete(pvs, false);
                    deleted += pvs.size();
                }

                Database.delete(visits, false);
                deleted += visits.size();
            }

            Integer remaining = [SELECT COUNT() FROM Visit WHERE InstructionDescription = :DEMO_TAG];
            String msg = 'Deleted ' + deleted + ' records.';
            if (remaining > 0) {
                msg += ' More records remain — click delete again.';
            }
            return msg;
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting: ' + e.getMessage());
        }
    }

    private static String extractCountryCode(String territoryName) {
        if (String.isBlank(territoryName)) return null;
        Integer dash = territoryName.indexOf('-');
        if (dash > 0) return territoryName.substring(0, dash);
        return null;
    }

    private static Set<Id> getLeafTerritoryIds() {
        List<Territory2> allTerrs = [
            SELECT Id, ParentTerritory2Id FROM Territory2
            WHERE Territory2Model.State = 'Active'
        ];
        Set<Id> parentIds = new Set<Id>();
        for (Territory2 t : allTerrs) {
            if (t.ParentTerritory2Id != null) parentIds.add(t.ParentTerritory2Id);
        }
        Set<Id> leafIds = new Set<Id>();
        for (Territory2 t : allTerrs) {
            if (!parentIds.contains(t.Id)) leafIds.add(t.Id);
        }
        return leafIds;
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

    private static List<Integer> generateSlotMinutes(Integer count, Integer seed) {
        // 8:00=0min to 16:00=480min window, each visit needs ~45min gap
        List<Integer> slots = new List<Integer>();
        Integer window = 480;
        Integer gap = window / (count + 1);
        for (Integer i = 0; i < count; i++) {
            Integer base = gap * (i + 1);
            Integer jitter = Math.mod(seed * (i + 3) * 7, 21) - 10;
            Integer mins = Math.max(0, Math.min(window - 40, base + jitter));
            slots.add(mins);
        }
        return slots;
    }
}
