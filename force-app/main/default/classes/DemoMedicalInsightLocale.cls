public class DemoMedicalInsightLocale {

    public static Map<String, List<Map<String, String>>> getInsights(String countryCode) {
        switch on countryCode {
            when 'FR' { return french(); }
            when 'DE' { return german(); }
            when 'IT' { return italian(); }
            when 'ES', 'MX', 'AR' { return spanish(); }
            when 'JP' { return japanese(); }
            when 'KR' { return korean(); }
            when 'BR' { return portuguese(); }
            when 'GB' { return englishGb(); }
            when else { return englishUs(); }
        }
    }

    private static Map<String, String> mi(String n, String c) {
        return new Map<String, String>{ 'Name' => n, 'Content' => c };
    }

    private static Map<String, List<Map<String, String>>> englishUs() {
        return new Map<String, List<Map<String, String>>>{
            'Immunexis' => new List<Map<String, String>>{
                mi('RA patients switching from methotrexate', 'Patient reported inadequate response to methotrexate after 12 weeks. Discussed Immunexis as next-line biologic option with favorable IL-6 inhibition profile. Physician interested in efficacy data for MTX-IR population.'),
                mi('Immunexis dosing flexibility discussion', 'Reviewed subcutaneous vs IV administration options for Immunexis. Physician preferred SC formulation for outpatient setting. Discussed auto-injector training program for nursing staff.'),
                mi('Immunexis real-world evidence review', 'Presented 24-month real-world data showing sustained remission rates with Immunexis in RA patients. Physician noted consistent safety profile aligned with clinical trial findings.'),
                mi('Formulary addition request for Immunexis', 'P&T committee reviewing Immunexis for preferred formulary status. Provided pharmacoeconomic dossier highlighting reduced hospitalization rates vs comparator biologics.'),
                mi('Immunexis biosimilar differentiation', 'Discussed unique MOA advantages of Immunexis vs emerging biosimilars. Physician values the established safety database spanning 8 years of post-market surveillance.'),
                mi('Early RA intervention with Immunexis', 'Rheumatologist shared interest in early biologic intervention for aggressive RA phenotypes. Reviewed Immunexis data in DMARD-naive patients showing rapid ACR50 response.'),
                mi('Immunexis combination therapy outcomes', 'Discussed outcomes of Immunexis plus low-dose methotrexate combination. Physician reported improved DAS28 scores in three recently switched patients.'),
                mi('Immunexis patient support enrollment', 'Enrolled two new patients in the Immunexis patient support program. Nurse coordinator confirmed insurance verification and copay assistance setup completed.'),
                mi('Immunexis safety monitoring protocol', 'Reviewed hepatic monitoring guidelines for Immunexis therapy. Lab protocol aligned with current ACR recommendations for biologic-treated RA patients.'),
                mi('Immunexis infusion center partnership', 'Discussed expanding infusion center hours to accommodate Immunexis IV patients. Center director interested in dedicated biologic infusion scheduling system.')
            },
            'Immunonco' => new List<Map<String, String>>{
                mi('Immunonco checkpoint inhibitor response', 'Oncologist reported durable partial response in NSCLC patient on Immunonco after 4 cycles. PD-L1 expression >50% at baseline correlated with favorable outcome.'),
                mi('Immunonco combination with chemotherapy', 'Reviewed phase III data for Immunonco plus platinum-doublet in first-line NSCLC. Physician noted improved PFS without significant increase in immune-related AEs.'),
                mi('Immunonco biomarker testing discussion', 'Discussed importance of comprehensive biomarker panel before initiating Immunonco. Pathologist agreed to implement reflex PD-L1 and TMB testing on all NSCLC biopsies.'),
                mi('Immunonco irAE management protocol', 'Reviewed immune-related adverse event management algorithm with oncology nursing team. Emphasized early detection of pneumonitis and colitis with Immunonco therapy.'),
                mi('Immunonco tumor board presentation', 'Presented Immunonco clinical data at multidisciplinary tumor board. Committee agreed to include Immunonco in institutional treatment pathway for stage IV NSCLC.'),
                mi('Immunonco second-line efficacy data', 'Shared updated OS data for Immunonco in previously treated NSCLC. Median OS improvement of 4.2 months vs docetaxel generated significant interest from attending physicians.'),
                mi('Immunonco patient selection criteria', 'Discussed optimal patient selection for Immunonco monotherapy. Oncologist emphasized need for ECOG 0-1 performance status and absence of autoimmune comorbidities.'),
                mi('Immunonco real-world survival outcomes', 'Reviewed institutional real-world data showing 18-month OS rate of 42% with Immunonco in NSCLC. Results consistent with pivotal trial data in community oncology setting.'),
                mi('Immunonco sequencing after progression', 'Discussed treatment sequencing options after Immunonco progression. Oncologist considering rechallenge with Immunonco plus targeted agent based on molecular profiling.'),
                mi('Immunonco access and reimbursement', 'Coordinated with pharmacy benefits team on Immunonco prior authorization process. Streamlined approval pathway reduced treatment initiation delay from 14 to 5 days.')
            }
        };
    }

    private static Map<String, List<Map<String, String>>> englishGb() {
        return new Map<String, List<Map<String, String>>>{
            'Immunexis' => new List<Map<String, String>>{
                mi('NICE TA compliance status for Immunexis', 'NICE TA recommends Immunexis for moderate-to-severe RA after inadequate response to two csDMARDs. Trust formulary currently lists Immunexis but ICB has not yet updated local prescribing guidance to reflect preferred status. Action: submit updated cost-effectiveness data to ICB medicines optimisation team.'),
                mi('ICB formulary inclusion progress', 'Met with ICB medicines optimisation pharmacist to discuss Immunexis formulary positioning. Currently Amber-listed requiring specialist initiation. Pharmacist receptive to reviewing traffic light status given NICE TA support and homecare cost savings vs hospital-administered alternatives.'),
                mi('Shared care protocol development', 'Shared care protocol for Immunexis between the Trust rheumatology department and local GP practices is in draft. Key blocker: GP practice leads want clearer monitoring responsibilities and blood test frequency guidance. Follow-up meeting scheduled with practice manager consortium next month.'),
                mi('Traffic light reclassification effort', 'Immunexis currently classified Amber (specialist initiation, GP continuation). Building case for Green classification with the area prescribing committee. Key argument: established safety profile, simple SC administration, and existing homecare infrastructure reduce burden on secondary care.'),
                mi('GP surgery access via practice manager', 'Arranged educational meeting at surgery through practice manager. GP partners have no-rep policy but practice manager agreed to lunchtime session focused on QOF-aligned RA management. Three GPs and two practice nurses confirmed attendance.'),
                mi('QOF alignment for RA management', 'Discussed how early biologic intervention with Immunexis supports QOF RA indicators. Practice nurse noted DAS28 monitoring is already embedded in their recall system. Positioned Immunexis as supporting achievement of tight control targets that align with QOF requirements.'),
                mi('BSRBR registry data presentation', 'Presented latest BSRBR-RA registry data at regional rheumatology network meeting. Real-world data showed Immunexis persistence rates comparable to or better than competitor biologics at 24 months. Two consultants from neighbouring Trusts requested formulary submission packs.'),
                mi('Biosimilar switching pressure', 'Trust pharmacy raising pressure to switch stable Immunexis patients to biosimilar alternatives. Consultant rheumatologist concerned about patient anxiety and nocebo effect. Provided ABPI-compliant switching evidence pack and patient communication templates to support informed shared decision-making.'),
                mi('Homecare service reducing outpatient burden', 'Homecare nursing team delivering Immunexis SC to 34 patients in the Trust catchment, freeing rheumatology day unit capacity. Clinical nurse specialist confirmed zero injection-related hospital contacts in past quarter. Trust management interested in expanding model as part of outpatient transformation programme.'),
                mi('Regional IQVIA data review', 'Reviewed regional IQVIA data at ICB level showing Immunexis biologic market share below national average despite positive NICE TA. Root cause: two large GP federations have not updated their formulary to reflect ICB guidance. Planning engagement with federation prescribing leads.')
            },
            'Immunonco' => new List<Map<String, String>>{
                mi('NICE TA and CDF status for Immunonco', 'Immunonco has positive NICE TA for first-line NSCLC with PD-L1 TPS >=50%. Currently also available via Cancer Drugs Fund for combination use in PD-L1 <50%. Trust oncology pharmacist confirmed Blueteq approval pathway is established but turnaround taking 5+ working days. Action: escalate with CDF team.'),
                mi('Trust formulary pathway for Immunonco', 'Presented Immunonco clinical and cost-effectiveness data to Trust Drug and Therapeutics Committee. Committee agreed to add Immunonco to trust chemotherapy protocols pending pharmacy standard operating procedure update. Expected go-live within 6 weeks.'),
                mi('MDT treatment pathway adoption', 'Lung cancer MDT agreed to include Immunonco in first-line treatment algorithm per NICE guidance. MDT coordinator confirmed pathway will be updated in trust electronic prescribing system. Key win: MDT lead now advocates for Immunonco as preferred IO in PD-L1 high expressors.'),
                mi('SACT data and NHS outcomes monitoring', 'Reviewed trust-level SACT data showing Immunonco real-world outcomes consistent with pivotal trials. 18-month OS rate of 41% across 47 treated patients. Data shared with trust clinical governance team for quality assurance reporting to NHS England.'),
                mi('Immunonco access delays at trust level', 'Identified bottleneck in Immunonco treatment initiation: average 8 working days from MDT decision to first infusion. Root causes: Blueteq submission delays and pharmacy aseptic unit capacity. Working with trust pharmacy lead to implement parallel processing of CDF approval and drug preparation.'),
                mi('Consultant engagement via advisory board', 'Lung cancer consultant attended national Immunonco advisory board (ABPI-compliant, no hospitality beyond light refreshments). Shared insights on real-world irAE management and patient selection. Consultant now willing to present at regional peer-to-peer education event hosted by the trust.'),
                mi('irAE management protocol update', 'Trust updating immune-related adverse event management protocol to align with latest NICE guidance. Oncology CNS team requested Immunonco-specific irAE pocket guide for ward staff. Provided ABPI-certified materials for trust approval process.'),
                mi('Biomarker testing turnaround times', 'Histopathology department reporting 10-day turnaround for PD-L1 testing, delaying Immunonco initiation. Discussed reflex testing protocol with lead pathologist to run PD-L1 automatically on all NSCLC biopsies. If adopted, could reduce time-to-treatment by 5 working days.'),
                mi('Regional cancer alliance engagement', 'Presented Immunonco outcomes data at Cancer Alliance quarterly meeting. Three trusts in the alliance currently using Immunonco; two others still defaulting to older IO. Alliance clinical lead agreed to review standardised treatment pathway across the network.'),
                mi('NHS Long Term Plan alignment', 'Discussed how Immunonco supports NHS Long Term Plan cancer targets: earlier diagnosis, faster treatment initiation, improved one-year survival. Trust management interested in case study showing reduced inpatient bed days with Immunonco versus chemotherapy-only regimens.')
            }
        };
    }

    private static Map<String, List<Map<String, String>>> french() {
        return new Map<String, List<Map<String, String>>>{
            'Immunexis' => new List<Map<String, String>>{
                mi('Evaluation ASMR Immunexis par la HAS', 'La HAS a attribue un ASMR III (amelioration moderee) a Immunexis dans la PR moderee a severe. Le CEPS negocie actuellement le prix rembourse. Le rhumatologue hospitalier attend la decision pour inscrire Immunexis au livret therapeutique de l\'etablissement.'),
                mi('Inscription au livret therapeutique', 'Presentation du dossier Immunexis au comite du medicament de l\'hopital. Le pharmacien hospitalier demande des donnees pharmaco-economiques complementaires avant le vote. Prochain comite dans 6 semaines — action : preparer le dossier medico-economique.'),
                mi('Prescription ville vs hopital Immunexis', 'Immunexis est inscrit sur la liste en ville avec remboursement a 65%. Le medecin generaliste peut renouveler l\'ordonnance initiale du rhumatologue. Discussion avec le medecin traitant sur le protocole de suivi en ville et les bilans biologiques requis.'),
                mi('Strategie ARS et acces regional', 'L\'ARS Ile-de-France a publie un plan regional de sante incluant l\'optimisation des parcours de soins en rhumatologie. Opportunite d\'aligner la strategie Immunexis sur les objectifs regionaux de reduction des hospitalisations evitables.'),
                mi('Donnees IQVIA prescripteur Immunexis', 'Analyse des donnees IQVIA au niveau prescripteur : part de marche Immunexis en hausse de 3 points sur le secteur. Le rhumatologue est le 2e prescripteur de biologiques du territoire. Objectif : consolider la position de premier choix apres echec du methotrexate.'),
                mi('Biosimilaires et pression tarifaire', 'Le pharmacien hospitalier signale une pression croissante pour substituer Immunexis par des biosimilaires. Le chef de service rhumatologie souhaite maintenir Immunexis pour les patients stables. Action : fournir les donnees de persistance et les arguments de non-interchangeabilite.'),
                mi('Parcours de soins coordonne PR', 'Discussion avec le medecin traitant sur le parcours de soins coordonne PR. Le protocole ALD 22 (affection longue duree) facilite le remboursement integral. Le generaliste souhaite un schema de suivi clair pour les patients sous Immunexis avec les bilans biologiques recommandes par la SFR.'),
                mi('Formation DU rhumatologie et Immunexis', 'Trois rhumatologues du service participent au DU de therapeutique en rhumatologie. Opportunite de presenter les donnees Immunexis dans le cadre universitaire. Le Pr coordinateur du DU est favorable a une intervention sur les biotherapies ciblees.'),
                mi('Base transparence et conformite', 'Mise a jour des declarations base transparence pour les interactions avec les professionnels de sante du secteur. Toutes les invitations au congres SFR sont conformes a la charte de la visite medicale. Aucun depassement du seuil de declaration.'),
                mi('HAD et Immunexis a domicile', 'Discussion avec le cadre de sante sur la mise en place d\'Immunexis en hospitalisation a domicile (HAD). Le circuit de dispensation via la pharmacie hospitaliere est operationnel. L\'infirmiere coordinatrice HAD confirme la faisabilite des injections SC a domicile.')
            },
            'Immunonco' => new List<Map<String, String>>{
                mi('Liste en sus et acces Immunonco', 'Immunonco est inscrit sur la liste en sus (hors T2A) pour le CBNPC en premiere ligne. Le pharmacien hospitalier confirme que le financement est securise hors GHS. Action : s\'assurer que le codage PMSI est correct pour chaque administration afin d\'eviter les rejets de facturation.'),
                mi('Presentation en RCP Immunonco', 'Presentation des donnees cliniques Immunonco en reunion de concertation pluridisciplinaire thoracique. La RCP a valide l\'inclusion d\'Immunonco dans le protocole institutionnel CBNPC stade IV avec PD-L1 TPS >= 50%. Le coordonnateur RCP soutiendra la mise a jour du referentiel regional.'),
                mi('Referentiel INCa et Immunonco', 'Le referentiel INCa (Institut National du Cancer) pour le CBNPC recommande Immunonco en premiere ligne. Discussion avec l\'oncologue sur l\'alignement du protocole hospitalier avec les recommandations nationales. Action : fournir le tableau comparatif des referentiels INCa vs ESMO.'),
                mi('Circuit du medicament Immunonco', 'Revue du circuit du medicament Immunonco avec le pharmacien hospitalier. Preparation en unite centralisee de preparation des chimiotherapies (UCPC). Delai de preparation actuel : 48h. Discussion sur l\'optimisation pour reduire a 24h et ameliorer le parcours patient.'),
                mi('ARS et plan cancer regional', 'L\'ARS a lance le volet regional du plan cancer avec objectif de reduction des delais d\'acces au traitement. Immunonco positionne comme levier pour atteindre l\'objectif de premiere administration dans les 15 jours suivant la RCP. Donnees institutionnelles montrent un delai median actuel de 12 jours.'),
                mi('Biomarqueurs et delai diagnostic', 'Le pathologiste signale un delai de 8 jours pour les resultats PD-L1 sur les biopsies CBNPC. Discussion sur le test reflexe PD-L1 + TMB systematique pour accelerer l\'acces a Immunonco. Le chef de service anatomopathologie est favorable a la mise en place d\'ici le prochain trimestre.'),
                mi('Gestion des irAE protocole hospitalier', 'Mise a jour du protocole hospitalier de gestion des effets indesirables immuno-medies avec l\'equipe d\'oncologie. Formation de l\'equipe IDE sur la detection precoce de la pneumopathie et de la colite. Le cadre de sante a planifie deux sessions de formation continue.'),
                mi('Donnees PMSI et medico-economiques', 'Analyse des donnees PMSI montrant une reduction des durees moyennes de sejour chez les patients sous Immunonco vs chimiotherapie seule. Argument cle pour le directeur d\'etablissement dans le contexte de la T2A et de l\'efficience hospitaliere.'),
                mi('Congres ESMO donnees francaises', 'Presentation des donnees francaises de la cohorte Immunonco au congres ESMO. Taux de SG a 18 mois de 43% conforme aux donnees internationales. L\'oncologue du CHU souhaite presenter ces resultats lors de la prochaine journee regionale de cancerologie.'),
                mi('Transparence et conformite oncologie', 'Verification de la conformite des interactions avec les oncologues du territoire. Toutes les participations aux advisory boards et congres sont declarees dans la base transparence. Le responsable conformite valide l\'ensemble des activites du trimestre.')
            }
        };
    }

    private static Map<String, List<Map<String, String>>> german() {
        return new Map<String, List<Map<String, String>>>{
            'Immunexis' => new List<Map<String, String>>{
                mi('AMNOG-Nutzenbewertung Immunexis', 'Der G-BA hat Immunexis einen betrachtlichen Zusatznutzen bei RA nach csDMARD-Versagen zuerkannt. IQWiG-Bewertung stuetzt die Erstattungsverhandlungen mit dem GKV-Spitzenverband. Ergebnis beeinflusst den Erstattungsbetrag ab nachstem Quartal.'),
                mi('Krankenkassen-Erstattung Immunexis', 'Gesprach mit dem Verordnungsberater der AOK zur Immunexis-Wirtschaftlichkeit. Richtgroessenrelevanz geklaert — Immunexis liegt unter dem Tagestherapiekosten-Durchschnitt der Vergleichsbiologika. Verordnungsberater bestaetigt keine Regressgefahr bei leitliniengerechter Verordnung.'),
                mi('KV-Praxisbesuch Immunexis', 'Besuch beim niedergelassenen Rheumatologen in der KV-Region. Arzt berichtet ueber steigende Nachfrage nach SC-Biologika fuer die ambulante Versorgung. Immunexis-Autoinjektor als Vorteil gegenueber Praxis-Infusionen bewertet. Entlastung des Praxispersonals als Argument.'),
                mi('Arzneimittelkommission Immunexis', 'Prasentation des Immunexis-Dossiers vor der Arzneimittelkommission des Krankenhauses. Klinikapotheker fordert Vergleichsdaten zu Tagestherapiekosten. Nachstes AK-Treffen in 4 Wochen — Aktion: pharmakooekonomische Analyse nachreichen.'),
                mi('Biosimilar-Wechseldruck Immunexis', 'Krankenkasse uebt Druck auf Umstellung stabiler Immunexis-Patienten auf Biosimilar aus. Rheumatologe betont Therapietreue und Nocebo-Risiko bei Umstellung. Rabattvertraege der Kasse bevorzugen Biosimilar — Aktion: Daten zur Nicht-Austauschbarkeit bereitstellen.'),
                mi('DGRh-Leitlinie und Immunexis', 'Aktualisierte DGRh-Leitlinie empfiehlt fruehen Biologika-Einsatz bei aggressiver RA. Immunexis positioniert als erste Wahl nach MTX-Versagen gemaess Treat-to-Target-Strategie. Rheumatologe plant Anpassung des Praxis-Therapiealgorithmus.'),
                mi('MVZ-Partnerschaft Immunexis', 'Gesprach mit der aerztlichen Leitung des MVZ Rheumatologie. Drei Rheumatologen im MVZ verordnen regelmaessig Biologika. Immunexis-Schulung fuer MFA geplant — Schwerpunkt Autoinjektor-Anleitung und Patientenbetreuung.'),
                mi('Immunexis Versorgungsforschungsdaten', 'Prasentation deutscher Versorgungsforschungsdaten aus dem RABBIT-Register. Immunexis zeigt hohe Persistenzraten im Vergleich zu anderen Biologika nach 24 Monaten. Rheumatologe interessiert an Poster fuer naechsten DGRh-Kongress.'),
                mi('Selektivvertrag Immunexis Rheumatologie', 'Die Barmer prueft einen Selektivvertrag fuer die rheumatologische Biologika-Versorgung. Immunexis koennte als praeferiertes Biologikum aufgenommen werden. Aktion: Kontakt zum Barmer-Vertragsmanagement herstellen und Vertragsbedingungen sondieren.'),
                mi('Homecare-Versorgung Immunexis', 'Abstimmung mit dem Homecare-Dienstleister zur Immunexis-SC-Versorgung. 28 Patienten erhalten Immunexis im Heimselbstinjektionsprogramm. Apotheker bestaetigt lueckenlose Kuehlkettenlogistik und keine Lieferengpaesse im laufenden Quartal.')
            },
            'Immunonco' => new List<Map<String, String>>{
                mi('AMNOG-Bewertung Immunonco NSCLC', 'Der G-BA hat Immunonco einen erheblichen Zusatznutzen beim NSCLC mit PD-L1 TPS >= 50% in der Erstlinie zuerkannt. Erstattungsbetrag liegt ueber dem Vergleichsniveau. Onkologe begrueet die positive Bewertung fuer die Therapieentscheidung im Tumorboard.'),
                mi('Tumorboard-Integration Immunonco', 'Interdisziplinaeres Tumorboard hat Immunonco in den institutionellen Behandlungspfad NSCLC Stadium IV aufgenommen. Tumorboard-Koordinator aktualisiert die Leitlinie im klinischen Informationssystem. Pathologie stellt Reflex-PD-L1-Testung sicher.'),
                mi('Krankenkassen-Genehmigung Immunonco', 'Abstimmung mit dem MDK-Berater zur Genehmigung von Immunonco bei Off-Label-Indikationen. Fuer die zugelassene Indikation ist keine Einzelfallgenehmigung erforderlich. Onkologe bestaetigt reibungslosen Genehmigungsprozess bei den grossen Kassen.'),
                mi('Onkologische Schwerpunktpraxis Immunonco', 'Besuch der onkologischen Schwerpunktpraxis mit IV-Therapieplatz. Niedergelassener Onkologe fuehrt Immunonco-Erstlinientherapie ambulant durch. Diskussion ueber Therapiemanagement und Nachsorgeprotokoll. Praxis behandelt 12 NSCLC-Patienten mit Immunonco.'),
                mi('Comprehensive Cancer Center Immunonco', 'Prasentation der Immunonco-Daten beim wissenchaftlichen Kolloquium des CCC. Zwei Oberaerzte der Thoraxonkologie interessiert an klinikuebergreifender Auswertung der Ansprechraten. Aktion: Real-World-Datenauswertung mit dem Studiensekretariat abstimmen.'),
                mi('Immunonco irAE-Protokoll Aktualisierung', 'Aktualisierung des klinikinternen Protokolls zur Behandlung immunvermittelter Nebenwirkungen. Schulung des Pflegeteams auf der onkologischen Station zur Frueherkennung von Pneumonitis und Kolitis. Chefarzt hat Immunonco-spezifische SOPs fuer die Notaufnahme angeordnet.'),
                mi('Biomarker-Diagnostik Turnaround', 'Pathologie berichtet 7 Tage Turnaround fuer PD-L1-Testung. Diskussion mit dem Leiter Molekularpathologie ueber Reflex-Testung bei allen NSCLC-Biopsien. Wenn umgesetzt, verkuerzt sich die Zeit bis zum Therapiebeginn um 5 Werktage.'),
                mi('DKG-zertifiziertes Lungenkrebszentrum', 'Das DKG-zertifizierte Lungenkrebszentrum hat Immunonco als Standard-Erstlinientherapie bei PD-L1-High-Patienten festgelegt. Die Zertifizierungsanforderungen unterstuetzen die leitliniengerechte IO-Therapie. Qualitaetsindikatoren werden im naechsten Zertifizierungsaudit erfasst.'),
                mi('Immunonco Versorgungslandschaft ambulant', 'Analyse der regionalen Versorgungslandschaft: drei onkologische Schwerpunktpraxen und zwei Kliniken fuehren Immunonco-Therapie durch. KV-Daten zeigen steigende ambulante IO-Verordnungen. Marktanteil Immunonco in der Region bei 38% — Ziel: 45% bis Jahresende.'),
                mi('Klinische Studien und Immunonco', 'Diskussion ueber laufende klinische Studien mit Immunonco-Kombinationen am Universitaetsklinikum. Studienleiter plant Investigator-Initiated Trial zur Immunonco-Rechallenge nach Progression. Aktion: Unterstuetzung bei der Studienplanung und Sponsoring-Optionen pruefen.')
            }
        };
    }

    private static Map<String, List<Map<String, String>>> italian() {
        return new Map<String, List<Map<String, String>>>{
            'Immunexis' => new List<Map<String, String>>{
                mi('Classificazione AIFA e rimborsabilita Immunexis', 'Immunexis e in Classe A (rimborsabile SSN) con Nota AIFA per la prescrizione nella PR moderata-severa dopo fallimento di due csDMARD. Il reumatologo conferma che la Nota limita la prescrizione ai centri autorizzati. Azione: verificare che l\'ASL abbia aggiornato il prontuario locale.'),
                mi('Inserimento PTR e PTO Immunexis', 'Immunexis e stato inserito nel Prontuario Terapeutico Regionale (PTR) della Lombardia. Ora serve l\'approvazione al Prontuario Terapeutico Ospedaliero (PTO) del singolo presidio. La Commissione Terapeutica si riunisce il mese prossimo — azione: preparare il dossier per il farmacista ospedaliero.'),
                mi('Registro AIFA monitoraggio Immunexis', 'Il reumatologo segnala che la compilazione del Registro AIFA per Immunexis richiede tempo eccessivo. La scheda di monitoraggio prevede visite a 3, 6 e 12 mesi con DAS28 obbligatorio. Discussione su come semplificare il flusso di inserimento dati nel sistema web AIFA.'),
                mi('Distribuzione diretta ASL Immunexis', 'La ASL eroga Immunexis in distribuzione diretta (DD) dalla farmacia ospedaliera. Il paziente ritira il farmaco ogni 4 settimane. Discussione con il direttore di farmacia sulla possibilita di passare alla distribuzione per conto (DPC) tramite farmacie convenzionate per migliorare l\'aderenza.'),
                mi('Pressione biosimilari e gare regionali', 'La Regione ha indetto una gara per i biologici anti-IL-6. Il biosimilare e entrato in gara a prezzo inferiore. Il primario di reumatologia vuole mantenere Immunexis per i pazienti in trattamento stabile. Azione: fornire dati di persistenza e Position Paper SIR sulla non-sostituibilita automatica.'),
                mi('Piano terapeutico e MMG', 'Il piano terapeutico per Immunexis e compilato dal reumatologo del centro prescrittore e rinnovato ogni 6 mesi. Il medico di medicina generale (MMG) non puo prescrivere autonomamente ma gestisce il follow-up. Discussione sul coinvolgimento del MMG nel monitoraggio degli esami ematici.'),
                mi('Appropriatezza prescrittiva e LEA', 'Discussione con il direttore sanitario ASL sull\'appropriatezza prescrittiva dei biologici in reumatologia. Immunexis rientra nei LEA (Livelli Essenziali di Assistenza). Dati regionali mostrano variabilita nella spesa biologica tra ASL — Immunexis posizionato come scelta costo-efficace.'),
                mi('Linee guida SIR e Immunexis', 'Le linee guida SIR (Societa Italiana di Reumatologia) raccomandano l\'impiego precoce di biologici nella PR aggressiva. Presentati dati Immunexis in pazienti DMARD-naive al congresso regionale SIR. Due reumatologi del presidio richiedono il dossier per la commissione terapeutica.'),
                mi('ADI e Immunexis domiciliare', 'Discussione con il responsabile dell\'Assistenza Domiciliare Integrata (ADI) sulla somministrazione di Immunexis SC a domicilio. Il distretto ASL ha un programma infermieristico domiciliare attivo. L\'infermiera del territorio conferma la fattibilita per 12 pazienti nell\'area.'),
                mi('Budget impact e tetto di spesa farmaceutica', 'La Regione monitora il tetto di spesa farmaceutica ospedaliera. Immunexis rientra nel budget del presidio. Il farmacista ospedaliero chiede un\'analisi di budget impact per giustificare l\'aumento delle prescrizioni. Azione: fornire modello budget impact adattato ai costi SSN.')
            },
            'Immunonco' => new List<Map<String, String>>{
                mi('Registro AIFA e accesso Immunonco', 'Immunonco e inserito nel Registro di monitoraggio AIFA per il NSCLC in prima linea con PD-L1 TPS >= 50%. La compilazione della scheda di eleggibilita e obbligatoria prima della prima somministrazione. Il farmacista ospedaliero segnala 3 giorni di attesa per la validazione AIFA — azione: verificare il flusso.'),
                mi('Inserimento PTO e percorso ospedaliero', 'Presentazione del dossier Immunonco alla Commissione Terapeutica del presidio. Il farmacista chiede i dati di costo-efficacia rispetto alla chemioterapia standard. Immunonco e gia nel PTR regionale. Prossima riunione PTO tra 5 settimane — azione: preparare analisi farmacoeconomica con dati AIES.'),
                mi('GOM e algoritmo terapeutico', 'Il Gruppo Oncologico Multidisciplinare (GOM) ha inserito Immunonco nell\'algoritmo di prima linea per il NSCLC stadio IV. Il coordinatore GOM aggiornera il PDTA (Percorso Diagnostico Terapeutico Assistenziale) del presidio. Il patologo conferma il test riflesso PD-L1 su tutte le biopsie polmonari.'),
                mi('Rete Oncologica Regionale Immunonco', 'Presentati dati Immunonco alla Rete Oncologica della Regione. Tre presidi nella rete utilizzano Immunonco; due sono ancora su protocolli precedenti. Il coordinatore della Rete ha concordato una revisione del PDTA regionale per uniformare l\'accesso.'),
                mi('Tempi di accesso e UFA', 'L\'Unita Farmaci Antiblastici (UFA) riporta un tempo di allestimento di 48 ore per Immunonco. Discussione con il responsabile UFA sull\'ottimizzazione del circuito di preparazione. Obiettivo: ridurre il tempo dalla decisione GOM alla prima infusione a meno di 10 giorni lavorativi.'),
                mi('Fondo farmaci innovativi Immunonco', 'Immunonco e classificato come farmaco innovativo da AIFA con accesso al Fondo farmaci innovativi. Questo garantisce il finanziamento extra-budget regionale per 36 mesi. Il direttore di farmacia conferma che non impatta sul tetto di spesa del presidio — argomento chiave per l\'adozione.'),
                mi('Gestione irAE e protocollo istituzionale', 'Aggiornamento del protocollo istituzionale per la gestione degli eventi avversi immuno-mediati. Formazione dell\'equipe infermieristica oncologica sulla rilevazione precoce di polmonite e colite. Il coordinatore infermieristico ha pianificato due sessioni di aggiornamento ECM.'),
                mi('Diagnostica molecolare e turnaround PD-L1', 'L\'anatomia patologica riporta 8 giorni di turnaround per il test PD-L1 sulle biopsie NSCLC. Discussione con il responsabile di anatomia patologica sul test riflesso PD-L1 + TMB sistematico. Se implementato, ridurrebbe il tempo all\'avvio di Immunonco di 5 giorni lavorativi.'),
                mi('Dati AIRTUM e real-world evidence', 'Revisione dei dati AIRTUM (Associazione Italiana Registri Tumori) sulla sopravvivenza nel NSCLC trattato con immunoterapia. Dati real-world italiani mostrano OS a 18 mesi del 40%, coerenti con gli studi registrativi. L\'oncologo del centro propone una presentazione al congresso AIOM.'),
                mi('Compliance e trasparenza Immunonco', 'Verifica della conformita delle interazioni con gli oncologi del territorio. Tutte le partecipazioni ad advisory board e congressi sono registrate nel sistema Farmindustria. Il responsabile compliance conferma la conformita delle attivita del trimestre con il codice deontologico.')
            }
        };
    }

    private static Map<String, List<Map<String, String>>> spanish() {
        return new Map<String, List<Map<String, String>>>{
            'Immunexis' => new List<Map<String, String>>{
                mi('IPT y financiacion SNS Immunexis', 'El Informe de Posicionamiento Terapeutico (IPT) de la AEMPS posiciona Immunexis como alternativa biologica en AR moderada-severa tras fracaso de csDMARD. La CIPM ha fijado el precio de financiacion. Accion: confirmar inclusion en la guia farmacoterapeutica del hospital.'),
                mi('Inclusion en GFT hospitalaria', 'Presentacion del dossier Immunexis a la Comision de Farmacia y Terapeutica del hospital. El farmaceutico hospitalario solicita datos comparativos de coste-efectividad frente a biologicos del concurso publico vigente. Proxima reunion CFT en 4 semanas — accion: preparar analisis farmacoeconomico.'),
                mi('Acceso autonomico Immunexis', 'La Comunidad Autonoma ha incluido Immunexis en su protocolo de biologicos para AR. Sin embargo, el servicio regional de salud (SERMAS) exige visado de inspeccion para la dispensacion. El reumatologo solicita agilizar el tramite del visado para reducir el tiempo hasta el inicio del tratamiento.'),
                mi('Concurso publico y presion biosimilar', 'El hospital ha adjudicado el concurso publico de biologicos anti-IL-6 al biosimilar por precio inferior. El jefe de servicio de reumatologia quiere mantener Immunexis para pacientes estables. Accion: presentar datos de persistencia y posicionamiento de la SER sobre no-sustitucion automatica.'),
                mi('Protocolo de prescripcion y atencion primaria', 'El protocolo de prescripcion de Immunexis exige inicio por reumatologo hospitalario. El medico de atencion primaria gestiona el seguimiento pero no puede prescribir biologicos. Discusion sobre el circuito de coordinacion entre hospital y centro de salud para las analiticas de seguimiento.'),
                mi('Guias SER y Immunexis', 'Las guias de la Sociedad Espanola de Reumatologia (SER) recomiendan intervencion biologica temprana en AR agresiva siguiendo estrategia treat-to-target. Presentados datos de Immunexis en pacientes naive de DMARD en la reunion regional de la SER. Dos reumatologos del area solicitan el dossier.'),
                mi('Variabilidad entre CCAA Immunexis', 'Analisis de la variabilidad de acceso a Immunexis entre Comunidades Autonomas. Madrid y Cataluna tienen protocolos de acceso rapido; Andalucia requiere aprobacion adicional del comite de uso racional. Accion: adaptar la estrategia de acceso a los requisitos especificos de cada CCAA.'),
                mi('Hospital de dia y Immunexis SC', 'El hospital de dia de reumatologia administra Immunexis SC a 28 pacientes. La supervisora de enfermeria confirma cero incidencias de inyeccion en el ultimo trimestre. Discusion con la direccion medica sobre programa de autoadministracion domiciliaria para liberar plazas de hospital de dia.'),
                mi('BIOBADASER y evidencia real', 'Presentados datos del registro BIOBADASER (registro espanol de biologicos en enfermedades reumaticas) sobre Immunexis. Tasas de persistencia a 24 meses superiores a la media de la clase. El reumatologo del hospital propone una comunicacion al congreso nacional de la SER.'),
                mi('Farmacia hospitalaria y dispensacion', 'Reunion con el servicio de farmacia hospitalaria sobre el circuito de dispensacion de Immunexis. Actualmente dispensacion directa en consultas externas cada 4 semanas. El farmaceutico propone dispensacion bimensual con doble dosis para mejorar adherencia y reducir visitas.')
            },
            'Immunonco' => new List<Map<String, String>>{
                mi('IPT e indicacion financiada Immunonco', 'El IPT de la AEMPS posiciona Immunonco en primera linea de CPNM con PD-L1 TPS >= 50%. La financiacion SNS esta aprobada por la CIPM. El oncologico hospitalario confirma inclusion en la guia de practica clinica del servicio. Accion: asegurar que el circuito de farmacia esta operativo.'),
                mi('Comite de tumores y PDTC', 'Presentacion de datos Immunonco en el comite multidisciplinar de tumores toracicos. El comite ha acordado incluir Immunonco en el Protocolo Diagnostico Terapeutico del Centro (PDTC) para CPNM estadio IV. El coordinador actualizara la via clinica en el sistema informatico del hospital.'),
                mi('Acceso autonomico y variabilidad regional', 'Immunonco esta incluido en el protocolo de la Comunidad Autonoma pero los tiempos de acceso varian. En Madrid, inicio en 7 dias desde la decision del comite; en Andalucia, el tramite de uso tutelado anade 5 dias. Accion: mapear los circuitos de cada comunidad para optimizar tiempos.'),
                mi('Comision de farmacia y coste-efectividad', 'La Comision de Farmacia del hospital evalua la relacion coste-efectividad de Immunonco frente a quimioterapia estandar. El farmaceutico solicita datos de coste por AVAC. El acuerdo de riesgo compartido con el SNS refuerza el argumento economico — accion: preparar el dossier con datos espanoles.'),
                mi('Servicio de farmacia y preparacion', 'El servicio de farmacia hospitalaria reporta 24 horas de preparacion para Immunonco en la unidad centralizada de mezclas. Discusion sobre optimizacion del circuito de elaboracion. Objetivo: reducir el tiempo desde la prescripcion hasta la administracion en hospital de dia oncologico.'),
                mi('Red de cancer y PDTC regional', 'Presentacion de resultados Immunonco en la reunion de la red regional de cancer. Cuatro hospitales del area utilizan Immunonco; dos mantienen protocolos anteriores. El coordinador de la red ha acordado revisar el PDTC regional para homogeneizar el acceso a la inmunoterapia.'),
                mi('Gestion irAE y protocolo institucional', 'Actualizacion del protocolo institucional de gestion de efectos adversos inmunomediados. Formacion del equipo de enfermeria oncologica en deteccion precoz de neumonitis y colitis. La supervisora de enfermeria ha planificado dos sesiones de formacion continuada acreditada.'),
                mi('Diagnostico molecular y tiempos PD-L1', 'El servicio de anatomia patologica reporta 9 dias de turnaround para PD-L1 en biopsias CPNM. Discusion con el jefe de servicio sobre test reflejo PD-L1 + TMB sistematico. Si se implementa, reduciria 5 dias el tiempo hasta el inicio de Immunonco.'),
                mi('Datos REDECAN y evidencia real', 'Revision de datos de la Red Espanola de Registros de Cancer (REDECAN) sobre supervivencia en CPNM con inmunoterapia. Datos real-world espanoles muestran SG a 18 meses del 39%, consistentes con ensayos pivotales. El oncologo propone comunicacion al congreso SEOM.'),
                mi('Transparencia y cumplimiento normativo', 'Verificacion de la conformidad de las interacciones con los oncologos del territorio. Todas las actividades estan registradas conforme al Codigo de Buenas Practicas de Farmaindustria. El responsable de compliance confirma la conformidad de las actividades del trimestre.')
            }
        };
    }

    private static Map<String, List<Map<String, String>>> japanese() {
        return new Map<String, List<Map<String, String>>>{
            'Immunexis' => new List<Map<String, String>>{
                mi('薬価収載とNHI償還 Immunexis', 'ImmunexisはPMDA承認後、中医協での薬価算定を経てNHI薬価収載済み。類似薬効比較方式で算定され、有用性加算IIを取得。次回薬価改定での市場拡大再算定リスクについて医薬情報担当者間で情報共有が必要。'),
                mi('院内採用と薬事委員会', '基幹病院の薬事委員会にImmunexis採用申請を提出。薬剤部長はDPC包括評価への影響と高額療養費制度の適用を確認中。次回薬事委員会は来月 — アクション：費用対効果分析と既存生物学的製剤との比較資料を準備。'),
                mi('MR活動とImmunexis情報提供', '大学病院リウマチ科への訪問。教授は日本リウマチ学会（JCR）ガイドラインに沿ったtreat-to-target戦略でのImmunexis位置づけに関心。MR活動ガイドラインに準拠した学術資料を提供。面談時間の確保が課題 — 次回は医局説明会での時間枠を確保予定。'),
                mi('バイオシミラー参入とImmunexis', '後発品企業がIL-6阻害薬バイオシミラーの承認を取得。DPC病院では薬価差による切替圧力が増加。リウマチ専門医はバイオシミラーへの切替時のノセボ効果を懸念。アクション：JCRバイオシミラーポジションステートメントと長期安全性データを提供。'),
                mi('地域連携パスとImmunexis', '地域医療連携パスにおけるImmunexis処方の流れを確認。専門医が処方開始し、かかりつけ医が継続処方する連携体制。地域連携室と協力し、生物学的製剤の連携パス運用マニュアルの更新を支援。紹介元クリニックへの情報提供が課題。'),
                mi('JCRガイドラインとImmunexis', 'JCR最新ガイドラインではMTX不応後の早期生物学的製剤導入を推奨。Immunexisのデータを地方リウマチ研究会で発表。3名のリウマチ専門医が院内採用に向けた検討を開始。次回学術講演会での症例検討に向け準備中。'),
                mi('高額療養費制度とImmunexis', '患者のImmunexis自己負担について高額療養費制度の適用を確認。月額上限を超える分は保険者負担となる。MSW（医療ソーシャルワーカー）と連携し、患者への制度説明と申請手続きの支援体制を構築。'),
                mi('NDB分析とImmunexis処方動向', 'NDB（レセプト情報・特定健診等情報データベース）の分析でImmunexisの地域別処方動向を確認。当エリアの生物学的製剤シェアは全国平均を下回る。根本原因：2つの基幹病院で未採用。処方委員会への働きかけを計画中。'),
                mi('在宅自己注射指導管理料', 'Immunexis SC製剤の在宅自己注射指導管理料の算定を確認。医師の指導のもと、患者が自宅で自己注射を行うことで外来通院の負担軽減が可能。看護師による自己注射手技の指導プログラムを3施設で実施中。'),
                mi('PMDA安全性情報とImmunexis', 'PMDAの医薬品安全性情報にImmunexisの肝機能障害に関する注意喚起が追加。リウマチ科主治医に対し最新の安全性プロファイルと推奨モニタリング項目を説明。適正使用ガイドの改訂版を配布済み。')
            },
            'Immunonco' => new List<Map<String, String>>{
                mi('薬価収載と最適使用推進GL', 'ImmunexisはPD-L1 TPS 50%以上のNSCLC一次治療で薬価収載済み。最適使用推進ガイドラインに基づき、施設要件（がん診療連携拠点病院等）と医師要件を充足する施設での使用が条件。当エリアの対象施設を確認し、未導入施設への働きかけを計画。'),
                mi('キャンサーボードとImmunonco', '集学的キャンサーボードでImmunoncの臨床データを発表。委員会はステージIV NSCLCのクリニカルパスにImmunoncを第一選択として組み込むことを承認。病理部はPD-L1リフレックス検査を全NSCLC生検に導入済み。'),
                mi('DPC制度とImmunonco費用', 'DPC/PDPS制度下でのImmunonco使用について薬剤部と協議。高額薬剤として出来高算定が適用されDPC包括には含まれない。病院経営企画部はImmunonco導入による収益インパクト分析を実施中 — アクション：医療経済データを提供。'),
                mi('がん診療連携拠点病院での採用', 'がん診療連携拠点病院の化学療法委員会にImmunonco採用を申請。レジメン登録と調製プロトコルの整備が必要。薬剤部はクリーンベンチでの無菌調製手順を2週間以内に策定予定。化学療法センターの投与枠確保が課題。'),
                mi('コンパニオン診断とPD-L1検査', '病理診断科でのPD-L1検査ターンアラウンドタイムは現在7営業日。検査部長とリフレックス検査導入について協議。実現すればImmunonco投与開始までの期間を5日短縮可能。コンパニオン診断薬の保険適用も確認済み。'),
                mi('irAE管理と院内プロトコル', '免疫関連有害事象（irAE）管理の院内プロトコルを更新中。腫瘍内科・呼吸器内科・消化器内科による横断的な対応体制を構築。看護部はImmunonco投与患者のirAE早期発見チェックリストを作成し、外来化学療法センターに配備。'),
                mi('肺癌診療ガイドラインとImmunonco', '日本肺癌学会の肺癌診療ガイドラインではPD-L1高発現NSCLCにImmunoncを推奨。地域肺癌カンファレンスでガイドライン準拠の重要性を共有。近隣2施設がImmunoncoのレジメン登録を検討開始。'),
                mi('がんゲノム医療とImmunonco', 'がんゲノム医療中核拠点病院でのコンプリヘンシブ・ゲノム・プロファイリング（CGP）検査との連携を確認。TMB-Highの結果がImmunonco投与判断を支援する追加エビデンスとなる。エキスパートパネルでの議論に向けた資料を準備。'),
                mi('地域がん登録とリアルワールドデータ', '地域がん登録データとNSCLCにおけるImmunoncoのリアルワールドアウトカムを確認。18か月OS率41%でピボタル試験と一致。腫瘍内科教授は日本臨床腫瘍学会（JSMO）での発表を予定。'),
                mi('公正競争規約とImmunonco活動', 'Immunonco関連の医療関係者との交流活動が公正競争規約に準拠していることを確認。学術講演会・アドバイザリーボードの全記録を適正に管理。コンプライアンス部門は今四半期の活動を承認済み。')
            }
        };
    }

    private static Map<String, List<Map<String, String>>> korean() {
        return new Map<String, List<Map<String, String>>>{
            'Immunexis' => new List<Map<String, String>>{
                mi('NHIS 급여 등재 및 약가 협상 Immunexis', 'Immunexis는 MFDS 허가 후 건강보험심사평가원(HIRA)의 경제성 평가를 거쳐 NHIS 급여 등재 완료. 약가는 위험분담제(RSA) 계약 하에 결정. 다음 약가 재평가 시 실사용 데이터에 기반한 약가 인하 리스크를 모니터링 필요.'),
                mi('병원 약사위원회 채택 Immunexis', '상급종합병원 약사위원회에 Immunexis 채택 신청서를 제출. 약제부장은 DRG 포괄수가에 미치는 영향과 본인부담 상한제 적용을 검토 중. 다음 약사위원회는 내달 — 액션: 비용효과성 분석 자료와 기존 생물학적 제제 대비 비교 자료 준비.'),
                mi('전문의약품 처방 및 의원급 연계', 'Immunexis는 류마티스 전문의 처방 개시 후 의원급에서 계속 처방 가능. 건강보험 요양급여 기준에 따라 사전승인(DUR) 시스템을 통한 처방 적정성 확인이 필요. 의원급 류마티스 전문의와의 연계 체계 구축에 대해 논의.'),
                mi('바이오시밀러 대체 압력 Immunexis', '건강보험공단의 약가 협상에서 바이오시밀러 출시에 따른 기존 오리지널 약가 인하 압력이 증가. 류마티스 전문의는 안정적 치료 환자의 강제 전환에 우려 표명. 액션: 대한류마티스학회 바이오시밀러 포지션 스테이트먼트와 장기 안전성 데이터 제공.'),
                mi('대한류마티스학회 가이드라인 Immunexis', '대한류마티스학회(KCR) 최신 가이드라인에서 MTX 불응 후 조기 생물학적 제제 도입을 권고. Immunexis 데이터를 류마티스학회 지역학술대회에서 발표. 2명의 류마티스 전문의가 원내 채택 검토를 시작. 다음 학술심포지엄 증례발표 준비 중.'),
                mi('HIRA 적정성 평가와 Immunexis', 'HIRA의 요양급여 적정성 평가에서 류마티스 질환 관리 지표를 확인. DAS28 모니터링과 treat-to-target 전략의 충실한 이행이 평가 항목에 포함. Immunexis 사용이 적정성 평가 지표 달성을 지원하는 근거 자료를 준비.'),
                mi('본인부담 상한제와 환자 접근성', 'Immunexis 처방 환자의 본인부담금에 대해 본인부담 상한제 적용을 확인. 소득 분위에 따라 연간 상한액이 결정되며, 초과분은 NHIS가 환급. 의료사회복지사와 연계하여 환자 대상 제도 안내 및 신청 지원 체계를 구축.'),
                mi('NIP 데이터와 Immunexis 처방 동향', '국민건강보험공단의 빅데이터(NIP) 분석으로 Immunexis의 지역별 처방 동향을 확인. 해당 권역의 생물학적 제제 시장 점유율이 전국 평균 대비 하회. 원인 분석: 2개 상급종합병원에서 미채택 상태. 약사위원회 접근 전략 수립 중.'),
                mi('자가주사 교육 및 외래 관리', 'Immunexis SC 제형의 자가주사 교육 프로그램을 3개 의료기관에서 운영 중. 전문간호사가 환자 대상 오토인젝터 사용법 교육을 시행. 자가주사로 외래 방문 부담 경감 및 치료 순응도 향상 효과를 모니터링.'),
                mi('MFDS 안전성 정보와 Immunexis', 'MFDS(식약처)의 의약품 안전성 서한에서 Immunexis의 간기능 장애 관련 주의사항이 업데이트. 류마티스과 주치의에게 최신 안전성 프로파일과 권장 모니터링 항목을 설명. 적정사용가이드 개정판을 배포 완료.')
            },
            'Immunonco' => new List<Map<String, String>>{
                mi('NHIS 급여 및 선별급여 Immunonco', 'Immunonco는 PD-L1 TPS 50% 이상의 NSCLC 1차 치료에 NHIS 급여 등재. 선별급여(본인부담률 차등 적용)로 환자 접근성 확보. HIRA의 급여 기준에 따른 사전승인(DUR) 절차 확인. 해당 권역 대상 의료기관의 처방 현황을 모니터링.'),
                mi('다학제 종양 컨퍼런스 Immunonco', '다학제 종양 컨퍼런스(MDT)에서 Immunonco 임상 데이터를 발표. 위원회는 4기 NSCLC 원내 치료 경로에 Immunonco를 1차 선택으로 포함하기로 합의. 병리과는 전체 NSCLC 생검에 PD-L1 리플렉스 검사를 도입 완료.'),
                mi('DRG 수가 및 Immunonco 비용', 'DRG/포괄수가 제도 하에서 Immunonco 사용 시 별도 산정 가능 여부를 약제부와 협의. 고가 항암제로서 행위별수가 산정이 적용되어 DRG 포괄에 포함되지 않음. 경영기획팀은 Immunonco 도입에 따른 수익 영향 분석 중 — 액션: 의료경제 데이터 제공.'),
                mi('암 전문병원 및 지역암센터 채택', '국립암센터 및 지역암센터의 항암화학요법 위원회에 Immunonco 채택을 신청. 레지멘 등록 및 조제 프로토콜 정비가 필요. 약제부는 클린벤치 무균조제 절차를 2주 이내 수립 예정. 항암주사실 투여 슬롯 확보가 과제.'),
                mi('동반진단과 PD-L1 검사', '병리진단과의 PD-L1 검사 턴어라운드 타임은 현재 7영업일. 병리과장과 리플렉스 검사 도입에 대해 협의. 실현 시 Immunonco 투여 개시까지 기간을 5일 단축 가능. 동반진단 검사의 건강보험 적용도 확인 완료.'),
                mi('irAE 관리 및 원내 프로토콜', '면역관련 이상반응(irAE) 관리 원내 프로토콜을 업데이트 중. 종양내과·호흡기내과·소화기내과 간 다학제 대응 체계를 구축. 간호부는 Immunonco 투여 환자의 irAE 조기발견 체크리스트를 작성하여 외래 항암주사실에 배치.'),
                mi('폐암 진료 가이드라인 Immunonco', '대한폐암학회 진료 가이드라인에서 PD-L1 고발현 NSCLC에 Immunonco를 권고. 지역 폐암 학술대회에서 가이드라인 준수의 중요성을 공유. 인근 2개 의료기관이 Immunonco 레지멘 등록을 검토 시작.'),
                mi('암 유전체 의료와 Immunonco', '암 유전체 의료 거점병원에서 포괄적 유전체 프로파일링(CGP) 검사와의 연계를 확인. TMB-High 결과가 Immunonco 투여 판단을 지원하는 추가 근거로 활용. 전문가 패널 토론을 위한 자료 준비 중.'),
                mi('국가암등록 리얼월드 데이터 Immunonco', '국가암등록통계 데이터와 NSCLC에서 Immunonco의 리얼월드 아웃컴을 확인. 18개월 OS율 42%로 피보탈 임상시험과 일치. 종양내과 교수는 대한종양내과학회(KSMO) 학술대회 발표를 계획 중.'),
                mi('공정경쟁규약 준수 Immunonco', 'Immunonco 관련 의료인 교류 활동이 한국제약바이오협회 공정경쟁규약에 부합함을 확인. 학술강연회·자문위원회 전체 기록을 적정하게 관리 중. 컴플라이언스 부서에서 금분기 활동 승인 완료.')
            }
        };
    }

    private static Map<String, List<Map<String, String>>> portuguese() {
        return new Map<String, List<Map<String, String>>>{
            'Immunexis' => new List<Map<String, String>>{
                mi('Pacientes AR apos falha do metotrexato', 'O paciente relatou resposta inadequada ao metotrexato apos 12 semanas. Discutido Immunexis como opcao biologica com perfil favoravel de inibicao de IL-6. O reumatologista solicitou dados de eficacia.'),
                mi('Flexibilidade de dosagem Immunexis', 'Revisao das opcoes de administracao subcutanea vs IV para Immunexis. O medico preferiu a formulacao SC para ambiente ambulatorial. Discutido programa de treinamento em autoinjetor para equipe de enfermagem.'),
                mi('Evidencias do mundo real Immunexis', 'Apresentados dados do mundo real de 24 meses mostrando remissao sustentada com Immunexis na AR. O medico destacou perfil de seguranca consistente com achados de ensaios clinicos.'),
                mi('Solicitacao de inclusao em formulario', 'A comissao de farmacia e terapeutica avalia Immunexis para status preferencial. Fornecido dossie farmacoeconomico destacando reducao de hospitalizacoes vs biologicos comparadores.'),
                mi('Diferenciacao de biossimilares Immunexis', 'Discutidas vantagens do mecanismo de acao do Immunexis frente a biossimilares emergentes. O medico valoriza o banco de dados de seguranca estabelecido com 8 anos de farmacovigilancia.'),
                mi('Intervencao precoce AR com Immunexis', 'O reumatologista interessado em intervencao biologica precoce para fenotipos agressivos de AR. Revisados dados de Immunexis em pacientes virgens de DMARD com resposta ACR50 rapida.'),
                mi('Terapia combinada Immunexis', 'Discutidos resultados da combinacao Immunexis mais metotrexato em dose baixa. O medico relatou melhora nos escores DAS28 em tres pacientes recentemente convertidos.'),
                mi('Programa de apoio Immunexis', 'Inscritos dois novos pacientes no programa de apoio Immunexis. A coordenadora de enfermagem confirmou verificacao de plano de saude e configuracao de assistencia de copagamento.'),
                mi('Protocolo de monitoramento Immunexis', 'Revisadas diretrizes de monitoramento hepatico para terapia com Immunexis. Protocolo laboratorial alinhado com recomendacoes atuais da SBR para pacientes AR em terapia biologica.'),
                mi('Parceria centro de infusao Immunexis', 'Discutida a expansao dos horarios do centro de infusao para pacientes Immunexis IV. O diretor do centro interessado em sistema dedicado de agendamento de biologicos.')
            },
            'Immunonco' => new List<Map<String, String>>{
                mi('Resposta checkpoint Immunonco', 'O oncologista relatou resposta parcial duravel em paciente com CPNPC sob Immunonco apos 4 ciclos. Expressao de PD-L1 >50% no basal correlacionada com resultado favoravel.'),
                mi('Immunonco em combinacao com quimioterapia', 'Revisados dados de fase III para Immunonco mais dubleto de platina em primeira linha de CPNPC. O medico destacou melhora da SLP sem aumento significativo de EA imunomediados.'),
                mi('Discussao de biomarcadores Immunonco', 'Discutida a importancia do painel de biomarcadores antes de iniciar Immunonco. O patologista concordou em implementar teste reflexo de PD-L1 e TMB em todas as biopsias de CPNPC.'),
                mi('Manejo de irAE Immunonco', 'Revisado algoritmo de manejo de eventos adversos imunomediados com a equipe de enfermagem oncologica. Enfase na deteccao precoce de pneumonite e colite com Immunonco.'),
                mi('Apresentacao em reuniao multidisciplinar', 'Apresentados dados clinicos de Immunonco na reuniao multidisciplinar de tumores. O comite concordou em incluir Immunonco no protocolo institucional para CPNPC estagio IV.'),
                mi('Eficacia em segunda linha Immunonco', 'Compartilhados dados atualizados de SG para Immunonco em CPNPC pretratado. Melhora mediana de SG de 4,2 meses vs docetaxel gerou interesse significativo entre os medicos presentes.'),
                mi('Criterios de selecao Immunonco', 'Discutida a selecao otima de pacientes para Immunonco em monoterapia. O oncologista enfatizou a necessidade de status de desempenho ECOG 0-1 e ausencia de comorbidades autoimunes.'),
                mi('Sobrevida real Immunonco', 'Revisados dados institucionais mostrando taxa de SG em 18 meses de 42% com Immunonco no CPNPC. Resultados consistentes com dados de ensaios pivotais na oncologia comunitaria.'),
                mi('Sequenciamento apos progressao Immunonco', 'Discutidas opcoes de sequenciamento apos progressao com Immunonco. O oncologista considera rechallenge com Immunonco mais agente alvo com base no perfil molecular.'),
                mi('Acesso e reembolso Immunonco', 'Coordenacao com equipe de farmacia sobre o processo de autorizacao previa de Immunonco. O fluxo simplificado reduziu o atraso no inicio do tratamento de 14 para 5 dias.')
            }
        };
    }
}
