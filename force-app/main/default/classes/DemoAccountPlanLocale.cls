public class DemoAccountPlanLocale {

    private static final String P = ' - <<N>>';

    public static final Map<String, List<String>> KAM_TEMPLATES_BY_LANG =
        new Map<String, List<String>>();

    private static Map<String, Map<String, List<String>>> archetypesCache;
    private static Map<String, Map<String, List<String>>> objectivesCache;

    private static List<String> l3(String a, String b, String c) {
        return new List<String>{a, b, c};
    }
    private static List<String> l4(String a, String b, String c, String d) {
        return new List<String>{a, b, c, d};
    }
    private static List<String> l6(String a, String b, String c, String d, String e, String f) {
        return new List<String>{a, b, c, d, e, f};
    }

    static {
        KAM_TEMPLATES_BY_LANG.put('FR', l6('Acces au Marche et Contractualisation', 'Chaine d Approvisionnement et Distribution', 'Preparation Comite du Formulaire', 'Preparation Terrain et Execution', 'Analyse des Lacunes Diagnostiques en Rhumatologie', 'Mise en Oeuvre de Nouveaux Protocoles Diagnostiques'));
        KAM_TEMPLATES_BY_LANG.put('DE', l6('Marktzugang und Vertragsgestaltung', 'Lieferkette und Distribution', 'Vorbereitung Arzneimittelkommission Formularliste', 'Aussendienst-Vorbereitung und Umsetzung', 'Analyse diagnostischer Lucken bei Rheumatoider Arthritis', 'Implementierung neuer Diagnoseprotokolle'));
        KAM_TEMPLATES_BY_LANG.put('IT', l6('Accesso al Mercato e Contrattualistica', 'Catena di Approvvigionamento e Distribuzione', 'Preparazione Comitato del Prontuario Terapeutico', 'Preparazione Rete Vendita ed Esecuzione', 'Analisi delle Lacune Diagnostiche in Reumatologia', 'Implementazione Nuovi Protocolli Diagnostici'));
        KAM_TEMPLATES_BY_LANG.put('ES', l6('Acceso al Mercado y Contratacion', 'Cadena de Suministro y Distribucion', 'Preparacion Comite de Formulario Terapeutico', 'Preparacion de Campo y Ejecucion', 'Analisis de Brechas Diagnosticas en Reumatologia', 'Implementacion de Nuevos Protocolos Diagnosticos'));
        KAM_TEMPLATES_BY_LANG.put('JP', l6('市場アクセスと契約', 'サプライチェーンと流通', '薬事委員会準備：処方集パートナーシップ', 'フィールド準備と実行', 'リウマチ診断ギャップ分析', '新規診断プロトコル導入とモニタリング'));
        KAM_TEMPLATES_BY_LANG.put('KR', l6('시장 접근 및 계약', '공급망 및 유통', '약물위원회 준비: 처방집 파트너십', '필드 준비 및 실행', '류마티스 진단 격차 분석', '새 진단 프로토콜 도입 및 모니터링'));
        KAM_TEMPLATES_BY_LANG.put('BR', l6('Acesso ao Mercado e Contratacao', 'Cadeia de Suprimentos e Distribuicao', 'Preparacao do Comite de Formulario Terapeutico', 'Preparacao de Campo e Execucao', 'Analise de Lacunas Diagnosticas em Reumatologia', 'Implementacao de Novos Protocolos Diagnosticos'));
    }

    private static void initArchetypes() {
        if (archetypesCache != null) return;
        archetypesCache = new Map<String, Map<String, List<String>>>();
        Map<String, List<String>> m;

        m = new Map<String, List<String>>();
        m.put('Hospital', l4('Inscription Immunexis au Formulaire' + P, 'Integration Immunexis au Parcours Clinique' + P, 'Defense contre le Switch Biosimilaire Immunexis' + P, 'Centre d Excellence Oncologie Immunexis' + P));
        m.put('Clinic', l4('Partenariat Cabinet Specialise Immunexis' + P, 'Expansion Salle de Perfusion Immunexis' + P, 'Reseau d Adressage Patient Immunexis' + P, 'Activation Site Essai Clinique Immunexis' + P));
        m.put('Insurance', l4('Accord d Acces Payeur Immunexis' + P, 'Contrat Base sur les Resultats Immunexis' + P, 'Optimisation Protocole Therapeutique Immunexis' + P, 'Politique Medicale Immunexis' + P));
        m.put('Pharmacy', l4('Distribution Specialisee Immunexis' + P, 'Integration Services Hub Immunexis' + P, 'Programme d Observance Patient Immunexis' + P, 'Excellence Chaine du Froid Immunexis' + P));
        m.put('HCP', l4('Plan d Engagement Professionnel de Sante Immunexis' + P, 'Developpement Leader d Opinion Immunexis' + P, 'Recrutement Reseau de Conferenciers Immunexis' + P, 'Partenariat Donnees de Vie Reelle Immunexis' + P));
        archetypesCache.put('FR', m);

        m = new Map<String, List<String>>();
        m.put('Hospital', l4('Immunexis Aufnahme in die Arzneimittelliste' + P, 'Immunexis Integration in den Klinischen Pfad' + P, 'Immunexis Biosimilar-Wechsel-Abwehr' + P, 'Immunexis Onkologie-Kompetenzzentrum' + P));
        m.put('Clinic', l4('Immunexis Facharztpraxis-Partnerschaft' + P, 'Immunexis Infusionszentrum-Erweiterung' + P, 'Immunexis Patientenzuweisungsnetzwerk' + P, 'Immunexis Aktivierung Studienzentrum' + P));
        m.put('Insurance', l4('Immunexis Kostentrager-Zugangsvereinbarung' + P, 'Immunexis Ergebnisbasierter Vertrag' + P, 'Immunexis Therapiestufen-Optimierung' + P, 'Immunexis Medizinische Leitliniengestaltung' + P));
        m.put('Pharmacy', l4('Immunexis Spezialdistribution' + P, 'Immunexis Hub-Service-Integration' + P, 'Immunexis Patienten-Adharenz-Programm' + P, 'Immunexis Kuhlketten-Exzellenz' + P));
        m.put('HCP', l4('Immunexis HCP-Engagement-Plan' + P, 'Immunexis KOL-Entwicklung' + P, 'Immunexis Referentennetzwerk-Rekrutierung' + P, 'Immunexis Real-World-Evidence-Partnerschaft' + P));
        archetypesCache.put('DE', m);

        m = new Map<String, List<String>>();
        m.put('Hospital', l4('Inserimento Immunexis nel Prontuario' + P, 'Integrazione Immunexis nel Percorso Clinico' + P, 'Difesa dallo Switch Biosimilare Immunexis' + P, 'Centro di Eccellenza Oncologica Immunexis' + P));
        m.put('Clinic', l4('Partnership Ambulatorio Specialistico Immunexis' + P, 'Espansione Centro Infusionale Immunexis' + P, 'Rete di Invio Pazienti Immunexis' + P, 'Attivazione Sito Sperimentazione Immunexis' + P));
        m.put('Insurance', l4('Accordo di Accesso Immunexis' + P, 'Contratto Basato sui Risultati Immunexis' + P, 'Ottimizzazione Percorso Terapeutico Immunexis' + P, 'Politica Medica Immunexis' + P));
        m.put('Pharmacy', l4('Distribuzione Specializzata Immunexis' + P, 'Integrazione Servizi Hub Immunexis' + P, 'Programma di Aderenza Paziente Immunexis' + P, 'Eccellenza Catena del Freddo Immunexis' + P));
        m.put('HCP', l4('Piano di Coinvolgimento HCP Immunexis' + P, 'Sviluppo Key Opinion Leader Immunexis' + P, 'Reclutamento Rete Relatori Immunexis' + P, 'Partnership Dati Real World Immunexis' + P));
        archetypesCache.put('IT', m);

        m = new Map<String, List<String>>();
        m.put('Hospital', l4('Inclusion Immunexis en el Formulario' + P, 'Integracion Immunexis en la Via Clinica' + P, 'Defensa contra el Cambio a Biosimilar Immunexis' + P, 'Centro de Excelencia Oncologica Immunexis' + P));
        m.put('Clinic', l4('Asociacion Consulta Especializada Immunexis' + P, 'Expansion Sala de Infusion Immunexis' + P, 'Red de Derivacion de Pacientes Immunexis' + P, 'Activacion Sitio de Ensayo Clinico Immunexis' + P));
        m.put('Insurance', l4('Acuerdo de Acceso con Pagador Immunexis' + P, 'Contrato Basado en Resultados Immunexis' + P, 'Optimizacion de Protocolo Terapeutico Immunexis' + P, 'Politica Medica Immunexis' + P));
        m.put('Pharmacy', l4('Distribucion Especializada Immunexis' + P, 'Integracion Servicios Hub Immunexis' + P, 'Programa de Adherencia del Paciente Immunexis' + P, 'Excelencia en Cadena de Frio Immunexis' + P));
        m.put('HCP', l4('Plan de Compromiso HCP Immunexis' + P, 'Desarrollo de Lider de Opinion Immunexis' + P, 'Reclutamiento Red de Ponentes Immunexis' + P, 'Asociacion de Datos del Mundo Real Immunexis' + P));
        archetypesCache.put('ES', m);

        m = new Map<String, List<String>>();
        m.put('Hospital', l4('Immunexis 採用申請計画' + P, 'Immunexis 臨床パスウェイ統合' + P, 'Immunexis バイオシミラー切替防止' + P, 'Immunexis オンコロジーセンター' + P));
        m.put('Clinic', l4('Immunexis 専門クリニック提携' + P, 'Immunexis 点滴室拡充' + P, 'Immunexis 患者紹介ネットワーク' + P, 'Immunexis 治験施設活性化' + P));
        m.put('Insurance', l4('Immunexis 保険者アクセス契約' + P, 'Immunexis 成果報酬型契約' + P, 'Immunexis 処方段階最適化' + P, 'Immunexis 医療ポリシー策定' + P));
        m.put('Pharmacy', l4('Immunexis 専門流通' + P, 'Immunexis ハブサービス統合' + P, 'Immunexis 患者アドヒアランスプログラム' + P, 'Immunexis コールドチェーン管理' + P));
        m.put('HCP', l4('Immunexis HCPエンゲージメント計画' + P, 'Immunexis KOL育成' + P, 'Immunexis スピーカー人材発掘' + P, 'Immunexis リアルワールドエビデンス提携' + P));
        archetypesCache.put('JP', m);

        m = new Map<String, List<String>>();
        m.put('Hospital', l4('Immunexis 약물목록 등재' + P, 'Immunexis 임상경로 통합' + P, 'Immunexis 바이오시밀러 전환 방어' + P, 'Immunexis 종양 전문센터' + P));
        m.put('Clinic', l4('Immunexis 전문 클리닉 파트너십' + P, 'Immunexis 주사실 확장' + P, 'Immunexis 환자 의뢰 네트워크' + P, 'Immunexis 임상시험 사이트 활성화' + P));
        m.put('Insurance', l4('Immunexis 보험사 접근 계약' + P, 'Immunexis 성과 기반 계약' + P, 'Immunexis 처방 단계 최적화' + P, 'Immunexis 의료 정책 수립' + P));
        m.put('Pharmacy', l4('Immunexis 전문 유통' + P, 'Immunexis 허브 서비스 통합' + P, 'Immunexis 환자 순응도 프로그램' + P, 'Immunexis 콜드체인 관리' + P));
        m.put('HCP', l4('Immunexis HCP 참여 계획' + P, 'Immunexis KOL 육성' + P, 'Immunexis 연자 네트워크 모집' + P, 'Immunexis 실사용 데이터 파트너십' + P));
        archetypesCache.put('KR', m);

        m = new Map<String, List<String>>();
        m.put('Hospital', l4('Inclusao Immunexis no Formulario' + P, 'Integracao Immunexis na Via Clinica' + P, 'Defesa contra Troca por Biossimilar Immunexis' + P, 'Centro de Excelencia Oncologica Immunexis' + P));
        m.put('Clinic', l4('Parceria Clinica Especializada Immunexis' + P, 'Expansao da Sala de Infusao Immunexis' + P, 'Rede de Encaminhamento de Pacientes Immunexis' + P, 'Ativacao de Site de Ensaio Clinico Immunexis' + P));
        m.put('Insurance', l4('Acordo de Acesso com Pagador Immunexis' + P, 'Contrato Baseado em Resultados Immunexis' + P, 'Otimizacao de Protocolo Terapeutico Immunexis' + P, 'Politica Medica Immunexis' + P));
        m.put('Pharmacy', l4('Distribuicao Especializada Immunexis' + P, 'Integracao de Servicos Hub Immunexis' + P, 'Programa de Adesao do Paciente Immunexis' + P, 'Excelencia na Cadeia de Frio Immunexis' + P));
        m.put('HCP', l4('Plano de Engajamento HCP Immunexis' + P, 'Desenvolvimento de Lider de Opiniao Immunexis' + P, 'Recrutamento de Rede de Palestrantes Immunexis' + P, 'Parceria de Dados do Mundo Real Immunexis' + P));
        archetypesCache.put('BR', m);
    }

    private static void initObjectives() {
        if (objectivesCache != null) return;
        objectivesCache = new Map<String, Map<String, List<String>>>();
        Map<String, List<String>> m;

        m = new Map<String, List<String>>();
        m.put('Hospital_0', l3('Obtenir l approbation du Comite du Formulaire', 'Etablir le protocole d achat avec la pharmacie', 'Identifier les champions cliniques en rhumatologie'));
        m.put('Hospital_1', l3('Cartographier les protocoles de traitement actuels', 'Integrer Immunexis dans les outils d aide a la decision', 'Former les internes sur les donnees Immunexis'));
        m.put('Hospital_2', l3('Quantifier le cout total vs alternatives biosimilaires', 'Presenter les donnees de differenciation au pharmacien', 'Obtenir un engagement contre le switch non medical'));
        m.put('Hospital_3', l3('Identifier les responsables de la filiere oncologie', 'Planifier les presentations en reunion de concertation', 'Lancer le protocole de diagnostic compagnon'));
        m.put('Clinic_0', l3('Positionner Immunexis comme biologique prefere', 'Etablir le protocole d administration en perfusion', 'Inscrire les medecins au reseau de conferenciers'));
        m.put('Clinic_1', l3('Evaluer la capacite des fauteuils de perfusion', 'Negocier le modele de remboursement', 'Former les infirmieres a l administration d Immunexis'));
        m.put('Clinic_2', l3('Cartographier le reseau de medecins adresseurs', 'Etablir un parcours patient accelere', 'Lancer les supports d education patient'));
        m.put('Clinic_3', l3('Qualifier le site pour un essai clinique Phase IV', 'Former le personnel au recrutement de patients', 'Mettre en place l infrastructure de collecte de donnees'));
        m.put('Insurance_0', l3('Obtenir le remboursement de niveau 2', 'Negocier les criteres de prescription favorables', 'Etablir la voie d exception medicale'));
        m.put('Insurance_1', l3('Concevoir un accord de partage de risques', 'Definir les metriques qualite et methodologie', 'Negocier les garanties de performance'));
        m.put('Insurance_2', l3('Revoir les criteres d autorisation prealable', 'Soumettre le dossier clinique au directeur medical', 'Negocier la reduction des etapes therapeutiques'));
        m.put('Insurance_3', l3('Presenter le dossier de valeur au directeur medical', 'Presenter les donnees medico-economiques', 'Obtenir la mise a jour de la politique medicale'));
        m.put('Pharmacy_0', l3('Integrer au reseau de pharmacies specialisees', 'Etablir le protocole de chaine du froid', 'Integrer la carte de copaiement patient'));
        m.put('Pharmacy_1', l3('Integrer le portail Hub au flux de travail', 'Simplifier la verification des droits', 'Lancer le programme d accueil patient'));
        m.put('Pharmacy_2', l3('Deployer le suivi d observance', 'Former les pharmaciens au conseil patient', 'Etablir le circuit de pharmacovigilance'));
        m.put('Pharmacy_3', l3('Valider les protocoles de surveillance thermique', 'Certifier le personnel a la manipulation des biologiques', 'Mettre en place la gestion des retours et dechets'));
        m.put('HCP_0', l3('Augmenter la part de prescriptions biologiques', 'Former sur les criteres de selection des patients', 'Inscrire au programme de support patient'));
        m.put('HCP_1', l3('Identifier et profiler l influence du leader d opinion', 'Participer aux comites consultatifs et evenements', 'Obtenir un engagement pour des presentations entre pairs'));
        m.put('HCP_2', l3('Recruter pour les programmes de conferenciers', 'Developper la presentation clinique Immunexis', 'Planifier les interventions aux congres'));
        m.put('HCP_3', l3('Proposer une collaboration en donnees de vie reelle', 'Aligner le design de l etude et la population', 'Soutenir la publication et la soumission d abstracts'));
        objectivesCache.put('FR', m);

        m = new Map<String, List<String>>();
        m.put('Hospital_0', l3('Aufnahme in die Arzneimittelliste sichern', 'Buy-and-Bill-Protokoll mit Apotheke etablieren', 'Klinische Champions in der Rheumatologie gewinnen'));
        m.put('Hospital_1', l3('Aktuelle Behandlungsprotokolle kartieren', 'Immunexis in klinische Entscheidungshilfen integrieren', 'Assistenzarzte zu Immunexis-Evidenz schulen'));
        m.put('Hospital_2', l3('Gesamtkosten vs Biosimilar-Alternativen quantifizieren', 'Differenzierungsdaten dem Apothekendirektor prasentieren', 'Commitment gegen nicht-medizinischen Wechsel sichern'));
        m.put('Hospital_3', l3('Leiter der Onkologie-Abteilung identifizieren', 'Tumorboard-Prasentationsplan erstellen', 'Companion-Diagnostik-Protokoll einfuhren'));
        m.put('Clinic_0', l3('Immunexis als bevorzugtes Biologikum positionieren', 'Infusionsprotokoll in der Praxis etablieren', 'Arzte fur das Referentennetzwerk gewinnen'));
        m.put('Clinic_1', l3('Infusionskapazitat und Terminplanung bewerten', 'Erstattungsmodell verhandeln', 'Infusionspersonal in Immunexis-Gabe schulen'));
        m.put('Clinic_2', l3('Zuweisernetzwerk und Volumen kartieren', 'Schnellaufnahmepfad fur Patienten etablieren', 'Patientenaufklarungsmaterial einfuhren'));
        m.put('Clinic_3', l3('Standort fur Phase-IV-Studie qualifizieren', 'Personal zur Patientenrekrutierung schulen', 'Datenerfassungsinfrastruktur aufbauen'));
        m.put('Insurance_0', l3('Erstattung auf Stufe 2 sichern', 'Gunstige Verordnungskriterien verhandeln', 'Medizinischen Ausnahmeweg etablieren'));
        m.put('Insurance_1', l3('Ergebnisbasierte Risikoteilungsvereinbarung entwerfen', 'Qualitatsmetriken und Methodik definieren', 'Leistungsgarantien verhandeln'));
        m.put('Insurance_2', l3('Aktuelle Genehmigungskriterien uberprufen', 'Klinisches Evidenzpaket einreichen', 'Therapiestufenreduktion verhandeln'));
        m.put('Insurance_3', l3('Value Dossier dem Medizinischen Direktor vorstellen', 'Gesundheitsokonomische Daten prasentieren', 'Aktualisierung der Medizinpolitik sichern'));
        m.put('Pharmacy_0', l3('In Spezialapotheken-Netzwerk aufnehmen', 'Kuhlkettenprotokoll etablieren', 'Zuzahlungskarte integrieren'));
        m.put('Pharmacy_1', l3('Hub-Portal in Apothekenworkflow integrieren', 'Leistungsprufung und Genehmigung vereinfachen', 'Patienten-Willkommensprogramm starten'));
        m.put('Pharmacy_2', l3('Adharenz-Monitoring implementieren', 'Apotheker in Patientenberatung schulen', 'Pharmakovigilanz-Workflow etablieren'));
        m.put('Pharmacy_3', l3('Temperaturuberwachungsprotokolle validieren', 'Personal fur Biologika-Handhabung zertifizieren', 'Ruckgabe- und Entsorgungsverfahren einrichten'));
        m.put('HCP_0', l3('Anteil der Biologika-Verordnungen steigern', 'Patientenauswahlkriterien schulen', 'In Patientenunterstutzungsprogramm einschreiben'));
        m.put('HCP_1', l3('KOL-Einfluss und Reichweite profilieren', 'Fur Beirate und Fortbildungen engagieren', 'Commitment fur Peer-to-Peer-Vortrage sichern'));
        m.put('HCP_2', l3('Fur Referentenprogramme rekrutieren', 'Klinische Immunexis-Prasentation entwickeln', 'Vortrage bei Kongressen planen'));
        m.put('HCP_3', l3('Real-World-Evidence-Studie vorschlagen', 'Studiendesign und Patientenpopulation abstimmen', 'Publikation und Abstract-Einreichung unterstutzen'));
        objectivesCache.put('DE', m);

        m = new Map<String, List<String>>();
        m.put('Hospital_0', l3('Ottenere l approvazione del Comitato del Prontuario', 'Stabilire il protocollo di acquisto con la farmacia', 'Costruire campioni clinici in reumatologia'));
        m.put('Hospital_1', l3('Mappare i protocolli di trattamento attuali', 'Integrare Immunexis negli strumenti decisionali clinici', 'Formare specializzandi sulle evidenze Immunexis'));
        m.put('Hospital_2', l3('Quantificare il costo totale vs alternative biosimilari', 'Presentare i dati di differenziazione al farmacista', 'Ottenere l impegno contro lo switch non medico'));
        m.put('Hospital_3', l3('Identificare i responsabili del servizio oncologico', 'Stabilire il calendario delle presentazioni al tumor board', 'Lanciare il protocollo di diagnostica companion'));
        m.put('Clinic_0', l3('Posizionare Immunexis come biologico preferito', 'Stabilire il protocollo di somministrazione infusionale', 'Iscrivere i medici alla rete di relatori'));
        m.put('Clinic_1', l3('Valutare la capacita infusionale e i flussi', 'Negoziare il modello di rimborso', 'Formare gli infermieri sulla somministrazione'));
        m.put('Clinic_2', l3('Mappare la rete dei medici invianti', 'Stabilire un percorso paziente accelerato', 'Lanciare materiali educativi per il paziente'));
        m.put('Clinic_3', l3('Qualificare il sito per studio clinico Fase IV', 'Formare il personale sul reclutamento pazienti', 'Creare l infrastruttura per la raccolta dati'));
        m.put('Insurance_0', l3('Ottenere il rimborso di livello 2', 'Negoziare criteri prescrittivi favorevoli', 'Stabilire il percorso di eccezione medica'));
        m.put('Insurance_1', l3('Progettare un accordo di condivisione del rischio', 'Definire metriche di qualita e metodologia', 'Negoziare garanzie di performance'));
        m.put('Insurance_2', l3('Rivedere i criteri di autorizzazione preventiva', 'Presentare il dossier clinico al direttore medico', 'Negoziare la riduzione dei passaggi terapeutici'));
        m.put('Insurance_3', l3('Presentare il dossier di valore al direttore medico', 'Presentare i dati di economia sanitaria', 'Ottenere l aggiornamento della politica medica'));
        m.put('Pharmacy_0', l3('Inserire nella rete di farmacie specializzate', 'Stabilire il protocollo della catena del freddo', 'Integrare la carta di compartecipazione paziente'));
        m.put('Pharmacy_1', l3('Integrare il portale Hub nel flusso di lavoro', 'Semplificare la verifica dei diritti', 'Lanciare il programma di accoglienza paziente'));
        m.put('Pharmacy_2', l3('Implementare il monitoraggio dell aderenza', 'Formare i farmacisti sul counseling al paziente', 'Stabilire il workflow di farmacovigilanza'));
        m.put('Pharmacy_3', l3('Validare i protocolli di monitoraggio temperatura', 'Certificare il personale sulla gestione dei biologici', 'Implementare le procedure di reso e smaltimento'));
        m.put('HCP_0', l3('Aumentare la quota di prescrizioni biologiche', 'Formare sui criteri di selezione dei pazienti', 'Iscrivere al programma di supporto paziente'));
        m.put('HCP_1', l3('Identificare e profilare l influenza del KOL', 'Coinvolgere in advisory board ed eventi formativi', 'Ottenere l impegno per presentazioni tra pari'));
        m.put('HCP_2', l3('Reclutare per i programmi di relatori', 'Sviluppare la presentazione clinica Immunexis', 'Pianificare interventi ai congressi'));
        m.put('HCP_3', l3('Proporre collaborazione su dati real world', 'Allineare il disegno dello studio e la popolazione', 'Supportare pubblicazione e invio abstract'));
        objectivesCache.put('IT', m);

        m = new Map<String, List<String>>();
        m.put('Hospital_0', l3('Obtener la aprobacion del Comite de Formulario', 'Establecer el protocolo de compra con farmacia', 'Identificar campeones clinicos en reumatologia'));
        m.put('Hospital_1', l3('Mapear los protocolos de tratamiento actuales', 'Integrar Immunexis en herramientas de decision clinica', 'Formar residentes sobre la evidencia de Immunexis'));
        m.put('Hospital_2', l3('Cuantificar el costo total vs alternativas biosimilares', 'Presentar datos de diferenciacion al director de farmacia', 'Obtener compromiso contra el cambio no medico'));
        m.put('Hospital_3', l3('Identificar lideres del servicio de oncologia', 'Establecer calendario de presentaciones en tumor board', 'Lanzar protocolo de diagnostico complementario'));
        m.put('Clinic_0', l3('Posicionar Immunexis como biologico preferido', 'Establecer protocolo de administracion por infusion', 'Inscribir medicos en la red de ponentes'));
        m.put('Clinic_1', l3('Evaluar capacidad de sillones de infusion', 'Negociar el modelo de reembolso', 'Formar enfermeras en la administracion de Immunexis'));
        m.put('Clinic_2', l3('Mapear la red de medicos derivantes', 'Establecer via rapida para pacientes', 'Lanzar materiales de educacion al paciente'));
        m.put('Clinic_3', l3('Calificar el sitio para ensayo clinico Fase IV', 'Formar al personal en reclutamiento de pacientes', 'Establecer infraestructura de recopilacion de datos'));
        m.put('Insurance_0', l3('Obtener el reembolso de nivel 2', 'Negociar criterios de prescripcion favorables', 'Establecer la via de excepcion medica'));
        m.put('Insurance_1', l3('Disenar acuerdo de riesgo compartido', 'Definir metricas de calidad y metodologia', 'Negociar garantias de rendimiento'));
        m.put('Insurance_2', l3('Revisar criterios de autorizacion previa', 'Presentar dossier clinico al director medico', 'Negociar reduccion de escalones terapeuticos'));
        m.put('Insurance_3', l3('Presentar dossier de valor al director medico', 'Presentar datos de economia de la salud', 'Obtener actualizacion de la politica medica'));
        m.put('Pharmacy_0', l3('Incorporar a la red de farmacias especializadas', 'Establecer protocolo de cadena de frio', 'Integrar la tarjeta de copago del paciente'));
        m.put('Pharmacy_1', l3('Integrar el portal Hub en el flujo de trabajo', 'Simplificar la verificacion de derechos', 'Lanzar el programa de bienvenida al paciente'));
        m.put('Pharmacy_2', l3('Implementar el monitoreo de adherencia', 'Formar farmaceuticos en consejo al paciente', 'Establecer el flujo de farmacovigilancia'));
        m.put('Pharmacy_3', l3('Validar protocolos de monitoreo de temperatura', 'Certificar personal en manejo de biologicos', 'Implementar procedimientos de devolucion y desecho'));
        m.put('HCP_0', l3('Aumentar la cuota de prescripciones biologicas', 'Formar en criterios de seleccion de pacientes', 'Inscribir en el programa de apoyo al paciente'));
        m.put('HCP_1', l3('Identificar y perfilar la influencia del KOL', 'Participar en advisory boards y eventos educativos', 'Obtener compromiso para presentaciones entre pares'));
        m.put('HCP_2', l3('Reclutar para programas de ponentes', 'Desarrollar presentacion clinica Immunexis', 'Programar intervenciones en congresos'));
        m.put('HCP_3', l3('Proponer colaboracion en datos del mundo real', 'Alinear diseno del estudio y poblacion', 'Apoyar publicacion y envio de abstracts'));
        objectivesCache.put('ES', m);

        m = new Map<String, List<String>>();
        m.put('Hospital_0', l3('薬事委員会での採用承認を獲得', '薬局との購入プロトコルを確立', 'リウマチ科の臨床チャンピオンを構築'));
        m.put('Hospital_1', l3('現行治療プロトコルをマッピング', 'Immunexisを臨床意思決定ツールに統合', '研修医にImmunexisエビデンスを教育'));
        m.put('Hospital_2', l3('バイオシミラー代替品との総コストを定量化', '差別化データを薬局長に提示', '非医学的切替防止のコミットメントを獲得'));
        m.put('Hospital_3', l3('オンコロジーサービスラインのリーダーを特定', 'キャンサーボード発表スケジュールを策定', 'コンパニオン診断プロトコルを立ち上げ'));
        m.put('Clinic_0', l3('Immunexisを優先バイオ医薬品に位置づけ', '院内点滴投与プロトコルを確立', '医師をスピーカーネットワークに登録'));
        m.put('Clinic_1', l3('点滴チェア容量とスケジューリングを評価', '償還モデルを交渉', '点滴看護師にImmunexis投与を訓練'));
        m.put('Clinic_2', l3('紹介医ネットワークと患者数をマッピング', '患者ファストトラックを確立', '患者教育資料を展開'));
        m.put('Clinic_3', l3('Phase IV臨床試験への参加を適格化', '患者募集のスタッフ訓練', 'データ収集インフラを構築'));
        m.put('Insurance_0', l3('Tier 2の保険収載を確保', '有利な処方基準を交渉', '医学的例外経路を確立'));
        m.put('Insurance_1', l3('成果報酬型リスク分担契約を設計', '品質指標と測定方法を定義', 'パフォーマンス保証を交渉'));
        m.put('Insurance_2', l3('現行の事前承認基準をレビュー', '臨床エビデンスパッケージを提出', '処方段階の軽減を交渉'));
        m.put('Insurance_3', l3('バリュードシエをメディカルディレクターに提示', '医療経済アウトカムデータを発表', '適応拡大のための医療ポリシー更新を確保'));
        m.put('Pharmacy_0', l3('専門薬局ネットワークへの参入', 'コールドチェーンプロトコルを確立', '患者自己負担カードを統合'));
        m.put('Pharmacy_1', l3('Hubポータルを薬局ワークフローに統合', '給付確認と事前承認プロセスを簡素化', '患者ウェルカムプログラムを開始'));
        m.put('Pharmacy_2', l3('アドヒアランスモニタリングを展開', '薬剤師の患者カウンセリング訓練', '有害事象報告ワークフローを確立'));
        m.put('Pharmacy_3', l3('温度監視プロトコルを検証', 'バイオ医薬品取扱い要件のスタッフ認定', '返品廃棄管理手順を実施'));
        m.put('HCP_0', l3('バイオ医薬品処方シェアを拡大', '患者選択基準の研修を実施', '患者サポートプログラムに登録'));
        m.put('HCP_1', l3('KOLの影響力とリーチをプロファイリング', 'アドバイザリーボードと教育イベントに参加', 'ピアプレゼンテーションのコミットメント獲得'));
        m.put('HCP_2', l3('スピーカープログラムへの人材募集', 'Immunexis臨床プレゼンテーション資料を作成', '主要学会での講演をスケジューリング'));
        m.put('HCP_3', l3('リアルワールドエビデンス研究の協力を提案', '研究デザインと対象集団を調整', '論文発表と学会抄録提出を支援'));
        objectivesCache.put('JP', m);

        m = new Map<String, List<String>>();
        m.put('Hospital_0', l3('약물위원회 등재 승인 획득', '약국과 구매 프로토콜 수립', '류마티스과 임상 챔피언 확보'));
        m.put('Hospital_1', l3('현행 치료 프로토콜 매핑', 'Immunexis를 임상 의사결정 도구에 통합', '전공의에게 Immunexis 근거 교육'));
        m.put('Hospital_2', l3('바이오시밀러 대비 총 비용 정량화', '차별화 데이터를 약국장에게 제시', '비의학적 전환 방지 약속 확보'));
        m.put('Hospital_3', l3('종양 서비스 라인 리더 파악', '다학제 종양 회의 발표 일정 수립', '동반진단 프로토콜 시작'));
        m.put('Clinic_0', l3('Immunexis를 선호 바이오의약품으로 포지셔닝', '원내 주사 투여 프로토콜 수립', '의사를 연자 네트워크에 등록'));
        m.put('Clinic_1', l3('주사 의자 용량 및 일정 평가', '상환 모델 협상', '주사 간호사 Immunexis 투여 교육'));
        m.put('Clinic_2', l3('의뢰 의사 네트워크 및 물량 매핑', '환자 패스트트랙 경로 수립', '환자 교육 자료 배포'));
        m.put('Clinic_3', l3('Phase IV 임상시험 사이트 자격 확인', '환자 모집 직원 교육', '데이터 수집 인프라 구축'));
        m.put('Insurance_0', l3('Tier 2 보험 등재 확보', '유리한 처방 기준 협상', '의학적 예외 경로 수립'));
        m.put('Insurance_1', l3('성과 기반 위험 분담 계약 설계', '품질 지표 및 측정 방법 정의', '성과 보증 협상'));
        m.put('Insurance_2', l3('현행 사전 승인 기준 검토', '임상 근거 패키지 제출', '처방 단계 완화 협상'));
        m.put('Insurance_3', l3('가치 자료를 의료 이사에게 제시', '의료 경제 성과 데이터 발표', '적응증 확대 의료 정책 업데이트 확보'));
        m.put('Pharmacy_0', l3('전문 약국 네트워크 가입', '콜드체인 프로토콜 수립', '환자 본인부담 카드 통합'));
        m.put('Pharmacy_1', l3('허브 포털을 약국 워크플로에 통합', '급여 확인 및 사전 승인 프로세스 간소화', '환자 환영 프로그램 시작'));
        m.put('Pharmacy_2', l3('순응도 모니터링 구현', '약사 환자 상담 교육', '이상반응 보고 워크플로 수립'));
        m.put('Pharmacy_3', l3('온도 모니터링 프로토콜 검증', '바이오의약품 취급 직원 인증', '반품 및 폐기 관리 절차 수립'));
        m.put('HCP_0', l3('바이오의약품 처방 점유율 확대', '환자 선택 기준 교육', '환자 지원 프로그램 등록'));
        m.put('HCP_1', l3('KOL 영향력 및 도달 범위 프로파일링', '자문위원회 및 교육 이벤트 참여', '동료 발표 약속 확보'));
        m.put('HCP_2', l3('연자 프로그램 인재 모집', 'Immunexis 임상 발표 자료 개발', '주요 학회 강연 일정 수립'));
        m.put('HCP_3', l3('실사용 데이터 연구 협력 제안', '연구 설계 및 대상 집단 조율', '논문 발표 및 학회 초록 제출 지원'));
        objectivesCache.put('KR', m);

        m = new Map<String, List<String>>();
        m.put('Hospital_0', l3('Obter aprovacao do Comite de Formulario', 'Estabelecer protocolo de compra com a farmacia', 'Identificar lideres clinicos em reumatologia'));
        m.put('Hospital_1', l3('Mapear protocolos de tratamento atuais', 'Integrar Immunexis nas ferramentas de decisao clinica', 'Treinar residentes sobre as evidencias do Immunexis'));
        m.put('Hospital_2', l3('Quantificar custo total vs alternativas biossimilares', 'Apresentar dados de diferenciacao ao diretor de farmacia', 'Obter compromisso contra troca nao medica'));
        m.put('Hospital_3', l3('Identificar lideres do servico de oncologia', 'Estabelecer cronograma de apresentacoes no tumor board', 'Lancar protocolo de diagnostico complementar'));
        m.put('Clinic_0', l3('Posicionar Immunexis como biologico preferido', 'Estabelecer protocolo de administracao por infusao', 'Inscrever medicos na rede de palestrantes'));
        m.put('Clinic_1', l3('Avaliar capacidade de poltronas de infusao', 'Negociar modelo de reembolso', 'Treinar enfermeiros na administracao de Immunexis'));
        m.put('Clinic_2', l3('Mapear rede de medicos encaminhadores', 'Estabelecer via rapida para pacientes', 'Lancar materiais de educacao ao paciente'));
        m.put('Clinic_3', l3('Qualificar o site para ensaio clinico Fase IV', 'Treinar equipe em recrutamento de pacientes', 'Estabelecer infraestrutura de coleta de dados'));
        m.put('Insurance_0', l3('Obter reembolso de nivel 2', 'Negociar criterios de prescricao favoraveis', 'Estabelecer via de excecao medica'));
        m.put('Insurance_1', l3('Desenhar acordo de compartilhamento de risco', 'Definir metricas de qualidade e metodologia', 'Negociar garantias de desempenho'));
        m.put('Insurance_2', l3('Revisar criterios de autorizacao previa', 'Submeter dossie clinico ao diretor medico', 'Negociar reducao de etapas terapeuticas'));
        m.put('Insurance_3', l3('Apresentar dossie de valor ao diretor medico', 'Apresentar dados de economia da saude', 'Obter atualizacao da politica medica'));
        m.put('Pharmacy_0', l3('Incorporar a rede de farmacias especializadas', 'Estabelecer protocolo de cadeia de frio', 'Integrar cartao de copagamento do paciente'));
        m.put('Pharmacy_1', l3('Integrar portal Hub ao fluxo de trabalho', 'Simplificar verificacao de direitos', 'Lancar programa de boas-vindas ao paciente'));
        m.put('Pharmacy_2', l3('Implementar monitoramento de adesao', 'Treinar farmaceuticos em aconselhamento ao paciente', 'Estabelecer fluxo de farmacovigilancia'));
        m.put('Pharmacy_3', l3('Validar protocolos de monitoramento de temperatura', 'Certificar equipe em manuseio de biologicos', 'Implementar procedimentos de devolucao e descarte'));
        m.put('HCP_0', l3('Aumentar participacao em prescricoes biologicas', 'Treinar em criterios de selecao de pacientes', 'Inscrever no programa de apoio ao paciente'));
        m.put('HCP_1', l3('Identificar e perfilar a influencia do KOL', 'Participar de advisory boards e eventos educacionais', 'Obter compromisso para apresentacoes entre pares'));
        m.put('HCP_2', l3('Recrutar para programas de palestrantes', 'Desenvolver apresentacao clinica Immunexis', 'Programar palestras em congressos'));
        m.put('HCP_3', l3('Propor colaboracao em dados do mundo real', 'Alinhar desenho do estudo e populacao', 'Apoiar publicacao e submissao de abstracts'));
        objectivesCache.put('BR', m);
    }

    public static List<String> getCountriesForLang(String langKey) {
        if (langKey == 'ES') return new List<String>{'ES', 'MX', 'AR'};
        return new List<String>{langKey};
    }

    private static String getLangKey(String countryCode) {
        if (countryCode == null) return null;
        if (countryCode == 'MX' || countryCode == 'AR') return 'ES';
        if (countryCode == 'US' || countryCode == 'GB') return null;
        return countryCode;
    }

    public static List<String> getArchetypes(String countryCode, String baseType) {
        initArchetypes();
        String lang = getLangKey(countryCode);
        if (lang != null) {
            Map<String, List<String>> langArchetypes = archetypesCache.get(lang);
            if (langArchetypes != null && langArchetypes.containsKey(baseType)) {
                return langArchetypes.get(baseType);
            }
        }
        return DemoAccountPlanData.PLAN_ARCHETYPES.get(baseType);
    }

    public static List<String> getObjectives(String countryCode, String objKey) {
        initObjectives();
        String lang = getLangKey(countryCode);
        if (lang != null) {
            Map<String, List<String>> langObjectives = objectivesCache.get(lang);
            if (langObjectives != null && langObjectives.containsKey(objKey)) {
                return langObjectives.get(objKey);
            }
        }
        return DemoAccountPlanData.OBJECTIVES.get(objKey);
    }

    public static List<String> getTemplateNames(String countryCode) {
        String lang = getLangKey(countryCode);
        if (lang != null && KAM_TEMPLATES_BY_LANG.containsKey(lang)) {
            return KAM_TEMPLATES_BY_LANG.get(lang);
        }
        return DemoActivityPlanController.KAM_TEMPLATES;
    }

    public static String formatArchetype(String archetype, String accountName) {
        return archetype.replace('<<N>>', accountName);
    }
}
