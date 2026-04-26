# AFLSCE Demo Data Starter Kit

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
3. Follow the tabs in order: Territory Setup → Accounts & Providers → Contact Points → Product Alignment → Samples → Inventory Replenishment → Scenario Builder

## What Gets Created

### Tab 1: Territory Hierarchy
- Territory Model (LSC Territory Model) with 3 types: Geographical, Medical, KAM
- **GLOBAL** root with 11 country hierarchies (US, GB, FR, DE, IT, ES, JP, KR, BR, MX, AR) and regional sub-territories
- **Medical** specialty tree: Oncology, Cardiology, Neurology, Immunology, Primary Care (each with sub-specialties)
- **KAM** tree: Academic Medical Centers, Hospital Systems, Payer/Insurance, IDN, Government/VA

### Tab 2: Accounts & Healthcare Providers

**Accounts (110+ HCOs)**
- Real hospitals, clinics, payers, and pharmacies across US, GB, FR, DE, IT, ES, JP, KR, BR, MX, AR
- 10 HCOs per country with culturally appropriate names and addresses
- Uses Health_Care_Organization record type for orgs, Health_Care_Provider (PersonAccount) for doctors
- Full billing addresses with country-specific formatting and state/country picklist codes

**Healthcare Providers (110+ HCPs)**
- 10 HCPs per country with culturally appropriate names
- HealthcareProviderNpi records with unique 10-digit NPIs
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

Creates LifeSciMarketableProduct hierarchy and territory alignments:

- **Market** nodes: Autoimmune Disorders, Oncology Market
- **Brand** nodes: Immunexis (per country), Immunonco (per country)
- **ProductTerritoryAvailability** (PTA) records aligned to country territories
- PTA sharing with leaf territory groups (walks hierarchy 3 levels deep)
- Triggers alignment job to generate PTDAs for leaf territories

### Tab 5: Samples

Creates the full sample pipeline for mobile visit engagement:

- **Sample Products** (`Product2`, 22) — Immunexis 10mg and 15mg per country. `RecordType = LSC_Sample`, `Family = Sample`, `ProductCode = IMMUNEXIS-{CC}-{dose}-SMPL`
- **Production Batches** (`ProductionBatch`, 44) — two per product (1-year and 2-year expiry). Key fields: `ProductId`, `UniqueIdentificationNumber` (batch ID shown in visit dropdown), `RemainingQuantity = 1000`, `ExpirationDate`
- **Batch–Inventory Links** (`ProductBatchItem`) — junction between `ProductItem` and `ProductionBatch`. Required for the production batch dropdown on visits. Key fields: `ProductItemId`, `ProductionBatchId`, `RemainingQuantity = 1000`
- **Sample Marketable Products** (`LifeSciMarketableProduct`) — `ProductSpecificationType = LSSampleProduct`, linked to country-level Brand MPs. Key fields: `ProductId` (→ Product2), `ParentProductId` (→ Brand MP), `SourceSystem = AFLSCE-Demo-Data`
- **Territory Availability** (`ProductTerritoryAvailability`) — sample PTAs aligned to country territories with `AlignmentType = Territory and Subordinates Inclusion`. Shared with leaf territory groups (Private OWD)
- **Rep Inventory** (`ProductItem`) — links each `Product2` to a rep's `Location`. Key fields: `Product2Id`, `LocationId`, `QuantityOnHand = 1000`
- **User Inventory Locations** (`Location`) — `LocationType = User Inventory`, `IsInventoryLocation = true`, `PrimaryUserId` = rep. Auto-created for reps assigned to country territories
- **Inventory Storage Address** (`Address`) — child of `Location`. Key fields: `ParentId` (→ Location), `CountryCode`, `City`, `Street`, `PostalCode`, `LocationType = Site`. Shown on the Sample Inventory Management page
- **Sample Periods** (`TimePeriod`, 2) — current year and next year. Key fields: `StartDate`, `EndDate`, `PeriodCategory = Custom`
- **Sample Limits** (`ProviderSampleLimit`) — per-HCP per-product limits with complex `Rule` JSON. Key fields: `AccountId`, `ProductId` (→ LifeSciMarketableProduct), `ProviderSampleLimitTemplateId`, `Rule` (JSON). Created async via Queueable to avoid governor limits

All records use manual sharing (Private OWD) for PTA, ProductionBatch, and ProductItem objects, sharing with territory groups at the leaf level.

> **DB Schema Note:** For samples to sync to mobile, configure two DB Schema entries:
> 1. `DbSchema_ProductTerritoryAvailability` — SOQL Filter: `AlignmentType = 'Territory and Subordinates Inclusion'` (without `Territory.Name = '{USER.TERRITORY}'`)
> 2. `DbSchema_ProductBatchItem` — no SOQL filter condition (required for production batch dropdown on visits)

### Tab 6: Inventory Replenishment

Simulates non-user-initiated warehouse-to-rep shipments. Creates `Shipment`, `ShipmentItem`, `InventoryOperation` (TransferIn), and `ProductTransfer` records for each rep. Records are created in a pending state so reps can acknowledge receipt on the Sample Inventory Management page.

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

Every tab has a **Delete** button that removes only the records created by this tool. Your existing org data is never touched.

## Requirements

- Salesforce org with Health Cloud or Life Sciences Cloud enabled
- Territory Management enabled (for Territory tab)
- Person Accounts enabled (for Healthcare Provider PersonAccounts)
- State & Country Picklists enabled

## Project Structure

```
force-app/main/default/
├── applications/         AFLSCE Demo Data app
├── classes/              Apex controllers
│   ├── DemoTerritoryController        Territory hierarchy CRUD
│   ├── DemoAccountProviderController  Accounts, HCPs, NPIs, specialties, affiliations, territories, PATI
│   ├── DemoAffiliationHelper          ProviderAffiliation CRUD (separate class for Schema visibility)
│   ├── DemoContactPointController     Contact points & business licenses (batched)
│   ├── DemoProductAlignmentController Product hierarchy & territory alignment (PTA/PTDA)
│   ├── DemoSampleController           Sample products, batches, inventory, sharing
│   ├── DemoReplenishmentController    Warehouse-to-rep inventory replenishment
│   └── DemoScenarioController         Therapy-area scenario layering
├── lwc/                  Lightning Web Components
│   ├── demoDataAdmin           Main tabbed UI
│   ├── territorySetup          Territory hierarchy creator
│   ├── accountProviderSetup    Account & HCP creator + territory assignment
│   ├── contactPointSetup       Contact points & licenses (batched UI with progress)
│   ├── productAlignmentSetup   Product hierarchy & territory alignment
│   ├── sampleSetup             Sample products, batches & inventory for mobile visits
│   ├── replenishmentSetup      Warehouse-to-rep inventory replenishment
│   └── scenarioBuilder         Therapy-area scenario layering
├── permissionsets/       AFLSCE Demo Data Admin
└── tabs/                 AFLSCE Demo Data tab
```
