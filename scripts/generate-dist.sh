#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
skills_root="$root/skills"
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

copy_skills "$dist/agents/.agents/skills"
touch "$dist/agents/.agents/skills/.gitkeep"
