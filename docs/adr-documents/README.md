# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) generated automatically by the `salesforce-design-architect` agent during the design phase of each user story.

## File Naming Convention

```
ADR-[STORY-KEY]-[NNN]-[decision-slug].md
```

| Segment | Description | Example |
|---------|-------------|---------|
| `STORY-KEY` | Jira issue key | `SCRUM-8` |
| `NNN` | Zero-padded sequence per story | `001`, `002` |
| `decision-slug` | Kebab-case decision title (max 5 words) | `communication-pattern-lms` |

**Example filenames:**
- `ADR-SCRUM-8-001-communication-pattern-lms.md`
- `ADR-SCRUM-8-002-data-model-custom-object.md`
- `ADR-SCRUM-9-001-automation-apex-over-flow.md`

## ADR Lifecycle

| Status | Meaning |
|--------|---------|
| `Accepted` | Decision is active and in use |
| `Deprecated` | Decision was valid but is no longer relevant |
| `Superseded` | Replaced by a newer ADR (link to replacement) |

## Index

ADR files are added here automatically. One or more ADRs are generated per user story, one per significant architectural decision.
