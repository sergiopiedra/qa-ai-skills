---
description: "Create a risk-based test plan for a software release: scope, risk assessment per change, test strategy, environments and data, schedule, entry/exit criteria, go/no-go checklist, rollback verification, and post-release monitoring. Use when asked for a release test plan, QA plan, regression plan, or test strategy for an upcoming version, sprint, or deployment."
argument-hint: "<release version + list of tickets/changes + date and team capacity>"
agent: agent
---

<!-- Generated from .claude/skills/release-test-plan/SKILL.md by scripts/sync-prompts.sh. Edit the source and re-run the script. -->

# Release Test Plan

Produce a test plan that can be executed: every change has a risk score, a test approach, and an owner, and the plan ends in a clear go/no-go decision.

## Inputs

| Input | Required | Notes |
|---|---|---|
| Release scope | Yes | Changelog, ticket or PR list, or release notes. In a workspace, you can read them from `git log`, a CHANGELOG, or exported tickets. |
| Release details | Recommended | Version, target date, deployment window and method (big bang, canary, feature flags). |
| Team & capacity | Recommended | Who is testing and how many days are available. |
| Environments | No | Staging/pre-prod details, data refreshes, third-party sandboxes, flag states. |
| Known risks & history | No | Recent incidents, defect-prone areas, flaky suites, cross-team dependencies. |
| Existing assets | No | Automated suites (scope and runtime), smoke tests, previous plans. |
| Constraints | No | Code freeze, compliance sign-offs, blackout periods. |

Where information is missing, make a reasonable assumption and list it in section 10. Don't stall.

## Instructions

1. **Inventory the changes.** Group them by product area. Classify each as New feature, Change, Bug fix, Dependency upgrade, Config/content, Infra, or Tech debt.
2. **Score the risk of each change**:
   - *Impact* (1–3): user reach, money, data integrity, security, compliance.
   - *Likelihood* (1–3): complexity, code churn, new technology, defect history, existing coverage.
   - *Score* = Impact × Likelihood: **High** 6–9, **Medium** 3–4, **Low** 1–2.
   - Add **indirect regression risks** as their own rows, for shared components touched by several changes, or areas with recent incidents.
3. **Choose the test approach by risk**:
   - **High**: dedicated scenario testing, a time-boxed exploratory session, automated regression of the area, and non-functional checks where relevant.
   - **Medium**: targeted scenarios plus automated regression of the area.
   - **Low**: verify the change; rely on the automated suite and smoke tests.
4. **Define the scope**: in scope, out of scope (each with a reason), and regression scope.
5. **Select non-functional testing only where the changes warrant it**: performance, security, accessibility, browser/device compatibility, localisation, data migration.
6. **Specify environments and test data**: environment, build, flag states, accounts, seed data, sandbox credentials (by reference, never the actual secrets).
7. **Set entry and exit criteria** that can be measured.
8. **Schedule highest risk first.** Fit the work to the stated capacity and keep about 20% buffer for retesting fixes. Name an owner per block.
9. **Write the go/no-go checklist** and name the decision makers.
10. **Plan deployment verification, rollback, and monitoring**: production smoke tests, how rollback works and whether it was rehearsed (are migrations reversible? are there flag kill-switches?), and which dashboards and metrics to watch, for how long, with thresholds.
11. **List risks to the plan itself** (environment instability, late tickets, dependency on another team) with mitigations, plus your assumptions.
12. **Keep it lean.** No generic filler: every line should change what someone does.

## Output format

```markdown
# Release test plan: <product> <version>

| Field | Value |
|---|---|
| Release | |
| Target date / window | |
| Deployment method | |
| Test window & capacity | |
| Plan owner | |
| Go/no-go decision by | |

## 1. Scope summary
## 2. Risk assessment
| ID | Change | Type | Impact | Likelihood | Score | Risk | Test approach | Owner |
## 3. Test strategy
## 4. In scope / out of scope
## 5. Environments & test data
## 6. Entry & exit criteria
## 7. Schedule
## 8. Go/no-go checklist
## 9. Deployment verification, rollback & monitoring
## 10. Risks to the plan & assumptions
```

## Example

**Input**

> ShopFront web 2.4.0 goes to production on Thursday 29 Oct 2026, 07:00. 2 testers (Ana, Luis), 4 days on staging starting Fri 23 Oct.
> Tickets: SF-101 discount codes at checkout (new); SF-115 payment SDK upgrade v3 → v4; SF-120 fix: order history pagination off by one; SF-122 new image carousel on the product page; SF-130 footer copy change.
> The last release had a production incident in checkout tax calculation. The automated regression suite takes about 45 min.

**Output**

# Release test plan: ShopFront web 2.4.0

| Field | Value |
|---|---|
| Release | ShopFront web 2.4.0 |
| Target date / window | Thu 29 Oct 2026, 07:00 |
| Deployment method | Standard deploy; SF-101 behind the `discount_codes` flag (assumption A1) |
| Test window & capacity | Fri 23 – Wed 28 Oct (4 working days), 2 testers |
| Plan owner | Ana |
| Go/no-go decision by | QA lead, product owner, engineering manager. Wed 28 Oct, 16:00 |

