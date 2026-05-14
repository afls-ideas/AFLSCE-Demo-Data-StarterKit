# ES Healthcare System — Guide for Life Sciences Demos

How the Spanish healthcare system works and how pharma field teams operate within it. Use this as context when demoing AFLSCE features for ES territories.

---

## The SNS at a Glance

The Sistema Nacional de Salud (SNS) provides universal public healthcare funded through taxation. Unlike the UK where a single NHS structure gates access nationally, Spain is highly decentralized — each of the 17 Comunidades Autónomas (Autonomous Communities) runs its own health service with its own budget, formulary, and purchasing decisions. This means a drug approved nationally can still face 17 separate market access hurdles at regional level.

**Key bodies:**

| Body | Role | Demo Equivalent |
|------|------|-----------------|
| **AEMPS** (Agencia Española de Medicamentos y Productos Sanitarios) | National drug regulatory agency — authorises medicines for the Spanish market | No direct account — it's a national regulatory gate |
| **CIPM** (Comisión Interministerial de Precios de los Medicamentos) | Sets the national reference price for drugs. Without CIPM pricing, a drug cannot be publicly reimbursed | No direct account — national pricing gate |
| **Ministerio de Sanidad** | National ministry of health. Sets baseline coverage (prestación farmacéutica), coordinates between regions, publishes the IPT | Account type: Insurance (national payer) |
| **Comunidades Autónomas / Regional Health Services** | Each region runs its own health service (e.g., SERMAS in Madrid, SAS in Andalucía, CatSalut in Catalonia). Controls regional budget, formulary (Guía Farmacoterapéutica), hospital management, and purchasing | Account type: Insurance (payer equivalent) |
| **Hospital CFyT** (Comité de Farmacia y Terapéutica) | Hospital formulary committee — decides which drugs are available within a specific hospital. Equivalent to a D&TC in the UK | Decision body within Hospital accounts |
| **IPT** (Informe de Posicionamiento Terapéutico) | National therapeutic positioning report — a mini-HTA that guides regional and hospital decisions but is not legally binding | No direct account — referenced in insights |

---

## The Triple Access Hurdle

Unique to Spain, drugs must clear three successive gates before reaching patients:

| Gate | Body | What Happens | What It Means for Reps |
|------|------|--------------|----------------------|
| **1. National Price** | CIPM | Drug receives a national reimbursement price after AEMPS marketing authorisation | Baseline requirement — no price, no public access anywhere |
| **2. Regional Formulary** | Comunidad Autónoma | Regional health service decides whether to include the drug in its Guía Farmacoterapéutica and allocate budget | A drug can be on formulary in Madrid but not in Andalucía. Regional engagement is critical |
| **3. Hospital Formulary** | Hospital CFyT | Individual hospital committee votes to add the drug to its local formulary | Even within a region that has approved a drug, individual hospitals may not have it available |

**Immunexis** (SC biologic for RA) would need CIPM pricing, then inclusion in each target region's formulary, then approval by each hospital's CFyT.

**Immunonco** (IV checkpoint inhibitor for NSCLC) would follow the same path but with additional IPT positioning as a key influence on regional and hospital decisions.

---

## The IPT — Spain's Mini-HTA

The Informe de Posicionamiento Terapéutico is produced jointly by AEMPS and the Comunidades Autónomas. It evaluates a drug's therapeutic value relative to existing alternatives and positions it within the treatment landscape.

**Key characteristics:**
- Not legally binding, but highly influential — regions and hospitals use it as the basis for their formulary decisions
- Focuses on therapeutic positioning rather than cost-effectiveness (unlike NICE TAs)
- A favourable IPT significantly eases regional and hospital access
- An unfavourable IPT (positioning as "no added value") can effectively block access even with a national price

---

## How Spanish Pharma Reps (Delegados) Work

### Regional variation is the defining challenge
- The same drug can have completely different access status across regions — on formulary in Madrid (SERMAS), under evaluation in Catalonia (CatSalut), and not submitted in Andalucía (SAS)
- Reps must understand the specific access environment in each Comunidad Autónoma they cover
- Regional health authorities have their own therapeutic equivalence rules (equivalentes terapéuticos) that can substitute your drug for a cheaper alternative

### Hospital access is increasingly restricted
- Many hospitals require **cita previa** (prior appointment) arranged through the Dirección Médica (medical directorate)
- Cold visits are declining — relationship-based access through established contacts is the norm
- Access to key stakeholders requires navigating hospital administration

### Key stakeholders differ from other markets
- **Jefe de Servicio** (department head) — clinical decision-maker and CFyT influencer
- **Farmacéutico hospitalario** (hospital pharmacist) — gatekeeper for formulary inclusion and day-to-day drug availability
- **Gerente del hospital** (hospital manager) — budget holder, especially relevant for high-cost drugs
- **Responsable de farmacia de área** (area pharmacy manager) — regional formulary influence

### Public procurement dominates volume
- **Concursos públicos** (public tenders) — hospitals and regional health services buy drugs through public procurement processes
- Winning the tender (licitación) is critical for volume. Price is a major factor but not the only criterion
- Tenders are published in official bulletins (BOE, regional equivalents) and have strict timelines
- **BIFIMED** — the national medicines pricing database that provides transparency on public procurement prices

