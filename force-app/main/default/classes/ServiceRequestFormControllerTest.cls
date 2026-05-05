/**
 * Created by sinan on 1.05.2026.
 */

@IsTest
private class ServiceRequestFormControllerTest {
    @IsTest
    static void testBehavior() {
        Test.startTest();
        List<Map<String, String>> picklistValues = ServiceRequestFormController.getPriorityValues();
        Test.stopTest();

        Assert.isFalse(picklistValues.isEmpty());
    }

    @IsTest
    static void testBehavior2() {
        List<Service_Request__c> initServiceRequests = new List<Service_Request__c>();
        for (Integer i = 0; i < 10; i++) {
            Service_Request__c sr = new Service_Request__c(
                    Customer_Email__c = 'test' + String.valueOf(i) + '@test.com',
                    Priority__c = 'Low',
                    Description__c = 'test' + String.valueOf(i)
            );

            initServiceRequests.add(sr);
        }

        insert initServiceRequests;

        /*
         * we change their creation dates so we have more control over the resulting list and our assertions are easier
         * to make. First record will have been created today, second yesterday, etc.
         * Therefore first element will be in the list because it's the most recent record created.
         * Last element won't be because it's the earliest one
         */
        for (Integer i = 0; i < 10; i++) {
            Test.setCreatedDate(initServiceRequests[i].Id, System.now().addDays(i * (-1)));
        }

        Test.startTest();
        List<Service_Request__c> serviceRequests = ServiceRequestFormController.getMostRecentServiceRequests();
        Test.stopTest();

        // save the id of each record to check records in Assert statements using their ids
        Set<Id> serviceRequestIds = new Set<Id>();
        for (Service_Request__c sr : serviceRequests) {
            serviceRequestIds.add(sr.Id);
        }

        Assert.areEqual(serviceRequests.size(), 5);
        Assert.isTrue(serviceRequestIds.contains(initServiceRequests[0].Id));
        Assert.isFalse(serviceRequestIds.contains(initServiceRequests[9].Id));
    }

    @IsTest
    static void testBehavior3() {
        Test.startTest();
        Id srId = ServiceRequestFormController.createServiceRequest('test@test.com', 'test', 'Low');
        Test.stopTest();

        Assert.isTrue(String.isNotBlank(srId));
    }

    @IsTest
    static void testBehavior4() {
        Id srId;
        Test.startTest();
        try {
            srId = ServiceRequestFormController.createServiceRequest('', 'test', 'Low');
        } catch (Exception ex) { }
        Test.stopTest();

        Assert.isTrue(String.isBlank(srId));
        Assert.areEqual([SELECT COUNT() FROM Service_Request__c], 0);
    }
}