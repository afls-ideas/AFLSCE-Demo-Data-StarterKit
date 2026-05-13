import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getStatus from '@salesforce/apex/DemoMedicalInsightController.getStatus';
import getTerritories from '@salesforce/apex/DemoMedicalInsightController.getTerritories';
import createInsightsForTerritory from '@salesforce/apex/DemoMedicalInsightController.createInsightsForTerritory';
import deleteMedicalInsights from '@salesforce/apex/DemoMedicalInsightController.deleteMedicalInsights';

export default class MedicalInsightSetup extends LightningElement {
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

    handleTerritoryChange(event) {
        this.selectedTerritoryId = event.detail.value;
    }

    get resultClass() {
        return this.isSuccess
            ? 'slds-box slds-theme_success slds-p-around_small slds-m-bottom_small'
            : 'slds-box slds-theme_error slds-p-around_small slds-m-bottom_small';
    }

    get hasActivityLog() {
        return this.activityLog.length > 0;
    }

    addLogEntry(message, type) {
        this.activityLog = [
            ...this.activityLog,
            { id: this.activityLog.length, message, ['is' + type]: true }
        ];
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
            const raw = await createInsightsForTerritory({ territoryId: this.selectedTerritoryId });
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
        try {
            const result = await deleteMedicalInsights();
            this.isSuccess = true;
            this.resultMessage = result;
            this.activityLog = [
                { id: 0, message: 'Delete Complete', isHeader: true },
                { id: 1, message: result, isSuccess: true }
            ];
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success', message: result, variant: 'success'
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
