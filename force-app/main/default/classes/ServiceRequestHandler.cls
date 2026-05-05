/**
 * Created by sinan on 30.04.2026.
 */

public with sharing class ServiceRequestHandler {
    public class SRException extends Exception { }

    public static void resolveServiceRequests(Map<Id, String> requestMap) {
        // main method
        System.debug('ServiceRequestHandler.resolveServiceRequests start');
        List<Service_Request__c> serviceRequests = new List<Service_Request__c>();
        for (Id srId : requestMap.keySet()) {
            Service_Request__c sr = new Service_Request__c(
                    Id = srId,
                    Resolution_Notes__c = requestMap.get(srId),
                    Status__c = 'Resolved'
            );

            serviceRequests.add(sr);
        }

        update serviceRequests;
        System.debug('ServiceRequestHandler.resolveServiceRequests end');
    }

    public static void resolveServiceRequest(Service_Request__c serviceRequest, String resolutionNotes) {
        // single record
        resolveServiceRequests(new Map<Id, String>{
                serviceRequest.Id => resolutionNotes
        });
    }

    public static void resolveServiceRequest(Id serviceRequestId, String resolutionNotes) {
        // single record
        resolveServiceRequests(new Map<Id, String>{
                serviceRequestId => resolutionNotes
        });
    }

    public static void resolveServiceRequests(List<Service_Request__c> serviceRequests, List<String> resolutionNotes) {
        // multiple records and notes given separately
        if (serviceRequests.size() != resolutionNotes.size()) {
            throw new SRException('The numbers of service requests and resolution notes do not match');
        } else {
            Map<Id, String> requestMap = new Map<Id, String>();
            for (Integer i = 0; i < serviceRequests.size(); i++) {
                requestMap.put(serviceRequests[i].Id, resolutionNotes[i]);
            }

            resolveServiceRequests(requestMap);
        }
    }
}