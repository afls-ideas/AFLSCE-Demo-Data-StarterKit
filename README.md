# AFLSCE Demo Data Starter Kit

> **Disclaimer:** This is **not** an official Salesforce product or repository. It is an independent developer tool intended to accelerate demo setup in sandbox environments. Use at your own risk — you are responsible for testing and validating all generated data in your org before any demo or presentation.

Admin UI for creating realistic demo data for **Agentforce for Life Sciences Cloud Edition** (AFLSCE).

Deploy to any Salesforce org, open the app, and click buttons to populate a full demo environment with territories, accounts, healthcare providers, contact points, and therapy-area scenarios.

## Deploy to Salesforce

<a href="https://githubsfdeploy.herokuapp.com?owner=afls-ideas&repo=AFLSCE-Demo-Data-StarterKit&ref=main">
  <img alt="Deploy to Salesforce" src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

Or deploy via SFDX CLI:

```bash
sf project deploy start --source-dir force-app --target-org YOUR_ORG_ALIAS
```

## Post-Deploy Setup

1. Assign the **AFLSCE Demo Data Admin** permission set to your user
2. Open the **AFLSCE Demo Data** app from the App Launcher
3. Assign the **AFLSCE Demo Account Plan** permission set (for Account & Action Plans tab)
4. Open the **AFLSCE Demo Data** app from the App Launcher
5. Follow the tabs in order: Territory Setup → Accounts & Providers → Contact Points → Product Alignment → Samples → Inventory Replenishment → Scenario Builder → Account & Action Plans → Activity Plans → Visits → Medical Insights → Next Best Customer → Medical Inquiries

## What Gets Created

### Tab 1: Territory Hierarchy
- Territory Model (LSC Territory Model) with 3 types: Geographical, Medical, KAM
- **GLOBAL** root with 11 country hierarchies (US, GB, FR, DE, IT, ES, JP, KR, BR, MX, AR) and regional sub-territories
- **Medical** specialty tree: Oncology, Cardiology, Neurology, Immunology, Primary Care (each with sub-specialties)
- **KAM** tree: Academic Medical Centers, Hospital Systems, Payer/Insurance, IDN, Government/VA

### Tab 2: Accounts & Healthcare Providers

**Accounts (200+ HCOs)**
- Real hospitals, clinics, payers, and pharmacies across US, GB, FR, DE, IT, ES, JP, KR, BR, MX, AR
- Major city in each country has 6-8 HCOs; secondary cities have 2-3 each
- Uses Health_Care_Organization record type for orgs, Health_Care_Provider (PersonAccount) for doctors
- Full billing addresses with country-specific formatting and state/country picklist codes

**Healthcare Providers (380+ HCPs)**
- 20 HCPs in the major city of each country (SF, London, Paris, Berlin, Rome, Madrid, Tokyo, Seoul, São Paulo, Mexico City, Buenos Aires); 4-5 in secondary cities
- HealthcareProviderNpi records with unique 10-digit NPIs (US providers only)
- HealthcareProviderSpecialty records (Oncology, Cardiology, Neurology, etc.)
- CareSpecialty reference records
- ProviderAffiliation linking doctors to their hospitals/clinics

**Territory Assignment**
- Maps all accounts to territories by city (with country-level fallback)
- Creates ObjectTerritory2Association records
- Creates ProviderAcctTerritoryInfo (PATI) records for each account-territory pair
  - `IsTargetedAccount = true`, `IsAvailableOffline = true`, `IsActive = true`
  - Tagged with `SourceSystemName = 'AFLSCE-Demo-Data'` for cleanup

### Tab 3: Contact Points & Business Licenses

Batched in groups of 15 to stay within managed-package SOQL governor limits.

- **ContactPointAddress** — billing addresses for all accounts
- **ContactPointEmail** — general + department emails per org, personal for doctors
- **ContactPointPhone** — main + department lines, country-formatted numbers
- **ContactPointSocial** — LinkedIn and X handles for organizations
- **BusinessLicense** — dual State + DEA license pattern for HCPs (required for visit sample drops); facility/pharmacy licenses with country-specific formats (CQC, FINESS, IK, SSN, REGA, CRM, ANVISA, COFEPRIS, ANMAT). Address-scoped licenses are linked to ContactPointAddress records post-insert so the system auto-computes `IsLicenseValidated = true`.

