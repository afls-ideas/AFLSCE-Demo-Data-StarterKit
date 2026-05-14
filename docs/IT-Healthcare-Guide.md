# IT Healthcare System — Guide for Life Sciences Demos

How the Italian healthcare system works and how pharma field teams operate within it. Use this as context when demoing AFLSCE features for IT territories.

---

## The SSN at a Glance

The Servizio Sanitario Nazionale (SSN) provides universal public healthcare, funded through taxation. Unlike the UK's relatively centralised NHS, the SSN is highly decentralised to 20 Regioni (regions). Each region controls its own health budget, formulary, and delivery model. This means reps face 20 different access environments — a drug reimbursed and accessible in Lombardia may be blocked or delayed in Sicilia.

**Key bodies:**

| Body | Role | Demo Equivalent |
|------|------|-----------------|
| **AIFA** (Agenzia Italiana del Farmaco) | National drug agency. Negotiates pricing, sets reimbursement class (A/H/C), manages Registro di Monitoraggio, issues Note AIFA. The CTS (Commissione Tecnico Scientifica) within AIFA evaluates drug value | No direct account — it's a national policy gate |
| **Regione** | Regional government health department. Sets regional drug budget, regional therapeutic formulary (PTR), and reimbursement policies. 20 regions, each with autonomous health governance | Not modelled as accounts — referenced in insights |
| **ASL** (Azienda Sanitaria Locale) | Local health authorities (~100 across Italy). Control primary care budgets, GP contracts, local formulary, and rep access permissions | Account type: Insurance (payer equivalent) |
| **AO** (Azienda Ospedaliera) | Autonomous hospital trusts, often large teaching hospitals. Have their own PTO (Prontuario Terapeutico Ospedaliero — hospital formulary) and Direzione Sanitaria that gates rep access | Account type: Hospital |
| **MMG** (Medico di Medicina Generale) | General practitioners. Independent contractors to the SSN, contracted through their local ASL | Account type: Clinic |

---

## The Reimbursement Classes

AIFA assigns every authorised drug to a reimbursement class that determines who pays:

| Class | Meaning | What It Means for Reps |
|-------|---------|----------------------|
| **Classe A** | Fully reimbursed by SSN. Prescribable in primary and secondary care | Highest volume potential. Focus on PTR inclusion and GP awareness |
| **Classe H** | Hospital-only, reimbursed by SSN. Must be dispensed within hospital setting | Volume limited to secondary care. Focus on PTO inclusion and specialist engagement |
| **Classe C** | Not reimbursed. Patient pays out of pocket | Limited commercial interest for most reps. Niche/lifestyle products |

**Immunexis** (SC biologic for RA) would typically be **Classe H** initially, potentially moving to **Classe A** with a Nota AIFA restriction and distribution through pharmacies via PHT (Prontuario della distribuzione diretta per conto).

**Immunonco** (IV checkpoint inhibitor for NSCLC) would be **Classe H** — hospital-only administration with mandatory Registro di Monitoraggio entry.

---

## The Double Formulary Hurdle — The Unlock for Market Access

Unlike single-gate systems, Italian drugs must clear two (sometimes three) formulary levels after AIFA approval. This is the central challenge for Italian pharma reps.

**The pathway:**

1. **AIFA negotiation** — pricing and reimbursement class (A/H/C) agreed nationally
2. **Regional PTR inclusion** — the Regione's Commissione Terapeutica Regionale decides whether to add the drug to the Prontuario Terapeutico Regionale. Some regions rubber-stamp AIFA decisions; others impose restrictions or delays
3. **Hospital PTO inclusion** — for Classe H drugs, each AO's Commissione Terapeutica Ospedaliera must add the drug to the Prontuario Terapeutico Ospedaliero
4. **Prescribing** — only after all formulary gates are cleared can the specialist or GP prescribe

**Why it matters for reps:**
- A national AIFA approval means nothing if the region hasn't added it to PTR
- A PTR listing means nothing if the local hospital hasn't added it to PTO
- Tracking inserimento (inclusion) at each level is the core metric
- Timing gaps between levels can be months — reps must work all three levels simultaneously

---

## How Italian Pharma Reps (ISF) Work Differently

### ISF is a regulated profession
- **Informatore Scientifico del Farmaco (ISF)** requires a science degree (pharmacy, biology, medicine, chemistry)
- ISF registration is mandatory — companies must notify AIFA of their field force
- Activities are governed by Legislative Decree 219/2006 and the Farmindustria Code

### Access is tightly controlled
- **ASL controls rep access** — many ASLs require appointment booking through the ASL ufficio informazione scientifica (scientific information office)
- Hospital access requires **Direzione Sanitaria** (medical directorate) approval. Reps must register, provide credentials, and often book specific time slots
- Some ASLs impose limits on visit frequency (e.g., max 2 visits per physician per month)
- Regional variation is massive — Lombardia's accreditation system runs completely differently from Sicilia's paper-based process

### AIFA Registro di Monitoraggio
For expensive or innovative drugs, AIFA requires every prescription to be entered in a national web registry (Registro di Monitoraggio) with clinical data:
- Prescriber must register the patient, enter baseline clinical data, and obtain AIFA authorisation before dispensing
- This gates access but also generates real-world evidence
- Registry compliance is a key metric — if physicians find it burdensome, they may avoid prescribing
- Reps often provide practical support on registry navigation (within compliance boundaries)

