# SALESFORCE REQUIREMENTS DOCUMENT

**Jira Issue:** SCRUM-8
**Date:** 2026-05-10
**Assignee:** Prasanthi K (prasanthi.kandula@cognizant.com)
**Priority:** Medium
**Status:** To Do

---

## Request Summary

As a property seeker, users need the ability to mark individual properties as favorites directly from the property listing page (via a heart icon on each property tile) and from the property detail record page (via an "Add to Favorites" / "Remove from Favorites" button). Favorites must persist across sessions, requiring server-side storage linked to the current user. A dedicated "My Favorites" Lightning App Page (or tab) must display all favorited properties for a given user, with each entry navigable to the property detail page. The heart icon on property tiles must toggle between an empty/inactive state and a filled red/active state to reflect the current favorite status.

## Business Objective

Enable property seekers to curate and quickly revisit a personal shortlist of properties of interest without needing to re-apply search filters. This reduces friction in the property evaluation process and increases platform stickiness by giving users a persistent, personalized workspace within the DreamHouse application.

## Assumptions

1. The running user's `Id` (`UserInfo.getUserId()`) is used as the owner of each `Property_Favorite__c` record — there is no separate "property seeker" persona object.
2. Sharing model for `Property_Favorite__c` will be **Private** (OWD = Private) with a sharing rule or implicit ownership so each user sees only their own favorites.
3. The "My Favorites" view will be delivered as a new Lightning App Page (`My_Favorites.flexipage-meta.xml`) surfaced as a tab in the existing DreamHouse app, rather than as a modal or sidebar panel.
4. The property detail page favorite button will be added to the existing `Property_Record_Page.flexipage-meta.xml` sidebar region as the new `propertyFavoriteButton` LWC component.
5. `propertyTile` currently receives no favorite state from its parent — the new Apex method `getFavoriteIds` will return a `Set<Id>` of favorited property Ids so the parent (`propertyTileList`) can pass `isFavorited` as a property to each tile.
6. No batch/asynchronous processing is needed; all DML is synchronous (single-record insert/delete per user action).
7. API version for all new components is 64.0.
8. Jest test files are NOT created for any LWC component (per project convention).

## Out of Scope

- Email or push notifications when a property is favorited
- Sharing favorites with other users or brokers
- Analytics/reporting on most-favorited properties
- Favorites count displayed on the property listing page
- Mobile-specific (Small form factor) optimizations beyond what existing components already handle

---

## Component Checklist

| # | Component | Type | Action | Status |
|---|-----------|------|--------|--------|
| 1 | Property_Favorite__c | Custom Object | CREATE | [ ] |
| 2 | Property_Favorite__c.Property__c | Custom Field (Lookup) | CREATE | [ ] |
| 3 | Property_Favorite__c.User__c | Custom Field (Lookup) | CREATE | [ ] |
| 4 | Property_Favorite__c.UniqueUserProperty | Unique Validation Rule | CREATE | [ ] |
| 5 | Property_Favorite__c (OWD — Private) | Sharing Settings | CREATE | [ ] |
| 6 | FavoriteController | Apex Class | CREATE | [ ] |
| 7 | FavoriteControllerTest | Apex Test Class | CREATE | [ ] |
| 8 | propertyTile (heart icon + toggle) | LWC Component | UPDATE | [ ] |
| 9 | propertyTileList (pass isFavorited state) | LWC Component | UPDATE | [ ] |
| 10 | propertyFavoriteButton | LWC Component | CREATE | [ ] |
| 11 | myFavorites | LWC Component | CREATE | [ ] |
| 12 | My_Favorites | Lightning App Page (FlexiPage) | CREATE | [ ] |
| 13 | My_Favorites_Tab | Custom Tab | CREATE | [ ] |
| 14 | dreamhouse (permission set) | Permission Set | UPDATE | [ ] |
| 15 | Property_Record_Page.flexipage-meta.xml | FlexiPage | UPDATE | [ ] |

---

## SECTION A: ADMINISTRATION TASKS (Declarative / Configuration)

