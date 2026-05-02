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
    public static List<Map<String, String>> getChannelOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Schema.DescribeFieldResult dfr = Visit.Channel.getDescribe();
        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
            if (pe.isActive()) {
                options.add(new Map<String, String>{
                    'value' => pe.getValue(),
                    'label' => pe.getLabel()
                });
            }
        }
        return options;
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
    public static String createVisits(String territoryId, String primaryChannel) {
        List<String> details = new List<String>();
        List<String> errors = new List<String>();

        try {
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

            details.add('HEADER:Step 3 — Building channel targets');
            if (String.isBlank(primaryChannel)) primaryChannel = 'In-Person';
            List<ChannelTarget> channelTargets = buildChannelTargets(primaryChannel, details);

            details.add('HEADER:Step 4 — Loading brand products for ' + countryCode);
            Map<String, List<Id>> countryToBrandIds = loadBrandsByCountry();
            List<Id> brandIds = countryToBrandIds.get(countryCode);
            if (brandIds == null || brandIds.isEmpty()) {
                details.add('WARNING:No brand products found for country ' + countryCode + ' — skipping product detailing');
            } else {
                details.add('SUCCESS:Found ' + brandIds.size() + ' brand products');
            }

            details.add('HEADER:Step 5 — Building visit records');
            Date today = Date.today();
            Date startDate = Date.newInstance(today.year(), 1, 1);
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
            details.add('Found ' + weekdays.size() + ' weekdays from Jan 1 to today');

            Schema.SObjectType visitType = Schema.getGlobalDescribe().get('Visit');
            Schema.SObjectType pvType = Schema.getGlobalDescribe().get('ProviderVisit');
            Schema.SObjectType pvpdType = Schema.getGlobalDescribe().get('ProviderVisitProdDetailing');

            String tz = COUNTRY_TIMEZONE.get(countryCode);
            if (tz == null) tz = 'America/Chicago';
            TimeZone localTz = TimeZone.getTimeZone(tz);
            details.add('Using timezone: ' + tz);

            List<SObject> allVisits = new List<SObject>();
            List<Datetime> allVisitStartTimes = new List<Datetime>();
            Integer seed = today.dayOfYear() * 7 + territoryId.hashCode();
            Integer visitIndex = 0;

            for (ChannelTarget ct : channelTargets) {
                List<Date> visitDates = pickVisitDates(weekdays, ct.proratedCount, seed + ct.channel.hashCode());
                details.add('Channel ' + ct.channel + ': ' + ct.proratedCount + ' visits (yearly goal: ' + ct.yearlyGoal + ')');

                for (Integer i = 0; i < visitDates.size(); i++) {
                    Date visitDate = visitDates[i];
                    Id hcpId = usableHcpIds[Math.mod(visitIndex, usableHcpIds.size())];
                    visitIndex++;
                    Id placeId = accountToCpa.get(hcpId);

                    Integer slotMin = pseudoRandom(seed + visitIndex * 13 + 5, 480);
                    Integer localHour = 8 + (slotMin / 60);
                    Integer localMin = Math.mod(slotMin, 60);
                    Datetime localDt = Datetime.newInstance(visitDate, Time.newInstance(localHour, localMin, 0, 0));
                    Integer offsetMs = localTz.getOffset(localDt);
                    Datetime startDt = localDt.addSeconds(-offsetMs / 1000);
                    Integer duration = 15 + pseudoRandom(seed + visitIndex * 17, 31);
                    Datetime endDt = startDt.addMinutes(duration);

                    SObject v = visitType.newSObject();
                    v.put('AccountId', hcpId);
                    v.put('OwnerId', ownerId);
                    v.put('PlaceId', placeId);
                    v.put('TerritoryId', territoryId);
                    v.put('Channel', ct.channel);
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

            details.add('HEADER:Step 7 — Inserting ' + allVisits.size() + ' visits (single DML)');
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

            details.add('HEADER:Step 8 — Inserting ' + allPvs.size() + ' provider visits');
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
                details.add('HEADER:Step 9 — Inserting ' + allPvpds.size() + ' product detailing records');
                Database.SaveResult[] pdResults = Database.insert(allPvpds, false);
                for (Database.SaveResult sr : pdResults) {
                    if (sr.isSuccess()) totalPvpd++;
                    else if (errors.size() < 20) {
                        errors.add('ProdDetailing: ' + sr.getErrors()[0].getMessage());
                    }
                }
                details.add('SUCCESS:Created ' + totalPvpd + ' product detailing records');
            }

            details.add('HEADER:Step 10 — Building planned visits (today + 1 month)');
            Date futureEnd = today.addDays(30);
            List<Date> futureWeekdays = new List<Date>();
            Date fd = today;
            while (fd <= futureEnd) {
                Datetime fdt = Datetime.newInstance(fd, Time.newInstance(0, 0, 0, 0));
                String fDayName = fdt.format('EEEE');
                if (fDayName != 'Saturday' && fDayName != 'Sunday') {
                    futureWeekdays.add(fd);
                }
                fd = fd.addDays(1);
            }
            details.add('Found ' + futureWeekdays.size() + ' weekdays in next 30 days');

            Date jan1Future = Date.newInstance(today.year(), 1, 1);
            Date dec31Future = Date.newInstance(today.year(), 12, 31);
            Integer daysInYearFuture = jan1Future.daysBetween(dec31Future) + 1;
            Decimal futureFraction = 30.0 / daysInYearFuture;

            List<SObject> plannedVisits = new List<SObject>();
            List<Datetime> plannedStartTimes = new List<Datetime>();
            Integer plannedIndex = 0;
            Integer plannedSeed = seed + 9999;
            for (ChannelTarget ct : channelTargets) {
                Integer plannedCount = (Integer) Math.round(ct.yearlyGoal * futureFraction);
                if (plannedCount <= 0) continue;

                List<Date> plannedDates = new List<Date>();
                for (Integer pi = 0; pi < plannedCount; pi++) {
                    Integer dayIdx = pseudoRandom(plannedSeed + ct.channel.hashCode() + pi * 31, futureWeekdays.size());
                    plannedDates.add(futureWeekdays[dayIdx]);
                }
                plannedDates.sort();
                details.add('Planned ' + ct.channel + ': ' + plannedCount + ' visits');

                for (Integer i = 0; i < plannedDates.size(); i++) {
                    Date visitDate = plannedDates[i];
                    Id hcpId = usableHcpIds[Math.mod(plannedIndex, usableHcpIds.size())];
                    plannedIndex++;
                    Id placeId = accountToCpa.get(hcpId);

                    Integer slotMin = pseudoRandom(plannedSeed + plannedIndex * 13 + 5, 480);
                    Integer localHour = 8 + (slotMin / 60);
                    Integer localMin = Math.mod(slotMin, 60);
                    Datetime localDt = Datetime.newInstance(visitDate, Time.newInstance(localHour, localMin, 0, 0));
                    Integer offsetMs = localTz.getOffset(localDt);
                    Datetime pStartDt = localDt.addSeconds(-offsetMs / 1000);
                    Integer duration = 15 + pseudoRandom(plannedSeed + plannedIndex * 17, 31);
                    Datetime pEndDt = pStartDt.addMinutes(duration);

                    SObject v = visitType.newSObject();
                    v.put('AccountId', hcpId);
                    v.put('OwnerId', ownerId);
                    v.put('PlaceId', placeId);
                    v.put('TerritoryId', territoryId);
                    v.put('Channel', ct.channel);
                    v.put('PlannedVisitStartTime', pStartDt);
                    v.put('PlannedVisitEndTime', pEndDt);
                    v.put('ActualVisitStartTime', pStartDt);
                    v.put('ActualVisitEndTime', pEndDt);
                    v.put('Status', 'Completed');
                    v.put('InstructionDescription', DEMO_TAG);
                    plannedVisits.add(v);
                    plannedStartTimes.add(pStartDt);
                }
            }

            details.add('HEADER:Step 11 — Inserting ' + plannedVisits.size() + ' planned visits (as Completed to avoid email triggers)');
            Integer totalPlanned = 0;
            Database.SaveResult[] plannedResults = Database.insert(plannedVisits, false);
            List<Id> plannedVisitIds = new List<Id>();
            List<SObject> plannedPvs = new List<SObject>();
            for (Integer i = 0; i < plannedResults.size(); i++) {
                if (plannedResults[i].isSuccess()) {
                    totalPlanned++;
                    plannedVisitIds.add(plannedResults[i].getId());
                    SObject pv = pvType.newSObject();
                    pv.put('VisitId', plannedResults[i].getId());
                    pv.put('OwnerId', ownerId);
                    pv.put('VisitSubmitDateTime', plannedStartTimes[i].addMinutes(25));
                    pv.put('SourceSystemName', DEMO_TAG);
                    plannedPvs.add(pv);
                } else if (errors.size() < 20) {
                    errors.add('Planned Visit: ' + plannedResults[i].getErrors()[0].getMessage());
                }
            }
            details.add('SUCCESS:Created ' + totalPlanned + ' visits');

            Integer totalPlannedPv = 0;
            Integer totalPlannedPvpd = 0;
            if (!plannedPvs.isEmpty()) {
                details.add('HEADER:Step 12 — Inserting ' + plannedPvs.size() + ' planned provider visits + product detailing');
                Database.SaveResult[] ppvResults = Database.insert(plannedPvs, false);
                List<SObject> plannedPvpds = new List<SObject>();
                for (Integer i = 0; i < ppvResults.size(); i++) {
                    if (ppvResults[i].isSuccess()) {
                        totalPlannedPv++;
                        if (brandIds != null && !brandIds.isEmpty()) {
                            Id pvId = ppvResults[i].getId();
                            Integer priority = 1;
                            for (Id brandId : brandIds) {
                                SObject pvpd = pvpdType.newSObject();
                                pvpd.put('ProviderVisitId', pvId);
                                pvpd.put('ProductId', brandId);
                                pvpd.put('Priority', priority);
                                pvpd.put('SourceSystemName', DEMO_TAG);
                                plannedPvpds.add(pvpd);
                                priority++;
                            }
                        }
                    } else if (errors.size() < 20) {
                        errors.add('Planned PV: ' + ppvResults[i].getErrors()[0].getMessage());
                    }
                }
                details.add('SUCCESS:Created ' + totalPlannedPv + ' planned provider visits');

                if (!plannedPvpds.isEmpty()) {
                    Database.SaveResult[] ppdResults = Database.insert(plannedPvpds, false);
                    for (Database.SaveResult sr : ppdResults) {
                        if (sr.isSuccess()) totalPlannedPvpd++;
                        else if (errors.size() < 20) {
                            errors.add('Planned ProdDetailing: ' + sr.getErrors()[0].getMessage());
                        }
                    }
                    details.add('SUCCESS:Created ' + totalPlannedPvpd + ' planned product detailing records');
                }
            }

            details.add('HEADER:Step 13 — Flipping ' + plannedVisitIds.size() + ' visits to Planned status');
            List<SObject> toFlip = new List<SObject>();
            for (Id vid : plannedVisitIds) {
                SObject v = visitType.newSObject(vid);
                v.put('Status', 'Planned');
                toFlip.add(v);
            }
            Integer flipped = 0;
            Database.SaveResult[] flipResults = Database.update(toFlip, false);
            for (Database.SaveResult sr : flipResults) {
                if (sr.isSuccess()) flipped++;
                else if (errors.size() < 20) {
                    errors.add('Flip to Planned: ' + sr.getErrors()[0].getMessage());
                }
            }
            details.add('SUCCESS:Flipped ' + flipped + ' visits to Planned');

            String summary = errors.isEmpty()
                ? 'Created ' + totalVisits + ' completed + ' + totalPlanned + ' planned visits, '
                    + totalPv + ' provider visits, '
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

    private class ChannelTarget {
        public String channel;
        public Integer yearlyGoal;
        public Integer proratedCount;
        public ChannelTarget(String ch, Integer yearly, Integer prorated) {
            this.channel = ch;
            this.yearlyGoal = yearly;
            this.proratedCount = prorated;
        }
    }

    private static List<ChannelTarget> buildChannelTargets(String primaryChannel, List<String> details) {
        List<ChannelTarget> targets = new List<ChannelTarget>();

        Date jan1 = Date.newInstance(Date.today().year(), 1, 1);
        Date dec31 = Date.newInstance(Date.today().year(), 12, 31);
        Integer daysInYear = jan1.daysBetween(dec31) + 1;
        Integer daysElapsed = jan1.daysBetween(Date.today());
        Decimal fraction = (Decimal) daysElapsed / daysInYear;

        Integer yearlyTotal = 600;
        Integer primaryYearly = (Integer) Math.round(yearlyTotal * 0.90);
        Integer primaryProrated = (Integer) Math.round(primaryYearly * fraction);
        targets.add(new ChannelTarget(primaryChannel, primaryYearly, primaryProrated));
        details.add('SUCCESS:Primary channel: ' + primaryChannel + ' — ' + primaryYearly + ' yearly (' + primaryProrated + ' prorated)');

        List<String> secondaryChannels = new List<String>();
        for (Schema.PicklistEntry pe : Visit.Channel.getDescribe().getPicklistValues()) {
            if (pe.isActive() && pe.getValue() != primaryChannel) {
                secondaryChannels.add(pe.getValue());
            }
        }
        if (!secondaryChannels.isEmpty()) {
            Integer remainingYearly = yearlyTotal - primaryYearly;
            Integer perChannel = (Integer) Math.round((Decimal) remainingYearly / secondaryChannels.size());
            for (String ch : secondaryChannels) {
                Integer prorated = (Integer) Math.round(perChannel * fraction);
                if (prorated > 0) {
                    targets.add(new ChannelTarget(ch, perChannel, prorated));
                }
            }
            details.add('SUCCESS:Secondary channels (' + secondaryChannels.size() + '): ' + perChannel + ' yearly each');
        }

        return targets;
    }

    private static List<Date> pickVisitDates(List<Date> weekdays, Integer count, Integer seed) {
        List<Date> picked = new List<Date>();
        if (weekdays.isEmpty() || count <= 0) return picked;
        Integer total = weekdays.size();
        Integer numWeeks = (total + 4) / 5;

        // Build 3-6 phases of "hot" (1.6-2.5x) and "cold" (0-0.4x) activity
        Integer numPhases = 3 + pseudoRandom(seed + 11, 4);
        List<Decimal> phaseMultiplier = new List<Decimal>();
        Boolean hotFirst = pseudoRandom(seed + 3, 2) == 1;
        for (Integer p = 0; p < numPhases; p++) {
            Boolean isHot = (Math.mod(p, 2) == 0) == hotFirst;
            Integer r = pseudoRandom(seed + p * 71 + 19, 100);
            if (isHot) {
                phaseMultiplier.add(1.6 + (r / 100.0) * 0.9);
            } else {
                Decimal cold = (r < 20) ? 0.0 : 0.05 + (r / 100.0) * 0.35;
                phaseMultiplier.add(cold);
            }
        }

        // Divide weeks into phases of varying length
        List<Integer> phaseLengths = new List<Integer>();
        Integer lengthBudget = numWeeks;
        for (Integer p = 0; p < numPhases; p++) {
            Integer minLen = 2;
            Integer maxLen = Math.max(minLen, lengthBudget - (numPhases - p - 1) * minLen);
            Integer len = minLen + pseudoRandom(seed + p * 37, maxLen - minLen + 1);
            if (p == numPhases - 1) len = lengthBudget;
            phaseLengths.add(len);
            lengthBudget -= len;
        }

        // Map each week to its phase multiplier
        List<Decimal> weekWeights = new List<Decimal>();
        Decimal weightSum = 0;
        Integer phaseIdx = 0;
        Integer weeksInPhase = 0;
        for (Integer w = 0; w < numWeeks; w++) {
            if (phaseIdx < numPhases - 1 && weeksInPhase >= phaseLengths[phaseIdx]) {
                phaseIdx++;
                weeksInPhase = 0;
            }
            Decimal base = phaseMultiplier[phaseIdx];
            // Add per-week jitter within the phase (+-30%)
            Integer jr = pseudoRandom(seed + w * 53 + 7, 60);
            Decimal jitter = 0.7 + (jr / 100.0);
            Decimal weight = base * jitter;
            // Slow ramp first 2 weeks
            if (w < 2) weight *= 0.3;
            weekWeights.add(weight);
            weightSum += weight;
            weeksInPhase++;
        }
        if (weightSum == 0) weightSum = 1;

        List<Integer> weekCounts = new List<Integer>();
        Integer assigned = 0;
        for (Integer w = 0; w < numWeeks; w++) {
            Integer wc = (Integer) Math.round(count * weekWeights[w] / weightSum);
            weekCounts.add(wc);
            assigned += wc;
        }
        Integer diff = count - assigned;
        for (Integer w = numWeeks - 1; diff != 0 && w >= 0; w--) {
            if (diff > 0) { weekCounts.set(w, weekCounts[w] + 1); diff--; }
            else if (weekCounts[w] > 0) { weekCounts.set(w, weekCounts[w] - 1); diff++; }
        }

        for (Integer w = 0; w < numWeeks; w++) {
            Integer weekStart = w * 5;
            Integer weekEnd = Math.min(weekStart + 5, total);
            Integer daysInWeek = weekEnd - weekStart;
            if (daysInWeek <= 0) continue;
            for (Integer v = 0; v < weekCounts[w]; v++) {
                Integer dayIdx = weekStart + pseudoRandom(seed + w * 97 + v * 13, daysInWeek);
                picked.add(weekdays[dayIdx]);
            }
        }
        picked.sort();
        return picked;
    }

    private static Integer pseudoRandom(Integer seed, Integer maxVal) {
        if (maxVal <= 0) return 0;
        Long hash = Math.abs(((Long) seed * 6364136223846793005L + 1442695040888963407L));
        return (Integer) Math.mod(hash, maxVal);
    }

    @AuraEnabled
    public static Map<String, Object> deleteVisitBatch() {
        try {
            Integer deleted = 0;
            Integer batchSize = 1500;
            List<String> errors = new List<String>();

            List<Visit> visits = [SELECT Id, Status FROM Visit
                WHERE InstructionDescription = :DEMO_TAG LIMIT :batchSize];

            if (visits.isEmpty()) {
                return new Map<String, Object>{
                    'message' => 'No demo visits to delete.',
                    'remaining' => 0
                };
            }

            // Unlock submitted visits so they can be deleted
            List<Visit> toUnlock = new List<Visit>();
            for (Visit v : visits) {
                if (v.Status != 'Planned') {
                    v.Status = 'Planned';
                    toUnlock.add(v);
                }
            }
            if (!toUnlock.isEmpty()) {
                Database.SaveResult[] ur = Database.update(toUnlock, false);
                Integer unlockFail = 0;
                for (Database.SaveResult sr : ur) {
                    if (!sr.isSuccess()) unlockFail++;
                }
                if (unlockFail > 0 && errors.size() < 3) {
                    errors.add('Failed to unlock ' + unlockFail + '/' + toUnlock.size() + ' visits');
                }
            }

            Set<Id> visitIds = new Set<Id>();
            for (Visit v : visits) visitIds.add(v.Id);

            // Delete child records first
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            if (gd.containsKey('providervisitproddetailing')) {
                List<SObject> pvpds = Database.query(
                    'SELECT Id FROM ProviderVisitProdDetailing WHERE VisitId IN :visitIds');
                if (!pvpds.isEmpty()) {
                    Database.delete(pvpds, false);
                    deleted += pvpds.size();
                }
            }

            if (gd.containsKey('providervisit')) {
                List<SObject> pvs = Database.query(
                    'SELECT Id FROM ProviderVisit WHERE VisitId IN :visitIds');
                if (!pvs.isEmpty()) {
                    Database.delete(pvs, false);
                    deleted += pvs.size();
                }
            }

            Database.DeleteResult[] vr = Database.delete(visits, false);
            Integer visitDeleted = 0;
            for (Database.DeleteResult sr : vr) {
                if (sr.isSuccess()) {
                    visitDeleted++;
                } else if (errors.size() < 3) {
                    errors.add(sr.getErrors()[0].getMessage());
                }
            }
            deleted += visitDeleted;

            Integer remaining = [SELECT COUNT() FROM Visit WHERE InstructionDescription = :DEMO_TAG];
            String msg = 'Deleted ' + visitDeleted + '/' + visits.size() + ' visits + ' + (deleted - visitDeleted) + ' child records. ' + remaining + ' remaining.';
            if (!errors.isEmpty()) msg += ' | ' + String.join(errors, '; ');
            return new Map<String, Object>{
                'message' => msg,
                'remaining' => remaining
            };
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

}