## 1. Scope summary
Five changes. Two are high risk and both touch checkout: the payment SDK upgrade and discount codes. Because checkout tax calculation caused the last incident, it is treated as a separate high-risk regression area.

## 2. Risk assessment
| ID | Change | Type | Impact | Likelihood | Score | Risk | Test approach | Owner |
|---|---|---|---|---|---|---|---|---|
| R1 | SF-115 Payment SDK v3 → v4 | Dependency upgrade | 3 | 3 | 9 | High | Payment matrix (cards, 3-D Secure, declines, refunds, saved cards), exploratory session, checkout regression | Ana |
| R2 | SF-101 Discount codes | New feature | 3 | 2 | 6 | High | Story test cases, combinations with tax and shipping, exploratory session, flag on/off | Luis |
| R3 | Checkout totals & tax (indirect, from R1 + R2, prior incident) | Regression | 3 | 2 | 6 | High | Tax matrix across 3 regions × discount × shipping; compare totals with 2.3.x | Luis |
| R4 | SF-122 Product page image carousel | New feature | 2 | 2 | 4 | Medium | Cross-browser and mobile checks, keyboard and screen-reader pass, page performance | Luis |
| R5 | SF-120 Order history pagination fix | Bug fix | 1 | 2 | 2 | Low | Verify the fix: first, last, and exact-multiple pages | Ana |
| R6 | SF-130 Footer copy | Content | 1 | 1 | 1 | Low | Visual check in all locales | Ana |

## 3. Test strategy
- **Functional:** scenario tests for R1–R3; verification for R5 and R6.
- **Exploratory:** two 90-minute sessions with charters "Pay with v4 under adverse conditions" (R1) and "Break discount and total calculation" (R2, R3).
- **Automated regression:** full suite (about 45 min) on day 1 and again on day 4 after fixes; failures are triaged the same day.
- **Non-functional:** carousel page performance (LCP ≤ 2.5 s on mid-range mobile), WCAG 2.2 AA spot check of the carousel, payment flows on Chrome, Safari, Firefox, iOS Safari, and Android Chrome.

## 4. In scope / out of scope
- **In scope:** R1–R6, checkout end to end, order history, product page.
- **Regression scope:** cart, checkout, order confirmation emails, refunds.
- **Out of scope:** load testing (no infrastructure changes, traffic is normal for the season); admin back office (untouched by this release).

## 5. Environments & test data
- Staging with build `2.4.0-rc.*`; `discount_codes` flag ON (with an OFF check on day 2).
- Payment provider sandbox with v4 keys. Test cards for success, decline, insufficient funds, and 3-D Secure challenge.
- Discount codes: active, expired, below-minimum, and expiring-today, seeded via the admin API.
- Accounts with 0, 10, and 25 orders, for pagination.

## 6. Entry & exit criteria
- **Entry:** rc build deployed to staging; all tickets dev-complete with unit tests; CI green; sandbox keys and test data ready.
- **Exit:** all High-risk scenarios executed and passed; no open S1/S2 defects; S3 defects have an agreed workaround and are logged; automated regression ≥ 98% pass with every failure triaged; carousel LCP within budget.

## 7. Schedule
| Day | Ana | Luis |
|---|---|---|
| Fri 23 | Entry check, smoke, start of automated regression; R1 payment matrix | R2 story test cases |
| Mon 26 | R1 3-D Secure, declines, refunds; R1 exploratory session | R3 tax matrix; R2 exploratory session; flag OFF check |
| Tue 27 | R5, R6; regression triage | R4 cross-browser, accessibility, performance |
| Wed 28 | Retest fixes; regression re-run; sign-off notes | Retest fixes; buffer; go/no-go at 16:00 |

## 8. Go/no-go checklist
- [ ] Exit criteria met (section 6)
- [ ] No open S1/S2; open S3 list reviewed by the product owner
- [ ] Rollback for the SDK upgrade rehearsed on staging
- [ ] `discount_codes` kill-switch verified (OFF hides the code field with no errors)
- [ ] On-call engineer and payment-provider contact confirmed for release morning

## 9. Deployment verification, rollback & monitoring
- **Production smoke test (07:15):** log in, search, product page carousel, add to cart, apply a test code, pay with a real low-value card, then refund.
- **Rollback:** redeploy 2.3.x if payments fail. SDK v4 has no database migrations (assumption A3). For discount issues, turn the flag OFF instead of rolling back.
- **Monitoring for 24 h:** payment success rate (alert if more than 2 points below the 7-day baseline), checkout 5xx rate, tax amount anomalies, front-end JS errors on the product page.

## 10. Risks to the plan & assumptions
| Risk | Mitigation |
|---|---|
| Payment sandbox instability blocks R1 | Start R1 on day 1; escalate to the provider contact early |
| Late fixes leave no time to retest | Code freeze Tue 27 at 12:00; only S1/S2 fixes after that |

- **A1.** Discount codes are released behind a feature flag.
- **A2.** The payment sandbox supports v4 test cards, including 3-D Secure.
- **A3.** The SDK upgrade includes no data migrations.
