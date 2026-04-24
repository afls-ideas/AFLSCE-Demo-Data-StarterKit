import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getAvailableScenarios from '@salesforce/apex/DemoScenarioController.getAvailableScenarios';
import applyScenario from '@salesforce/apex/DemoScenarioController.applyScenario';
import removeScenario from '@salesforce/apex/DemoScenarioController.removeScenario';

export default class ScenarioBuilder extends LightningElement {
    scenarios;
    isLoading = false;
    resultMessage;
    isSuccess = false;
    wiredScenariosResult;

    @wire(getAvailableScenarios)
    wiredScenarios(result) {
        this.wiredScenariosResult = result;
        if (result.data) {
            this.scenarios = result.data.map(scenario => ({
                ...scenario,
                cardClass: scenario.isApplied
                    ? 'slds-card slds-card_boundary slds-theme_default scenario-card scenario-applied'
                    : 'slds-card slds-card_boundary slds-theme_default scenario-card',
                applyAriaLabel: `Apply ${scenario.label} scenario`,
                removeAriaLabel: `Remove ${scenario.label} scenario`
            }));
        } else if (result.error) {
            this.scenarios = undefined;
            this.resultMessage = result.error.body ? result.error.body.message : 'Unable to load scenarios.';
            this.isSuccess = false;
        }
    }

    get resultClass() {
        return this.isSuccess
            ? 'slds-box slds-theme_success slds-p-around_small slds-m-bottom_medium'
            : 'slds-box slds-theme_error slds-p-around_small slds-m-bottom_medium';
    }

    async handleApply(event) {
        const scenarioName = event.currentTarget.dataset.scenario;
        this.isLoading = true;
        this.resultMessage = undefined;
        try {
            const result = await applyScenario({ scenarioName });
            this.isSuccess = true;
            this.resultMessage = result;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: `Scenario "${scenarioName}" applied successfully.`,
                    variant: 'success'
                })
            );
        } catch (error) {
            this.isSuccess = false;
            this.resultMessage = error.body ? error.body.message : 'An error occurred while applying the scenario.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.resultMessage,
                    variant: 'error'
                })
            );
        } finally {
            this.isLoading = false;
            await refreshApex(this.wiredScenariosResult);
        }
    }

    async handleRemove(event) {
        const scenarioName = event.currentTarget.dataset.scenario;
        this.isLoading = true;
        this.resultMessage = undefined;
        try {
            const result = await removeScenario({ scenarioName });
            this.isSuccess = true;
            this.resultMessage = result;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: `Scenario "${scenarioName}" removed successfully.`,
                    variant: 'success'
                })
            );
        } catch (error) {
            this.isSuccess = false;
            this.resultMessage = error.body ? error.body.message : 'An error occurred while removing the scenario.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.resultMessage,
                    variant: 'error'
                })
            );
        } finally {
            this.isLoading = false;
            await refreshApex(this.wiredScenariosResult);
        }
    }
}
