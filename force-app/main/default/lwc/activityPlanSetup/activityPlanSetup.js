import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getStatus from '@salesforce/apex/DemoActivityPlanController.getStatus';
import createActivityPlans from '@salesforce/apex/DemoActivityPlanController.createActivityPlans';
import deleteActivityPlans from '@salesforce/apex/DemoActivityPlanController.deleteActivityPlans';
import getBatchProgress from '@salesforce/apex/DemoActivityPlanController.getBatchProgress';

export default class ActivityPlanSetup extends LightningElement {
    statusData;
    statusError;
    isLoading = false;
    resultMessage;
    isSuccess = false;
    wiredStatusResult;
    activityLog = [];
    _pollTimer;
    batchProgress;

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

    get hasActivityLog() {
        return this.activityLog.length > 0;
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

    disconnectedCallback() {
        this._stopPolling();
    }

    _stopPolling() {
        if (this._pollTimer) {
            clearInterval(this._pollTimer);
            this._pollTimer = undefined;
        }
    }

    _startPolling() {
        this._stopPolling();
        this.batchProgress = 'Batch queued — waiting for first update...';
        this._pollTimer = setInterval(() => this._pollBatch(), 8000);
    }

    async _pollBatch() {
        try {
            const raw = await getBatchProgress();
            if (raw === 'DONE') {
                this._stopPolling();
                this.batchProgress = undefined;
                this.isLoading = false;
                this.isSuccess = true;
                this.resultMessage = 'Batch complete — all action plans created.';
                this.activityLog = [
                    ...this.activityLog,
                    { id: this.activityLog.length, message: 'Batch finished', isSuccess: true }
                ];
                await refreshApex(this.wiredStatusResult);
                return;
            }
            const parts = raw.split('|');
            const status = parts[0];
            const processed = parts[1];
            const total = parts[2];
            const apCount = parts[3];
            const taskCount = parts[4];
            this.batchProgress = `${status}: ${processed}/${total} batches — ${apCount} action plans, ${taskCount} assessment tasks created`;
            await refreshApex(this.wiredStatusResult);
        } catch (err) {
            // keep polling
        }
    }

    async handleCreate() {
        this.isLoading = true;
        this.resultMessage = undefined;
        this.activityLog = [];
        this.batchProgress = undefined;
        try {
            const raw = await createActivityPlans();
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

            if (this.isSuccess) {
                this._startPolling();
            } else {
                this.isLoading = false;
            }
        } catch (error) {
            this.isSuccess = false;
            this.isLoading = false;
            this.resultMessage = error.body ? error.body.message : 'An error occurred.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.resultMessage,
                    variant: 'error'
                })
            );
        }
    }

    async handleDelete() {
        this.isLoading = true;
        this.resultMessage = undefined;
        this.activityLog = [];
        try {
            const result = await deleteActivityPlans();
            this.isSuccess = true;
            this.resultMessage = result;
            this.activityLog = [
                { id: 0, message: 'Delete Complete', isHeader: true },
                { id: 1, message: result, isSuccess: true }
            ];
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Activity plan records deleted.',
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
}
