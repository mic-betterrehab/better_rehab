/**
 * Created by Enrite Solutions on 23/12/2020.
 */

import {LightningElement, api, track, wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { NavigationMixin } from 'lightning/navigation';
import {loadScript} from "lightning/platformResourceLoader";

import sendExtractToXeroAction from '@salesforce/apexContinuation/sendExtractToXeroController.sendExtractToXero';

export default class Sendextracttoxero extends NavigationMixin(LightningElement) {

    @track isLoaded = false;
    @track isProccessing = false;
    @api recordId = false;

    renderedCallback() {
        this.isLoaded = true;
    }


    sendExtractToXero() {
        this.isProccessing = true;
        let promiseArray = [];
        let currentContext = this;
        let extractId = this.recordId;
        promiseArray.push(new Promise(function (resolve, reject) {
            sendExtractToXeroAction({extractId: extractId}
            ).then(result => {
                if (result == undefined || result == null || result == '') {
                    currentContext.showErrorToast('No Response from server', 'Something has gone wrong, Please contact a System Administrator.')
                } else {
                    let resultObj = JSON.parse(result);
                    if (resultObj.isSuccess === true) {
                        currentContext.handleSuccessfulResponce(resultObj);
                    } else {
                        currentContext.handleFailureResponce(resultObj);
                    }
                }
                resolve("Done");
            })
        }));
        var results = Promise.all(promiseArray);
        results.then(data =>
            this.finishAndClose()
        );
    }

    finishAndClose() {
        this.isProccessing = false;
        // Creates the event with the contact ID data.
        const changeEvent = new CustomEvent('close', {});
        // Dispatches the event.
        this.dispatchEvent(changeEvent);
    }

    handleResponce(responceString) {
        let resultObj = JSON.parse(responceString);
        if (resultObj.isSuccess === true) {
            this.handleSuccessfulResponce(resultObj);
        } else {
            this.handleFailureResponce(resultObj);
        }
    }

    handleSuccessfulResponce(resultObj) {
        this.showSuccessNotification('Extract is being processed and being sent to Xero, An email will be sent when complete.');
    }

    handleFailureResponce(resultObj) {
        this.showErrorToast(resultObj.errorMessage, 'Something has gone wrong, Please contact a System Administrator.')
        console.log(resultObj.errorMessage);
    }

    showErrorToast(errorMsg, errorTitle) {
        const event = new ShowToastEvent({
            title: errorTitle,
            variant: 'error',
            message: errorMsg,
            mode: 'Sticky',
        });
        this.dispatchEvent(event);
    }

    showSuccessNotification(msg) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: msg,
            variant: 'success',
        }));
    }
}