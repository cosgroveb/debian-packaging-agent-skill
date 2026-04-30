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

### 2. debcargo Workflow

#### Initial setup
```bash
git clone git@salsa.debian.org:rust-team/debcargo-conf
cd debcargo-conf
```

#### Packaging a new crate
1. debcargo reads Cargo.toml from crates.io
2. Automatically generates debian/ files
3. Creates appropriate dependencies from Cargo dependencies

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

## Handling features
- Each Cargo feature can become a separate binary package
- Naming: `librust-<crate>+<feature>-dev`
- Automatic dependency generation
- Feature combinations handled through metapackages

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
