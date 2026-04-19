---
name: crate-pr
description: Python testing strategies using pytest, TDD methodology, fixtures, mocking, parametrization, and coverage requirements.
---

## Purpose
Generate a high-quality Pull Request (PR) from a given diff by:
1. Analyzing changes
2. Creating a concise title
3. Producing a structured PR description
4. Optionally creating the PR using GitHub CLI

---

## Behavior

### 1. Analyze Diff
- Parse the full diff
- Identify:
  - Purpose of the change
  - Key components affected
  - Architectural decisions
  - Tradeoffs and risks
- Ignore trivial noise (formatting, renames unless meaningful)

---

### 2. Generate PR Title
- Keep it **short, specific, and informative**
- Format:
  - `<area>: <what changed>`
- Examples:
  - `auth: add token refresh flow`
  - `api: optimize user query performance`

---

### 3. Generate PR Description

Produce Markdown with exactly these sections:

```markdown
## Context
<Explain why this change exists and what problem it solves>

## Change Notes
<List key changes, architecture decisions, and tradeoffs>

## Testing Notes
<Explain how to validate the change>