*These tasks are handled through Salesforce Setup, point-and-click tools, and metadata configuration without custom code.*

| # | Task | Description | Salesforce Feature | Priority | Effort Estimate |
|---|------|-------------|-------------------|----------|----------------|
| A1 | Create `Property_Favorite__c` Custom Object | New custom object with Label = "Property Favorite", Plural Label = "Property Favorites", API Name = `Property_Favorite__c`. Name field = Auto Number (format `FAV-{0000}`). OWD sharing = **Private**. Allow Reports = true, Allow Activities = false, Track Field History = false, Deployment Status = Deployed. | Custom Object | High | S |
| A2 | Create `Property__c` Lookup Field on `Property_Favorite__c` | Lookup field: Label = "Property", API Name = `Property__c`, Related Object = `Property__c`. Required = true. Relationship Name = `Property_Favorites`. Delete behavior = Cascade delete (child deleted when parent property is deleted). | Custom Field — Lookup | High | S |
| A3 | Create `User__c` Lookup Field on `Property_Favorite__c` | Lookup field: Label = "User", API Name = `User__c`, Related Object = `User`. Required = true. Relationship Name = `User_Favorites`. Delete behavior = Don't allow deletion of the lookup record that's part of a lookup relationship (restrict). | Custom Field — Lookup | High | S |
| A4 | Create Unique Validation Rule on `Property_Favorite__c` | Validation Rule: `UniqueUserProperty`. Prevents duplicate favorites by checking if a record with the same `Property__c` and `User__c` already exists. Error condition formula: `VLOOKUP( VLOOKUP_MATCH, VLOOKUP_FIELD, VLOOKUP_OBJECT )` — implement via a before-insert Apex check in `FavoriteController` instead (see B1). Mark this row as handled programmatically. | Validation / Apex (see B1) | High | S |
| A5 | Update `dreamhouse` Permission Set | Add to the existing `dreamhouse.permissionset-meta.xml`: (a) Object permissions for `Property_Favorite__c` — Read, Create, Delete (no Edit, no ModifyAll, no ViewAll). (b) Field-level security: Read+Edit on `Property_Favorite__c.Property__c` and `Property_Favorite__c.User__c`. (c) Apex class access for `FavoriteController`. (d) Tab visibility for `My_Favorites` tab set to Visible. | Permission Set | High | S |
| A6 | Create `My_Favorites` Custom Tab | Custom Tab of type Lightning Component Tab pointing to the `myFavorites` LWC App Page. Tab Label = "My Favorites", Tab Name = `My_Favorites`, Icon = `utility:favorite` (heart). Add to the DreamHouse app navigation. | Custom Tab | Medium | S |
| A7 | Create `My_Favorites` Lightning App Page (FlexiPage) | New Lightning App Page: masterLabel = "My Favorites", type = AppPage, template = `lightning:appDefaultLayout` (one-region). Place the `myFavorites` LWC in the main region. Activate and assign to the DreamHouse app. | FlexiPage (AppPage) | Medium | S |
| A8 | Update `Property_Record_Page` FlexiPage | Add `propertyFavoriteButton` LWC component to the **sidebar** region of `Property_Record_Page.flexipage-meta.xml` — insert it at the top of the sidebar, above `brokerCard`. No new tabs required. | FlexiPage (RecordPage) | Medium | S |

---

## SECTION B: DEVELOPMENT TASKS (Programmatic / Custom Code)

*These tasks require custom Apex or Lightning Web Components because the requirements exceed declarative capability.*

