import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getStatus from '@salesforce/apex/DemoAccountProviderController.getStatus';
import getAccountRecordTypes from '@salesforce/apex/DemoAccountProviderController.getAccountRecordTypes';
import getCountryCodes from '@salesforce/apex/DemoAccountProviderController.getCountryCodes';
import getDoctorCount from '@salesforce/apex/DemoAccountProviderController.getDoctorCount';
import createOrgsForCountry from '@salesforce/apex/DemoAccountProviderController.createOrgsForCountry';
import createDoctorsForCountry from '@salesforce/apex/DemoAccountProviderController.createDoctorsForCountry';
import createProvidersForCountry from '@salesforce/apex/DemoAccountProviderController.createProvidersForCountry';
import createAffiliationsForCountry from '@salesforce/apex/DemoAccountProviderController.createAffiliationsForCountry';
import deleteAccountsAndProviders from '@salesforce/apex/DemoAccountProviderController.deleteAccountsAndProviders';
import assignTerritories from '@salesforce/apex/DemoAccountProviderController.assignTerritories';
import getTerritorySummary from '@salesforce/apex/DemoTerritoryController.getTerritorySummary';

const PROVIDER_BATCH_SIZE = 30;
const AFFILIATION_BATCH_SIZE = 20;

let logCounter = 0;

export default class AccountProviderSetup extends LightningElement {
    statusData;
    statusError;
    isLoading = false;
    resultMessage;
    isSuccess = false;
    wiredStatusResult;

    recordTypes = [];
    hcoRecordTypeId;
    hcpRecordTypeId;
    wiredSummaryResult;
    summaryRows;
    activityLog = [];

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

    @wire(getAccountRecordTypes)
    wiredRecordTypes({ data, error }) {
        if (data) {
            this.recordTypes = data.map(rt => ({
                label: rt.name + ' (' + rt.developerName + ')' + (rt.isPersonType === 'true' ? ' — Person Account' : ''),
                value: rt.id,
                isPersonType: rt.isPersonType === 'true',
                developerName: rt.developerName
            }));
            this.autoSelectDefaults();
        } else if (error) {
            this.recordTypes = [];
        }
    }

    @wire(getTerritorySummary)
    wiredSummary(result) {
        this.wiredSummaryResult = result;
        if (result.data) {
            this.summaryRows = result.data;
        } else if (result.error) {
            this.summaryRows = undefined;
        }
    }

    get hasSummaryRows() {
        return this.summaryRows && this.summaryRows.length > 0;
    }

    get summaryTotals() {
        if (!this.summaryRows) return null;
        const t = { hcp: 0, hco: 0, pati: 0, pats: 0, affl: 0 };
        for (const r of this.summaryRows) {
            t.hcp += r.hcpCount;
            t.hco += r.hcoCount;
            t.pati += r.patiCount;
            t.pats += r.patsCount;
            t.affl += r.affiliationCount;
        }
        return t;
    }

    get hasActivityLog() {
        return this.activityLog.length > 0;
    }

    autoSelectDefaults() {
        const hcoNames = ['Health_Care_Organization', 'LSDO_Healthcare_Organization', 'HLS_Account_HealthCareFacility'];
        const hcpNames = ['Health_Care_Provider', 'LSDO_Healthcare_Provider'];

        for (const rt of this.recordTypes) {
            if (!this.hcoRecordTypeId && hcoNames.includes(rt.developerName)) {
                this.hcoRecordTypeId = rt.value;
            }
            if (!this.hcpRecordTypeId && hcpNames.includes(rt.developerName)) {
                this.hcpRecordTypeId = rt.value;
            }
        }
    }

    get hcoOptions() {
        return this.recordTypes.filter(rt => !rt.isPersonType);
    }

    get hcpOptions() {
        return this.recordTypes.filter(rt => rt.isPersonType);
    }

    get hasRecordTypes() {
        return this.recordTypes.length > 0;
    }

    get isCreateDisabled() {
        return this.isLoading || !this.hcoRecordTypeId || !this.hcpRecordTypeId;
    }

    get resultClass() {
        return this.isSuccess
            ? 'slds-box slds-theme_success slds-p-around_small slds-m-bottom_small'
            : 'slds-box slds-theme_error slds-p-around_small slds-m-bottom_small';
    }

    handleHcoChange(event) {
        this.hcoRecordTypeId = event.detail.value;
    }

