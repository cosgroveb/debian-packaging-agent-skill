# Debian Python packaging

**Source**: Debian Python Policy 0.12.0.0 + Wiki packaging guides

## 1. Python 3 migration and policy overview

### 1.1 Python 2 to Python 3 transition
- **Python 2 is removed** from Debian 11 (Bullseye) onwards
- All packages MUST use Python 3
- New packages must use Python 3 from initial upload

### 1.2 Unversioned Python commands
- `/usr/bin/python`, `python-minimal`, `python-dev`, `python-dbg`, `python-doc` **removed** in Bullseye
- `python-is-python3` and `python-dev-is-python3` packages provide unversioned commands pointing to Python 3
- These packages must NOT be used as dependencies in packaging

## 2. Python interpreter and versions

### 2.1 Interpreter requirements
- Default Python 3 version: latest stable upstream fully integrated in Debian
- Binary package `python3` represents current default Python 3
- Main packages: `python3.Y` for specific versions
- Versions defined in `/usr/share/python3/debian_defaults`
- Query supported versions: `/usr/bin/py3versions`

### 2.2 Interpreter directives (shebangs)
- **Python 3 scripts**: `#!/usr/bin/python3` (preferred)
- **Specific version**: `#!/usr/bin/python3.Y` if version-specific
- **Never use**: `#!/usr/bin/env python` (bypasses Debian dependency checking)
- **Never use**: `#!/usr/bin/python` (removed in Bullseye)

### 2.3 Module paths
**Python 3 public modules**:
- `/usr/lib/python3/dist-packages` (system-wide)
- `/usr/local/lib/python3/dist-packages` (local admin)
- `/usr/local/lib/python3/site-packages` (local pip installs)

**Private modules**: `/usr/share/<package>` or `/usr/lib/<package>`

## 3. Packaging tools

### 3.1 Core build tools

#### **pybuild** (primary build system)
- Modern, modular build system for Python packages
- Automatically builds for all supported Python versions
- Auto-detects and runs test suites
- Supports pytest, tox, nose, distutils, setuptools
- Configurable via `PYBUILD_*` environment variables

#### **dh-python** (debhelper integration)
- Provides `dh_python3` helper
- Calculates Python dependencies automatically
- Adds maintainer scripts for byte-compilation
- Use `dh-sequence-python3` (>=3.20190307) or `dh-python` package

## 4. Package naming conventions

### 4.1 Module package names
- **Python 3 public modules**: `python3-<name>`
- Module name based on `import` statement, NOT setuptools metadata
  - Example: `pyxdg` package -> `import xdg` -> package is `python3-xdg`
- Replace underscores with hyphens: `distro_info` -> `python3-distro-info`
- Lowercase capital letters: `Xlib` -> `python3-xlib`
- Subpackages: `python3-foo.bar` for `import foo.bar`

### 4.2 Django packages
- Upstream naming: `django_<name>`
- Debian naming: `python3-django-<name>`

### 4.3 Documentation packages
- Name: `python-<module>-doc` (NOT `python3-<module>-doc`)
- Architecture: `all`
- Section: `doc`

## 5. debian/control structure

### 5.1 Source package stanza

**Essential Build-Depends**:
```
Build-Depends:
    debhelper-compat (= 13),
    dh-sequence-python3,
    python3-all,
    python3-setuptools,
    python3-build,
    python3-wheel
```

**For C extensions**:
```
    python3-all-dev
```

**Version specification**:
```
X-Python3-Version: >= 3.X
```
Only needed if minimum version > current stable.

### 5.2 Binary package stanza

**Python 3 library**:
```
Package: python3-foo
Architecture: all | any
Depends: ${python3:Depends}, ${misc:Depends}
Description: ...
```

## 6. debian/rules with pybuild

### 6.1 Minimal debian/rules
```makefile
#!/usr/bin/make -f

export PYBUILD_NAME = foo

%:
	dh $@ --buildsystem=pybuild
```

### 6.2 pybuild environment variables

**Basic configuration**:
```makefile
export PYBUILD_NAME = foo
export PYBUILD_SYSTEM = distutils | pytest | custom
export PYBUILD_DISABLE = test | configure | build
```

**Per-interpreter customization**:
```makefile
export PYBUILD_DESTDIR_python3 = debian/python3-foo/
export PYBUILD_TEST_ARGS = -k 'not test_network'
export PYBUILD_DISABLE_python3.11 = test
```

**Before/after hooks**:
```makefile
export PYBUILD_BEFORE_BUILD = echo {version} >> '{dir}/enabled'
export PYBUILD_AFTER_INSTALL = rm -rf '{destdir}/{install_dir}/tests'
```

