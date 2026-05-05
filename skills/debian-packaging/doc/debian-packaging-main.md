# Debian packaging reference

## Core philosophy

Debhelper provides a collection of small, focused tools that automate common packaging tasks. Changes to Debian Policy can often be accommodated by updating debhelper tools rather than individual packages. The modern approach uses the `dh` sequencer to run appropriate commands automatically.

## Package structure

### Essential debian/ files

**debian/control** (REQUIRED)
- Source stanza: Source, Maintainer, Build-Depends, Standards-Version, Homepage
- Binary stanza(s): Package, Architecture, Depends, Description
- Controls what packages are built and their metadata
- First package listed is the "main package" (compat < 15)

**debian/changelog** (REQUIRED)
- Format: `package (version) distribution; urgency=low`
- Documents changes, sets package version
- First entry determines source package name and version
- Must be in specific Debian changelog format

**debian/copyright** (REQUIRED)
- Machine-readable format (DEP-5) recommended
- Must document all licenses in the package
- Declare upstream source and copyright holders

**debian/rules** (REQUIRED)
- Makefile that builds the package
- Must be executable
- Modern minimal form using dh:
  ```makefile
  #!/usr/bin/make -f
  %:
  	dh $@
  ```
- Standard targets: clean, build, build-arch, build-indep, binary, binary-arch, binary-indep, install

### Common debian/ files

**debian/install**
- List files to install: `path/to/file destination/dir`
- One file/directory per line
- Supports wildcards (* ? [])

**debian/dirs**
- Directories to create in package

**debian/docs**
- Documentation files to install to `/usr/share/doc/package/`

**debian/examples**
- Example files for `/usr/share/doc/package/examples/`

**debian/manpages**
- Man pages to install (dh_installman auto-detects section from extension)

**debian/links**
- Symlinks to create: `target linkname`

**debian/\*.service, debian/\*.timer**
- systemd unit files (handled by dh_installsystemd)

**Package-specific naming**: `debian/package.foo` for multi-binary packages. Falls back to `debian/foo` for single-binary or first package (< compat 15).

**Architecture/OS-specific**: `debian/package.foo.ARCH` or `debian/package.foo.OS` override general files

## Debhelper compatibility levels

Specified via `Build-Depends: debhelper-compat (= 13)` in debian/control (modern method)

**Key Compat Levels:**
- **13**: Current stable recommendation. Enables substitutions in config files, improved defaults
- **12**: Added execute_before_/execute_after_ hook targets (12.8+)
- **11**: Changed to `dh_missing --fail-missing` by default
- **10**: Minimum for modern features, dh_installinit uses systemd
- **9 and below**: Legacy, avoid in new packages

**Compat level affects:**
- Default options passed to dh_* commands
- Which files debhelper processes automatically
- Behavior of dh sequences
- Package selection defaults
- Whether ${misc:Depends} is auto-added

## The dh sequencer

**Basic usage in debian/rules:**
```makefile
%:
	dh $@
```

**Sequences** correspond to debian/rules targets:
- `clean`: Clean build tree
- `build`, `build-arch`, `build-indep`: Build software
- `install`, `install-arch`, `install-indep`: Install to debian/tmp
- `binary`, `binary-arch`, `binary-indep`: Create .deb files

**Override targets** (replace a step):
```makefile
override_dh_auto_configure:
	dh_auto_configure -- --with-custom-flag

override_dh_install:
	dh_install
	# Additional custom install steps
```

**Hook targets** (inject before/after, compat 10+, debhelper 12.8+):
```makefile
execute_before_dh_install:
	# Runs before dh_install

execute_after_dh_install:
	# Runs after dh_install
```

**Architecture-specific overrides:**
```makefile
override_dh_auto_test-arch:
	# Only for arch-dependent packages

execute_after_dh_install-indep:
	# Only for arch-independent packages
```

**Addons** (via `--with`):
```makefile
%:
	dh $@ --with python3,systemd
```
Or via Build-Depends: `dh-sequence-addon` (recommended, avoids --with in rules)

## Key debhelper commands

