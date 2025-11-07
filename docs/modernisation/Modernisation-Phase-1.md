# Phase 1: Foundation Modernization (1-2 months)

## Phase Overview

Phase 1 establishes a solid foundation for modernization by addressing build infrastructure, dependency management, and testing capabilities. This phase focuses on low-risk, high-impact improvements that reduce technical debt without disrupting core functionality. The objectives are to migrate from deprecated tools (Carthage, Node.js v11) to modern standards (Swift Package Manager, Node.js LTS), upgrade the Swift language version to enable access to modern features, and establish comprehensive test coverage to safeguard against regressions during subsequent phases. Expected outcomes include improved build reliability, reduced security vulnerabilities from outdated dependencies, enhanced developer experience through modern tooling, and a robust test suite that enables confident refactoring in later phases.

---

## P1-T01: Audit Current Carthage Dependencies

**Component**: Dependency Management  
**Files**:
- `Cartfile`
- `Cartfile.resolved`

**Technical Changes**:
1. Read and document all dependencies declared in `Cartfile`:
   - `github "sparkle-project/Sparkle" ~> 1.2`
   - `github "PaddleHQ/Mac-Framework-V4"`
2. Record exact versions from `Cartfile.resolved`
3. Verify each framework's SPM compatibility by checking respective GitHub repositories
4. Document framework usage locations via `import` statements using grep
5. Create dependency audit document listing: framework name, current version, SPM availability, import locations

**Prerequisites**: None

**Success Criteria**:
```bash
# Verify audit document exists and contains all required information
test -f docs/modernisation/carthage-dependency-audit.txt
grep -q "Sparkle" docs/modernisation/carthage-dependency-audit.txt
grep -q "Paddle" docs/modernisation/carthage-dependency-audit.txt
```

---

## P1-T02: Create Swift Package Manifest

**Component**: Dependency Management  
**Files**:
- `Package.swift` (new)

**Technical Changes**:
1. Create `Package.swift` at repository root
2. Set Swift tools version to 5.9 minimum (compatible with Xcode 15+)
3. Define package with name "TaskPaper"
4. Declare macOS 11.0 platform minimum
5. Add Sparkle dependency using SPM-compatible version:
   ```swift
   .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")
   ```
6. Note: PaddleHQ framework may require manual integration (check availability in audit)
7. Define library products for BirchOutline and BirchEditor frameworks
8. Specify target dependencies matching current module structure

**Prerequisites**: P1-T01

**Success Criteria**:
```bash
# Verify Package.swift exists and is valid
test -f Package.swift
swift package resolve
swift package show-dependencies | grep -q "Sparkle"
```

---

## P1-T03: Update Xcode Project for SPM Integration

**Component**: Build Configuration  
**Files**:
- `TaskPaper.xcodeproj/project.pbxproj`

**Technical Changes**:
1. Open `TaskPaper.xcodeproj` in Xcode
2. Remove Carthage framework search paths from Build Settings:
   - Delete `$(PROJECT_DIR)/Carthage/Build/Mac` from Framework Search Paths
3. Remove Carthage copy-frameworks build phase from all targets:
   - TaskPaper-Direct
   - TaskPaper-AppStore
   - TaskPaper-Setapp
4. Add Swift package dependency through Xcode UI (File > Add Packages)
5. Link Sparkle framework to targets via SPM
6. Update build schemes to remove Carthage-specific steps
7. Configure SPM package resolution settings in project

**Prerequisites**: P1-T02

**Success Criteria**:
```bash
# Verify project builds successfully with SPM
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct -configuration Debug clean build | grep -q "BUILD SUCCEEDED"
# Verify Carthage references removed
! grep -q "Carthage" TaskPaper.xcodeproj/project.pbxproj
```

---

## P1-T04: Handle Paddle Framework Integration

**Component**: Licensing Framework  
**Files**:
- `TaskPaper.xcodeproj/project.pbxproj`
- Potentially new manual framework integration documentation

