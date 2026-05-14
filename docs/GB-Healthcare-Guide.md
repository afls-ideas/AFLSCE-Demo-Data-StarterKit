# GB Healthcare System — Guide for Life Sciences Demos

How the UK healthcare system works and how pharma field teams operate within it. Use this as context when demoing AFLSCE features for GB territories.

---

## The NHS at a Glance

The National Health Service provides ~90% of UK healthcare, funded through taxation. Unlike the US where reps engage individual prescribers and payers separately, in the NHS the system itself gates access — a drug that isn't on formulary simply won't be prescribed regardless of clinical merit.

**Key bodies:**

| Body | Role | Demo Equivalent |
|------|------|-----------------|
| **NICE** (National Institute for Health and Care Excellence) | Issues Technology Appraisals (TAs) that determine whether the NHS should fund a drug. A positive NICE TA is the single biggest driver of adoption | No direct account — it's a national policy gate |
| **ICB** (Integrated Care Board) | Controls local commissioning, budgets, and formulary decisions. Replaced CCGs in 2022. There are 42 ICBs across England | Account type: Insurance (payer equivalent) |
| **NHS Trust / Foundation Trust** | Runs hospitals and specialist services. Trusts have their own Drug & Therapeutics Committees (D&TCs) that decide local formulary | Account type: Hospital |
| **GP Surgery / Practice** | Primary care. GPs are independent contractors to the NHS, organised into practices and increasingly into Primary Care Networks (PCNs) and GP Federations | Account type: Clinic |
| **Cancer Alliance** | Regional networks coordinating cancer care across multiple trusts. 21 alliances in England | Not modelled as accounts — referenced in insights |

---

## The Traffic Light System

Unique to the UK, drugs are classified by colour that determines who can prescribe:

| Colour | Meaning | What It Means for Reps |
|--------|---------|----------------------|
| **Green** | Any prescriber (GP or specialist) can prescribe freely | Highest volume potential. Focus on GP engagement and formulary awareness |
| **Amber** | Specialist initiates treatment; GP continues under a **shared care protocol** | Most common for biologics. Getting the shared care protocol established is critical — without it, GPs won't continue prescribing |
| **Red** | Hospital/specialist only. Cannot be prescribed in primary care | Volume limited to secondary care. Focus on trust formulary positioning and consultant engagement |

**Immunexis** (SC biologic for RA) would typically be **Amber** — rheumatologist initiates, GP continues via shared care.

**Immunonco** (IV checkpoint inhibitor for NSCLC) would typically be **Red** — hospital-only administration in oncology day units.

---

## Shared Care Protocols — The Unlock for Amber Drugs

For Amber-classified drugs like Immunexis, the shared care protocol is what converts specialist initiation into ongoing GP prescribing volume. Without it, patients stay under hospital care (expensive, limited capacity) and volume stays low.

**What a shared care protocol defines:**
- Which monitoring the GP takes over (blood tests, safety labs)
- When the patient transitions from specialist to GP care
- What triggers a referral back to the specialist
- Prescribing responsibilities (who writes the ongoing Rx)

**Why it matters for reps:**
- Establishing a shared care protocol between a Trust and its local GPs is one of the highest-value activities a UK rep can do
- It requires engagement with both the Trust (rheumatology department, pharmacy) and GP practices (practice managers, GP leads)
- A Trust with no shared care protocol means the specialist starts patients but GPs won't pick them up — volume stays capped

---

## How UK Pharma Reps Work Differently

### Access is harder
- Many GP surgeries have **"no rep" policies**. Reps go through practice managers to arrange appointments
- Hospital consultants are reached through **medical liaison, peer events, and advisory boards** — not cold calls
- Quality of access matters far more than visit volume
- The **ABPI Code of Practice** is stricter than most countries: very low hospitality caps, no branded items, all materials must be ABPI-certified

### Metrics are different
- **No prescriber-level Rx data** like the US NRx/TRx. UK reps think in terms of:
  - Formulary wins (trust D&TC decisions, ICB formulary inclusion)
  - Shared care protocol adoption rates
  - NICE compliance (is the trust following NICE TA guidance?)
  - Regional market share from IQVIA data at ICB level
  - Patient access metrics (time from diagnosis to treatment initiation)

