public class DemoAccountPlanData {

    public static final Map<String, String> PLAN_NAMES = new Map<String, String>{
        'US_Hospital'  => 'Immunexis Formulary Inclusion — {0}',
        'US_Clinic'    => 'Immunexis Specialty Practice Partnership — {0}',
        'US_Insurance' => 'Immunexis Payer Access Agreement — {0}',
        'US_Pharmacy'  => 'Immunexis Specialty Distribution — {0}',
        'US_HCP'       => 'Immunexis HCP Engagement Plan — {0}',

        'GB_Hospital'  => 'Immunexis NHS Trust Adoption Plan — {0}',
        'GB_Clinic'    => 'Immunexis Rheumatology Centre Partnership — {0}',
        'GB_Insurance' => 'Immunexis Integrated Care Board Plan — {0}',
        'GB_Pharmacy'  => 'Immunexis NHS Dispensing Partnership — {0}',
        'GB_HCP'       => 'Immunexis GP & Specialist Engagement — {0}',

        'FR_Hospital'  => 'Immunexis Adoption Hospitalière — {0}',
        'FR_Clinic'    => 'Immunexis Partenariat Centre Spécialisé — {0}',
        'FR_Insurance' => 'Immunexis Accord Remboursement — {0}',
        'FR_Pharmacy'  => 'Immunexis Partenariat Officine — {0}',
        'FR_HCP'       => 'Immunexis Plan d\'Engagement Prescripteur — {0}',

        'DE_Hospital'  => 'Immunexis Krankenhauseinführung — {0}',
        'DE_Clinic'    => 'Immunexis Facharztpraxis-Partnerschaft — {0}',
        'DE_Insurance' => 'Immunexis Krankenkassen-Vereinbarung — {0}',
        'DE_Pharmacy'  => 'Immunexis Apothekenpartnerschaft — {0}',
        'DE_HCP'       => 'Immunexis Arzt-Engagement-Plan — {0}',

        'IT_Hospital'  => 'Immunexis Piano Adozione Ospedaliera — {0}',
        'IT_Clinic'    => 'Immunexis Partenariato Centro Specialistico — {0}',
        'IT_Insurance' => 'Immunexis Accordo Rimborso SSN — {0}',
        'IT_Pharmacy'  => 'Immunexis Accordo Distribuzione Farmaci — {0}',
        'IT_HCP'       => 'Immunexis Piano Coinvolgimento Medico — {0}',

        'ES_Hospital'  => 'Immunexis Plan Adopción Hospitalaria — {0}',
        'ES_Clinic'    => 'Immunexis Alianza Centro Especializado — {0}',
        'ES_Insurance' => 'Immunexis Acuerdo Financiación SNS — {0}',
        'ES_Pharmacy'  => 'Immunexis Acuerdo Distribución Farmacia — {0}',
        'ES_HCP'       => 'Immunexis Plan Compromiso Prescriptor — {0}',

        'JP_Hospital'  => 'イムネキシス 病院導入プラン — {0}',
        'JP_Clinic'    => 'イムネキシス 専門クリニック連携プラン — {0}',
        'JP_Insurance' => 'イムネキシス 保険適用推進プラン — {0}',
        'JP_Pharmacy'  => 'イムネキシス 薬局パートナーシッププラン — {0}',
        'JP_HCP'       => 'イムネキシス KOL育成プラン — {0}',

        'KR_Hospital'  => '이뮤넥시스 병원 도입 계획 — {0}',
        'KR_Clinic'    => '이뮤넥시스 전문 클리닉 파트너십 — {0}',
        'KR_Insurance' => '이뮤넥시스 급여 등재 추진 계획 — {0}',
        'KR_Pharmacy'  => '이뮤넥시스 약국 유통 파트너십 — {0}',
        'KR_HCP'       => '이뮤넥시스 KOL 육성 계획 — {0}',

        'BR_Hospital'  => 'Immunexis Plano Adoção Hospitalar SUS — {0}',
        'BR_Clinic'    => 'Immunexis Parceria Clínica Especializada — {0}',
        'BR_Insurance' => 'Immunexis Acordo Reembolso ANVISA — {0}',
        'BR_Pharmacy'  => 'Immunexis Parceria Distribuição Farmácia — {0}',
        'BR_HCP'       => 'Immunexis Plano Engajamento Prescritor — {0}',

        'MX_Hospital'  => 'Immunexis Plan Adopción Hospitalaria IMSS — {0}',
        'MX_Clinic'    => 'Immunexis Alianza Clínica Especializada — {0}',
        'MX_Insurance' => 'Immunexis Acuerdo Cobertura COFEPRIS — {0}',
        'MX_Pharmacy'  => 'Immunexis Acuerdo Distribución Farmacia — {0}',
        'MX_HCP'       => 'Immunexis Plan Compromiso Prescriptor — {0}',

        'AR_Hospital'  => 'Immunexis Plan Adopción Hospitalaria — {0}',
        'AR_Clinic'    => 'Immunexis Alianza Centro Especializado — {0}',
        'AR_Insurance' => 'Immunexis Acuerdo Obras Sociales — {0}',
        'AR_Pharmacy'  => 'Immunexis Acuerdo Distribución Farmacia — {0}',
        'AR_HCP'       => 'Immunexis Plan Compromiso Prescriptor — {0}'
    };