**Technical Changes**:
1. Verify if PaddleHQ/Mac-Framework-V4 has SPM support
2. If SPM available: Add to `Package.swift` dependencies
3. If SPM unavailable:
   - Document manual integration process in `docs/modernisation/paddle-integration.md`
   - Add Paddle.framework as XCFramework to repository under `Frameworks/` directory
   - Link framework manually in Xcode project settings
   - Update .gitignore to exclude Carthage but include manually managed frameworks
4. Ensure licensing code remains untouched per contribution guidelines

**Prerequisites**: P1-T02, P1-T03

**Success Criteria**:
```bash
# Verify Paddle framework is accessible
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct -configuration Debug -showBuildSettings | grep -q "Paddle"
# Verify licensing code still functions (manual testing required)
echo "Manual verification: Launch app and verify license validation works"
```

---

## P1-T05: Remove Carthage Files and Configuration

**Component**: Dependency Management  
**Files**:
- `Cartfile` (remove)
- `Cartfile.resolved` (remove)
- `Carthage/` directory (remove)
- `.gitignore`

**Technical Changes**:
1. Delete `Cartfile` from repository root
2. Delete `Cartfile.resolved` from repository root
3. Remove `Carthage/` directory entirely: `rm -rf Carthage/`
4. Update `.gitignore` to remove Carthage-specific entries:
   - Remove `Carthage/Build`
   - Remove `Carthage/Checkouts`
5. Add SPM-specific entries to `.gitignore`:
   - Add `.swiftpm/`
   - Add `.build/` (if using command-line SPM)

**Prerequisites**: P1-T03, P1-T04

**Success Criteria**:
```bash
# Verify Carthage files removed
! test -f Cartfile
! test -f Cartfile.resolved
! test -d Carthage
# Verify gitignore updated
grep -q ".swiftpm" .gitignore
# Verify project still builds
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct -configuration Debug build | grep -q "BUILD SUCCEEDED"
```

---

## P1-T06: Update README.md for SPM Instructions

**Component**: Documentation  
**Files**:
- `README.md`

**Technical Changes**:
1. Locate Carthage setup instructions in README.md (search for "carthage")
2. Replace with SPM instructions:
   ```markdown
   ## Dependencies
   
   TaskPaper uses Swift Package Manager for dependency management.
   Dependencies are automatically resolved when opening the Xcode project.
   
   Main dependencies:
   - Sparkle (automatic updates)
   - Paddle (licensing framework - manual integration if needed)
   ```
3. Remove `carthage update` commands from build instructions
4. Update contribution guidelines to mention SPM instead of Carthage
5. Retain JavaScript build instructions (Node.js) - those will be updated in separate tasks

**Prerequisites**: P1-T05

**Success Criteria**:
```bash
# Verify README updated
! grep -q "carthage update" README.md
grep -q "Swift Package Manager" README.md
```

---

## P1-T07: Audit Node.js Dependencies in birch-outline.js

**Component**: JavaScript Build System  
**Files**:
- `BirchOutline/birch-outline.js/package.json`
- `BirchOutline/birch-outline.js/package-lock.json`

**Technical Changes**:
1. Read `package.json` and document all dependencies and devDependencies
2. Check each dependency for known vulnerabilities: `npm audit`
3. Identify dependencies with available updates: `npm outdated`
4. Verify webpack and babel configurations are compatible with Node.js LTS v20
5. Document current Node.js version requirement (v11.15.0) and reasons for upgrade
6. Create upgrade plan document: `docs/modernisation/nodejs-upgrade-plan.md`
7. List breaking changes expected from Node.js 11 → 20 migration

**Prerequisites**: None

**Success Criteria**:
```bash
# Verify audit completed
test -f docs/modernisation/nodejs-upgrade-plan.md
grep -q "Node.js 11.15.0" docs/modernisation/nodejs-upgrade-plan.md
grep -q "Node.js 20" docs/modernisation/nodejs-upgrade-plan.md
```

---

## P1-T08: Update birch-outline.js Package Configuration

**Component**: JavaScript Build System  
**Files**:
- `BirchOutline/birch-outline.js/package.json`
- `BirchOutline/birch-outline.js/.nvmrc` (new)

