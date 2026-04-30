# debian-packaging

[![CI](https://github.com/cosgroveb/debian-packaging-agent-skill/actions/workflows/ci.yml/badge.svg)](https://github.com/cosgroveb/debian-packaging-agent-skill/actions/workflows/ci.yml)

Debian packaging skill with reference documentation for Ruby (gem2deb), Python (pybuild), Rust (debcargo), and Go (dh-golang).

## Install

Add the marketplace and install:

```
/plugin marketplace add cosgroveb/debian-packaging-agent-skill
/plugin install debian-packaging-agent-skill@cosgroveb-debian-packaging-agent-skill
/reload-plugins
```

Or for local development, run Claude Code with the plugin directory:

```bash
git clone https://github.com/cosgroveb/debian-packaging-agent-skill.git
claude --plugin-dir ./debian-packaging-agent-skill
```

## Usage

Once installed, the skill activates when you work on Debian packaging tasks. You can invoke it directly:

```
/debian-packaging
```

Or just ask Claude to package something and it picks up the skill from context:

```
Package this Python project as a .deb
```

```
Create debian/ for this Go binary
```

```
Fix the lintian errors in this package
```

The skill reads the appropriate `doc/*.md` reference for the language it detects (Ruby, Python, Rust, or Go) and follows Debian Policy throughout.

## Structure

The source of truth is `skills/` and `doc/`.

`skills/example` is a template only. `make dist` skips it.

Build output goes to two places:

- `dist/claude-plugin/` - Claude Code plugin bundle
- `dist/agents/` - `.agents` skill bundle

## Source files

Each real skill lives in `skills/<skill-name>/`.

- `SKILL.md`: required entry point
- `references/`: optional material loaded only when needed

Reference documentation lives in `doc/`:

- `debian-packaging-main.md`: Core Debian policy, debhelper, package structure
- `debian-packaging-ruby.md`: gem2deb workflow and Ruby team conventions
- `debian-packaging-python.md`: pybuild workflow and Python policy
- `debian-packaging-rust.md`: debcargo workflow and Rust team conventions
- `debian-packaging-golang.md`: dh-golang workflow and Go team conventions
- `systematic-debugging.md`: Systematic debugging framework for build failures

## Build

```bash
make dist
```

Run this only for a local check. CI owns `dist/`.

Build output:

- `dist/claude-plugin/.claude/skills`
- `dist/claude-plugin/.claude-plugin/{plugin.json,marketplace.json}`
- `dist/claude-plugin/doc`
- `dist/agents/.agents/skills`
- `dist/agents/doc`

## Editing

Edit these source files:

- `skills/**`
- `doc/**`
- `.claude-plugin/**`

Do not edit `dist/` by hand.

GitHub Actions builds `dist/` on pushes to `main`.

## License

[Apache License 2.0](LICENSE)
