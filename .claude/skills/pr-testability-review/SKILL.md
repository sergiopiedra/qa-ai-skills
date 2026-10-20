---
name: pr-testability-review
description: "Review a pull request from a QA perspective: check that every behaviour change is covered by meaningful tests, flag code that is hard to test, assess regression risk, and list the missing tests and manual QA checks. Use when asked to review a PR, diff, or branch for testability, test coverage, or QA readiness."
argument-hint: "<PR number/URL, branch, or pasted diff>"
---

# PR Testability Review

Answer one question: *if this change were broken, would our tests catch it?* Then make it easier for them to.

## Inputs

| Input | Required | Notes |
|---|---|---|
| Diff | Yes | PR URL or number, a branch, or a pasted diff. With tool access, fetch it, e.g. `gh pr diff <n>` / `gh pr view <n>`, or `git diff main...HEAD`. |
| PR description & linked story | Recommended | The intended behaviour and acceptance criteria. |
| Related existing tests | No | Test files for the touched modules. In a workspace, search for them. |
| Team conventions | No | Coverage thresholds, test pyramid, selector conventions (`data-testid`), definition of done. |

## Instructions

1. **Understand the intent.** Summarise in one or two sentences what behaviour changes. If the description and the diff disagree, flag it.
2. **Map the behaviour changes**: new code paths, changed conditions, new errors, data or schema changes, configuration and feature flags, UI elements, and API contract changes. For pure refactors, check that they really preserve behaviour.
3. **Match tests to the changes.** For each behaviour change, find the test, in the diff or in the existing suite, that would *fail if the change were reverted or broken*. Mark it Covered, Partial, or Not covered.
4. **Evaluate test quality**:
   - Meaningful assertions, not "doesn't throw" or giant snapshots.
   - Negative and boundary paths are covered.
   - The test is at the right level (unit, integration, or end-to-end).
   - Deterministic: no sleeps, real clocks, live network, or order dependence.
   - Names describe the behaviour under test.
5. **Look for testability smells in the production code**:

   | Smell | Why it hurts | Suggestion |
   |---|---|---|
   | Hidden dependencies (`new` inside logic, imported singletons, static calls) | Can't substitute fakes; forces heavy mocking or a real database | Inject collaborators (constructor or parameter) |
   | Non-determinism (`new Date()`, `Date.now()`, `Math.random()`, inline UUIDs) | Boundaries can't be tested reliably | Inject a clock or ID/random provider |
   | Logic mixed with I/O | Rules can only be tested end-to-end | Extract a pure function for the rule |
   | Swallowed or generic errors | Failure paths can't be asserted | Typed or coded errors; explicit handling |
   | External calls without a seam (HTTP, queues, payments) | Tests hit real services or can't run at all | An adapter or interface at the boundary |
   | New UI without stable selectors or accessible names | Brittle end-to-end tests | Accessible roles and names, or `data-testid` per team convention |
   | Feature flag with only one path tested | The other path ships untested | Test both flag states |
   | Migration or contract change without compatibility tests | Breaks existing data or consumers | Migration and rollback tests; consumer or contract tests |
   | New failure mode with no logging or metrics | Can't be diagnosed in production | Structured log or metric at the failure point |

6. **Rate the risk** as Low, Medium, or High, based on blast radius (users, money, data, security), complexity, and how much of the change is untested.
7. **Recommend concrete actions.** Name each missing test, its level, and what it should assert. Give the smallest production-code change that makes the code testable. List manual exploratory checks for anything automation won't cover. Point to `file:line`.
8. **Give a verdict**:
   - ✅ **Ready**
   - ⚠️ **Ready with suggestions**
   - ❌ **Needs tests before merge**: only when high-risk behaviour is uncovered.

   Be constructive and prioritised, and leave style nitpicks to linters.

## Output format

```markdown
## PR testability review: <title or #number>

**Verdict:** ✅ Ready | ⚠️ Ready with suggestions | ❌ Needs tests before merge
**Risk:** Low | Medium | High (<one-line reason>)
**Summary:** <what the PR changes, in 1–2 sentences>

### Behaviour changes & coverage
| # | Change | Location | Covered by | Status |

### Findings
| # | Severity | Location | Finding | Suggestion |
(Severity: Blocking / Should fix / Nit)

### Missing tests
- [ ] <test name> (<level>): <what it asserts>

### Manual QA checklist
- [ ] …

### Questions for the author
- …
```

## Example

**Input**

