# Debian Go packaging

**Source**: https://go-team.pages.debian.net/packaging.html

## 1. General notes and team conventions

### Team maintenance

All Go packages in Debian are **team-maintained** under the **pkg-go team**:

**Team designation in debian/control**:
```
Debian Go Packaging Team <team+pkg-go@tracker.debian.org>
```

**Two collaboration models**:

1. **Strong collaboration** (team in `Maintainer` field):
   - Fully collaborative maintenance
   - Anyone can commit to git and upload as needed

2. **Weak collaboration** (team in `Uploaders` field):
   - Tighter control by original maintainers
   - Contact Maintainer before uploading

### Packaging in git

**All Go packages**:
- Must be maintained in git
- Must be buildable with: `gbp buildpackage` using git-buildpackage
- Stored on **Salsa** (salsa.debian.org)

### Using dh-make-golang

**Always use dh-make-golang** when starting a new Go library/program package. Don't copy debian/ from random packages.

**Key features**:
- Creates proper debian/ directory structure
- Can create Salsa projects
- Configures CI automatically

### Version numbers

For **version-less upstream packages**, use this format:

```
0.0~git20130606.b00ec39-1
```

**Format breakdown**:
- `0.0`: Allows upstream to adopt version numbers later
- `git`: Version control system
- `20130606`: Date in YYYYMMDD format
- `b00ec39`: VCS revision/commit hash
- `-1`: Debian version number

### changelog: UNRELEASED

**During development**: Use `UNRELEASED` in distribution field: `dch -v <debian_version>`
**When ready to upload**: Change to `unstable`: `dch -r`

## 2. dh-golang workflow

### How dh-golang works

```bash
apt-get install dh-golang  # from Debian unstable
```

**Important**: Buildds use unstable version, so you must too.

### Build system integration

**Required configuration in debian/control**:
```
XS-Go-Import-Path: github.com/user/package
```

This is the upstream package name (what you'd use with `go get`). dh-golang needs this to run `go install`.

### Environment variables and options

**The CI infrastructure evaluates environment variables**:
- `DH_GOLANG_GO_GENERATE`
- Other `Debian::Debhelper::Buildsystem::golang(3pm)` options

**Important for CI**: Packages must be buildable/testable after extracting source (`apt source pkg`).

## 3. Binary-only packages

Binary-only packages contain a program written in Go but no source code (no API).

### Naming conventions

**DO NOT use golang- prefix**:
- Source package: `docker` (NOT `golang-docker`)
- Binary package: `docker` (NOT `golang-docker`)

Name packages like the upstream project.

## 4. Library packages

Go libraries are packaged **only for building other Go programs in Debian**, not for regular user development.

### Naming conventions

**Derive names from import path**:
- Replace slashes with dashes
- Use canonical identifier instead of hostname
- Add `-dev` suffix

**Examples**:

| Import path | Debian package name |
|------------|---------------------|
| `github.com/stapelberg/websocket` | `golang-github-stapelberg-websocket-dev` |
| `golang.org/x/oauth2` | `golang-golang-x-oauth2-dev` |
| `google.golang.org/appengine` | `golang-google-appengine-dev` |

### File locations

**Install path**: `/usr/share/gocode/src/` (corresponds to `$GOPATH/src`)

### Dependencies management

**Library packages need all Go dependencies in `Depends` line**:
- Required at **build time** to run tests
- Required at **installation time** so other packages can be built

### Upstream package moves

When upstream moves (e.g., from code.google.com to GitHub):

1. **Add compatibility symlink** via `debian/links`
2. **Rename package** (since location is in package name)

## 5. Go modules integration

- dh-golang is aware of Go modules
- Use the module path as the `XS-Go-Import-Path`
- Follow same naming conventions based on import/module path

### Vendoring considerations

- Packages must be buildable after source extraction
- CI doesn't use dpkg-buildpackage
- Invokes `go` tool directly

## 6. CI/CD infrastructure

### Goals and motivation

1. **Prevent issues before uploading to archive**
2. **Enable auto-updating**
3. **Test archive-wide rebuilds of new Go version**

### Implementation details

- GitLab CI infrastructure
- Custom Docker container with build tools
- Overlay filesystem for staging changes
- Direct go tool invocation (not dpkg-buildpackage)

### Tools: pgt-gopath, ci-build, ci-diff

#### pgt-gopath
Constructs Go workspace src directory from Debian unstable archive.

#### ci-build
Builds/tests all packages in parallel (~30 seconds when cached).

#### ci-diff
Compares two ci-build outputs, prints new breakages.

### Implications/caveats

**CI does NOT use Debian package build process**:
- No dpkg-buildpackage
- Invokes `go` tool directly
- File deletion in debian/rules won't work in CI
- Use dh_clean or debian/copyright instead

## Key commands reference

### Package creation
```bash
dh-make-golang <upstream-url>
dh-make-golang create-salsa-project
```

### Version management
```bash
dch -v <debian_version>   # New version (sets UNRELEASED)
dch -a                    # Add changelog entry
dch -r                    # Release (changes to unstable)
```

### Building
```bash
gbp buildpackage
```

### Testing/CI
```bash
ratt                                    # Rebuild reverse deps (slow)
ci-build                               # Build all packages (fast)
ci-diff before.json after.json         # Compare build results
pgt-gopath -dsc package.dsc            # Construct Go workspace
```

## Important file paths

- **Library install location**: `/usr/share/gocode/src/`
- **GOPATH in CI**: `/srv/gopath`
- **Go cache in CI**: `/cache/go`

## Important gotchas

1. **Always use dh-make-golang** - don't copy debian/ from other packages
2. **Install dh-golang from unstable** - buildds use unstable version
3. **Don't use golang- prefix for binary-only packages**
4. **Libraries are NOT for end users** - only for building Debian packages
5. **CI doesn't run dpkg-buildpackage** - must be buildable with direct `go` tool
6. **File deletion in debian/rules won't work in CI** - use dh_clean or debian/copyright
7. **Code generation must use //go:generate** - not Makefiles
8. **Version format matters** - use `0.0~git20130606.b00ec39-1` for version-less upstreams
9. **Add compat symlinks when upstream moves** - and rename package
10. **Use UNRELEASED during development** - change to unstable only when ready

## Resources

- **Documentation**: https://go-team.pages.debian.net/packaging.html
- **Salsa go-team**: https://salsa.debian.org/go-team
- **Team tracker**: https://tracker.debian.org (Debian Go Packaging Team)
