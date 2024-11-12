@RestResource(UrlMapping='/lost')
global with sharing class AssetService {

    /* @param String: assetIdentifier */
    @HttpPost
    global static String reportLostDevice(String assetId) {
        String API_MSG;

        /* Invalid Asset Identifier: Test with scenarios where the assetIdentifier is either missing or does not exist in the system.
            The API should handle these cases and return No device found. in the response. */
        Asset[] asset;
        try {
            asset = [SELECT Id, Status, ContactId FROM Asset WHERE Asset_Identifier__c = :assetId LIMIT 1];

            if (asset.isEmpty()) {
                throw new AssetException('No asset records found');
            }
        } catch (AssetException aE) {
            return API_MSG = 'No device found.';
        }

        /* No Coverage: If a device is not insured, the API should update the status to 'Lost' and return No coverage. Asset status adjusted to Lost. */
        Insurance__c[] insurance;
        try {
            insurance = [SELECT Id, Coverage__c, Active__c FROM Insurance__c WHERE Asset__c = :asset[0].Id LIMIT 1];

            if (insurance.isEmpty() || insurance[0].Coverage__c != 'Comprehensive') {
                throw new AssetException('No insurance coverage for device');
            }
        } catch (AssetException aE) {
            asset[0].Status = 'Lost';
            update asset[0];
            return API_MSG = 'No coverage. Asset status adjusted to Lost.';
        }

        /* Claim Already Filed: If there's already a claim of type Loss, the method should return the message [Claim number] already filed. */
        Claim__c[] claim;
        try {
            claim = [SELECT Id, Name, Type__c, Status__c FROM Claim__c WHERE Asset__c = :asset[0].Id LIMIT 1];


            if (!claim.isEmpty() && claim[0].Type__c == 'Loss') {
                throw new AssetException('Loss claim found!');
            }
        } catch (AssetException aE) {
            return API_MSG = claim[0].Name + ' already filed.';
        }

        // Claim Number: Test with an asset record which has an active comprehensive insurance coverage, and returns the claim number (API Name Claim__c.Name).
        try {
            if (!asset.isEmpty()) {

                // Update asset to 'Lost' if not already set to 'Lost'
                if (asset[0].Status != 'Lost') {
                    asset[0].Status = 'Lost';
                    update asset[0];
                }

                // Create the Claim__c record
                if (insurance[0].Coverage__c == 'Comprehensive' && insurance[0].Active__c == true) {
                    Claim__c c = new Claim__c(
                            Insurance__c = insurance[0].Id,
                            Asset__c = asset[0].Id,
                            Type__c = 'Loss',
                            Contact__c = asset[0].ContactId
                    );
                    insert c;
                    return API_MSG = [SELECT Name FROM Claim__c WHERE Id = :c.Id].Name;
                }
            }
        } catch (AssetException aE) {
            throw new AssetException('An error occurred ' + aE.getMessage());
        }

        return API_MSG;
    }

    // Custom exception class
    private class AssetException extends Exception {}
}