**Technical Changes**:
1. Update `package.json`:
   - Change `engines.node` from `11.15.0` to `>=20.0.0`
   - Update all devDependencies to latest compatible versions
   - Update webpack to v5+ if currently on v4
   - Update babel packages to latest v7.x versions
2. Create `.nvmrc` file specifying Node.js version: `echo "20" > .nvmrc`
3. Update npm scripts if needed for webpack 5 compatibility
4. Retain `npm link` capability for development workflow
5. Ensure output bundle format remains compatible with JavaScriptCore

**Prerequisites**: P1-T07

**Success Criteria**:
```bash
# Verify package.json updated
cd BirchOutline/birch-outline.js
grep -q ">=20.0.0" package.json
test -f .nvmrc
# Verify dependencies install with Node 20
nvm use 20
npm install
echo $? # Should be 0
```

---

## P1-T09: Update birch-editor.js Package Configuration

**Component**: JavaScript Build System  
**Files**:
- `BirchEditor/birch-editor.js/package.json`
- `BirchEditor/birch-editor.js/.nvmrc` (new)

**Technical Changes**:
1. Update `package.json` (same changes as P1-T08):
   - Change `engines.node` to `>=20.0.0`
   - Update webpack, babel, and other devDependencies to latest versions
2. Create `.nvmrc` file: `echo "20" > .nvmrc`
3. Update build scripts for webpack 5 if applicable
4. Ensure `npm link` integration with birch-outline.js still works
5. Verify output bundle compatibility with JavaScriptCore

**Prerequisites**: P1-T08

**Success Criteria**:
```bash
cd BirchEditor/birch-editor.js
grep -q ">=20.0.0" package.json
test -f .nvmrc
nvm use 20
npm install
echo $? # Should be 0
```

---

## P1-T10: Test JavaScript Build Process with Node.js 20

**Component**: JavaScript Build System  
**Files**:
- `BirchOutline/birch-outline.js/webpack.config.js`
- `BirchEditor/birch-editor.js/webpack.config.js`

**Technical Changes**:
1. Clean existing build artifacts:
   ```bash
   cd BirchOutline/birch-outline.js && rm -rf dist/ node_modules/
   cd BirchEditor/birch-editor.js && rm -rf dist/ node_modules/
   ```
2. Install dependencies with Node.js 20: `npm install` in both directories
3. Run builds: `npm run build` (or appropriate build script)
4. Verify output bundles exist in expected locations
5. Check bundle sizes haven't increased significantly (webpack 5 should reduce size)
6. Verify no runtime errors in console when loading bundles
7. Test `npm link` workflow for development setup

**Prerequisites**: P1-T09

**Success Criteria**:
```bash
# Verify builds complete successfully
cd BirchOutline/birch-outline.js && npm run build
test -f dist/birch-outline.js || test -f dist/index.js
cd ../../BirchEditor/birch-editor.js && npm run build
test -f dist/birch-editor.js || test -f dist/index.js
# Verify Xcode build still works with new bundles
cd ../.. && xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct -configuration Debug build | grep -q "BUILD SUCCEEDED"
```

---

## P1-T11: Update README.md Node.js Requirements

**Component**: Documentation  
**Files**:
- `README.md`

**Technical Changes**:
1. Locate Node.js version requirement in README.md
2. Replace `v11.15.0` with `v20.x LTS or higher`
3. Add recommendation to use nvm: `nvm use 20`
4. Update build instructions to reflect modern npm workflow
5. Verify all JavaScript build commands are documented accurately
6. Add note about `.nvmrc` files for automatic version switching

**Prerequisites**: P1-T10

**Success Criteria**:
```bash
# Verify README updated
! grep -q "11.15.0" README.md
grep -q "20" README.md
grep -qi "nvm" README.md
```

---

## P1-T12: Upgrade Xcode Project to Swift 6 (Compatibility Mode) ⚠️ REVISED

**Status**: ⚠️ **DEFERRED TO PHASE 2** - Swift 6 migration attempt revealed architectural incompatibilities requiring comprehensive planning.

**Component**: Language Version  
**Files**:
- `TaskPaper.xcodeproj/project.pbxproj`