### Nota AIFA restrictions
Prescribing notes (Note AIFA) restrict reimbursement to specific clinical conditions:
- **Nota 66**: biologics in rheumatoid arthritis — only after failure of conventional DMARDs
- **Nota 48**: statins — only for specific cardiovascular risk profiles
- These restrict which patients qualify for reimbursement, even if the drug is Classe A

### Tetti di spesa (spending caps)
- Regions have pharmaceutical spending caps (tetto della spesa farmaceutica territoriale and tetto della spesa ospedaliera)
- When a region exceeds its cap, AIFA triggers payback mechanisms — pharma companies must reimburse the overspend
- This creates regional pressure to limit new, expensive drugs even when nationally approved

---

## Metrics for Italian Reps

| Metric | Meaning |
|--------|---------|
| **Inserimento PTR** | Regional formulary inclusion — has the Regione added it to PTR? |
| **Inserimento PTO** | Hospital formulary inclusion — has the AO added it to their PTO? |
| **Accesso ASL** | ASL-level access status — is the rep authorised to visit in this ASL territory? |
| **Registro compliance** | Are physicians successfully enrolling patients in AIFA Registro? |
| **Tetti di spesa** | Regional spending cap status — is the region at risk of payback? |
| **Copertura territoriale** | Territory coverage across ASLs and hospitals |
| **Visite effettuate** | Visits completed within ASL-approved parameters |

---

## The Oncology Pathway (Immunonco)

Cancer drugs in Italy follow a distinct path:

1. **AIFA Classe H + Registro**: Drug approved as Classe H with mandatory Registro di Monitoraggio. AIFA may grant "innovativity" status (Fondo farmaci innovativi) which bypasses regional budget constraints
2. **Fondo farmaci innovativi**: Ring-fenced national fund for innovative drugs. If AIFA grants innovativity, the drug gets immediate access without regional budget impact — bypassing the double formulary hurdle
3. **Regional PTR**: If not innovative, must still pass through regional formulary
4. **Hospital PTO + Commissione**: Local hospital Commissione Terapeutica must approve
5. **GIC/GOM** (Gruppo Interdisciplinare Cure / Gruppo Oncologico Multidisciplinare): Italian equivalent of MDT — multidisciplinary tumour boards that decide treatment. Getting Immunonco into GIC treatment protocols is the key win
6. **Registro data**: All prescriptions tracked in AIFA Registro. Payment-by-results and risk-sharing agreements are common — if the drug doesn't work, the company reimburses the SSN

---

## Demo Data Mapping

The demo dataset models this system with:

| Italian Concept | Demo Data | Account Type |
|-----------------|-----------|-------------|
| Aziende Ospedaliere (Hospital Trusts) | Policlinico Gemelli, Ospedale San Raffaele, Policlinico di Milano, Ospedale Molinette | Hospital |
| Teaching Hospitals / IRCCS | Istituto Nazionale Tumori, Humanitas, Ospedale Niguarda | Hospital |
| ASL (Local Health Authorities) | ASL Milano, ASL Roma 1, ASL Torino, ASL Napoli 1 Centro | Insurance |
| Regione (Regional Health Dept) | Referenced in territory and insight data | Not modelled as accounts |
| MMG Practices | Referenced in visit and call data | Clinic |

### Medical Insights reflect Italian rep activities:
- **Immunexis**: PTR inclusion status by region, PTO inclusion at key hospitals, Nota AIFA 66 compliance, Registro di Monitoraggio enrolment rates, ASL access authorisation, tetti di spesa pressure, biosimilar switching at regional level, PHT distribution pathway, Farmindustria code compliance
- **Immunonco**: AIFA innovativity status, Fondo farmaci innovativi allocation, PTO commissione pathway, GIC/GOM protocol adoption, Registro compliance and payment-by-results tracking, Direzione Sanitaria access, regional PTR delays, biomarker testing availability, irAE management protocols

---

## Key Terminology Quick Reference

| Term | Meaning |
|------|---------|
| **AIFA** | Agenzia Italiana del Farmaco — national drug regulatory and reimbursement agency |
| **SSN** | Servizio Sanitario Nazionale — Italian national health service |
| **ASL** | Azienda Sanitaria Locale — local health authority (~100 across Italy) |
| **AO** | Azienda Ospedaliera — autonomous hospital trust |
| **PTO** | Prontuario Terapeutico Ospedaliero — hospital formulary |
| **PTR** | Prontuario Terapeutico Regionale — regional formulary |
| **Classe A/H/C** | AIFA reimbursement classes: A (fully reimbursed), H (hospital-only), C (patient pays) |
| **Nota AIFA** | Prescribing restriction notes limiting reimbursement to specific conditions |
| **Registro di Monitoraggio** | AIFA web registry for expensive/innovative drugs — tracks every prescription |
| **ISF** | Informatore Scientifico del Farmaco — regulated pharma rep profession |
| **Tetti di spesa** | Pharmaceutical spending caps at regional level |
| **Prontuario** | Formulary (generic term — can be regional PTR or hospital PTO) |
| **Direzione Sanitaria** | Hospital medical directorate — gates rep access to hospital physicians |
| **CTS** | Commissione Tecnico Scientifica — AIFA committee evaluating drug value |
| **Inserimento** | Formulary inclusion — the key milestone reps track |
| **GIC/GOM** | Multidisciplinary tumour board (Italian equivalent of MDT) |
| **Fondo farmaci innovativi** | Ring-fenced national fund for innovative drugs |
| **MMG** | Medico di Medicina Generale — general practitioner |
| **Farmindustria** | Italian pharmaceutical industry association — sets code of conduct |
| **PHT** | Prontuario distribuzione diretta/per conto — direct distribution pathway |