| # | Task | Description | Technology | Rationale for Code | Priority | Effort Estimate |
|---|------|-------------|------------|-------------------|----------|----------------|
| B1 | `FavoriteController` Apex Class | Server-side controller with four `@AuraEnabled` methods: (1) `getFavoriteIds()`— queries all `Property_Favorite__c` records for `UserInfo.getUserId()`, returns `Set<Id>` of `Property__c` Ids. Used by `propertyTileList` on load. (2) `addFavorite(Id propertyId)` — inserts a new `Property_Favorite__c` record linking current user + property. Includes duplicate guard (query-before-insert or try/catch on unique index). Returns the new record Id. (3) `removeFavorite(Id propertyId)` — deletes the `Property_Favorite__c` record where `Property__c = propertyId AND User__c = UserInfo.getUserId()`. (4) `getFavoriteProperties()` — returns `List<Property__c>` for all properties the current user has favorited, with fields: `Id, Name, City__c, State__c, Beds__c, Baths__c, Price__c, Thumbnail__c`. All methods use `WITH USER_MODE` for CRUD/FLS enforcement. `addFavorite` and `removeFavorite` are non-cacheable (DML). `getFavoriteIds` and `getFavoriteProperties` are `cacheable=true`. | Apex | DML operations (insert/delete), dynamic user-scoped queries, and duplicate prevention require Apex. Declarative (Flow) cannot be called from LWC wire adapters and cannot return typed collections. | High | M |
| B2 | `FavoriteControllerTest` Apex Test Class | Test class achieving minimum 85% coverage of `FavoriteController`. Test scenarios: (a) `testGetFavoriteIds_empty` — new user has no favorites, returns empty set. (b) `testAddFavorite_success` — adds a favorite, verifies record inserted. (c) `testAddFavorite_duplicate` — calling `addFavorite` twice on same property does not throw uncaught exception (duplicate guard). (d) `testRemoveFavorite_success` — removes a favorite, verifies record deleted. (e) `testGetFavoriteProperties` — inserts 2 favorites, verifies both properties returned. Uses `@TestSetup` to create test `Property__c` records. Runs as a test user with the `dreamhouse` permission set assigned. | Apex Test | Test coverage is a Salesforce deployment requirement. Cannot be achieved declaratively. | High | M |
| B3 | Update `propertyTile` LWC | Add a heart/favorite icon overlay to the tile. Changes: (a) Add `@api isFavorited` boolean property. (b) Render a `lightning-icon` (`utility:heart`) in the top-right corner of the tile `div`, positioned absolutely. (c) Apply CSS class `favorite-active` (red fill via `--lwc-colorTextIconDefault` override or inline style `color: red`) when `isFavorited === true`, otherwise render the outline variant. (d) Add `onclick` handler `handleFavoriteToggle` that fires a custom `favoritetoggle` DOM event with `detail: { propertyId: this.property.Id, isFavorited: this.isFavorited }` bubbling up to `propertyTileList`. (e) Call `event.stopPropagation()` inside `handleFavoriteToggle` so the click does not also trigger `handlePropertySelected`. | LWC (UPDATE) | Icon state toggle, custom events, and CSS class manipulation require LWC code. The existing `propertyTile` HTML has no slot for declarative icon injection. | High | M |
| B4 | Update `propertyTileList` LWC | Wire `getFavoriteIds` from `FavoriteController` to load the current user's favorited property IDs on component initialization. Changes: (a) Import `getFavoriteIds`, `addFavorite`, `removeFavorite` from `@salesforce/apex/FavoriteController`. (b) Add `favoriteIds = new Set()` tracked property. (c) Wire `getFavoriteIds` — on result, populate `this.favoriteIds` as a `Set`. (d) Add computed getter `propertiesWithFavoriteFlag` that maps `properties.data.records` and adds `isFavorited: this.favoriteIds.has(prop.Id)` to each property object. (e) Update template to pass `property={prop}` and `is-favorited={prop.isFavorited}` to each `c-property-tile`. (f) Add `handleFavoriteToggle(event)` — calls `addFavorite` or `removeFavorite` imperatively based on `event.detail.isFavorited`, then refreshes `favoriteIds` via `refreshApex` or re-queries. | LWC (UPDATE) | Requires wire adapter composition, imperative Apex calls, and reactive Set-based state management — beyond declarative capability. The parent must own favorite state to keep tile components stateless and reusable. | High | M |
| B5 | Create `propertyFavoriteButton` LWC | New standalone LWC for the Property Record Page sidebar. This component is record-context aware (receives `recordId` via `@api`). Behavior: (a) On `connectedCallback`, call `getFavoriteIds` (or a dedicated `isFavorited(propertyId)` method) to determine current favorite status. (b) Render a `lightning-button` with `label` = "Add to Favorites" or "Remove from Favorites" and `icon-name` = `utility:heart` based on `isFavorited` state. (c) On click, call `addFavorite` or `removeFavorite` imperatively and toggle the local `isFavorited` state. (d) Show a `lightning-spinner` during the async call. (e) On error, use `this.dispatchEvent(new ShowToastEvent(...))` with variant `error`. On success, show a success toast. | LWC (CREATE) | Requires an `@api recordId` record-context component with imperative Apex calls and toast notifications. A Quick Action or standard button cannot conditionally change its label based on per-user database state. | High | M |
| B6 | Create `myFavorites` LWC | New LWC App Page component that displays all favorited properties for the current user. Structure: (a) On `connectedCallback` / wire, call `getFavoriteProperties` from `FavoriteController`. (b) Render a `lightning-card` with title "My Favorites" and icon `utility:favorite`. (c) For each property, render a row (or reuse `c-property-tile`) showing: `Thumbnail__c` image, `Name`, `City__c`, `State__c`, `Beds__c`, `Baths__c`, `Price__c` (formatted as currency). (d) Each row/tile has an onclick handler that navigates to the Property record page using `NavigationMixin.Navigate` with `type: 'standard__recordPage'`. (e) Include a "Remove" heart icon per tile that calls `removeFavorite` and refreshes the list. (f) If the list is empty, render `c-error-panel` with `friendly-message="You have no saved favorites yet."`. (g) On error, render `c-error-panel`. | LWC (CREATE) | Requires a user-scoped server query, navigation, and conditional rendering. A standard Related List cannot filter by `UserInfo.getUserId()` at the component level without Apex. | High | M |

