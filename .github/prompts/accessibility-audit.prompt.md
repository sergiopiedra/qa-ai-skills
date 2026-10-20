---
description: "Audit a web page, component, or HTML/JSX code against the WCAG 2.2 Level A and AA success criteria, and return a prioritised findings report with code fixes. Use when asked for an accessibility (a11y) audit or review, a WCAG check, or a keyboard or screen-reader review."
argument-hint: "<URL, component file, HTML snippet, or screenshot + scope>"
agent: agent
---

<!-- Generated from .claude/skills/accessibility-audit/SKILL.md by scripts/sync-prompts.sh. Edit the source and re-run the script. -->

# Accessibility Audit (WCAG 2.2)

Check a UI against WCAG 2.2 and report each failure with the success criterion, who it affects, and how to fix it.

## Inputs

| Input | Required | Notes |
|---|---|---|
| Target | Yes | URL, HTML/JSX/Vue/Svelte code, component files, or screenshots. |
| Conformance level | No | Defaults to **AA** (which includes A). AAA only on request. |
| Scope | Recommended | Pages, flows, and states to cover: error states, modals, menus, loading, empty states. |
| Tool results | No | Output from axe, Lighthouse, WAVE, or Accessibility Insights. |
| Context | No | Target browsers and assistive technologies, design tokens (colours), known constraints. |

## Instructions

1. **Define the scope and limits.** List what you audited. Note what the input *can't* show: code alone doesn't show rendered contrast or focus order, and a screenshot doesn't show names, roles, or keyboard behaviour. Mark such criteria **Needs manual check**, never Pass.
2. **Run an automated pass** if you have tool access, for example `@axe-core/playwright` (`new AxeBuilder({ page }).withTags(['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa']).analyze()`). If you don't, recommend the command. Automated tools find only a fraction of issues; the manual pass is mandatory.
3. **Do the manual pass** with the checklist below:
   - Keyboard only: Tab, Shift+Tab, Enter, Space, Esc, and arrow keys.
   - Semantics: name, role, value, and state for every interactive element.
   - Zoom to 200% and reflow at 320 CSS px.
   - Text and non-text contrast.
   - Forms: labels, errors, and recovery.
   - Motion and timing.
4. **Record each failure** with:
   - the SC number and level;
   - the location (selector, `file:line`, or screen + element);
   - what is wrong;
   - who is affected (e.g. screen-reader users, keyboard users, low vision, cognitive, motor);
   - the fix, with a code snippet for Blocker and Serious issues.
5. **Rate severity:**
   - **Blocker**: some users can't complete the task at all.
   - **Serious**: the task is possible but very difficult, or information is lost.
   - **Moderate**: an annoyance or inefficiency with a workaround.
   - **Minor**: a best-practice gap with little user impact.
6. **Mark every in-scope SC** Pass, Fail, N/A, or Needs manual check.
7. **Don't certify legal conformance.** Write "no failures found within the audited scope", never "the site is compliant".
8. **Prefer native HTML** over ARIA in fixes. The first rule of ARIA: don't use it if a native element does the job.

### WCAG 2.2 A/AA checklist

★ = new in WCAG 2.2. 4.1.1 Parsing is obsolete in 2.2 and is not checked.

**1. Perceivable**

