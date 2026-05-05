/**
 * Created by sinan on 3.05.2026.
 * invocable used by agent
 */

public with sharing class ServiceRequestGetterInvocable {
    public class SRGetRequest {
        @InvocableVariable(
                Required = true
                Label = 'Service Request Number')
        public String serviceRequestNumber;
    }

    public class SRGetResponse {
        @InvocableVariable(Label = 'Is Found')
        public Boolean isFound;

        @InvocableVariable(Label = 'Service Request Id')
        public Id serviceRequestId;

        @InvocableVariable(Label = 'Service Request Name')
        public String serviceRequestName;

        @InvocableVariable(Label = 'Service Request Description')
        public String description;

        @InvocableVariable(Label = 'Status')
        public String status;

        public SRGetResponse() {
            this.isFound = false;
        }

        public SRGetResponse(String srName) {
            this.isFound = false;
            this.serviceRequestName = srName;
        }

        public SRGetResponse(Service_Request__c sr) {
            this.isFound = true;
            this.serviceRequestId = sr.Id;
            this.serviceRequestName = sr.Name;
            this.description = sr.Description__c;
            this.status = sr.Status__c;
        }
    }

    @InvocableMethod(
            Label = 'Get Service Request'
            Description = 'Retrieves a Service Request by number'
    ) public static List<SRGetResponse> retrieveServiceRequest(List<SRGetRequest> getRequests) {
        System.debug('ServiceRequestGetterInvocable.retrieveServiceRequest start');
        Set<String> srNumbers = new Set<String>();
        List<SRGetResponse> response = new List<SRGetResponse>();
        for (SRGetRequest sgr : getRequests) {
            if (String.isNotBlank(sgr.serviceRequestNumber)) {
                srNumbers.add(sgr.serviceRequestNumber.trim());
            }
        }

        Map<String, Service_Request__c> serviceRequestMap = new Map<String, Service_Request__c>();
        List<Service_Request__c> serviceRequests = [
                SELECT Id, Name, Status__c, Priority__c, Description__c, Customer_Email__c
                FROM Service_Request__c
                WHERE Name IN :srNumbers
        ]; // get all relevant service requests

        for (Service_Request__c sr : serviceRequests) {
            serviceRequestMap.put(sr.Name, sr);
        }

        for (SRGetRequest req : getRequests) {
            String nm = req.serviceRequestNumber; // operate on the given number
            Service_Request__c tempRequest = serviceRequestMap.get(nm);
            if (tempRequest != null) { // match found for given number, add it to the response list
                response.add(new SRGetResponse(tempRequest));
            } else {
                response.add(new SRGetResponse(nm));
            }
        }

        System.debug('Response list: ' + response);
        return response;
    }

}