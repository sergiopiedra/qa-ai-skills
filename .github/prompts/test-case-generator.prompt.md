---
description: "Generate positive, negative, and edge-case test cases from a user story or acceptance criteria, returned as a traceable Markdown table. Use when asked to write test cases, test scenarios, or a test suite for a story, ticket, or feature."
argument-hint: "<user story + acceptance criteria, or a ticket file>"
agent: agent
---

<!-- Generated from .claude/skills/test-case-generator/SKILL.md by scripts/sync-prompts.sh. Edit the source and re-run the script. -->

# Test Case Generator

Turn a user story into test cases that a tester can run without asking questions. Every case traces back to an acceptance criterion.

## Inputs

| Input | Required | Notes |
|---|---|---|
| User story | Yes | "As a … I want … so that …", or a plain feature description. Pasted text, a selected file, or a ticket export. |
| Acceptance criteria | Recommended | Gherkin, bullets, or prose. If missing, derive them from the story and label them *inferred*. |
| Business rules / constraints | No | Limits, formats, roles, states, integrations. |
| Platform & scope | No | Web, mobile, API; anything explicitly out of scope. |
| Format override | No | e.g. Gherkin instead of a table, or CSV for import into a test management tool. |

If the story has no observable outcome, ask up to three targeted questions before generating. Otherwise, proceed and record your assumptions.

## Instructions

1. **Parse the story.** Identify the actor(s), the action, the observable outcome, and every acceptance criterion. Number criteria AC1, AC2, … (keep the original numbering if there is one).
2. **Extract testable variables.** For each input, state, or rule, note its valid classes, invalid classes, and boundaries (min, max, just inside, just outside, empty, null).
3. **Apply test design techniques** where they fit:
   - *Equivalence partitioning*: one case per valid and invalid class.
   - *Boundary value analysis*: on every numeric, length, date, or count limit.
   - *Decision table*: when two or more conditions combine to change the outcome.
   - *State transition*: when the feature has states (e.g. draft → submitted → approved).
   - *Error guessing*: double submit, back button, session expiry, concurrent edits, special characters, localisation, time zones.
4. **Write the cases.**
   - **Positive**: every AC has at least one happy-path case.
   - **Negative**: every validation and business rule has at least one case that violates it, and the expected result states the exact error behaviour.
   - **Edge**: boundaries, empty or maximum data, unusual-but-valid combinations, permissions.
5. **Make each case atomic and deterministic.** One behaviour per case. Use concrete test data, never "enter a valid value". The expected result must be observable: UI text, a state change, an HTTP status, or a stored record.
6. **Prioritise.** P1 = core happy path, or a risk to money, data, or security. P2 = important rule or common error. P3 = rare edge or cosmetic.
7. **Check coverage.** Build the traceability summary. Every AC maps to at least one case. Flag any AC you could not cover and explain why.
8. **List assumptions and open questions** wherever the story was silent. Reference them from the affected cases (e.g. "see Q2").

## Output format

Return Markdown with these three sections, in order:

1. `### Test cases`: one table.

   | ID | Title | Type | Priority | AC | Preconditions | Steps | Test data | Expected result |
   |---|---|---|---|---|---|---|---|---|

   - ID: `TC-001`, `TC-002`, …
   - Type: `Positive`, `Negative`, or `Edge`.
   - Steps: numbered, separated by `<br>` so the table renders.
2. `### Coverage summary`: a table of AC → test case IDs, followed by counts by type.
3. `### Assumptions & open questions`: numbered `Q1`, `Q2`, …

If the user asks for Gherkin or CSV, keep the same IDs and fields in that format.

## Example

**Input**

> As a shopper, I want to apply a discount code at checkout so that I pay less.
> - AC1: A valid code reduces the order subtotal by the code's percentage.
> - AC2: An expired code shows "This code has expired" and the total is unchanged.
> - AC3: Only one code can be applied per order.
> - Rules: codes require a minimum subtotal of $20.00; codes are case-insensitive.

**Output**

### Test cases

