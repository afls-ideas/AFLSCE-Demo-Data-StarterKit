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
                mi('RA patients switching from methotrexate', 'Patient reported inadequate response to methotrexate after 12 weeks on NHS pathway. Discussed Immunexis as next-line biologic with favourable IL-6 inhibition profile per NICE guidelines.'),
                mi('Immunexis dosing flexibility discussion', 'Reviewed subcutaneous versus IV administration for Immunexis. Consultant rheumatologist preferred SC for outpatient clinic. Discussed homecare nursing training programme.'),
                mi('Immunexis real-world evidence review', 'Presented 24-month real-world data from UK biologics registry showing sustained remission with Immunexis. Consultant noted safety profile consistent with BSRBR data.'),
                mi('NICE pathway update for Immunexis', 'Discussed updated NICE technology appraisal for Immunexis in moderate-to-severe RA. Trust formulary committee reviewing for preferred biologic status.'),
                mi('Immunexis biosimilar differentiation', 'Discussed clinical differentiation of Immunexis versus emerging biosimilars. Consultant values established long-term safety database from post-marketing surveillance.'),
                mi('Early RA intervention with Immunexis', 'Rheumatology consultant interested in early biologic intervention for aggressive RA. Reviewed Immunexis data in DMARD-naive cohort showing rapid ACR50 response.'),
                mi('Immunexis combination therapy outcomes', 'Discussed Immunexis plus low-dose methotrexate combination outcomes. Registrar reported improved DAS28 scores in recently switched patients at rheumatology clinic.'),
                mi('Immunexis patient support programme', 'Enrolled patients in Immunexis patient support programme. Specialist nurse confirmed homecare delivery and injection training arranged through NHS trust pathway.'),
                mi('Immunexis safety monitoring protocol', 'Reviewed hepatic monitoring guidelines for Immunexis per BSR recommendations. Laboratory protocol aligned with trust biologic monitoring standard operating procedures.'),
                mi('Immunexis homecare service expansion', 'Discussed expanding homecare provision for Immunexis SC patients. Clinical nurse specialist keen to reduce outpatient attendance through supported self-injection programme.')
            },
            'Immunonco' => new List<Map<String, String>>{
                mi('Immunonco checkpoint inhibitor response', 'Consultant oncologist reported durable partial response in NSCLC patient on Immunonco after 4 cycles. PD-L1 TPS >50% at baseline per local pathology assessment.'),
                mi('Immunonco combination with chemotherapy', 'Reviewed phase III data for Immunonco plus platinum-doublet in first-line NSCLC. Consultant noted improved PFS without significant increase in immune-related AEs.'),
                mi('Immunonco biomarker testing discussion', 'Discussed comprehensive biomarker panel before initiating Immunonco. Histopathologist agreed to implement reflex PD-L1 and TMB testing on all NSCLC specimens.'),
                mi('Immunonco irAE management protocol', 'Reviewed immune-related adverse event management algorithm with oncology CNS team. Emphasised early detection of pneumonitis and colitis per trust guidelines.'),
                mi('Immunonco MDT presentation', 'Presented Immunonco clinical data at multidisciplinary team meeting. MDT agreed to include Immunonco in trust treatment pathway for stage IV NSCLC per NICE guidance.'),
                mi('Immunonco second-line efficacy data', 'Shared updated OS data for Immunonco in previously treated NSCLC. Median OS improvement of 4.2 months versus docetaxel noted by attending consultants at lung cancer MDT.'),
                mi('Immunonco patient selection criteria', 'Discussed optimal patient selection for Immunonco monotherapy. Oncologist emphasised need for WHO performance status 0-1 and absence of autoimmune comorbidities.'),
                mi('Immunonco real-world survival outcomes', 'Reviewed SACT data showing 18-month OS rate of 42% with Immunonco in NSCLC. Results consistent with pivotal trial findings across NHS cancer centres.'),
                mi('Immunonco sequencing after progression', 'Discussed treatment sequencing after Immunonco progression. Consultant considering rechallenge with Immunonco plus targeted agent based on molecular tumour board recommendation.'),
                mi('Immunonco CDF access pathway', 'Coordinated with trust pharmacy on Immunonco Cancer Drugs Fund application. Streamlined approval reduced treatment initiation delay through Blueteq submission process.')
            }
        };
    }

    private static Map<String, List<Map<String, String>>> french() {
        return new Map<String, List<Map<String, String>>>{
            'Immunexis' => new List<Map<String, String>>{
                mi('Patients PR en echec du methotrexate', 'Le patient a signale une reponse inadequate au methotrexate apres 12 semaines. Discussion sur Immunexis comme option biologique avec un profil d\'inhibition de l\'IL-6 favorable. Le rhumatologue souhaite les donnees d\'efficacite.'),
                mi('Flexibilite du dosage Immunexis', 'Revue des options d\'administration sous-cutanee vs IV pour Immunexis. Le medecin prefere la formulation SC en ambulatoire. Discussion sur la formation du personnel infirmier a l\'auto-injecteur.'),
                mi('Donnees en vie reelle Immunexis', 'Presentation des donnees en vie reelle sur 24 mois montrant une remission soutenue avec Immunexis dans la PR. Le medecin note un profil de securite coherent avec les essais cliniques.'),
                mi('Demande d\'inscription au formulaire', 'Le comite therapeutique examine Immunexis pour le statut preferentiel. Dossier pharmaco-economique fourni soulignant la reduction des hospitalisations par rapport aux biologiques comparateurs.'),
                mi('Differenciation biosimilaire Immunexis', 'Discussion des avantages du mecanisme d\'action d\'Immunexis face aux biosimilaires. Le medecin valorise la base de donnees de securite etablie sur 8 ans de pharmacovigilance.'),
                mi('Intervention precoce PR avec Immunexis', 'Le rhumatologue s\'interesse a l\'intervention biologique precoce pour les phenotypes PR agressifs. Revue des donnees Immunexis chez les patients naifs de DMARD montrant une reponse ACR50 rapide.'),
                mi('Bitherapie Immunexis et methotrexate', 'Discussion des resultats de la bitherapie Immunexis plus methotrexate faible dose. Le medecin rapporte une amelioration des scores DAS28 chez trois patients recemment switches.'),
                mi('Programme d\'accompagnement Immunexis', 'Inscription de deux nouveaux patients au programme de soutien Immunexis. L\'infirmiere coordinatrice confirme la verification d\'assurance et la mise en place de l\'aide financiere.'),
                mi('Protocole de suivi Immunexis', 'Revue des recommandations de surveillance hepatique sous Immunexis. Le protocole de laboratoire est aligne sur les recommandations actuelles de la SFR pour les patients PR sous biologique.'),
                mi('Partenariat centre de perfusion', 'Discussion de l\'extension des horaires du centre de perfusion pour les patients Immunexis IV. Le directeur du centre interesse par un systeme de planification dedie aux biologiques.')
            },
            'Immunonco' => new List<Map<String, String>>{
                mi('Reponse au checkpoint Immunonco', 'L\'oncologue rapporte une reponse partielle durable chez un patient CBNPC sous Immunonco apres 4 cycles. L\'expression PD-L1 >50% a l\'inclusion est correlee a un resultat favorable.'),
                mi('Immunonco en association chimiotherapie', 'Revue des donnees de phase III Immunonco plus doublet de platine en premiere ligne CBNPC. Le medecin note une amelioration de la SSP sans augmentation significative des EI immuno-medies.'),
                mi('Discussion biomarqueurs Immunonco', 'Discussion de l\'importance du panel de biomarqueurs avant l\'initiation d\'Immunonco. Le pathologiste accepte de mettre en place le test reflexe PD-L1 et TMB sur toutes les biopsies CBNPC.'),
                mi('Gestion des EI immunitaires Immunonco', 'Revue de l\'algorithme de gestion des effets indesirables immuno-medies avec l\'equipe infirmiere d\'oncologie. Accent sur la detection precoce de la pneumopathie et de la colite sous Immunonco.'),
                mi('Presentation en RCP Immunonco', 'Presentation des donnees cliniques Immunonco en reunion de concertation pluridisciplinaire. Le comite a accepte d\'inclure Immunonco dans le protocole institutionnel pour le CBNPC stade IV.'),
                mi('Efficacite en deuxieme ligne Immunonco', 'Partage des donnees actualisees de SG pour Immunonco dans le CBNPC pretraite. L\'amelioration mediane de SG de 4,2 mois vs docetaxel a suscite un interet significatif.'),
                mi('Criteres de selection Immunonco', 'Discussion de la selection optimale des patients pour Immunonco en monotherapie. L\'oncologue souligne la necessite d\'un indice de performance ECOG 0-1 et l\'absence de comorbidites auto-immunes.'),
                mi('Survie en vie reelle Immunonco', 'Revue des donnees institutionnelles montrant un taux de SG a 18 mois de 42% avec Immunonco dans le CBNPC. Resultats coherents avec les donnees des essais pivots en pratique courante.'),
                mi('Sequencage apres progression Immunonco', 'Discussion des options de sequencage apres progression sous Immunonco. L\'oncologue envisage une reprise d\'Immunonco associe a une therapie ciblee selon le profil moleculaire.'),
                mi('Acces et remboursement Immunonco', 'Coordination avec l\'equipe de pharmacie sur le processus d\'autorisation prealable d\'Immunonco. Le parcours simplifie a reduit le delai d\'initiation du traitement de 14 a 5 jours.')
            }
        };
    }

    private static Map<String, List<Map<String, String>>> german() {
        return new Map<String, List<Map<String, String>>>{
            'Immunexis' => new List<Map<String, String>>{
                mi('RA-Patienten nach Methotrexat-Versagen', 'Patient berichtete unzureichendes Ansprechen auf Methotrexat nach 12 Wochen. Immunexis als nachste biologische Option mit gunstigem IL-6-Hemmungsprofil besprochen. Rheumatologe interessiert an Wirksamkeitsdaten.'),
                mi('Immunexis Dosierungsflexibilitat', 'Subkutane vs. IV-Verabreichungsoptionen fur Immunexis besprochen. Arzt bevorzugt SC-Formulierung fur ambulante Behandlung. Schulungsprogramm fur Pflegepersonal zum Autoinjektor diskutiert.'),
                mi('Immunexis Real-World-Evidenz', 'Prasentation der 24-monatigen Real-World-Daten mit anhaltender Remission unter Immunexis bei RA. Arzt stellte konsistentes Sicherheitsprofil fest, das mit klinischen Studienergebnissen ubereinstimmt.'),
                mi('Immunexis Formularlisten-Antrag', 'Arzneimittelkommission pruft Immunexis fur den bevorzugten Formularlisten-Status. Pharmakookonomisches Dossier mit reduzierten Hospitalisierungsraten im Vergleich zu Komparator-Biologika vorgelegt.'),
                mi('Immunexis Biosimilar-Differenzierung', 'Vorteile des Wirkmechanismus von Immunexis gegenuber Biosimilars besprochen. Arzt schatzt die etablierte Sicherheitsdatenbank uber 8 Jahre Post-Marketing-Uberwachung.'),
                mi('Fruhe RA-Intervention mit Immunexis', 'Rheumatologe interessiert an fruher biologischer Intervention bei aggressiven RA-Phanotypen. Immunexis-Daten bei DMARD-naiven Patienten mit schnellem ACR50-Ansprechen besprochen.'),
                mi('Immunexis Kombinationstherapie', 'Ergebnisse der Immunexis-Kombination mit niedrig dosiertem Methotrexat besprochen. Arzt berichtete verbesserte DAS28-Scores bei drei kurzlich umgestellten Patienten.'),
                mi('Immunexis Patientenunterstutzung', 'Zwei neue Patienten im Immunexis-Patientenunterstutzungsprogramm eingeschrieben. Pflegekoordinatorin bestatigte Versicherungsprufung und Einrichtung der Zuzahlungshilfe.'),
                mi('Immunexis Sicherheitsmonitoring', 'Hepatische Uberwachungsrichtlinien fur Immunexis-Therapie besprochen. Laborprotokoll stimmt mit aktuellen DGRh-Empfehlungen fur biologisch behandelte RA-Patienten uberein.'),
                mi('Immunexis Infusionszentrum-Partnerschaft', 'Erweiterung der Infusionszentrum-Zeiten fur Immunexis-IV-Patienten besprochen. Zentrumsleiter interessiert an dediziertem Biologika-Infusionsplanungssystem.')
            },
            'Immunonco' => new List<Map<String, String>>{
                mi('Immunonco Checkpoint-Inhibitor-Ansprechen', 'Onkologe berichtete dauerhaftes partielles Ansprechen bei NSCLC-Patient unter Immunonco nach 4 Zyklen. PD-L1-Expression >50% zu Studienbeginn korrelierte mit gunstigem Ergebnis.'),
                mi('Immunonco Kombination mit Chemotherapie', 'Phase-III-Daten fur Immunonco plus Platin-Doublet in der Erstlinie NSCLC besprochen. Arzt stellte verbesserte PFS ohne signifikante Zunahme immunvermittelter Nebenwirkungen fest.'),
                mi('Immunonco Biomarker-Testung', 'Bedeutung eines umfassenden Biomarker-Panels vor Immunonco-Einleitung besprochen. Pathologe stimmte der Implementierung von Reflex-PD-L1- und TMB-Testung bei allen NSCLC-Biopsien zu.'),
                mi('Immunonco irAE-Management', 'Algorithmus zur Behandlung immunvermittelter Nebenwirkungen mit dem onkologischen Pflegeteam besprochen. Fruherkennung von Pneumonitis und Kolitis unter Immunonco betont.'),
                mi('Immunonco Tumorboard-Prasentation', 'Klinische Daten zu Immunonco im interdisziplinaren Tumorboard vorgestellt. Komitee stimmte der Aufnahme von Immunonco in den institutionellen Behandlungspfad fur Stadium IV NSCLC zu.'),
                mi('Immunonco Zweitlinien-Wirksamkeit', 'Aktualisierte OS-Daten fur Immunonco bei vorbehandeltem NSCLC geteilt. Mediane OS-Verbesserung von 4,2 Monaten vs. Docetaxel erregte erhebliches Interesse der behandelnden Arzte.'),
                mi('Immunonco Patientenauswahl', 'Optimale Patientenselektion fur Immunonco-Monotherapie besprochen. Onkologe betonte ECOG-Performance-Status 0-1 und Abwesenheit autoimmuner Komorbiditaten als Voraussetzung.'),
                mi('Immunonco Real-World-Uberlebensdaten', 'Institutionelle Real-World-Daten mit 18-Monats-OS-Rate von 42% unter Immunonco bei NSCLC besprochen. Ergebnisse konsistent mit Zulassungsstudiendaten in der Regelversorgung.'),
                mi('Immunonco Sequenzierung nach Progression', 'Behandlungssequenzierung nach Immunonco-Progression besprochen. Onkologe erwagt Rechallenge mit Immunonco plus zielgerichteter Therapie basierend auf molekularer Profilierung.'),
                mi('Immunonco Zugang und Erstattung', 'Koordination mit Krankenkassen-Team zum Immunonco-Genehmigungsverfahren. Vereinfachter Bewilligungspfad reduzierte Behandlungsbeginnsverzogerung von 14 auf 5 Tage.')
            }
        };
    }

    private static Map<String, List<Map<String, String>>> italian() {
        return new Map<String, List<Map<String, String>>>{
            'Immunexis' => new List<Map<String, String>>{
                mi('Pazienti AR in fallimento da metotrexato', 'Il paziente ha riportato risposta inadeguata al metotrexato dopo 12 settimane. Discusso Immunexis come opzione biologica con profilo favorevole di inibizione dell\'IL-6. Il reumatologo richiede dati di efficacia.'),
                mi('Flessibilita posologica Immunexis', 'Revisione delle opzioni di somministrazione sottocutanea vs IV per Immunexis. Il medico preferisce la formulazione SC in ambito ambulatoriale. Discusso programma di formazione infermieristica sull\'autoiniettore.'),
                mi('Evidenze real-world Immunexis', 'Presentati dati real-world a 24 mesi che mostrano remissione sostenuta con Immunexis nell\'AR. Il medico nota un profilo di sicurezza coerente con i risultati degli studi clinici.'),
                mi('Richiesta inserimento in prontuario', 'La commissione terapeutica sta valutando Immunexis per lo status preferenziale. Fornito dossier farmacoeconomico che evidenzia la riduzione delle ospedalizzazioni rispetto ai biologici comparatori.'),
                mi('Differenziazione biosimilari Immunexis', 'Discussi i vantaggi del meccanismo d\'azione di Immunexis rispetto ai biosimilari emergenti. Il medico apprezza il database di sicurezza consolidato in 8 anni di farmacovigilanza post-marketing.'),
                mi('Intervento precoce AR con Immunexis', 'Il reumatologo e interessato all\'intervento biologico precoce per fenotipi AR aggressivi. Revisionati dati Immunexis in pazienti DMARD-naive con rapida risposta ACR50.'),
                mi('Terapia combinata Immunexis', 'Discussi gli esiti della combinazione Immunexis piu metotrexato a basso dosaggio. Il medico riporta miglioramento dei punteggi DAS28 in tre pazienti recentemente convertiti.'),
                mi('Programma supporto pazienti Immunexis', 'Iscritti due nuovi pazienti al programma di supporto Immunexis. L\'infermiera coordinatrice conferma la verifica assicurativa e la configurazione dell\'assistenza alla compartecipazione.'),
                mi('Protocollo monitoraggio Immunexis', 'Revisionate le linee guida di monitoraggio epatico per la terapia con Immunexis. Il protocollo di laboratorio e allineato alle raccomandazioni SIR per i pazienti AR in terapia biologica.'),
                mi('Partnership centro infusionale', 'Discussa l\'espansione degli orari del centro infusionale per i pazienti Immunexis IV. Il direttore del centro interessato a un sistema di programmazione dedicato ai biologici.')
            },
            'Immunonco' => new List<Map<String, String>>{
                mi('Risposta checkpoint Immunonco', 'L\'oncologo riporta risposta parziale duratura in paziente NSCLC in trattamento con Immunonco dopo 4 cicli. Espressione PD-L1 >50% al basale correlata con esito favorevole.'),
                mi('Immunonco in combinazione con chemioterapia', 'Revisionati dati di fase III per Immunonco piu doppietta di platino in prima linea NSCLC. Il medico nota miglioramento della PFS senza aumento significativo degli EA immunomediati.'),
                mi('Discussione biomarcatori Immunonco', 'Discussa l\'importanza del pannello biomarcatori prima dell\'avvio di Immunonco. Il patologo ha accettato di implementare il test riflesso PD-L1 e TMB su tutte le biopsie NSCLC.'),
                mi('Gestione irAE Immunonco', 'Revisionato l\'algoritmo di gestione degli eventi avversi immunomediati con il team infermieristico oncologico. Enfasi sulla rilevazione precoce di polmonite e colite con Immunonco.'),
                mi('Presentazione GOM Immunonco', 'Presentati dati clinici Immunonco al gruppo oncologico multidisciplinare. Il comitato ha concordato l\'inclusione di Immunonco nel percorso terapeutico istituzionale per NSCLC stadio IV.'),
                mi('Efficacia seconda linea Immunonco', 'Condivisi dati OS aggiornati per Immunonco nel NSCLC pretrattato. Miglioramento mediano di OS di 4,2 mesi vs docetaxel ha generato significativo interesse tra i medici presenti.'),
                mi('Criteri di selezione Immunonco', 'Discussa la selezione ottimale dei pazienti per Immunonco in monoterapia. L\'oncologo sottolinea la necessita di performance status ECOG 0-1 e assenza di comorbidita autoimmuni.'),
                mi('Sopravvivenza real-world Immunonco', 'Revisionati dati istituzionali che mostrano tasso di OS a 18 mesi del 42% con Immunonco nel NSCLC. Risultati coerenti con i dati degli studi registrativi nella pratica clinica.'),
                mi('Sequenziamento post-progressione Immunonco', 'Discusse opzioni di sequenziamento dopo progressione con Immunonco. L\'oncologo considera il rechallenge con Immunonco piu agente mirato sulla base del profilo molecolare.'),
                mi('Accesso e rimborso Immunonco', 'Coordinamento con il team farmacia ospedaliera sul processo di autorizzazione Immunonco. Il percorso semplificato ha ridotto il ritardo nell\'avvio del trattamento da 14 a 5 giorni.')
            }
        };
    }

    private static Map<String, List<Map<String, String>>> spanish() {
        return new Map<String, List<Map<String, String>>>{
            'Immunexis' => new List<Map<String, String>>{
                mi('Pacientes AR tras fracaso de metotrexato', 'El paciente reporto respuesta inadecuada al metotrexato tras 12 semanas. Se discutio Immunexis como opcion biologica con perfil favorable de inhibicion de IL-6. El reumatologo solicita datos de eficacia.'),
                mi('Flexibilidad de dosificacion Immunexis', 'Revision de opciones de administracion subcutanea vs IV para Immunexis. El medico prefiere la formulacion SC para consulta ambulatoria. Se discutio programa de capacitacion en autoinyector para enfermeria.'),
                mi('Evidencia del mundo real Immunexis', 'Presentacion de datos del mundo real a 24 meses mostrando remision sostenida con Immunexis en AR. El medico destaca perfil de seguridad consistente con hallazgos de ensayos clinicos.'),
                mi('Solicitud de inclusion en formulario', 'El comite de farmacia y terapeutica evalua Immunexis para estatus preferencial. Se proporciono dossier farmacoeconomico destacando reduccion de hospitalizaciones vs biologicos comparadores.'),
                mi('Diferenciacion de biosimilares Immunexis', 'Se discutieron ventajas del mecanismo de accion de Immunexis frente a biosimilares emergentes. El medico valora la base de datos de seguridad establecida con 8 anos de farmacovigilancia.'),
                mi('Intervencion temprana AR con Immunexis', 'El reumatologo se interesa en intervencion biologica temprana para fenotipos agresivos de AR. Se revisaron datos de Immunexis en pacientes naive de DMARD con respuesta ACR50 rapida.'),
                mi('Terapia combinada Immunexis', 'Se discutieron resultados de la combinacion Immunexis mas metotrexato a dosis baja. El medico reporta mejoria de puntuaciones DAS28 en tres pacientes recientemente cambiados.'),
                mi('Programa de apoyo Immunexis', 'Se inscribieron dos nuevos pacientes en el programa de apoyo Immunexis. La coordinadora de enfermeria confirmo la verificacion de seguro y configuracion de asistencia de copago.'),
                mi('Protocolo de monitoreo Immunexis', 'Revision de las guias de monitoreo hepatico para terapia con Immunexis. Protocolo de laboratorio alineado con recomendaciones actuales de la SER para pacientes AR bajo biologico.'),
                mi('Asociacion centro de infusion Immunexis', 'Se discutio la ampliacion de horarios del centro de infusion para pacientes Immunexis IV. El director del centro interesado en sistema dedicado de programacion de biologicos.')
            },
            'Immunonco' => new List<Map<String, String>>{
                mi('Respuesta checkpoint Immunonco', 'El oncologo reporto respuesta parcial duradera en paciente con CPNM bajo Immunonco tras 4 ciclos. Expresion PD-L1 >50% basal correlacionada con resultado favorable.'),
                mi('Immunonco en combinacion con quimioterapia', 'Revision de datos fase III para Immunonco mas doblete de platino en primera linea de CPNM. El medico destaca mejoria de SLP sin aumento significativo de EA inmunomediados.'),
                mi('Discusion de biomarcadores Immunonco', 'Se discutio la importancia del panel de biomarcadores antes de iniciar Immunonco. El patologo acepto implementar prueba refleja de PD-L1 y TMB en todas las biopsias de CPNM.'),
                mi('Manejo de irAE Immunonco', 'Revision del algoritmo de manejo de eventos adversos inmunomediados con el equipo de enfermeria oncologica. Enfasis en deteccion temprana de neumonitis y colitis con Immunonco.'),
                mi('Presentacion en comite de tumores', 'Presentacion de datos clinicos de Immunonco en comite multidisciplinario de tumores. El comite acordo incluir Immunonco en la via de tratamiento institucional para CPNM estadio IV.'),
                mi('Eficacia en segunda linea Immunonco', 'Se compartieron datos actualizados de SG para Immunonco en CPNM pretratado. Mejora mediana de SG de 4,2 meses vs docetaxel genero interes significativo entre los medicos asistentes.'),
                mi('Criterios de seleccion Immunonco', 'Se discutio la seleccion optima de pacientes para Immunonco en monoterapia. El oncologo enfatiza la necesidad de estado funcional ECOG 0-1 y ausencia de comorbilidades autoinmunes.'),
                mi('Supervivencia real Immunonco', 'Revision de datos institucionales mostrando tasa de SG a 18 meses del 42% con Immunonco en CPNM. Resultados consistentes con datos de ensayos pivotales en oncologia comunitaria.'),
                mi('Secuenciacion tras progresion Immunonco', 'Se discutieron opciones de secuenciacion tras progresion con Immunonco. El oncologo considera rechallenge con Immunonco mas agente dirigido basado en perfilacion molecular.'),
                mi('Acceso y reembolso Immunonco', 'Coordinacion con equipo de farmacia sobre el proceso de autorizacion previa de Immunonco. La via simplificada redujo el retraso en inicio de tratamiento de 14 a 5 dias.')
            }
        };
    }

    private static Map<String, List<Map<String, String>>> japanese() {
        return new Map<String, List<Map<String, String>>>{
            'Immunexis' => new List<Map<String, String>>{
                mi('メトトレキサート不応のRA患者', '患者は12週間のメトトレキサート投与後に効果不十分と報告。IL-6阻害プロファイルが良好なImmunexisを次の生物学的製剤として検討。リウマチ専門医は有効性データに関心を示した。'),
                mi('Immunexis投与の柔軟性', '皮下注射とIV投与のオプションを確認。医師は外来診療にSC製剤を選好。看護スタッフ向けオートインジェクター研修プログラムについて議論した。'),
                mi('Immunexisリアルワールドエビデンス', 'RA患者におけるImmunexisの24か月リアルワールドデータで持続的寛解を確認。医師は臨床試験結果と一致する安全性プロファイルを評価した。'),
                mi('Immunexis採用申請', '薬事委員会がImmunexisの優先採用を検討中。比較対象の生物学的製剤と比較した入院率低下を強調する薬剤経済学的資料を提供した。'),
                mi('Immunexisバイオシミラー差別化', '新興バイオシミラーに対するImmunexisの作用機序の優位性を議論。医師は8年間の市販後調査にわたる確立された安全性データベースを評価した。'),
                mi('早期RA介入とImmunexis', 'リウマチ専門医は攻撃的RAに対する早期生物学的介入に関心。DMARD未治療患者における迅速なACR50達成を示すImmunexisデータを確認した。'),
                mi('Immunexis併用療法の転帰', 'Immunexisと低用量メトトレキサートの併用療法について検討。医師は最近切り替えた3名の患者でDAS28スコアの改善を報告した。'),
                mi('Immunexis患者サポートプログラム', '2名の新規患者をImmunexis患者サポートプログラムに登録。看護コーディネーターが保険確認と自己負担支援の設定完了を確認した。'),
                mi('Immunexis安全性モニタリング', 'Immunexis療法の肝機能モニタリングガイドラインを確認。検査プロトコルはJCR推奨の生物学的製剤治療RA患者向け基準に準拠している。'),
                mi('Immunexis点滴センター提携', 'Immunexis IV患者向けの点滴センター運用時間拡大を議論。センター長は生物学的製剤専用の点滴スケジューリングシステムに関心を示した。')
            },
            'Immunonco' => new List<Map<String, String>>{
                mi('Immunoncoチェックポイント阻害薬の奏効', '腫瘍内科医はNSCLC患者で4サイクル後にImmunoncの持続的部分奏効を報告。ベースラインPD-L1発現>50%が良好な転帰と相関した。'),
                mi('Immunonco化学療法併用', 'NSCLC一次治療におけるImmunonco＋プラチナダブレットのフェーズIIIデータを確認。医師はirAEの有意な増加なくPFSの改善を指摘した。'),
                mi('Immunoncoバイオマーカー検査', 'Immunonco開始前の包括的バイオマーカーパネルの重要性を議論。病理医はすべてのNSCLC生検でPD-L1とTMBのリフレックス検査導入に同意した。'),
                mi('Immunonco免疫関連有害事象管理', '腫瘍科看護チームと免疫関連有害事象管理アルゴリズムを確認。Immunonco療法における肺臓炎と大腸炎の早期発見を強調した。'),
                mi('Immunoncoキャンサーボード発表', '集学的キャンサーボードでImmunoncの臨床データを発表。委員会はステージIV NSCLCの施設内治療パスにImmunoncの組み込みを承認した。'),
                mi('Immunonco二次治療の有効性', '既治療NSCLC患者におけるImmunoncの最新OS datを共有。ドセタキセル比で中央値4.2か月のOS改善が参加医師の大きな関心を集めた。'),
                mi('Immunonco患者選択基準', 'Immunonco単剤療法の最適な患者選択を議論。腫瘍内科医はECOG PS 0-1と自己免疫疾患の合併がないことの必要性を強調した。'),
                mi('Immunoncoリアルワールド生存率', 'NSCLCにおけるImmunoncの18か月OS率42%を示す施設データを確認。市中腫瘍学での結果はピボタル試験データと一致した。'),
                mi('Immunonco進行後の治療シーケンス', 'Immunonco進行後の治療選択について議論。腫瘍内科医は分子プロファイリングに基づくImmunoncと分子標的薬の再チャレンジを検討している。'),
                mi('Immunoncoアクセスと償還', 'Immunoncの事前承認プロセスについて薬剤部と調整。合理化された承認経路により治療開始までの遅延が14日から5日に短縮された。')
            }
        };
    }

    private static Map<String, List<Map<String, String>>> korean() {
        return new Map<String, List<Map<String, String>>>{
            'Immunexis' => new List<Map<String, String>>{
                mi('메토트렉세이트 불응 RA 환자', '환자가 12주 메토트렉세이트 투여 후 불충분한 반응을 보고. IL-6 억제 프로파일이 우수한 Immunexis를 차기 생물학적 제제로 논의. 류마티스 전문의가 유효성 데이터에 관심을 표명.'),
                mi('Immunexis 투여 유연성 논의', '피하주사 대 IV 투여 옵션을 검토. 의사는 외래 환경에서 SC 제형을 선호. 간호 인력 대상 자동주사기 교육 프로그램에 대해 논의.'),
                mi('Immunexis 실제 임상 근거 검토', 'RA 환자에서 Immunexis의 24개월 실제 임상 데이터로 지속적 관해를 확인. 의사는 임상시험 결과와 일치하는 안전성 프로파일을 주목.'),
                mi('Immunexis 약물목록 등재 요청', '약사위원회에서 Immunexis 우선 등재를 검토 중. 비교 생물학적 제제 대비 입원율 감소를 강조한 약물경제학 자료를 제공.'),
                mi('Immunexis 바이오시밀러 차별화', '신규 바이오시밀러 대비 Immunexis 작용기전의 장점을 논의. 의사는 8년간의 시판 후 조사를 통해 구축된 안전성 데이터베이스를 평가.'),
                mi('Immunexis 조기 RA 개입', '류마티스 전문의가 공격적 RA 표현형에 대한 조기 생물학적 개입에 관심. DMARD 미치료 환자에서 빠른 ACR50 반응을 보여주는 Immunexis 데이터를 검토.'),
                mi('Immunexis 병용요법 결과', 'Immunexis와 저용량 메토트렉세이트 병용 결과를 논의. 의사는 최근 전환된 3명의 환자에서 DAS28 점수 개선을 보고.'),
                mi('Immunexis 환자 지원 프로그램', '2명의 신규 환자를 Immunexis 환자 지원 프로그램에 등록. 간호 코디네이터가 보험 확인 및 본인부담금 지원 설정 완료를 확인.'),
                mi('Immunexis 안전성 모니터링 프로토콜', 'Immunexis 치료의 간 기능 모니터링 가이드라인을 검토. 검사 프로토콜은 대한류마티스학회 권고에 부합하는 생물학적 제제 치료 환자 기준에 따름.'),
                mi('Immunexis 주사실 파트너십', 'Immunexis IV 환자를 위한 주사실 운영 시간 확대를 논의. 센터장이 생물학적 제제 전용 주사 스케줄링 시스템에 관심을 표명.')
            },
            'Immunonco' => new List<Map<String, String>>{
                mi('Immunonco 면역관문억제제 반응', '종양내과 전문의가 4주기 후 NSCLC 환자에서 Immunonco의 지속적 부분 반응을 보고. 기저 PD-L1 발현 >50%가 양호한 결과와 상관.'),
                mi('Immunonco 항암화학요법 병용', '1차 NSCLC에서 Immunonco + 백금 이중항 병용의 3상 데이터를 검토. 의사는 면역 관련 이상반응의 유의한 증가 없이 PFS 개선을 확인.'),
                mi('Immunonco 바이오마커 검사 논의', 'Immunonco 시작 전 포괄적 바이오마커 패널의 중요성을 논의. 병리의사가 모든 NSCLC 생검에서 PD-L1 및 TMB 반사 검사 도입에 동의.'),
                mi('Immunonco 면역 관련 이상반응 관리', '종양 간호팀과 면역 관련 이상반응 관리 알고리즘을 검토. Immunonco 치료에서 폐렴과 대장염의 조기 발견을 강조.'),
                mi('Immunonco 다학제 컨퍼런스 발표', '다학제 종양 컨퍼런스에서 Immunonco 임상 데이터를 발표. 위원회는 4기 NSCLC 기관 내 치료 경로에 Immunonco 포함을 합의.'),
                mi('Immunonco 2차 치료 유효성', '기치료 NSCLC에서 Immunonco의 최신 OS 데이터를 공유. 도세탁셀 대비 중앙값 4.2개월 OS 개선이 참석 의사들의 상당한 관심을 유발.'),
                mi('Immunonco 환자 선택 기준', 'Immunonco 단독요법의 최적 환자 선택을 논의. 종양내과 전문의는 ECOG 활동도 0-1 및 자가면역 동반질환 부재의 필요성을 강조.'),
                mi('Immunonco 실제 임상 생존 결과', 'NSCLC에서 Immunonco의 18개월 OS율 42%를 보여주는 기관 데이터를 검토. 결과는 지역사회 종양학에서의 임상시험 데이터와 일치.'),
                mi('Immunonco 진행 후 치료 순서', 'Immunonco 진행 후 치료 순서 옵션을 논의. 종양내과 전문의가 분자 프로파일링에 기반한 Immunonco와 표적치료제의 재시도를 고려 중.'),
                mi('Immunonco 접근성 및 급여', 'Immunonco 사전승인 절차에 대해 약제팀과 조율. 간소화된 승인 경로로 치료 시작 지연이 14일에서 5일로 단축.')
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