**Original Plan**:
1. Upgrade `SWIFT_VERSION` from `5.0` to `6.0` for all targets
2. Set `SWIFT_CONCURRENCY_COMPLETE_CHECKING` = `minimal` (compatibility mode)
3. Resolve minor compatibility warnings
4. Continue with Phase 1 tasks

**What Actually Happened**:

**Attempt 1: Initial Swift 6 Upgrade** (2025-11-07)
- Changed `SWIFT_VERSION` from `5.0` to `6.0` in project.pbxproj (2 locations)
- Build FAILED with **19 Swift 6 concurrency errors**
- Errors appeared despite compatibility mode expectations

**Attempt 2: Cascading Error Pattern** ("Whack-a-Mole")
- **Round 1**: Fixed 3 errors in Commands.swift with `nonisolated(unsafe)` → revealed 6 new errors
- **Round 2**: Fixed 6 errors across 5 files with `nonisolated(unsafe)` → revealed 3 new errors
- **Round 3**: Fixed 3 errors by adding `@MainActor` to protocols → revealed 3 new errors
- **Total**: 9 errors fixed, 3 errors remaining, pattern suggests 15-40 total hidden errors

**Remaining Errors** (ItemPasteboardUtilities.swift:38, 61, 159):
```
error: call to main actor-isolated instance method 'deserializeItems(_:options:)' 
       in a synchronous nonisolated context
error: call to main actor-isolated instance method 'moveBranches(_:parent:nextSibling:options:)' 
       in a synchronous nonisolated context
```

**Root Cause Analysis**:
1. **Architectural mismatch**: 15-year-old codebase (2005-2018) designed pre-Swift Concurrency (2021)
2. **Mixed codebase**: 256 Objective-C files (58%) + 182 Swift files create interop complexity
3. **JavaScriptCore blocker**: 89 usages of non-Sendable JSContext/JSValue with no workaround
4. **Global mutable state**: 45 global variables + 48 static properties require actor isolation decisions
5. **Synchronous APIs**: Utility methods calling MainActor-isolated code cannot be made async without breaking changes

**Decision: Revert to Swift 5.0** (Path 2 from Swift-Concurrency-Migration-Analysis.md)

**Reversion Actions Taken**:
1. Reverted `SWIFT_VERSION` from `6.0` to `5.0` in project.pbxproj (2 locations)
2. Removed incompatible `@MainActor` annotations from 4 protocols/classes:
   - OutlineEditorHolderType protocol (OutlineEditorType.swift:79)
   - StylesheetHolder protocol (StyleSheet.swift:415)
   - FirstResponderDelegate protocol (SearchBarSearchField.swift:1)
   - SearchBarViewController class (SearchBarViewController.swift:24)
3. **Preserved** 9 `nonisolated(unsafe)` annotations for forward compatibility:
   - Commands.swift:15-17 (3 static properties)
   - OutlineEditorWindow.swift:11-12 (2 global variables)
   - PreferencesWindowController.swift:14 (1 global constant)
   - PreviewTitlebarAccessoryViewController.swift:12 (1 global constant)
   - OutlineEditorTextStorageItem.swift:22 (1 global constant)
   - ChoicePaletteRowView.swift:3 (1 global variable)
4. Verified build succeeds in Swift 5.0 mode: **BUILD SUCCEEDED** ✅

**Key Findings**:
- **Cascading error multiplier**: Each fix revealed 1.17× new errors on average
- **Estimated total scope**: 15-40 errors requiring fixes (vs. 3 visible)
- **Effort estimate**: 2-4 weeks for proper Swift 6 migration (vs. "quick upgrade")
- **Risk assessment**: High - extensive code changes with regression potential

**Lessons Learned**:
1. **Swift 6 compatibility mode myth**: Swift 6 enforces concurrency checking even in "minimal" mode
2. **Architecture matters**: Pre-concurrency codebases require comprehensive migration planning
3. **Tactical fixes create tech debt**: Quick annotations without architectural strategy accumulate
4. **JavaScriptCore constraint**: Core dependency on non-Sendable types has no current solution

