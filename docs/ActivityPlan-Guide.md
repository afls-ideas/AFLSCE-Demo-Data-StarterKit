# Activity Plan & Visit Guide

Everything we learned the hard way about Provider Activity Plans, Visits, and the Activity Plan Progress widget.

## Overview

The Activity Plan Progress widget on mobile shows how many visits a rep has completed vs. their goal. Getting it to work requires:

1. **ProviderActivityMeasureType** records with `Category = 'ActivityGoal'`
2. **ActivityPlan** per territory with goals and measures
3. **Visits** with `Status = 'Completed'` and `Channel` matching the measure type
4. Running the **Calculate Provider Activity Goal Measures** batch job

## ProviderActivityMeasureType

This is the foundation — it tells the system what to count and how. Records are created through Admin Console > Activity Plan > Activity Plan Settings, but the Admin Console UI does **not** expose the `Category` field.

### The Category Problem

The batch job `ActivityPlanCalculationBatch` filters measure types with:

```sql
WHERE IsActive = true AND Category = 'ActivityGoal' AND ActivityObject != null AND ActivityProductField = null
```

Records created through the Admin Console UI may have `Category = null`, which means the batch job silently ignores them — it finds 0 matching types and processes 0 records with no error.

### Querying ProviderActivityMeasureType

This object has unusual visibility rules:
- **Anonymous Apex** returns 0 rows (run in default namespace context)
- **REST API / Tooling API** returns 0 rows
- **Developer Console Query Editor** returns rows (runs in a different context)
- **Managed package code** (`lsc4ce`) can query it normally

You can still **insert and update** records via anonymous Apex — only reads are restricted.

### Visit-Level Measure Types (Required)

These three records must exist with `Category = 'ActivityGoal'` for the batch to calculate visit progress:

```apex
Schema.SObjectType pamtType = Schema.getGlobalDescribe().get('ProviderActivityMeasureType');

SObject inPerson = pamtType.newSObject();
inPerson.put('DeveloperName', 'In_Person_Visit');
inPerson.put('MasterLabel', 'In Person Visit');
inPerson.put('Language', 'en_US');
inPerson.put('ActivityAccountField', 'AccountId');
inPerson.put('ActivityObject', 'Visit');
inPerson.put('ActivityTerritoryField', 'TerritoryId');
inPerson.put('ActivityTypeDtTmField', 'PlannedVisitStartTime');
inPerson.put('ActivityTypeField', 'Channel');
inPerson.put('ActivityTypeFieldValue', 'In-Person');
inPerson.put('ActivityTypeStatusField', 'Status');
inPerson.put('ActivityTypeStatusList', 'Completed');
inPerson.put('ActivityTypSchdStatusList', 'InProgress;Planned');
inPerson.put('Level1RelatedAccountObject', 'Visit');
inPerson.put('Lvl1RelatedAccountObjField', 'AccountId');
inPerson.put('DisplayOrder', 0);
inPerson.put('IsActive', true);
inPerson.put('Category', 'ActivityGoal');
```

Repeat for `Phone_Visit` (`ActivityTypeFieldValue = 'Phone'`, DisplayOrder 1) and `Remote_Visit` (`ActivityTypeFieldValue = 'Remote'`, DisplayOrder 2).

### Product-Level Measure Types

These have `ActivityObject = 'ProviderVisitProdDetailing'` and `ActivityProductField = 'ProductId'`. They are processed by `ProductsActivityPlanCalculationBatch` (a separate batch). The Admin Console creates these with `Category = 'ActivityGoal'` correctly.

## Visit Object

### Required Fields for Calendar Display

| Field | Value | Why |
|---|---|---|
| `TerritoryId` | The territory ID | Without this, visits don't appear on the Planner calendar |
| `Channel` | `'In-Person'`, `'Phone'`, or `'Remote'` | Required for calendar display and must match the measure type's `ActivityTypeFieldValue` |
| `Status` | `'Completed'` | Only completed visits count toward activity plan progress |

### Tagging Demo Visits

The Visit object does **not** have a `SourceSystemName` field. Use `InstructionDescription` (a textarea field) for demo tagging:

```apex
v.put('InstructionDescription', 'AFLSCE-Demo-Data');
```

`ProviderVisit` and `ProviderVisitProdDetailing` do have `SourceSystemName`.

### VisitSubmitDateTime Drives the Progress Chart

The Activity Plan Progress chart plots visits on a timeline using `ProviderVisit.VisitSubmitDateTime`, **not** the visit's `CreatedDate`. If `VisitSubmitDateTime` is null, all visits cluster at `CreatedDate` (today), producing a vertical line instead of a spread-out curve.

```apex
pv.put('VisitSubmitDateTime', visitStartTime.addMinutes(25));
```

### Completed Visits Are Locked

The managed package `VisitLockHandler` trigger prevents editing or deleting visits with `Status = 'Completed'` that have been submitted. This means:

- `Database.delete(visits, false)` silently fails (reports success but records remain)
- You must **disable VisitLockHandler** in Admin Console > Trigger Settings before deleting
- Remember to **re-enable it after** deleting

### Timezone-Aware Scheduling

Visits should be scheduled in local business hours (8am-4pm). Use the timezone map:

