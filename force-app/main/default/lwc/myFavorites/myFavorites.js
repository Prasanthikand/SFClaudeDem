import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getFavoriteProperties from '@salesforce/apex/FavoriteController.getFavoriteProperties';
import removeFavorite from '@salesforce/apex/FavoriteController.removeFavorite';

export default class MyFavorites extends NavigationMixin(LightningElement) {
    @track favoriteProperties;
    _favPropsResult;

    @wire(getFavoriteProperties)
    wiredFavProperties(result) {
        this._favPropsResult = result;
        this.favoriteProperties = result;
    }

    get hasNoFavorites() {
        return (
            this.favoriteProperties &&
            this.favoriteProperties.data &&
            this.favoriteProperties.data.length === 0
        );
    }

    handleNavigateToProperty(event) {
        const propertyId = event.currentTarget.dataset.propertyId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: propertyId,
                objectApiName: 'Property__c',
                actionName: 'view'
            }
        });
    }

    handleRemoveFavorite(event) {
        event.stopPropagation();
        const propertyId = event.currentTarget.dataset.propertyId;
        removeFavorite({ propertyId })
            .then(() => refreshApex(this._favPropsResult))
            .catch((err) => console.error(err));
    }
}
