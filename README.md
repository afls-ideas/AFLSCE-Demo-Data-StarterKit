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
3. Follow the tabs in order: Territory Setup → Accounts & Providers → Contact Points → Scenario Builder

## What Gets Created

### Tab 1: Territory Hierarchy
- Territory Model (LSC Territory Model) with 3 types: Geographical, Medical, KAM
- **GLOBAL** root with 6 country hierarchies (US, GB, FR, DE, IT, ES) and regional sub-territories
- **Medical** specialty tree: Oncology, Cardiology, Neurology, Immunology, Primary Care (each with sub-specialties)
- **KAM** tree: Academic Medical Centers, Hospital Systems, Payer/Insurance, IDN, Government/VA

### Tab 2: Accounts & Healthcare Providers

**Accounts (40 total)**
- Real hospitals, clinics, payers, and pharmacies across US, GB, FR, DE, IT, ES
- Uses Health_Care_Organization record type for orgs, Health_Care_Provider (PersonAccount) for doctors
- Full billing addresses with country-specific formatting and state/country picklist codes

**Healthcare Providers (32 doctors)**
- Culturally appropriate names per country
- HealthcareProviderNpi records with unique 10-digit NPIs
- HealthcareProviderSpecialty records (Oncology, Cardiology, Neurology, etc.)
- CareSpecialty reference records
- ProviderAffiliation linking doctors to their hospitals/clinics

**Territory Assignment**
- Maps all 72 accounts to territories by city (with country-level fallback)
- Creates ObjectTerritory2Association records
- Creates ProviderAcctTerritoryInfo (PATI) records for each account-territory pair
  - `IsTargetedAccount = true`, `IsAvailableOffline = true`, `IsActive = true`
  - Tagged with `SourceSystemName = 'AFLSCE-Demo-Data'` for cleanup

### Tab 3: Contact Points & Business Licenses

Batched in groups of 15 to stay within managed-package SOQL governor limits.

- **ContactPointAddress** (72) — billing addresses for all accounts
- **ContactPointEmail** (104) — general + department emails per org, personal for doctors
- **ContactPointPhone** (208) — main + department lines, country-formatted numbers
- **ContactPointSocial** (~52) — LinkedIn and X handles for organizations
- **BusinessLicense** (~32) — facility and pharmacy licenses with country-specific formats (CQC, FINESS, IK, SSN, REGA)

### Tab 4: Scenario Builder (Layered)
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
│   └── DemoScenarioController         Therapy-area scenario layering
├── lwc/                  Lightning Web Components
│   ├── demoDataAdmin           Main tabbed UI
│   ├── territorySetup          Territory hierarchy creator
│   ├── accountProviderSetup    Account & HCP creator + territory assignment
│   ├── contactPointSetup       Contact points & licenses (batched UI with progress)
│   └── scenarioBuilder         Therapy-area scenario layering
├── permissionsets/       AFLSCE Demo Data Admin
└── tabs/                 AFLSCE Demo Data tab
```
