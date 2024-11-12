@IsTest
private with sharing class AssetServiceTest {

    /* Invalid Asset Identifier: Test with scenarios where the assetIdentifier is either missing or does not exist in the system.
       The API should handle these cases and return No device found. in the response. */
    @IsTest
    static void testInvalidAssetIdentifier() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/lost/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('INVALID');
        RestContext.request = req;
        RestContext.response = new RestResponse();

        String response = AssetService.reportLostDevice('INVALID');
        Assert.areEqual('No device found.', response);
    }

    @TestSetup static void createRecords() {
        // Create accounts
        Account acct = new Account(
                Name = 'Test Account'
        );
        insert acct;

        // Create contact record
        Contact con = new Contact(
                FirstName = 'Test',
                LastName = 'User',
                Email = 'testd343@example.com',
                AccountId = acct.Id
        );
        insert con;

        // Create asset record with invalid Asset_Identifier__c
        Asset asset = new Asset(
                ContactId = con.Id,
                Name = 'Test Asset',
                AccountId = acct.Id,
                Asset_Identifier__c = 'VALID1'
        );
        insert asset;

        // Create insurance record
        Insurance__c ins = new Insurance__c(
                Active__c = true,
                Asset__c = asset.Id,
                Coverage__c = 'Liability'
        );
        insert ins;

        // Create claim record
        Claim__c c = new Claim__c(
                Contact__c = con.Id,
                Insurance__c = ins.Id,
                Asset__c = asset.Id,
                Type__c = 'Loss'
        );
        insert c;

    }

    /* No Coverage: If a device is not insured, the API should update the status to 'Lost' and return No coverage. Asset status adjusted to Lost. */
    @IsTest
    static void testDeviceNotInsured() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/lost/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('VALID1');
        RestContext.request = req;
        RestContext.response = new RestResponse();

        String response = AssetService.reportLostDevice('VALID1');
        Assert.areEqual('No coverage. Asset status adjusted to Lost.', response);

    }

    @IsTest
    static void testExistingLossClaim() {
        Claim__c claim = [SELECT Id, Type__c, Name FROM Claim__c WHERE Type__c = 'Loss' LIMIT 1];

        Insurance__c insur = [SELECT Id, Coverage__c, Name FROM Insurance__c WHERE Coverage__c = 'Liability' LIMIT 1];
        insur.Coverage__c = 'Comprehensive';
        update insur;

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/lost/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('VALID1');
        RestContext.request = req;
        RestContext.response = new RestResponse();

        String response = AssetService.reportLostDevice('VALID1');
        Assert.areEqual(claim.Name + ' already filed.', response);

    }

    @IsTest
    static void testActiveComprehensiveInsurance() {
        Insurance__c insur = [SELECT Id, Coverage__c, Name FROM Insurance__c WHERE Coverage__c = 'Liability' LIMIT 1];
        insur.Coverage__c = 'Comprehensive';
        insur.Active__c = true;
        update insur;

       //  Delete existing claim record
       delete [SELECT Id, Type__c, Name FROM Claim__c WHERE Type__c = 'Loss' LIMIT 1];

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/lost/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('VALID1');
        RestContext.request = req;
        RestContext.response = new RestResponse();

        String response = AssetService.reportLostDevice('VALID1');

        // Query newly inserted claim record
        Claim__c claim = [SELECT Id, Type__c, Name FROM Claim__c WHERE Type__c = 'Loss' ORDER BY Name DESC LIMIT 1];

        Assert.areEqual(claim.Name, response);

    }

}