**Revised Approach for Future Swift 6 Migration**:
See `Swift-Concurrency-Migration-Analysis.md` for comprehensive analysis of three migration paths:
- **Path 1**: Full concurrency migration (2-4 weeks, high risk) - deferred to Phase 2
- **Path 2**: Revert to Swift 5 (1-2 hours, zero risk) - **EXECUTED** ✅
- **Path 3**: Incremental fixes (3-7 days, unpredictable) - rejected due to whack-a-mole pattern

**Impact on Phase 1**:
- Swift 6 upgrade **DEFERRED to Phase 2** after proper architectural planning
- Remain on Swift 5.0 for Phase 1 completion
- All other Phase 1 tasks proceed as planned
- 9 concurrency annotations preserved for future migration
- No regression to codebase functionality

**Impact on Phase 2**:
- Phase 2 must include comprehensive Swift 6 migration planning
- Allocate 2-4 weeks for proper concurrency adoption
- Consider architectural refactoring of global state
- Monitor Apple's progress on JavaScriptCore Sendable conformance
- Plan for async/await propagation through call chains

**Prerequisites**: P1-T05 (ensure SPM migration complete)

**Success Criteria** (REVISED):
```bash
# Verify Swift version remains at 5.0 (reversion successful)
grep -q "SWIFT_VERSION = 5.0" TaskPaper.xcodeproj/project.pbxproj
# Verify project compiles in Swift 5 mode
xcodebuild -project TaskPaper.xcodeproj -scheme "TaskPaper Direct" -configuration Debug clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO | grep -q "BUILD SUCCEEDED"
# Verify @MainActor annotations removed (4 files)
! grep -q "@MainActor" BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorType.swift
! grep -q "@MainActor" BirchEditor/BirchEditor.swift/BirchEditor/StyleSheet.swift
! grep -q "@MainActor" BirchEditor/BirchEditor.swift/BirchEditor/SearchBarSearchField.swift
! grep -q "@MainActor" BirchEditor/BirchEditor.swift/BirchEditor/SearchBarViewController.swift
# Verify nonisolated(unsafe) annotations preserved (9 annotations across 6 files)
grep -q "nonisolated(unsafe)" BirchEditor/BirchEditor.swift/BirchEditor/Commands.swift
grep -q "nonisolated(unsafe)" BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorWindow.swift
```

**Related Documentation**:
- `Swift-Concurrency-Migration-Analysis.md` - Comprehensive migration analysis and path evaluation
- `docs/modernisation/swift6-upgrade-status.md` - Intermediate migration status (historical)

---

## P1-T13: Resolve Swift 6 Compatibility Warnings ⚠️ NOT APPLICABLE

**Status**: ⚠️ **NOT APPLICABLE** - Task skipped due to P1-T12 deferral.

**Component**: Language Version  
**Files**:
- N/A (Swift 6 not active in Phase 1)

**Original Plan**:
1. Build project and capture all Swift 6 warnings
2. Address only critical warnings that would become errors in strict mode
3. Document remaining warnings in `docs/modernisation/swift6-warnings.md`

**Why Not Applicable**:
- P1-T12 (Swift 6 upgrade) was **deferred to Phase 2** after comprehensive analysis
- Project remains on Swift 5.0 for Phase 1 completion
- Swift 6 compatibility warnings do not exist in Swift 5.0 mode
- This task will be re-evaluated as part of Phase 2 Swift 6 migration planning

**Impact**:
- No action required for Phase 1
- Task will be incorporated into Phase 2 comprehensive Swift 6 migration plan
- See `Swift-Concurrency-Migration-Analysis.md` for future migration strategy

**Prerequisites**: P1-T12 (deferred)

**Success Criteria** (N/A):
```bash
# Verify project builds in Swift 5.0 mode (already verified in P1-T12)
grep -q "SWIFT_VERSION = 5.0" TaskPaper.xcodeproj/project.pbxproj
xcodebuild -project TaskPaper.xcodeproj -scheme "TaskPaper Direct" -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO | grep -q "BUILD SUCCEEDED"
```

---

## P1-T14: Create Test Plan for BirchOutline Module

