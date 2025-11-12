# Node.js Upgrade Plan - birch-outline.js

## Current Environment

**Node.js Version Requirement:** Not specified in package.json (no `engines.node` field)

**Package Manager:** npm

**Current Package:** birch-outline v0.2.1

**Note:** The absence of a Node.js version constraint in package.json means the project may have been developed for an older Node.js version (likely v11.15.0 based on the modernization plan context). The legacy dependencies and build tools suggest this package was last updated around 2019-2020.

## Security Audit Results

**Total Vulnerabilities:** 54

### Breakdown by Severity:
- **Critical:** 18 vulnerabilities
- **High:** 27 vulnerabilities
- **Moderate:** 8 vulnerabilities
- **Low:** 1 vulnerability
- **Info:** 0 vulnerabilities

### Critical Vulnerabilities Summary:

1. **birch-doc** (devDependency) - No fix available
   - Multiple transitive vulnerabilities via donna, haml-coffee, highlight.js, tello, yargs

2. **coffeelint** - Fix available
   - Via optimist → minimist prototype pollution

3. **crypto-browserify** - Fix available (webpack-stream@7.0.0)
   - Via sha.js missing type checks (CVSS 9.1)

4. **donna** - Fix available
   - Via optimist → minimist

5. **growl** - Fix available (mocha@11.7.5)
   - Command injection vulnerability (CVSS 9.8)

6. **haml-coffee** - No fix available
   - Insecure template handling + optimist vulnerability

7. **loader-utils** - Fix available (webpack-stream@7.0.0)
   - Prototype pollution (CVSS 9.8)

8. **lodash** - Fix available
   - Multiple prototype pollution and command injection issues (CVSS up to 9.1)

9. **minimist** - Fix available (webpack-stream@7.0.0)
   - Prototype pollution (CVSS 9.8)

10. **mkdirp** - Fix available (mocha@11.7.5)
    - Via minimist

11. **mocha** (devDependency) - Fix available (v11.7.5, breaking change)
    - Multiple vulnerabilities via debug, diff, growl, mkdirp

12. **node-libs-browser** - Fix available (webpack-stream@7.0.0)
    - Via crypto-browserify

13. **optimist** - Fix available (webpack-stream@7.0.0)
    - Via minimist prototype pollution

14. **sha.js** - Fix available (webpack-stream@7.0.0)
    - Missing type checks (CVSS 9.1)

15. **tello** - Fix available
    - Via atomdoc, optimist, underscore

16. **underscore** - Fix available
    - Arbitrary code execution (CVSS 9.8)

17. **webpack** - Fix available (webpack-stream@7.0.0)
    - Via loader-utils, node-libs-browser, optimist

18. **webpack-stream** (devDependency) - Fix available (v7.0.0, breaking change)
    - Via gulp-util, webpack

### High-Risk Direct Dependencies:
- `birch-doc@0.0.2` (devDependency) - **CRITICAL** - No fix available
- `gulp@3.9.1` (devDependency) - **HIGH** - Fix available (v5.0.1, breaking change)
- `gulp-clean@0.3.2` (devDependency) - **HIGH** - Fix available (v0.4.0, breaking change)
- `gulp-coffee@2.3.2` (devDependency) - **HIGH** - Fix available (v3.0.3, breaking change)
- `gulp-coffeelint@0.6.0` (devDependency) - **HIGH** - No fix available
- `gulp-mocha@3.0.1` (devDependency) - **HIGH** - Fix available (v10.0.1, breaking change)
- `gulp-shell@0.5.2` (devDependency) - **HIGH** - Fix available (v0.8.0, breaking change)
- `gulp-util@3.0.7` (devDependency) - **HIGH** - Via lodash.template command injection
- `mocha@3.1.2` (devDependency) - **CRITICAL** - Fix available (v11.7.5, breaking change)
- `webpack-stream@3.2.0` (devDependency) - **CRITICAL** - Fix available (v7.0.0, breaking change)

## Outdated Packages

**Total Outdated Packages:** 1 (production dependency only)

