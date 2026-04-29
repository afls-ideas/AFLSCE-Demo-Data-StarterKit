# Account Plans & Action Plans (Tab 8)

Creates **Account Plans**, **Account Plan Objectives**, **Action Plans**, and **Assessment Tasks** for demo accounts (1 HCP + 2 HCOs per territory) across all 11 countries. Each account gets a localized account plan with country- and account-type-specific objectives, linked to localized KAM Action Plan Templates via a batch job. The UI shows live batch progress while action plans are being created.

## Prerequisites

1. **Accounts & Providers** (Tab 2) must be run first — the controller queries demo accounts tagged with `Site = 'AFLSCE-Demo-Data'`
2. **Territory Hierarchy** (Tab 1) must be set up with users assigned to leaf territories — Account Plans inherit ownership from the territory rep
3. **48 KAM Action Plan Templates** must exist and be published in the org — 6 English + 6 per language for FR, DE, IT, ES, JP, KR, BR (see [Action Plan Templates](#action-plan-templates) below)

## What Gets Created

### Account Plans (~144)

One per selected demo account (1 HCP + 2 HCOs per territory), owned by the territory rep. Plan names are localized per country and account type, with a hyphen separator before the account name:

| Account Type | US Example | FR Example | JP Example |
|---|---|---|---|
| Hospital | Immunexis Formulary Inclusion - {name} | Inscription Immunexis au Formulaire - {name} | イムネキシス 処方集収載 - {name} |
| Clinic | Immunexis Specialty Practice Partnership - {name} | Partenariat Clinique Specialisee Immunexis - {name} | イムネキシス 専門クリニック連携 - {name} |
| Insurance | Immunexis Payer Access Agreement - {name} | Accord Acces Payeur Immunexis - {name} | イムネキシス 保険者アクセス契約 - {name} |
| Pharmacy | Immunexis Specialty Distribution - {name} | Distribution Specialisee Immunexis - {name} | イムネキシス 専門流通 - {name} |
| HCP | Immunexis HCP Engagement Plan - {name} | Plan d Engagement Professionnel de Sante Immunexis - {name} | イムネキシス HCPエンゲージメントプラン - {name} |

All 11 countries have full localized plan names. US/GB use English; MX/AR share Spanish with ES. See `DemoAccountPlanLocale` for the complete localization map and `DemoAccountPlanData.PLAN_ARCHETYPES` for English archetypes.

**Key fields:**
- `AccountId` — the demo account
- `OwnerId` — the first user assigned to the account's leaf territory
- `StartDate` / `EndDate` — January 1 to December 31 of the current year
- `Status` — `Active`
- `SourceSystemName` — `AFLSCE-Demo-Data`

### Account Plan Objectives (~432)

3 objectives per account plan, localized per country and account type. Objectives are specific to the healthcare system in each country (e.g., P&T Committee in the US, NICE pathway in GB, AIFA in Italy, COFEPRIS in Mexico).

US Hospital example:
- Secure P&T Committee Formulary Approval
- Establish Buy-and-Bill Protocol with Pharmacy Department
- Build Clinical Champions Among Rheumatology Staff

FR Hospital example:
- Obtenir l approbation du Comite du Formulaire
- Etablir le protocole d achat avec la pharmacie
- Identifier les champions cliniques en rhumatologie

See `DemoAccountPlanLocale` for localized objectives and `DemoAccountPlanData.OBJECTIVES` for English.

**Key fields:**
- `AccountPlanId` — parent account plan
- `Description` — same as Name
- `StartDate` / `EndDate` — matches the account plan
- `SourceSystemName` — `AFLSCE-Demo-Data`

### Action Plans (~2,592)

Created asynchronously via `DemoActionPlanBatch` (batch size 10). Each objective gets 6 Action Plans, one per localized KAM template. The batch picks the correct language based on the account's `BillingCountryCode`.

English templates (US/GB):
1. Market Access & Contracting
2. Supply Chain & Distribution Readiness
3. P&T Committee Prep: Proactive Partnership for Formulary
4. Field Readiness & Pull-Through
5. Analyse Diagnostic Gaps for Rheumatoid Arthritis
6. Implement & Monitor new Diagnostic Protocols

French territories get French templates (e.g., "Acces au Marche et Contractualisation"), German get German, etc. MX/AR share Spanish templates with ES.

**Key fields:**
- `TargetId` — the AccountPlanObjective (not the Account)
- `OwnerId` — inherited from `AccountPlan.OwnerId` (the territory rep)
- `ActionPlanState` — `Not Started`
- `ActionPlanType` — `KAM`
- `ActionPlanTemplateVersionId` — linked to the localized published template version
- `StartDate` — January 1 of the current year
- `SourceSystemName` — `AFLSCE-Demo-Data`

### Assessment Tasks (~7,776)

Auto-created by the platform when Action Plans are inserted with `ActionPlanTemplateVersionId`. Each template has 2-4 items, so each action plan gets 2-4 assessment tasks in the local language. Task ownership is updated to the territory rep by the batch.

## Action Plan Templates

48 KAM templates must exist in the org (6 English + 6 per language for FR, DE, IT, ES, JP, KR, BR). Templates are **not** created by this tool — they should be set up manually or via anonymous Apex scripts.

To create a template:
1. Go to **Setup > Action Plan Templates** (or use the App Launcher)
2. Create a template with `ActionPlanType = KAM` and `TargetEntityType = AccountPlanObjective`
3. Add template items (`ItemEntityType = AssessmentTask`) to the auto-created version
4. Publish the template version

The batch class matches templates by **exact name** against `ActionPlanTemplateVersion.Name`. See `DemoAccountPlanLocale.KAM_TEMPLATES_BY_LANG` for the full list of localized template names.

## Data Flow

```
Territory (with assigned rep)
  └── Account (1 HCP + 2 HCOs per territory)
       └── AccountPlan (owned by rep, localized name)
            └── AccountPlanObjective (3 per plan, localized)
                 └── ActionPlan (6 per objective, localized template)
                      └── AssessmentTask (2-4 per plan, auto-created from template items)
```

Assessment Tasks are auto-created by the platform when Action Plans are inserted with `ActionPlanTemplateVersionId` set.

## Lightning Record Pages

Two custom FlexiPages are included in this project for the Action Plan and Action Plan Template objects:

| FlexiPage | Object | parentFlexiPage |
|---|---|---|
| `Action_Plan_Record_Page` | ActionPlan | `actionplan__ActionPlan_rec_L` |
| `Action_Plan_Template_Record_Page` | ActionPlanTemplate | `actionplan__ActionPlanTemplate_rec_L` |

Both use the `flexipage:recordHomeSingleColTemplateDesktop` template with three tabs: Details, Related, and Items (task manager).

**After deploying**, activate each page as **Org Default** via:
Setup > Object Manager > Action Plan > Lightning Record Pages > Activation > Assign as Org Default

## Mobile Sync (DB Schema)

For Action Plan data to sync to the AFLS mobile app, the following DB Schema entries must be assigned to the user's profile:

| DB Schema Record | Required |
|---|---|
| `DbSchema_ActionPlan` | Yes |
| `DbSchema_ActionPlanItem` | Yes |
| `DbSchema_ActionPlanTemplate` | Yes |
| `DbSchema_ActionPlanTemplateAssignment` | Yes |
| `DbSchema_ActionPlanTemplateItem` | Yes |
| `DbSchema_ActionPlanTemplateVersion` | Yes |

After adding assignments, regenerate the metadata cache for the profile.

## Required Permissions

The rep's **profile** (not just permission set) must have:

| Object | Minimum | Notes |
|---|---|---|
| AccountPlan | Read | Full CRUD for plan owners |
| AccountPlanObjective | Read | Full CRUD for plan owners |
| ActionPlan | Read, Create, Edit, Delete | Profile-level CRUD required for ownership |
| ActionPlanItem | Read | Restricted picklist — must be granted via profile metadata deploy, not Apex |
| ActionPlanTemplate | Read | For template rendering |
| ActionPlanTemplateAssignment | Read | For template rendering |
| ActionPlanTemplateItem | Read | For template rendering |
| ActionPlanTemplateVersion | Read | For template rendering |
| GoalDefinition | Read | Required by the managed Account Plan page |
| GoalAssignment | Read | Required by the managed Account Plan page |

> **Important:** ActionPlanItem and the template objects are restricted picklist values in `ObjectPermissions.SobjectType`. They cannot be granted via anonymous Apex — deploy them as profile metadata instead.

Field-level security (FLS) must also be granted for all fields the user needs to see. Without FLS, users get "Insufficient Privileges" even if they own the record.

## Troubleshooting

**Account Plan tab shows "Coming Soon":**
The profile is missing an OMCC DbSchema record for AccountPlan. This is not a permissions issue — it must be configured in the Admin Console by assigning the `DbSchema_AccountPlan` entry to the profile.

**"Page not found" on Action Plan records:**
The `Action_Plan_Record_Page` FlexiPage is not activated. Deploy it and activate as Org Default via Setup UI (`FlexiPageOrgWideDefault` is not deployable via CLI).

**"Insufficient Privileges" viewing Action Plan records:**
Check FLS on the ActionPlan, AccountPlan, and AccountPlanObjective objects for the user's profile. Zero FLS = can't view even owned records.

**"The new owner must have read permission" on Action Plans:**
The target user's **profile** lacks ActionPlan CRUD. Permission sets alone are not sufficient for ownership transfer.

**Action Plan Items chevrons are empty (no tasks under objectives):**
Action Plans are created with `ActionPlanState = 'Not Started'`. Items are generated by the platform only when the plan is activated (state = `Started`).

**No Action Plans downloading to mobile:**
Check that all 6 `DbSchema_ActionPlan*` entries are assigned to the user's profile. Regenerate the metadata cache after adding assignments.

**Template not found errors during creation:**
The batch matches `ActionPlanTemplateVersion.Name` exactly. Ensure templates are published and the version name matches one of the 6 KAM template names.

## Tagging & Cleanup

| Object | Tag Field | Tag Value |
|---|---|---|
| AccountPlan | `SourceSystemName` | `AFLSCE-Demo-Data` |
| AccountPlanObjective | `SourceSystemName` | `AFLSCE-Demo-Data` |
| ActionPlan | `SourceSystemName` + `ActionPlanType` | `AFLSCE-Demo-Data` + `KAM` |

The **Delete** button removes records in dependency order: Action Plans first, then Objectives, then Account Plans. Deletion uses `Database.delete(records, false)` to handle partial failures gracefully.

## Project Files

| File | Purpose |
|---|---|
| `DemoActivityPlanController.cls` | Main controller — creates Account Plans, Objectives, queues batch, batch progress polling |
| `DemoActionPlanBatch.cls` | Batchable — creates localized Action Plans from template versions, updates task ownership |
| `DemoAccountPlanData.cls` | English plan archetypes and objectives |
| `DemoAccountPlanLocale.cls` | Localized plan names, objectives, and template names for 7 languages (FR, DE, IT, ES, JP, KR, BR) |
| `activityPlanSetup/` (LWC) | UI component with create/delete buttons, live batch progress, and refresh status |
| `Action_Plan_Record_Page.flexipage-meta.xml` | Lightning Record Page for ActionPlan |
| `Action_Plan_Template_Record_Page.flexipage-meta.xml` | Lightning Record Page for ActionPlanTemplate |
