public without sharing class DemoInquiryController {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';
    private static final String DEFAULT_RT_NAME = 'Medical Inquiry';
    private static final String CASE_RT_FALLBACK = 'Medical Inquiry';

    // Tiny placeholder PNG body used for the DigitalSignature on each demo Inquiry.
    private static final String SIGNATURE_PNG_BASE64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkAAIAAAoAAv/lxKUAAAAASUVORK5CYII=';

    private static final String[] DISCLAIMERS = new String[]{
        'I understand the importance of patient privacy and confirm I did not discuss any personal health information.',
        'No protected health information (PHI) was shared during this interaction.',
        'Inquiry captured per company SOP — no patient identifiers recorded.'
    };

    private static final String[] IMMUNEXIS_QUESTIONS = new String[]{
        'Can you share the latest head-to-head efficacy data for Immunexis vs adalimumab in moderate-to-severe RA?',
        'What is the recommended dosing strategy for Immunexis in patients who have failed two prior biologics?',
        'Are there published real-world outcomes for Immunexis in elderly patients with comorbidities?',
        'Could you send the prescribing information and current safety profile for Immunexis including infection risk?',
        'What patient support programs are available for Immunexis in this region?',
        'Is Immunexis being studied in psoriatic arthritis or other indications beyond RA?',
        'Please provide the latest formulary status and prior authorization criteria for Immunexis in major payers.',
        'What does the latest BSRBR-RA / RABBIT registry data show for Immunexis persistence?'
    };

    private static final String[] IMMUNEXIS_RESPONSES = new String[]{
        'In the SHIELD-RA Phase 3 head-to-head trial (n=820), Immunexis achieved ACR50 of 58% at week 24 vs adalimumab 41% (p<0.001). DAS28-CRP remission was 32% vs 22%. Full data and PI are attached.',
        'For patients with prior biologic failure, the standard 200 mg IV at weeks 0/2/4 then every 8 weeks dosing is recommended. No dose adjustment is required after biologic switch. See PI section 2.3.',
        'Yes — REAL-RA registry analysis (n=2,140 patients ≥65 years) showed comparable efficacy and a stable safety profile vs the overall trial population. Serious infection rate was 2.1 per 100 patient-years.',
        'Prescribing information and the latest periodic safety update are attached. Most common AEs: URI, injection-site reactions, headache. Serious infections 1.8/100 PY in clinical trials; TB screening recommended before start.',
        'Patient support is available through ImmunexisCare: copay assistance up to $15K/year for commercial insurance, free-trial program, nurse educator support, and adherence coaching. Enrollment form attached.',
        'Yes — Phase 3 in PsA (RADIANT-PsA) is fully enrolled with primary readout expected Q4 2026. Phase 2 in axial SpA is ongoing. We can provide protocol synopses on request.',
        'Zelanumab is currently on Tier 2 preferred at the major national payers in the US (Aetna, Cigna, UHC). PA criteria typically require prior csDMARD failure plus one TNFi failure. Detailed payer matrix attached.',
        'Latest BSRBR-RA data (April 2026 release) shows 24-month drug survival of 71% on Immunexis vs 58% on adalimumab. RABBIT (German registry) shows similar persistence advantage. Citations in attached summary.'
    };

    private static final String[] IMMUNONCO_QUESTIONS = new String[]{
        'Can you provide the latest overall survival data for Immunonco in second-line NSCLC after progression on PD-1 inhibitors?',
        'What biomarker testing is recommended before initiating Immunonco in advanced melanoma?',
        'Please share the latest combination data for Immunonco + chemotherapy in metastatic colorectal cancer.',
        'How should I manage immune-related adverse events on Immunonco in a patient with a history of autoimmune disease?',
        'Is Immunonco being investigated in earlier lines of therapy or adjuvant settings?',
        'What is the current evidence for Immunonco in patients with brain metastases?',
        'Could you provide reimbursement and access details for Immunonco through specialty pharmacy?',
        'What dosing modifications are recommended for Immunonco in patients with hepatic impairment?'
    };

    private static final String[] IMMUNONCO_RESPONSES = new String[]{
        'In the VANTAGE-NSCLC Phase 3 study, post-PD-1 second-line Immunonco showed median OS of 14.2 months vs 9.8 months for docetaxel (HR 0.68, p<0.001). 24-month OS rate 31% vs 18%. Full publication and KM curves attached.',
        'Recommended pre-treatment testing: BRAF V600 mutation status, PD-L1 IHC (TPS), and LDH at baseline. Tumor mutational burden testing is supportive but not required. NCCN aligned. Testing guide attached.',
        'VORA-COLON Phase 2 (n=180) reported ORR 38% with Immunonco + FOLFIRI vs 22% FOLFIRI alone in MSS metastatic CRC. Median PFS 9.1 vs 5.4 months. Phase 3 enrollment begins Q3 2026.',
        'In patients with controlled autoimmune disease, Immunonco can be considered with close monitoring. Hold therapy for grade ≥2 irAEs; corticosteroids per ASCO/ESMO guidelines. Multidisciplinary review recommended.',
        'Yes — VANTAGE-Adjuvant is enrolling stage III melanoma patients (1500 target). VANTAGE-Earlier is studying first-line NSCLC + chemo. Both expected to read out 2027-2028.',
        'CNS-VORA (n=92) showed intracranial response rate 42% in patients with active brain metastases. Median CNS PFS 7.8 months. PI now includes CNS efficacy data.',
        'Vorastinib is dispensed through specialty pharmacy. Average days to fulfillment: 5 business days. Copay assistance available up to $25K/year for commercial; foundation grants for Medicare patients via patient hub.',
        'For mild-moderate hepatic impairment (Child-Pugh A/B) reduce starting dose by 25%. Severe impairment: not recommended due to limited PK data. LFT monitoring at weeks 2, 4, 6, then monthly.'
    };

    private static final String[] PRIORITIES = new String[]{ 'Low', 'Medium', 'High' };

    /** Resolves the active InquiryChannelType picklist values at runtime so we never write an invalid value. */
    private static List<String> getInquiryChannels() {
        List<String> values = new List<String>();
        Schema.DescribeFieldResult dfr = Inquiry.InquiryChannelType.getDescribe();
        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
            if (pe.isActive()) values.add(pe.getValue());
        }
        return values;
    }

    @AuraEnabled(cacheable=true)
    public static String getStatus() {
        try {
            if (!objectExists('Inquiry')) return 'Inquiry not available in this org.';
            String tag = DEMO_TAG;
            Integer inq = Database.countQuery('SELECT COUNT() FROM Inquiry WHERE SourceSystemName = :tag');
            Integer iq = Database.countQuery('SELECT COUNT() FROM InquiryQuestion WHERE SourceSystemName = :tag');
            String s = 'Inquiries: ' + inq + ', Questions: ' + iq;
            if (objectExists('InquiryQuestionAnswer')) {
                Integer iqa = Database.countQuery('SELECT COUNT() FROM InquiryQuestionAnswer WHERE SourceSystemName = :tag');
                s += ', Answers: ' + iqa;
            }
            if (objectExists('DigitalSignature')) {
                Set<Id> demoInquiryIds = new Set<Id>();
                for (Inquiry i : [SELECT Id FROM Inquiry WHERE SourceSystemName = :tag LIMIT 10000]) demoInquiryIds.add(i.Id);
                if (!demoInquiryIds.isEmpty()) {
                    Integer sigs = Database.countQuery(
                        'SELECT COUNT() FROM DigitalSignature WHERE ParentId IN :demoInquiryIds'
                    );
                    s += ', Signatures: ' + sigs;
                }
            }
            return s;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getInquiryRecordTypes() {
        try {
            List<Map<String, String>> result = new List<Map<String, String>>();
            for (RecordType rt : [
                SELECT Id, Name, DeveloperName FROM RecordType
                WHERE SObjectType = 'Inquiry' AND IsActive = true ORDER BY Name
            ]) {
                result.add(new Map<String, String>{ 'label' => rt.Name, 'value' => rt.Name });
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error loading record types: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTerritories() {
        try {
            List<Territory2> allTerrs = [
                SELECT Id, Name, ParentTerritory2Id FROM Territory2
                WHERE Territory2Model.State = 'Active'
            ];
            Set<Id> parentIds = new Set<Id>();
            for (Territory2 t : allTerrs) {
                if (t.ParentTerritory2Id != null) parentIds.add(t.ParentTerritory2Id);
            }
            Set<Id> leafIds = new Set<Id>();
            Map<Id, String> leafNames = new Map<Id, String>();
            for (Territory2 t : allTerrs) {
                if (!parentIds.contains(t.Id)) {
                    leafIds.add(t.Id);
                    leafNames.put(t.Id, t.Name);
                }
            }

            String demoTag = DEMO_TAG;
            Set<Id> demoHcpIds = new Set<Id>();
            for (Account a : [SELECT Id FROM Account
                    WHERE Site = :demoTag AND IsPersonAccount = true]) {
                demoHcpIds.add(a.Id);
            }

            Set<Id> terrsWithHcps = new Set<Id>();
            for (ObjectTerritory2Association ota : [
                SELECT Territory2Id FROM ObjectTerritory2Association
                WHERE Territory2Id IN :leafIds AND ObjectId IN :demoHcpIds
            ]) {
                terrsWithHcps.add(ota.Territory2Id);
            }

            List<String> sortedNames = new List<String>(leafNames.values());
            sortedNames.sort();
            Map<String, Id> nameToId = new Map<String, Id>();
            for (Id tId : leafNames.keySet()) nameToId.put(leafNames.get(tId), tId);

            List<Map<String, String>> result = new List<Map<String, String>>();
            for (String tName : sortedNames) {
                Id tId = nameToId.get(tName);
                if (!terrsWithHcps.contains(tId)) continue;
                result.add(new Map<String, String>{ 'label' => tName, 'value' => tId });
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error loading territories: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String createInquiriesForTerritory(Id territoryId, String recordTypeName, String responsePreference) {
        List<String> details = new List<String>();
        List<String> errors = new List<String>();

        try {
            if (!objectExists('Inquiry') || !objectExists('InquiryQuestion')) {
                throw new AuraHandledException('Inquiry / InquiryQuestion not available in this org.');
            }

            Territory2 terr = [SELECT Id, Name FROM Territory2 WHERE Id = :territoryId LIMIT 1];
            String effectiveRtName = String.isBlank(recordTypeName) ? DEFAULT_RT_NAME : recordTypeName;
            details.add('HEADER:' + terr.Name + ' — Inquiry RT: ' + effectiveRtName);

            Id ownerId;
            List<UserTerritory2Association> utas = [
                SELECT UserId FROM UserTerritory2Association
                WHERE Territory2Id = :territoryId ORDER BY Territory2Id LIMIT 1
            ];
            ownerId = utas.isEmpty() ? UserInfo.getUserId() : utas[0].UserId;

            // Resolve record types by Name (portable across orgs that prefix DeveloperName like "LSDO_").
            // Try to match the Case RT to the chosen Inquiry RT name; fall back to "Medical Inquiry".
            Id inquiryRtId = lookupRecordTypeId('Inquiry', effectiveRtName);
            Id caseRtId = lookupRecordTypeId('Case', effectiveRtName);
            if (caseRtId == null) caseRtId = lookupRecordTypeId('Case', CASE_RT_FALLBACK);
            if (caseRtId == null) {
                throw new AuraHandledException('No matching Case record type ("' + effectiveRtName + '" or "' + CASE_RT_FALLBACK + '") in this org.');
            }

            String demoTag = DEMO_TAG;
            Set<Id> hcpIds = new Set<Id>();
            for (Account a : [SELECT Id FROM Account
                    WHERE Site = :demoTag AND IsPersonAccount = true]) {
                hcpIds.add(a.Id);
            }

            Set<Id> leafSet = new Set<Id>{ territoryId };
            List<Id> terrHcps = new List<Id>();
            for (ObjectTerritory2Association ota : [
                SELECT ObjectId FROM ObjectTerritory2Association
                WHERE Territory2Id IN :leafSet AND ObjectId IN :hcpIds
            ]) {
                terrHcps.add(ota.ObjectId);
            }

            if (terrHcps.isEmpty()) {
                return JSON.serialize(new Map<String, Object>{
                    'summary' => terr.Name + ': no HCPs', 'details' => details, 'errors' => errors,
                    'caseCount' => 0, 'inquiryCount' => 0, 'questionCount' => 0
                });
            }

            Map<Id, String> hcpToCountry = new Map<Id, String>();
            Map<Id, String> hcpToName = new Map<Id, String>();
            for (Account a : [SELECT Id, Name, BillingCountryCode FROM Account WHERE Id IN :terrHcps]) {
                hcpToCountry.put(a.Id, a.BillingCountryCode);
                hcpToName.put(a.Id, a.Name);
            }

            // Resolve preferred response contact point per HCP based on user's chosen type.
            Map<Id, Id> hcpToCpId = lookupContactPoints(new Set<Id>(terrHcps), responsePreference);
            details.add('SUCCESS:Found ' + terrHcps.size() + ' HCPs (response pref: ' +
                (String.isBlank(responsePreference) ? 'none' : responsePreference) +
                ', ' + hcpToCpId.size() + ' matched)');

            // Step 1 — Cases
            Schema.SObjectType caseType = Schema.getGlobalDescribe().get('Case');
            List<SObject> casesToInsert = new List<SObject>();
            List<Id> caseHcpIds = new List<Id>();
            Integer seed = terr.Name.hashCode();
            Integer seq = 0;
            List<String> channels = getInquiryChannels();
            if (channels.isEmpty()) channels = new List<String>{ 'Email' };

            for (Id hcpId : terrHcps) {
                // 1-2 inquiries per HCP
                Integer numInquiries = 1 + pseudoRandom(seed + seq, 2);
                for (Integer i = 0; i < numInquiries; i++) {
                    seq++;
                    SObject c = caseType.newSObject();
                    c.put('RecordTypeId', caseRtId);
                    c.put('AccountId', hcpId);
                    c.put('OwnerId', ownerId);
                    c.put('Priority', PRIORITIES[pseudoRandom(seed + seq, PRIORITIES.size())]);
                    // LSC workflow rejects direct insert at later stages — start as Draft, optionally promote later.
                    c.put('Status', 'Draft');
                    c.put('Origin', 'Phone');
                    casesToInsert.add(c);
                    caseHcpIds.add(hcpId);
                }
            }

            Database.SaveResult[] caseResults = Database.insert(casesToInsert, false);
            Integer caseSuccess = 0;
            for (Database.SaveResult sr : caseResults) {
                if (sr.isSuccess()) caseSuccess++;
                else if (errors.size() < 10) errors.add('Case: ' + sr.getErrors()[0].getMessage());
            }
            details.add('SUCCESS:Created ' + caseSuccess + ' cases');

            // Step 2 — Inquiries
            Schema.SObjectType inqType = Schema.getGlobalDescribe().get('Inquiry');
            Map<String, Schema.SObjectField> inqFields = inqType.getDescribe().fields.getMap();
            List<SObject> inquiriesToInsert = new List<SObject>();
            List<Id> inquiryHcpIds = new List<Id>();
            List<Id> inquiryCaseIds = new List<Id>();

            for (Integer i = 0; i < caseResults.size(); i++) {
                if (!caseResults[i].isSuccess()) continue;
                seq++;
                Id hcpId = caseHcpIds[i];
                Id caseId = caseResults[i].getId();

                SObject inq = inqType.newSObject();
                inq.put('CaseId', caseId);
                // Inquiry.AccountId and Inquiry.Status are read-only: AccountId is inherited from
                // the parent Case, Status is managed by the LSC state machine (defaults to Draft).
                inq.put('Type', 'Medical Inquiry');
                inq.put('Priority', PRIORITIES[pseudoRandom(seed + seq, PRIORITIES.size())]);
                inq.put('InquiryChannelType', channels[pseudoRandom(seed + seq + 1, channels.size())]);
                inq.put('DisclaimerText', DISCLAIMERS[pseudoRandom(seed + seq + 2, DISCLAIMERS.size())]);
                inq.put('Territory2Id', territoryId);
                inq.put('TerritoryName', terr.Name);
                inq.put('SubmittedDateTime', Datetime.now().addDays(-pseudoRandom(seed + seq + 3, 30)));
                inq.put('SourceSystemName', DEMO_TAG);
                inq.put('SourceSystemIdentifier', 'INQ-' + caseId);
                if (inquiryRtId != null && inqFields.containsKey('recordtypeid')) {
                    inq.put('RecordTypeId', inquiryRtId);
                }
                Id cpId = hcpToCpId.get(hcpId);
                if (cpId != null) inq.put('ResponseContactPointRecId', cpId);
                inquiriesToInsert.add(inq);
                inquiryHcpIds.add(hcpId);
                inquiryCaseIds.add(caseId);
            }

            Database.SaveResult[] inqResults = Database.insert(inquiriesToInsert, false);
            Integer inqSuccess = 0;
            for (Database.SaveResult sr : inqResults) {
                if (sr.isSuccess()) inqSuccess++;
                else if (errors.size() < 10) errors.add('Inquiry: ' + sr.getErrors()[0].getMessage());
            }
            details.add('SUCCESS:Created ' + inqSuccess + ' inquiries');

            // Step 2b — DigitalSignature (one per Inquiry).
            // Reuse an existing signature image from the org for realism; fall back to placeholder.
            Integer sigSuccess = 0;
            if (objectExists('DigitalSignature') && inqSuccess > 0) {
                Blob sigBody;
                String sigContentType = 'image/png';
                List<DigitalSignature> templates = [
                    SELECT DocumentBody, DocumentContentType, DocumentLength
                    FROM DigitalSignature
                    WHERE DocumentLength > 1000
                    ORDER BY DocumentLength DESC LIMIT 1
                ];
                if (!templates.isEmpty()) {
                    sigBody = templates[0].DocumentBody;
                    if (String.isNotBlank(templates[0].DocumentContentType)) {
                        sigContentType = templates[0].DocumentContentType;
                    }
                    details.add('SUCCESS:Reusing existing signature image (' + templates[0].DocumentLength + ' bytes, ' + sigContentType + ')');
                } else {
                    sigBody = EncodingUtil.base64Decode(SIGNATURE_PNG_BASE64);
                    details.add('SUCCESS:No existing signature found — using placeholder PNG');
                }

                List<DigitalSignature> sigs = new List<DigitalSignature>();
                for (Integer i = 0; i < inqResults.size(); i++) {
                    if (!inqResults[i].isSuccess()) continue;
                    Id inquiryId = inqResults[i].getId();
                    Id hcpId = inquiryHcpIds[i];
                    String hcpName = hcpToName.get(hcpId);
                    if (hcpName == null) hcpName = 'HCP';
                    SObject inqSObj = inquiriesToInsert[i];
                    Datetime submitted = (Datetime) inqSObj.get('SubmittedDateTime');
                    sigs.add(new DigitalSignature(
                        ParentId = inquiryId,
                        DocumentName = 'Inquiry Signature - ' + hcpName,
                        DocumentContentType = sigContentType,
                        DocumentBody = sigBody,
                        SignedBy = hcpName,
                        SignedDate = submitted != null ? submitted : Datetime.now()
                    ));
                }
                Database.SaveResult[] sigResults = Database.insert(sigs, false);
                for (Database.SaveResult sr : sigResults) {
                    if (sr.isSuccess()) sigSuccess++;
                    else if (errors.size() < 10) errors.add('Signature: ' + sr.getErrors()[0].getMessage());
                }
                details.add('SUCCESS:Created ' + sigSuccess + ' signatures');
            }

            // Step 3 — InquiryQuestions (paired with their canned response so we can create answers)
            Schema.SObjectType iqType = Schema.getGlobalDescribe().get('InquiryQuestion');
            List<SObject> questionsToInsert = new List<SObject>();
            List<String> questionResponses = new List<String>();
            List<Id> questionHcpIds = new List<Id>();
            List<Datetime> questionSubmittedTimes = new List<Datetime>();

            for (Integer i = 0; i < inqResults.size(); i++) {
                if (!inqResults[i].isSuccess()) continue;
                Id inquiryId = inqResults[i].getId();
                Id caseId = inquiryCaseIds[i];
                Id hcpId = inquiryHcpIds[i];
                String country = hcpToCountry.get(hcpId);
                Datetime submittedAt = (Datetime) inquiriesToInsert[i].get('SubmittedDateTime');
                Boolean useOnco = Math.mod(Math.abs(seed + i), 2) == 0;
                String[] qPool = useOnco ? IMMUNONCO_QUESTIONS : IMMUNEXIS_QUESTIONS;
                String[] rPool = useOnco ? IMMUNONCO_RESPONSES : IMMUNEXIS_RESPONSES;

                Integer numQs = 1 + pseudoRandom(seed + i + 7, 2);
                Set<Integer> usedIdx = new Set<Integer>();
                for (Integer q = 0; q < numQs; q++) {
                    Integer idx = pseudoRandom(seed + i + q + 13, qPool.size());
                    while (usedIdx.contains(idx)) idx = Math.mod(idx + 1, qPool.size());
                    usedIdx.add(idx);

                    SObject iq = iqType.newSObject();
                    iq.put('CaseId', caseId);
                    iq.put('InquiryId', inquiryId);
                    iq.put('Question', qPool[idx]);
                    iq.put('ResponseStatus', 'Responded');
                    iq.put('SourceSystemName', DEMO_TAG);
                    iq.put('SourceSystemIdentifier', 'IQ-' + inquiryId + '-' + q);
                    questionsToInsert.add(iq);
                    questionResponses.add(rPool[idx]);
                    questionHcpIds.add(hcpId);
                    questionSubmittedTimes.add(submittedAt);
                }
            }

            Database.SaveResult[] iqResults = Database.insert(questionsToInsert, false);
            Integer iqSuccess = 0;
            for (Database.SaveResult sr : iqResults) {
                if (sr.isSuccess()) iqSuccess++;
                else if (errors.size() < 10) errors.add('Question: ' + sr.getErrors()[0].getMessage());
            }
            details.add('SUCCESS:Created ' + iqSuccess + ' questions');

            // Step 4 — InquiryQuestionAnswer (one per question)
            Integer iqaSuccess = 0;
            if (objectExists('InquiryQuestionAnswer') && iqSuccess > 0) {
                Schema.SObjectType iqaType = Schema.getGlobalDescribe().get('InquiryQuestionAnswer');
                List<SObject> answersToInsert = new List<SObject>();
                for (Integer i = 0; i < iqResults.size(); i++) {
                    if (!iqResults[i].isSuccess()) continue;
                    Id qId = iqResults[i].getId();
                    Id hcpId = questionHcpIds[i];
                    SObject iqa = iqaType.newSObject();
                    iqa.put('InquiryQuestionId', qId);
                    iqa.put('Response', questionResponses[i]);
                    // Validation rule: ResponseDateTime must be AFTER the parent Inquiry's SubmittedDateTime.
                    Datetime submittedAt = questionSubmittedTimes[i];
                    if (submittedAt == null) submittedAt = Datetime.now().addDays(-7);
                    Integer offsetHours = 1 + pseudoRandom(seed + i + 17, 168); // 1h to 7d after
                    iqa.put('ResponseDateTime', submittedAt.addHours(offsetHours));
                    iqa.put('SourceSystemName', DEMO_TAG);
                    iqa.put('SourceSystemIdentifier', 'IQA-' + qId);
                    Id cpId = hcpToCpId.get(hcpId);
                    if (cpId != null) iqa.put('ResponseContactPointRecId', cpId);
                    answersToInsert.add(iqa);
                }
                Database.SaveResult[] iqaResults = Database.insert(answersToInsert, false);
                for (Database.SaveResult sr : iqaResults) {
                    if (sr.isSuccess()) iqaSuccess++;
                    else if (errors.size() < 10) errors.add('Answer: ' + sr.getErrors()[0].getMessage());
                }
                details.add('SUCCESS:Created ' + iqaSuccess + ' answers');
            }

            return JSON.serialize(new Map<String, Object>{
                'summary' => terr.Name + ': ' + inqSuccess + ' inquiries, ' + iqSuccess + ' questions, ' +
                             iqaSuccess + ' answers, ' + sigSuccess + ' signatures',
                'details' => details, 'errors' => errors,
                'caseCount' => caseSuccess, 'inquiryCount' => inqSuccess,
                'questionCount' => iqSuccess, 'answerCount' => iqaSuccess,
                'signatureCount' => sigSuccess
            });
        } catch (Exception e) {
            throw new AuraHandledException(territoryId + ' error: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }

    @AuraEnabled
    public static String deleteInquiriesForTerritory(Id territoryId) {
        try {
            if (!objectExists('Inquiry')) return 'Inquiry not available in this org.';
            String tag = DEMO_TAG;

            List<Inquiry> inquiries = [
                SELECT Id, CaseId FROM Inquiry
                WHERE SourceSystemName = :tag AND Territory2Id = :territoryId LIMIT 10000
            ];
            if (inquiries.isEmpty()) return 'No demo inquiries for this territory.';
            return cascadeDelete(inquiries);
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String deleteAllInquiries() {
        try {
            if (!objectExists('Inquiry')) return 'Inquiry not available in this org.';
            String tag = DEMO_TAG;
            List<Inquiry> inquiries = [
                SELECT Id, CaseId FROM Inquiry WHERE SourceSystemName = :tag LIMIT 10000
            ];
            if (inquiries.isEmpty()) return 'No demo inquiries to delete.';
            return cascadeDelete(inquiries);
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    private static String cascadeDelete(List<Inquiry> inquiries) {
        Set<Id> caseIds = new Set<Id>();
        Set<Id> inquiryIds = new Set<Id>();
        for (Inquiry i : inquiries) {
            inquiryIds.add(i.Id);
            if (i.CaseId != null) caseIds.add(i.CaseId);
        }
        List<String> deleted = new List<String>();

        if (objectExists('InquiryQuestion')) {
            List<InquiryQuestion> qs = [SELECT Id FROM InquiryQuestion WHERE InquiryId IN :inquiryIds LIMIT 10000];
            if (!qs.isEmpty()) {
                Set<Id> qIds = new Set<Id>();
                for (InquiryQuestion q : qs) qIds.add(q.Id);

                if (objectExists('InquiryQuestionAnswer')) {
                    List<SObject> answers = Database.query(
                        'SELECT Id FROM InquiryQuestionAnswer WHERE InquiryQuestionId IN :qIds LIMIT 10000'
                    );
                    if (!answers.isEmpty()) {
                        Database.delete(answers, false);
                        deleted.add(answers.size() + ' answers');
                    }
                }

                Database.delete(qs, false);
                deleted.add(qs.size() + ' questions');
            }
        }

        if (objectExists('DigitalSignature')) {
            List<SObject> sigs = Database.query(
                'SELECT Id FROM DigitalSignature WHERE ParentId IN :inquiryIds LIMIT 10000'
            );
            if (!sigs.isEmpty()) {
                Database.delete(sigs, false);
                deleted.add(sigs.size() + ' signatures');
            }
        }

        Database.delete(inquiries, false);
        deleted.add(inquiries.size() + ' inquiries');

        if (!caseIds.isEmpty()) {
            List<Case> cases = [SELECT Id FROM Case WHERE Id IN :caseIds LIMIT 10000];
            if (!cases.isEmpty()) {
                Database.delete(cases, false);
                deleted.add(cases.size() + ' cases');
            }
        }

        return 'Deleted ' + String.join(deleted, ', ') + '.';
    }

    /**
     * Returns a map of accountId → ContactPoint Id for the chosen contact-point type.
     * Picks the primary contact point first; falls back to the first available record per account.
     */
    private static Map<Id, Id> lookupContactPoints(Set<Id> accountIds, String preference) {
        Map<Id, Id> result = new Map<Id, Id>();
        if (accountIds == null || accountIds.isEmpty() || String.isBlank(preference)) return result;

        String objectName;
        if (preference.equalsIgnoreCase('Address')) objectName = 'ContactPointAddress';
        else if (preference.equalsIgnoreCase('Email')) objectName = 'ContactPointEmail';
        else if (preference.equalsIgnoreCase('Phone')) objectName = 'ContactPointPhone';
        else return result;

        if (!objectExists(objectName)) return result;

        // Primary first, then any
        String soql = 'SELECT Id, ParentId, IsPrimary FROM ' + objectName +
                      ' WHERE ParentId IN :accountIds ORDER BY IsPrimary DESC, CreatedDate ASC LIMIT 50000';
        for (SObject cp : Database.query(soql)) {
            Id parentId = (Id) cp.get('ParentId');
            if (!result.containsKey(parentId)) result.put(parentId, (Id) cp.get('Id'));
        }
        return result;
    }

    private static Id lookupRecordTypeId(String sObjectName, String name) {
        List<RecordType> rts = [
            SELECT Id FROM RecordType
            WHERE SObjectType = :sObjectName AND Name = :name AND IsActive = true
            LIMIT 1
        ];
        return rts.isEmpty() ? null : rts[0].Id;
    }

    private static String[] pickQuestionPool(String country, Integer seed) {
        // Mix or pick by parity — country code is informational but not required
        Boolean useOnco = Math.mod(Math.abs(seed), 2) == 0;
        return useOnco ? IMMUNONCO_QUESTIONS : IMMUNEXIS_QUESTIONS;
    }

    private static Integer pseudoRandom(Integer seed, Integer maxVal) {
        if (maxVal <= 0) return 0;
        Long hash = Math.abs(((Long) seed * 6364136223846793005L + 1442695040888963407L));
        return (Integer) Math.mod(hash, maxVal);
    }

    private static Boolean objectExists(String objectName) {
        return Schema.getGlobalDescribe().containsKey(objectName);
    }
}