| Package | Current | Wanted | Latest | Type | Breaking Change |
|---------|---------|--------|--------|------|-----------------|
| htmlparser2 | 3.10.1 | 3.10.1 | 10.0.0 | production | Yes (major version) |
| ctph.js | 0.0.5 | 0.0.5 | 0.0.5 | production | No |
| event-kit | 2.5.3 | 2.5.3 | 2.5.3 | production | No |
| moment | 2.30.1 | 2.30.1 | 2.30.1 | production | No |
| natives | 1.1.6 | 1.1.6 | 1.1.6 | production | No |
| string-hash | 1.1.3 | 1.1.3 | 1.1.3 | production | No |
| underscore-plus | 1.7.0 | 1.7.0 | 1.7.0 | production | No |

**Note:** The `npm outdated` command shows packages as "MISSING" because node_modules is not currently installed. The version information above reflects what would be installed based on package.json specifications.

### Key Outdated Package:

**htmlparser2**: Currently pinned at `^3.10.1`, latest is `10.0.0`
- **Impact:** This is 7 major versions behind
- **Risk:** May contain unpatched security vulnerabilities
- **Upgrade Path:** Requires testing for breaking API changes

## Migration Assessment

### Node.js v11 → v20 LTS Breaking Changes

#### 1. Deprecated APIs Requiring Updates

**url.parse() → URL Constructor**
- **Status:** `url.parse()` deprecated in Node.js v11+
- **Action Required:** Search codebase for `require('url').parse()` usage
- **Replacement:** Use `new URL()` constructor or WHATWG URL API
- **Impact:** Medium - Common pattern in older Node.js code

**Buffer() Constructor → Buffer.alloc() / Buffer.from()**
- **Status:** `new Buffer()` deprecated in Node.js v10+
- **Action Required:** Search for `new Buffer()` and `Buffer()` without static methods
- **Replacement:** Use `Buffer.alloc()`, `Buffer.allocUnsafe()`, or `Buffer.from()`
- **Impact:** High - Security issue (uninitialized memory)

**crypto.createCipher() → crypto.createCipheriv()**
- **Status:** Deprecated in Node.js v10+
- **Action Required:** Search for `crypto.createCipher()` and `crypto.createDecipher()`
- **Replacement:** Use `crypto.createCipheriv()` and `crypto.createDecipheriv()` with explicit IV
- **Impact:** Medium - Affects cryptographic code

**process.binding() Access**
- **Status:** Internal API removed in Node.js v16+
- **Action Required:** Check if `natives` package (v1.1.6) uses this
- **Replacement:** Native modules must be updated or replaced
- **Impact:** High - May break the `natives` dependency

#### 2. Native Module Recompilation Requirements

**Current Native Dependencies:**
- `natives@1.1.6` - May use deprecated `process.binding()`
- Build tools using native addons (node-gyp dependencies)

**Actions Required:**
1. Verify `natives` package compatibility with Node.js v20
2. Update `node-gyp` to latest version (v10+)
3. Recompile all native modules after Node.js upgrade
4. Test on target platform (macOS 11.0+ per project requirements)

**Potential Issues:**
- Native modules may fail to compile with Node.js v20's V8 engine
- Python 3 requirement for node-gyp (Node.js v12+ dropped Python 2 support)
- Xcode Command Line Tools version compatibility

#### 3. Dependency Compatibility Issues

**High-Priority Compatibility Concerns:**

**Gulp 3.9.1 → 5.0.1**
- Breaking change: Gulp 4+ uses new task system
- Current code uses Gulp 3 syntax: `gulp.task('name', function() {})`
- Must migrate to: `gulp.task('name', gulp.series(...))`
- Impact: **HIGH** - Requires rewriting gulpfile.js

**Mocha 3.1.2 → 11.7.5**
- Breaking changes across 8 major versions
- Mocha 8+ requires Node.js v10+ minimum
- Mocha 9+ requires Node.js v12+ minimum
- Mocha 11+ requires Node.js v14+ minimum
- Impact: **MEDIUM** - Test syntax may need updates

**Webpack-stream 3.2.0 → 7.0.0**
- Webpack 2 → Webpack 5 breaking changes
- Configuration format changes
- Loader/plugin compatibility issues
- Impact: **HIGH** - May require webpack config rewrite

