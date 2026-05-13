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

            Integer pgCount = Database.countQuery(
                'SELECT COUNT() FROM ProductGuidance WHERE SourceSystemName = \'' + escaped + '\'');
            parts.add('Product Guidance: ' + pgCount);

            Integer msgCount = Database.countQuery(
                'SELECT COUNT() FROM ProviderVisitDtlProductMsg WHERE SourceSystemName = \'' + escaped + '\'');
            parts.add('Product Messages: ' + msgCount);

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
                            pvpd.put('OwnerId', ownerId);
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
                List<Id> successPvpdIds = new List<Id>();
                for (Database.SaveResult sr : pdResults) {
                    if (sr.isSuccess()) {
                        totalPvpd++;
                        successPvpdIds.add(sr.getId());
                    } else if (errors.size() < 20) {
                        errors.add('ProdDetailing: ' + sr.getErrors()[0].getMessage());
                    }
                }
                details.add('SUCCESS:Created ' + totalPvpd + ' product detailing records');

                // Step 9b: Create ProviderVisitDtlProductMsg for completed visits
                List<SObject> allMsgs = buildProductMessages(successPvpdIds, countryCode, ownerId, seed, false);
                if (!allMsgs.isEmpty()) {
                    details.add('HEADER:Step 9b — Inserting ' + allMsgs.size() + ' product messages');
                    Integer totalMsgs = 0;
                    Database.SaveResult[] msgResults = Database.insert(allMsgs, false);
                    for (Database.SaveResult sr : msgResults) {
                        if (sr.isSuccess()) totalMsgs++;
                        else if (errors.size() < 20) {
                            errors.add('ProductMsg: ' + sr.getErrors()[0].getMessage());
                        }
                    }
                    details.add('SUCCESS:Created ' + totalMsgs + ' product messages');
                }
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
                                pvpd.put('OwnerId', ownerId);
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
                    List<Id> plannedPvpdIds = new List<Id>();
                    for (Database.SaveResult sr : ppdResults) {
                        if (sr.isSuccess()) {
                            totalPlannedPvpd++;
                            plannedPvpdIds.add(sr.getId());
                        } else if (errors.size() < 20) {
                            errors.add('Planned ProdDetailing: ' + sr.getErrors()[0].getMessage());
                        }
                    }
                    details.add('SUCCESS:Created ' + totalPlannedPvpd + ' planned product detailing records');

                    List<SObject> plannedMsgs = buildProductMessages(plannedPvpdIds, countryCode, ownerId, seed + 7777, true);
                    if (!plannedMsgs.isEmpty()) {
                        Integer totalPlannedMsgs = 0;
                        Database.SaveResult[] pmResults = Database.insert(plannedMsgs, false);
                        for (Database.SaveResult sr : pmResults) {
                            if (sr.isSuccess()) totalPlannedMsgs++;
                            else if (errors.size() < 20) {
                                errors.add('Planned ProductMsg: ' + sr.getErrors()[0].getMessage());
                            }
                        }
                        details.add('SUCCESS:Created ' + totalPlannedMsgs + ' planned product messages');
                    }
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

    private static List<SObject> buildProductMessages(List<Id> pvpdIds, String countryCode, Id ownerId, Integer seed, Boolean isPlanned) {
        List<SObject> msgs = new List<SObject>();
        if (pvpdIds.isEmpty()) return msgs;

        String escaped = String.escapeSingleQuotes(DEMO_TAG);
        // Load ProductGuidance records for this country's brands
        List<SObject> guidanceRecords = Database.query(
            'SELECT Id, ProductReferenceRecordId, Type FROM ProductGuidance ' +
            'WHERE SourceSystemName = \'' + escaped + '\' ORDER BY Id');
        if (guidanceRecords.isEmpty()) return msgs;

        // Group guidance by product Id
        Map<Id, List<SObject>> guidanceByProduct = new Map<Id, List<SObject>>();
        for (SObject pg : guidanceRecords) {
            Id prodId = (Id) pg.get('ProductReferenceRecordId');
            if (!guidanceByProduct.containsKey(prodId)) {
                guidanceByProduct.put(prodId, new List<SObject>());
            }
            guidanceByProduct.get(prodId).add(pg);
        }

        // Query PVPDs to get their ProductId and ProviderVisitId
        Map<Id, SObject> pvpdMap = new Map<Id, SObject>(Database.query(
            'SELECT Id, ProductId, ProviderVisitId, VisitId FROM ProviderVisitProdDetailing WHERE Id IN :pvpdIds'));

        Schema.SObjectType msgType = Schema.getGlobalDescribe().get('ProviderVisitDtlProductMsg');
        if (msgType == null) return msgs;

        String[] reactions = new String[]{'Positive', 'Positive', 'Positive', 'Neutral', 'Neutral', null, null};

        Integer idx = 0;
        for (Id pvpdId : pvpdIds) {
            SObject pvpd = pvpdMap.get(pvpdId);
            if (pvpd == null) continue;

            Id productId = (Id) pvpd.get('ProductId');
            List<SObject> pgList = guidanceByProduct.get(productId);
            if (pgList == null || pgList.isEmpty()) continue;

            // Pick 2-4 random guidance records per PVPD
            Integer count = 2 + pseudoRandom(seed + idx * 37, 3);
            Set<Integer> pickedIndices = new Set<Integer>();
            for (Integer i = 0; i < count && pickedIndices.size() < pgList.size(); i++) {
                Integer pick = pseudoRandom(seed + idx * 53 + i * 17, pgList.size());
                Integer attempts = 0;
                while (pickedIndices.contains(pick) && attempts < 10) {
                    pick = pseudoRandom(seed + idx * 53 + i * 17 + attempts * 7, pgList.size());
                    attempts++;
                }
                pickedIndices.add(pick);
            }

            for (Integer pick : pickedIndices) {
                SObject pg = pgList[pick];
                SObject msg = msgType.newSObject();
                msg.put('ProviderVisitProductDtlId', pvpdId);
                msg.put('MessageRecordId', pg.get('Id'));
                msg.put('OwnerId', ownerId);
                msg.put('SourceSystemName', DEMO_TAG);
                if (!isPlanned) {
                    Integer reactionIdx = pseudoRandom(seed + idx * 71 + pick, reactions.size());
                    if (reactions[reactionIdx] != null) {
                        msg.put('ReactionType', reactions[reactionIdx]);
                    }
                }
                msgs.add(msg);
                idx++;
            }
        }
        return msgs;
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

            // Delete child records first (deepest children first)
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            if (gd.containsKey('providervisitdtlproductmsg')) {
                List<SObject> productMsgs = Database.query(
                    'SELECT Id FROM ProviderVisitDtlProductMsg WHERE VisitId IN :visitIds');
                if (!productMsgs.isEmpty()) {
                    Database.delete(productMsgs, false);
                    deleted += productMsgs.size();
                }
            }

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

    @AuraEnabled
    public static Map<String, Object> deleteVisitBatchForTerritory(Id territoryId) {
        try {
            Integer deleted = 0;
            Integer batchSize = 1500;
            List<String> errors = new List<String>();

            List<Visit> visits = [SELECT Id, Status FROM Visit
                WHERE InstructionDescription = :DEMO_TAG AND TerritoryId = :territoryId LIMIT :batchSize];

            if (visits.isEmpty()) {
                Integer remaining = [SELECT COUNT() FROM Visit WHERE InstructionDescription = :DEMO_TAG AND TerritoryId = :territoryId];
                return new Map<String, Object>{
                    'message' => 'No demo visits to delete for this territory.',
                    'remaining' => remaining
                };
            }

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

            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            if (gd.containsKey('providervisitdtlproductmsg')) {
                List<SObject> productMsgs = Database.query(
                    'SELECT Id FROM ProviderVisitDtlProductMsg WHERE VisitId IN :visitIds');
                if (!productMsgs.isEmpty()) {
                    Database.delete(productMsgs, false);
                    deleted += productMsgs.size();
                }
            }

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

            Integer remaining = [SELECT COUNT() FROM Visit WHERE InstructionDescription = :DEMO_TAG AND TerritoryId = :territoryId];
            String msg = 'Deleted ' + visitDeleted + '/' + visits.size() + ' visits + ' + (deleted - visitDeleted) + ' child records. ' + remaining + ' remaining.';
            if (!errors.isEmpty()) msg += ' | ' + String.join(errors, '; ');
            return new Map<String, Object>{
                'message' => msg,
                'remaining' => remaining
            };
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting territory visits: ' + e.getMessage());
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

    @AuraEnabled
    public static String createProductGuidance() {
        List<String> details = new List<String>();
        List<String> errors = new List<String>();

        try {
            details.add('HEADER:Step 1 — Loading country brand products');
            Map<String, List<Id>> countryBrands = loadBrandsByCountry();
            if (countryBrands.isEmpty()) {
                throw new AuraHandledException('No country brand products found');
            }
            Integer productCount = 0;
            for (List<Id> ids : countryBrands.values()) productCount += ids.size();
            details.add('SUCCESS:Found ' + productCount + ' country brand products across ' + countryBrands.size() + ' countries');

            details.add('HEADER:Step 2 — Building product guidance messages');
            Map<String, Map<String, List<String>>> messages = getLocalizedMessages();

            List<SObject> guidanceRecords = new List<SObject>();
            Schema.SObjectType pgType = Schema.getGlobalDescribe().get('ProductGuidance');

            for (String cc : countryBrands.keySet()) {
                List<Id> brandIds = countryBrands.get(cc);
                for (Id brandId : brandIds) {
                    String brandName = getBrandNameForId(brandId, countryBrands, cc);
                    Map<String, List<String>> brandMessages = messages.get(brandName + '_' + cc);
                    if (brandMessages == null) {
                        brandMessages = messages.get(brandName + '_US');
                    }
                    if (brandMessages == null) continue;

                    List<String> msgs = brandMessages.get('messages');
                    List<String> objectives = brandMessages.get('objectives');
                    String[] themes = new String[]{'Efficacy', 'Safety', 'Differentiation', 'Patient Experience', 'Convenience'};

                    for (Integer i = 0; i < msgs.size() && i < 5; i++) {
                        SObject pg = pgType.newSObject();
                        pg.put('Name', brandName + ' ' + cc + ' - ' + themes[i]);
                        pg.put('ProductReferenceRecordId', brandId);
                        pg.put('Type', 'Message');
                        pg.put('ContentText', msgs[i]);
                        pg.put('Priority', i + 1);
                        pg.put('GroupName', 'Key Messages');
                        pg.put('GroupSequence', i + 1);
                        pg.put('IsActive', true);
                        pg.put('EffectiveStartDate', Date.newInstance(2025, 1, 1));
                        pg.put('SourceSystemName', DEMO_TAG);
                        guidanceRecords.add(pg);
                    }

                    String[] objThemes = new String[]{'Positioning', 'Patient Identification'};
                    for (Integer i = 0; i < objectives.size() && i < 2; i++) {
                        SObject pgObj = pgType.newSObject();
                        pgObj.put('Name', brandName + ' ' + cc + ' - ' + objThemes[i]);
                        pgObj.put('ProductReferenceRecordId', brandId);
                        pgObj.put('Type', 'Objective');
                        pgObj.put('ContentText', objectives[i]);
                        pgObj.put('Priority', msgs.size() + i + 1);
                        pgObj.put('GroupName', 'Call Objectives');
                        pgObj.put('GroupSequence', i + 1);
                        pgObj.put('IsActive', true);
                        pgObj.put('EffectiveStartDate', Date.newInstance(2025, 1, 1));
                        pgObj.put('SourceSystemName', DEMO_TAG);
                        guidanceRecords.add(pgObj);
                    }
                }
            }
            details.add('SUCCESS:Built ' + guidanceRecords.size() + ' product guidance records');

            details.add('HEADER:Step 3 — Inserting records');
            Database.SaveResult[] results = Database.insert(guidanceRecords, false);
            Integer successCount = 0;
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    successCount++;
                } else {
                    for (Database.Error err : sr.getErrors()) {
                        errors.add(err.getMessage());
                    }
                }
            }
            details.add('SUCCESS:Inserted ' + successCount + ' of ' + guidanceRecords.size() + ' records');

            details.add('HEADER:Step 4 — Sharing with territory groups');
            shareGuidanceWithTerritoryGroups(guidanceRecords, results, countryBrands, details, errors);

            Map<String, Object> response = new Map<String, Object>{
                'summary' => 'Created ' + successCount + ' Product Guidance records',
                'details' => details,
                'errors' => errors
            };
            return JSON.serialize(response);

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }

    private static void shareGuidanceWithTerritoryGroups(
        List<SObject> guidanceRecords, Database.SaveResult[] insertResults,
        Map<String, List<Id>> countryBrands, List<String> details, List<String> errors
    ) {
        Map<Id, String> brandIdToCountry = new Map<Id, String>();
        for (String cc : countryBrands.keySet()) {
            for (Id brandId : countryBrands.get(cc)) {
                brandIdToCountry.put(brandId, cc);
            }
        }

        List<SObject> successRecords = new List<SObject>();
        for (Integer i = 0; i < insertResults.size(); i++) {
            if (insertResults[i].isSuccess()) successRecords.add(guidanceRecords[i]);
        }
        if (successRecords.isEmpty()) return;

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

        Map<String, Set<Id>> countryToLeafIds = new Map<String, Set<Id>>();
        for (Territory2 t : leafTerrs) {
            String cc = extractCountryCode(t.Name);
            if (cc == null) continue;
            if (!countryToLeafIds.containsKey(cc)) countryToLeafIds.put(cc, new Set<Id>());
            countryToLeafIds.get(cc).add(t.Id);
        }

        Set<Id> allLeafIds = new Set<Id>();
        for (Set<Id> ids : countryToLeafIds.values()) allLeafIds.addAll(ids);
        Map<Id, Id> terrToGroup = new Map<Id, Id>();
        for (Group g : [SELECT Id, RelatedId FROM Group WHERE Type = 'Territory' AND RelatedId IN :allLeafIds]) {
            terrToGroup.put(g.RelatedId, g.Id);
        }

        List<SObject> shares = new List<SObject>();
        Schema.SObjectType shareType = Schema.getGlobalDescribe().get('ProductGuidanceShare');
        if (shareType == null) {
            errors.add('ProductGuidanceShare object not found');
            return;
        }

        for (SObject pg : successRecords) {
            Id brandId = (Id) pg.get('ProductReferenceRecordId');
            String cc = brandIdToCountry.get(brandId);
            if (cc == null) continue;
            Set<Id> leafIds = countryToLeafIds.get(cc);
            if (leafIds == null) continue;
            for (Id leafId : leafIds) {
                Id groupId = terrToGroup.get(leafId);
                if (groupId == null) continue;
                SObject share = shareType.newSObject();
                share.put('ParentId', pg.Id);
                share.put('UserOrGroupId', groupId);
                share.put('AccessLevel', 'Read');
                share.put('RowCause', 'Manual');
                shares.add(share);
            }
        }

        if (!shares.isEmpty()) {
            Database.SaveResult[] shareResults = Database.insert(shares, false);
            Integer shareSuccess = 0;
            for (Database.SaveResult sr : shareResults) {
                if (sr.isSuccess()) shareSuccess++;
                else if (errors.size() < 15) errors.add('Share: ' + sr.getErrors()[0].getMessage());
            }
            details.add('SUCCESS:Shared with ' + shareSuccess + ' territory group assignments');
        } else {
            details.add('SUCCESS:No territory groups found to share with');
        }
    }

    @AuraEnabled
    public static Map<String, Object> deleteProductGuidance() {
        try {
            String escaped = String.escapeSingleQuotes(DEMO_TAG);
            List<SObject> records = Database.query(
                'SELECT Id FROM ProductGuidance WHERE SourceSystemName = \'' + escaped + '\' LIMIT 2000');
            Integer remaining = Database.countQuery(
                'SELECT COUNT() FROM ProductGuidance WHERE SourceSystemName = \'' + escaped + '\'');

            if (records.isEmpty()) {
                return new Map<String, Object>{
                    'message' => 'No demo product guidance records to delete',
                    'remaining' => 0
                };
            }

            Database.DeleteResult[] results = Database.delete(records, false);
            Integer deleted = 0;
            List<String> errs = new List<String>();
            for (Database.DeleteResult dr : results) {
                if (dr.isSuccess()) {
                    deleted++;
                } else {
                    for (Database.Error e : dr.getErrors()) {
                        errs.add(e.getMessage());
                    }
                }
            }

            String msg = 'Deleted ' + deleted + ' records';
            if (!errs.isEmpty()) {
                msg += ' | Errors: ' + String.join(errs, '; ');
            }

            return new Map<String, Object>{
                'message' => msg,
                'remaining' => remaining - deleted
            };
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    private static String getBrandNameForId(Id brandId, Map<String, List<Id>> countryBrands, String cc) {
        List<SObject> brands = Database.query(
            'SELECT Id, Name FROM LifeSciMarketableProduct WHERE Id = \'' + brandId + '\'');
        if (brands.isEmpty()) return '';
        String fullName = (String) brands[0].get('Name');
        for (String baseName : BRAND_NAMES) {
            if (fullName.startsWith(baseName)) return baseName;
        }
        return fullName;
    }

    private static Map<String, Map<String, List<String>>> getLocalizedMessages() {
        Map<String, Map<String, List<String>>> m = new Map<String, Map<String, List<String>>>();

        // ── Immunexis (zelanumab) — autoimmune (RA, PsA) ──
        m.put('Immunexis_US', new Map<String, List<String>>{
            'messages' => new List<String>{
                'SHIELD-RA Phase 3: 68% ACR50 at Week 24 with zelanumab vs 31% placebo. Dual IL-23/IL-17A blockade delivers superior joint protection in moderate-to-severe RA.',
                'Favorable safety: serious infection rate 1.8/100 PY, no new TB signals, mild injection-site reactions in <5% of patients. No mandatory lab monitoring required.',
                'Only bispecific targeting both IL-23 and IL-17A in a single molecule — addresses upstream and downstream inflammation simultaneously, unlike sequential monotherapy.',
                'In PRISM Registry real-world data, 74% of PsA patients on zelanumab reported meaningful improvement in daily activities at 12 months. Patients rank reduced morning stiffness as their top quality-of-life gain.',
                'Ready-to-use prefilled pen, room-temperature stable for 14 days. Patients self-administer every 4 weeks — half the injection frequency of leading IL-17A inhibitors.'
            },
            'objectives' => new List<String>{
                'Position zelanumab as first-line biologic after csDMARD inadequate response. Secure formulary discussion with rheumatology department head.',
                'Identify patients with moderate-to-severe RA who have failed at least one csDMARD or show early radiographic progression. Flag candidates during chart review with the care team.'
            }
        });
        m.put('Immunexis_GB', new Map<String, List<String>>{
            'messages' => new List<String>{
                'SHIELD-RA Phase 3: 68% ACR50 at Week 24 with zelanumab versus 31% placebo. Dual IL-23/IL-17A blockade offers superior joint protection in moderate-to-severe RA.',
                'Favourable safety profile: serious infection rate 1.8/100 PY, no new TB signals, mild injection-site reactions in fewer than 5% of patients. No mandatory lab monitoring.',
                'The only bispecific targeting both IL-23 and IL-17A in a single molecule — addressing upstream and downstream inflammation simultaneously, unlike sequential monotherapy.',
                'PRISM Registry real-world data: 74% of PsA patients on zelanumab reported meaningful improvement in daily activities at 12 months. Reduced morning stiffness rated as the top quality-of-life benefit.',
                'Ready-to-use prefilled pen, room-temperature stable for 14 days. Patients self-administer every 4 weeks — half the injection frequency of leading IL-17A inhibitors.'
            },
            'objectives' => new List<String>{
                'Position zelanumab as first-line biologic following inadequate response to csDMARDs. Arrange formulary review with rheumatology department lead.',
                'Identify patients with moderate-to-severe RA who have failed at least one csDMARD or show early radiographic progression. Coordinate chart review with the rheumatology care team.'
            }
        });
        m.put('Immunexis_FR', new Map<String, List<String>>{
            'messages' => new List<String>{
                'SHIELD-RA Phase 3 : ACR50 de 68% a S24 sous zelanumab contre 31% placebo. Le double blocage IL-23/IL-17A offre une protection articulaire superieure dans la PR moderee a severe.',
                'Profil de securite favorable : infections graves 1,8/100 PA, aucun signal TB, reactions au site d injection legeres chez <5% des patients. Pas de suivi biologique obligatoire.',
                'Seul bispecifique ciblant IL-23 et IL-17A en une seule molecule — agit simultanement sur l inflammation en amont et en aval, contrairement a la monotherapie sequentielle.',
                'Donnees en vie reelle PRISM : 74% des patients PsA sous zelanumab rapportent une amelioration significative des activites quotidiennes a 12 mois. La reduction de la raideur matinale est le benefice le plus cite.',
                'Stylo prerempli pret a l emploi, stable a temperature ambiante pendant 14 jours. Auto-injection toutes les 4 semaines — deux fois moins frequent que les anti-IL-17A de reference.'
            },
            'objectives' => new List<String>{
                'Positionner zelanumab comme biologique de 1re intention apres reponse inadequate aux csDMARD. Obtenir discussion au comite du medicament avec le chef de rhumatologie.',
                'Identifier les patients atteints de PR moderee a severe en echec d au moins un csDMARD ou presentant une progression radiographique precoce. Coordonner la revue de dossiers avec l equipe de soins.'
            }
        });
        m.put('Immunexis_DE', new Map<String, List<String>>{
            'messages' => new List<String>{
                'SHIELD-RA Phase 3: 68% ACR50 in Woche 24 unter Zelanumab vs. 31% Placebo. Duale IL-23/IL-17A-Blockade bietet ueberlegenen Gelenkschutz bei mittelschwerer bis schwerer RA.',
                'Guenstiges Sicherheitsprofil: schwere Infektionen 1,8/100 PJ, keine neuen TB-Signale, leichte Reaktionen an der Injektionsstelle bei <5% der Patienten. Kein obligatorisches Labormonitoring.',
                'Einziger bispezifischer Antikoerper gegen IL-23 und IL-17A in einem Molekuel — adressiert gleichzeitig vorgelagerte und nachgelagerte Entzuendung, im Gegensatz zur sequenziellen Monotherapie.',
                'PRISM-Registerdaten: 74% der PsA-Patienten unter Zelanumab berichten nach 12 Monaten ueber eine bedeutsame Verbesserung im Alltag. Reduzierte Morgensteifigkeit wird als wichtigster Lebensqualitaetsgewinn genannt.',
                'Gebrauchsfertiger Fertigpen, 14 Tage bei Raumtemperatur stabil. Selbstinjektion alle 4 Wochen — halb so haeufig wie fuehrende IL-17A-Inhibitoren.'
            },
            'objectives' => new List<String>{
                'Zelanumab als Erstlinien-Biologikum nach unzureichendem Ansprechen auf csDMARDs positionieren. Aufnahme in die Hausliste mit dem Leiter der Rheumatologie besprechen.',
                'Patienten mit mittelschwerer bis schwerer RA identifizieren, die auf mindestens ein csDMARD nicht angesprochen haben oder fruehere Roentgenprogression zeigen. Aktenreview mit dem Behandlungsteam koordinieren.'
            }
        });
        m.put('Immunexis_IT', new Map<String, List<String>>{
            'messages' => new List<String>{
                'SHIELD-RA Fase 3: ACR50 del 68% alla settimana 24 con zelanumab vs 31% placebo. Il doppio blocco IL-23/IL-17A offre protezione articolare superiore nell AR moderata-grave.',
                'Profilo di sicurezza favorevole: infezioni gravi 1,8/100 PA, nessun segnale TB, reazioni lievi nel sito di iniezione in <5% dei pazienti. Nessun monitoraggio di laboratorio obbligatorio.',
                'Unico bispecifico che colpisce sia IL-23 che IL-17A in un unica molecola — agisce simultaneamente sull infiammazione a monte e a valle, a differenza della monoterapia sequenziale.',
                'Dati real-world PRISM: il 74% dei pazienti PsA in trattamento con zelanumab riporta un miglioramento significativo nelle attivita quotidiane a 12 mesi. La riduzione della rigidita mattutina e il beneficio piu citato.',
                'Penna preriempita pronta all uso, stabile a temperatura ambiente per 14 giorni. Autosomministrazione ogni 4 settimane — meta della frequenza degli inibitori IL-17A di riferimento.'
            },
            'objectives' => new List<String>{
                'Posizionare zelanumab come biologico di prima linea dopo risposta inadeguata ai csDMARD. Ottenere presentazione al comitato terapeutico con il responsabile di reumatologia.',
                'Identificare pazienti con AR moderata-grave in fallimento di almeno un csDMARD o con progressione radiografica precoce. Coordinare la revisione delle cartelle con il team di cura.'
            }
        });
        m.put('Immunexis_ES', new Map<String, List<String>>{
            'messages' => new List<String>{
                'SHIELD-RA Fase 3: ACR50 del 68% en semana 24 con zelanumab frente al 31% con placebo. El doble bloqueo IL-23/IL-17A ofrece proteccion articular superior en AR moderada a grave.',
                'Perfil de seguridad favorable: infecciones graves 1,8/100 PA, sin senales de TB, reacciones leves en sitio de inyeccion en <5% de pacientes. Sin monitorizacion analitica obligatoria.',
                'Unico biespecifico dirigido contra IL-23 e IL-17A en una sola molecula — aborda la inflamacion aguas arriba y aguas abajo simultaneamente, a diferencia de la monoterapia secuencial.',
                'Datos en vida real PRISM: 74% de pacientes con APs bajo zelanumab reportan mejoria significativa en actividades diarias a los 12 meses. La reduccion de la rigidez matutina es el beneficio mas valorado.',
                'Pluma precargada lista para usar, estable a temperatura ambiente durante 14 dias. Autoinyeccion cada 4 semanas — la mitad de frecuencia que los inhibidores IL-17A de referencia.'
            },
            'objectives' => new List<String>{
                'Posicionar zelanumab como biologico de primera linea tras respuesta inadecuada a FAMEsc. Conseguir revision en comite de farmacia con el jefe de reumatologia.',
                'Identificar pacientes con AR moderada a grave que hayan fallado al menos un FAMEsc o muestren progresion radiografica temprana. Coordinar revision de historiales con el equipo asistencial.'
            }
        });
        m.put('Immunexis_JP', new Map<String, List<String>>{
            'messages' => new List<String>{
                'SHIELD-RA第3相試験：ゼラヌマブ投与24週時ACR50達成率68%（プラセボ31%）。IL-23/IL-17Aデュアルブロックが中等度～重度RAで優れた関節保護を実現。',
                '良好な安全性：重篤感染率1.8/100人年、新規TBシグナルなし、注射部位反応は5%未満で軽度。定期的な臨床検査モニタリング不要。',
                'IL-23とIL-17Aの両方を単一分子で標的とする唯一のバイスペシフィック抗体——逐次単剤療法と異なり、上流・下流の炎症を同時に制御。',
                'PRISMレジストリ実臨床データ：ゼラヌマブ投与PsA患者の74%が12ヶ月時に日常活動の有意な改善を報告。朝のこわばり軽減が最も評価されるQOL向上。',
                'すぐに使えるプレフィルドペン、室温14日間安定。4週に1回の自己注射——主要IL-17A阻害剤の半分の頻度。'
            },
            'objectives' => new List<String>{
                'csDMARD効果不十分例に対する第一選択バイオ製剤としてゼラヌマブを位置づける。リウマチ科部長との採用検討会議を確保。',
                'csDMARD1剤以上無効または早期X線進行を示す中等度～重度RA患者を特定。診療チームとのカルテレビューを調整する。'
            }
        });
        m.put('Immunexis_KR', new Map<String, List<String>>{
            'messages' => new List<String>{
                'SHIELD-RA 3상: 젤라누맙 24주차 ACR50 68%(위약 31%). IL-23/IL-17A 이중 차단이 중등도~중증 RA에서 우수한 관절 보호 효과를 제공.',
                '양호한 안전성: 중증 감염률 1.8/100인년, 새로운 TB 신호 없음, 주사 부위 반응 5% 미만으로 경미. 필수 검사 모니터링 불필요.',
                'IL-23과 IL-17A를 단일 분자로 동시 표적하는 유일한 이중특이항체 — 순차적 단독요법과 달리 상류·하류 염증을 동시 억제.',
                'PRISM 레지스트리 실제 데이터: 젤라누맙 투여 PsA 환자의 74%가 12개월 시점에서 일상 활동의 의미 있는 개선을 보고. 아침 경직 감소가 가장 높은 삶의 질 개선.',
                '바로 사용 가능한 프리필드 펜, 실온 14일 안정. 4주 1회 자가 주사 — 주요 IL-17A 억제제의 절반 빈도.'
            },
            'objectives' => new List<String>{
                'csDMARD 불충분 반응 후 1차 생물학적 제제로 젤라누맙을 포지셔닝. 류마티스내과 과장과 약물심의위원회 논의 확보.',
                'csDMARD 1제 이상 실패 또는 초기 방사선학적 진행을 보이는 중등도~중증 RA 환자 식별. 진료팀과 차트 리뷰 조율.'
            }
        });
        m.put('Immunexis_BR', new Map<String, List<String>>{
            'messages' => new List<String>{
                'SHIELD-RA Fase 3: ACR50 de 68% na semana 24 com zelanumab vs 31% placebo. O duplo bloqueio IL-23/IL-17A oferece protecao articular superior na AR moderada a grave.',
                'Perfil de seguranca favoravel: infeccoes graves 1,8/100 PA, sem sinais de TB, reacoes leves no local de injecao em <5% dos pacientes. Sem monitoramento laboratorial obrigatorio.',
                'Unico biespecifico que atinge IL-23 e IL-17A em uma unica molecula — aborda inflamacao a montante e a jusante simultaneamente, diferente da monoterapia sequencial.',
                'Dados do mundo real PRISM: 74% dos pacientes com APs em zelanumab relatam melhora significativa nas atividades diarias em 12 meses. Reducao da rigidez matinal e o beneficio mais citado.',
                'Caneta preenchida pronta para uso, estavel em temperatura ambiente por 14 dias. Autoinjecao a cada 4 semanas — metade da frequencia dos inibidores IL-17A de referencia.'
            },
            'objectives' => new List<String>{
                'Posicionar zelanumab como biologico de primeira linha apos resposta inadequada a csDMARDs. Garantir discussao no comite de farmacia com o chefe de reumatologia.',
                'Identificar pacientes com AR moderada a grave que falharam pelo menos um csDMARD ou mostram progressao radiografica precoce. Coordenar revisao de prontuarios com a equipe de cuidados.'
            }
        });
        m.put('Immunexis_MX', new Map<String, List<String>>{
            'messages' => new List<String>{
                'SHIELD-RA Fase 3: ACR50 del 68% en semana 24 con zelanumab vs 31% placebo. El doble bloqueo IL-23/IL-17A brinda proteccion articular superior en AR moderada a severa.',
                'Perfil de seguridad favorable: infecciones graves 1,8/100 PA, sin senales de TB, reacciones leves en sitio de inyeccion en <5% de pacientes. Sin monitoreo de laboratorio obligatorio.',
                'Unico biespecifico dirigido contra IL-23 e IL-17A en una sola molecula — aborda la inflamacion aguas arriba y aguas abajo simultaneamente, a diferencia de la monoterapia secuencial.',
                'Datos en vida real PRISM: 74% de pacientes con APs bajo zelanumab reportan mejoria significativa en actividades diarias a 12 meses. La reduccion de la rigidez matutina es el beneficio mas valorado.',
                'Pluma precargada lista para usar, estable a temperatura ambiente durante 14 dias. Autoinyeccion cada 4 semanas — la mitad de frecuencia que los inhibidores IL-17A de referencia.'
            },
            'objectives' => new List<String>{
                'Posicionar zelanumab como biologico de primera linea tras respuesta inadecuada a FAMEsc. Asegurar presentacion en comite de farmacia con el jefe de reumatologia.',
                'Identificar pacientes con AR moderada a severa que hayan fallado al menos un FAMEsc o muestren progresion radiografica temprana. Coordinar revision de expedientes con el equipo medico.'
            }
        });
        m.put('Immunexis_AR', new Map<String, List<String>>{
            'messages' => new List<String>{
                'SHIELD-RA Fase 3: ACR50 del 68% en semana 24 con zelanumab vs 31% placebo. El doble bloqueo IL-23/IL-17A ofrece proteccion articular superior en AR moderada a severa.',
                'Perfil de seguridad favorable: infecciones graves 1,8/100 PA, sin senales de TB, reacciones leves en sitio de inyeccion en <5% de pacientes. Sin monitoreo de laboratorio obligatorio.',
                'Unico biespecifico dirigido contra IL-23 e IL-17A en una sola molecula — aborda simultaneamente la inflamacion aguas arriba y aguas abajo, a diferencia de la monoterapia secuencial.',
                'Datos en vida real PRISM: 74% de pacientes con APs bajo zelanumab reportan mejoria significativa en actividades diarias a los 12 meses. La reduccion de la rigidez matutina es el beneficio mas valorado.',
                'Pluma precargada lista para usar, estable a temperatura ambiente durante 14 dias. Autoinyeccion cada 4 semanas — la mitad de frecuencia que los inhibidores IL-17A de referencia.'
            },
            'objectives' => new List<String>{
                'Posicionar zelanumab como biologico de primera linea tras respuesta inadecuada a FAMEsc. Conseguir revision en comite de farmacia con el jefe de reumatologia.',
                'Identificar pacientes con AR moderada a severa que hayan fallado al menos un FAMEsc o muestren progresion radiografica temprana. Coordinar revision de historiales con el equipo de atencion.'
            }
        });

        // ── Immunonco (vorastinib) — oncology (NSCLC, HCC) ──
        m.put('Immunonco_US', new Map<String, List<String>>{
            'messages' => new List<String>{
                'BEACON-LUNG Phase 3: median PFS 11.2 months vs 5.4 months with pembrolizumab alone in PD-L1 >=50% NSCLC. 42% confirmed ORR in first-line setting.',
                'Manageable irAE profile: Grade >=3 events in 18% of patients. No unexpected hepatotoxicity. Median time to irAE onset: 6 weeks, responsive to standard steroid protocols.',
                'Dual PD-1/TIGIT blockade overcomes adaptive resistance seen with anti-PD-1 monotherapy. TIGIT+ NK cell reinvigoration drives responses even in PD-L1-low tumors.',
                'BEACON-HCC Phase 2: 28% ORR in post-atezolizumab-bevacizumab HCC patients, a population with no approved second-line IO. Median duration of response: 14.1 months.',
                'Fixed-dose IV infusion every 3 weeks, no weight-based dosing. Compatible with standard oncology infusion chairs — 30-minute administration after the first cycle.'
            },
            'objectives' => new List<String>{
                'Drive vorastinib adoption as preferred first-line IO in PD-L1 >=50% NSCLC. Secure tumor board presentation slot to review BEACON-LUNG data.',
                'Identify advanced NSCLC patients with PD-L1 >=50% who are treatment-naive or progressing on current IO. Review molecular profiling reports with the oncology team to flag candidates.'
            }
        });
        m.put('Immunonco_GB', new Map<String, List<String>>{
            'messages' => new List<String>{
                'BEACON-LUNG Phase 3: median PFS 11.2 months versus 5.4 months with pembrolizumab alone in PD-L1 >=50% NSCLC. 42% confirmed ORR in the first-line setting.',
                'Manageable irAE profile: Grade >=3 events in 18% of patients. No unexpected hepatotoxicity signal. Median time to irAE onset: 6 weeks, responsive to standard steroid protocols.',
                'Dual PD-1/TIGIT blockade overcomes adaptive resistance observed with anti-PD-1 monotherapy. TIGIT+ NK cell reinvigoration drives responses even in PD-L1-low tumours.',
                'BEACON-HCC Phase 2: 28% ORR in post-atezolizumab-bevacizumab HCC patients with no approved second-line IO. Median duration of response: 14.1 months.',
                'Fixed-dose IV infusion every 3 weeks, no weight-based dosing. Compatible with standard oncology infusion chairs — 30-minute administration after the first cycle.'
            },
            'objectives' => new List<String>{
                'Drive vorastinib adoption as preferred first-line IO in PD-L1 >=50% NSCLC. Secure tumour board presentation to review BEACON-LUNG data with the MDT.',
                'Identify advanced NSCLC patients with PD-L1 >=50% who are treatment-naive or progressing on current IO. Review molecular profiling reports with the oncology MDT to flag candidates.'
            }
        });
        m.put('Immunonco_FR', new Map<String, List<String>>{
            'messages' => new List<String>{
                'BEACON-LUNG Phase 3 : SG mediane 11,2 mois vs 5,4 mois sous pembrolizumab seul dans le CBNPC PD-L1 >=50%. TRO confirme de 42% en premiere ligne.',
                'Profil d EI immuno-medies gerable : evenements grade >=3 chez 18% des patients. Pas d hepatotoxicite inattendue. Delai median : 6 semaines, repondant aux protocoles corticoides.',
                'Le double blocage PD-1/TIGIT surmonte la resistance adaptative sous anti-PD-1. La reactivation des cellules NK TIGIT+ induit des reponses meme dans les tumeurs PD-L1 faibles.',
                'BEACON-HCC Phase 2 : TRO de 28% chez les patients CHC post-atezolizumab-bevacizumab, sans IO de 2e ligne approuvee. Duree mediane de reponse : 14,1 mois.',
                'Perfusion IV a dose fixe toutes les 3 semaines, sans ajustement au poids. Compatible avec les fauteuils de perfusion standard — 30 minutes apres le premier cycle.'
            },
            'objectives' => new List<String>{
                'Promouvoir vorastinib comme IO de 1re ligne dans le CBNPC PD-L1 >=50%. Obtenir une presentation en RCP pour les donnees BEACON-LUNG.',
                'Identifier les patients CBNPC avance PD-L1 >=50% naifs de traitement ou en progression sous IO. Revoir les profils moleculaires avec l equipe d oncologie pour reperer les candidats.'
            }
        });
        m.put('Immunonco_DE', new Map<String, List<String>>{
            'messages' => new List<String>{
                'BEACON-LUNG Phase 3: medianes PFS 11,2 Monate vs. 5,4 Monate unter Pembrolizumab allein bei PD-L1 >=50% NSCLC. 42% bestaetigte ORR in der Erstlinie.',
                'Handhabbares irAE-Profil: Grad >=3 Ereignisse bei 18% der Patienten. Keine unerwartete Hepatotoxizitaet. Mediane Zeit bis irAE-Onset: 6 Wochen, Ansprechen auf Standard-Steroid-Protokolle.',
                'Duale PD-1/TIGIT-Blockade ueberwindet adaptive Resistenz unter Anti-PD-1-Monotherapie. TIGIT+ NK-Zell-Reaktivierung erzielt Ansprechen auch bei PD-L1-niedrigen Tumoren.',
                'BEACON-HCC Phase 2: 28% ORR bei Post-Atezolizumab-Bevacizumab-HCC-Patienten ohne zugelassene Zweitlinien-IO. Mediane Ansprechdauer: 14,1 Monate.',
                'Fixdosis-IV-Infusion alle 3 Wochen, keine gewichtsbasierte Dosierung. Kompatibel mit Standard-Infusionsstuehlen — 30 Minuten Verabreichung nach dem ersten Zyklus.'
            },
            'objectives' => new List<String>{
                'Vorastinib als bevorzugte Erstlinien-IO bei PD-L1 >=50% NSCLC etablieren. Vorstellung im Tumorboard zur Besprechung der BEACON-LUNG-Daten sichern.',
                'Fortgeschrittene NSCLC-Patienten mit PD-L1 >=50% identifizieren, die therapienaiv sind oder unter aktueller IO progredieren. Molekulare Profilberichte mit dem Onkologie-Team pruefen.'
            }
        });
        m.put('Immunonco_IT', new Map<String, List<String>>{
            'messages' => new List<String>{
                'BEACON-LUNG Fase 3: PFS mediana 11,2 mesi vs 5,4 mesi con pembrolizumab in monoterapia nel NSCLC PD-L1 >=50%. ORR confermato del 42% in prima linea.',
                'Profilo irAE gestibile: eventi grado >=3 nel 18% dei pazienti. Nessuna epatotossicita inattesa. Tempo mediano all insorgenza: 6 settimane, responsivo a protocolli steroidei standard.',
                'Il doppio blocco PD-1/TIGIT supera la resistenza adattativa con anti-PD-1 in monoterapia. La riattivazione delle cellule NK TIGIT+ genera risposte anche nei tumori PD-L1 bassi.',
                'BEACON-HCC Fase 2: ORR del 28% in pazienti HCC post-atezolizumab-bevacizumab, senza IO di seconda linea approvata. Durata mediana della risposta: 14,1 mesi.',
                'Infusione IV a dose fissa ogni 3 settimane, senza dosaggio basato sul peso. Compatibile con le poltrone di infusione standard — 30 minuti dopo il primo ciclo.'
            },
            'objectives' => new List<String>{
                'Promuovere vorastinib come IO di prima linea nel NSCLC PD-L1 >=50%. Ottenere slot al tumor board per i dati BEACON-LUNG.',
                'Identificare pazienti NSCLC avanzato con PD-L1 >=50% naive o in progressione sotto IO. Rivedere i profili molecolari con il team oncologico per individuare i candidati.'
            }
        });
        m.put('Immunonco_ES', new Map<String, List<String>>{
            'messages' => new List<String>{
                'BEACON-LUNG Fase 3: SLP mediana 11,2 meses vs 5,4 meses con pembrolizumab solo en CPNM PD-L1 >=50%. TRO confirmada del 42% en primera linea.',
                'Perfil de irAE manejable: eventos grado >=3 en 18% de pacientes. Sin hepatotoxicidad inesperada. Tiempo mediano hasta irAE: 6 semanas, responde a protocolos de corticoides.',
                'El doble bloqueo PD-1/TIGIT supera la resistencia adaptativa del anti-PD-1 en monoterapia. La reactivacion de celulas NK TIGIT+ genera respuestas incluso en tumores PD-L1 bajos.',
                'BEACON-HCC Fase 2: TRO del 28% en pacientes CHC post-atezolizumab-bevacizumab, sin IO de segunda linea aprobada. Duracion mediana de respuesta: 14,1 meses.',
                'Infusion IV a dosis fija cada 3 semanas, sin ajuste por peso. Compatible con sillones de infusion estandar — 30 minutos de administracion tras el primer ciclo.'
            },
            'objectives' => new List<String>{
                'Impulsar vorastinib como IO de primera linea en CPNM PD-L1 >=50%. Asegurar presentacion en comite de tumores para datos BEACON-LUNG.',
                'Identificar pacientes con CPNM avanzado PD-L1 >=50% naive o en progresion bajo IO actual. Revisar perfiles moleculares con el equipo de oncologia para detectar candidatos.'
            }
        });
        m.put('Immunonco_JP', new Map<String, List<String>>{
            'messages' => new List<String>{
                'BEACON-LUNG第3相：PD-L1>=50% NSCLCでボラスチニブPFS中央値11.2ヶ月（ペムブロリズマブ単独5.4ヶ月）。一次治療確認ORR 42%。',
                '管理可能なirAE：Grade>=3イベント18%。予期しない肝毒性なし。irAE発現中央値6週間、標準ステロイドプロトコルに反応。',
                'PD-1/TIGITデュアルブロックが抗PD-1単剤の適応耐性を克服。TIGIT+NK細胞再活性化がPD-L1低発現腫瘍でも奏効を実現。',
                'BEACON-HCC第2相：アテゾリズマブ・ベバシズマブ後HCC患者でORR 28%、承認済み2次IO不在の集団。奏効期間中央値14.1ヶ月。',
                '3週毎の固定用量IV点滴、体重ベースの用量調節不要。標準点滴椅子対応——初回以降30分で投与完了。'
            },
            'objectives' => new List<String>{
                'PD-L1>=50% NSCLCにおけるボラスチニブの1次IO推奨薬としての採用を推進。キャンサーボードでBEACON-LUNGデータ発表枠を確保。',
                'PD-L1>=50%の進行NSCLC治療未施行または現行IO進行中の患者を特定。腫瘍内科チームと分子プロファイリング結果をレビューし候補を選定。'
            }
        });
        m.put('Immunonco_KR', new Map<String, List<String>>{
            'messages' => new List<String>{
                'BEACON-LUNG 3상: PD-L1 >=50% NSCLC에서 보라스티닙 PFS 중앙값 11.2개월(펨브롤리주맙 단독 5.4개월). 1차 치료 확인 ORR 42%.',
                '관리 가능한 irAE: Grade >=3 18%. 예상치 못한 간독성 없음. irAE 발현 중앙값 6주, 표준 스테로이드 프로토콜에 반응.',
                'PD-1/TIGIT 이중 차단이 항PD-1 단독요법의 적응 내성을 극복. TIGIT+ NK 세포 재활성화가 PD-L1 저발현 종양에서도 반응 유도.',
                'BEACON-HCC 2상: 아테졸리주맙-베바시주맙 후 HCC 환자에서 ORR 28%, 승인된 2차 IO 부재. 반응 지속 중앙값 14.1개월.',
                '3주마다 고정 용량 IV 주입, 체중 기반 용량 조절 불필요. 표준 항암 주입 의자 호환 — 첫 주기 이후 30분 투여.'
            },
            'objectives' => new List<String>{
                'PD-L1 >=50% NSCLC에서 보라스티닙을 선호 1차 IO로 채택 추진. 종양학 컨퍼런스에서 BEACON-LUNG 데이터 발표 확보.',
                'PD-L1 >=50% 진행성 NSCLC 치료 미경험 또는 현재 IO 진행 환자 식별. 종양내과팀과 분자 프로파일링 보고서를 검토하여 후보 선별.'
            }
        });
        m.put('Immunonco_BR', new Map<String, List<String>>{
            'messages' => new List<String>{
                'BEACON-LUNG Fase 3: SLP mediana 11,2 meses vs 5,4 meses com pembrolizumab isolado no CPCNP PD-L1 >=50%. TRO confirmada de 42% em primeira linha.',
                'Perfil de irAE manejavel: eventos grau >=3 em 18% dos pacientes. Sem hepatotoxicidade inesperada. Tempo mediano ate irAE: 6 semanas, responsivo a corticoides padrao.',
                'O duplo bloqueio PD-1/TIGIT supera a resistencia adaptativa do anti-PD-1 em monoterapia. A reativacao de celulas NK TIGIT+ gera respostas mesmo em tumores PD-L1 baixos.',
                'BEACON-HCC Fase 2: TRO de 28% em pacientes CHC pos-atezolizumab-bevacizumab, sem IO de segunda linha aprovada. Duracao mediana de resposta: 14,1 meses.',
                'Infusao IV em dose fixa a cada 3 semanas, sem dosagem por peso. Compativel com poltronas de infusao padrao — 30 minutos de administracao apos o primeiro ciclo.'
            },
            'objectives' => new List<String>{
                'Impulsionar vorastinib como IO de primeira linha no CPCNP PD-L1 >=50%. Garantir apresentacao no tumor board para dados BEACON-LUNG.',
                'Identificar pacientes com CPCNP avancado PD-L1 >=50% virgem de tratamento ou em progressao sob IO. Revisar relatorios de perfil molecular com a equipe de oncologia.'
            }
        });
        m.put('Immunonco_MX', new Map<String, List<String>>{
            'messages' => new List<String>{
                'BEACON-LUNG Fase 3: SLP mediana 11,2 meses vs 5,4 meses con pembrolizumab solo en CPCNP PD-L1 >=50%. TRO confirmada del 42% en primera linea.',
                'Perfil de irAE manejable: eventos grado >=3 en 18% de pacientes. Sin hepatotoxicidad inesperada. Tiempo mediano hasta irAE: 6 semanas, responde a corticoides estandar.',
                'El doble bloqueo PD-1/TIGIT supera la resistencia adaptativa del anti-PD-1 en monoterapia. La reactivacion de celulas NK TIGIT+ genera respuestas incluso en tumores PD-L1 bajos.',
                'BEACON-HCC Fase 2: TRO del 28% en pacientes CHC post-atezolizumab-bevacizumab, sin IO de segunda linea aprobada. Duracion mediana de respuesta: 14,1 meses.',
                'Infusion IV a dosis fija cada 3 semanas, sin ajuste por peso. Compatible con sillones de infusion estandar — 30 minutos de administracion tras el primer ciclo.'
            },
            'objectives' => new List<String>{
                'Impulsar vorastinib como IO de primera linea en CPCNP PD-L1 >=50%. Asegurar presentacion en comite de tumores para datos BEACON-LUNG.',
                'Identificar pacientes con CPCNP avanzado PD-L1 >=50% naive o en progresion bajo IO actual. Revisar perfiles moleculares con el equipo de oncologia para detectar candidatos.'
            }
        });
        m.put('Immunonco_AR', new Map<String, List<String>>{
            'messages' => new List<String>{
                'BEACON-LUNG Fase 3: SLP mediana 11,2 meses vs 5,4 meses con pembrolizumab solo en CPCNP PD-L1 >=50%. TRO confirmada del 42% en primera linea.',
                'Perfil de irAE manejable: eventos grado >=3 en 18% de pacientes. Sin hepatotoxicidad inesperada. Tiempo mediano hasta irAE: 6 semanas, responde a corticoides estandar.',
                'El doble bloqueo PD-1/TIGIT supera la resistencia adaptativa del anti-PD-1 en monoterapia. La reactivacion de celulas NK TIGIT+ genera respuestas incluso en tumores PD-L1 bajos.',
                'BEACON-HCC Fase 2: TRO del 28% en pacientes CHC post-atezolizumab-bevacizumab, sin IO de segunda linea aprobada. Duracion mediana de respuesta: 14,1 meses.',
                'Infusion IV a dosis fija cada 3 semanas, sin ajuste por peso. Compatible con sillones de infusion estandar — 30 minutos de administracion tras el primer ciclo.'
            },
            'objectives' => new List<String>{
                'Impulsar vorastinib como IO de primera linea en CPCNP PD-L1 >=50%. Asegurar presentacion en comite de tumores para discutir datos BEACON-LUNG.',
                'Identificar pacientes con CPCNP avanzado PD-L1 >=50% naive o en progresion bajo IO actual. Revisar perfiles moleculares con el equipo de oncologia para seleccionar candidatos.'
            }
        });

        return m;
    }

}
