# FR Healthcare System — Guide for Life Sciences Demos

How the French healthcare system works and how pharma field teams operate within it. Use this as context when demoing AFLSCE features for FR territories.

---

## The System at a Glance

France provides universal coverage through **Assurance Maladie** (part of Sécurité Sociale), funded primarily through employer/employee contributions and taxation. The system achieves near-universal coverage with a mix of public hospitals and private clinics. Unlike the UK where a single NHS gates access, France operates a dual system: **ville** (community/ambulatory care — GPs, specialists, pharmacies) and **hôpital** (hospital care — public and private).

**Key bodies:**

| Body | Role | Demo Equivalent |
|------|------|-----------------|
| **HAS** (Haute Autorité de Santé) | Evaluates drugs and issues ASMR ratings (I–V) that determine clinical added value. An ASMR I–III is the equivalent of a positive NICE TA — it drives reimbursement and price leverage | No direct account — it's a national policy gate |
| **ANSM** (Agence Nationale de Sécurité du Médicament) | Drug safety and regulatory agency (equivalent to MHRA). Handles marketing authorisations, pharmacovigilance, and product recalls | No direct account |
| **ARS** (Agence Régionale de Santé) | 18 regional health agencies controlling hospital budgets, coordinating care, and managing regional health strategy. Similar to UK ICBs — they gate local resource allocation | Account type: Insurance (payer equivalent) |
| **AP-HP** (Assistance Publique - Hôpitaux de Paris) | Largest hospital group in Europe — 39 hospitals across the Paris region. Major KOL concentration and formulary decisions at scale | Account type: Hospital |
| **CHU** (Centre Hospitalier Universitaire) | Teaching hospitals in each major city (CHU de Lyon, CHU de Bordeaux, etc.). Key sites for clinical trials and early adoption | Account type: Hospital |
| **CEPS** (Comité Économique des Produits de Santé) | Negotiates drug prices with pharma companies after HAS evaluation. Sets the official reimbursed price | No direct account — national pricing body |
| **CPAM** (Caisse Primaire d'Assurance Maladie) | Local health insurance offices — handle patient reimbursement claims and enforce prescribing guidelines | Account type: Insurance |

---

## The ASMR Rating System

The **ASMR** (Amélioration du Service Médical Rendu) is the cornerstone of French market access. HAS evaluates each drug's added clinical benefit versus existing treatments:

| ASMR Level | Meaning | Commercial Impact |
|------------|---------|-------------------|
| **I** — Major | Major therapeutic advance | Premium pricing, rapid reimbursement, strong formulary uptake |
| **II** — Important | Important improvement | Good pricing leverage, priority formulary listing |
| **III** — Moderate | Moderate improvement | Reasonable pricing, standard formulary pathway |
| **IV** — Minor | Minor improvement | Limited pricing premium, competitive positioning required |
| **V** — None | No improvement vs existing treatments | Price must match or undercut comparators. Difficult market access |

**Immunexis** (SC biologic for RA) would likely receive **ASMR III–IV** — moderate-to-minor improvement depending on comparator positioning and subgroup data.

**Immunonco** (IV checkpoint inhibitor for NSCLC) could achieve **ASMR II–III** — important improvement in a high unmet need setting.

---

## Drug Access Pathway — From HAS to Patient

French drug access follows a structured pathway that differs significantly between hospital and community settings:

### Hospital drugs (liste en sus)

1. **HAS ASMR evaluation** — determines clinical added value
2. **CEPS price negotiation** — ASMR level drives pricing power
3. **Liste en sus** — expensive hospital drugs are listed separately from the DRG (T2A) payment. This means the hospital gets reimbursed for the drug on top of the procedure payment, removing the financial disincentive to prescribe expensive treatments
4. **Pharmacie hospitalière** — hospital pharmacy controls physical access and stock
5. **Comité du médicament** — hospital D&TC equivalent approves formulary listing

**Why liste en sus matters:** Without it, the drug cost comes out of the hospital's global T2A budget, creating a financial barrier to prescribing. Getting a drug on liste en sus is analogous to getting a positive NICE TA for hospital drugs.

### Community drugs (ville)

1. **HAS ASMR evaluation** — same as hospital
2. **CEPS price negotiation** — sets retail price
3. **Taux de remboursement** — HAS sets reimbursement rate (typically 65% for important drugs, 30% for moderate, 15% for low service). Patient's mutuelle (supplementary insurance) covers the rest
4. **Prescription** — GPs and specialists prescribe freely once the drug is reimbursed (no traffic light equivalent)

---

## How French Pharma Reps Work

### Visiteurs médicaux (VM)

French pharmaceutical reps — visiteurs médicaux — have traditionally had more open access to prescribers than their UK counterparts, but this has changed dramatically:

- **Dramatic workforce reduction**: The VM workforce has been cut by ~50% since the early 2000s (from ~24,000 to ~12,000). Companies have shifted toward medical/scientific liaisons and digital channels
- **Access still relatively open**: Unlike UK GP surgeries with "no rep" policies, French GPs and specialists generally still receive VMs, though appointment scheduling is increasingly required
- **Prescriber-level data available**: IQVIA provides prescriber-level data in France — reps know exactly which doctors prescribe which products and in what volume

### Hospital engagement

- **Pharmacie hospitalière** is the gatekeeper — hospital pharmacists control formulary and purchasing decisions
- **Comité du médicament** (hospital D&TC equivalent) makes formal formulary decisions. Getting on the agenda and presenting clinical data is critical
- **Chef de service** (department head) is the key clinical decision-maker within their specialty
- **Appels d'offres** (hospital tenders) — public hospitals must follow procurement rules for purchasing

### KOL engagement

- **Congrès** (medical conferences) — major events like Journées Nationales de Médecine Générale, SFR (rheumatology), ESMO/ASCO for oncology
- **DU/DIU** (Diplôme Universitaire / Diplôme Inter-Universitaire) — post-graduate university diplomas that KOLs teach. Sponsoring or participating in these programmes builds long-term relationships
- **Advisory boards and expert meetings** — standard KOL engagement, but subject to transparency rules

### Compliance and transparency

- **Base Transparence Santé** — the French equivalent of the US Sunshine Act. All payments, gifts, and benefits to HCPs are published in a public database. This includes consulting fees, congress sponsorships, meals, and travel
- **Charte de la Visite Médicale** — industry self-regulation charter governing VM conduct, visit quality, and promotional claims. Companies must be certified compliant
- **ANSM pre-approval** — all promotional materials must be submitted to ANSM before use (unlike UK where ABPI certification is industry-managed)

---

## Metrics and KPIs

Because prescriber-level data is available in France, rep metrics are more granular than in the UK:

| Metric | French Term | What It Measures |
|--------|-------------|-----------------|
| Market share | Part de marché (PDM) | % of prescriptions in the therapy area going to your product |
| Prescription volume | Nombre de prescriptions | Raw prescription count per prescriber/territory |
| Formulary penetration | Pénétration formulaire | % of hospitals in territory with product on formulary |
| Reimbursement rate | Taux de remboursement | HAS-determined reimbursement percentage |
| Visit frequency | Fréquence de visite | Number of VM visits per prescriber per cycle |
| Coverage | Couverture | % of target prescribers visited in the cycle |
| Reach | Reach | % of target prescribers visited at least once |

**IQVIA CMA data** (Closes de Marché Ambulatoires) provides monthly prescriber-level market share data — reps can track individual physician prescribing patterns over time.

---

## The Oncology Pathway (Immunonco)

Cancer drugs in France follow a specific pathway:

1. **HAS evaluation** — ASMR rating plus assessment of target population size
2. **Liste en sus** — critical for hospital-administered oncology drugs. Without it, the hospital absorbs the cost within its T2A envelope
3. **RCP (Réunion de Concertation Pluridisciplinaire)** — the French equivalent of the UK MDT meeting. Treatment decisions for cancer patients must be made collectively. Getting Immunonco into the RCP treatment algorithm is the key win
4. **Référentiels** — national and regional treatment guidelines (like INCa referentials). These standardise care pathways across centres
5. **ATU/AAP (Accès Précoce)** — early access programme for drugs before formal marketing authorisation (similar to CDF). Recently reformed into the Accès Précoce/Accès Compassionnel framework

---

## Demo Data Mapping

The demo dataset models the French system with:

| French Concept | Demo Data | Account Type |
|----------------|-----------|-------------|
| AP-HP (Paris hospitals) | AP-HP Pitié-Salpêtrière, AP-HP Hôpital Saint-Louis | Hospital |
| CHU Teaching Hospitals | CHU de Lyon, CHU de Bordeaux, CHU de Toulouse | Hospital |
| Private Clinics | Clinique du Parc Lyon, Clinique Hartmann | Clinic |
| ARS (Regional Health Agencies) | ARS Île-de-France, ARS Auvergne-Rhône-Alpes, ARS Nouvelle-Aquitaine | Insurance |
| CPAM (Local Insurance) | CPAM de Paris, CPAM du Rhône | Insurance |
| Cabinets médicaux (GP/Specialist) | Cabinet Médical Rivoli, Cabinet de Rhumatologie Montparnasse | Clinic |

### Medical Insights reflect FR rep activities:
- **Immunexis**: ASMR positioning vs comparators, comité du médicament formulary pathway, prescriber-level PDM tracking, ARS regional prescribing guidelines, biosimilar competition, DU/DIU KOL engagement, Transparence compliance, IQVIA CMA data trends, mutuelle coverage status, hospital vs ville prescribing split
- **Immunonco**: ASMR evaluation status, liste en sus inclusion, RCP treatment algorithm adoption, INCa referential alignment, Accès Précoce/AAP status, pharmacie hospitalière formulary decisions, chef de service engagement, biomarker testing infrastructure, regional cancer network coordination, Transparence-compliant congress sponsorship

---

## Key Terminology Quick Reference

| Term | Meaning |
|------|---------|
| **HAS** | Haute Autorité de Santé — national health technology assessment body |
| **ASMR** | Amélioration du Service Médical Rendu — clinical added value rating (I–V) |
| **ARS** | Agence Régionale de Santé — regional health agencies (18 in France) |
| **AP-HP** | Assistance Publique - Hôpitaux de Paris — largest European hospital group |
| **CEPS** | Comité Économique des Produits de Santé — drug price negotiation body |
| **CPAM** | Caisse Primaire d'Assurance Maladie — local health insurance offices |
| **T2A** | Tarification à l'Activité — activity-based hospital funding (French DRG) |
| **Liste en sus** | Supplementary list for expensive hospital drugs reimbursed outside T2A |
| **Ville** | Community/ambulatory care setting (GPs, specialists, pharmacies) |
| **Hôpital** | Hospital care setting |
| **Visiteur médical (VM)** | Pharmaceutical sales representative |
| **Comité du médicament** | Hospital Drug & Therapeutics Committee equivalent |
| **Pharmacie hospitalière** | Hospital pharmacy — controls formulary and drug access |
| **Transparence** | Public database of pharma payments to HCPs (Sunshine Act equivalent) |
| **RCP** | Réunion de Concertation Pluridisciplinaire — multidisciplinary team meeting |
| **CHU** | Centre Hospitalier Universitaire — teaching hospital |
| **DU/DIU** | Diplôme Universitaire — post-graduate university qualification |
| **Mutuelle** | Supplementary health insurance (covers patient co-pay) |
| **Accès Précoce** | Early access programme for drugs before full marketing authorisation |
| **PDM** | Part de marché — market share |
| **Charte de la Visite Médicale** | Industry charter regulating rep conduct |