    handleHcpChange(event) {
        this.hcpRecordTypeId = event.detail.value;
    }

    addLog(message, type) {
        logCounter++;
        const cssClass = type === 'header' ? 'slds-text-title_bold slds-m-top_xx-small'
            : type === 'success' ? 'slds-text-color_success slds-m-left_medium'
            : type === 'error' ? 'slds-text-color_error slds-m-left_medium'
            : 'slds-m-left_medium';
        this.activityLog = [...this.activityLog, {
            id: logCounter,
            message,
            cssClass
        }];
    }

    async callApex(fn, params, label) {
        try {
            const result = await fn(params);
            this.addLog(result, 'success');
            return true;
        } catch (err) {
            const msg = err.body ? err.body.message : err.message;
            this.addLog(label + ' failed: ' + msg, 'error');
            return false;
        }
    }

    async handleCreate() {
        this.isLoading = true;
        this.resultMessage = undefined;
        this.activityLog = [];
        try {
            this.addLog('Loading country list...', 'detail');
            const countries = await getCountryCodes();
            this.addLog('Found ' + countries.length + ' countries: ' + countries.join(', '), 'success');

            for (const cc of countries) {
                this.addLog(cc + ' — Creating organization accounts...', 'header');
                await this.callApex(createOrgsForCountry,
                    { hcoRecordTypeId: this.hcoRecordTypeId, countryCode: cc },
                    cc + ' orgs');

                this.addLog(cc + ' — Creating doctor accounts...', 'header');
                await this.callApex(createDoctorsForCountry,
                    { hcpRecordTypeId: this.hcpRecordTypeId, countryCode: cc },
                    cc + ' doctors');

                // Get doctor count to determine batching
                let docCount = 0;
                try {
                    docCount = await getDoctorCount({ countryCode: cc });
                } catch (err) {
                    this.addLog(cc + ' getDoctorCount failed: ' + (err.body ? err.body.message : err.message), 'error');
                }
                const provBatches = Math.max(1, Math.ceil(docCount / PROVIDER_BATCH_SIZE));
                const afflBatches = Math.max(1, Math.ceil(docCount / AFFILIATION_BATCH_SIZE));

                this.addLog(cc + ' — Creating providers, NPIs & specialties (' + docCount + ' doctors, ' + provBatches + ' batch' + (provBatches > 1 ? 'es' : '') + ')...', 'header');
                for (let b = 0; b < provBatches; b++) {
                    await this.callApex(createProvidersForCountry,
                        { countryCode: cc, batchIndex: b + 1 },
                        cc + ' providers batch ' + (b + 1));
                }

                this.addLog(cc + ' — Creating affiliations (' + afflBatches + ' batch' + (afflBatches > 1 ? 'es' : '') + ')...', 'header');
                for (let b = 0; b < afflBatches; b++) {
                    await this.callApex(createAffiliationsForCountry,
                        { countryCode: cc, batchIndex: b + 1 },
                        cc + ' affiliations batch ' + (b + 1));
                }
            }

            this.addLog('All countries complete!', 'header');
            this.isSuccess = true;
            this.resultMessage = 'Accounts and providers created for ' + countries.length + ' countries.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Accounts and providers created successfully.',
                    variant: 'success'
                })
            );
        } catch (error) {
            this.isSuccess = false;
            this.resultMessage = error.body ? error.body.message : 'An error occurred while creating accounts and providers.';
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
            await refreshApex(this.wiredSummaryResult);
        }
    }

    async handleAssignTerritories() {
        this.isLoading = true;
        this.resultMessage = undefined;
        try {
            const result = await assignTerritories();
            this.isSuccess = true;
            this.resultMessage = result;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Territory assignments completed.',
                    variant: 'success'
                })
            );
        } catch (error) {
            this.isSuccess = false;
            this.resultMessage = error.body ? error.body.message : 'An error occurred assigning territories.';
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
            await refreshApex(this.wiredSummaryResult);
        }
    }

    async handleDelete() {
        this.isLoading = true;
        this.resultMessage = undefined;
        try {
            const result = await deleteAccountsAndProviders();
            this.isSuccess = true;
            this.resultMessage = result;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Accounts and providers deleted successfully.',
                    variant: 'success'
                })
            );
        } catch (error) {
            this.isSuccess = false;
            this.resultMessage = error.body ? error.body.message : 'An error occurred while deleting accounts and providers.';
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
            await refreshApex(this.wiredSummaryResult);
        }
    }
}
