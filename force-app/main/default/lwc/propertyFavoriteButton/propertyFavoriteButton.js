import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFavoriteIds from '@salesforce/apex/FavoriteController.getFavoriteIds';
import addFavorite from '@salesforce/apex/FavoriteController.addFavorite';
import removeFavorite from '@salesforce/apex/FavoriteController.removeFavorite';

export default class PropertyFavoriteButton extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isFavorited = false;
    @track isLoading = false;

    connectedCallback() {
        getFavoriteIds()
            .then((result) => {
                this.isFavorited = result.includes(this.recordId);
            })
            .catch((error) => console.error(error));
    }

    handleToggleFavorite() {
        this.isLoading = true;
        const action = this.isFavorited ? removeFavorite : addFavorite;
        action({ propertyId: this.recordId })
            .then(() => {
                this.isFavorited = !this.isFavorited;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: this.isFavorited ? 'Added to Favorites' : 'Removed from Favorites',
                        variant: 'success'
                    })
                );
                this.isLoading = false;
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body ? error.body.message : 'An error occurred',
                        variant: 'error'
                    })
                );
                this.isLoading = false;
            });
    }

    get favoriteButtonLabel() {
        return this.isFavorited ? 'Remove from Favorites' : 'Add to Favorites';
    }

    get favoriteButtonVariant() {
        return this.isFavorited ? 'destructive-text' : 'neutral';
    }
}
