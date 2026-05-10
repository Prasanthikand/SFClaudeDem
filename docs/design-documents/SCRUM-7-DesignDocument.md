# SALESFORCE REQUIREMENTS DOCUMENT

**Jira Issue:** SCRUM-7
**Date:** 2026-05-10
**Assignee:** Prasanthi K (prasanthi.kandula@cognizant.com)
**Priority:** Medium
**Status at Design Time:** To Do
**Issue Type:** Story

---

**Request Summary:**
Add a new custom text field named "Banking Name" (`Banking_Name__c`) to the standard Account object in Salesforce. The field will store a banking institution name associated with the account. This is a purely declarative metadata task requiring no Apex or LWC development. The field must be created as a custom field on the standard Account object and deployed via Salesforce DX at API version 64.0.

**Business Objective:**
Enable users to capture and associate a banking name directly on the Account record, supporting financial or banking-related business processes that require this data point to be stored alongside core account information.

**Assumptions:**
1. The field type is Text (not a lookup or picklist) as stated in the story description.
2. Field length is assumed to be 255 characters (standard maximum for Text fields) unless otherwise specified — no length constraint was provided in the story.
3. The field is not required (not mandatory) by default; this can be updated if business rules dictate otherwise.
4. Field-level security (FLS) will grant Read/Edit access to the System Administrator profile at minimum; broader access will follow the org's standard permission set model.
5. The field does not need to appear on any specific page layout beyond the default Account layout — no layout modification instructions were provided.
6. No validation rule is required on this field.
7. No integration, Apex logic, or LWC component needs to consume this field as part of this story.
8. Deployment targets a scratch org using `sf project deploy start` per the project's standard workflow.

**Out of Scope:**
- Any Apex trigger, class, or batch job referencing `Banking_Name__c`
- Any LWC component changes to display this field (beyond standard record page layout)
- Validation rules on this field
- Workflow rules, Process Builder, or Flow automation triggered by this field
- Data migration or population of existing Account records
- Reporting or dashboard creation
- Integration with external banking systems

---

## Component Checklist

| # | Component | Type | Action | Status |
|---|-----------|------|--------|--------|
| 1 | Account.Banking_Name__c | Custom Field (Text) | CREATE | [ ] |
| 2 | Account Page Layout (Default) | Page Layout Assignment | UPDATE | [ ] |

---

## SECTION A: ADMINISTRATION TASKS (Declarative / Configuration)

*These tasks should be handled through Salesforce metadata files and deployed via Salesforce DX. No custom code is required.*

| # | Task | Description | Salesforce Feature | Priority | Effort Estimate |
|---|------|-------------|-------------------|----------|----------------|
| A1 | Create Banking_Name__c Field on Account | Create a custom Text field with API name `Banking_Name__c`, label "Banking Name", length 255, not required, not unique, not external ID. The field metadata file must be placed at `force-app/main/default/objects/Account/fields/Banking_Name__c.field-meta.xml` using API version 64.0. | Custom Field — Text | High | S |
| A2 | Add Field to Account Page Layout | Add the `Banking_Name__c` field to the default Account page layout (Account Layout) so it is visible to users on the Account record detail page. This is done declaratively via the page layout metadata or through Setup > Object Manager > Account > Page Layouts. | Page Layout | Medium | S |

---

## SECTION B: DEVELOPMENT TASKS (Programmatic / Custom Code)

*No development tasks are required for this story.*

This requirement is fully achievable through declarative configuration. A custom Text field on a standard object is a standard metadata operation supported entirely through Salesforce's declarative tooling (Object Manager / Salesforce DX metadata). There is no business logic, calculation, or UI complexity that would require Apex or LWC development.

**No Section B tasks are identified for SCRUM-7.**

---

## SECTION C: ARCHITECTURAL DECISIONS

- **Declarative-only approach:** A custom Text field on the standard Account object is a straightforward metadata change. No programmatic implementation is warranted. Classifying this as an admin-only story aligns with the Salesforce Well-Architected Framework principle of preferring configuration over code.

- **API name convention:** The field API name `Banking_Name__c` follows Salesforce naming conventions (PascalCase, underscore-separated words, `__c` suffix). This ensures consistency with the existing custom fields in the project (e.g., `Broker_Id__c`, `Mobile_Phone__c` on `Broker__c`).

- **Field type — Text vs. other types:** Text (length 255) is selected based on the explicit description in the story. If "Banking Name" ever needs to enforce a controlled vocabulary, it could be converted to a Picklist; however, free-text is appropriate for institution names which vary widely.

- **No namespace:** This project uses no namespace (confirmed in `sfdx-project.json`), so the field deploys with no namespace prefix.

- **Standard object handling:** The Account object folder (`force-app/main/default/objects/Account/`) does not currently exist in this project. The admin agent must create the folder structure alongside the field metadata file. Salesforce DX supports creating custom field files for standard objects using the same directory structure as custom objects.

- **Page layout:** Rather than modifying the page layout XML (which can be large and conflict-prone), it is preferable to add the field to the layout through Setup post-deployment, or to include the layout metadata only if a layout XML already exists in the project. Given no existing Account layout XML is present, the recommended approach is to add the field to the layout via Setup after deploying the field.

---

## Agent Prompts

### salesforce-admin Agent Prompt

```
You are the Salesforce Admin agent. Your task is to create custom field metadata for the Account object as specified in Jira story SCRUM-7.

PROJECT CONTEXT:
- Salesforce DX project at: C:\Users\2094003\OneDrive - Cognizant\Documents\Claude Code\Development\SFClaudeDem
- Source directory: force-app/main/default/
- API Version: 64.0
- No namespace

TASK: Create the following metadata file exactly as specified.

FILE TO CREATE:
Path: force-app/main/default/objects/Account/fields/Banking_Name__c.field-meta.xml

Content:
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Banking_Name__c</fullName>
    <label>Banking Name</label>
    <type>Text</type>
    <length>255</length>
    <required>false</required>
    <unique>false</unique>
    <externalId>false</externalId>
    <trackTrending>false</trackTrending>
    <trackFeedHistory>false</trackFeedHistory>
</CustomField>

IMPORTANT NOTES:
- The objects/Account/ directory does not currently exist in the project. You must create the full path: force-app/main/default/objects/Account/fields/
- This is a standard object (Account), not a custom object. Do NOT create an Account.object-meta.xml file — only the field file is needed.
- Do not modify any existing files.
- Do not create any Apex, LWC, or test files.
- After creating the file, confirm the path and content are correct.

ACCEPTANCE CRITERIA:
- File exists at force-app/main/default/objects/Account/fields/Banking_Name__c.field-meta.xml
- XML is valid and uses API version 64.0 namespace
- Field label is "Banking Name"
- Field type is Text with length 255
- Field is not required, not unique, not an external ID
```

### salesforce-developer Agent Prompt

```
No development work is required for Jira story SCRUM-7.

This story involves only a declarative custom field addition to the Account object (Banking_Name__c — Text, length 255). The salesforce-admin agent handles all required work for this story.

If future stories require Apex logic or LWC components that reference Account.Banking_Name__c, a new developer task will be scoped at that time.

STATUS: SKIP — no developer action needed for SCRUM-7.
```

---

*Document generated by salesforce-design-architect. Story source: SCRUM-7 (Jira). All requirements derived from the Jira story description and project conventions.*
