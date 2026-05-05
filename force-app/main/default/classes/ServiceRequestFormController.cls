/**
 * Created by sinan on 30.04.2026.
 * controller for serviceRequestForm LWC
 */

public with sharing class ServiceRequestFormController {
    public static String SRF_ERROR_MSG = 'Customer email cannot be empty';

    @AuraEnabled(Cacheable = true)
    public static List<Map<String, String>> getPriorityValues() {
        List<Map<String, String>> options = new List<Map<String, String>>();

        // get priority values
        Schema.DescribeFieldResult fieldResult = Service_Request__c.Priority__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        // return values as a map for the LWC to parse
        for (Schema.PicklistEntry pickListVal : ple) {
            options.add(new Map<String, String>{
                    'label' => pickListVal.getLabel(),
                    'value' => pickListVal.getValue()
            });
        }
        return options;
    }

    @AuraEnabled(Cacheable = true)
    public static List<Service_Request__c> getMostRecentServiceRequests() {
        return [
                SELECT Id, Name, Customer_Email__c, Status__c, Priority__c
                FROM Service_Request__c
                ORDER BY CreatedDate DESC
                LIMIT 5
        ];
    }

    @AuraEnabled
    public static Id createServiceRequest(String customerEmail, String description, String priority) {
        System.debug('ServiceRequestHandler.createServiceRequest start');
        try {
            if (String.isBlank(customerEmail)) { // email is required
                throw new ServiceRequestHandler.SRException(SRF_ERROR_MSG);
            }

            Service_Request__c sr = new Service_Request__c(
                    Customer_Email__c = customerEmail,
                    Description__c = description,
                    Priority__c = priority
            ); // create service request

            insert sr;

            System.debug('ServiceRequestHandler.createServiceRequest end');
            return sr.Id;
        } catch (Exception ex) {
            String errorMsg = 'Error occurred: ' + ex.getMessage() + ' (' + ex.getStackTraceString() + ')';
            System.debug(errorMsg);
            throw new AuraHandledException(errorMsg);
        }
    }
}