---
name: flaky-test-triage
description: "Diagnose a flaky (intermittently failing) automated test: classify the likely root cause from logs, CI history, and test code, propose a reproduction strategy and a concrete fix, and decide whether to quarantine it. Use when a test passes and fails without code changes, or when asked to triage, debug, or stabilise flaky tests."
argument-hint: "<test name or file + failure logs / CI history>"
---

# Flaky Test Triage

Find out *why* a test is nondeterministic, prove it, and fix the cause instead of masking it with retries or longer timeouts.

## Inputs

| Input | Required | Notes |
|---|---|---|
| Test identifier and code | Yes | Test file, test name, and any helpers, fixtures, or page objects it uses. In a workspace, read them directly. |
| Failure output | Yes | Error message, stack trace, logs, and screenshots or traces. Ideally one failing run *and* one passing run. |
| CI history | Recommended | Pass/fail rate, runner/OS, shard or worker, retries, dates, and the commit SHAs of failing runs. |
| Runner configuration | No | Framework and version, parallel workers, retries, timeouts, test order settings. |
| Recent changes | No | Product or test changes around when the flakiness started. |

## Instructions

1. **Confirm it is flaky, not broken.** Flaky means both outcomes occur on the *same* commit and environment. If the test fails consistently since a specific commit, it's a regression: say so and stop.
2. **Group the failure signatures** by error message and failing line. Several distinct signatures usually mean several problems; triage each one separately.
3. **Read the test, its helpers, and the code under test** for these smells:

   | Category | Smells | Typical fix |
   |---|---|---|
   | Async / timing | Fixed sleeps, assertions that don't auto-wait, un-awaited promises, racing animations or transient UI | Wait for a specific condition (web-first assertions, response waits); await everything |
   | Shared state / order dependence | Depends on data left by another test, global singletons, shared accounts, leaked mocks | Isolate data per test; reset state in hooks; one account per worker |
   | Data collisions in parallel runs | Hard-coded IDs, emails, or names that hit unique constraints | Generate unique data per test or worker |
   | Time & date | `now()`, time zones, DST, midnight or month-end, expiry windows | Inject a clock or use fake timers; pin the TZ |
   | Randomness & ordering | Unseeded random, unordered collections, queries without `ORDER BY` | Seed; sort before comparing |
   | Selectors / UI | Generated IDs, `nth-child`, text that changes, element re-rendered or detached | Role, label, or test-id locators; re-query after navigation |
   | External dependencies | Third-party APIs, email, payment sandboxes, feature-flag services | Stub at the boundary; cover the real integration with contract tests |
   | Environment / infra | Slow or overloaded runners, container start-up, resource limits, DNS | Readiness checks before the suite; right-size resources |
   | Resource leaks | Unclosed connections, browser contexts, ports, file handles | Proper teardown |
   | Real product race | The app itself is nondeterministic (double submit, out-of-order responses) | File a product bug: the test is doing its job |

4. **Correlate with metadata.** Does it fail only on one shard, worker, OS, or browser? At certain times of day? Only after a specific test? Only on the first attempt?
5. **Rank hypotheses** with the evidence for each and a confidence level (High, Medium, or Low). Don't claim certainty without evidence. If the data is insufficient, say exactly what to collect, for example "enable trace on first retry".
6. **Give a reproduction plan** with exact commands. Raise contention to expose timing issues, and change test order to expose state leaks. Examples:
   - Playwright: `npx playwright test path/to.spec.ts -g "name" --repeat-each=50 --workers=4 --retries=0`
   - Jest: `npx jest path/to.test.ts -t "name"`, run in a shell loop; compare with `--runInBand`
   - pytest: `pytest path::test_name --count=50` (pytest-repeat); `-p randomly` (pytest-randomly) for order
   - JUnit 5: `@RepeatedTest(50)`
   - Add CPU pressure with, for example, `docker run --cpus=1 …`, or run the test next to the suspected polluting test only.
7. **Propose a fix** for the top hypothesis as a code diff, and explain why it removes the nondeterminism. Raising timeouts or adding retries is *not* a fix, unless the root cause really is slow infrastructure; if so, say that explicitly.
8. **Decide about quarantine.** Quarantine only if the test blocks the pipeline and the fix isn't immediate. A quarantine needs a ticket, an owner, and an expiry date, and the test should keep running in a non-blocking job. Never quarantine a test that may be catching a real product bug.
9. **Define verification**: for example, 100 consecutive runs with CI-like parallelism and 0 failures, then monitor the CI pass rate for a week.
10. **Suggest prevention**: a lint rule, a helper, or a convention that stops this class of flakiness from recurring.

