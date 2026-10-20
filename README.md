# qa-ai-skills

Reusable AI skills for QA engineers, packaged for both **Claude Code** (Agent Skills) and **GitHub Copilot in VS Code** (prompt files).

Each skill encodes a QA workflow: what input it needs, the steps to follow, the exact output format, and a worked example. You get consistent, reviewable results instead of one-off prompts.

## Skills

| Skill | What it does | Try it with |
|---|---|---|
| [`test-case-generator`](.claude/skills/test-case-generator/SKILL.md) | Positive, negative, and edge test cases from a user story, as a traceable table | `/test-case-generator` + a story and its acceptance criteria |
| [`bug-report-writer`](.claude/skills/bug-report-writer/SKILL.md) | Turns rough notes and logs into a reproducible report: steps, expected vs actual, severity, environment | `/bug-report-writer` + your notes |
| [`flaky-test-triage`](.claude/skills/flaky-test-triage/SKILL.md) | Root-causes an intermittent test, with repro commands, a fix, and a quarantine decision | `/flaky-test-triage` + the test file and failure log |
| [`accessibility-audit`](.claude/skills/accessibility-audit/SKILL.md) | WCAG 2.2 A/AA audit with a full checklist, prioritised findings, and code fixes | `/accessibility-audit` + a component or URL |
| [`api-test-generator`](.claude/skills/api-test-generator/SKILL.md) | Test matrix and runnable tests from an OpenAPI spec (Playwright by default), plus spec gaps | `/api-test-generator openapi.yaml` |
| [`pr-testability-review`](.claude/skills/pr-testability-review/SKILL.md) | Reviews a PR for test coverage, testability smells, and risk; lists missing tests | `/pr-testability-review 482` |
| [`release-test-plan`](.claude/skills/release-test-plan/SKILL.md) | Risk-based release plan: scope, schedule, entry/exit criteria, go/no-go, rollback | `/release-test-plan` + version, tickets, and dates |

Every skill has the same structure: **Inputs → Instructions → Output format → Example**.

## Repository layout

```text
qa-ai-skills/
├── .claude/skills/<skill>/SKILL.md     # Claude Code skills (source of truth)
├── .github/prompts/<skill>.prompt.md   # Copilot prompt files (generated)
├── .github/workflows/check-prompts.yml # CI: fails if the prompt files are out of date
└── scripts/sync-prompts.sh             # Regenerates the prompt files from SKILL.md
```

## Install in Claude Code

Claude Code loads skills from `.claude/skills/` in your project, and from `~/.claude/skills/` for personal skills available in every project.

```bash
git clone https://github.com/sergiopiedra/qa-ai-skills.git

# Option A: for one project (commit the files to share them with your team)
mkdir -p your-project/.claude/skills
cp -R qa-ai-skills/.claude/skills/* your-project/.claude/skills/

# Option B: personal, for all your projects
mkdir -p ~/.claude/skills
cp -R qa-ai-skills/.claude/skills/* ~/.claude/skills/
```

To copy a single skill, copy just its folder, e.g. `cp -R qa-ai-skills/.claude/skills/bug-report-writer ~/.claude/skills/`.

**Use them**

- **Automatically:** describe the task ("write test cases for this story…") and Claude loads the skill whose description matches.
- **Explicitly:** type `/<skill-name>` followed by your input, e.g. `/flaky-test-triage tests/checkout.spec.ts`.
- Skills are picked up when a session starts. Restart Claude Code after copying them.

## Install in VS Code (GitHub Copilot)

Requirements: VS Code with the GitHub Copilot Chat extension. Prompt files are enabled by default in current releases (setting `chat.promptFiles`).

**Option A: workspace (shared with your team)**

```bash
mkdir -p your-project/.github/prompts
cp qa-ai-skills/.github/prompts/*.prompt.md your-project/.github/prompts/
```

**Option B: user profile (available in every workspace)**

Copy the `.prompt.md` files into your VS Code profile's `prompts` folder:

| OS | Folder |
|---|---|
| macOS | `~/Library/Application Support/Code/User/prompts/` |
| Windows | `%APPDATA%\Code\User\prompts\` |
| Linux | `~/.config/Code/User/prompts/` |

Or run **Chat: New Prompt File** from the Command Palette and choose *User Data* to see where your profile keeps them.

**Option C: point VS Code at this clone** (updates arrive with `git pull`). Add to `settings.json`:

```json
"chat.promptFilesLocations": {
  "/absolute/path/to/qa-ai-skills/.github/prompts": true
}
```

**Use them**

- In Copilot Chat, type `/` and pick the prompt, e.g. `/test-case-generator`, then add your input.
- Attach context with `#file` (an OpenAPI spec, a test file, a diff) or select text in the editor first.
- The prompts run in **agent** mode, so Copilot can read workspace files and run commands such as `gh pr diff` when needed.

> Recent VS Code releases can also discover Agent Skills from `.claude/skills/` directly. Check the VS Code Copilot documentation for your version. The prompt files work either way.

## Customising and contributing

`.claude/skills/<name>/SKILL.md` is the **single source of truth**. The Copilot prompt files are generated from it:

```bash
./scripts/sync-prompts.sh          # regenerate .github/prompts/
./scripts/sync-prompts.sh --check  # what CI runs
```

The script maps the SKILL.md frontmatter (`description`, `argument-hint`) to prompt-file frontmatter, adds `agent: agent`, and copies the body unchanged. Never edit files in `.github/prompts/` by hand.

To add a skill:

1. Create `.claude/skills/<kebab-name>/SKILL.md` with frontmatter:
   ```yaml
   ---
   name: <kebab-name>
   description: "<what it does>. Use when <trigger phrases>."
   argument-hint: "<what the user passes>"
   ---
   ```
   Keep `description` on a single line; it decides when Claude picks the skill.
2. Write the sections `Inputs`, `Instructions`, `Output format`, and `Example`, using platform-neutral wording (no tool names specific to one assistant).
3. Run `./scripts/sync-prompts.sh` and commit both files.

Good customisations for your team: your severity scale, your tracker's field names, your default test framework, your definition of done.

## Responsible use

- AI output is a **draft**. Review test cases, bug reports, and plans before you rely on them.
- Don't paste secrets, tokens, or personal data into prompts. The bug report skill redacts what it notices, but it isn't a safeguard.
- `accessibility-audit` doesn't replace testing with real assistive technology, and it doesn't certify legal conformance.

## License

[MIT](LICENSE)
