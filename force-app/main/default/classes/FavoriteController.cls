/**
 * AuraEnabled controller that manages Property_Favorite__c records for the
 * current running user. Exposes read and write operations for the favoriting
 * feature used by the propertyTileList, propertyFavoriteButton, and
 * myFavorites Lightning Web Components.
 *
 * All SOQL uses WITH USER_MODE to enforce CRUD/FLS for the running user.
 * All DML is performed in USER_MODE via AccessLevel parameter.
 */
public with sharing class FavoriteController {

    // ─── Read Methods ────────────────────────────────────────────────────────

    /**
     * Returns the List of Property__c Ids that the running user has favorited.
     * Marked cacheable so LWC wire adapters can cache the result client-side.
     *
     * @return List<Id> of Property__c record Ids favorited by the current user.
     *         Returns an empty List when the user has no favorites.
     */
    @AuraEnabled(cacheable=true)
    public static List<Id> getFavoriteIds() {
        List<Property_Favorite__c> favorites = [
            SELECT Property__c
            FROM Property_Favorite__c
            WHERE User__c = :UserInfo.getUserId()
            WITH USER_MODE
        ];

        List<Id> favoriteIds = new List<Id>();
        for (Property_Favorite__c fav : favorites) {
            favoriteIds.add(fav.Property__c);
        }
        return favoriteIds;
    }

    /**
     * Returns the full list of Property__c records that the running user has
     * favorited, with the fields required to render a property tile.
     * Marked cacheable so LWC wire adapters can cache the result client-side.
     *
     * @return List<Property__c> of favorited properties. Returns an empty list
     *         when the user has no favorites.
     */
    @AuraEnabled(cacheable=true)
    public static List<Property__c> getFavoriteProperties() {
        List<Id> favoriteIds = getFavoriteIds();
        if (favoriteIds.isEmpty()) {
            return new List<Property__c>();
        }

        return [
            SELECT
                Id,
                Name,
                City__c,
                State__c,
                Beds__c,
                Baths__c,
                Price__c,
                Thumbnail__c
            FROM Property__c
            WHERE Id IN :favoriteIds
            WITH USER_MODE
            ORDER BY Name
        ];
    }

    // ─── Write Methods ───────────────────────────────────────────────────────

    /**
     * Adds a property to the running user's favorites. Idempotent: if the
     * favorite already exists the existing record Id is returned without
     * inserting a duplicate.
     *
     * @param propertyId Id of the Property__c record to favorite.
     * @return Id of the Property_Favorite__c record (new or pre-existing).
     * @throws AuraHandledException when propertyId is null or a DML error occurs.
     * @example
     * Id favId = FavoriteController.addFavorite(propertyId);
     */
    @AuraEnabled
    public static Id addFavorite(Id propertyId) {
        if (propertyId == null) {
            throw new AuraHandledException('propertyId is required.');
        }

        // Duplicate guard — return existing record Id without inserting again.
        List<Property_Favorite__c> existing = [
            SELECT Id
            FROM Property_Favorite__c
            WHERE Property__c = :propertyId
                AND User__c = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];
        if (!existing.isEmpty()) {
            return existing[0].Id;
        }

        try {
            Property_Favorite__c favorite = new Property_Favorite__c(
                Property__c = propertyId,
                User__c = UserInfo.getUserId()
            );
            insert as user favorite;
            return favorite.Id;
        } catch (DmlException dmlEx) {
            throw new AuraHandledException(dmlEx.getDmlMessage(0));
        }
    }

    /**
     * Removes the running user's favorite record for the given property.
     * Idempotent: if no favorite exists the method returns without error.
     *
     * @param propertyId Id of the Property__c record to un-favorite.
     * @throws AuraHandledException when propertyId is null or a DML error occurs.
     * @example
     * FavoriteController.removeFavorite(propertyId);
     */
    @AuraEnabled
    public static void removeFavorite(Id propertyId) {
        if (propertyId == null) {
            throw new AuraHandledException('propertyId is required.');
        }

        List<Property_Favorite__c> existing = [
            SELECT Id
            FROM Property_Favorite__c
            WHERE Property__c = :propertyId
                AND User__c = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];
        if (existing.isEmpty()) {
            return;
        }

        try {
            delete as user existing;
        } catch (DmlException dmlEx) {
            throw new AuraHandledException(dmlEx.getDmlMessage(0));
        }
    }
}