```apex
Map<String, String> COUNTRY_TIMEZONE = new Map<String, String>{
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
```

Convert local time to UTC:

```apex
TimeZone localTz = TimeZone.getTimeZone(tz);
Datetime localDt = Datetime.newInstance(weekday, Time.newInstance(localHour, localMin, 0, 0));
Integer offsetMs = localTz.getOffset(localDt);
Datetime utcDt = localDt.addSeconds(-offsetMs / 1000);
```

Without timezone conversion, "5pm local" visits in Italy hit after-hours validation and fail.

### Governor Limits

Managed-package triggers on Visit consume ~11 SOQL queries per DML batch. Structure inserts as 3 bulk DML operations (all Visits, then all ProviderVisits, then all ProviderVisitProdDetailing) rather than per-day loops.

## Activity Plan Structure

```
TimePeriod (Jan 1 - Dec 31)
  └── ActivityPlan (one per territory, Type=AccountGoal, UsageType=ProviderPlanCycle)
        └── ActivityPlanTerritory (links plan to Territory2)
        └── ProviderActivityGoal (one per HCP account)
              └── ProviderActivityGoalMeasure (one per measure type per goal)
```

### Key Fields on ActivityPlan

| Field | Value |
|---|---|
| `Type` | `'AccountGoal'` |
| `UsageType` | `'ProviderPlanCycle'` |
| `Status` | `'Submitted'` (after activation) |
| `IsActive` | `true` |
| `TerritoryList` | Territory2 ID as a string |
| `SourceSystemName` | Demo tag for cleanup |

### Goal Measures Must Reference the Right Type IDs

`ProviderActivityGoalMeasure.ProviderActivityMeasureTypeId` must point to active measure type records with `Category = 'ActivityGoal'`. If you recreate the measure types (new IDs), you must also recreate the activity plans so the measures point to the correct IDs.

## Calculate Provider Activity Goal Measures Batch Job

This batch job recalculates the actual visit counts against goals. It must be run from **Admin Console > Activity Plan > Activity Plan Jobs > Calculate Provider Activity Goal Measures**.

### How It Works

1. Queries `ProviderActivityMeasureType WHERE Category = 'ActivityGoal' AND ActivityProductField = null`
2. For each measure type, runs a separate batch (visible as "ActivityPlanCalculation In_Person_Visit", etc.)
3. Each batch queries `ProviderActivityGoalMeasure` records linked to that type
4. Counts matching visits (by territory, account, status, channel, date range)
5. Updates the actual count on each goal measure

### The Batch Cannot Be Called From Apex

The managed package classes (`lsc4ce.ActivityPlanCalculationBatch`) are `public`, not `global`. `Type.forName()` returns null. The only way to trigger the job is through the Admin Console UI.

## Stuck Job Status

The batch job uses `LifeSciMetadataFieldValue` records to track job state. Two records gate whether a new job can run:

| Name | Purpose |
|---|---|
| `JobStatus` | Tracks whether a batch is running |
| `JobId` | Stores the AsyncApexJob ID of the last run |

### The Stuck Job Error

```
An Instance of Activity Plan Calculation Batch is already in progress
```

This error occurs when:
- `JobStatus` is stuck at `'In Progress'` (common after a failed batch), OR
- `JobId` points to a stale/old job ID that the gatekeeper can't resolve

### Clearing Stuck Jobs

Both `JobId` and `JobStatus` must be cleared — clearing only `JobStatus` is not enough if the old `JobId` is stale:

```apex
List<SObject> records = Database.query(
    'SELECT Id, Name, TextValue FROM LifeSciMetadataFieldValue ' +
    'WHERE Name IN (\'JobStatus\', \'JobId\')');
for (SObject rec : records) {
    rec.put('TextValue', null);
}
Database.update(records, false);
```

The Demo Data Starter Kit includes a "Clear Stuck Job Status" button on the **Provider Activity Plans** tab that does this automatically.

## Debugging Checklist

### Batch job runs but processes 0 records

1. Check `ProviderActivityMeasureType` records have `Category = 'ActivityGoal'` — query from Developer Console (not Apex) since anonymous Apex can't see these records
2. Verify visit-level types exist (ActivityObject = 'Visit', ActivityProductField = null)
3. Verify `ProviderActivityGoalMeasure` records point to the correct `ProviderActivityMeasureTypeId`
4. Verify visits exist with `Status = 'Completed'` and `Channel` matching the measure type's `ActivityTypeFieldValue`
5. Verify visits have `TerritoryId` matching an `ActivityPlanTerritory` record
6. Verify the `TimePeriod` date range covers the visit dates

### Activity Plan Progress shows a vertical line

7. Check `ProviderVisit.VisitSubmitDateTime` is set and spread across the date range (not all null or same date)

### "An Instance of Activity Plan Calculation Batch is already in progress"

8. Clear both `JobStatus` and `JobId` in `LifeSciMetadataFieldValue` (use the "Clear Stuck Job Status" button or the Apex snippet above)

### Visits don't appear on calendar

9. Check `Visit.TerritoryId` is set
10. Check `Visit.Channel` is set to a valid value ('In-Person', 'Phone', 'Remote')

### Delete visits fails silently

11. Disable `VisitLockHandler` in Admin Console > Trigger Settings before deleting
12. Re-enable after deletion