**Component**: Testing Infrastructure  
**Files**:
- `BirchOutline/BirchOutline.swift/BirchOutlineTests/BirchOutlineTestPlan.xctestplan` (new)

**Technical Changes**:
1. Create Xcode test plan for BirchOutline module
2. Configure test plan settings:
   - Enable code coverage collection
   - Set language/region to English/US
   - Configure test execution order (alphabetical)
3. Include all existing BirchOutline test targets
4. Add test configurations for Debug and Release builds
5. Enable address sanitizer in Debug configuration
6. Document test plan in README.md

**Prerequisites**: None

**Success Criteria**:
```bash
# Verify test plan exists
test -f BirchOutline/BirchOutline.swift/BirchOutlineTests/BirchOutlineTestPlan.xctestplan
# Verify tests run successfully
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchOutline -testPlan BirchOutlineTestPlan | grep -q "Test Succeeded"
```

---

## P1-T15: Add Unit Tests for Outline Core Operations

**Component**: Test Coverage  
**Files**:
- `BirchOutline/BirchOutline.swift/BirchOutlineTests/OutlineCoreTests.swift` (new)

**Technical Changes**:
1. Create `OutlineCoreTests.swift` test file
2. Import XCTest and BirchOutline module
3. Implement tests for core outline operations:
   - `testCreateOutline()`: Verify outline initialization
   - `testAddItem()`: Add items to outline
   - `testRemoveItem()`: Remove items from outline
   - `testMoveItem()`: Move items within outline hierarchy
   - `testItemAttributes()`: Set and get item attributes
   - `testOutlineHierarchy()`: Verify parent-child relationships
   - `testItemSerialization()`: Convert items to string representation
4. Use XCTAssert* functions for validation
5. Ensure tests are isolated (setup/teardown properly)

**Prerequisites**: P1-T14

**Success Criteria**:
```bash
# Verify test file exists
test -f BirchOutline/BirchOutline.swift/BirchOutlineTests/OutlineCoreTests.swift
# Verify tests pass
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchOutline -only-testing:BirchOutlineTests/OutlineCoreTests | grep -q "Test Succeeded"
```

---

## P1-T16: Add Unit Tests for JavaScript Bridge

**Component**: Test Coverage  
**Files**:
- `BirchOutline/BirchOutline.swift/BirchOutlineTests/JavaScriptBridgeTests.swift` (new)

**Technical Changes**:
1. Create `JavaScriptBridgeTests.swift` test file
2. Implement tests for JavaScriptCore bridge:
   - `testJavaScriptContextInitialization()`: Verify BirchOutline.sharedContext creation
   - `testJavaScriptToSwiftTypeBridge()`: Test data type conversions (String, Int, Array, Dict)
   - `testSwiftToJavaScriptTypeBridge()`: Test reverse type conversions
   - `testJavaScriptFunctionInvocation()`: Call JS functions from Swift
   - `testJavaScriptExceptionHandling()`: Verify error propagation
   - `testMemoryManagement()`: Check for retain cycles
3. Use JSContext APIs to verify bridge behavior
4. Test both success and failure scenarios

**Prerequisites**: P1-T14

**Success Criteria**:
```bash
test -f BirchOutline/BirchOutline.swift/BirchOutlineTests/JavaScriptBridgeTests.swift
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchOutline -only-testing:BirchOutlineTests/JavaScriptBridgeTests | grep -q "Test Succeeded"
```

---

## P1-T17: Create Test Plan for BirchEditor Module

**Component**: Testing Infrastructure  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditorTests/BirchEditorTestPlan.xctestplan` (new)

**Technical Changes**:
1. Create Xcode test plan for BirchEditor module (similar to P1-T14)
2. Configure same test plan settings (coverage, sanitizers, etc.)
3. Include all existing BirchEditor test targets
4. Add Debug and Release configurations
5. Enable thread sanitizer in Debug mode (important for text system)

**Prerequisites**: None

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditorTests/BirchEditorTestPlan.xctestplan
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchEditor -testPlan BirchEditorTestPlan | grep -q "Test Succeeded"
```

---

## P1-T18: Add Unit Tests for OutlineEditorTextStorage

