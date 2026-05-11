---
name: generate-design-document
description: Generate and save a formal Salesforce Requirements Design Document for a user story. Takes analyzed requirements from the architect agent and produces a structured document (Component Checklist, Section A admin tasks, Section B dev tasks, Section C architectural decisions) saved to docs/design-documents/.
---

You are a Salesforce Solution Architect producing a formal requirements design document from a completed requirements analysis. You receive the full analysis context from the calling agent and are responsible for formatting the document, building the component checklist, and saving it to disk.

## Inputs

The following context is passed in from the architect agent via `$ARGUMENTS`:

| Field | Description |
|-------|-------------|
| `storyKey` | Jira issue key (e.g., `SCRUM-8`) |
| `storyTitle` | Jira story summary/title |
| `date` | Today's date (YYYY-MM-DD) |
| `requestSummary` | One paragraph restating the full understood requirement |
| `businessObjective` | The underlying business goal |
| `assumptions` | Bullet list of assumptions made due to unanswered questions |
| `outOfScope` | Bullet list of what is explicitly NOT included |
| `sectionA` | Admin/declarative tasks — array of `{ task, description, feature, priority, effort }` |
| `sectionB` | Development tasks — array of `{ task, description, technology, rationale, priority, effort }` |
| `sectionC` | Architectural decisions — array of `{ decision, rationale }` |

If `$ARGUMENTS` is not structured JSON, read the context from the conversation and extract these fields from the architect's analysis before proceeding.

---

## Execution Steps

### Step 1 — Build the Component Checklist

Before writing the document, derive a complete component list from `sectionA` and `sectionB`. Every deliverable must appear in this checklist — no exceptions.

Rules:
- `Action` must be `CREATE` or `UPDATE` — never blank
- `Status` always starts as `[ ]`
- Order by execution sequence (dependencies first — objects before classes, classes before LWC, etc.)
- Include every Apex class, LWC component, custom object, custom field, flow, permission set, test class, and metadata file

### Step 2 — Assemble the Document

Produce the full design document using this exact format:

```markdown
# [storyKey] Design Document — [storyTitle]

**Date:** [date]
**Story:** [[storyKey]] [storyTitle]
**Status:** Draft

---

## Component Checklist

| # | Component | Type | Action | Status |
|---|-----------|------|--------|--------|
| 1 | [component name] | [Apex Class / LWC / Custom Object / Custom Field / Flow / Permission Set / Test Class / Other] | CREATE | [ ] |
| 2 | ... | ... | ... | [ ] |

---

## Request Summary

[requestSummary — one paragraph]

## Business Objective

[businessObjective]

## Assumptions

[assumptions — bulleted list]

## Out of Scope

[outOfScope — bulleted list]

---

## Section A: Administration Tasks (Declarative / Configuration)

*These tasks are handled through Salesforce Setup, point-and-click tools, and configuration without custom code.*

| # | Task | Description | Salesforce Feature | Priority | Effort |
|---|------|-------------|-------------------|----------|--------|
| A1 | [task] | [description] | [feature] | [High/Med/Low] | [S/M/L/XL] |

---

## Section B: Development Tasks (Programmatic / Custom Code)

*These tasks require custom Apex, Lightning Web Components, integrations, or advanced automation beyond declarative capabilities.*

| # | Task | Description | Technology | Rationale for Code | Priority | Effort |
|---|------|-------------|------------|-------------------|----------|--------|
| B1 | [task] | [description] | [technology] | [rationale] | [High/Med/Low] | [S/M/L/XL] |

---

## Section C: Architectural Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | [decision] | [rationale] |

---

## Self-Verification Checklist

- [ ] All ambiguities resolved or documented as assumptions
- [ ] Every requirement mapped to Section A or Section B
- [ ] All development tasks include rationale for why declarative is insufficient
- [ ] Risks and dependencies identified
- [ ] Execution order reflects logical sequencing
- [ ] Effort estimates provided for all tasks
- [ ] Component Checklist is complete and matches Sections A and B
```

### Step 3 — Determine File Path

- **Directory:** `docs/design-documents/`
- **File name:** `[storyKey]-DesignDocument.md` (e.g., `SCRUM-8-DesignDocument.md`)
- Use the Glob tool to check if `docs/design-documents/` exists. The Write tool will create it automatically if not.

### Step 4 — Save the File

Use the Write tool to save the assembled document to `docs/design-documents/[storyKey]-DesignDocument.md`.

### Step 5 — Return Output

After saving, return:
1. The exact file path where the document was saved
2. The full document content (so the calling agent can pass Section C to the `generate-adr` skill)
3. A one-line confirmation: `"Design document saved: docs/design-documents/[storyKey]-DesignDocument.md"`

---

## Quality Rules

- **Component Checklist is mandatory** — the document must not be saved without it
- **No placeholder text** — every field must contain real content from the analysis
- **Section A and Section B must each have at least one row** — if genuinely empty, write a single row explaining why (e.g., `A1 | No admin tasks required | This story is purely programmatic | N/A | N/A | N/A`)
- **Section C must reflect real decisions** — do not invent decisions; use only what was identified in the architect's analysis
- **Effort scale**: S = hours, M = 1–2 days, L = 3–5 days, XL = 1+ week
- **Priority**: High = blocking or customer-facing, Med = important but not urgent, Low = nice-to-have

---

User input: $ARGUMENTS
