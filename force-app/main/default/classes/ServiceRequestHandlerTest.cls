/**
 * Created by sinan on 30.04.2026.
 */

@IsTest
private class ServiceRequestHandlerTest {
    public static String RESOLUTION_MSG = 'Request resolved';

    @TestSetup
    static void setup() {
        Service_Request__c request = new Service_Request__c(
                Customer_Email__c = 'sinan@test.com',
                Description__c = 'test',
                Status__c = 'New',
                Priority__c = 'Low'
        );

        insert request;
    }

    @IsTest
    static void testBehavior() {
        Service_Request__c request = [
                SELECT Id, Customer_Email__c, Description__c, Status__c, Priority__c
                FROM Service_Request__c
                LIMIT 1
        ];

        Test.startTest();
        ServiceRequestHandler.resolveServiceRequests(new Map<Id, String>{
                request.Id => RESOLUTION_MSG
        });
        Test.stopTest();
    }

    @IsTest
    static void testBehavior2() {
        Service_Request__c request = [
                SELECT Id, Customer_Email__c, Description__c, Status__c, Priority__c
                FROM Service_Request__c
                LIMIT 1
        ];

        Test.startTest();
        ServiceRequestHandler.resolveServiceRequest(request, RESOLUTION_MSG);
        Test.stopTest();

        Service_Request__c request2 = [
                SELECT Id, Customer_Email__c, Description__c, Status__c, Priority__c, Resolution_Notes__c
                FROM Service_Request__c
                LIMIT 1
        ];

        Assert.areEqual(request2.Status__c, 'Resolved');
        Assert.areEqual(request2.Resolution_Notes__c, RESOLUTION_MSG);
    }

    @IsTest
    static void testBehavior3() {
        Service_Request__c request = [
                SELECT Id, Customer_Email__c, Description__c, Status__c, Priority__c
                FROM Service_Request__c
                LIMIT 1
        ];

        Test.startTest();
        ServiceRequestHandler.resolveServiceRequest(request.Id, RESOLUTION_MSG);
        Test.stopTest();

        Service_Request__c request2 = [
                SELECT Id, Customer_Email__c, Description__c, Status__c, Priority__c, Resolution_Notes__c
                FROM Service_Request__c
                LIMIT 1
        ];

        Assert.areEqual(request2.Status__c, 'Resolved');
        Assert.areEqual(request2.Resolution_Notes__c, RESOLUTION_MSG);
    }

    @IsTest
    static void testBehavior4() {
        Service_Request__c request = [
                SELECT Id, Customer_Email__c, Description__c, Status__c, Priority__c
                FROM Service_Request__c
                LIMIT 1
        ];

        List<Service_Request__c> serviceRequests2 = new List<Service_Request__c>();

        Service_Request__c newRequest = request.clone(false, true);
        Service_Request__c newRequest2 = request.clone(false, true);

        serviceRequests2.add(newRequest);
        serviceRequests2.add(newRequest2);
        insert serviceRequests2;

        Test.startTest();
        ServiceRequestHandler.resolveServiceRequests(serviceRequests2, new List<String>{RESOLUTION_MSG, RESOLUTION_MSG});
        Test.stopTest();

        List<Service_Request__c> serviceRequests = [
                SELECT Id, Customer_Email__c, Description__c, Status__c, Priority__c, Resolution_Notes__c
                FROM Service_Request__c
                WHERE Id =: newRequest.Id OR Id =: newRequest2.Id
        ];

        for (Service_Request__c sr : serviceRequests) {
            Assert.areEqual(sr.Status__c, 'Resolved');
            Assert.areEqual(sr.Resolution_Notes__c, RESOLUTION_MSG);
        }
    }

    @IsTest
    static void testBehavior5() {
        Service_Request__c request = [
                SELECT Id, Customer_Email__c, Description__c, Status__c, Priority__c
                FROM Service_Request__c
                LIMIT 1
        ];

        List<Service_Request__c> serviceRequests2 = new List<Service_Request__c>();

        Service_Request__c newRequest = request.clone(false, true);
        Service_Request__c newRequest2 = request.clone(false, true);

        serviceRequests2.add(newRequest);
        serviceRequests2.add(newRequest2);
        insert serviceRequests2;

        Test.startTest();
        try {
            ServiceRequestHandler.resolveServiceRequests(serviceRequests2, new List<String>{RESOLUTION_MSG});
        } catch (Exception ex) {
            Assert.areEqual(ex.getMessage(), 'The numbers of service requests and resolution notes do not match');
        }
        Test.stopTest();

        List<Service_Request__c> serviceRequests = [
                SELECT Id, Customer_Email__c, Description__c, Status__c, Priority__c, Resolution_Notes__c
                FROM Service_Request__c
        ];

        for (Service_Request__c sr : serviceRequests) {
            Assert.areNotEqual(sr.Status__c, 'Resolved');
            Assert.areNotEqual(sr.Resolution_Notes__c, RESOLUTION_MSG);
        }
    }
}