    public static final Map<String, List<String>> OBJECTIVES = new Map<String, List<String>>{
        'US_Hospital' => new List<String>{
            'Secure P&T Committee Formulary Approval',
            'Establish Buy-and-Bill Protocol with Pharmacy Department',
            'Build Clinical Champions Among Rheumatology Staff'
        },
        'US_Clinic' => new List<String>{
            'Achieve Immunexis as Preferred Biologic in Treatment Algorithm',
            'Establish In-Office Infusion Suite Administration Protocol',
            'Enroll Key Physicians in Immunexis Speaker Bureau'
        },
        'US_Insurance' => new List<String>{
            'Secure Tier 2 Formulary Placement on Commercial Plans',
            'Negotiate Step-Edit Criteria Favorable to Immunexis',
            'Establish Medical Exception Pathway for RA Patients'
        },
        'US_Pharmacy' => new List<String>{
            'Onboard onto Specialty Pharmacy Network',
            'Establish Cold-Chain Storage & Handling Protocol',
            'Drive Patient Adherence via Copay Card Integration'
        },
        'US_HCP' => new List<String>{
            'Increase Immunexis Share of Biologic Prescriptions',
            'Train on Patient Selection Criteria for RA & Oncology',
            'Enroll in Patient Support & Hub Services Program'
        },

        'GB_Hospital' => new List<String>{
            'Secure NICE-Aligned Prescribing Pathway',
            'Establish Biosimilar Switch Prevention Protocol',
            'Gain Inclusion in NHS Trust Rheumatology Guidelines'
        },
        'GB_Clinic' => new List<String>{
            'Achieve Immunexis Listing on Outpatient Formulary',
            'Establish Nurse-Led Infusion Pathway',
            'Train Clinical Staff on NICE Eligibility Criteria'
        },
        'GB_Insurance' => new List<String>{
            'Align Coverage Policy with NICE Technology Appraisal',
            'Engage Integrated Care Board on Pathway Commissioning',
            'Negotiate Outcomes-Based Reimbursement Agreement'
        },
        'GB_Pharmacy' => new List<String>{
            'Register on NHS Homecare Medicines Service Panel',
            'Establish Cold-Chain Dispensing Protocol',
            'Support Patient Adherence via NHS Hub Integration'
        },
        'GB_HCP' => new List<String>{
            'Drive Adoption Within NICE-Recommended Patient Cohort',
            'Engage as Immunexis Clinical Lead for Local NHS Trust',
            'Support Submission of Real-World Evidence to NICE'
        },

        'FR_Hospital' => new List<String>{
            'Obtenir l\'inscription sur la Liste des Médicaments Agréés',
            'Intégrer le protocole du service rhumatologie',
            'Développer des champions cliniques au sein du CHU'
        },
        'FR_Clinic' => new List<String>{
            'Référencer Immunexis dans les protocoles du centre',
            'Former l\'équipe soignante aux critères de sélection HAS',
            'Intégrer le programme de soutien aux patients'
        },
        'FR_Insurance' => new List<String>{
            'Soutenir le dossier de remboursement auprès de la HAS',
            'Négocier les conditions Sécurité Sociale',
            'Établir un accord de partage de risque basé sur les résultats'
        },
        'FR_Pharmacy' => new List<String>{
            'Référencer Immunexis à la Pharmacie à Usage Intérieur',
            'Établir un protocole de gestion de la chaîne du froid',
            'Former les pharmaciens aux programmes d\'observance'
        },
        'FR_HCP' => new List<String>{
            'Augmenter la part de prescriptions Immunexis en biothérapie',
            'Former aux critères d\'éligibilité HAS pour la PR',
            'Impliquer dans les publications de données en vie réelle'
        },

        'DE_Hospital' => new List<String>{
            'Aufnahme in die Krankenhausformularliste sichern',
            'Klinische Champions in der Rheumatologie gewinnen',
            'AMNOG-Nutzenbewertung in Klinikprotokoll verankern'
        },
        'DE_Clinic' => new List<String>{
            'Immunexis als bevorzugtes Biologikum etablieren',
            'Infusionsprogramm in der Facharztpraxis einrichten',
            'Arzt für regionale Fortbildungen gewinnen'
        },
        'DE_Insurance' => new List<String>{
            'Rabattvertrag nach §130a SGB V verhandeln',
            'AMNOG-Dossier-Supportpaket einreichen',
            'Selektivvertrag mit bevorzugter Positionierung aushandeln'
        },
        'DE_Pharmacy' => new List<String>{
            'Aufnahme in Apothekenliefernetzwerk für Spezialbiologika',
            'Kühlketten-Lagerprotokoll etablieren',
            'Patientenadhärenzprogramm durch Apotheke integrieren'
        },
        'DE_HCP' => new List<String>{
            'Verordnungsanteil von Immunexis bei Biologika steigern',
            'Als regionalen Meinungsführer für Immunexis gewinnen',
            'Schulung zu Patientenselektionskriterien RA & Onkologie'
        },

        'IT_Hospital' => new List<String>{
            'Inserimento nel Prontuario Terapeutico Ospedaliero',
            'Stabilire protocollo di somministrazione con la farmacia',
            'Sviluppare KOL di reumatologia per supporto AIFA'
        },
        'IT_Clinic' => new List<String>{
            'Inserire Immunexis nel percorso terapeutico del centro',
            'Formare il personale sui criteri di eleggibilità AIFA',
            'Integrare il programma di supporto pazienti SSN'
        },
        'IT_Insurance' => new List<String>{
            'Supportare il dossier di rimborso AIFA per Immunexis',
            'Negoziare i termini di rimborsabilità con il SSN',
            'Stabilire un accordo managed-entry a risultato'
        },
        'IT_Pharmacy' => new List<String>{
            'Registrare Immunexis nella farmacia ospedaliera SSN',
            'Stabilire protocollo gestione della catena del freddo',
            'Formare i farmacisti sui programmi di aderenza'
        },
        'IT_HCP' => new List<String>{
            'Aumentare la quota prescrizioni di Immunexis in biologici',
            'Coinvolgere come KOL per real-world evidence',
            'Formare sui criteri di selezione pazienti AR e oncologia'
        },

        'ES_Hospital' => new List<String>{
            'Inclusión en la Guía Farmacoterapéutica del hospital',
            'Establecer protocolo de administración con farmacia',
            'Desarrollar KOL de reumatología para soporte AEMPS'
        },
        'ES_Clinic' => new List<String>{
            'Posicionar Immunexis como biológico de referencia',
            'Formar al equipo clínico en criterios de selección SNS',
            'Integrar el programa de soporte a pacientes del SNS'
        },
        'ES_Insurance' => new List<String>{
            'Apoyar el expediente de reembolso ante SNS y AEMPS',
            'Negociar acuerdo de riesgo compartido por resultados',
            'Alinear la cobertura con guías de práctica clínica SNS'
        },
        'ES_Pharmacy' => new List<String>{
            'Registrar en red de farmacias hospitalarias SNS',
            'Establecer protocolo de dispensación en cadena de frío',
            'Integrar programa de adherencia de pacientes en farmacia'
        },
        'ES_HCP' => new List<String>{
            'Incrementar prescripciones de Immunexis en biológicos',
            'Involucrar como líder de opinión regional',
            'Formar en criterios de elegibilidad SNS para AR y oncología'
        },

        'JP_Hospital' => new List<String>{
            '院内採用薬リストへのイムネキシス収載を確保する',
            '薬剤部と連携した投与プロトコルを策定する',
            'リウマチ科における医師KOLを育成する'
        },
        'JP_Clinic' => new List<String>{
            '治療アルゴリズムにイムネキシスを組み込む',
            '外来点滴投与体制の整備を支援する',
            '患者サポートプログラムへの登録を促進する'
        },
        'JP_Insurance' => new List<String>{
            '薬価基準収載に向けたデータ提出を支援する',
            '保険償還条件の最適化に向けて厚労省と連携する',
            '費用対効果評価対応の根拠資料を整備する'
        },
        'JP_Pharmacy' => new List<String>{
            '専門薬局ネットワークへの採用を確保する',
            '冷蔵保管・コールドチェーン管理体制を整備する',
            '患者服薬アドヒアランス向上プログラムを導入する'
        },
        'JP_HCP' => new List<String>{
            '生物学的製剤処方におけるシェアを拡大する',
            'RA・オンコロジー適応の患者選択基準を習得してもらう',
            '学術論文・リアルワールドエビデンス創出に参画してもらう'
        },

        'KR_Hospital' => new List<String>{
            '병원 내 의약품 처방집에 이뮤넥시스 등재 확보',
            '류마티스내과 투여 프로토콜 수립 및 약제부 협력',
            '류마티스 분야 KOL 육성 및 심평원 대응 지원'
        },
        'KR_Clinic' => new List<String>{
            '전문 클리닉 치료 알고리즘에 이뮤넥시스 포함',
            '외래 주사 투여 환경 구축 지원',
            '환자 지원 프로그램 등록 및 활성화'
        },
        'KR_Insurance' => new List<String>{
            '심사평가원 급여 등재를 위한 자료 제출 지원',
            '국민건강보험공단과의 약가 협상 전략 수립',
            '성과 기반 리스크 분담 계약 협의'
        },
        'KR_Pharmacy' => new List<String>{
            '전문의약품 유통 네트워크에 이뮤넥시스 등록',
            '냉장 보관 및 콜드체인 관리 프로토콜 수립',
            '환자 복약 순응도 향상 프로그램 도입'
        },
        'KR_HCP' => new List<String>{
            '생물학적 제제 처방 중 이뮤넥시스 점유율 확대',
            'RA 및 종양학 적응증 환자 선택 기준 교육',
            '실사용 데이터 및 임상 연구 참여 유도'
        },

        'BR_Hospital' => new List<String>{
            'Garantir inclusão no RENAME e protocolos PCDT',
            'Estabelecer protocolo de dispensação com farmácia SUS',
            'Desenvolver KOLs de reumatologia para suporte ANVISA'
        },
        'BR_Clinic' => new List<String>{
            'Posicionar no algoritmo de tratamento da clínica',
            'Capacitar equipe nos critérios de elegibilidade PCDT',
            'Integrar ao programa de suporte a pacientes do SUS'
        },
        'BR_Insurance' => new List<String>{
            'Inclusão nas coberturas de planos privados ANS',
            'Negociar acordo de risco compartilhado com operadoras',
            'Alinear cobertura com os protocolos clínicos CONITEC'
        },
        'BR_Pharmacy' => new List<String>{
            'Cadastrar na rede de farmácias especializadas',
            'Estabelecer protocolo de armazenamento em cadeia de frio',
            'Integrar programa de adesão de pacientes à farmácia'
        },
        'BR_HCP' => new List<String>{
            'Aumentar participação nas prescrições de biológicos',
            'Capacitar em critérios ANVISA e PCDT para AR e oncologia',
            'Engajar em geração de evidências de mundo real no SUS'
        },

        'MX_Hospital' => new List<String>{
            'Inclusión en el Cuadro Básico de Medicamentos IMSS',
            'Establecer protocolo de aplicación con servicio de farmacia',
            'Desarrollar KOLs de reumatología para soporte COFEPRIS'
        },
        'MX_Clinic' => new List<String>{
            'Posicionar en el algoritmo de tratamiento del centro',
            'Capacitar al equipo en criterios COFEPRIS para AR',
            'Integrar el programa de soporte a pacientes del IMSS'
        },
        'MX_Insurance' => new List<String>{
            'Inclusión en coberturas IMSS e ISSSTE',
            'Negociar acuerdo de riesgo compartido con aseguradoras',
            'Alinear cobertura con guías de práctica clínica CENETEC'
        },
        'MX_Pharmacy' => new List<String>{
            'Registrar en red de farmacias especializadas COFEPRIS',
            'Establecer protocolo de cadena de frío para dispensación',
            'Integrar programa de adherencia de pacientes a la farmacia'
        },
        'MX_HCP' => new List<String>{
            'Incrementar prescripciones de Immunexis en IMSS',
            'Capacitar en criterios de elegibilidad COFEPRIS para AR',
            'Involucrar en generación de evidencia de mundo real'
        },

        'AR_Hospital' => new List<String>{
            'Inclusión en el Vademécum hospitalario y protocolos ANMAT',
            'Establecer protocolo de infusión con farmacia institucional',
            'Desarrollar KOLs de reumatología para soporte ANMAT'
        },
        'AR_Clinic' => new List<String>{
            'Posicionar en el protocolo terapéutico del centro',
            'Capacitar al equipo en criterios ANMAT para AR',
            'Integrar programa de soporte a pacientes de Obras Sociales'
        },
        'AR_Insurance' => new List<String>{
            'Negociar cobertura con principales Obras Sociales',
            'Apoyar expediente de reembolso ante ANMAT y Superintendencia',
            'Establecer acuerdo de riesgo compartido con prepagas'
        },
        'AR_Pharmacy' => new List<String>{
            'Registrar en red de farmacias especializadas ANMAT',
            'Establecer protocolo de cadena de frío para dispensación',
            'Integrar programa de adherencia a través de Obras Sociales'
        },
        'AR_HCP' => new List<String>{
            'Incrementar la prescripción de Immunexis en biológicos',
            'Capacitar en criterios ANMAT para AR y oncología',
            'Involucrar en publicaciones de evidencia de mundo real'
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
}
