import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import isValidID from '@salesforce/apex/IdHolidayCheckController.isValidID';
import makeApiCallout from '@salesforce/apex/IdHolidayCheckController.makeApiCallout';

export default class IdHolidayCheck extends LightningElement {
    @track searchTerm = '';
    @track apiResponse = '';
    @track errorMessage = '';


    // Check if total digits entered are 13
    get isSearchButtonDisabled() {
        return this.searchTerm.length !== 13;
    }

    // Input in input bar
    handleInputChange(event) {
        this.searchTerm = event.target.value;
    }

    // Handle search button
    async handleSearchClick() {
        if (this.searchTerm) {
            this.errorMessage = '';
            const isValid = await this.validateIdNumber(this.searchTerm);
            if (!isValid) {
                this.showInvalidIdToast(this.errorMessage);
            }
        } else {
            return null;
        }
    }

    // Error Toast Message
    showInvalidIdToast(errorMessage) {
        const event = new ShowToastEvent({
            title: 'Invalid ID Number',
            message: `The provided South African ID number is invalid${errorMessage}`,
            variant: 'error',
        });
        this.dispatchEvent(event);
    }

    // Validate ID Number from Input Bar
    async validateIdNumber(idNumber) {
        const parts = this.parseIdNumber(idNumber);
        if (this.isValidFormat(parts)) {
            try {
                
                await isValidID({ idNumber })
                const response = await makeApiCallout({ idNumber });
                this.apiResponse = response;
                return true;

            } catch (error) {

                this.errorMessage = ' - Something went wrong while validating the ID.';

            }
        } else {
            this.setErrorMessage(parts);
        }
        return false;
    }

    // Split ID into variables
    parseIdNumber(idNumber) {
        const yearPart = parseInt(idNumber.slice(0, 2), 10);
        const monthPart = parseInt(idNumber.slice(2, 4), 10);
        const dayPart = parseInt(idNumber.slice(4, 6), 10);
        const genderPart = parseInt(idNumber.slice(6, 10), 10);
        const citizenshipDigit = parseInt(idNumber.charAt(10), 10);
    
        return { yearPart, monthPart, dayPart, genderPart, citizenshipDigit };
    }

    // Check if format of ID is correct
    isValidFormat({ yearPart, monthPart, dayPart, genderPart, citizenshipDigit }) {
        return (
            /^\d{13}$/.test(this.searchTerm) &&
            yearPart >= 0 && yearPart <= 99 &&
            monthPart >= 1 && monthPart <= 12 &&
            dayPart >= 1 && dayPart <= 31 &&
            genderPart >= 0 && genderPart <= 9999 &&
            (citizenshipDigit === 0 || citizenshipDigit === 1)
        );
    }


    // Error messages based on where ID is incorrect
    setErrorMessage({ monthPart, dayPart, genderPart, citizenshipDigit  }) {
        if (monthPart < 1 || monthPart > 12) {
            this.errorMessage = ', Invalid month.';
        } else if (dayPart < 1 || dayPart > 31) {
            this.errorMessage = ', Invalid day.';
        } else if (genderPart > 9999) {
            this.errorMessage = ', Invalid gender number.';
        } else if (citizenshipDigit > 1) {
            this.errorMessage = ', Invalid citizen number.';        
        } else {
            this.errorMessage = '';
        }
    }

    // Add luhn algorithm


}