| SC | Level | Check |
|---|---|---|
| 1.1.1 Non-text Content | A | Informative images have meaningful `alt`; decorative images have `alt=""`; icon buttons have names; CAPTCHAs offer an alternative. |
| 1.2.1 Audio-only and Video-only (Prerecorded) | A | A transcript or audio track is provided. |
| 1.2.2 Captions (Prerecorded) | A | Videos with audio have accurate captions. |
| 1.2.3 Audio Description or Media Alternative (Prerecorded) | A | Audio description or a full text alternative is provided. |
| 1.2.4 Captions (Live) | AA | Live audio has captions. |
| 1.2.5 Audio Description (Prerecorded) | AA | Important visual-only content is described. |
| 1.3.1 Info and Relationships | A | Headings, lists, tables, landmarks, and label/field associations are in the markup, not only visual. |
| 1.3.2 Meaningful Sequence | A | DOM order matches the visual reading order. |
| 1.3.3 Sensory Characteristics | A | Instructions don't rely only on shape, position, or sound ("click the round button on the right"). |
| 1.3.4 Orientation | AA | Not locked to portrait or landscape. |
| 1.3.5 Identify Input Purpose | AA | Personal-data fields have the correct `autocomplete` value. |
| 1.4.1 Use of Color | A | Colour isn't the only means of conveying information (errors, links in text, chart series). |
| 1.4.2 Audio Control | A | Auto-playing audio longer than 3 s can be paused or muted. |
| 1.4.3 Contrast (Minimum) | AA | Text contrast ≥ 4.5:1; large text (≥ 24px, or ≥ 18.66px bold) ≥ 3:1. |
| 1.4.4 Resize Text | AA | Text scales to 200% without loss of content or function. |
| 1.4.5 Images of Text | AA | Real text is used instead of images of text. |
| 1.4.10 Reflow | AA | No two-dimensional scrolling at 320 CSS px width (except maps, tables, and similar). |
| 1.4.11 Non-text Contrast | AA | UI component boundaries, states, focus indicators, and meaningful graphics ≥ 3:1. |
| 1.4.12 Text Spacing | AA | No loss of content with increased line, paragraph, letter, and word spacing. |
| 1.4.13 Content on Hover or Focus | AA | Tooltips and popovers are dismissible (Esc), hoverable, and persistent. |

**2. Operable**

| SC | Level | Check |
|---|---|---|
| 2.1.1 Keyboard | A | Everything works with the keyboard; no `div`/`span` click handlers without keyboard support. |
| 2.1.2 No Keyboard Trap | A | Focus can always move away (modals included, via Esc or Tab cycling with a close control). |
| 2.1.4 Character Key Shortcuts | A | Single-key shortcuts can be turned off or remapped, or are active only on focus. |
| 2.2.1 Timing Adjustable | A | Time limits can be turned off, adjusted, or extended (session time-out warnings). |
| 2.2.2 Pause, Stop, Hide | A | Carousels, auto-updating content, and animations longer than 5 s can be paused. |
| 2.3.1 Three Flashes or Below Threshold | A | Nothing flashes more than 3 times per second. |
| 2.4.1 Bypass Blocks | A | Skip link or landmarks let users bypass repeated blocks. |
| 2.4.2 Page Titled | A | Unique, descriptive `<title>`, updated on SPA route changes. |
| 2.4.3 Focus Order | A | Focus order preserves meaning; focus moves into opened dialogs and returns on close. |
| 2.4.4 Link Purpose (In Context) | A | Link text (with context) states the destination; no bare "click here". |
| 2.4.5 Multiple Ways | AA | More than one way to find pages (navigation, search, sitemap). |
| 2.4.6 Headings and Labels | AA | Headings and labels describe their topic or purpose. |
| 2.4.7 Focus Visible | AA | A visible focus indicator on every focusable element; no bare `outline: none`. |
| ★ 2.4.11 Focus Not Obscured (Minimum) | AA | The focused element is not fully hidden by sticky headers, footers, cookie banners, or chat widgets. |
| 2.5.1 Pointer Gestures | A | Multipoint or path gestures (pinch, swipe) have a single-pointer alternative. |
| 2.5.2 Pointer Cancellation | A | Actions fire on up-event, or can be aborted or undone. |
| 2.5.3 Label in Name | A | The accessible name contains the visible label text. |
| 2.5.4 Motion Actuation | A | Shake or tilt actions have a UI alternative and can be disabled. |
| ★ 2.5.7 Dragging Movements | AA | Drag-and-drop has a single-pointer alternative (buttons, select). |
| ★ 2.5.8 Target Size (Minimum) | AA | Pointer targets are ≥ 24×24 CSS px, or have enough spacing (exceptions: inline, equivalent, essential). |