### QOF Alignment
The **Quality and Outcomes Framework (QOF)** rewards GP practices financially for hitting clinical quality indicators. Smart reps align their messaging with QOF targets so the GP sees prescribing the product as helping their practice performance — not just a clinical decision but a business one.

For Immunexis (RA): QOF indicators include DAS28 monitoring and tight disease control targets. Positioning Immunexis as supporting these targets gives GPs a reason to engage.

---

## The Oncology Pathway (Immunonco)

Cancer drugs follow a different path in the NHS:

1. **NICE TA or Cancer Drugs Fund (CDF)**: Drug must have a positive NICE TA or be available through the CDF (a ring-fenced NHS England budget for cancer drugs pending full NICE appraisal)
2. **Blueteq**: Electronic prior-authorisation system for CDF drugs. Consultants must submit a Blueteq form before prescribing. Delays here directly impact time-to-treatment
3. **MDT (Multidisciplinary Team)**: Treatment decisions are made collectively at MDT meetings — oncologist, radiologist, pathologist, CNS. Getting Immunonco into the MDT treatment algorithm is the key win
4. **SACT (Systemic Anti-Cancer Therapy) data**: NHS England collects outcome data on all cancer treatments. This real-world evidence feeds back into NICE reviews
5. **Cancer Alliance**: Regional coordination bodies that standardise treatment pathways across trusts. A Cancer Alliance endorsement can influence multiple trusts at once

---

## Demo Data Mapping

The demo dataset models this system with:

| NHS Concept | Demo Data | Account Type |
|-------------|-----------|-------------|
| NHS Foundation Trusts | Barts Health, Guy's & St Thomas', Manchester University, NHS Lothian | Hospital |
| Teaching Hospitals | Royal London, King's College, UCLH, The Christie, Royal Infirmary of Edinburgh | Hospital |
| Integrated Care Boards | NHS North East London ICB, NHS South East London ICB, NHS Greater Manchester ICB | Insurance |
| GP Surgeries | Whitechapel Health Centre, Bloomsbury Surgery, Bermondsey Medical Mission, Fallowfield, Stockbridge | Clinic |
| Private Healthcare | BUPA, Harley Street Clinic | Insurance / Clinic |
| NHS England (national) | NHS England | Insurance |

### Medical Insights reflect GB rep activities:
- **Immunexis**: NICE TA compliance, ICB formulary status, shared care protocol progress, traffic light reclassification, GP access via practice managers, QOF alignment, BSRBR registry data, biosimilar switching pressure, homecare services, regional IQVIA data
- **Immunonco**: NICE TA/CDF status, trust D&TC formulary pathway, MDT adoption, SACT outcomes, Blueteq access delays, ABPI-compliant consultant engagement, irAE protocols, biomarker testing turnaround, Cancer Alliance engagement, NHS Long Term Plan alignment

---

## Key Terminology Quick Reference

| Term | Meaning |
|------|---------|
| **NICE TA** | Technology Appraisal — national recommendation on NHS funding |
| **ICB** | Integrated Care Board — local NHS commissioning body |
| **D&TC** | Drug and Therapeutics Committee — trust-level formulary decision body |
| **CDF** | Cancer Drugs Fund — interim NHS funding for cancer drugs |
| **Blueteq** | Electronic prior-auth system for CDF drugs |
| **MDT** | Multidisciplinary Team — collective treatment decision meeting |
| **SACT** | Systemic Anti-Cancer Therapy dataset — NHS cancer outcomes data |
| **QOF** | Quality and Outcomes Framework — GP practice performance incentives |
| **ABPI** | Association of the British Pharmaceutical Industry — code of practice |
| **BSRBR** | British Society for Rheumatology Biologics Register |
| **Shared Care Protocol** | Agreement between specialist and GP on ongoing prescribing |
| **Traffic Light** | Green/Amber/Red prescribing classification system |
| **PCN** | Primary Care Network — groups of GP practices working together |
| **CNS** | Clinical Nurse Specialist |
