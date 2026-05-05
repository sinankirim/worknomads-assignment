/**
 * Created by sinan on 3.05.2026.
 */

@IsTest
private class ServiceRequestResolverInvocableTest {
    public static String RESOLUTION_MSG = 'Request resolved';

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
                SELECT Id, Name
                FROM Service_Request__c
                LIMIT 1
        ];

        ServiceRequestResolverInvocable.SRRRequest srr = new ServiceRequestResolverInvocable.SRRRequest();
        srr.serviceRequestNumber = request2.Name;
        srr.resolutionNotes = RESOLUTION_MSG;

        Test.startTest();
        ServiceRequestResolverInvocable.resolveServiceRequests(new List<ServiceRequestResolverInvocable.SRRRequest>{
                srr
        });
        Test.stopTest();

        Service_Request__c request3 = [
                SELECT Id, Customer_Email__c, Description__c, Status__c, Priority__c, Resolution_Notes__c
                FROM Service_Request__c
                LIMIT 1
        ];

        Assert.areEqual(request3.Status__c, 'Resolved');
        Assert.areEqual(request3.Resolution_Notes__c, RESOLUTION_MSG);
    }
}