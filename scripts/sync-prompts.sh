#!/usr/bin/env bash
# Generates GitHub Copilot prompt files (.github/prompts/<name>.prompt.md)
# from the Claude skills (.claude/skills/<name>/SKILL.md), the single source of truth.
#
# Usage:
#   scripts/sync-prompts.sh          # regenerate prompt files
#   scripts/sync-prompts.sh --check  # exit 1 if prompt files are out of date (CI)
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
skills_dir="$root/.claude/skills"
prompts_dir="$root/.github/prompts"

check=false
[[ "${1:-}" == "--check" ]] && check=true

out_dir="$prompts_dir"
if $check; then
  out_dir="$(mktemp -d)"
  trap 'rm -rf "$out_dir"' EXIT
fi
mkdir -p "$out_dir"

for skill in "$skills_dir"/*/SKILL.md; do
  name="$(basename "$(dirname "$skill")")"
  awk -v name="$name" '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" {
      in_fm = 0
      print "---"
      print "description: " desc
      if (hint != "") print "argument-hint: " hint
      print "agent: agent"
      print "---"
      print ""
      print "<!-- Generated from .claude/skills/" name "/SKILL.md by scripts/sync-prompts.sh. Edit the source and re-run the script. -->"
      next
    }
    in_fm && /^description:/ { sub(/^description:[ ]*/, ""); desc = $0; next }
    in_fm && /^argument-hint:/ { sub(/^argument-hint:[ ]*/, ""); hint = $0; next }
    in_fm { next }
    { print }
  ' "$skill" > "$out_dir/$name.prompt.md"
done

if $check; then
  if ! diff -r "$prompts_dir" "$out_dir"; then
    echo "Prompt files are out of date. Run scripts/sync-prompts.sh and commit the result." >&2
    exit 1
  fi
  echo "Prompt files are in sync."
else
  echo "Generated $(ls "$out_dir"/*.prompt.md | wc -l | tr -d ' ') prompt files in .github/prompts/"
fi
