#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

repo="$workdir/repo"
mkdir -p "$repo"
rsync -a --exclude .git --exclude dist "$root/" "$repo/"

mkdir -p "$repo/skills/real-skill"
cat >"$repo/skills/real-skill/SKILL.md" <<'SKILL'
---
name: real-skill
description: Test fixture skill.
---

Fixture body.
SKILL

(
  cd "$repo"
  make dist
)

test -f "$repo/dist/agents/.agents/skills/real-skill/SKILL.md"
test -f "$repo/dist/claude-plugin/.claude/skills/real-skill/SKILL.md"
test -f "$repo/dist/agents/.agents/skills/.gitkeep"
test -f "$repo/dist/claude-plugin/.claude/skills/.gitkeep"
test -f "$repo/dist/claude-plugin/.claude-plugin/plugin.json"
test -f "$repo/dist/claude-plugin/.claude-plugin/marketplace.json"

test -f "$repo/dist/claude-plugin/doc/debian-packaging-main.md"
test -f "$repo/dist/agents/doc/debian-packaging-main.md"