## Output format

```markdown
## Flaky test triage: <test name>

**Verdict:** Flaky (<category>, <confidence> confidence) | Not flaky (regression since <commit>) | Inconclusive (need <data>)
**Observed failure rate:** <x/y runs> (<where>)

### Failure signatures
| # | Signature | Occurrences | Notes |

### Root-cause hypotheses
| # | Hypothesis | Category | Evidence | Confidence |

### Reproduce
<commands>

### Fix
<diff + explanation>

### Quarantine decision
<yes/no + ticket, owner, expiry>

### Verify
<criteria>

### Prevent
<bullets>
```

## Example

**Input**

> `checkout.spec.ts › shows confirmation after placing order` fails in CI about 6 times in 80 runs (4 workers, Linux). It never fails locally.
> Error: `expect(locator).toBeVisible() failed. Locator: getByText('Order placed'). Timeout: 5000ms. Error: element(s) not found.`
> The trace shows the toast rendered about 1.2 s after the click and disappeared about 3 s later.
>
> ```ts
> test('shows confirmation after placing order', async ({ page }) => {
>   await page.goto('/checkout');
>   await page.getByRole('button', { name: 'Place order' }).click();
>   await page.waitForTimeout(2000);
>   await page.waitForLoadState('networkidle');
>   await expect(page.getByText('Order placed')).toBeVisible();
> });
> ```

**Output**

## Flaky test triage: checkout.spec.ts › shows confirmation after placing order

**Verdict:** Flaky (async/timing, assertion on transient UI), High confidence
**Observed failure rate:** 6/80 (7.5%), CI only, 4 workers

### Failure signatures
| # | Signature | Occurrences | Notes |
|---|---|---|---|
| 1 | `getByText('Order placed')` not found after 5000 ms | 6/6 | The trace shows the toast *did* render, then auto-dismissed before the assertion ran |

### Root-cause hypotheses
| # | Hypothesis | Category | Evidence | Confidence |
|---|---|---|---|---|
| 1 | The toast auto-dismisses after ~3 s. The fixed 2 s sleep plus `networkidle` (which waits for analytics beacons and polling) often exceeds that window on loaded CI runners, so the assertion starts after the toast has gone. | Async / timing | The trace shows the toast appear and disappear before the assertion. CI only. `networkidle` duration varies with background requests. | High |
| 2 | Parallel workers share one test user, so the cart is occasionally emptied by another test and the order fails. | Shared state | No error state visible in the failing traces; the order API returned 201 in all failures checked | Low |

### Reproduce
```bash
npx playwright test checkout.spec.ts -g "shows confirmation" --repeat-each=50 --workers=4 --retries=0
# Locally, add CPU contention to mimic CI:
docker run --rm --cpus=1 -v "$PWD":/app -w /app mcr.microsoft.com/playwright:v1.48.0-noble \
  npx playwright test checkout.spec.ts -g "shows confirmation" --repeat-each=50 --retries=0
```

### Fix
```diff
 test('shows confirmation after placing order', async ({ page }) => {
   await page.goto('/checkout');
+  const orderCreated = page.waitForResponse(
+    (r) => r.url().includes('/api/orders') && r.request().method() === 'POST',
+  );
   await page.getByRole('button', { name: 'Place order' }).click();
-  await page.waitForTimeout(2000);
-  await page.waitForLoadState('networkidle');
-  await expect(page.getByText('Order placed')).toBeVisible();
+  expect((await orderCreated).status()).toBe(201);
+  await expect(page.getByRole('status')).toHaveText('Order placed');
+  await expect(page).toHaveURL(/\/orders\/\w+/);
 });
```
The web-first assertion starts polling as soon as the order response arrives, well inside the toast's 3 s lifetime. The sleep and `networkidle`, both of which are discouraged, are gone. The persistent outcome (the order page URL) is asserted as well, so the test no longer depends only on transient UI. If the toast lifetime is configurable, set it longer in the test environment.

### Quarantine decision
No. The fix is small and can merge today.

### Verify
- 100 runs with `--repeat-each=100 --workers=4 --retries=0` in CI: 0 failures.
- Monitor the CI pass rate for this test for 7 days.

### Prevent
- Enable the `playwright/no-wait-for-timeout` and `playwright/no-networkidle` rules in eslint-plugin-playwright.
- Team guideline: assert transient UI (toasts, spinners) immediately after the triggering action, and prefer asserting persistent state.
