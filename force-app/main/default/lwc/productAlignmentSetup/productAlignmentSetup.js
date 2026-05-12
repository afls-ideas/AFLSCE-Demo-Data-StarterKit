import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getStatus from '@salesforce/apex/DemoProductAlignmentController.getStatus';
import createProductsAndAlign from '@salesforce/apex/DemoProductAlignmentController.createProductsAndAlign';
import deleteProductsAndAlignments from '@salesforce/apex/DemoProductAlignmentController.deleteProductsAndAlignments';
import createProductGuidance from '@salesforce/apex/DemoVisitController.createProductGuidance';
import deleteProductGuidance from '@salesforce/apex/DemoVisitController.deleteProductGuidance';

export default class ProductAlignmentSetup extends LightningElement {
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
            const result = await createProductsAndAlign();
            this.isSuccess = true;
            this.resultMessage = result;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Products and alignments created.',
                    variant: 'success'
                })
            );
        } catch (error) {
            this.isSuccess = false;
            this.resultMessage = error.body ? error.body.message : 'An error occurred.';
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
        if (!window.confirm('Are you sure you want to delete? This cannot be undone.')) return;
        this.isLoading = true;
        this.resultMessage = undefined;
        try {
            const result = await deleteProductsAndAlignments();
            this.isSuccess = true;
            this.resultMessage = result;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Products and alignments deleted.',
                    variant: 'success'
                })
            );
        } catch (error) {
            this.isSuccess = false;
            this.resultMessage = error.body ? error.body.message : 'An error occurred.';
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

    async handleCreateGuidance() {
        this.isLoading = true;
        this.resultMessage = undefined;
        try {
            const raw = await createProductGuidance();
            let result;
            try {
                result = typeof raw === 'string' ? JSON.parse(raw) : raw;
            } catch (parseErr) {
                this.isSuccess = true;
                this.resultMessage = raw;
                return;
            }
            this.isSuccess = !result.errors || result.errors.length === 0;
            this.resultMessage = result.summary || '';
            if (result.errors && result.errors.length > 0) {
                this.resultMessage += ' | Errors: ' + result.errors.join('; ');
            }
            this.dispatchEvent(new ShowToastEvent({
                title: this.isSuccess ? 'Success' : 'Warning',
                message: this.resultMessage,
                variant: this.isSuccess ? 'success' : 'warning'
            }));
        } catch (error) {
            this.isSuccess = false;
            this.resultMessage = error.body ? error.body.message : 'An error occurred.';
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error', message: this.resultMessage, variant: 'error'
            }));
        } finally {
            this.isLoading = false;
            await refreshApex(this.wiredStatusResult);
        }
    }

    async handleDeleteGuidance() {
        if (!window.confirm('Delete all demo product guidance records?')) return;
        this.isLoading = true;
        this.resultMessage = undefined;
        let batchNum = 0;
        try {
            let remaining = 1;
            let prevRemaining = -1;
            while (remaining > 0) {
                batchNum++;
                const result = await deleteProductGuidance();
                remaining = result.remaining;
                if (remaining === prevRemaining) break;
                prevRemaining = remaining;
            }
            this.isSuccess = remaining === 0;
            this.resultMessage = remaining === 0
                ? 'All product guidance deleted in ' + batchNum + ' batch(es).'
                : 'Deleted what we could. ' + remaining + ' records remain.';
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success', message: this.resultMessage, variant: 'success'
            }));
        } catch (error) {
            this.isSuccess = false;
            this.resultMessage = error.body ? error.body.message : 'An error occurred.';
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error', message: this.resultMessage, variant: 'error'
            }));
        } finally {
            this.isLoading = false;
            await refreshApex(this.wiredStatusResult);
        }
    }
}
