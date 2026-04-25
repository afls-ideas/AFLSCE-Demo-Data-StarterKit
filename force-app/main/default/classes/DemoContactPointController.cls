/**
 * DemoContactPointController
 *
 * Creates ContactPointAddress, ContactPointEmail, ContactPointPhone,
 * ContactPointSocial, and BusinessLicense records in batches to stay
 * within SOQL governor limits imposed by managed-package triggers.
 *
 * Each @AuraEnabled method accepts an offset and processes BATCH_SIZE
 * accounts per call. The LWC calls repeatedly until hasMore = false.
 */
public with sharing class DemoContactPointController {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';
    private static final Integer BATCH_SIZE = 15;

    // ──────────────────────────────────────────────────────────
    // Batch-style create methods — each returns JSON:
    //   { "created": N, "total": N, "hasMore": true/false, "errors": [] }
    // ──────────────────────────────────────────────────────────

    @AuraEnabled
    public static String createAddressBatch(Integer batchOffset) {
        try {
            List<Account> batch = queryAccountBatch(batchOffset);
            if (batch.isEmpty()) return batchResult(0, 0, false, new List<String>());
            Integer total = countDemoAccounts();

            List<ContactPointAddress> records = buildAddresses(batch);
            Database.SaveResult[] sr = Database.insert(records, false);
            List<String> errors = new List<String>();
            collectErrors(sr, records, errors);
            Integer created = countSuccesses(sr);

            // Link new CPAs to existing ProviderAcctTerritoryInfo records as PreferredAddressId
            linkCpaToPati(records, sr);

            Boolean hasMore = (batchOffset + BATCH_SIZE) < total;
            return batchResult(created, records.size(), hasMore, errors);
        } catch (Exception e) {
            throw new AuraHandledException('Error creating addresses: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String createEmailBatch(Integer batchOffset) {
        try {
            List<Account> batch = queryAccountBatch(batchOffset);
            List<SObject> hcpBatch = queryHcpBatch(batchOffset);
            if (batch.isEmpty() && hcpBatch.isEmpty()) return batchResult(0, 0, false, new List<String>());

            Integer totalAccts = countDemoAccounts();
            Integer totalHcps = countDemoHcps();
            Integer totalRecords = totalAccts + totalHcps;

            List<ContactPointEmail> records = buildEmails(batch, hcpBatch);
            Database.SaveResult[] sr = Database.insert(records, false);
            List<String> errors = new List<String>();
            collectErrors(sr, records, errors);
            Integer created = countSuccesses(sr);

            Boolean hasMore = (batchOffset + BATCH_SIZE) < Math.max(totalAccts, totalHcps);
            return batchResult(created, records.size(), hasMore, errors);
        } catch (Exception e) {
            throw new AuraHandledException('Error creating emails: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String createPhoneBatch(Integer batchOffset) {
        try {
            List<Account> batch = queryAccountBatch(batchOffset);
            List<SObject> hcpBatch = queryHcpBatch(batchOffset);
            if (batch.isEmpty() && hcpBatch.isEmpty()) return batchResult(0, 0, false, new List<String>());

            Integer totalAccts = countDemoAccounts();
            Integer totalHcps = countDemoHcps();

            List<ContactPointPhone> records = buildPhones(batch, hcpBatch);
            Database.SaveResult[] sr = Database.insert(records, false);
            List<String> errors = new List<String>();
            collectErrors(sr, records, errors);
            Integer created = countSuccesses(sr);

            Boolean hasMore = (batchOffset + BATCH_SIZE) < Math.max(totalAccts, totalHcps);
            return batchResult(created, records.size(), hasMore, errors);
        } catch (Exception e) {
            throw new AuraHandledException('Error creating phones: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String createSocialBatch(Integer batchOffset) {
        try {
            Schema.SObjectType socialType = Schema.getGlobalDescribe().get('contactpointsocial');
            if (socialType == null) return batchResult(0, 0, false, new List<String>{ 'ContactPointSocial not available' });

            List<Account> batch = queryOrgAccountBatch(batchOffset);
            if (batch.isEmpty()) return batchResult(0, 0, false, new List<String>());
            Integer total = countOrgAccounts();

            List<SObject> records = buildSocials(batch);
            if (records.isEmpty()) {
                Boolean hasMore = (batchOffset + BATCH_SIZE) < total;
                return batchResult(0, 0, hasMore, new List<String>());
            }
            Database.SaveResult[] sr = Database.insert(records, false);
            List<String> errors = new List<String>();
            collectErrors(sr, records, errors);
            Integer created = countSuccesses(sr);

            Boolean hasMore = (batchOffset + BATCH_SIZE) < total;
            return batchResult(created, records.size(), hasMore, errors);
        } catch (Exception e) {
            throw new AuraHandledException('Error creating socials: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String createLicenseBatch(Integer batchOffset) {
        try {
            Schema.SObjectType blType = Schema.getGlobalDescribe().get('businesslicense');
            if (blType == null) return batchResult(0, 0, false, new List<String>{ 'BusinessLicense not available' });

            List<Account> batch = queryAccountBatch(batchOffset);
            if (batch.isEmpty()) return batchResult(0, 0, false, new List<String>());
            Integer total = countDemoAccounts();

            List<SObject> records = buildBusinessLicenses(batch);
            if (records.isEmpty()) {
                Boolean hasMore = (batchOffset + BATCH_SIZE) < total;
                return batchResult(0, 0, hasMore, new List<String>());
            }
            Database.SaveResult[] sr = Database.insert(records, false);
            List<String> errors = new List<String>();
            collectErrors(sr, records, errors);
            Integer created = countSuccesses(sr);

            Boolean hasMore = (batchOffset + BATCH_SIZE) < total;
            return batchResult(created, records.size(), hasMore, errors);
        } catch (Exception e) {
            throw new AuraHandledException('Error creating licenses: ' + e.getMessage());
        }
    }

    // ──────────────────────────────────────────────────────────
    // Status + Delete
    // ──────────────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static String getStatus() {
        try {
            List<String> counts = new List<String>();

            Set<Id> accountIds = new Set<Id>();
            for (Account a : [SELECT Id FROM Account WHERE Site = :DEMO_TAG]) {
                accountIds.add(a.Id);
            }

            if (!accountIds.isEmpty()) {
                counts.add('Addresses: ' + [SELECT COUNT() FROM ContactPointAddress WHERE ParentId IN :accountIds]);
                counts.add('Emails: ' + [SELECT COUNT() FROM ContactPointEmail WHERE ParentId IN :accountIds]);
                counts.add('Phones: ' + [SELECT COUNT() FROM ContactPointPhone WHERE ParentId IN :accountIds]);
            }

            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            if (gd.containsKey('businesslicense')) {
                Integer cnt = Database.countQuery(
                    'SELECT COUNT() FROM BusinessLicense WHERE Identifier LIKE \'' + String.escapeSingleQuotes(DEMO_TAG) + '%\''
                );
                counts.add('Licenses: ' + cnt);
            }

            return counts.isEmpty() ? 'No contact points found.' : String.join(counts, ', ');
        } catch (Exception e) {
            throw new AuraHandledException('Error getting status: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String deleteContactPointBatch(String objectType) {
        try {
            Set<Id> accountIds = new Set<Id>();
            for (Account a : [SELECT Id FROM Account WHERE Site = :DEMO_TAG]) {
                accountIds.add(a.Id);
            }

            Integer deleted = 0;
            String escapedTag = String.escapeSingleQuotes(DEMO_TAG);

            if (objectType == 'ContactPointAddress' && !accountIds.isEmpty()) {
                List<ContactPointAddress> recs = [SELECT Id FROM ContactPointAddress WHERE ParentId IN :accountIds];
                if (!recs.isEmpty()) { deleted += countDeleteSuccesses(Database.delete(recs, false)); }
            } else if (objectType == 'ContactPointEmail' && !accountIds.isEmpty()) {
                List<ContactPointEmail> recs = [SELECT Id FROM ContactPointEmail WHERE ParentId IN :accountIds];
                if (!recs.isEmpty()) { deleted += countDeleteSuccesses(Database.delete(recs, false)); }
            } else if (objectType == 'ContactPointPhone' && !accountIds.isEmpty()) {
                List<ContactPointPhone> recs = [SELECT Id FROM ContactPointPhone WHERE ParentId IN :accountIds];
                if (!recs.isEmpty()) { deleted += countDeleteSuccesses(Database.delete(recs, false)); }
            } else if (objectType == 'ContactPointSocial') {
                List<SObject> recs = Database.query('SELECT Id FROM ContactPointSocial WHERE SourceSystemName = \'' + escapedTag + '\'');
                if (!recs.isEmpty()) { deleted += countDeleteSuccesses(Database.delete(recs, false)); }
            } else if (objectType == 'BusinessLicense') {
                List<SObject> recs = Database.query('SELECT Id FROM BusinessLicense WHERE Identifier LIKE \'' + escapedTag + '%\'');
                if (!recs.isEmpty()) { deleted += countDeleteSuccesses(Database.delete(recs, false)); }
            }

            return String.valueOf(deleted);
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting ' + objectType + ': ' + e.getMessage());
        }
    }

    // ──────────────────────────────────────────────────────────
    // Query helpers with LIMIT/OFFSET for batching
    // ──────────────────────────────────────────────────────────

    private static List<Account> queryAccountBatch(Integer offset) {
        return [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingStateCode,
                   BillingPostalCode, BillingCountry, BillingCountryCode,
                   Type, Phone, Site, IsPersonAccount, PersonContactId
            FROM Account
            WHERE Site = :DEMO_TAG
            ORDER BY Name
            LIMIT :BATCH_SIZE OFFSET :offset
        ];
    }

    private static List<Account> queryOrgAccountBatch(Integer offset) {
        return [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState,
                   BillingPostalCode, BillingCountry, Type, Phone, Site
            FROM Account
            WHERE Site = :DEMO_TAG AND IsPersonAccount = false
            ORDER BY Name
            LIMIT :BATCH_SIZE OFFSET :offset
        ];
    }

    private static List<SObject> queryHcpBatch(Integer offset) {
        String escapedTag = String.escapeSingleQuotes(DEMO_TAG);
        return Database.query(
            'SELECT Id, Name, SourceSystem, AccountId FROM HealthcareProvider WHERE SourceSystem = \'' + escapedTag + '\' ORDER BY Name LIMIT ' + BATCH_SIZE + ' OFFSET ' + offset
        );
    }

    private static Integer countDemoAccounts() {
        return [SELECT COUNT() FROM Account WHERE Site = :DEMO_TAG];
    }

    private static Integer countOrgAccounts() {
        return [SELECT COUNT() FROM Account WHERE Site = :DEMO_TAG AND IsPersonAccount = false];
    }

    private static Integer countDemoHcps() {
        String escapedTag = String.escapeSingleQuotes(DEMO_TAG);
        return Database.countQuery('SELECT COUNT() FROM HealthcareProvider WHERE SourceSystem = \'' + escapedTag + '\'');
    }

    // ──────────────────────────────────────────────────────────
    // Link CPAs to ProviderAcctTerritoryInfo as PreferredAddressId
    // ──────────────────────────────────────────────────────────

    private static void linkCpaToPati(List<ContactPointAddress> cpas, Database.SaveResult[] results) {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey('provideracctterritoryinfo')) return;

        Map<Id, Id> acctToCpaId = new Map<Id, Id>();
        for (Integer i = 0; i < cpas.size(); i++) {
            if (results[i].isSuccess()) {
                Id parentId = cpas[i].ParentId;
                if (!acctToCpaId.containsKey(parentId)) {
                    acctToCpaId.put(parentId, results[i].getId());
                }
            }
        }
        if (acctToCpaId.isEmpty()) return;

        String escapedTag = String.escapeSingleQuotes(DEMO_TAG);
        List<SObject> patiRecords = Database.query(
            'SELECT Id, AccountId, PreferredAddressId FROM ProviderAcctTerritoryInfo ' +
            'WHERE SourceSystemName = \'' + escapedTag + '\' AND AccountId IN (\'' +
            String.join(new List<Id>(acctToCpaId.keySet()), '\',\'') + '\') AND PreferredAddressId = null'
        );

        List<SObject> toUpdate = new List<SObject>();
        for (SObject pati : patiRecords) {
            Id acctId = (Id) pati.get('AccountId');
            Id cpaId = acctToCpaId.get(acctId);
            if (cpaId != null) {
                pati.put('PreferredAddressId', cpaId);
                toUpdate.add(pati);
            }
        }

        if (!toUpdate.isEmpty()) {
            Database.update(toUpdate, false);
        }
    }

    // ──────────────────────────────────────────────────────────
    // Build ContactPointAddress records
    // ──────────────────────────────────────────────────────────

    private static List<ContactPointAddress> buildAddresses(List<Account> accounts) {
        List<ContactPointAddress> addresses = new List<ContactPointAddress>();

        for (Account acct : accounts) {
            ContactPointAddress cpa = new ContactPointAddress();
            cpa.Name = DEMO_TAG + ' - ' + acct.Name + ' Primary';
            cpa.AddressType = 'Billing';
            cpa.UsageType = 'Work';
            cpa.ParentId = acct.Id;

            if (String.isNotBlank(acct.BillingCity)) {
                cpa.Street = acct.BillingStreet;
                cpa.City = acct.BillingCity;
                cpa.State = acct.BillingState;
                cpa.PostalCode = acct.BillingPostalCode;
                cpa.Country = acct.BillingCountry;
            } else {
                Map<String, String> addr = getRealisticAddress(acct.BillingCountry);
                cpa.Street = addr.get('street');
                cpa.City = addr.get('city');
                if (addr.containsKey('state')) cpa.State = addr.get('state');
                cpa.PostalCode = addr.get('postalCode');
                cpa.Country = addr.get('country');
            }

            cpa.IsActive = true;
            addresses.add(cpa);
        }

        return addresses;
    }

    private static Map<String, String> getRealisticAddress(String country) {
        Map<String, String> addr = new Map<String, String>();

        if (country == 'United Kingdom' || country == 'UK' || country == 'GB') {
            addr.put('street', '10 Harley Street');
            addr.put('city', 'London');
            addr.put('postalCode', 'W1G 9PF');
            addr.put('country', 'GB');
        } else if (country == 'France' || country == 'FR') {
            addr.put('street', '47 Boulevard de l\'Hopital');
            addr.put('city', 'Paris');
            addr.put('postalCode', '75013');
            addr.put('country', 'FR');
        } else if (country == 'Germany' || country == 'DE') {
            addr.put('street', 'Chariteplatz 1');
            addr.put('city', 'Berlin');
            addr.put('postalCode', '10117');
            addr.put('country', 'DE');
        } else if (country == 'Italy' || country == 'IT') {
            addr.put('street', 'Via Francesco Sforza 35');
            addr.put('city', 'Milan');
            addr.put('state', 'MI');
            addr.put('postalCode', '20122');
            addr.put('country', 'IT');
        } else if (country == 'Spain' || country == 'ES') {
            addr.put('street', 'Calle del Prof Martin Lagos');
            addr.put('city', 'Madrid');
            addr.put('postalCode', '28040');
            addr.put('country', 'ES');
        } else {
            addr.put('street', '1250 Health Sciences Drive');
            addr.put('city', 'San Francisco');
            addr.put('state', 'CA');
            addr.put('postalCode', '94143');
            addr.put('country', 'US');
        }

        return addr;
    }

    // ──────────────────────────────────────────────────────────
    // Build ContactPointEmail records
    // ──────────────────────────────────────────────────────────

    private static List<ContactPointEmail> buildEmails(
        List<Account> accounts,
        List<SObject> hcps
    ) {
        List<ContactPointEmail> emails = new List<ContactPointEmail>();

        for (Account acct : accounts) {
            String domain = sanitizeDomain(acct.Name);
            ContactPointEmail cpe = new ContactPointEmail();
            cpe.EmailAddress = 'info@' + domain + '.com';
            cpe.EmailMailBox = 'info';
            cpe.IsPrimary = true;
            cpe.ParentId = acct.Id;
            emails.add(cpe);
        }

        for (SObject hcp : hcps) {
            Id hcpAccountId = (Id) hcp.get('AccountId');
            if (hcpAccountId == null) continue;

            String hcpName = (String) hcp.get('Name');
            String lastName = extractLastName(hcpName);
            String domain = sanitizeDomain(hcpName);

            ContactPointEmail cpe = new ContactPointEmail();
            cpe.EmailAddress = 'dr.' + lastName.toLowerCase() + '@' + domain + '.com';
            cpe.EmailMailBox = 'dr.' + lastName.toLowerCase();
            cpe.IsPrimary = true;
            cpe.ParentId = hcpAccountId;
            emails.add(cpe);
        }

        return emails;
    }

    // ──────────────────────────────────────────────────────────
    // Build ContactPointPhone records
    // ──────────────────────────────────────────────────────────

    private static List<ContactPointPhone> buildPhones(
        List<Account> accounts,
        List<SObject> hcps
    ) {
        List<ContactPointPhone> phones = new List<ContactPointPhone>();
        Integer counter = 0;

        for (Account acct : accounts) {
            String countryCode = acct.BillingCountry;

            ContactPointPhone mainPhone = new ContactPointPhone();
            mainPhone.TelephoneNumber = generatePhone(countryCode, counter++);
            mainPhone.PhoneType = 'Home';
            mainPhone.IsPrimary = true;
            mainPhone.ParentId = acct.Id;
            phones.add(mainPhone);

            ContactPointPhone mobilePhone = new ContactPointPhone();
            mobilePhone.TelephoneNumber = generatePhone(countryCode, counter++);
            mobilePhone.PhoneType = 'Mobile';
            mobilePhone.IsPrimary = false;
            mobilePhone.ParentId = acct.Id;
            phones.add(mobilePhone);
        }

        for (SObject hcp : hcps) {
            Id hcpAccountId = (Id) hcp.get('AccountId');
            if (hcpAccountId == null) continue;

            ContactPointPhone office = new ContactPointPhone();
            office.TelephoneNumber = generatePhone('US', counter++);
            office.PhoneType = 'Home';
            office.IsPrimary = true;
            office.ParentId = hcpAccountId;
            phones.add(office);

            ContactPointPhone mobile = new ContactPointPhone();
            mobile.TelephoneNumber = generatePhone('US', counter++);
            mobile.PhoneType = 'Mobile';
            mobile.IsPrimary = false;
            mobile.ParentId = hcpAccountId;
            phones.add(mobile);
        }

        return phones;
    }

    private static String generatePhone(String country, Integer seed) {
        String last4 = String.valueOf(Math.mod(1000 + seed * 137, 9000) + 1000);
        String mid3 = String.valueOf(Math.mod(200 + seed * 53, 800) + 200);

        if (country == 'United Kingdom' || country == 'UK' || country == 'GB') {
            return '+44-20-' + mid3 + '-' + last4;
        } else if (country == 'France' || country == 'FR') {
            String d2 = String.valueOf(Math.mod(10 + seed * 7, 90) + 10);
            return '+33-1-' + d2 + '-' + mid3.substring(0, 2) + '-' + last4.substring(0, 2) + '-' + last4.substring(2, 4);
        } else if (country == 'Germany' || country == 'DE') {
            return '+49-30-' + mid3 + last4;
        } else if (country == 'Italy' || country == 'IT') {
            return '+39-02-' + mid3 + last4;
        } else if (country == 'Spain' || country == 'ES') {
            return '+34-91' + mid3.substring(0, 1) + '-' + mid3.substring(1) + '-' + last4.substring(0, 3);
        } else {
            return '+1-415-' + mid3 + '-' + last4;
        }
    }

    // ──────────────────────────────────────────────────────────
    // Build ContactPointSocial records
    // ──────────────────────────────────────────────────────────

    private static List<SObject> buildSocials(List<Account> accounts) {
        List<SObject> socials = new List<SObject>();
        Schema.SObjectType socialType = Schema.getGlobalDescribe().get('contactpointsocial');
        if (socialType == null) return socials;

        for (Account acct : accounts) {
            String acctType = acct.Type;
            if (acctType == null) continue;
            String acctTypeLower = acctType.toLowerCase();
            if (!acctTypeLower.contains('hospital') && !acctTypeLower.contains('health system') &&
                !acctTypeLower.contains('clinic') && !acctTypeLower.contains('medical center')) {
                continue;
            }

            String handle = sanitizeDomain(acct.Name);

            String liHandle = 'linkedin.com/company/' + handle;
            if (liHandle.length() > 40) liHandle = liHandle.substring(0, 40);

            SObject linkedin = socialType.newSObject();
            linkedin.put('Name', acct.Name + ' LinkedIn');
            linkedin.put('SocialPlatformProvider', 'LinkedIn');
            linkedin.put('SocialHandleIdentifier', liHandle);
            linkedin.put('SocialHandleName', handle);
            linkedin.put('ParentReferenceRecordId', acct.Id);
            linkedin.put('SourceSystemName', DEMO_TAG);
            socials.add(linkedin);

            String xHandle = '@' + handle;
            if (xHandle.length() > 40) xHandle = xHandle.substring(0, 40);

            SObject xRecord = socialType.newSObject();
            xRecord.put('Name', acct.Name + ' X');
            xRecord.put('SocialPlatformProvider', 'X');
            xRecord.put('SocialHandleIdentifier', xHandle);
            xRecord.put('SocialHandleName', handle);
            xRecord.put('ParentReferenceRecordId', acct.Id);
            xRecord.put('SourceSystemName', DEMO_TAG);
            socials.add(xRecord);
        }

        return socials;
    }

    // ──────────────────────────────────────────────────────────
    // Build BusinessLicense records
    // ──────────────────────────────────────────────────────────

    private static List<SObject> buildBusinessLicenses(List<Account> accounts) {
        List<SObject> licenses = new List<SObject>();
        Schema.SObjectType blType = Schema.getGlobalDescribe().get('businesslicense');
        if (blType == null) return licenses;

        Integer counter = 0;

        for (Account acct : accounts) {
            String country = String.isNotBlank(acct.BillingCountry) ? acct.BillingCountry : 'United States';
            String state = String.isNotBlank(acct.BillingStateCode) ? acct.BillingStateCode
                         : (String.isNotBlank(acct.BillingState) ? acct.BillingState : 'CA');

            if (acct.IsPersonAccount) {
                String licNum = generateMedicalLicenseNumber(acct.BillingCountryCode, counter++);
                SObject bl = blType.newSObject();
                bl.put('Name', DEMO_TAG + ' - ' + acct.Name + ' Medical License');
                bl.put('LicenseNumber', licNum);
                bl.put('Status', 'Verified');
                bl.put('IsActive', true);
                bl.put('VerificationStatus', 'Authorized');
                bl.put('LicenseClass', 'Healthcare');
                bl.put('Description', 'Medical Practitioner License');
                bl.put('IssueDate', Date.today().addYears(-3));
                bl.put('PeriodStart', Datetime.newInstance(Date.today().addYears(-3), Time.newInstance(0, 0, 0, 0)));
                bl.put('PeriodEnd', Datetime.newInstance(Date.today().addYears(5), Time.newInstance(0, 0, 0, 0)));
                bl.put('ComplianceScope', 'JurisdictionState');
                bl.put('JurisdictionState', state);
                bl.put('Identifier', DEMO_TAG + '-' + licNum);
                bl.put('AccountId', acct.Id);
                if (acct.PersonContactId != null) bl.put('ContactId', acct.PersonContactId);
                licenses.add(bl);
                continue;
            }

            String acctType = acct.Type;
            String acctTypeLower = String.isNotBlank(acctType) ? acctType.toLowerCase() : '';

            if (acctTypeLower.contains('hospital') || acctTypeLower.contains('clinic') ||
                acctTypeLower.contains('medical center') || acctTypeLower.contains('health system')) {

                String licNum = generateFacilityLicenseNumber(country, state, counter++);
                SObject bl = blType.newSObject();
                bl.put('Name', DEMO_TAG + ' - ' + acct.Name + ' Facility License');
                bl.put('LicenseNumber', licNum);
                bl.put('Status', 'Verified');
                bl.put('IsActive', true);
                bl.put('VerificationStatus', 'Authorized');
                bl.put('LicenseClass', 'Healthcare');
                bl.put('Description', 'Medical Facility');
                bl.put('IssueDate', Date.today().addYears(-2));
                bl.put('PeriodStart', Datetime.newInstance(Date.today().addYears(-2), Time.newInstance(0, 0, 0, 0)));
                bl.put('PeriodEnd', Datetime.newInstance(Date.today().addYears(3), Time.newInstance(0, 0, 0, 0)));
                bl.put('ComplianceScope', 'JurisdictionState');
                bl.put('JurisdictionState', state);
                bl.put('Identifier', DEMO_TAG + '-' + licNum);
                bl.put('AccountId', acct.Id);
                licenses.add(bl);

            } else if (acctTypeLower.contains('pharmacy')) {

                String licNum = generatePharmacyLicenseNumber(country, state, counter++);
                SObject bl = blType.newSObject();
                bl.put('Name', DEMO_TAG + ' - ' + acct.Name + ' Pharmacy License');
                bl.put('LicenseNumber', licNum);
                bl.put('Status', 'Verified');
                bl.put('IsActive', true);
                bl.put('VerificationStatus', 'Authorized');
                bl.put('LicenseClass', 'Pharmaceutical');
                bl.put('Description', 'Pharmacy');
                bl.put('IssueDate', Date.today().addYears(-1));
                bl.put('PeriodStart', Datetime.newInstance(Date.today().addYears(-1), Time.newInstance(0, 0, 0, 0)));
                bl.put('PeriodEnd', Datetime.newInstance(Date.today().addYears(2), Time.newInstance(0, 0, 0, 0)));
                bl.put('ComplianceScope', 'JurisdictionState');
                bl.put('JurisdictionState', state);
                bl.put('Identifier', DEMO_TAG + '-' + licNum);
                bl.put('AccountId', acct.Id);
                licenses.add(bl);

            } else {
                // Insurance, payers, and other org types still need a state license for green mobile icon
                String licNum = generateFacilityLicenseNumber(country, state, counter++);
                SObject bl = blType.newSObject();
                bl.put('Name', DEMO_TAG + ' - ' + acct.Name + ' State License');
                bl.put('LicenseNumber', licNum);
                bl.put('Status', 'Verified');
                bl.put('IsActive', true);
                bl.put('VerificationStatus', 'Authorized');
                bl.put('LicenseClass', 'Healthcare');
                bl.put('Description', 'Business License');
                bl.put('IssueDate', Date.today().addYears(-2));
                bl.put('PeriodStart', Datetime.newInstance(Date.today().addYears(-2), Time.newInstance(0, 0, 0, 0)));
                bl.put('PeriodEnd', Datetime.newInstance(Date.today().addYears(3), Time.newInstance(0, 0, 0, 0)));
                bl.put('ComplianceScope', 'JurisdictionState');
                bl.put('JurisdictionState', state);
                bl.put('Identifier', DEMO_TAG + '-' + licNum);
                bl.put('AccountId', acct.Id);
                licenses.add(bl);
            }
        }

        return licenses;
    }

    private static String generateFacilityLicenseNumber(String country, String state, Integer seed) {
        String seq = String.valueOf(100000 + seed * 731).substring(0, 6);
        if (country == 'United Kingdom' || country == 'UK' || country == 'GB') return 'CQC-' + seq;
        if (country == 'France' || country == 'FR') return 'FINESS-' + seq;
        if (country == 'Germany' || country == 'DE') return 'IK-' + seq;
        if (country == 'Italy' || country == 'IT') return 'SSN-' + seq;
        if (country == 'Spain' || country == 'ES') return 'REGA-' + seq;
        String stateAbbr = (state != null && state.length() >= 2) ? state.substring(0, 2).toUpperCase() : 'CA';
        return stateAbbr + '-MFL-' + seq;
    }

    private static String generateMedicalLicenseNumber(String countryCode, Integer seed) {
        String seq = String.valueOf(300000 + seed * 547).substring(0, 6);
        if (countryCode == 'GB') return 'GMC-' + seq;
        if (countryCode == 'FR') return 'RPPS-' + seq;
        if (countryCode == 'DE') return 'LANR-' + seq;
        if (countryCode == 'IT') return 'OMC-' + seq;
        if (countryCode == 'ES') return 'COM-' + seq;
        if (countryCode == 'JP') return 'MHLW-' + seq;
        if (countryCode == 'KR') return 'MOHW-' + seq;
        if (countryCode == 'BR') return 'CRM-' + seq;
        if (countryCode == 'MX') return 'CESS-' + seq;
        if (countryCode == 'AR') return 'MN-' + seq;
        return 'MED-' + seq;
    }

    private static String generatePharmacyLicenseNumber(String country, String state, Integer seed) {
        String seq = String.valueOf(200000 + seed * 419).substring(0, 6);
        if (country == 'United Kingdom' || country == 'UK' || country == 'GB') return 'GPhC-' + seq;
        if (country == 'France' || country == 'FR') return 'RPPS-' + seq;
        if (country == 'Germany' || country == 'DE') return 'ApoG-' + seq;
        if (country == 'Italy' || country == 'IT') return 'FOFI-' + seq;
        if (country == 'Spain' || country == 'ES') return 'COF-' + seq;
        String stateAbbr = (state != null && state.length() >= 2) ? state.substring(0, 2).toUpperCase() : 'CA';
        return stateAbbr + '-PHY-' + seq;
    }

    // ──────────────────────────────────────────────────────────
    // Utility methods
    // ──────────────────────────────────────────────────────────

    private static String batchResult(Integer created, Integer attempted, Boolean hasMore, List<String> errors) {
        return JSON.serialize(new Map<String, Object>{
            'created' => created,
            'attempted' => attempted,
            'hasMore' => hasMore,
            'errors' => errors
        });
    }

    private static String sanitizeDomain(String name) {
        if (String.isBlank(name)) return 'unknown';
        return name.replaceAll('[^a-zA-Z0-9]', '').toLowerCase();
    }

    private static String extractLastName(String fullName) {
        if (String.isBlank(fullName)) return 'provider';
        List<String> parts = fullName.split('\\s+');
        return parts[parts.size() - 1].replaceAll('[^a-zA-Z]', '');
    }

    private static Integer countSuccesses(List<Database.SaveResult> results) {
        Integer count = 0;
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) count++;
        }
        return count;
    }

    private static void collectErrors(Database.SaveResult[] results, List<SObject> records, List<String> errors) {
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess() && errors.size() < 5) {
                String name = '';
                try { name = (String) records[i].get('Name'); } catch (Exception ex) { name = 'record ' + i; }
                errors.add(name + ': ' + results[i].getErrors()[0].getMessage());
            }
        }
    }

    private static Integer countDeleteSuccesses(List<Database.DeleteResult> results) {
        Integer count = 0;
        for (Database.DeleteResult dr : results) {
            if (dr.isSuccess()) count++;
        }
        return count;
    }
}
