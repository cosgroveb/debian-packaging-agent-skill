# Debian Rust packaging

## Overview

The Debian Rust Team maintains the Rust toolchain (rustc compiler and cargo package manager) and Rust crates/applications in Debian. The team uses specialized tools and workflows to automate much of the packaging process.

## Core tools

### debcargo
- **Purpose**: Automated tool for generating Debian packages from Rust crates
- **Repository**: https://salsa.debian.org/rust-team/debcargo
- **Function**: Automatically generates debian/ directory contents from crate metadata
- **Integration**: Works with debcargo-conf repository for manual overrides

### debcargo-conf
- **Purpose**: Monorepo containing per-crate configuration and debian/ overrides
- **Repository**: https://salsa.debian.org/rust-team/debcargo-conf
- **Structure**: Contains only files under debian/ that need manual inspection

### dh-cargo
- **Purpose**: Debhelper buildsystem integration for Cargo
- **Function**: Handles Debian-specific cargo build requirements
- **Integration**: Provides dh sequence for building Rust packages

## Debian Rust packaging workflow

### 1. Package naming convention
- Libraries: `rust-<crate-name>` (source package)
- Binary packages: `librust-<crate-name>-dev`
- Applications: `<application-name>` or `rust-<name>` (case by case)
- Feature packages: `librust-<crate-name>+<feature>-dev`

### 2. debcargo workflow

#### Initial setup
```bash
git clone git@salsa.debian.org:rust-team/debcargo-conf
cd debcargo-conf
```

#### Packaging a new crate
1. debcargo reads Cargo.toml from crates.io
2. Automatically generates debian/ files
3. Creates appropriate dependencies from Cargo dependencies

Before adding a patch or overriding a generated file, read the installed
`/usr/share/doc/debcargo/examples/debcargo.toml.example` and nearby packages in
debcargo-conf. The [upstream example](https://salsa.debian.org/rust-team/debcargo/-/blob/master/debcargo.toml.example)
documents the available settings. Check that the installed version supports
the settings you choose.

Put supported customizations in `debian/debcargo.toml`. Regenerate and inspect
the resulting manifest, dependencies and tests before adding an overlay file.
When removing an override, remove its obsolete `.debcargo.hint` too. Treat
remaining hints as generator output, not files to edit by hand.

### 3. Cargo integration

#### Build system integration
- **dh-cargo** provides debhelper sequence
- Automatically handles `Cargo.toml` dependencies
- Maps Cargo features to Debian binary packages
- Manages vendored dependencies appropriately

#### Dependency resolution
- Cargo dependencies -> Debian package dependencies
- Optional dependencies -> separate feature packages
- Build dependencies handled separately from runtime

### 4. Rust team conventions

#### Version handling
- Use tilde `~` for pre-release versions (e.g., `1.0.0~beta1`)
- Epoch bumps rare but used when necessary
- Semantic versioning typically followed

#### Repository structure
- Single debcargo-conf monorepo for all crates
- Individual directories per crate: `src/<crate-name>/`
- debian/ subdirectory contains only manual overrides

### 5. Package categories

#### Libraries (librust-*-dev)
- Development files only (no runtime libraries needed)
- Statically linked into dependent packages
- May have multiple feature-specific packages

#### Applications
- Standalone binary packages
- May be maintained with GNOME team (gtk-rs based)
- Examples: lsd, exa, bat

#### Toolchain packages
- rustc: Rust compiler
- cargo: Package manager (integrated into rust package since 1.70.0)

## Advanced topics

### Cross-Compilation
```bash
sbuild --host=$arch --profiles=nocheck $pkg
```

### Bootstrapping
- rustc and cargo have circular dependency
- Uses Build Profiles to break dependency loop
- May use upstream binaries initially

### Testing
- Autopkgtests automatically generated where possible
- Unit tests run during build
- Integration tests via autopkgtest framework

Prefer `test_command`, `test_depends`, `test_restrictions` and
`test_architecture` in debcargo.toml over a handwritten `debian/tests/control`.
Keep dependency and architecture metadata generated unless a requirement
cannot be expressed in the configuration.

Use `{stock_cmd}` when adding arguments to the generated command. If the
default target selection is unsuitable, an explicit command can use
`{crate_name}`, `{crate_version}` and `{feature_arguments}`. For example,
tui-textarea-2 needs a widget backend even for backend-independent features:

```toml
[packages.lib]
test_command = "/usr/share/cargo/bin/cargo-auto-test {crate_name} {crate_version} {feature_arguments} --features no-backend"
```

Here `no-backend` enables Ratatui without selecting a terminal backend. This
choice is specific to that crate. Verify the feature graph before adapting it.
Inspect inherited commands for the bare library, default, individual features
and all-features cases after regeneration.

Cargo's `--all-targets` does not include doctests. If documentation tests matter,
run them separately or use Cargo's default target selection, checking that it
still covers the required targets. Compare coverage, not just stanza counts,
when replacing handwritten tests. Run the generated installed-package tests.

`test_is_broken` marks tests flaky. Use it only for a documented known failure,
not to hide an invalid feature combination that can be tested with the right
arguments. Do not turn a failing test into a passing result by suppressing it.

## Handling features
- Each Cargo feature can become a separate binary package
- Naming: `librust-<crate>+<feature>-dev`
- Automatic dependency generation
- Feature combinations handled through metapackages

Use `collapse_features = true` for the usual single library package, following
nearby packages and checking for dependency cycles.

Prefer `remove_features` to manually deleting feature definitions and their
unused optional dependencies from Cargo.toml. Use `remove_target_types` for
whole target classes, such as benchmarks:

```toml
remove_features = ["legacy-backend"]
remove_target_types = ["bench"]
```

These are top-level settings. Replace the example feature with names from the
crate. Inspect debcargo's generated patches: target removal may leave unused
development dependencies, and feature removal may leave examples requiring
the omitted features. Keep a small manual patch for any remaining changes.
Do not remove supported examples or dependencies needed by tests. Compare the
generated feature graph and targets with the intended supported combinations.

## Special considerations

### gtk-rs applications
- Should be maintained with GNOME team
- Different workflow than typical crates

### ITP filing
- File ITP for applications
- NOT required for regular crates/libraries

### Security updates
- Monitor security advisories
- Rust's memory safety reduces certain vulnerabilities
- Coordinate through security team when needed

## Team resources

### Communication channels
- **Mailing list**: https://lists.debian.org/debian-rust/
- **IRC**: #debian-rust on irc.oftc.net
- **Matrix**: #debian-rust:matrix.debian.social
- **Salsa**: https://salsa.debian.org/rust-team

### Documentation
- **Packaging book**: https://rust-team.pages.debian.net/book/
- **Policy**: https://wiki.debian.org/Teams/RustPackaging/Policy
- **Team page**: https://wiki.debian.org/Teams/RustPackaging

## Common patterns

### Adding a new crate
1. Check if crate is on crates.io
2. Run debcargo to generate packaging
3. Review generated debian/ files
4. Add customizations to debcargo-conf if needed
5. Build and test locally
6. Submit merge request

### Updating an existing crate
1. Update version in debcargo-conf
2. Regenerate with debcargo
3. Check for new dependencies
4. Update customizations if needed
5. Test build
6. Upload

## Summary

- debcargo automates most debian/ file generation
- debcargo-conf centralizes all crate packaging configuration
- Cargo features map to Debian binary packages
- Rust packages primarily use static linking
- Collaborative development via Salsa MRs
- Follow Debian Rust packaging policy
- Use dh-cargo for Debian build integration
