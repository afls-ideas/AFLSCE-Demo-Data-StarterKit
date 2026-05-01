import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getStatus from '@salesforce/apex/DemoVisitController.getStatus';
import getTerritories from '@salesforce/apex/DemoVisitController.getTerritories';
import createVisits from '@salesforce/apex/DemoVisitController.createVisits';
import deleteVisitBatch from '@salesforce/apex/DemoVisitController.deleteVisitBatch';

export default class VisitSetup extends LightningElement {
    statusData;
    statusError;
    isLoading = false;
    resultMessage;
    isSuccess = false;
    wiredStatusResult;
    activityLog = [];
    territoryOptions = [];
    selectedTerritoryId;

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

    @wire(getTerritories)
    wiredTerritories({ data, error }) {
        if (data) {
            this.territoryOptions = data;
        } else if (error) {
            this.territoryOptions = [];
        }
    }

    get hasTerritorySelected() {
        return !!this.selectedTerritoryId;
    }

    get resultClass() {
        return this.isSuccess
            ? 'slds-box slds-theme_success slds-p-around_small slds-m-bottom_small'
            : 'slds-box slds-theme_error slds-p-around_small slds-m-bottom_small';
    }

    get hasActivityLog() {
        return this.activityLog.length > 0;
    }

    handleTerritoryChange(event) {
        this.selectedTerritoryId = event.detail.value;
    }

    parseDetails(detailsList) {
        const entries = [];
        if (!detailsList || !Array.isArray(detailsList)) return entries;
        for (const item of detailsList) {
            if (typeof item !== 'string') continue;
            if (item.startsWith('HEADER:')) {
                entries.push({ id: entries.length, message: item.substring(7), isHeader: true });
            } else if (item.startsWith('SUCCESS:')) {
                entries.push({ id: entries.length, message: item.substring(8), isSuccess: true });
            } else if (item.startsWith('ERROR:')) {
                entries.push({ id: entries.length, message: item.substring(6), isError: true });
            } else if (item.startsWith('WARNING:')) {
                entries.push({ id: entries.length, message: item.substring(8), isWarning: true });
            } else {
                entries.push({ id: entries.length, message: item, isDetail: true });
            }
        }
        return entries;
    }

    async handleRefreshStatus() {
        await refreshApex(this.wiredStatusResult);
    }

    async handleCreate() {
        if (!this.selectedTerritoryId) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error', message: 'Please select a territory first.', variant: 'error'
            }));
            return;
        }
        this.isLoading = true;
        this.resultMessage = undefined;
        this.activityLog = [];
        try {
            const raw = await createVisits({ territoryId: this.selectedTerritoryId });
            let result;
            try {
                result = typeof raw === 'string' ? JSON.parse(raw) : raw;
            } catch (parseErr) {
                this.isSuccess = true;
                this.resultMessage = raw;
                return;
            }

            this.activityLog = this.parseDetails(result.details);
            if (result.errors && result.errors.length > 0) {
                for (const err of result.errors) {
                    this.activityLog = [
                        ...this.activityLog,
                        { id: this.activityLog.length, message: err, isError: true }
                    ];
                }
            }
            this.isSuccess = !result.errors || result.errors.length === 0;
            this.resultMessage = result.summary || '';
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

    async handleDelete() {
        if (!window.confirm('Are you sure you want to delete? This cannot be undone.')) return;
        this.isLoading = true;
        this.resultMessage = undefined;
        this.activityLog = [];
        let batchNum = 0;
        try {
            let remaining = 1;
            let prevRemaining = -1;
            while (remaining > 0) {
                batchNum++;
                this.activityLog = [...this.activityLog,
                    { id: this.activityLog.length, message: 'Deleting batch ' + batchNum + '...', isHeader: true }
                ];
                const result = await deleteVisitBatch();
                remaining = result.remaining;
                const hasError = result.message && result.message.includes('|');
                this.activityLog = [...this.activityLog,
                    { id: this.activityLog.length, message: result.message, isSuccess: !hasError, isError: hasError }
                ];
                if (remaining === prevRemaining) {
                    this.activityLog = [...this.activityLog,
                        { id: this.activityLog.length, message: 'Stopping — ' + remaining + ' visits could not be deleted. Check errors above.', isError: true }
                    ];
                    break;
                }
                prevRemaining = remaining;
            }
            this.isSuccess = remaining === 0;
            this.resultMessage = remaining === 0
                ? 'All demo visits deleted in ' + batchNum + ' batch(es).'
                : 'Deleted what we could. ' + remaining + ' visits remain (see errors above).';
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