---

## SECTION C: ARCHITECTURAL DECISIONS

### C1 — Persistence via `Property_Favorite__c` Custom Object (not a custom field on `Property__c`)

A junction-object approach (`Property_Favorite__c` with lookups to `Property__c` and `User`) is chosen over alternatives such as a multi-select picklist or a Text Area on `Property__c`. The junction object correctly models a many-to-many relationship (one property can be favorited by multiple users; one user can favorite multiple properties), enforces row-level ownership via the Private OWD (each user owns only their own favorite records), and allows SOQL filtering via `WHERE User__c = :UserInfo.getUserId()` without exposing other users' data. A field on `Property__c` would require sharing all users' favorites in one field and cannot be indexed for per-user queries.

### C2 — Favorite State Owned by `propertyTileList`, Not by Individual `propertyTile`

`propertyTileList` already owns the collection of `Property__c` records from the wire adapter. Loading all favorited IDs once in the parent (as a Set) and passing `isFavorited` as a boolean `@api` prop to each child tile avoids N+1 Apex call patterns (one call per tile would hit governor limits at scale). The tile component remains a pure presentational component and the parent orchestrates all server interactions.

### C3 — Apex Controller Pattern Consistent with Existing `PropertyController`

`FavoriteController` follows the same `@AuraEnabled` pattern used by `PropertyController`. All read methods use `cacheable=true` with `scope='global'` for LWC wire adapter compatibility. All DML methods are non-cacheable. `WITH USER_MODE` is used in all SOQL statements to enforce CRUD/FLS automatically, consistent with existing controller patterns.

### C4 — No Lightning Message Service for Favorite State

Favorite state is local to each page context (listing page vs. record page). There is no cross-component synchronization requirement between pages. On the listing page, `propertyTileList` is the sole subscriber. On the record page, `propertyFavoriteButton` is standalone. LMS would add unnecessary complexity. A simple `refreshApex` or imperative re-query after DML is sufficient.

### C5 — `propertyFavoriteButton` as a Sidebar LWC on the Record Page