**3. Understandable**

| SC | Level | Check |
|---|---|---|
| 3.1.1 Language of Page | A | `<html lang>` is set correctly. |
| 3.1.2 Language of Parts | AA | `lang` is set on passages in another language. |
| 3.2.1 On Focus | A | Focusing an element doesn't trigger a change of context. |
| 3.2.2 On Input | A | Changing a setting doesn't trigger an unexpected change of context (auto-submit, navigation). |
| 3.2.3 Consistent Navigation | AA | Repeated navigation keeps the same relative order across pages. |
| 3.2.4 Consistent Identification | AA | The same function has the same label and icon everywhere. |
| ★ 3.2.6 Consistent Help | A | Help mechanisms (contact, chat, FAQ) appear in the same relative place across pages. |
| 3.3.1 Error Identification | A | Errors are identified in text and tied to the field. |
| 3.3.2 Labels or Instructions | A | Fields have visible labels; required fields and formats are stated. Placeholders alone aren't labels. |
| 3.3.3 Error Suggestion | AA | Errors suggest how to fix the input, where known. |
| 3.3.4 Error Prevention (Legal, Financial, Data) | AA | Submissions can be reviewed, confirmed, or reversed. |
| ★ 3.3.7 Redundant Entry | A | Information already entered in the same process is auto-filled or selectable, not retyped. |
| ★ 3.3.8 Accessible Authentication (Minimum) | AA | No cognitive function test to log in: paste and password managers are allowed; no puzzle-only CAPTCHA. |

**4. Robust**

| SC | Level | Check |
|---|---|---|
| 4.1.2 Name, Role, Value | A | Custom controls expose their name, role, state, and value; ARIA is used correctly. |
| 4.1.3 Status Messages | AA | Status and error messages are announced without moving focus (`role="status"`, `role="alert"`, `aria-live`). |

## Output format

```markdown
## Accessibility audit: <target>

**Standard:** WCAG 2.2 Level AA · **Date:** <date> · **Method:** <automated tool + manual / code review only>
**Scope:** <pages, components, states> · **Not evaluable from input:** <list>

### Summary
<counts by severity; the top 3 issues to fix first; one-line overall statement>

### Findings
| ID | SC | Level | Severity | Location | Issue | Affected users | Fix |

### Fix details
<code for Blocker and Serious findings>

### Checklist results
- **Fail:** <SC list>
- **Needs manual check:** <SC list + what to check>
- **Pass:** <SC list>
- **N/A:** <SC list>

### Next steps
<bullets: re-test, assistive-technology testing, regression automation>
```

## Example

**Input**

> Audit this login form (code only).
>
> ```html
> <style>*:focus { outline: none; }</style>
> <div class="login">
>   <img src="logo.png">
>   <input type="text" placeholder="Email">
>   <input type="password" placeholder="Password">
>   <div class="btn" onclick="login()">Sign in</div>
>   <span style="color:#999" onclick="forgot()">Forgot password?</span>
>   <p class="error" style="color:#ff0000">Invalid credentials</p>
> </div>
> <div id="cookie-banner" style="position:fixed;bottom:0;height:120px">…</div>
> ```

**Output**

## Accessibility audit: Login form

**Standard:** WCAG 2.2 Level AA · **Date:** 2026-10-19 · **Method:** Code review only
**Scope:** Login form, default and error states · **Not evaluable from input:** rendered focus order, logo content, behaviour of `login()` and `forgot()`, page `<title>` and `lang`

### Summary
8 findings: 2 Blocker, 4 Serious, 2 Moderate. Fix first: the non-focusable **Sign in** control, the removed focus outline, and the unlabelled fields. No conformance claim is possible until these are fixed and the Needs-manual-check items have been tested.

