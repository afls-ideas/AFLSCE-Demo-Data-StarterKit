/**
 * DemoContactPointController
 *
 * Creates ContactPointAddress, ContactPointEmail, ContactPointPhone,
 * ContactPointSocial, and BusinessLicense records tied to existing
 * Account and HealthcareProvider records tagged with 'AFLSCE-Demo-Data'.
 *
 * Callable from LWC via @AuraEnabled methods.
 */
public with sharing class DemoContactPointController {

    private static final String DEMO_TAG = 'AFLSCE-Demo-Data';

    // ──────────────────────────────────────────────────────────
    // Public AuraEnabled methods
    // ──────────────────────────────────────────────────────────

    @AuraEnabled
    public static String createContactPoints() {
        try {
            List<Account> accounts = queryAccounts();
            List<HealthcareProvider> hcps = queryHealthcareProviders();

            if (accounts.isEmpty() && hcps.isEmpty()) {
                return 'No records found with AFLSCE-Demo-Data tag.';
            }

            Map<String, Boolean> available = checkObjectAvailability();

            List<String> results = new List<String>();
            Integer totalCreated = 0;

            // ContactPointAddress
            if (available.get('ContactPointAddress') == true) {
                List<ContactPointAddress> addresses = buildAddresses(accounts, hcps);
                if (!addresses.isEmpty()) {
                    List<Database.SaveResult> sr = Database.insert(addresses, false);
                    Integer cnt = countSuccesses(sr);
                    totalCreated += cnt;
                    results.add('ContactPointAddress: ' + cnt + '/' + addresses.size());
                }
            } else {
                results.add('ContactPointAddress: object not available');
            }

            // ContactPointEmail
            if (available.get('ContactPointEmail') == true) {
                List<ContactPointEmail> emails = buildEmails(accounts, hcps);
                if (!emails.isEmpty()) {
                    List<Database.SaveResult> sr = Database.insert(emails, false);
                    Integer cnt = countSuccesses(sr);
                    totalCreated += cnt;
                    results.add('ContactPointEmail: ' + cnt + '/' + emails.size());
                }
            } else {
                results.add('ContactPointEmail: object not available');
            }

            // ContactPointPhone
            if (available.get('ContactPointPhone') == true) {
                List<ContactPointPhone> phones = buildPhones(accounts, hcps);
                if (!phones.isEmpty()) {
                    List<Database.SaveResult> sr = Database.insert(phones, false);
                    Integer cnt = countSuccesses(sr);
                    totalCreated += cnt;
                    results.add('ContactPointPhone: ' + cnt + '/' + phones.size());
                }
            } else {
                results.add('ContactPointPhone: object not available');
            }

            // ContactPointSocial — check via Schema since it may not exist
            if (available.get('ContactPointSocial') == true) {
                List<SObject> socials = buildSocials(accounts);
                if (!socials.isEmpty()) {
                    List<Database.SaveResult> sr = Database.insert(socials, false);
                    Integer cnt = countSuccesses(sr);
                    totalCreated += cnt;
                    results.add('ContactPointSocial: ' + cnt + '/' + socials.size());
                }
            } else {
                results.add('ContactPointSocial: object not available');
            }

            // BusinessLicense
            if (available.get('BusinessLicense') == true) {
                List<BusinessLicense> licenses = buildBusinessLicenses(accounts);
                if (!licenses.isEmpty()) {
                    List<Database.SaveResult> sr = Database.insert(licenses, false);
                    Integer cnt = countSuccesses(sr);
                    totalCreated += cnt;
                    results.add('BusinessLicense: ' + cnt + '/' + licenses.size());
                }
            } else {
                results.add('BusinessLicense: object not available');
            }

            return 'Created ' + totalCreated + ' records. Details: ' + String.join(results, '; ');

        } catch (Exception e) {
            throw new AuraHandledException(
                'Error creating contact points: ' + e.getMessage()
            );
        }
    }

    @AuraEnabled
    public static String getStatus() {
        try {
            Map<String, Boolean> available = checkObjectAvailability();
            List<String> counts = new List<String>();

            if (available.get('ContactPointAddress') == true) {
                Integer cnt = [SELECT COUNT() FROM ContactPointAddress WHERE Name LIKE :('%' + DEMO_TAG + '%') OR Parent.Name IN (SELECT Name FROM Account WHERE Description LIKE :('%' + DEMO_TAG + '%'))];
                counts.add('ContactPointAddress: ' + cnt);
            }
            if (available.get('ContactPointEmail') == true) {
                Integer cnt = [SELECT COUNT() FROM ContactPointEmail WHERE ParentId IN (SELECT Id FROM Account WHERE Description LIKE :('%' + DEMO_TAG + '%'))];
                counts.add('ContactPointEmail: ' + cnt);
            }
            if (available.get('ContactPointPhone') == true) {
                Integer cnt = [SELECT COUNT() FROM ContactPointPhone WHERE ParentId IN (SELECT Id FROM Account WHERE Description LIKE :('%' + DEMO_TAG + '%'))];
                counts.add('ContactPointPhone: ' + cnt);
            }
            if (available.get('BusinessLicense') == true) {
                Integer cnt = [SELECT COUNT() FROM BusinessLicense WHERE Name LIKE :('%' + DEMO_TAG + '%')];
                counts.add('BusinessLicense: ' + cnt);
            }

            return counts.isEmpty() ? 'No contact point objects available.' : String.join(counts, '; ');

        } catch (Exception e) {
            throw new AuraHandledException(
                'Error getting status: ' + e.getMessage()
            );
        }
    }

    @AuraEnabled
    public static String deleteContactPoints() {
        try {
            List<Account> taggedAccounts = queryAccounts();
            Set<Id> accountIds = new Set<Id>();
            for (Account a : taggedAccounts) {
                accountIds.add(a.Id);
            }

            Map<String, Boolean> available = checkObjectAvailability();
            Integer totalDeleted = 0;

            if (available.get('ContactPointAddress') == true && !accountIds.isEmpty()) {
                List<ContactPointAddress> recs = [
                    SELECT Id FROM ContactPointAddress
                    WHERE ParentId IN :accountIds
                ];
                if (!recs.isEmpty()) {
                    List<Database.DeleteResult> dr = Database.delete(recs, false);
                    totalDeleted += countDeleteSuccesses(dr);
                }
            }

            if (available.get('ContactPointEmail') == true && !accountIds.isEmpty()) {
                List<ContactPointEmail> recs = [
                    SELECT Id FROM ContactPointEmail
                    WHERE ParentId IN :accountIds
                ];
                if (!recs.isEmpty()) {
                    List<Database.DeleteResult> dr = Database.delete(recs, false);
                    totalDeleted += countDeleteSuccesses(dr);
                }
            }

            if (available.get('ContactPointPhone') == true && !accountIds.isEmpty()) {
                List<ContactPointPhone> recs = [
                    SELECT Id FROM ContactPointPhone
                    WHERE ParentId IN :accountIds
                ];
                if (!recs.isEmpty()) {
                    List<Database.DeleteResult> dr = Database.delete(recs, false);
                    totalDeleted += countDeleteSuccesses(dr);
                }
            }

            if (available.get('ContactPointSocial') == true && !accountIds.isEmpty()) {
                String soql = 'SELECT Id FROM ContactPointSocial WHERE ParentId IN :accountIds';
                List<SObject> recs = Database.query(soql);
                if (!recs.isEmpty()) {
                    List<Database.DeleteResult> dr = Database.delete(recs, false);
                    totalDeleted += countDeleteSuccesses(dr);
                }
            }

            if (available.get('BusinessLicense') == true) {
                String likePattern = '%' + DEMO_TAG + '%';
                List<BusinessLicense> recs = [
                    SELECT Id FROM BusinessLicense
                    WHERE Name LIKE :likePattern
                ];
                if (!recs.isEmpty()) {
                    List<Database.DeleteResult> dr = Database.delete(recs, false);
                    totalDeleted += countDeleteSuccesses(dr);
                }
            }

            return 'Deleted ' + totalDeleted + ' contact point and license records.';

        } catch (Exception e) {
            throw new AuraHandledException(
                'Error deleting contact points: ' + e.getMessage()
            );
        }
    }

    // ──────────────────────────────────────────────────────────
    // Query helpers
    // ──────────────────────────────────────────────────────────

    private static List<Account> queryAccounts() {
        String likePattern = '%' + DEMO_TAG + '%';
        return [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState,
                   BillingPostalCode, BillingCountry, Type, Description, Phone
            FROM Account
            WHERE Description LIKE :likePattern
            ORDER BY Name
        ];
    }

    private static List<HealthcareProvider> queryHealthcareProviders() {
        String likePattern = '%' + DEMO_TAG + '%';
        return [
            SELECT Id, Name, Description
            FROM HealthcareProvider
            WHERE Description LIKE :likePattern
            ORDER BY Name
        ];
    }

    private static Map<String, Boolean> checkObjectAvailability() {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Map<String, Boolean> result = new Map<String, Boolean>();
        result.put('ContactPointAddress', gd.containsKey('ContactPointAddress'));
        result.put('ContactPointEmail', gd.containsKey('ContactPointEmail'));
        result.put('ContactPointPhone', gd.containsKey('ContactPointPhone'));
        result.put('ContactPointSocial', gd.containsKey('ContactPointSocial'));
        result.put('BusinessLicense', gd.containsKey('BusinessLicense'));
        return result;
    }

    // ──────────────────────────────────────────────────────────
    // Build ContactPointAddress records
    // ──────────────────────────────────────────────────────────

    private static List<ContactPointAddress> buildAddresses(
        List<Account> accounts,
        List<HealthcareProvider> hcps
    ) {
        List<ContactPointAddress> addresses = new List<ContactPointAddress>();

        for (Account acct : accounts) {
            // Use the Account's billing address if present; otherwise generate one
            String street = acct.BillingStreet;
            String city = acct.BillingCity;
            String state = acct.BillingState;
            String postalCode = acct.BillingPostalCode;
            String country = acct.BillingCountry;

            if (String.isBlank(street)) {
                Map<String, String> addr = getRealisticAddress(country, acct.Name);
                street = addr.get('street');
                city = addr.get('city');
                state = addr.get('state');
                postalCode = addr.get('postalCode');
                country = addr.get('country');
            }

            ContactPointAddress cpa = new ContactPointAddress();
            cpa.Name = DEMO_TAG + ' - ' + acct.Name + ' Primary';
            cpa.Street = street;
            cpa.City = city;
            cpa.State = state;
            cpa.PostalCode = postalCode;
            cpa.Country = country;
            cpa.AddressType = 'Mailing';
            cpa.ParentId = acct.Id;
            addresses.add(cpa);
        }

        // HCP office addresses — ParentId on ContactPointAddress is polymorphic;
        // HealthcareProvider may or may not be a valid parent. We link via Account
        // if available, otherwise skip.
        return addresses;
    }

    private static Map<String, String> getRealisticAddress(String country, String contextName) {
        Map<String, String> addr = new Map<String, String>();

        if (country == 'United Kingdom' || country == 'UK' || country == 'GB') {
            addr.put('street', '10 Harley Street');
            addr.put('city', 'London');
            addr.put('state', 'England');
            addr.put('postalCode', 'W1G 9PF');
            addr.put('country', 'United Kingdom');
        } else if (country == 'France' || country == 'FR') {
            addr.put('street', '47 Boulevard de l\'Hôpital');
            addr.put('city', 'Paris');
            addr.put('state', 'Île-de-France');
            addr.put('postalCode', '75013');
            addr.put('country', 'France');
        } else if (country == 'Germany' || country == 'DE') {
            addr.put('street', 'Charité­platz 1');
            addr.put('city', 'Berlin');
            addr.put('state', 'Berlin');
            addr.put('postalCode', '10117');
            addr.put('country', 'Germany');
        } else if (country == 'Italy' || country == 'IT') {
            addr.put('street', 'Via Francesco Sforza 35');
            addr.put('city', 'Milan');
            addr.put('state', 'Lombardy');
            addr.put('postalCode', '20122');
            addr.put('country', 'Italy');
        } else if (country == 'Spain' || country == 'ES') {
            addr.put('street', 'Calle del Prof Martín Lagos');
            addr.put('city', 'Madrid');
            addr.put('state', 'Madrid');
            addr.put('postalCode', '28040');
            addr.put('country', 'Spain');
        } else {
            // Default to US
            addr.put('street', '1250 Health Sciences Drive');
            addr.put('city', 'San Francisco');
            addr.put('state', 'CA');
            addr.put('postalCode', '94143');
            addr.put('country', 'United States');
        }

        return addr;
    }

    // ──────────────────────────────────────────────────────────
    // Build ContactPointEmail records
    // ──────────────────────────────────────────────────────────

    private static List<ContactPointEmail> buildEmails(
        List<Account> accounts,
        List<HealthcareProvider> hcps
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

        // HCP professional emails — linked to Account parent
        for (HealthcareProvider hcp : hcps) {
            String lastName = extractLastName(hcp.Name);
            String domain = sanitizeDomain(hcp.Name);

            ContactPointEmail cpe = new ContactPointEmail();
            cpe.EmailAddress = 'dr.' + lastName.toLowerCase() + '@' + domain + '.com';
            cpe.EmailMailBox = 'dr.' + lastName.toLowerCase();
            cpe.IsPrimary = true;
            cpe.ParentId = hcp.Id;
            emails.add(cpe);
        }

        return emails;
    }

    // ──────────────────────────────────────────────────────────
    // Build ContactPointPhone records
    // ──────────────────────────────────────────────────────────

    private static List<ContactPointPhone> buildPhones(
        List<Account> accounts,
        List<HealthcareProvider> hcps
    ) {
        List<ContactPointPhone> phones = new List<ContactPointPhone>();
        Integer counter = 0;

        for (Account acct : accounts) {
            String countryCode = acct.BillingCountry;

            // Main business phone
            ContactPointPhone mainPhone = new ContactPointPhone();
            mainPhone.TelephoneNumber = generatePhone(countryCode, counter++);
            mainPhone.PhoneType = 'Business';
            mainPhone.IsPrimary = true;
            mainPhone.ParentId = acct.Id;
            phones.add(mainPhone);

            // Fax
            ContactPointPhone fax = new ContactPointPhone();
            fax.TelephoneNumber = generatePhone(countryCode, counter++);
            fax.PhoneType = 'Fax';
            fax.IsPrimary = false;
            fax.ParentId = acct.Id;
            phones.add(fax);
        }

        for (HealthcareProvider hcp : hcps) {
            // Office phone
            ContactPointPhone office = new ContactPointPhone();
            office.TelephoneNumber = generatePhone('US', counter++);
            office.PhoneType = 'Business';
            office.IsPrimary = true;
            office.ParentId = hcp.Id;
            phones.add(office);

            // Mobile
            ContactPointPhone mobile = new ContactPointPhone();
            mobile.TelephoneNumber = generatePhone('US', counter++);
            mobile.PhoneType = 'Mobile';
            mobile.IsPrimary = false;
            mobile.ParentId = hcp.Id;
            phones.add(mobile);
        }

        return phones;
    }

    private static String generatePhone(String country, Integer seed) {
        // Generate realistic-looking phone numbers per country
        // Use seed to vary the last digits
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
            // US default
            return '+1-415-' + mid3 + '-' + last4;
        }
    }

    // ──────────────────────────────────────────────────────────
    // Build ContactPointSocial records (dynamic SObject)
    // ──────────────────────────────────────────────────────────

    private static List<SObject> buildSocials(List<Account> accounts) {
        List<SObject> socials = new List<SObject>();
        Schema.SObjectType socialType = Schema.getGlobalDescribe().get('ContactPointSocial');
        if (socialType == null) {
            return socials;
        }

        for (Account acct : accounts) {
            String acctType = acct.Type;
            // Only create social profiles for hospitals and health systems
            if (acctType == null) {
                continue;
            }
            String acctTypeLower = acctType.toLowerCase();
            if (!acctTypeLower.contains('hospital') && !acctTypeLower.contains('health system') &&
                !acctTypeLower.contains('clinic') && !acctTypeLower.contains('medical center')) {
                continue;
            }

            String handle = sanitizeDomain(acct.Name);

            // LinkedIn
            SObject linkedin = socialType.newSObject();
            linkedin.put('SocialNetworkProvider', 'LinkedIn');
            linkedin.put('SocialHandle', 'linkedin.com/company/' + handle);
            linkedin.put('ParentId', acct.Id);
            socials.add(linkedin);

            // Twitter / X
            SObject twitter = socialType.newSObject();
            twitter.put('SocialNetworkProvider', 'Twitter');
            twitter.put('SocialHandle', '@' + handle);
            twitter.put('ParentId', acct.Id);
            socials.add(twitter);
        }

        return socials;
    }

    // ──────────────────────────────────────────────────────────
    // Build BusinessLicense records
    // ──────────────────────────────────────────────────────────

    private static List<BusinessLicense> buildBusinessLicenses(List<Account> accounts) {
        List<BusinessLicense> licenses = new List<BusinessLicense>();
        Integer counter = 0;

        for (Account acct : accounts) {
            String acctType = acct.Type;
            if (acctType == null) {
                continue;
            }
            String acctTypeLower = acctType.toLowerCase();

            String country = String.isNotBlank(acct.BillingCountry) ? acct.BillingCountry : 'United States';
            String state = String.isNotBlank(acct.BillingState) ? acct.BillingState : 'CA';

            if (acctTypeLower.contains('hospital') || acctTypeLower.contains('clinic') ||
                acctTypeLower.contains('medical center') || acctTypeLower.contains('health system')) {

                BusinessLicense bl = new BusinessLicense();
                bl.Name = DEMO_TAG + ' - ' + acct.Name + ' Facility License';
                bl.LicenseNumber = generateFacilityLicenseNumber(country, state, counter++);
                bl.Status = 'Active';
                bl.LicenseType = 'Medical Facility';
                bl.LicenseClass = 'Healthcare';
                bl.EffectiveDate = Date.today().addYears(-2);
                bl.ExpirationDate = Date.today().addYears(3);
                licenses.add(bl);

            } else if (acctTypeLower.contains('pharmacy')) {

                BusinessLicense bl = new BusinessLicense();
                bl.Name = DEMO_TAG + ' - ' + acct.Name + ' Pharmacy License';
                bl.LicenseNumber = generatePharmacyLicenseNumber(country, state, counter++);
                bl.Status = 'Active';
                bl.LicenseType = 'Pharmacy';
                bl.LicenseClass = 'Pharmaceutical';
                bl.EffectiveDate = Date.today().addYears(-1);
                bl.ExpirationDate = Date.today().addYears(2);
                licenses.add(bl);
            }
        }

        return licenses;
    }

    private static String generateFacilityLicenseNumber(String country, String state, Integer seed) {
        String seq = String.valueOf(100000 + seed * 731).substring(0, 6);

        if (country == 'United Kingdom' || country == 'UK' || country == 'GB') {
            return 'CQC-' + seq;
        } else if (country == 'France' || country == 'FR') {
            return 'FINESS-' + seq;
        } else if (country == 'Germany' || country == 'DE') {
            return 'IK-' + seq;
        } else if (country == 'Italy' || country == 'IT') {
            return 'SSN-' + seq;
        } else if (country == 'Spain' || country == 'ES') {
            return 'REGA-' + seq;
        } else {
            // US: state-specific
            String stateAbbr = (state != null && state.length() >= 2) ? state.substring(0, 2).toUpperCase() : 'CA';
            return stateAbbr + '-MFL-' + seq;
        }
    }

    private static String generatePharmacyLicenseNumber(String country, String state, Integer seed) {
        String seq = String.valueOf(200000 + seed * 419).substring(0, 6);

        if (country == 'United Kingdom' || country == 'UK' || country == 'GB') {
            return 'GPhC-' + seq;
        } else if (country == 'France' || country == 'FR') {
            return 'RPPS-' + seq;
        } else if (country == 'Germany' || country == 'DE') {
            return 'ApoG-' + seq;
        } else if (country == 'Italy' || country == 'IT') {
            return 'FOFI-' + seq;
        } else if (country == 'Spain' || country == 'ES') {
            return 'COF-' + seq;
        } else {
            String stateAbbr = (state != null && state.length() >= 2) ? state.substring(0, 2).toUpperCase() : 'CA';
            return stateAbbr + '-PHY-' + seq;
        }
    }

    // ──────────────────────────────────────────────────────────
    // Utility methods
    // ──────────────────────────────────────────────────────────

    private static String sanitizeDomain(String name) {
        if (String.isBlank(name)) {
            return 'unknown';
        }
        return name.replaceAll('[^a-zA-Z0-9]', '').toLowerCase();
    }

    private static String extractLastName(String fullName) {
        if (String.isBlank(fullName)) {
            return 'provider';
        }
        List<String> parts = fullName.split('\\s+');
        return parts[parts.size() - 1].replaceAll('[^a-zA-Z]', '');
    }

    private static Integer countSuccesses(List<Database.SaveResult> results) {
        Integer count = 0;
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                count++;
            }
        }
        return count;
    }

    private static Integer countDeleteSuccesses(List<Database.DeleteResult> results) {
        Integer count = 0;
        for (Database.DeleteResult dr : results) {
            if (dr.isSuccess()) {
                count++;
            }
        }
        return count;
    }
}
