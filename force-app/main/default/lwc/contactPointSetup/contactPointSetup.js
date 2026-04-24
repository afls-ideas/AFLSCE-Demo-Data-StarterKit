import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getStatus from '@salesforce/apex/DemoContactPointController.getStatus';
import createAddressBatch from '@salesforce/apex/DemoContactPointController.createAddressBatch';
import createEmailBatch from '@salesforce/apex/DemoContactPointController.createEmailBatch';
import createPhoneBatch from '@salesforce/apex/DemoContactPointController.createPhoneBatch';
import createSocialBatch from '@salesforce/apex/DemoContactPointController.createSocialBatch';
import createLicenseBatch from '@salesforce/apex/DemoContactPointController.createLicenseBatch';
import deleteContactPointBatch from '@salesforce/apex/DemoContactPointController.deleteContactPointBatch';

export default class ContactPointSetup extends LightningElement {
    statusData;
    statusError;
    isLoading = false;
    resultMessage;
    isSuccess = false;
    wiredStatusResult;
    progressMessage;

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

    async runBatchedCreate(apexFn, label) {
        let offset = 0;
        let totalCreated = 0;
        let totalAttempted = 0;
        const allErrors = [];

        // eslint-disable-next-line no-constant-condition
        while (true) {
            this.progressMessage = `Creating ${label} (batch at offset ${offset})...`;
            const raw = await apexFn({ batchOffset: offset });
            const result = JSON.parse(raw);
            totalCreated += result.created;
            totalAttempted += result.attempted;
            if (result.errors) {
                allErrors.push(...result.errors);
            }
            if (!result.hasMore) break;
            offset += 15;
        }

        let summary = `${label}: ${totalCreated}/${totalAttempted}`;
        if (allErrors.length > 0) {
            summary += ` (${allErrors.slice(0, 3).join('; ')})`;
        }
        return summary;
    }

    async handleCreate() {
        this.isLoading = true;
        this.resultMessage = undefined;
        this.progressMessage = undefined;

        const steps = [
            { fn: createAddressBatch, label: 'Addresses' },
            { fn: createEmailBatch, label: 'Emails' },
            { fn: createPhoneBatch, label: 'Phones' },
            { fn: createSocialBatch, label: 'Socials' },
            { fn: createLicenseBatch, label: 'Business Licenses' }
        ];

        const results = [];
        let hasError = false;

        for (const step of steps) {
            try {
                const summary = await this.runBatchedCreate(step.fn, step.label);
                results.push(summary);
            } catch (error) {
                const msg = error.body ? error.body.message : `Error creating ${step.label}`;
                results.push(`${step.label}: FAILED - ${msg}`);
                hasError = true;
            }
        }

        this.progressMessage = undefined;
        this.isSuccess = !hasError;
        this.resultMessage = results.join('; ');
        this.dispatchEvent(
            new ShowToastEvent({
                title: hasError ? 'Completed with errors' : 'Success',
                message: hasError ? 'Some contact points failed.' : 'All contact points created.',
                variant: hasError ? 'warning' : 'success'
            })
        );
        this.isLoading = false;
        await refreshApex(this.wiredStatusResult);
    }

    async handleDelete() {
        this.isLoading = true;
        this.resultMessage = undefined;
        this.progressMessage = undefined;

        const objectTypes = [
            'ContactPointAddress',
            'ContactPointEmail',
            'ContactPointPhone',
            'ContactPointSocial',
            'BusinessLicense'
        ];

        let totalDeleted = 0;
        let hasError = false;
        const results = [];

        for (const objType of objectTypes) {
            this.progressMessage = `Deleting ${objType}...`;
            try {
                const count = await deleteContactPointBatch({ objectType: objType });
                const num = parseInt(count, 10);
                totalDeleted += num;
                if (num > 0) results.push(`${objType}: ${num}`);
            } catch (error) {
                hasError = true;
                results.push(`${objType}: FAILED`);
            }
        }

        this.progressMessage = undefined;
        this.isSuccess = !hasError;
        this.resultMessage = `Deleted ${totalDeleted} records.` +
            (results.length > 0 ? ' (' + results.join(', ') + ')' : '');
        this.dispatchEvent(
            new ShowToastEvent({
                title: hasError ? 'Completed with errors' : 'Success',
                message: hasError ? 'Some deletes failed.' : `Deleted ${totalDeleted} records.`,
                variant: hasError ? 'warning' : 'success'
            })
        );
        this.isLoading = false;
        await refreshApex(this.wiredStatusResult);
    }
}
