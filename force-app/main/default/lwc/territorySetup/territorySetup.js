import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getStatus from '@salesforce/apex/DemoTerritoryController.getStatus';
import createTerritoryHierarchy from '@salesforce/apex/DemoTerritoryController.createTerritoryHierarchy';
import deleteAllTerritories from '@salesforce/apex/DemoTerritoryController.deleteAllTerritories';

export default class TerritorySetup extends LightningElement {
    statusData;
    statusError;
    isLoading = false;
    resultMessage;
    isSuccess = false;
    wiredStatusResult;

    @wire(getStatus)
    wiredStatus(result) {
        this.wiredStatusResult = result;
        if (result.data) {
            this.statusData = result.data;
            this.statusError = undefined;
        } else if (result.error) {
            this.statusError = result.error.body ? result.error.body.message : 'Unable to retrieve status.';
            this.statusData = undefined;
        }
    }

    get resultClass() {
        return this.isSuccess
            ? 'slds-box slds-theme_success slds-p-around_small slds-m-bottom_small'
            : 'slds-box slds-theme_error slds-p-around_small slds-m-bottom_small';
    }

    async handleCreate() {
        this.isLoading = true;
        this.resultMessage = undefined;
        try {
            const result = await createTerritoryHierarchy();
            this.isSuccess = true;
            this.resultMessage = result;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Territory hierarchy created successfully.',
                    variant: 'success'
                })
            );
        } catch (error) {
            this.isSuccess = false;
            this.resultMessage = error.body ? error.body.message : 'An error occurred while creating territories.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.resultMessage,
                    variant: 'error'
                })
            );
        } finally {
            this.isLoading = false;
            await refreshApex(this.wiredStatusResult);
        }
    }

    async handleDelete() {
        this.isLoading = true;
        this.resultMessage = undefined;
        try {
            const result = await deleteAllTerritories();
            this.isSuccess = true;
            this.resultMessage = result;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'All territories deleted successfully.',
                    variant: 'success'
                })
            );
        } catch (error) {
            this.isSuccess = false;
            this.resultMessage = error.body ? error.body.message : 'An error occurred while deleting territories.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.resultMessage,
                    variant: 'error'
                })
            );
        } finally {
            this.isLoading = false;
            await refreshApex(this.wiredStatusResult);
        }
    }
}