**Component**: Test Coverage  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditorTests/OutlineEditorTextStorageTests.swift` (new)

**Technical Changes**:
1. Create `OutlineEditorTextStorageTests.swift` test file
2. Implement tests for custom NSTextStorage subclass:
   - `testTextStorageInitialization()`: Verify setup of OutlineEditorTextStorage
   - `testReplaceCharacters()`: Test character replacement and JS sync
   - `testSetAttributes()`: Verify attribute application
   - `testBidirectionalSync()`: Test JavaScript ↔ NSTextStorage synchronization
   - `testSyncFlagPreventsInfiniteLoop()`: Verify `isUpdatingFromJS` flag works
   - `testEditedNotifications()`: Ensure NSTextStorage notifications fire correctly
3. Mock OutlineEditor dependency using protocols (prepare for P2 protocol extraction)

**Prerequisites**: P1-T17

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditorTests/OutlineEditorTextStorageTests.swift
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchEditor -only-testing:BirchEditorTests/OutlineEditorTextStorageTests | grep -q "Test Succeeded"
```

---

## P1-T19: Add Unit Tests for StyleSheet Compilation

**Component**: Test Coverage  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditorTests/StyleSheetTests.swift` (new)

**Technical Changes**:
1. Create `StyleSheetTests.swift` test file
2. Implement tests for LESS stylesheet compilation:
   - `testLESSCompilation()`: Verify LESS string compiles to CSS
   - `testVariableSubstitution()`: Test `$APPEARANCE`, `$USER_FONT_SIZE`, `$CONTROL_ACCENT_COLOR`
   - `testLightModeStyles()`: Compile with `@appearance: light`
   - `testDarkModeStyles()`: Compile with `@appearance: dark`
   - `testInvalidLESSHandling()`: Verify error handling for malformed LESS
   - `testComputedStyleGeneration()`: Convert compiled CSS to ComputedStyle objects
3. Reference base-stylesheet.less as test fixture
4. Validate NSFont, NSColor extraction from computed styles

**Prerequisites**: P1-T17

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditorTests/StyleSheetTests.swift
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchEditor -only-testing:BirchEditorTests/StyleSheetTests | grep -q "Test Succeeded"
```

---

## P1-T20: Create Integration Test for Document Load/Save

**Component**: Test Coverage  
**Files**:
- `TaskPaperTests/DocumentIntegrationTests.swift` (new)

**Technical Changes**:
1. Create `DocumentIntegrationTests.swift` in TaskPaperTests target
2. Implement end-to-end document tests:
   - `testLoadTaskPaperDocument()`: Load sample .taskpaper file, verify parsing
   - `testSaveTaskPaperDocument()`: Create outline, save, verify file contents
   - `testDocumentRoundTrip()`: Load → modify → save → reload, verify integrity
   - `testProjectParsing()`: Verify lines ending with `:` become projects
   - `testTaskParsing()`: Verify lines starting with `- ` become tasks
   - `testTagParsing()`: Verify `@tag` and `@tag(value)` parsing
   - `testHierarchyPreservation()`: Verify tab-based indentation preserved
3. Use Welcome.txt as test fixture
4. Test all three build targets (Direct, AppStore, Setapp) configurations

**Prerequisites**: P1-T14, P1-T17

**Success Criteria**:
```bash
test -f TaskPaperTests/DocumentIntegrationTests.swift
xcodebuild test -project TaskPaper.xcodeproj -scheme TaskPaper-Direct -only-testing:TaskPaperTests/DocumentIntegrationTests | grep -q "Test Succeeded"
```

---

## P1-T21: Add UI Tests for Basic Editor Interaction

**Component**: Test Coverage  
**Files**:
- `TaskPaperUITests/EditorInteractionUITests.swift` (new, requires new UI test target)

**Technical Changes**:
1. Create TaskPaperUITests target in Xcode project (if not exists)
2. Create `EditorInteractionUITests.swift` file
3. Implement basic UI automation tests:
   - `testLaunchAndCreateDocument()`: Launch app, create new document
   - `testTypeTask()`: Type `- task` and verify outline item created
   - `testTypeProject()`: Type `project:` and verify project formatting
   - `testTypeTag()`: Type `@tag` and verify tag highlighting
   - `testFoldUnfoldItems()`: Click disclosure triangle, verify collapsing
   - `testSearchBarFiltering()`: Enter search query, verify filtered results
