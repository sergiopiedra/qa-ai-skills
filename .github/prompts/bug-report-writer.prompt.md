---
description: "Turn rough notes, logs, chat messages, or screenshots into a clear, reproducible bug report with steps to reproduce, expected vs actual results, severity, and environment. Use when asked to write, file, clean up, or improve a bug report, defect, or issue."
argument-hint: "<what happened: notes, logs, error text, screenshot>"
agent: agent
---

<!-- Generated from .claude/skills/bug-report-writer/SKILL.md by scripts/sync-prompts.sh. Edit the source and re-run the script. -->

# Bug Report Writer

Turn an observation into a bug report that a developer can reproduce on the first try, and that a triager can prioritise without a follow-up conversation.

## Inputs

| Input | Required | Notes |
|---|---|---|
| Observation | Yes | Free-form notes, a chat message, an error text, or a screenshot description. |
| Environment | Recommended | App version/build, environment (dev/staging/prod), OS, browser or device, account role. |
| Evidence | No | Logs, console output, network requests (HAR), screenshots, video, request/correlation IDs. |
| Frequency | No | How many times it reproduced out of how many attempts. |
| Tracker | No | Jira, GitHub Issues, Azure DevOps, etc. Adjust field names and markup to match. |

## Instructions

1. **Extract the facts.** What was done, what happened, what should have happened, where, and when. Keep facts separate from guesses.
2. **Never invent details.** If steps, the expected result, or the environment are missing and can't be inferred, ask up to three questions, or insert a visible `TODO:` placeholder.
3. **Write the title** as `[Area] <Symptom> when <Condition>`. Keep it under 80 characters. Avoid vague words like "broken", "doesn't work", or "bug".
4. **Write the steps to reproduce** from a known starting state:
   - List preconditions separately: account, data, feature flags, cart contents.
   - One action per step, with concrete data.
   - Stop at the step where the failure appears.
5. **State expected vs actual.**
   - *Expected* cites its source: an acceptance criterion, the spec, previous behaviour, or a platform convention.
   - *Actual* describes the observable symptom exactly. Quote error text verbatim and include status codes.
6. **Assess severity** (technical impact) separately from **priority** (business urgency). Justify severity in one sentence. Give priority as a *suggestion*, because the product owner decides it.

   | Severity | Definition |
   |---|---|
   | S1 Critical | Crash, data loss or corruption, security exposure, payment failure, or a core flow blocked with no workaround. |
   | S2 Major | A core feature is broken or wrong for many users; the workaround is painful or doesn't exist. |
   | S3 Moderate | A feature is partially broken, a reasonable workaround exists, or only a secondary flow is affected. |
   | S4 Minor | Cosmetic, copy, or layout issue with no functional impact. |

7. **Record the environment**: build/version/commit, environment and URL, OS and version, browser or device and version, account role, feature flags, locale/time zone, and network conditions if relevant.
8. **Curate the evidence.** Trim logs to the relevant lines and keep their timestamps. Include request or correlation IDs. List attachments by name.
9. **State reproducibility**: Always, Intermittent (x/y attempts), or Once.
10. **Describe impact and workaround**: who is affected, how many, and what they can do instead.
11. **Redact** tokens, passwords, API keys, session cookies, and personal data. Replace them with `[REDACTED]`.
12. **Put hypotheses under Notes**, clearly labelled. Link related tickets or recent changes there.

## Output format

```markdown
**Title:** [Area] <Symptom> when <Condition>

**Severity:** S<n> <Name> (<one-sentence justification>)
**Suggested priority:** P<n>
**Reproducibility:** Always | Intermittent (x/y) | Once

### Environment
| Field | Value |
|---|---|
| Build / version | |
| Environment / URL | |
| OS | |
| Browser / device | |
| Account / role | |
| Feature flags | |

### Preconditions
- …

### Steps to reproduce
1. …

### Expected result
…

### Actual result
…

### Evidence
- …

### Impact & workaround
…

### Notes
- …
```

## Example

**Input**

> hey, checkout broke on staging again. tried paying with saved visa and it spun forever then said "Something went wrong". chrome on my mac. worked fine yesterday. happened 3 out of 4 times. console had a 502 on /api/payments/intent. my user is qa.buyer2@shop.example token eyJhbGciOiJIUzI1NiJ9.abc…

**Output**

**Title:** [Checkout] Payment with saved card fails with "Something went wrong" (502 on payment intent)

**Severity:** S1 Critical (payment fails in the core checkout flow and no workaround is confirmed)
**Suggested priority:** P1 (blocks release testing of checkout)
**Reproducibility:** Intermittent (3/4 attempts)

### Environment
| Field | Value |
|---|---|
| Build / version | TODO: staging build number |
| Environment / URL | Staging, `https://staging.shop.example/checkout` (TODO: confirm URL) |
| OS | macOS (TODO: version) |
| Browser / device | Chrome (TODO: version) |
| Account / role | Test buyer account `qa.buyer2@shop.example` |
| Feature flags | TODO |

### Preconditions
- Logged in as `qa.buyer2@shop.example`, with a saved Visa card on the account.
- At least one item in the cart.

### Steps to reproduce
1. Go to **Cart** and click **Checkout**.
2. On the payment step, select the saved Visa card.
3. Click **Pay now**.

### Expected result
The payment is authorised and the order confirmation page is displayed (this worked on staging the previous day).

### Actual result
The spinner is shown for a long time (TODO: approximate seconds), then the error "Something went wrong" is displayed. No order is created (TODO: confirm in order history). The browser console shows `502 Bad Gateway` for `POST /api/payments/intent`.

### Evidence
- Console: `POST /api/payments/intent 502` (TODO: attach HAR and the request ID from the response headers)
- TODO: screenshot of the error state

### Impact & workaround
Users paying with a saved card can't complete checkout. Workaround unknown. TODO: check whether paying with a newly entered card succeeds. If it does, consider downgrading to S2.

### Notes
- Hypothesis (unverified): the 502 suggests the payment service or its upstream gateway is unavailable or timing out on staging, rather than a frontend issue.
- "Worked fine yesterday": check staging deployments from the last 24 h.
- The session token from the original note has been removed. Don't paste tokens into tickets.
