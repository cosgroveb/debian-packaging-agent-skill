# debian-packaging

[![CI](https://github.com/cosgroveb/debian-packaging-agent-skill/actions/workflows/ci.yml/badge.svg)](https://github.com/cosgroveb/debian-packaging-agent-skill/actions/workflows/ci.yml)

Debian packaging skill with comprehensive reference documentation, packaged in two places:

- Claude plugin bundle
- `.agents` skill bundle

The source of truth is `skills/` and `doc/`.

`skills/example` is a template only. `make dist` skips it.

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
