/**
 * Created by sinan on 3.05.2026.
 */

@IsTest
private class ServiceRequestGetterInvocableTest {
    @IsTest
    static void testBehavior() {
        Service_Request__c request = new Service_Request__c(
                Customer_Email__c = 'sinan@test.com',
                Description__c = 'test',
                Status__c = 'New',
                Priority__c = 'Low'
        );

        insert request;

        Service_Request__c request2 = [
                SELECT Id, Name, Customer_Email__c, Description__c, Status__c, Priority__c
                FROM Service_Request__c
                WHERE Id =: request.Id
                LIMIT 1
        ];

        ServiceRequestGetterInvocable.SRGetRequest getRequest = new ServiceRequestGetterInvocable.SRGetRequest();
        getRequest.serviceRequestNumber = request2.Name;

        ServiceRequestGetterInvocable.SRGetRequest getRequest2 = new ServiceRequestGetterInvocable.SRGetRequest();
        getRequest2.serviceRequestNumber = request2.Name + 'test';

        Test.startTest();
        List<ServiceRequestGetterInvocable.SRGetResponse> getResponses =
                ServiceRequestGetterInvocable.retrieveServiceRequest(new List<ServiceRequestGetterInvocable.SRGetRequest>{
                getRequest, getRequest2
        });
        Test.stopTest();

        for (ServiceRequestGetterInvocable.SRGetResponse res : getResponses) {
            if (res.serviceRequestName == getRequest.serviceRequestNumber) {
                Assert.isTrue(res.isFound);
            } else {
                Assert.isFalse(res.isFound);
            }
        }
    }

    @IsTest
    static void testBehavior2() {
        ServiceRequestGetterInvocable.SRGetResponse response = new ServiceRequestGetterInvocable.SRGetResponse();
    }
}