### Findings
| ID | SC | Level | Severity | Location | Issue | Affected users | Fix |
|---|---|---|---|---|---|---|---|
| A11Y-01 | 2.1.1, 4.1.2 | A | Blocker | `div.btn` | **Sign in** is a `div` with a click handler: it isn't focusable, has no button role, and Enter/Space do nothing | Keyboard, screen-reader, and switch users | Use `<button type="submit">` inside a `<form>` |
| A11Y-02 | 2.4.7 | AA | Blocker | `*:focus { outline: none }` | Focus indicator removed globally, so keyboard users can't see where they are | Keyboard and low-vision users | Remove the rule; style `:focus-visible` with ≥ 3:1 contrast |
| A11Y-03 | 1.3.1, 3.3.2, 4.1.2 | A | Serious | Both `input`s | Placeholder only: no programmatic label, and the hint disappears when typing | Screen-reader and cognitive users | Add `<label for>` for each field |
| A11Y-04 | 2.1.1, 4.1.2 | A | Serious | `span` "Forgot password?" | Clickable `span`: not focusable, not announced as a link | Keyboard and screen-reader users | Use `<a href="/forgot-password">` |
| A11Y-05 | 1.4.3 | AA | Serious | "Forgot password?" `#999` on white | Contrast 2.8:1 (needs 4.5:1) | Low-vision users | Use `#595959` or darker (7:1) |
| A11Y-06 | 4.1.3, 3.3.1 | AA / A | Serious | `p.error` | The error isn't announced when it appears and isn't associated with the fields | Screen-reader users | Container with `role="alert"`; `aria-invalid` and `aria-describedby` on the fields |
| A11Y-07 | 1.4.3 | AA | Moderate | `p.error` `#ff0000` on white | Contrast 4.0:1 (needs 4.5:1) | Low-vision users | Use `#d00000` (5.7:1) or darker |
| A11Y-08 | 1.3.5, 1.1.1 | AA / A | Moderate | `input`s, `img` | Missing `autocomplete` (also helps 3.3.8); logo has no `alt` | Users of autofill and password managers; screen-reader users | `autocomplete="username"` / `"current-password"`; `alt="<Brand> home"` or `alt=""` if decorative |

### Fix details
```html
<style>
  :focus-visible { outline: 3px solid #1a5fb4; outline-offset: 2px; }
  .muted-link { color: #595959; }
  .error { color: #d00000; }
</style>
<form class="login" action="/login" method="post" novalidate>
  <img src="logo.png" alt="">
  <label for="email">Email</label>
  <input id="email" name="email" type="email" autocomplete="username"
         aria-describedby="login-error" aria-invalid="true">
  <label for="password">Password</label>
  <input id="password" name="password" type="password" autocomplete="current-password"
         aria-describedby="login-error" aria-invalid="true">
  <button type="submit">Sign in</button>
  <a class="muted-link" href="/forgot-password">Forgot password?</a>
  <div id="login-error" class="error" role="alert">Invalid email or password.</div>
</form>
```
Set `aria-invalid` only after a failed attempt. Render the alert container empty, then inject the text, so that the message is announced.

### Checklist results
- **Fail:** 1.1.1, 1.3.1, 1.3.5, 1.4.3, 2.1.1, 2.4.7, 3.3.1, 3.3.2, 4.1.2, 4.1.3
- **Needs manual check:** 2.4.11 (can the fixed 120px cookie banner cover the focused **Sign in** button or link on short viewports?), 2.5.8 (rendered target size of the link), 3.3.8 (confirm that paste isn't blocked by script), 1.4.10 / 1.4.4 (reflow and zoom), 2.4.2 and 3.1.1 (page `<title>` and `lang`), 1.4.11 (input border contrast)
- **Pass:** 2.5.3 (accessible names derive from the visible text)
- **N/A:** 1.2.x (no media), 2.2.2 (no moving content), 2.5.1, 2.5.4, 2.5.7, 3.3.7

### Next steps
- Apply the fixes, then repeat the keyboard-only pass and test with a screen reader (VoiceOver + Safari, NVDA + Firefox).
- Add `@axe-core/playwright` checks for the default and error states to CI.
