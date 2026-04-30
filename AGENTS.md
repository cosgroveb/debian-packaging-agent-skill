## generated output
Treat `dist/` as CI-owned output.
Edit `skills/`, `doc/`, and repo metadata, not generated bundles.
- X run `make dist` after source edits and commit the result
- O commit source changes only; let CI regenerate `dist/`
Run `make dist` only when the user asks for a local check.

## docs
Write user-facing docs for humans, not agents.
Cut process-speak, packaging jargon, and internal labels unless the reader needs them.
Prefer the concrete label a person would look for on screen or in the repo.

## reference documentation
The `doc/` directory contains Debian packaging knowledge that was previously
stored in atuin kv. These files are the authoritative reference for the skill.
When updating reference docs, preserve the existing structure and section headings.

## workflow
Check repo docs and workflow files before running build or generation commands.
Follow the repo's workflow, not generic habits from other projects.
If CI owns an artifact, leave it alone unless the user says otherwise.