Acceptance Criterion 2 requires an "Add to Favorites" button on the property detail page. Rather than modifying the existing `propertySummary` component (which would increase coupling and violate single-responsibility), a new standalone `propertyFavoriteButton` LWC is created and added to the sidebar region of `Property_Record_Page.flexipage-meta.xml`. This follows the composable page-builder architecture already established in the project.

### C6 — Duplicate Guard in Apex (not a Validation Rule)

A Validation Rule using `VLOOKUP` cannot reliably prevent duplicate `Property_Favorite__c` records when LWC makes concurrent async calls. The `addFavorite` Apex method will use a query-before-insert pattern: `SELECT Id FROM Property_Favorite__c WHERE Property__c = :propertyId AND User__c = :currentUserId LIMIT 1`. If a record exists, the method returns its Id without throwing. This provides idempotent behavior that is safe for optimistic UI patterns.

---

## Agent Prompts

### ADMIN AGENT PROMPT

```
You are the salesforce-admin agent. Execute the following tasks for Jira story SCRUM-8 ("Favoriting Properties") in the DreamHouse Salesforce DX project located at:
C:\Users\2094003\OneDrive - Cognizant\Documents\Claude Code\Development\SFClaudeDem

Project source root: force-app/main/default/
Salesforce API Version: 64.0

--- TASKS ---

TASK A1 — Create Property_Favorite__c Custom Object
File: force-app/main/default/objects/Property_Favorite__c/Property_Favorite__c.object-meta.xml
- Label: Property Favorite
- Plural Label: Property Favorites
- API Name: Property_Favorite__c
- Name field type: AutoNumber, format: FAV-{0000}, starting number: 1
- Sharing model: Private
- allowReports: true
- allowActivities: false
- enableHistory: false
- deploymentStatus: Deployed
- description: Stores a user's favorited properties. Each record links one User to one Property__c.

TASK A2 — Create Property__c Lookup Field on Property_Favorite__c
File: force-app/main/default/objects/Property_Favorite__c/fields/Property__c.field-meta.xml
- Field type: Lookup
- Label: Property
- API Name: Property__c
- Referenced Object: Property__c
- RelationshipName: Property_Favorites
- RelationshipLabel: Property Favorites
- Required: true
- deleteConstraint: Cascade (when property deleted, favorites are deleted)

TASK A3 — Create User__c Lookup Field on Property_Favorite__c
File: force-app/main/default/objects/Property_Favorite__c/fields/User__c.field-meta.xml
- Field type: Lookup
- Label: User
- API Name: User__c
- Referenced Object: User
- RelationshipName: User_Favorites
- RelationshipLabel: Property Favorites
- Required: true
- deleteConstraint: Restrict (cannot delete user while favorites exist)

TASK A4 — Update dreamhouse Permission Set
File: force-app/main/default/permissionsets/dreamhouse.permissionset-meta.xml
Add to the EXISTING file (do not remove any existing entries):
1. Object permissions for Property_Favorite__c:
   - allowCreate: true
   - allowRead: true
   - allowDelete: true
   - allowEdit: false
   - modifyAllRecords: false
   - viewAllRecords: false
2. Field permissions (readable + editable) for:
   - Property_Favorite__c.Property__c
   - Property_Favorite__c.User__c
3. Apex class access:
   - apexClass: FavoriteController, enabled: true
4. Tab visibility:
   - tab: My_Favorites, visibility: Visible

TASK A5 — Create My_Favorites Custom Tab
File: force-app/main/default/tabs/My_Favorites.tab-meta.xml
- Type: Lightning Component tab referencing the myFavorites LWC App Page
- Label: My Favorites
- mobileReady: true
- motif: utility:favorite (use standard heart icon)

TASK A6 — Create My_Favorites Lightning App Page
File: force-app/main/default/flexipages/My_Favorites.flexipage-meta.xml
- masterLabel: My Favorites
- type: AppPage
- template: lightning:appDefaultLayout (one-region, standard)
- Place component: myFavorites in the main region
- description: Displays the current user's favorited properties.

TASK A7 — Update Property_Record_Page FlexiPage
File: force-app/main/default/flexipages/Property_Record_Page.flexipage-meta.xml
Add a new componentInstance for propertyFavoriteButton to the EXISTING sidebar region:
- Insert at the top of the sidebar region (before the existing brokerCard2 entry)
- componentName: c__propertyFavoriteButton
- identifier: c_propertyFavoriteButton
No other regions or existing entries should be modified.

All files must be valid Salesforce metadata XML at API version 64.0.
Do NOT create Jest test files.
Do NOT create Apex classes — those are handled by the developer agent.
```