**CoffeeScript Ecosystem**
- `coffee-script@1.7.0` (deprecated) → `coffeescript@2.4.1` (in devDeps)
- Gulp plugins may not support CoffeeScript 2+
- Impact: **MEDIUM** - May need to migrate away from CoffeeScript

**No Fix Available (Blockers):**
- `birch-doc@0.0.2` - Critical vulnerabilities, no updates available
- `gulp-coffeelint@0.6.0` - High vulnerabilities, no updates available
- `haml-coffee` - Critical vulnerabilities, no updates available

#### 4. Node.js v20 LTS New Requirements

**ES Modules (ESM) vs CommonJS:**
- Node.js v12+ supports ES modules
- Node.js v16+ enables ESM by default with `.mjs` or `"type": "module"`
- Current package uses CommonJS exclusively
- Impact: **LOW** - Optional migration, but recommended for future

**Fetch API:**
- Node.js v18+ includes global `fetch()`
- May conflict with polyfills if present
- Impact: **LOW** - Unlikely to affect build tools

**--experimental-* Flags:**
- Many v11-era experimental features are now stable
- Check for usage of experimental flags in npm scripts
- Impact: **LOW** - None found in current package.json

### Recommended Migration Strategy

#### Phase 1: Prepare for Migration (Current Node.js version)
1. Install all dependencies: `npm install`
2. Run existing tests: `npm test`
3. Document current build output and behavior
4. Create feature branch for Node.js upgrade

#### Phase 2: Update Build Tools (Node.js v16)
1. Upgrade to Node.js v16 LTS (intermediate step)
2. Update npm to latest v8.x
3. Update build tools to compatible versions:
   - mocha: v8.4.0 (last version supporting Node.js v10-16)
   - gulp: v4.0.2
   - webpack-stream: v7.0.0
4. Rewrite gulpfile.js for Gulp 4 syntax
5. Test build process thoroughly

#### Phase 3: Address Security Vulnerabilities
1. Run `npm audit fix` to auto-fix non-breaking updates
2. Run `npm audit fix --force` for breaking updates (after testing)
3. Manually address packages with no fix available:
   - Consider removing `birch-doc` or finding alternatives
   - Replace `gulp-coffeelint` with modern linting tools
   - Update or remove `haml-coffee` dependencies

#### Phase 4: Upgrade to Node.js v20 LTS
1. Upgrade to Node.js v20 LTS
2. Update npm to latest v10.x
3. Recompile native modules: `npm rebuild`
4. Run full test suite
5. Fix any remaining compatibility issues

#### Phase 5: Production Dependency Updates
1. Update `htmlparser2` from 3.10.1 → 10.0.0
2. Test parsing functionality thoroughly
3. Review `moment` usage (consider migrating to date-fns or native Temporal API)
4. Verify `natives` package compatibility or replace

#### Phase 6: Modernization (Optional but Recommended)
1. Add `engines.node` field to package.json: `">=20.0.0"`
2. Add `engines.npm` field: `">=10.0.0"`
3. Consider migrating from CoffeeScript to TypeScript or modern JavaScript
4. Replace Gulp with npm scripts or modern build tools
5. Update test framework to use modern Mocha features

### Risk Assessment

**High Risk:**
- Gulp 3 → 5 migration (build system rewrite required)
- Native module compilation failures
- `birch-doc` has no security fixes available

**Medium Risk:**
- htmlparser2 API changes (7 major versions behind)
- Mocha test compatibility (8 major versions behind)
- Webpack configuration changes

**Low Risk:**
- Most production dependencies are current
- Node.js v20 maintains good backward compatibility for standard APIs

### Success Criteria

- [ ] All tests pass with Node.js v20 LTS
- [ ] Build process completes without errors
- [ ] Zero critical security vulnerabilities
- [ ] All high-severity vulnerabilities resolved or documented
- [ ] Native modules compile successfully
- [ ] Production dependencies updated to supported versions
- [ ] package.json includes `engines.node: ">=20.0.0"`
- [ ] CI/CD pipeline updated to use Node.js v20
- [ ] Documentation updated with new build requirements