4. Use XCUIApplication and XCUIElement APIs
5. Add test plan for UI tests with slower timeout settings

**Prerequisites**: P1-T14

**Success Criteria**:
```bash
# Verify UI test target exists
xcodebuild -project TaskPaper.xcodeproj -list | grep -q "TaskPaperUITests"
# Verify tests pass (may require code signing and running simulator)
xcodebuild test -project TaskPaper.xcodeproj -scheme TaskPaper-Direct -only-testing:TaskPaperUITests/EditorInteractionUITests | grep -q "Test Succeeded"
```

---

## P1-T22: Configure Code Coverage Reporting

**Component**: Testing Infrastructure  
**Files**:
- `TaskPaper.xcodeproj/project.pbxproj`
- `.github/workflows/tests.yml` (new, if using CI)

**Technical Changes**:
1. Enable code coverage in Xcode scheme settings:
   - Edit scheme → Test → Options → Code Coverage → Enable
   - Gather coverage for all targets
2. Configure coverage report generation: `xcodebuild test -enableCodeCoverage YES`
3. Set minimum coverage threshold goal: 60% for Phase 1 (baseline)
4. Generate coverage report and save baseline:
   ```bash
   xcodebuild test -project TaskPaper.xcodeproj -scheme TaskPaper-Direct -enableCodeCoverage YES
   xcrun xccov view --report $(find ~/Library/Developer/Xcode/DerivedData -name '*.xcresult' | head -1) > docs/modernisation/phase1-coverage-baseline.txt
   ```
5. Document coverage gaps for future improvement

**Prerequisites**: P1-T15, P1-T16, P1-T18, P1-T19, P1-T20, P1-T21

**Success Criteria**:
```bash
# Verify coverage enabled in scheme
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct -showBuildSettings | grep -q "CODE_COVERAGE"
# Verify coverage report generated
test -f docs/modernisation/phase1-coverage-baseline.txt
grep -q "%" docs/modernisation/phase1-coverage-baseline.txt
```

---

## P1-T23: Document Phase 1 Completion and Metrics

**Component**: Documentation  
**Files**:
- `docs/modernisation/Phase-1-Completion-Report.md` (new)

**Technical Changes**:
1. Create completion report documenting:
   - All tasks completed in Phase 1
   - Dependencies migrated (Carthage → SPM, Node.js 11 → 20)
   - Swift version upgraded (5.0 → 6.0 compatibility mode)
   - Test coverage baseline (target: 60%+)
   - Build time comparison (before/after)
   - Remaining warnings and technical debt
2. Include metrics:
   - Number of unit tests added
   - Number of integration tests added
   - Number of UI tests added
   - Code coverage percentage
   - Build success rate across all targets
3. List known issues and blockers for Phase 2
4. Update main README.md with Phase 1 completion status

**Prerequisites**: P1-T22 (all other tasks complete)

**Success Criteria**:
```bash
test -f docs/modernisation/Phase-1-Completion-Report.md
grep -q "Phase 1 Complete" docs/modernisation/Phase-1-Completion-Report.md
grep -q "Code Coverage" docs/modernisation/Phase-1-Completion-Report.md
```

---

## Phase 1 Summary

**Total Tasks**: 23  
**Estimated Duration**: 1-2 months  
**Key Deliverables**:
- ✅ Swift Package Manager migration complete
- ✅ Node.js updated to LTS version (v20+)
- ✅ Swift 6 compatibility mode enabled
- ✅ Comprehensive test suite with 60%+ coverage
- ✅ CI/CD foundation established
- ✅ Documentation updated for modern tooling

**Phase 1 Success Metrics**:
- All 23 tasks completed and verified
- Zero build failures across all targets (Direct, AppStore, Setapp)
- All tests passing (unit, integration, UI)
- Code coverage ≥ 60%
- No licensing code affected
- README.md accurately reflects new build process