| ID | Title | Type | Priority | AC | Preconditions | Steps | Test data | Expected result |
|---|---|---|---|---|---|---|---|---|
| TC-001 | Valid code applies percentage discount | Positive | P1 | AC1 | Subtotal $50.00; code `SAVE10` (10%) active | 1. Open checkout<br>2. Enter code<br>3. Click **Apply** | `SAVE10` | Discount line −$5.00; total $45.00; success message shown |
| TC-002 | Code is case-insensitive | Positive | P2 | AC1 | As TC-001 | 1. Enter code in lowercase<br>2. Click **Apply** | `save10` | Same result as TC-001 |
| TC-003 | Expired code is rejected | Negative | P1 | AC2 | Subtotal $50.00; `OLD20` expired yesterday | 1. Enter code<br>2. Click **Apply** | `OLD20` | Error "This code has expired"; total stays $50.00 |
| TC-004 | Unknown code is rejected | Negative | P2 | AC1 | Subtotal $50.00 | 1. Enter code<br>2. Click **Apply** | `NOPE99` | Error "Invalid code" (see Q1); total unchanged |
| TC-005 | Second code cannot be added | Negative | P1 | AC3 | `SAVE10` applied; `FREESHIP` active | 1. Enter second code<br>2. Click **Apply** | `FREESHIP` | Second code rejected (see Q2); only the `SAVE10` discount line is shown |
| TC-006 | Subtotal exactly at minimum | Edge | P1 | AC1 | Subtotal $20.00 | 1. Enter code<br>2. Click **Apply** | `SAVE10` | Discount −$2.00; total $18.00 |
| TC-007 | Subtotal one cent below minimum | Edge | P1 | AC1 | Subtotal $19.99 | 1. Enter code<br>2. Click **Apply** | `SAVE10` | Minimum-spend error (see Q1); total $19.99 |
| TC-008 | Cart drops below minimum after code applied | Edge | P2 | AC1 | `SAVE10` applied on $25.00 cart ($10.00 + $15.00 items) | 1. Remove the $10.00 item | — | Discount removed and minimum-spend message shown (see Q3); total $15.00 |
| TC-009 | Code with surrounding whitespace | Edge | P3 | AC1 | Subtotal $50.00 | 1. Paste code with spaces<br>2. Click **Apply** | `␣␣SAVE10␣␣` | Code trimmed and applied; total $45.00 |
| TC-010 | Empty code field | Negative | P3 | AC1 | Subtotal $50.00 | 1. Leave field empty<br>2. Click **Apply** | (empty) | Apply is disabled or shows "Enter a code"; no discount request sent |
| TC-011 | Code on its last valid day | Edge | P2 | AC2 | `ENDSTODAY` expires today 23:59 store time | 1. Enter code<br>2. Click **Apply** | `ENDSTODAY` | Discount applied (see Q5) |
| TC-012 | Discount rounding to the cent | Edge | P2 | AC1 | Subtotal $33.35 | 1. Enter code<br>2. Click **Apply** | `SAVE10` | Discount −$3.34 (half-up, see Q4); total $30.01 |

### Coverage summary

| AC | Test cases |
|---|---|
| AC1 | TC-001, TC-002, TC-004, TC-006, TC-007, TC-008, TC-009, TC-010, TC-012 |
| AC2 | TC-003, TC-011 |
| AC3 | TC-005 |

Totals: 12 cases (2 positive, 4 negative, 6 edge); 6 P1, 4 P2, 2 P3.

### Assumptions & open questions

- **Q1.** The error copy for unknown codes and for the minimum spend isn't specified. Assumed "Invalid code" and "Spend $20.00 or more to use this code".
- **Q2.** AC3: should a second code be rejected, or replace the first? Assumed rejected.
- **Q3.** What happens when the cart drops below the minimum after a code is applied? Assumed the discount is removed with a message.
- **Q4.** What is the rounding rule for percentage discounts? Assumed half-up to the cent.
- **Q5.** Is expiry evaluated in the store's time zone or the shopper's?