### Tab 4: Product Alignment

Creates LifeSciMarketableProduct hierarchy, territory alignments, and product guidance:

- **Market** nodes: Autoimmune Disorders, Oncology Market
- **Brand** nodes: Immunexis (per country), Immunonco (per country)
- **ProductTerritoryAvailability** (PTA) records aligned to country territories
- PTA sharing with leaf territory groups (walks hierarchy 3 levels deep)
- Triggers alignment job to generate PTDAs for leaf territories
- **ProductGuidance** — 7 per country brand (5 Messages + 2 Objectives), 154 total. Messages cover Efficacy, Safety, Differentiation, Patient Experience, and Convenience; Objectives cover Positioning and Patient Identification. All localized in native language per country (FR, DE, IT, ES, JP, KR, PT). Shared with leaf territory groups via `ProductGuidanceShare` (Private OWD). See [docs/ProductGuidance-Guide.md](docs/ProductGuidance-Guide.md)

### Tab 5: Samples

Creates the full sample pipeline for mobile visit engagement:

- **Sample Products** (`Product2`, 22) — Immunexis 10mg and 15mg per country. `RecordType = LSC_Sample`, `Family = Sample`, `ProductCode = IMMUNEXIS-{CC}-{dose}-SMPL`
- **Production Batches** (`ProductionBatch`, 44) — two per product (1-year and 2-year expiry). Key fields: `ProductId`, `UniqueIdentificationNumber` (batch ID shown in visit dropdown), `RemainingQuantity = 1000`, `ExpirationDate`
- **Batch–Inventory Links** (`ProductBatchItem`) — junction between `ProductItem` and `ProductionBatch`. Required for the production batch dropdown on visits. Key fields: `ProductItemId`, `ProductionBatchId`, `RemainingQuantity = 1000`
- **Sample Marketable Products** (`LifeSciMarketableProduct`) — `ProductSpecificationType = LSSampleProduct`, linked to country-level Brand MPs. Key fields: `ProductId` (→ Product2), `ParentProductId` (→ Brand MP), `ParentBrandProductId` (→ Brand MP), `SourceSystem = AFLSCE-Demo-Data`. Includes a self-repair step that corrects mismatched parent brands on re-run
- **Territory Availability** (`ProductTerritoryAvailability`) — sample PTAs aligned to country territories with `AlignmentType = Territory and Subordinates Inclusion`. Shared with leaf territory groups (Private OWD)
- **Rep Inventory** (`ProductItem`) — links each `Product2` to a rep's `Location`. Key fields: `Product2Id`, `LocationId`, `QuantityOnHand = 1000`
- **User Inventory Locations** (`Location`) — `LocationType = User Inventory`, `IsInventoryLocation = true`, `PrimaryUserId` = rep. Auto-created for reps assigned to any territory in the country hierarchy (walks parent→child up to 5 levels)
- **Inventory Storage Address** (`Address`) — child of `Location`. Key fields: `ParentId` (→ Location), `CountryCode`, `City`, `Street`, `PostalCode`, `LocationType = Site`. Shown on the Sample Inventory Management page
- **Sample Periods** (`TimePeriod`, 2) — current year and next year. Key fields: `StartDate`, `EndDate`, `PeriodCategory = Custom`
- **Sample Limits** (`ProviderSampleLimit`) — per-HCP per-product limits with complex `Rule` JSON. Key fields: `AccountId`, `ProductId` (→ LifeSciMarketableProduct), `ProviderSampleLimitTemplateId`, `Rule` (JSON). Created async via Queueable to avoid governor limits

All records use manual sharing (Private OWD) for PTA, ProductionBatch, and ProductItem objects, sharing with territory groups at the leaf level.

> **Permission Note:** The managed `ProductBatchItemTrigger` transfers ownership to the rep on each inventory location. Every rep must have the `LSDO_PH_Field_Sales_Rep` permission set (or equivalent read access to `ProductBatchItem`) before running sample creation — otherwise the trigger fails the entire batch with `TRANSFER_REQUIRES_READ`.

