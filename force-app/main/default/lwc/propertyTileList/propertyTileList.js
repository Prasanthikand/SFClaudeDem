import { LightningElement, wire } from 'lwc';
import {
    publish,
    subscribe,
    unsubscribe,
    MessageContext
} from 'lightning/messageService';
import { refreshApex } from '@salesforce/apex';
import FILTERSCHANGEMC from '@salesforce/messageChannel/FiltersChange__c';
import PROPERTYSELECTEDMC from '@salesforce/messageChannel/PropertySelected__c';
import getPagedPropertyList from '@salesforce/apex/PropertyController.getPagedPropertyList';
import getFavoriteIds from '@salesforce/apex/FavoriteController.getFavoriteIds';
import addFavorite from '@salesforce/apex/FavoriteController.addFavorite';
import removeFavorite from '@salesforce/apex/FavoriteController.removeFavorite';

const PAGE_SIZE = 9;

export default class PropertyTileList extends LightningElement {
    pageNumber = 1;
    pageSize = PAGE_SIZE;

    searchKey = '';
    maxPrice = 9999999;
    minBedrooms = 0;
    minBathrooms = 0;

    _favoritesWireResult;
    favoriteIds = new Set();

    @wire(MessageContext)
    messageContext;

    @wire(getPagedPropertyList, {
        searchKey: '$searchKey',
        maxPrice: '$maxPrice',
        minBedrooms: '$minBedrooms',
        minBathrooms: '$minBathrooms',
        pageSize: '$pageSize',
        pageNumber: '$pageNumber'
    })
    properties;

    @wire(getFavoriteIds)
    wiredFavorites(result) {
        this._favoritesWireResult = result;
        if (result.data) {
            this.favoriteIds = new Set(result.data);
        }
    }

    connectedCallback() {
        this.subscription = subscribe(
            this.messageContext,
            FILTERSCHANGEMC,
            (message) => {
                this.handleFilterChange(message);
            }
        );
    }

    disconnectedCallback() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleFilterChange(filters) {
        this.searchKey = filters.searchKey;
        this.maxPrice = filters.maxPrice;
        this.minBedrooms = filters.minBedrooms;
        this.minBathrooms = filters.minBathrooms;
    }

    handlePreviousPage() {
        this.pageNumber = this.pageNumber - 1;
    }

    handleNextPage() {
        this.pageNumber = this.pageNumber + 1;
    }

    get propertiesWithFavoriteFlag() {
        if (!this.properties || !this.properties.data) {
            return [];
        }
        return this.properties.data.records.map((prop) => ({
            ...prop,
            isFavorited: this.favoriteIds.has(prop.Id)
        }));
    }

    handlePropertySelected(event) {
        const message = { propertyId: event.detail };
        publish(this.messageContext, PROPERTYSELECTEDMC, message);
    }

    handleFavoriteToggle(event) {
        const { propertyId, isFavorited } = event.detail;
        const action = isFavorited ? removeFavorite : addFavorite;
        action({ propertyId })
            .then(() => refreshApex(this._favoritesWireResult))
            .catch((error) => console.error(error));
    }
}