## 7. Dependencies

### 7.1 Runtime dependencies

**Python 3 modules**:
```
Depends: python3 (>= 3.Y), ${python3:Depends}, ${misc:Depends}
```

### 7.2 Build dependencies

List build-time dependencies, including Python modules imported by build-time
tests, in `Build-Depends`. Put runtime dependencies in `Depends`, using
`${python3:Depends}` plus explicit dependencies when needed.

pybuild sets `http_proxy=127.0.0.1:9` to block unauthorized network access.

## 8. Byte-compilation

- `.pyc` and `.pyo` files must NOT ship in package
- Generate in `postinst`, remove in `prerm`
- `dh_python3` handles byte-compilation automatically via maintainer scripts

## 9. Testing and quality assurance

### 9.1 Clean build

Build Python packages in a clean environment before asking for review:

```bash
dpkg-buildpackage -S -us -uc
sbuild --dist=unstable ../<source>_<version>.dsc
```

This checks whether `Build-Depends` is sufficient for that clean build
environment. A Python package can appear to build locally because dependencies
are already installed on the developer machine. That is not enough before
asking for review.

When build-time tests import Python modules, list those modules in
`Build-Depends`. If the package also imports them at runtime, keep them in
`Depends` too. Do not rely on `pip`, PyPI, tox downloading packages, or locally
installed modules during the build.

### 9.2 autopkgtest (DEP-8)

**Enable autodep8**:
```debcontrol
Testsuite: autopkgtest-pkg-python
```

**Local testing**:
```bash
autopkgtest -- schroot sid-amd64-sbuild
```

### 9.3 Test suite integration

pybuild auto-detects test frameworks: pytest, nose, unittest, tox.

**Disable specific tests** (pytest):
```makefile
export PYBUILD_TEST_ARGS = -k 'not test_network and not test_slow'
```

## 10. Wheels policy

- Packages must NOT build or provide wheels
- Exception: narrow support for `pip`, `virtualenv`, `pyvenv`

## 11. debian/watch files

### PyPI watch file (modern format)

Use `pypi.debian.net` redirector service:

```
version=4
opts="uversionmangle=s/(rc|a|b|c)/~$1/" \
  https://pypi.debian.net/urllib3/urllib3-@ANY_VERSION@@ARCHIVE_EXT@
```

**Quick generation**:
```bash
wget -HN "https://pypi.debian.net/<module_name>/watch"
```

## 12. Sphinx documentation

### Building documentation

**Build-Depends**:
```
python3-sphinx,
python3-sphinx-rtd-theme
```

**debian/rules override**:
```makefile
override_dh_auto_build:
	dh_auto_build
	PYTHONPATH=. python3 -m sphinx -b html docs/ debian/python-foo-doc/usr/share/doc/python-foo-doc/html
```

## 13. Programs vs libraries

**If package provides both library and executable**:

Option 1: Separate packages
- `python3-foo` - library
- `foo` - executable (depends on `python3-foo`)

Option 2: Combined
- `python3-foo` - includes both

**Recommendation**: Use separate `foo` package for executables.

**Private module install locations**:
- Pure Python: `/usr/share/<program>/`
- Extensions: `/usr/lib/<program>/`

## 14. Quick reference checklist

### New package checklist
- [ ] debian/control: `dh-sequence-python3`, `python3-all`
- [ ] debian/control: Build-time deps in `Build-Depends`
- [ ] debian/control: `X-Python3-Version` if min > current stable
- [ ] debian/rules: `export PYBUILD_NAME=<module>`
- [ ] debian/rules: `dh $@ --buildsystem=pybuild`
- [ ] debian/watch: Use `pypi.debian.net`
- [ ] Clean build: `sbuild --dist=unstable ../<source>_<version>.dsc` or equivalent target suite
- [ ] Package naming: `python3-<name>` for libraries
- [ ] Shebang: `#!/usr/bin/python3`
- [ ] autopkgtest: Add `Testsuite: autopkgtest-pkg-python`
- [ ] No .pyc/.pyo files in package
- [ ] Verify no PyPI access during build

### Common debian/rules pattern
```makefile
#!/usr/bin/make -f

export PYBUILD_NAME = foo

%:
	dh $@ --buildsystem=pybuild

override_dh_auto_test:
	PYBUILD_TEST_ARGS="-k 'not test_network'" dh_auto_test
```

## 15. Resources

- Debian Python Policy: https://www.debian.org/doc/packaging-manuals/python-policy/
- pybuild manpage: `man pybuild`
- dh_python3 manpage: `man dh_python3`
- Mailing list: debian-python@lists.debian.org
- IRC: #debian-python on OFTC