> **DB Schema Note:** For samples to sync to mobile, configure two DB Schema entries:
> 1. `DbSchema_ProductTerritoryAvailability` — SOQL Filter: `AlignmentType = 'Territory and Subordinates Inclusion'` (without `Territory.Name = '{USER.TERRITORY}'`)
> 2. `DbSchema_ProductBatchItem` — no SOQL filter condition (required for production batch dropdown on visits)

### Tab 6: Inventory Replenishment

Simulates non-user-initiated warehouse-to-rep shipments. Creates `Shipment`, `ShipmentItem`, `InventoryOperation` (TransferIn), and `ProductTransfer` records for each rep. Records are created in a pending state so reps can acknowledge receipt on the Sample Inventory Management page. Walks the full territory hierarchy to find reps on any leaf territory under each country.

See [README-InventoryReplenishment.md](README-InventoryReplenishment.md) for full details on field values, the acknowledgement flow, and troubleshooting.

### Tab 7: Scenario Builder (Layered)
Pick your company type to layer therapy-area-specific data on top of base records:

| Scenario | HCPs Created | Specialty Accounts | Agentforce Personas |
|---|---|---|---|
| **Oncology** | Medical/Surgical/Radiation Oncologists, Hematologist-Oncologists, KOLs | Cancer centers, clinical trial sites | Medical Rep, MSL, KAM |
| **Cardiology** | Cardiologists, Interventional, Cardiac Surgeons, Electrophysiologists | Heart centers, cath labs, device companies | Med Rep, KAM, Field Medical |
| **Immunology** | Rheumatologists, Dermatologists, Gastroenterologists | Infusion centers, specialty pharmacies | Med Rep, Market Access, MSL |
| **Neurology** | Neurologists, Movement Disorder/MS/Epilepsy Specialists | Neuroscience research centers, patient support | Med Rep, MSL, Field Medical |
| **Rare Disease** | Geneticists, Metabolic Disease Specialists | Centers of Excellence, advocacy orgs, diagnostic labs | MSL, Field Medical, Market Access |

Scenarios are additive — apply multiple to build a multi-therapeutic-area demo. Each can be independently removed.

### Tab 8: Account & Action Plans

Creates the full Account Plan → Objective → Action Plan hierarchy for demo accounts (1 HCP + 2 HCOs per territory) across all 11 countries:

- **Account Plans** (~24) — one per selected account, with localized names per country and account type (Hospital, Clinic, Insurance, Pharmacy, HCP). Names use a hyphen separator (e.g., `Immunexis Formulary Inclusion - Baptist Health`). Owned by the territory rep
- **Account Plan Objectives** (~72) — 3 per plan, localized to each country's healthcare system (P&T Committee in US, NICE pathway in GB, AIFA in Italy, COFEPRIS in Mexico, etc.)
- **Action Plans** (~432) — 6 per objective, created asynchronously via batch using any existing Final `ActionPlanTemplateVersion` as the required template reference. Custom KAM names are applied (localized by country)
- **Assessment Tasks** (~1,296) — 3 per action plan, created directly by the batch with task names from `DemoAccountPlanData.KAM_TASKS`. No dependency on specific template content

Requires at least one `ActionPlanTemplateVersion` in Final status in the org (any template works). Requires the **AFLSCE Demo Account Plan** permission set assigned to the running user. Includes live batch progress monitoring.

See [README-AccountActionPlans.md](README-AccountActionPlans.md) for full details on permissions, mobile sync (DB Schema), and troubleshooting.

### Tab 9: Activity Plans

Creates the activity plan structure for tracking visit goals per territory:

- **Measure type picker** — radio button group showing `ProviderActivityMeasureType` options. Primary measure type gets 90% of visit goals; remaining 10% split across others
- **TimePeriod** — current calendar year
- **ActivityPlan** — one per leaf territory, tagged with `SourceSystemName = 'AFLSCE-Demo-Data'`
- **ActivityPlanTerritory** — links activity plan to territory
- **ProviderActivityGoal** — one per HCP in the territory, with realistic goals (50 down to 10 visits/year)
- **ProviderActivityGoalMeasure** — visit-level measures (90/5/5 channel split) and product-level measures per country brand

