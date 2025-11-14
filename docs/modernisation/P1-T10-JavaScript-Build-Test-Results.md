# P1-T10: JavaScript Build Test Results

**Date**: 2025-11-14
**Node.js Version**: v22.21.1
**Status**: ❌ **BLOCKED** - Requires build system upgrade

---

## Test Summary

Attempted to test the JavaScript build process with modern Node.js (v22.21.1) after Phase 1 configuration changes.

### Environment

- Node.js: v22.21.1 (exceeds v20 requirement)
- npm: Latest
- Package configuration: Updated with `engines.node >= 20.0.0`
- `.nvmrc` files: Created

### Test Results

#### ✅ npm install: SUCCESS

```bash
cd BirchOutline/birch-outline.js
npm install --ignore-scripts
```

**Result**: Succeeded in 7 seconds
- Added 29 packages, removed 25 packages, changed 43 packages
- 614 packages audited

**Security Status**: 54 vulnerabilities (1 low, 8 moderate, 27 high, 18 critical)
- Same vulnerabilities as documented in Phase 1 audit
- Fix available via `npm audit fix` (may have breaking changes)

#### ❌ gulp build: FAILED

```bash
./node_modules/.bin/gulp --tasks
```

**Error**: 
```
ReferenceError: primordials is not defined
    at fs.js:44:5
```

**Root Cause**: Incompatibility between:
- `gulp@3.9.1` (2016-era task runner)
- `graceful-fs@1.x` (deprecated filesystem wrapper)
- Node.js v12+ (primordials API removed from global scope)

This is the **exact same error** encountered in GitHub Actions CI.

### Analysis

#### Why the Build Fails

1. **Gulp 3.x** uses ancient `graceful-fs@1.x`
2. **graceful-fs@1.x** expects `primordials` in global scope
3. **Node.js 12+** removed `primordials` from global scope
4. Result: Immediate crash on gulp startup

#### Pre-Built Bundles

JavaScript bundles are **pre-built and committed** to the repository:
- `BirchOutline/BirchOutline.swift/Dependencies/birchoutline.js` (299 KB)
- `BirchEditor/BirchEditor.swift/Dependencies/bircheditor.js` (577 KB)

**Implication**: The application can build and run **without rebuilding JavaScript**. The bundles are loaded by JavaScriptCore at runtime.

### Recommendations

#### Option 1: Upgrade Build System (Recommended)

Modernize the JavaScript build toolchain:

**Changes Needed**:
- Upgrade `gulp@3.9.1` → `gulp@4.x` or `gulp@5.x`
- Update all gulp plugins to v4-compatible versions
- Rewrite `gulpfile.coffee` in CoffeeScript 2.x syntax
- Test with Node.js v20/v22

**Estimated Effort**: 4-8 hours
**Risk**: Medium (gulp 3→4 has breaking changes)
**Priority**: Medium (not blocking core development)

**Benefits**:
- Enables JavaScript development workflow
- Fixes 54 security vulnerabilities
- Modern build tooling
- Faster builds with newer tools

#### Option 2: Defer Until Phase 4 (Current Strategy)

Keep pre-built bundles, defer JavaScript development until Phase 4 (Pure Swift Migration).

**Rationale**:
- Phase 4 will eliminate JavaScript entirely
- JavaScript changes are rare (last modified 2018)
- Swift code can be developed independently
- Pre-built bundles work fine

**Trade-offs**:
- Cannot modify JavaScript code without local gulp 3.x setup
- 54 vulnerabilities remain (only in dev dependencies, not runtime)
- Technical debt persists until Phase 4

#### Option 3: Minimal Fix (Quick Workaround)

Install compatible Node.js version for JavaScript builds only:

```bash
nvm install 11.15.0  # Original Node.js version
nvm use 11.15.0
cd BirchOutline/birch-outline.js && npm install && npm start
nvm use 22  # Switch back for Swift work
```

**Trade-offs**:
- Works, but uses ancient, unsupported Node.js
- Security vulnerabilities remain
- Requires Node.js version switching
- Doesn't fix root cause

### Decision

**Current Status**: **Option 2 (Defer Until Phase 4)** is the pragmatic choice.

**Reasoning**:
1. JavaScript code is stable (no changes since 2018)
2. Phase 4 will replace JavaScript with Swift
3. Upgrading gulp 3→4 provides little value for 6-12 month lifespan
4. Development focus should be on Swift 6 migration (Phase 2)

**If JavaScript changes needed**: Use Option 3 (nvm to Node.js 11) as temporary workaround.

---

## P1-T10 Status Update

**Original Task**: Test JavaScript Build Process with Node.js 20
**Status**: ✅ **TESTED** (with expected failure documented)

**Completion Criteria Met**:
- ✅ Tested with Node.js 20+ (v22.21.1)
- ✅ Documented npm install results
- ✅ Documented build failure root cause
- ✅ Verified pre-built bundles exist
- ✅ Provided actionable recommendations

**Outcome**: P1-T10 is **COMPLETE** with documented blocker. No further action needed for Phase 1/2 unless JavaScript changes are required.

---

## GitHub Actions CI Validation

The CI workflow correctly disabled JavaScript builds due to this exact issue:

```yaml
# JavaScript build temporarily disabled due to Node.js compatibility issues
# The 2016-era build tools (gulp 3.x, graceful-fs 1.x) are incompatible with Node.js 12+
# JavaScript bundles are pre-built in Dependencies/
```

**CI Strategy**: ✅ **VALIDATED** - This was the correct decision.

---

## Files Created

- `docs/modernisation/P1-T10-JavaScript-Build-Test-Results.md` (this document)

## Related Documents

- `docs/modernisation/nodejs-upgrade-plan.md` - Phase 1 Node.js audit (on main branch)
- `.github/workflows/ci.yml` - CI configuration with JavaScript build disabled
- `BirchOutline/birch-outline.js/package.json` - Node.js v20 configuration
- `BirchEditor/birch-editor.js/package.json` - Node.js v20 configuration

---

**Conclusion**: P1-T10 successfully tested and documented. JavaScript build system modernization deferred to future phase or eliminated entirely in Phase 4's Pure Swift migration.
