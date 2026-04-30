# debian-packaging

[![CI](https://github.com/cosgroveb/debian-packaging-agent-skill/actions/workflows/ci.yml/badge.svg)](https://github.com/cosgroveb/debian-packaging-agent-skill/actions/workflows/ci.yml)

Claude Code plugin for Debian packaging. Covers debhelper, debian/rules, package metadata, and multi-binary packages for Ruby (gem2deb), Python (pybuild), Rust (debcargo), and Go (dh-golang).

## Install

```
/plugin marketplace add cosgroveb/debian-packaging-agent-skill
/plugin install debian-packaging-agent-skill@cosgroveb-debian-packaging-agent-skill
/reload-plugins
```

## Usage

Invoke directly:

```
/debian-packaging
```

Or describe what you need and the skill picks up from context:

```
Package this Python project as a .deb
```

```
Create debian/ for this Go binary
```

```
Fix the lintian errors in this package
```

The skill loads the language-specific reference doc (`doc/*.md`) for whichever language it detects and follows Debian Policy throughout.

## Project layout

Source of truth is `skills/` and `doc/`.

`make dist` builds to `dist/claude-plugin/` (Claude Code plugin bundle) and `dist/agents/` (.agents skill bundle). CI owns `dist/`; do not edit it by hand.

Edit `skills/**`, `doc/**`, and `.claude-plugin/**` only.

## License

[Apache License 2.0](LICENSE)
