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
- **40 accounts** across 6 countries: hospitals, clinics, payers, pharmacies, health systems, academic medical centers
- Real institutions: Mass General, Johns Hopkins, Charité Berlin, Hôpital Pitié-Salpêtrière, Policlinico Gemelli, Hospital Clínic Barcelona
- **32 healthcare providers** with culturally appropriate names, NPIs, specialties, and hospital affiliations

### Tab 3: Contact Points & Business Licenses
- Addresses, emails, phones (country-formatted), and social profiles for all accounts
- Medical facility and pharmacy licenses with country-specific formats (CQC, FINESS, IK, SSN, REGA)

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

## Cleanup

Every tab has a **Delete** button that removes only the records created by this tool (tagged with `AFLSCE-Demo-Data` in the Description field). Your existing org data is never touched.

## Requirements

- Salesforce org with Health Cloud or Life Sciences Cloud enabled
- Territory Management enabled (for Territory tab)
- Person Accounts enabled (for Scenario Builder HCPs)

## Project Structure

```
force-app/main/default/
├── applications/         AFLSCE Demo Data app
├── classes/              4 Apex controllers
│   ├── DemoTerritoryController
│   ├── DemoAccountProviderController
│   ├── DemoContactPointController
│   └── DemoScenarioController
├── lwc/                  5 Lightning Web Components
│   ├── demoDataAdmin           Main tabbed UI
│   ├── territorySetup          Territory hierarchy creator
│   ├── accountProviderSetup    Account & HCP creator
│   ├── contactPointSetup       Contact points & licenses
│   └── scenarioBuilder         Therapy-area scenario layering
├── permissionsets/       AFLSCE Demo Data Admin
└── tabs/                 AFLSCE Demo Data tab
```
