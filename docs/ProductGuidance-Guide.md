# Product Guidance — Demo Data Plan

Creates **ProductGuidance** records for each country-specific Immunexis and Immunonco product.
Each product gets **7 records** (5 Messages + 2 Objectives), grouped and sequenced for the mobile detailing flow.

## Record Structure

| Field | Value |
|-------|-------|
| Type | `Message` (x5) or `Objective` (x2) |
| GroupName | `Key Messages` (Messages) / `Call Objectives` (Objectives) |
| GroupSequence | 1-5 (Messages) / 1-2 (Objectives) |
| Priority | 1-7 |
| IsActive | true |
| EffectiveStartDate | 2025-01-01 |
| SourceSystemName | AFLSCE-Demo-Data |

---

## Immunexis (zelanumab)

Bispecific IL-23/IL-17A antibody for autoimmune diseases (RA, PsA).

### 1. Efficacy (Message)

SHIELD-RA Phase 3: 68% ACR50 at Week 24 with zelanumab vs 31% placebo.
Dual IL-23/IL-17A blockade delivers superior joint protection in moderate-to-severe RA.

### 2. Safety (Message)

Favorable safety: serious infection rate 1.8/100 PY, no new TB signals,
mild injection-site reactions in <5% of patients. No mandatory lab monitoring required.

### 3. Differentiation (Message)

Only bispecific targeting both IL-23 and IL-17A in a single molecule —
addresses upstream and downstream inflammation simultaneously, unlike sequential monotherapy.

### 4. Patient Experience (Message)

In PRISM Registry real-world data, 74% of PsA patients on zelanumab reported meaningful
improvement in daily activities at 12 months. Reduced morning stiffness rated as top
quality-of-life gain.

### 5. Convenience (Message)

Ready-to-use prefilled pen, room-temperature stable for 14 days. Patients self-administer
every 4 weeks — half the injection frequency of leading IL-17A inhibitors.

### 6. Positioning (Objective)

Position zelanumab as first-line biologic after csDMARD inadequate response.
Secure formulary discussion with rheumatology department head.

### 7. Patient Identification (Objective)

Identify patients with moderate-to-severe RA who have failed at least one csDMARD
or show early radiographic progression. Flag candidates during chart review with the care team.

---

## Immunonco (vorastinib)

Bispecific PD-1/TIGIT antibody for solid tumors (NSCLC, HCC).

### 1. Efficacy (Message)

BEACON-LUNG Phase 3: median PFS 11.2 months vs 5.4 months with pembrolizumab alone
in PD-L1 >=50% NSCLC. 42% confirmed ORR in first-line setting.

### 2. Safety (Message)

Manageable irAE profile: Grade >=3 events in 18% of patients. No unexpected hepatotoxicity.
Median time to irAE onset: 6 weeks, responsive to standard steroid protocols.

### 3. Differentiation (Message)

Dual PD-1/TIGIT blockade overcomes adaptive resistance seen with anti-PD-1 monotherapy.
TIGIT+ NK cell reinvigoration drives responses even in PD-L1-low tumors.

### 4. Patient Experience (Message)

BEACON-HCC Phase 2: 28% ORR in post-atezolizumab-bevacizumab HCC patients,
a population with no approved second-line IO. Median duration of response: 14.1 months.

### 5. Convenience (Message)

Fixed-dose IV infusion every 3 weeks, no weight-based dosing. Compatible with standard
oncology infusion chairs — 30-minute administration after the first cycle.

### 6. Positioning (Objective)

Drive vorastinib adoption as preferred first-line IO in PD-L1 >=50% NSCLC.
Secure tumor board presentation slot to review BEACON-LUNG data.

### 7. Patient Identification (Objective)

Identify advanced NSCLC patients with PD-L1 >=50% who are treatment-naive or progressing
on current IO. Review molecular profiling reports with the oncology team to flag candidates.

---

## Localization

All 7 messages per product are translated to the native language for each country.
Scientific content is preserved; phrasing is adapted to local medical communication style.

| Country | Language |
|---------|----------|
| US, GB | English (US vs UK spelling) |
| FR | French |
| DE | German |
| IT | Italian |
| ES, MX, AR | Spanish (regional variants) |
| JP | Japanese |
| KR | Korean |
| BR | Portuguese (Brazilian) |

## Summary

- **Total records**: 22 products x 7 records = **154 ProductGuidance records**
- **Products**: Immunexis (XX) and Immunonco (XX) for US, GB, FR, DE, IT, ES, JP, KR, BR, MX, AR
- **Naming convention**: `{Product} {Country} - {Theme}` e.g. "Immunexis US - Efficacy", "Immunonco DE - Patient Identification"
