/**
 * Created by sinan on 30.04.2026.
 */

import {LightningElement, wire, api} from 'lwc';
import {NavigationMixin} from 'lightning/navigation';
import createServiceRequest from '@salesforce/apex/ServiceRequestFormController.createServiceRequest';
import getPriorityValues from '@salesforce/apex/ServiceRequestFormController.getPriorityValues';
import getMostRecentServiceRequests from '@salesforce/apex/ServiceRequestFormController.getMostRecentServiceRequests';

export default class ServiceRequestForm extends LightningElement {
    @api flexipageRegionWidth;
    disableForm;
    customerEmail;
    description;
    priority = 'Medium';
    priorityOptions;
    serviceRequestId;
    success;
    error;
    inProgress;
    successMsg;
    errorMsg;
    inProgressMsg;
    recentRequests;

    activeSections = [];

    @wire(getPriorityValues)
    wiredPicklist({ error, data }) {
        if (data) {
            this.priorityOptions = data;
        } else if (error) {
            console.error('Error fetching picklist values', error);
        }
    }

    @wire(getMostRecentServiceRequests)
    wiredRecentRequests({ error, data }) {
        if (data) {
            this.recentRequests = data;
        } else if (error) {
            console.error('Error fetching recent service requests', error);
        }
    }

    handleOnChangeEmail(event) {
        this.customerEmail = event.detail.value;
    }

    handleOnChangeDescription(event) {
        this.description = event.detail.value;
    }

    handleOnChangePriority(event) {
        this.priority = event.detail.value;
    }

    handleClick(event) {
        this.disableForm = true;
        this.inProgress = true;
        this.error = false;
        this.success = false;
        this.inProgressMsg = 'Record is being created, please wait';
        if (this.customerEmail === undefined || this.customerEmail === '') {
            this.errorMsg = 'Please enter a valid email address';
            this.error = true;
            this.inProgress = false;
            this.success = false;
            this.disableForm = false;
            return;
        }
        createServiceRequest({
            customerEmail: this.customerEmail,
            description: this.description,
            priority: this.priority
        })
            .then((result) => {
                console.log('Success');
                this.inProgress = false;
                this.success = true;
                this.error = undefined;
                this.serviceRequestId = result;
                this.successMsg = 'Service request created successfully: <a href="/' + this.serviceRequestId + '" target="_blank">' + this.serviceRequestId + '</a>';
                this.disableForm = false;
            })
            .catch((error) => {
                console.log('Error occurred in processing: ' + JSON.stringify(error));
                this.success = false;
                this.inProgress = false;
                this.errorMsg = 'Error occurred in processing: ' + error.body.message;
                this.error = error;
                this.disableForm = false;
            })
    }
}