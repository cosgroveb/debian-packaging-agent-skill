# Debian Ruby packaging

## Overview
Debian Ruby Team maintains Ruby interpreters, libraries, and applications in Debian. All packages are hosted in the ruby-team group on Salsa (https://salsa.debian.org/ruby-team).

## gem2deb: the core tool

### What is gem2deb?
The preferred packaging tool for Ruby software in Debian. It automates most of the packaging process and has two uses:
1. Users can generate .debs from gems locally
2. Generates Debian source packages for packaging work

### gem2deb features
- Does almost everything automatically
- Uses dh (debhelper)
- Runs test suite during build for each Ruby implementation
- Uses single binary package for native libraries (instead of one per Ruby version)
- Considered the reference implementation of Debian Ruby policy

### Basic gem2deb workflow

#### Installation
```bash
apt-get install gem2deb
```

#### Creating a package from scratch
```bash
# Create build directory
mkdir -p ~/Build/ruby-packaging && cd $_

# Generate initial package (e.g., for 'devise' gem)
gem2deb devise
```

This downloads the gem from rubygems.org and creates:
- Source package (*.dsc, *.orig.tar.gz, *.debian.tar.xz)
- Binary package (*.deb)

#### Fetching from alternative sources
```bash
# For rails-assets-* gems
gem fetch --source https://rails-assets.org rails-assets-jquery
gem2deb rails-assets-jquery-*.gem

# From local .gem file or tarball
gem2deb path/to/foo.gem
```

#### If initial build fails
```bash
cd ruby-<foo-version>
dpkg-source -b .
cd ..
```

## Git workflow and repository management

### Branch structure
Three main branches (for non-native packages):
1. **pristine-tar**: Stores original tarballs (from gem2deb or gemwatch)
2. **upstream**: Tracks unpacked upstream tarballs
3. **master**: Contains upstream + debian/ directory (patches unapplied)

Additional branches may exist for:
- Backports: `wheezy-backports` (replaces master)
- Stable/testing updates: `master-<codename>`, `upstream-<codename>`

### Required tools
```bash
apt-get install myrepos git-buildpackage pristine-tar gem2deb
```

### Cloning the team repository
```bash
# Clone meta repository
git clone git@salsa.debian.org:ruby-team/meta.git ruby-team

# Checkout specific package
cd ruby-team
./checkout $PACKAGE

# Checkout all packages (takes time - hundreds of packages)
mr --force checkout

# Parallel checkout (5 simultaneous)
mr --force -j 5 checkout

# Clone individual repo without mr
gbp clone --pristine-tar git@salsa.debian.org:ruby-team/<pkg-name>.git
```

### Creating new package repository

#### From existing package
```bash
cd ruby-team
./setup-project
```

#### Packaging new gem
```bash
# Generate initial package
gem2deb foo

# DO NOT modify yet - track all changes in git

# Setup repository
cd ruby-team
./update-mrconfig  # Generate config for new repo
./checkout ruby-foo
cd ruby-foo

# Import to git
gbp import-dsc --pristine-tar path-to/ruby-foo_0.7-1.dsc
git tag -d debian/0.7-1  # Package not ready yet
git push --all
git push --tags

# Make needed changes, then push
git push

# After successful upload, tag and push
git tag debian/0.7-1
git push --tags
```

## File editing and fine-tuning

### Key files to edit (in debian/)
1. **copyright**: License information
2. **control**: Package metadata, dependencies
3. **changelog**: Version history and changes

### Finding package information
- rubygems.org (search for gem, check homepage)
- LICENSE, COPYING, or README files in source
- Use `licensecheck` for license detection:
  ```bash
  licensecheck --deb-machine --copyright LICENSE
  ```

### License notes
- Two MIT variants exist: Expat or X11
- Use Expat when text matches the Expat project license

## Building and quality checks

### Building from source repository
```bash
dpkg-buildpackage
# Ignore signing errors initially
```

### Lintian validation
```bash
lintian
```
Fix all errors, rebuild with `dpkg-buildpackage`, and re-check with lintian.

**Important**: Changes to debian/ only reflect in lintian output after rebuilding, as lintian checks the .changes file.

### Copyright validation
Verify that all copyright notices are in `debian/copyright`.

## Ruby team conventions

### Package naming
- Libraries: `ruby-<gemname>`
- Applications may have different naming

### Testing requirements
- Test suite should be enabled during build
- Tests run for each Ruby implementation

### Handling dependencies
Always install build dependencies via apt, not `gem install`.

### Setting environment variables
Configure DEBFULLNAME and DEBEMAIL to avoid manual entry each time.

## Updating existing packages

### Prerequisites
```bash
# Clone with pristine-tar
gbp clone --pristine-tar git@salsa.debian.org:ruby-team/<pkg-name>.git
```

### Using debian/watch (preferred)
```bash
# Test watch file
uscan --verbose --report

# Import new version automatically
gbp import-orig --pristine-tar --uscan

# For specific version
uscan --verbose --download-version <version>
gbp import-orig --pristine-tar <tarball>
```

### Manual tarball creation
```bash
# Fetch latest version
gem2tgz <gemname>

# Or specific version
gem fetch -v <version> <gemname>
gem2tgz <gemname>.gem

# Import to git
gbp import-orig --pristine-tar <tarball>
```

### Updating debian/changelog

**Option 1 (gbp dch)**:
```bash
gbp dch -a
```

**Option 2 (dch)**:
```bash
dch -v <new-upstream-version>-1
```

### Final steps
```bash
# Change UNRELEASED to unstable (or experimental for breaking changes)
git push -u --all --follow-tags

# Test RubyGems integration
echo "gem '<library name>', '<version>'" > Gemfile
bundle install --local
```

## Handling API breaking changes

### When changes are breaking
Assume SemVer compliance (https://semver.org):
- Major version updates when version >= 1.0
- Minor updates when version < 1.0

### Required steps
1. Verify autopkgtests of all reverse dependencies
2. Rebuild all reverse build dependencies
3. Use ruby-team-meta-build or upload to experimental
4. Watch britney pseudo-excuses for experimental

### Upload paths
**Path A (Ideal)**:
- Fix all breaking packages before uploading to unstable

**Path B**:
- Upload to experimental
- File bugs (severity: important) against all failed packages
- Give maintainers time to fix (at least 1 week)
- Upload to unstable with all fixed packages
- Add Breaks for packages that failed

### Exceptions
Be careful with minor updates for: rails, ruby-rack, ruby-doorkeeper, ruby-devise, ruby-graphql, ruby-grape

## Special cases

### Multiple gemspec files
Create `debian/gemspec` symlink or set `DH_RUBY_GEMSPEC` in `debian/rules`.
Remove `Testsuite` field from `debian/control` and create `debian/tests` manually.

### Rails engines
Gems with `app/assets`, `vendor/assets`, or `lib/assets` directories are Rails engines.
Often provide JavaScript libraries via Rails asset pipeline.

## Requesting sponsorship

### Pre-sponsorship checklist
- [ ] Builds in clean chroot (use sbuild or pbuilder)
- [ ] Lintian-clean (or issues explained in debian/changelog)
- [ ] debian/watch file correct (`uscan --download-current-version` works)
- [ ] Git repo up-to-date (changes and tags committed and pushed)
- [ ] Package actually works (test in clean chroot)
- [ ] Test suite enabled and passing
- [ ] autopkgtest passing

### Sponsorship request process
1. Change distribution from `UNRELEASED` to `unstable`
2. Email debian-ruby@lists.debian.org

## Communication channels

### Mailing list
- debian-ruby@lists.debian.org

### IRC
- #debian-ruby on irc.debian.org (OFTC)

### Salsa
- https://salsa.debian.org/ruby-team

## Quick reference commands

```bash
# Install tools
apt-get install gem2deb myrepos git-buildpackage pristine-tar

# Create package
gem2deb <gemname>

# Convert gem to tarball
gem2tgz <gemname>

# Import to git
gbp import-dsc --pristine-tar <file>.dsc
gbp import-orig --pristine-tar <tarball>
gbp import-orig --pristine-tar --uscan

# Build
dpkg-buildpackage

# Quality checks
lintian
uscan --verbose --report
autopkgtest -B ../foo.deb -- schroot unstable-amd64-sbuild

# Changelog
dch -v <version>
gbp dch -a

# Git operations
git tag debian/<version>
git push -u --all --follow-tags
gbp clone --pristine-tar git@salsa.debian.org:ruby-team/<pkg>.git
```
