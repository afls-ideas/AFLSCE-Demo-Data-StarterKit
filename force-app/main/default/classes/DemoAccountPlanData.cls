public class DemoAccountPlanData {

    // 4 account plan archetypes per account type = 20 distinct plan types.
    // Controller cycles through these so each account in a territory gets a different plan.
    public static final Map<String, List<String>> PLAN_ARCHETYPES = new Map<String, List<String>>{
        'Hospital' => new List<String>{
            'Immunexis Formulary Inclusion - <<N>>',
            'Immunexis Clinical Pathway Integration - <<N>>',
            'Immunexis Biosimilar Switch Defense - <<N>>',
            'Immunexis Oncology Center of Excellence - <<N>>'
        },
        'Clinic' => new List<String>{
            'Immunexis Specialty Practice Partnership - <<N>>',
            'Immunexis Infusion Suite Expansion - <<N>>',
            'Immunexis Patient Referral Network - <<N>>',
            'Immunexis Clinical Trial Site Activation - <<N>>'
        },
        'Insurance' => new List<String>{
            'Immunexis Payer Access Agreement - <<N>>',
            'Immunexis Outcomes-Based Contract - <<N>>',
            'Immunexis Step Therapy Optimization - <<N>>',
            'Immunexis Medical Policy Shaping - <<N>>'
        },
        'Pharmacy' => new List<String>{
            'Immunexis Specialty Distribution - <<N>>',
            'Immunexis Hub Services Integration - <<N>>',
            'Immunexis Patient Adherence Program - <<N>>',
            'Immunexis Cold Chain Excellence - <<N>>'
        },
        'HCP' => new List<String>{
            'Immunexis HCP Engagement Plan - <<N>>',
            'Immunexis KOL Development - <<N>>',
            'Immunexis Speaker Bureau Recruitment - <<N>>',
            'Immunexis Real-World Evidence Partnership - <<N>>'
        }
    };

    // Objectives mapped per archetype (by account type + index).
    // Each archetype has 3 objectives that align with the plan focus.
    public static final Map<String, List<String>> OBJECTIVES = new Map<String, List<String>>{

        // Hospital archetypes
        'Hospital_0' => new List<String>{
            'Secure P&T Committee Formulary Approval',
            'Establish Buy-and-Bill Protocol with Pharmacy Department',
            'Build Clinical Champions Among Rheumatology Staff'
        },
        'Hospital_1' => new List<String>{
            'Map Current Treatment Protocols and Identify Gaps',
            'Embed Immunexis in Clinical Decision Support Tools',
            'Train Residents and Fellows on Immunexis Evidence'
        },
        'Hospital_2' => new List<String>{
            'Quantify Total Cost of Care vs Biosimilar Alternatives',
            'Present Differentiation Data to Pharmacy Director',
            'Secure Non-Medical Switching Policy Commitment'
        },
        'Hospital_3' => new List<String>{
            'Identify Oncology Service Line Leaders',
            'Establish Tumor Board Presentation Schedule',
            'Launch Companion Diagnostic Testing Protocol'
        },

        // Clinic archetypes
        'Clinic_0' => new List<String>{
            'Achieve Immunexis as Preferred Biologic in Treatment Algorithm',
            'Establish In-Office Infusion Suite Administration Protocol',
            'Enroll Key Physicians in Immunexis Speaker Bureau'
        },
        'Clinic_1' => new List<String>{
            'Assess Infusion Chair Capacity and Scheduling Workflow',
            'Negotiate Immunexis Buy-and-Bill Reimbursement Model',
            'Train Infusion Nurses on Immunexis Administration'
        },
        'Clinic_2' => new List<String>{
            'Map Referring Physician Network and Volume',
            'Establish Immunexis Patient Fast-Track Pathway',
            'Launch Co-Branded Patient Education Materials'
        },
        'Clinic_3' => new List<String>{
            'Qualify Site for Phase IV Clinical Trial Participation',
            'Train Staff on Protocol Compliance and Patient Recruitment',
            'Establish Data Collection Infrastructure for RWE'
        },

        // Insurance archetypes
        'Insurance_0' => new List<String>{
            'Secure Tier 2 Formulary Placement on Commercial Plans',
            'Negotiate Step-Edit Criteria Favorable to Immunexis',
            'Establish Medical Exception Pathway for RA Patients'
        },
        'Insurance_1' => new List<String>{
            'Design Outcomes-Based Risk-Sharing Agreement',
            'Define Quality Metrics and Measurement Methodology',
            'Negotiate Performance Guarantees and Rebate Structure'
        },
        'Insurance_2' => new List<String>{
            'Review Current Prior Authorization Criteria',
            'Submit Clinical Evidence Package to Medical Director',
            'Negotiate Reduced Step Therapy Requirements'
        },
        'Insurance_3' => new List<String>{
            'Engage Medical Director with Immunexis Value Dossier',
            'Present Health Economic Outcomes Research Data',
            'Secure Medical Policy Update for Expanded Indications'
        },

        // Pharmacy archetypes
        'Pharmacy_0' => new List<String>{
            'Onboard onto Specialty Pharmacy Network',
            'Establish Cold-Chain Storage & Handling Protocol',
            'Drive Patient Adherence via Copay Card Integration'
        },
        'Pharmacy_1' => new List<String>{
            'Integrate Immunexis Hub Portal with Pharmacy Workflow',
            'Streamline Benefits Verification and Prior Auth Process',
            'Launch Patient Welcome Kit and Onboarding Program'
        },
        'Pharmacy_2' => new List<String>{
            'Deploy Refill Reminder and Adherence Monitoring',
            'Train Pharmacists on Patient Counseling for Immunexis',
            'Establish Adverse Event Reporting Workflow'
        },
        'Pharmacy_3' => new List<String>{
            'Validate Temperature Monitoring and Excursion Protocols',
            'Certify Staff on Biologic Handling Requirements',
            'Implement Returns and Waste Management Procedures'
        },

        // HCP archetypes
        'HCP_0' => new List<String>{
            'Increase Immunexis Share of Biologic Prescriptions',
            'Train on Patient Selection Criteria for RA & Oncology',
            'Enroll in Patient Support & Hub Services Program'
        },
        'HCP_1' => new List<String>{
            'Identify and Profile KOL Influence and Reach',
            'Engage in Advisory Board and Medical Education Events',
            'Secure Commitment for Peer-to-Peer Presentations'
        },
        'HCP_2' => new List<String>{
            'Recruit for National and Regional Speaker Programs',
            'Develop Immunexis Clinical Presentation Deck',
            'Schedule Speaker Engagements at Key Congresses'
        },
        'HCP_3' => new List<String>{
            'Propose Real-World Evidence Study Collaboration',
            'Align on Study Design and Patient Population',
            'Support Publication and Congress Abstract Submission'
        }
    };

    public static String getAccountTypeKey(String countryCode, String accountType, Boolean isPersonAccount) {
        if (isPersonAccount) {
            return countryCode + '_HCP';
        }
        if (String.isBlank(accountType)) {
            return countryCode + '_Hospital';
        }
        return countryCode + '_' + accountType;
    }

    public static String getBaseType(String mapKey) {
        if (mapKey == null) return 'Hospital';
        Integer idx = mapKey.indexOf('_');
        return idx >= 0 ? mapKey.substring(idx + 1) : 'Hospital';
    }
}
