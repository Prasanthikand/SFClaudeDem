/**
 * Test class for FavoriteController.
 * Covers: getFavoriteIds, addFavorite, removeFavorite, getFavoriteProperties —
 * including happy-path, idempotency, not-found, null-input, and empty-set branches.
 * Target coverage: ≥ 85 %.
 */
@IsTest
private class FavoriteControllerTest {

    // ── Test Data Setup ──────────────────────────────────────────────────────

    @TestSetup
    static void makeData() {
        List<Property__c> properties = new List<Property__c>{
            new Property__c(
                Name = 'Sunset Villa',
                City__c = 'Austin',
                State__c = 'TX',
                Price__c = 450000,
                Beds__c = 3,
                Baths__c = 2
            ),
            new Property__c(
                Name = 'Ocean Breeze',
                City__c = 'Miami',
                State__c = 'FL',
                Price__c = 875000,
                Beds__c = 4,
                Baths__c = 3
            ),
            new Property__c(
                Name = 'Mountain Retreat',
                City__c = 'Denver',
                State__c = 'CO',
                Price__c = 620000,
                Beds__c = 5,
                Baths__c = 4
            )
        };
        insert properties;
    }

    // ── Helper ───────────────────────────────────────────────────────────────

    /**
     * Returns the first Property__c inserted in @TestSetup by name.
     */
    private static Property__c getProperty(String name) {
        return [SELECT Id FROM Property__c WHERE Name = :name LIMIT 1];
    }

    // ── getFavoriteIds ───────────────────────────────────────────────────────

    @IsTest
    static void getFavoriteIds_noFavorites_returnsEmptySet() {
        Test.startTest();
        List<Id> result = FavoriteController.getFavoriteIds();
        Test.stopTest();

        Assert.isNotNull(result, 'Result should never be null');
        Assert.areEqual(0, result.size(), 'A user with no favorites should get an empty list');
    }

    @IsTest
    static void getFavoriteIds_withFavorites_returnsPropertyIds() {
        Property__c prop = getProperty('Sunset Villa');
        insert new Property_Favorite__c(
            Property__c = prop.Id,
            User__c = UserInfo.getUserId()
        );

        Test.startTest();
        List<Id> result = FavoriteController.getFavoriteIds();
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Should return exactly one favorited Id');
        Assert.isTrue(result.contains(prop.Id), 'The list should contain the favorited property Id');
    }

    // ── addFavorite ──────────────────────────────────────────────────────────

    @IsTest
    static void addFavorite_newProperty_insertsRecord() {
        Property__c prop = getProperty('Ocean Breeze');

        Test.startTest();
        Id favId = FavoriteController.addFavorite(prop.Id);
        Test.stopTest();

        Assert.isNotNull(favId, 'Returned Id should not be null');

        Integer count = [
            SELECT COUNT()
            FROM Property_Favorite__c
            WHERE Property__c = :prop.Id
                AND User__c = :UserInfo.getUserId()
        ];
        Assert.areEqual(1, count, 'Exactly one Property_Favorite__c record should exist after addFavorite');
    }

    @IsTest
    static void addFavorite_duplicate_returnsExistingIdNoDuplicate() {
        Property__c prop = getProperty('Sunset Villa');

        Test.startTest();
        Id firstCallId = FavoriteController.addFavorite(prop.Id);
        Id secondCallId = FavoriteController.addFavorite(prop.Id);
        Test.stopTest();

        Assert.isNotNull(firstCallId, 'First call should return a valid Id');
        Assert.isNotNull(secondCallId, 'Second call should return a valid Id');
        Assert.areEqual(firstCallId, secondCallId, 'Both calls should return the same existing record Id');

        Integer count = [
            SELECT COUNT()
            FROM Property_Favorite__c
            WHERE Property__c = :prop.Id
                AND User__c = :UserInfo.getUserId()
        ];
        Assert.areEqual(1, count, 'Only one favorite record should exist — no duplicate inserted');
    }

    @IsTest
    static void addFavorite_nullPropertyId_throwsAuraHandledException() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            FavoriteController.addFavorite(null);
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'AuraHandledException should be thrown for null propertyId');
    }

    // ── removeFavorite ───────────────────────────────────────────────────────

    @IsTest
    static void removeFavorite_existingFavorite_deletesRecord() {
        Property__c prop = getProperty('Mountain Retreat');
        insert new Property_Favorite__c(
            Property__c = prop.Id,
            User__c = UserInfo.getUserId()
        );

        Test.startTest();
        FavoriteController.removeFavorite(prop.Id);
        Test.stopTest();

        Integer count = [
            SELECT COUNT()
            FROM Property_Favorite__c
            WHERE Property__c = :prop.Id
                AND User__c = :UserInfo.getUserId()
        ];
        Assert.areEqual(0, count, 'Favorite record should be deleted after removeFavorite');
    }

    @IsTest
    static void removeFavorite_noExistingFavorite_noExceptionThrown() {
        Property__c prop = getProperty('Ocean Breeze');
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            FavoriteController.removeFavorite(prop.Id);
        } catch (Exception ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isFalse(exceptionThrown, 'removeFavorite on a non-existent favorite should not throw');
    }

    @IsTest
    static void removeFavorite_nullPropertyId_throwsAuraHandledException() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            FavoriteController.removeFavorite(null);
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'AuraHandledException should be thrown for null propertyId');
    }

    // ── getFavoriteProperties ────────────────────────────────────────────────

    @IsTest
    static void getFavoriteProperties_noFavorites_returnsEmptyList() {
        Test.startTest();
        List<Property__c> result = FavoriteController.getFavoriteProperties();
        Test.stopTest();

        Assert.isNotNull(result, 'Result should never be null');
        Assert.areEqual(0, result.size(), 'A user with no favorites should get an empty list');
    }

    @IsTest
    static void getFavoriteProperties_twoFavorites_returnsTwoProperties() {
        Property__c propA = getProperty('Sunset Villa');
        Property__c propB = getProperty('Ocean Breeze');

        insert new List<Property_Favorite__c>{
            new Property_Favorite__c(
                Property__c = propA.Id,
                User__c = UserInfo.getUserId()
            ),
            new Property_Favorite__c(
                Property__c = propB.Id,
                User__c = UserInfo.getUserId()
            )
        };

        Test.startTest();
        List<Property__c> result = FavoriteController.getFavoriteProperties();
        Test.stopTest();

        Assert.areEqual(2, result.size(), 'getFavoriteProperties should return exactly 2 entries');

        Set<Id> returnedIds = new Set<Id>();
        for (Property__c p : result) {
            returnedIds.add(p.Id);
        }
        Assert.isTrue(returnedIds.contains(propA.Id), 'Result should include first favorited property');
        Assert.isTrue(returnedIds.contains(propB.Id), 'Result should include second favorited property');
    }
}