### Tab 10: Visits

Creates completed Visit records for a selected territory with a UI-selectable primary channel:

- **Channel picker** — radio button group showing all active `Visit.Channel` picklist values, auto-defaults to "In-Person". 90% of visits use the primary channel; remaining 10% split evenly across other channels
- **Completed visits** — spread across weekdays from Jan 1 to today, 600 yearly total prorated. Phase-based distribution creates organic cumulative progress curves (multi-week hot/cold streaks instead of linear tracking). Status=Completed, timezone-aware scheduling (8am–4pm local)
- **Planned visits** — ~50 visits for the next 30 days (today + 1 month), Status=Planned. Inserted as Completed first to avoid ProviderVisitTrigger email templates, then flipped to Planned
- **ProviderVisit** — one per visit (both completed and planned), with `VisitSubmitDateTime` set for activity plan progress tracking
- **ProviderVisitProdDetailing** — one per brand per visit (Immunexis + Immunonco for territory's country)
- **Batched delete** — unlocks completed/submitted visits, deletes children first, loops in batches with error reporting

> **Before deleting visits:** Disable `VisitLockHandler` and `RemoteSessionInvitationVisitHandler` trigger handlers in Admin Console → Trigger Settings, then re-enable after.

### Tab 11: Medical Insights

Creates realistic medical insight records from field visits, linked to HCP accounts and brand products. Select a territory from the picker and click to create insights for that territory. Localized to each country's language (English, French, German, Italian, Spanish, Japanese, Korean, Portuguese):

- **MedicalInsight** — 1-2 per brand per HCP in the selected territory, `SourceType = Visit`. 10 Immunexis templates (RA treatment switching, dosing flexibility, real-world evidence, formulary requests, biosimilar differentiation, early intervention, combination therapy, patient support, safety monitoring, infusion partnerships) and 10 Immunonco templates (checkpoint inhibitor response, chemo combination, biomarker testing, irAE management, tumor board, second-line efficacy, patient selection, real-world survival, sequencing after progression, access and reimbursement). Owned by the territory rep
- **MedicalInsightAccount** — links each insight to the HCP account where the insight was captured
- **MedicalInsightProduct** — links each insight to the country-specific brand (`LifeSciMarketableProduct`)
- **Sharing** — `MedicalInsightShare` records grant Edit access to territory groups
- **Note:** Deactivate the **Insight Trigger Flow** in Setup > Flows before creating insights, then reactivate after

### Tab 12: Next Best Customer

Creates `TerritoryAccountScore` records ranking each demo HCP in the selected territory. Powers the Next Best Customer widget for field reps:

- **TerritoryAccountScore** — one per HCP in the chosen territory, `Rank` 1..N (sorted by Account Name), `TotalScore` descending from 100 down (floored at 30, 5-point step). Owned by the territory rep
- **ScoreExplainabilityInfo** — JSON `rationals` array covering Account Profile, Activity Plan, Sales Performance, Account Scope, and # of interactions in last 90 days. Tier (A/B/C) and segment (Strategic Growth / High Opportunity / Maintain) derived from rank
- **Tagged** via `SourceSystemName = 'AFLSCE-Demo-Data'`; `SourceSystemIdentifier = 'TAS-{territoryId}-{accountId}'`. Re-running Create for the same territory clears existing demo scores before re-inserting

### Tab 13: Medical Inquiries

Creates a full Case → Inquiry → Question → Answer chain plus a digital signature for each HCP in the selected territory. Two pickers in the UI:

- **Inquiry Record Type** (radio): Medical Inquiry / Adverse Event / General. Looked up by Name so the package works across orgs that namespace DeveloperName like `LSDO_*`. The Case parent uses the same record type when one with that name exists, otherwise falls back to "Medical Inquiry".
- **Response Delivery Preference** (radio): Email / Phone / Address. The controller resolves a ContactPoint of the chosen type per HCP (primary first), then sets it as `ResponseContactPointRecId` on the Inquiry and matching Answer.

Records created (all tagged with `SourceSystemName = 'AFLSCE-Demo-Data'`):

- **Case** — 1-2 per HCP, `Status = 'Draft'` (LSC's state machine rejects direct insert at later stages), `Origin = 'Phone'`, randomized priority. Owned by the territory rep
- **Inquiry** — one per Case. `Type = 'Medical Inquiry'`, `Territory2Id` + `TerritoryName` set, `InquiryChannelType` picked dynamically from the active picklist (Call Center, Email, Fax, Field Request, Web), realistic `DisclaimerText`, `SubmittedDateTime` within the last 30 days. `Status` and `AccountId` are read-only on Inquiry — `AccountId` inherits from the parent Case, `Status` defaults to Draft via the LSC state machine.
- **DigitalSignature** — one per Inquiry. The controller queries the org for an existing `DigitalSignature` (>1KB) and clones its `DocumentBody` + `DocumentContentType` so demo signatures look realistic. Falls back to a tiny placeholder PNG if no existing signature is found. `SignedBy = HCP name`, `SignedDate = Inquiry.SubmittedDateTime`.
- **InquiryQuestion** — 1-2 per Inquiry, `ResponseStatus = 'Responded'`, with realistic clinical questions for Immunexis (RA / autoimmune) and Immunonco (oncology). Brand names used in question text.
- **InquiryQuestionAnswer** — one per Question with a paired clinical response. `ResponseDateTime` is always after the Inquiry's `SubmittedDateTime` (1h–7d later) to satisfy the LSC validation rule. Inherits the same response contact point as the parent Inquiry.

Delete cascades: Answers → Signatures → Questions → Inquiries → Cases.

## Tagging & Cleanup

All created records are tagged for safe cleanup:

| Object | Tag Field | Tag Value |
|---|---|---|
| Account | `Site` | `AFLSCE-Demo-Data` |
| HealthcareProvider | `SourceSystem` | `AFLSCE-Demo-Data` |
| HealthcareProviderNpi | `SourceSystem` | `AFLSCE-Demo-Data` |
| HealthcareProviderSpecialty | `SourceSystem` | `AFLSCE-Demo-Data` |
| ProviderAffiliation | `SourceSystemName` | `AFLSCE-Demo-Data` |
| ProviderAcctTerritoryInfo | `SourceSystemName` | `AFLSCE-Demo-Data` |
| CareSpecialty | `Description` | `AFLSCE-Demo-Data` |
| ContactPoint* | `SourceSystemName` | `AFLSCE-Demo-Data` |
| BusinessLicense | `Identifier` | `AFLSCE-Demo-Data-*` |
| LifeSciMarketableProduct | `SourceSystem` | `AFLSCE-Demo-Data` |
| Product2 (samples) | `ProductCode` | `IMMUNEXIS-*-SMPL` |
| ProductionBatch | via Product2 | (linked to tagged products) |
| ProductItem | via Product2 | (linked to tagged products) |
| Location (inventory) | via PrimaryUserId | (linked to territory reps) |
| Address (inventory) | via ParentId | (child of Location) |
| TimePeriod | `Name` | `Sample Period *` |
| ProviderSampleLimit | via ProductId | (linked to tagged LifeSciMarketableProduct) |
| Shipment | `TrackingNumber` | `AFLSCE-Replenishment` |
| InventoryOperation | `Comment` | `AFLSCE-Replenishment` |
| ShipmentItem | via ShipmentId | (child of tagged Shipment) |
| ProductTransfer | via ShipmentId | (child of tagged Shipment) |
| AccountPlan | `SourceSystemName` | `AFLSCE-Demo-Data` |
| AccountPlanObjective | `SourceSystemName` | `AFLSCE-Demo-Data` |
| ActionPlan | `SourceSystemName` | `AFLSCE-Demo-Data` |
| ProductGuidance | `SourceSystemName` | `AFLSCE-Demo-Data` |
| MedicalInsight | `Name` | `* #AFLSCE` (suffix) |
| MedicalInsightAccount | via MedicalInsightId | (child of tagged MedicalInsight) |
| MedicalInsightProduct | via MedicalInsightId | (child of tagged MedicalInsight) |
| TerritoryAccountScore | `SourceSystemName` | `AFLSCE-Demo-Data` |
| Inquiry | `SourceSystemName` | `AFLSCE-Demo-Data` |
| InquiryQuestion | `SourceSystemName` | `AFLSCE-Demo-Data` |
| InquiryQuestionAnswer | `SourceSystemName` | `AFLSCE-Demo-Data` |
| DigitalSignature | via `ParentId` | (child of tagged Inquiry) |
| Case (Medical Inquiry) | via Inquiry.CaseId | (parent of tagged Inquiry) |

Every tab has a **Delete** button that removes only the records created by this tool. Your existing org data is never touched.

## Requirements

- Salesforce org with Agentforce Life Sciences Cloud for Commercial Engagement enabled
- Territory Management enabled (for Territory tab)
- Person Accounts enabled (for Healthcare Provider PersonAccounts)
- State & Country Picklists enabled

## Project Structure

```
force-app/main/default/
├── applications/         AFLSCE Demo Data app
├── classes/              Apex controllers
│   ├── DemoTerritoryController        Territory hierarchy CRUD
│   ├── DemoAccountProviderController  Accounts, HCPs, NPIs, specialties, affiliations, territories, PATI (per-country batched)
│   ├── DemoAffiliationHelper          ProviderAffiliation CRUD (separate class for Schema visibility)
│   ├── DemoContactPointController     Contact points & business licenses (batched)
│   ├── DemoProductAlignmentController Product hierarchy & territory alignment (PTA/PTDA)
│   ├── DemoSampleController           Sample products, batches, inventory, sharing
│   ├── DemoReplenishmentController    Warehouse-to-rep inventory replenishment
│   ├── DemoScenarioController         Therapy-area scenario layering
│   ├── DemoActivityPlanController     Activity Plans, Goals & Measures
│   ├── DemoAccountPlanController      Account Plans, Objectives, Action Plan orchestration
│   ├── DemoActionPlanBatch            Batchable for Action Plan + AssessmentTask creation
│   ├── DemoAccountPlanData            English plan archetypes, objectives & KAM task definitions
│   ├── DemoAccountPlanLocale          Localized plan names, objectives & templates (7 languages)
│   ├── DemoMedicalInsightController   Medical Insights with territory picker & per-HCP creation
│   ├── DemoMedicalInsightLocale       Localized insight templates (8 languages)
│   ├── DemoNextBestCustomerController TerritoryAccountScore creation per territory with explainability JSON
│   ├── DemoInquiryController          Case + Inquiry + InquiryQuestion creation per territory (Medical Inquiry)
│   └── DemoVisitController            Visit creation with channel picker & planned visits
├── lwc/                  Lightning Web Components
│   ├── demoDataAdmin           Main tabbed UI
│   ├── territorySetup          Territory hierarchy creator
│   ├── accountProviderSetup    Account & HCP creator + territory assignment
│   ├── contactPointSetup       Contact points & licenses (batched UI with progress)
│   ├── productAlignmentSetup   Product hierarchy & territory alignment
│   ├── sampleSetup             Sample products, batches & inventory for mobile visits
│   ├── replenishmentSetup      Warehouse-to-rep inventory replenishment
│   ├── scenarioBuilder         Therapy-area scenario layering
│   ├── activityPlanSetup       Account & Action Plans creation UI
│   ├── providerActivityPlanSetup  Activity Plans & Goals with measure type picker
│   ├── medicalInsightSetup     Medical Insights with account & product links
│   ├── nextBestCustomerSetup   TerritoryAccountScore creation with territory picker
│   ├── inquirySetup            Medical Inquiry Case/Inquiry/Question creation with territory picker
│   └── visitSetup              Visit creation with channel picker, territory selector & batched delete
├── flexipages/           Lightning Record Pages
│   ├── Action_Plan_Record_Page              ActionPlan record page
│   └── Action_Plan_Template_Record_Page     ActionPlanTemplate record page
├── permissionsets/       AFLSCE Demo Data Admin
└── tabs/                 AFLSCE Demo Data tab
```
