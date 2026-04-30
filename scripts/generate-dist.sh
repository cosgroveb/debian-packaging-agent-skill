#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
skills_root="$root/skills"
doc_root="$root/doc"
dist="$root/dist"

rm -rf "$dist"

copy_skills() {
  local dest_root="$1"
  local src skill_name

  mkdir -p "$dest_root"

  for src in "$skills_root"/*; do
    [[ -d "$src" ]] || continue

    skill_name=$(basename "$src")
    [[ -f "$src/SKILL.md" ]] || continue

    mkdir -p "$dest_root/$skill_name"
    rsync -a "$src/" "$dest_root/$skill_name/"
  done
}

copy_doc() {
  local dest_root="$1"

  mkdir -p "$dest_root"
  rsync -a "$doc_root/" "$dest_root/"
}

mkdir -p "$dist/claude-plugin/.claude-plugin"
cp "$root/.claude-plugin/plugin.json" "$dist/claude-plugin/.claude-plugin/plugin.json"
cp "$root/.claude-plugin/marketplace.json" "$dist/claude-plugin/.claude-plugin/marketplace.json"
copy_skills "$dist/claude-plugin/.claude/skills"
copy_doc "$dist/claude-plugin/doc"
touch "$dist/claude-plugin/.claude/skills/.gitkeep"

copy_skills "$dist/agents/.agents/skills"
copy_doc "$dist/agents/doc"
touch "$dist/agents/.agents/skills/.gitkeep"