**Build system automation:**
- `dh_auto_configure`: Run ./configure, cmake, meson, etc.
- `dh_auto_build`: Run make, ninja, etc.
- `dh_auto_test`: Run test suites
- `dh_auto_install`: Run make install to debian/tmp
- `dh_auto_clean`: Clean build artifacts

**Installation:**
- `dh_install`: Install files from debian/tmp to package dirs
- `dh_installdirs`: Create directories
- `dh_installdocs`: Install documentation
- `dh_installexamples`: Install example files
- `dh_installman`: Install man pages
- `dh_installchangelogs`: Install upstream changelog
- `dh_link`: Create symlinks
- `dh_missing`: Check for files not installed anywhere (--fail-missing)

**System integration:**
- `dh_installsystemd`: Install and enable systemd units
- `dh_installinit`: Install init scripts (legacy)
- `dh_installcron`: Install cron jobs
- `dh_installudev`: Install udev rules
- `dh_installdeb`: Install DEBIAN/* files, process #DEBHELPER#

**Binary package generation:**
- `dh_strip`: Strip debugging symbols
- `dh_compress`: Compress files in /usr/share/doc
- `dh_fixperms`: Fix file permissions
- `dh_shlibdeps`: Calculate shared library dependencies -> ${shlibs:Depends}
- `dh_gencontrol`: Generate DEBIAN/control file
- `dh_md5sums`: Generate DEBIAN/md5sums
- `dh_builddeb`: Build .deb files

**Dependency management:**
- `dh_makeshlibs`: Generate shlibs file for libraries
- `dh_perl`: Calculate Perl dependencies -> ${perl:Depends}
- `${misc:Depends}`: Auto-generated by various dh_* commands

## Debian policy requirements

### Package names
- Lowercase alphanumerics and `-` `.` `+` only
- Must start with alphanumeric
- Should not exceed 80 characters

### Version numbers
Format: `[epoch:]upstream_version[-debian_revision]`

**epoch**: Optional, numeric, incremented to override version ordering (rare)
**upstream_version**: Upstream's version, alphanumerics and `.` `+` `-` `:` `~`
**debian_revision**: Starts at -1, incremented for Debian changes, omitted for native packages

**Tilde (~)**: Sorts before anything, useful for pre-releases (1.0~rc1 < 1.0)
**Plus (+)**: Sorts after, useful for snapshots

Examples:
- `1.2.3-1`: Upstream 1.2.3, Debian revision 1
- `2:1.0-1`: Epoch 2 (overrides 1.9)
- `1.0~rc1-1`: Pre-release
- `1.0+git20230101-1`: Snapshot

### Architecture field
- `any`: Arch-dependent (needs compilation)
- `all`: Arch-independent (scripts, docs, etc.)
- Specific archs: `amd64`, `arm64`, etc.
- `linux-any`, `any-amd64`: Wildcards

### Maintainer scripts
Executed in sequence during install/upgrade/remove:

**Package installation:**
1. `new-preinst install`
2. Files unpacked
3. `new-postinst configure`

**Package upgrade:**
1. `new-preinst upgrade old-version`
2. `old-prerm upgrade new-version`
3. Files replaced
4. `new-postinst configure old-version`
5. `old-postrm upgrade new-version`

**Package removal:**
1. `prerm remove`
2. Files removed
3. `postrm remove`

**Package purge:**
1. `postrm purge`

**Must be idempotent** - safe to run multiple times
**Must handle failures** - package can be in various states
**Use #DEBHELPER#** marker for auto-generated code
**Exit status 0** for success

### File locations (FHS)
- `/usr/bin`, `/usr/sbin`: Executables
- `/usr/lib/arch-triplet`: Architecture-specific libraries
- `/usr/share`: Architecture-independent data
- `/usr/share/doc/package`: Documentation
- `/usr/share/man`: Man pages
- `/etc`: Configuration files (mark as conffiles)
- `/var/lib/package`: Variable state data
- `/var/log`: Log files

**Do NOT use:**
- `/usr/local`: Reserved for local admin
- `/opt`: Not for Debian packages
- `/home`: User data only

## Configuration files (conffiles)

**Automatic:** Files in /etc are automatically conffiles
**Manual:** List in debian/conffiles if needed
**Behavior:** dpkg asks user on upgrade if modified
**Best practice:** Use `/etc/package/config.conf`, not `/etc/package.conf`

## Build dependencies vs runtime dependencies

**Build-Depends:** Required to build package (all architectures)
**Build-Depends-Indep:** Required only for arch-independent packages
**Build-Depends-Arch:** Required only for arch-dependent packages

**Depends:** Required at runtime (mandatory)
**Recommends:** Strongly suggested (installed by default)
**Suggests:** Optional enhancements
**Enhances:** Reverse suggests

**Conflicts:** Cannot be installed together
**Breaks:** This version breaks older version of other package
**Replaces:** Files replaced during upgrade

**Version constraints:** `>= 1.0`, `<< 2.0`, `= 1.5-1`

## Substitution variables

**${shlibs:Depends}**: Auto-calculated by dh_shlibdeps from linked libraries
**${misc:Depends}**: Auto-calculated by various dh_* commands
**${perl:Depends}**: Perl dependencies (dh_perl)
**${python3:Depends}**: Python3 dependencies

In debian/control:
```
Depends: libc6, ${shlibs:Depends}, ${misc:Depends}
```

## Config file substitutions (compat 13+)

Available in debian/*.install, debian/*.dirs, etc:

**${DEB_HOST_ARCH}**, **${DEB_HOST_MULTIARCH}**: Architecture values
**${DEB_BUILD_*}**, **${DEB_TARGET_*}**: Build/target architecture
**${env:NAME}**: Environment variable (must be set)
**${Dollar}** or **${}**: Literal $
**${Space}**, **${Tab}**, **${Newline}**: Whitespace

Example debian/foo.install:
```
usr/lib/${DEB_HOST_MULTIARCH}/libfoo.so.1
```

## Building packages

**Basic build:**
```bash
dpkg-buildpackage -us -uc
```

**Common dpkg-buildpackage options:**
- `-us -uc`: Don't sign (for testing)
- `-b`: Binary only (no source)
- `-S`: Source only
- `-a ARCH`: Cross-build for architecture
- `-j8`: Parallel build (8 jobs)
- `--build=binary`: Just binary target
- `--build=any,all`: Both arch-dependent and independent

**Build artifacts:**
- `package_version_arch.deb`: Binary package
- `package_version.dsc`: Source package description
- `package_version.debian.tar.xz`: Debian packaging files
- `package_version.orig.tar.gz`: Upstream source
- `package_version_arch.changes`: Upload description
- `package_version_arch.buildinfo`: Build metadata

## Lintian quality checks

Before hand-fixing lintian issues, run `lintian-brush` and inspect what it would
change:

```bash
lintian-brush --dry-run --diff
```

If the diff is correct, run `lintian-brush` and review the resulting changes. If
the package uses `gbp dch` to generate `debian/changelog`, consider
`lintian-brush --no-update-changelog`.

**Run lintian:**
```bash
lintian package.changes
lintian -i -I --pedantic package.changes  # Verbose with info
```

**Severity levels:**
- **error**: Policy violation, will be rejected
- **warning**: Serious issue, should fix
- **info**: Informational
- **pedantic**: Cosmetic/style

**Common checks:**
- Policy compliance (file locations, naming, dependencies)
- Maintainer script correctness
- Copyright file completeness
- Lintian overrides (debian/source/lintian-overrides) for false positives
- Security issues (hardening flags, setuid binaries)
- Spelling errors in descriptions
- Missing documentation
- Outdated debhelper compat levels

**Override false positives:**
debian/source/lintian-overrides:
```
package-name: tag-name path/to/file
```

## Maintainer cleanup tools

Use these tools to make repeated packaging runs more consistent. They do not
replace human review.

**debian/control normalization:**
```bash
cme fix dpkg-control
```

Review the diff after running `cme`; it can reorder fields or reformat files.

**debian/copyright check:**
```bash
lrc
```

Use `lrc` output to compare `debian/copyright` with licenses detected by
`licensecheck`.

**Routine update workflows:**
If the package already uses `routine-update`, follow that package workflow
instead of reimplementing its steps by hand.

## Source formats

**3.0 (quilt)** - Modern standard for non-native packages
- Supports multiple upstream tarballs
- Debian changes in debian.tar.xz
- Patches in debian/patches/ (quilt format)
- Specify in debian/source/format

**3.0 (native)** - For Debian-native packages
- Single tarball
- No debian revision in version
- Use only for Debian-specific tools

**1.0** - Legacy, avoid

## Patches (quilt format)

**debian/patches/series** - List of patches to apply (order matters)
**debian/patches/\*.patch** - Individual patches with DEP-3 headers

**DEP-3 headers:**
```
Description: Fix buffer overflow in parser
Author: Your Name <email@example.com>
Bug: https://bugs.example.com/123
Bug-Debian: https://bugs.debian.org/123456
Forwarded: https://github.com/upstream/repo/pull/789
Last-Update: 2023-01-15
```

**Quilt workflow:**
```bash
export QUILT_PATCHES=debian/patches
quilt push -a          # Apply all patches
quilt new fix-bug.patch
quilt add src/file.c   # Track file
# Edit src/file.c
quilt refresh          # Update patch
quilt header -e        # Edit DEP-3 headers
```

## Common patterns

### Override dh_auto_configure for custom flags
```makefile
override_dh_auto_configure:
	dh_auto_configure -- --with-ssl --enable-feature
```

### Skip tests
```makefile
override_dh_auto_test:
	# Tests require network, skip
```

### Multiple binary packages from one source
debian/control:
```
Source: myapp
Build-Depends: debhelper-compat (= 13)

Package: myapp
Architecture: any
Depends: ${shlibs:Depends}, ${misc:Depends}
Description: Main application

Package: myapp-data
Architecture: all
Depends: ${misc:Depends}
Description: Data files for myapp
```

debian/myapp.install:
```
usr/bin/*
```

debian/myapp-data.install:
```
usr/share/myapp/*
```

### Custom installation
```makefile
execute_after_dh_auto_install:
	# Install additional files
	install -D -m 0644 extra/config debian/tmp/etc/myapp/config
```

## git-buildpackage (gbp)

`gbp` is a helper for maintaining Debian packaging in git. It is common in many
Debian team workflows, but Debian Policy does not require it. Do not tell the
user to "use gbp" without naming the command and why it is needed.

Common commands:
```bash
# Build from a packaging git repository
gbp buildpackage

# Import a new upstream tarball into a gbp repository
gbp import-orig ../package_version.orig.tar.gz

# Update debian/changelog from git commits
gbp dch
```

Use the package team's documented workflow when one exists. If the package does
not use `gbp`, do not introduce it just to satisfy a generic checklist.

When commits are allowed and `gbp dch` is part of the workflow, make small
commits with messages that can become useful changelog entries.

## Environment variables

**DH_VERBOSE=1**: Verbose output (same as dh --verbose)
**DH_OPTIONS**: Default options for all dh_* commands
**DH_COMPAT**: Override compat level (for testing)
**DEB_BUILD_OPTIONS**: Standard build options
  - `nocheck`: Skip tests
  - `nostrip`: Don't strip binaries
  - `nodocs`: Don't build documentation
  - `parallel=N`: Parallel build with N jobs
**dpkg-buildflags** environment: CFLAGS, CXXFLAGS, LDFLAGS, etc.

## Cross-compilation

**Build-Depends-Arch**: Dependencies for cross-building arch-dependent packages
**Use DEB_HOST_* variables**: Target architecture
**Use DEB_BUILD_* variables**: Build architecture

Example debian/rules:
```makefile
include /usr/share/dpkg/architecture.mk

override_dh_auto_configure:
	dh_auto_configure -- --host=$(DEB_HOST_GNU_TYPE)
```

## Security and hardening

**Hardening flags** (enabled by default):
- `FORTIFY_SOURCE`: Buffer overflow detection
- `stackprotector`: Stack canary
- `PIE`: Position Independent Executables
- `RELRO`: Read-only relocations
- `bindnow`: Immediate symbol binding

**Check hardening:**
```bash
hardening-check debian/package/usr/bin/program
```

**Disable hardening (rarely needed):**
```makefile
export DEB_BUILD_MAINT_OPTIONS = hardening=-all
# Or selectively:
export DEB_BUILD_MAINT_OPTIONS = hardening=-pie
```

## Standards-version

Current: 4.7.3.0 (as of late 2025)

Indicates which Debian Policy version the package complies with. Update when you verify compliance with newer policy. Check upgrading-checklist in policy manual.

## Common pitfalls

1. **Forgetting to update Standards-Version** - Check policy changes when updating
2. **Not using debhelper-compat** - Specify compat in Build-Depends, not debian/compat file
3. **Hardcoding paths** - Use ${DEB_HOST_MULTIARCH} for library paths
4. **Missing ${misc:Depends}** - Always include in Depends
5. **Installing to wrong directory** - Use debian/tmp, let dh_install move files
6. **Not testing package upgrades** - Test upgrade path, not just fresh install
7. **Conffile handling** - Don't ship /etc files in multiple packages
8. **Symlink attacks** - Use absolute paths, validate before creating symlinks
9. **Missing build dependencies** - Build with `sbuild` or equivalent, not only on the developer's machine
10. **Upstream tarball modifications** - Use +dfsg version suffix, document in copyright

## Workflow summary

1. **Get source:** Download upstream tarball as `package_version.orig.tar.gz`
2. **Extract:** `tar xf package_version.orig.tar.gz`
3. **Create debian/:** Initialize debian/control, changelog, rules, copyright, etc.
4. **Set compat:** `Build-Depends: debhelper-compat (= 13)`
5. **Normalize control:** `cme fix dpkg-control`, then review the diff
6. **Check copyright:** `lrc`
7. **Pre-fix lintian issues:** `lintian-brush --dry-run --diff`, then apply correct changes
8. **Build:** `dpkg-buildpackage -us -uc`
9. **Source build:** `dpkg-buildpackage -S -us -uc`
10. **Clean build:** `sbuild --dist=unstable ../<source>_<version>.dsc` or equivalent target suite
11. **Check:** `lintian -i ../*.changes`
12. **Test:** `sudo dpkg -i *.deb`, verify installation
13. **Iterate:** Fix issues, increment debian/changelog, rebuild

## Testing in clean environment

Use **sbuild** or **pbuilder** for clean chroot builds:
```bash
dpkg-buildpackage -S -us -uc
sbuild --dist=unstable ../<source>_<version>.dsc

# Or pbuilder
sudo pbuilder create
sudo pbuilder build ../<source>_<version>.dsc
```

A package that only builds on the developer's machine has not checked its
Build-Depends in a clean environment. Before asking Debian reviewers to look at
the package, build it with `sbuild` or a comparable chroot builder. This catches
missing Build-Depends, undeclared toolchain assumptions, and accidental use of
packages installed only on the developer's machine.

Use the target suite for the package under review. Use `pbuilder` instead when
that is the local workflow.

## Documentation resources

- Debian Policy Manual: https://www.debian.org/doc/debian-policy/
- Debian Developer's Reference: https://www.debian.org/doc/manuals/developers-reference/
- Debian New Maintainers' Guide: https://www.debian.org/doc/manuals/maint-guide/
- debhelper(7) man page: `man 7 debhelper`
- dh(1) man page: `man 1 dh`
- Lintian tags: https://lintian.debian.org/

## Quick reference commands

```bash
# Initialize packaging (dh-make)
dh_make -f ../upstream_1.0.tar.gz

# Build package
dpkg-buildpackage -us -uc

# Build source package only
dpkg-buildpackage -S -us -uc

# Install build dependencies
sudo apt build-dep .

# Check with lintian
lintian --pedantic *.changes

# List debhelper commands in sequence
dh binary --no-act

# Extract source package
dpkg-source -x package.dsc

# Install package
sudo dpkg -i package.deb

# Remove package
sudo dpkg -r package

# Purge package (including config)
sudo dpkg -P package

# Query installed package
dpkg -l package
dpkg -L package  # List files
dpkg -s package  # Show status

# Check which package owns file
dpkg -S /usr/bin/program
```
