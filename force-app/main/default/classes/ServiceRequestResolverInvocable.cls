/**
 * Created by sinan on 3.05.2026.
 */

public with sharing class ServiceRequestResolverInvocable {
    public class SRRRequest {
        @InvocableVariable(
                Required = true
                Label = 'Service Request Number')
        public String serviceRequestNumber;

        @InvocableVariable(
                Required = true
                Label = 'Resolution Notes')
        public String resolutionNotes;
    }

    public class SRRResponse {
        @InvocableVariable(Label = 'Is Successful')
        public Boolean isSuccessful;
    }

    @InvocableMethod(
            Label = 'Resolve Service Request'
            Description = 'Marks a Service Request as Resolved and stores the provided resolution notes'
            Category = 'Service'
    ) public static List<SRRResponse> resolveServiceRequests(List<SRRRequest> requests) {
        // flow or agent
        System.debug('ServiceRequestResolverInvocable.resolveServiceRequests start');
        Map<Id, String> requestMap = new Map<Id, String>();
        Map<String, Id> srIdsByName = new Map<String, Id>();

        for (SRRRequest srr : requests) {
            srIdsByName.put(srr.serviceRequestNumber, null); // put all numbers on a map
        }

        List<Service_Request__c> serviceRequests = [
                SELECT Id, Name, Description__c, Status__c, Priority__c, Resolution_Notes__c
                FROM Service_Request__c
                WHERE Name IN :srIdsByName.keySet()
        ]; // get the ids

        for (Service_Request__c sr : serviceRequests) {
            srIdsByName.put(sr.Name, sr.Id); // map the ids to related numbers
        }

        List<SRRResponse> response = new List<ServiceRequestResolverInvocable.SRRResponse>();
        for (SRRRequest srr : requests) {
            Id serviceRequestId = srIdsByName.get(srr.serviceRequestNumber); // get the corresponding id
            requestMap.put(serviceRequestId, srr.resolutionNotes);
        }

        ServiceRequestHandler.resolveServiceRequests(requestMap); // call the resolver service

        for (SRRRequest srr : requests) {
            SRRResponse res = new SRRResponse();
            res.isSuccessful = true;
            response.add(res);
        }

        return response;
    }
}