---

### DEVELOPER AGENT PROMPT

```
You are the salesforce-developer agent. Implement all LWC and Apex components for Jira story SCRUM-8 ("Favoriting Properties") in the DreamHouse Salesforce DX project at:
C:\Users\2094003\OneDrive - Cognizant\Documents\Claude Code\Development\SFClaudeDem

Project source root: force-app/main/default/
Salesforce API Version: 64.0
Code style: 4-space indentation, single quotes, no trailing commas (Prettier config).
DO NOT create any Jest test files (__tests__/ directories or *.test.js files).

=== PREREQUISITE CONTEXT ===

Existing components you will modify:
- force-app/main/default/lwc/propertyTile/propertyTile.js + propertyTile.html + propertyTile.css
- force-app/main/default/lwc/propertyTileList/propertyTileList.js + propertyTileList.html

New components you will create:
- force-app/main/default/lwc/propertyFavoriteButton/ (new folder)
- force-app/main/default/lwc/myFavorites/ (new folder)
- force-app/main/default/classes/FavoriteController.cls + .cls-meta.xml
- force-app/main/default/classes/FavoriteControllerTest.cls + .cls-meta.xml

Custom object available: Property_Favorite__c
  - Fields: Id, Name (AutoNumber), Property__c (Lookup→Property__c), User__c (Lookup→User)
  - OWD: Private

=== TASK B1: FavoriteController.cls ===

Create force-app/main/default/classes/FavoriteController.cls

public with sharing class FavoriteController {

    @AuraEnabled(cacheable=true scope='global')
    public static Set<Id> getFavoriteIds() {
        // Query Property_Favorite__c records for the running user
        // Return a Set<Id> of Property__c Ids
        // Use WITH USER_MODE
    }

    @AuraEnabled
    public static Id addFavorite(Id propertyId) {
        // Duplicate guard: query for existing record first
        // If exists, return existing record Id (idempotent)
        // If not, insert new Property_Favorite__c with Property__c=propertyId, User__c=UserInfo.getUserId()
        // Use WITH USER_MODE for query; use as user context for insert
        // Return the record Id
    }

    @AuraEnabled
    public static void removeFavorite(Id propertyId) {
        // Find and delete the Property_Favorite__c record for this user+property
        // Use WITH USER_MODE
        // If no record found, do nothing (no exception)
    }

    @AuraEnabled(cacheable=true scope='global')
    public static List<Property__c> getFavoriteProperties() {
        // Get Set<Id> of favorited property Ids for current user (reuse getFavoriteIds logic or subquery)
        // Query Property__c WHERE Id IN :favoriteIds
        // Return fields: Id, Name, City__c, State__c, Beds__c, Baths__c, Price__c, Thumbnail__c
        // Use WITH USER_MODE
        // Return empty list if no favorites
    }
}

Also create the meta file:
force-app/main/default/classes/FavoriteController.cls-meta.xml
  apiVersion: 64.0, status: Active

=== TASK B2: FavoriteControllerTest.cls ===

Create force-app/main/default/classes/FavoriteControllerTest.cls

Minimum 85% code coverage. Test scenarios:
1. testGetFavoriteIds_empty: new user, no favorites → returns empty Set
2. testAddFavorite_success: call addFavorite(propertyId) → verify Property_Favorite__c record exists
3. testAddFavorite_duplicate: call addFavorite twice with same propertyId → no exception, same Id returned
4. testRemoveFavorite_success: insert favorite, call removeFavorite → verify record deleted
5. testGetFavoriteProperties: insert 2 favorites → getFavoriteProperties returns 2 Property__c records

Use @TestSetup to create 2-3 Property__c test records (Name, City__c, Price__c, Beds__c, Baths__c populated).
Use System.runAs() with a test user assigned the dreamhouse permission set.
Use @isTest annotation and Test.startTest()/stopTest() around DML calls.

=== TASK B3: UPDATE propertyTile LWC ===

Modify force-app/main/default/lwc/propertyTile/propertyTile.js:
- Add: @api isFavorited = false;
- Add method handleFavoriteToggle(event):
    event.stopPropagation();
    const favEvent = new CustomEvent('favoritetoggle', {
        detail: { propertyId: this.property.Id, isFavorited: this.isFavorited },
        bubbles: true
    });
    this.dispatchEvent(favEvent);
- Add getter favoriteIconClass returning 'favorite-icon favorite-active' when isFavorited, else 'favorite-icon'
- Add getter favoriteIconVariant returning 'inverse' (always — icon is styled via CSS class)

Modify force-app/main/default/lwc/propertyTile/propertyTile.html:
- Inside the existing <div class="tile"> add a favorite button BEFORE the <div class="lower-third">:
  <button class={favoriteIconClass} onclick={handleFavoriteToggle} title="Toggle Favorite" aria-label="Toggle Favorite">
      <lightning-icon icon-name="utility:heart" size="x-small"></lightning-icon>
  </button>

Modify (or create) force-app/main/default/lwc/propertyTile/propertyTile.css:
- .favorite-icon: position absolute, top: 8px, right: 8px, background: rgba(0,0,0,0.4), border: none, border-radius: 50%, padding: 4px, cursor: pointer, z-index: 10
- .favorite-icon lightning-icon: color: white (default/inactive state)
- .favorite-active lightning-icon (or .favorite-icon.favorite-active --lwc-colorTextIconDefault): color: #e52207 (Salesforce red / filled heart)
  Use: .favorite-active { --lwc-colorTextIconDefault: #e52207; }

=== TASK B4: UPDATE propertyTileList LWC ===

Modify force-app/main/default/lwc/propertyTileList/propertyTileList.js:
- Import getFavoriteIds, addFavorite, removeFavorite from '@salesforce/apex/FavoriteController'
- Import refreshApex from '@salesforce/apex' (for wire refresh)
- Add tracked property: favoriteIds = new Set();
- Wire getFavoriteIds to a handler that sets this.favoriteIds from the returned Set/Array
- Add getter propertiesWithFavoriteFlag: maps this.properties.data.records adding isFavorited boolean
  (check if favoriteIds.has(prop.Id) — note: wire may return array, convert to Set)
- Add handleFavoriteToggle(event):
    const { propertyId, isFavorited } = event.detail;
    if (isFavorited) {
        // currently favorited → remove
        removeFavorite({ propertyId })
            .then(() => { refreshApex(this._favoritesResult); })
            .catch(error => console.error(error));
    } else {
        // not yet favorited → add
        addFavorite({ propertyId })
            .then(() => { refreshApex(this._favoritesResult); })
            .catch(error => console.error(error));
    }
- Store the wire result in this._favoritesResult for refreshApex

Modify force-app/main/default/lwc/propertyTileList/propertyTileList.html:
- In the template loop over properties, change the c-property-tile binding to:
  <c-property-tile
      property={prop}
      is-favorited={prop.isFavorited}
      onselected={handlePropertySelected}
      onfavoritetoggle={handleFavoriteToggle}>
  </c-property-tile>
- Use propertiesWithFavoriteFlag getter instead of properties.data.records directly

=== TASK B5: CREATE propertyFavoriteButton LWC ===

Create force-app/main/default/lwc/propertyFavoriteButton/propertyFavoriteButton.js:
- @api recordId (the Property__c record Id, set by the record page)
- isFavorited = false; isLoading = false;
- connectedCallback: call getFavoriteIds imperatively, check if recordId is in result, set isFavorited
- handleToggleFavorite(): set isLoading=true, call addFavorite or removeFavorite based on isFavorited,
  on success: toggle isFavorited, show success toast, set isLoading=false
  on error: show error toast, set isLoading=false
- Use ShowToastEvent from 'lightning/platformShowToastEvent'
- Import NavigationMixin from 'lightning/navigation' (not needed here — skip)
- Import getFavoriteIds, addFavorite, removeFavorite from '@salesforce/apex/FavoriteController'

Create force-app/main/default/lwc/propertyFavoriteButton/propertyFavoriteButton.html:
<template>
    <lightning-card title="Favorites" icon-name="utility:heart">
        <div class="slds-var-m-around_medium">
            <template lwc:if={isLoading}>
                <lightning-spinner alternative-text="Loading" size="small"></lightning-spinner>
            </template>
            <template lwc:else>
                <lightning-button
                    label={favoriteButtonLabel}
                    icon-name="utility:heart"
                    onclick={handleToggleFavorite}
                    variant={favoriteButtonVariant}>
                </lightning-button>
            </template>
        </div>
    </lightning-card>
</template>

JS getters:
- get favoriteButtonLabel(): return isFavorited ? 'Remove from Favorites' : 'Add to Favorites'
- get favoriteButtonVariant(): return isFavorited ? 'destructive-text' : 'neutral'

Create force-app/main/default/lwc/propertyFavoriteButton/propertyFavoriteButton.js-meta.xml:
- apiVersion: 64.0
- isExposed: true
- targets: lightning__RecordPage (with objects: [Property__c])

=== TASK B6: CREATE myFavorites LWC ===

Create force-app/main/default/lwc/myFavorites/myFavorites.js:
- Wire getFavoriteProperties from FavoriteController
- favoriteProperties: wire result (data/error)
- get hasNoFavorites(): return favoriteProperties.data && favoriteProperties.data.length === 0
- handleNavigateToProperty(event):
    const propertyId = event.currentTarget.dataset.propertyId;
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: { recordId: propertyId, objectApiName: 'Property__c', actionName: 'view' }
    });
- handleRemoveFavorite(event):
    event.stopPropagation();
    const propertyId = event.currentTarget.dataset.propertyId;
    removeFavorite({ propertyId })
        .then(() => { refreshApex(this._favPropsResult); })
        .catch(err => console.error(err));
- Extend NavigationMixin(LightningElement)
- Import removeFavorite from FavoriteController, refreshApex

Create force-app/main/default/lwc/myFavorites/myFavorites.html:
- lightning-card with title="My Favorites" icon-name="utility:favorite"
- If favoriteProperties.data and length > 0: iterate with template for:each
  Show each property as a clickable row with: thumbnail image, name, city/state, beds/baths, price (lightning-formatted-number), and a remove heart button
- If hasNoFavorites: c-error-panel with friendly-message="You have no saved favorites yet."
- If favoriteProperties.error: c-error-panel with friendly-message="Error loading favorites."

Create force-app/main/default/lwc/myFavorites/myFavorites.js-meta.xml:
- apiVersion: 64.0
- isExposed: true
- targets: lightning__AppPage

Create force-app/main/default/lwc/myFavorites/myFavorites.css:
- Style the property rows (flex layout, thumbnail sizing, hover state for click affordance)

=== CONSTRAINTS ===
- DO NOT create any __tests__/ folders or *.test.js files
- All SOQL in Apex must use WITH USER_MODE
- All @AuraEnabled methods must handle null inputs gracefully
- Follow existing Prettier config: 4-space indent, single quotes, no trailing commas
- .cls-meta.xml files must be API version 64.0, status Active
- .js-meta.xml files must be API version 64.0
```

---

*Document generated by salesforce-design-architect agent — SCRUM-8*
*Saved to: docs/design-documents/SCRUM-8-DesignDocument.md*