> PR #482 "Validate discount codes": rejects expired codes and enforces a $20 minimum subtotal.
>
> ```diff
> --- a/src/discounts/applyCode.ts
> +++ b/src/discounts/applyCode.ts
> @@ -1,10 +1,12 @@
>  import { db } from '../db';
>
>  export async function applyCode(cartId: string, code: string) {
> -  const discount = await db.discounts.findByCode(code);
> +  const discount = await db.discounts.findByCode(code.trim().toUpperCase());
>    if (!discount) throw new Error('INVALID_CODE');
> +  if (discount.expiresAt < new Date()) throw new Error('EXPIRED_CODE');
>    const cart = await db.carts.get(cartId);
> +  if (cart.subtotal < 20) throw new Error('MIN_SUBTOTAL');
>    cart.discount = cart.subtotal * discount.percent / 100;
>    await db.carts.save(cart);
>    return cart;
>  }
> --- a/test/applyCode.test.ts
> +++ b/test/applyCode.test.ts
> @@ -25,0 +26,4 @@
> +it('rejects expired codes', async () => {
> +  await seedDiscount({ code: 'OLD', percent: 10, expiresAt: new Date('2020-01-01') });
> +  await expect(applyCode(cartId, 'OLD')).rejects.toThrow('EXPIRED_CODE');
> +});
> ```

**Output**

## PR testability review: #482 Validate discount codes

**Verdict:** ❌ Needs tests before merge
**Risk:** High (changes money calculation at checkout; one of the three new behaviours is tested)
**Summary:** Adds code normalisation (trim + upper-case), rejects expired codes, and enforces a $20 minimum subtotal when applying a discount.

### Behaviour changes & coverage
| # | Change | Location | Covered by | Status |
|---|---|---|---|---|
| 1 | Codes are trimmed and upper-cased before lookup | `src/discounts/applyCode.ts:4` | — | Not covered |
| 2 | Expired codes throw `EXPIRED_CODE` | `src/discounts/applyCode.ts:6` | `rejects expired codes` | Partial: far-past date only; no boundary at "now" |
| 3 | Subtotal below $20 throws `MIN_SUBTOTAL` | `src/discounts/applyCode.ts:8` | — | Not covered |

### Findings
| # | Severity | Location | Finding | Suggestion |
|---|---|---|---|---|
| 1 | Blocking | `applyCode.ts:8` | The new minimum-subtotal rule has no test; an off-by-one (`<` vs `<=`) would ship unnoticed | Add boundary tests at 19.99 and 20.00 |
| 2 | Blocking | `applyCode.ts:6` | `new Date()` inline makes the expiry boundary untestable without global time mocking | Accept `now: Date = new Date()` as a parameter, or inject a clock |
| 3 | Should fix | `applyCode.ts:4` | Normalisation is untested; a regression would reject `save10` or `" SAVE10 "` | Add a case-insensitivity and whitespace test |
| 4 | Should fix | `applyCode.ts:1` | The imported `db` singleton forces tests through a real or seeded database | Pass a repository (`{ discounts, carts }`) as a dependency to allow fast unit tests |
| 5 | Should fix | `applyCode.ts:9` | Floating-point money maths: `33.35 * 10 / 100` stores `3.335` (fractional cents), and downstream rounding is inconsistent: `toFixed(2)` gives `3.33`, `Math.round(x * 100) / 100` gives `3.34` | Compute in integer cents with an explicit rounding rule; add a rounding test |
| 6 | Nit | `applyCode.ts:8` | Magic number `20` | Named constant or configuration value |

### Missing tests
- [ ] `rejects subtotal of 19.99 with MIN_SUBTOTAL` (unit)
- [ ] `accepts subtotal of exactly 20.00` (unit): discount applied
- [ ] `accepts a code expiring later today` and `rejects a code that expired one second ago` (unit, with injected `now`)
- [ ] `normalises lowercase and padded codes` (unit): `" save10 "` finds `SAVE10`
- [ ] `rounds the discount to the cent` (unit): 33.35 at 10% → 3.34 (rule to be confirmed)
- [ ] `does not modify the cart when validation fails` (integration): the cart is unchanged after each error

### Manual QA checklist
- [ ] The checkout UI shows a specific, user-friendly message for each new error code (not a generic failure).
- [ ] Removing items so the subtotal drops below $20 after a code is applied: what happens? (Not handled in this PR.)
- [ ] Code expiry around midnight in the store's time zone.

### Questions for the author
- Is `expiresAt` stored in UTC, and is "expired" meant to be inclusive of the expiry instant?
- When a code is both expired and below the minimum, which error should win? (Currently: expired.)
- Should the $20 minimum be per-code configuration rather than global?