---

## Equivalentes Terapéuticos — The Substitution Risk

Regional therapeutic equivalence rules allow Comunidades Autónomas to designate drugs as interchangeable within a therapeutic class. When this happens:

- The cheapest option in the equivalence group becomes the default
- Prescribers may be pressured or required to use the designated equivalent
- Your drug can lose volume even while remaining on formulary if it's not the preferred equivalent
- Fighting equivalence classification requires clinical differentiation evidence

This is Spain's version of formulary switching pressure — more systematic than the UK's approach.

---

## Metrics Spanish Reps Track

- **Inclusión en guía** — formulary inclusion status at regional and hospital level
- **Licitaciones ganadas** — tender wins (number and value of concursos públicos won)
- **Cuota de mercado regional** — regional market share from IMS/IQVIA data at Comunidad Autónoma level
- **Acceso hospitalario** — number of hospitals where the drug is available on formulary
- **Prescripción por área de salud** — prescribing volumes by health area
- **Posicionamiento en IPT** — whether the IPT positioning is favourable
- **Equivalente terapéutico status** — whether the drug is at risk of therapeutic equivalence substitution

---

## The Oncology Pathway (Immunonco)

Cancer drugs in Spain follow a specific path:

1. **AEMPS authorisation**: Marketing authorisation (often via EMA centralised procedure)
2. **CIPM pricing**: National price negotiation — can be lengthy for high-cost oncology drugs
3. **IPT**: Therapeutic positioning is especially influential for oncology, where treatment algorithms matter
4. **Regional inclusion**: Each Comunidad Autónoma decides on reimbursement within its budget
5. **Hospital CFyT**: Hospital formulary committee adds the drug — oncology drugs often reviewed in dedicated subcommittees
6. **Protocolos asistenciales**: Hospital-level treatment protocols that define when and how the drug is used (equivalent to MDT treatment algorithms in the UK)

---

## Demo Data Mapping

The demo dataset models this system with:

| Spanish Concept | Demo Data | Account Type |
|-----------------|-----------|-------------|
| Regional Health Services | SERMAS (Madrid), SAS (Andalucía), CatSalut (Catalonia), Osakidetza (Basque Country), IB-Salut (Balearic Islands) | Insurance |
| University Hospitals | Hospital La Paz, Hospital 12 de Octubre, Hospital Clínic Barcelona, Hospital Vall d'Hebron, Hospital Virgen del Rocío | Hospital |
| General Hospitals | Hospital Gregorio Marañón, Hospital Ramón y Cajal, Hospital La Fe Valencia | Hospital |
| Centros de Salud | Centro de Salud Alameda, Centro de Salud Chamberí, Centro de Salud Les Corts | Clinic |
| Ministerio de Sanidad | Ministerio de Sanidad | Insurance |

### Medical Insights reflect ES rep activities:
- **Immunexis**: IPT positioning, regional formulary status across Comunidades, hospital CFyT inclusion progress, equivalente terapéutico risk, concurso público outcomes, Jefe de Servicio engagement, farmacéutico hospitalario relationships, cita previa access challenges, BIFIMED pricing transparency, biosimilar tender pressure
- **Immunonco**: IPT oncology positioning, CIPM price negotiation status, regional budget allocation, hospital CFyT pathway, protocolo asistencial adoption, comité de tumores (tumour board) inclusion, farmacéutico hospitalario gatekeeper engagement, licitación outcomes, biomarker testing availability, Comunidad Autónoma budget constraints

---

## Key Terminology Quick Reference

| Term | Meaning |
|------|---------|
| **SNS** | Sistema Nacional de Salud — Spain's national health system |
| **AEMPS** | Agencia Española de Medicamentos y Productos Sanitarios — national drug regulator |
| **CIPM** | Comisión Interministerial de Precios de los Medicamentos — national drug pricing body |
| **IPT** | Informe de Posicionamiento Terapéutico — national therapeutic positioning report |
| **Comunidad Autónoma** | Autonomous Community — each of Spain's 17 regions with devolved health authority |
| **SERMAS** | Servicio Madrileño de Salud — Madrid's regional health service |
| **SAS** | Servicio Andaluz de Salud — Andalucía's regional health service |
| **CatSalut** | Servei Català de la Salut — Catalonia's regional health service |
| **CFyT** | Comité de Farmacia y Terapéutica — hospital formulary committee |
| **Concurso público** | Public tender — procurement process for hospital/regional drug purchasing |
| **Guía Farmacoterapéutica** | Pharmacotherapeutic guide — regional or hospital formulary |
| **Equivalente terapéutico** | Therapeutic equivalent — regional substitution classification |
| **Delegado** | Delegado de Visita Médica — pharmaceutical sales representative |
| **Cita previa** | Prior appointment — required for hospital access in many centres |
| **Jefe de Servicio** | Department head — key clinical decision-maker |
| **Farmacéutico hospitalario** | Hospital pharmacist — formulary gatekeeper |
| **Gerente del hospital** | Hospital manager — budget holder |
| **BIFIMED** | Base de datos de información farmacoterapéutica — medicines pricing database |
| **Licitación** | Tender/bid — the specific procurement event within a concurso público |
| **Área de salud** | Health area — geographic subdivision within a Comunidad Autónoma |
