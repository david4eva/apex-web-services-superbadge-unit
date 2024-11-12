@IsTest
private class CredentialVerificationServiceTest {

    @TestSetup
    static void createRecords() {
        // Create contact record
        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                Email = 'test3434@example.com'
        );
        insert contact;

        // Create certification record
        Certification__c cert = new Certification__c(
                isActive__c = true,
                Name = 'Test Cert'
        );
        insert cert;

        // Create contact certification record
        Contact_Certification__c conCert = new Contact_Certification__c(
                Contact__c = contact.Id,
                Certification__c = cert.Id,
                Issue_Date__c = Date.today().addDays(-20),
                isActive__c = true
        );
        insert conCert;
    }

    @IsTest
    static void testVerifyCredential() {
        // 20 days ago
        Date twentyDaysAgo = Date.today().addDays(-20);

        Contact con = [SELECT LastName FROM Contact WHERE LastName = 'Contact' LIMIT 1];
        Certification__c cert = [SELECT Name FROM Certification__c WHERE Name = 'Test Cert' LIMIT 1];
        Contact_Certification__c conCert = [
                SELECT isActive__c, Certification__r.Name
                FROM Contact_Certification__c
                WHERE Issue_Date__c = :twentyDaysAgo
        ];

        Test.startTest();
        CredentialVerificationService.verifyCredential(con.LastName, conCert.Certification__r.Name);
        Test.stopTest();
    }

    @IsTest
    static void testVerifyContactCertLinked() {
        // 20 days ago
        Date twentyDaysAgo = Date.today().addDays(-20);

        Contact_Certification__c[] conCert = [
                SELECT isActive__c, Certification__r.Name, Contact__r.LastName, Name
                FROM Contact_Certification__c
                WHERE Issue_Date__c = :twentyDaysAgo
                LIMIT 1
        ];

        Contact_Certification__c conCertification = conCert[0];
        Test.startTest();
        CredentialVerificationService.verifyCredential(conCertification.Contact__r.LastName, conCertification.Name);
        Test.stopTest();


    }

    @IsTest
    static void testContactCertNeedsRenewal() {
        // 20 days ago
        Date twentyDaysAgo = Date.today().addDays(-20);

        Contact_Certification__c[] conCert = [
                SELECT isActive__c, Certification__r.Name, Contact__r.LastName, Name
                FROM Contact_Certification__c
                WHERE Issue_Date__c =: twentyDaysAgo
                LIMIT 1
        ];

        // Update contact certificate to inactive state
        Contact_Certification__c conCertification = conCert[0];
        conCertification.isActive__c = false;
        update conCertification;

        Test.startTest();
        CredentialVerificationService.verifyCredential(conCertification.Contact__r.LastName, conCertification.Name);
        Test.stopTest();
    }
}