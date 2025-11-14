# Manual Xcode Tasks Required for Phase 1 and Phase 2

**TaskPaper Modernization Initiative**
**Document**: Manual Xcode Task Checklist
**Date**: 2025-11-13
**Status**: Ready for Execution

---

## Table of Contents

1. [Overview](#overview)
2. [Phase 1 Manual Tasks](#phase-1-manual-tasks)
3. [Phase 2 Manual Tasks](#phase-2-manual-tasks)
4. [Estimated Time Summary](#estimated-time-summary)
5. [Execution Order Recommendations](#execution-order-recommendations)

---

## Overview

This document consolidates all manual tasks from Phase 1 and Phase 2 that require Xcode IDE. These tasks cannot be completed through command-line tools or automated scripts and must be performed directly in the Xcode application.

### Why These Tasks Require Xcode

- **Build Settings**: Project configuration requires Xcode project editor
- **SPM Integration**: Adding Swift Package dependencies requires Xcode UI
- **Framework Management**: Linking frameworks and configuring build phases
- **Swift 6 Migration**: Compiler errors only visible in Xcode with proper project settings
- **UI Testing**: Recording and running UI tests requires Xcode Test Navigator
- **Code Coverage**: Coverage configuration and reports require Xcode scheme editor
- **Performance Testing**: Benchmarking and profiling require Xcode Instruments
- **Thread Sanitizer**: Runtime checking requires Xcode debug configuration

### Prerequisites

Before starting any manual tasks:
1. ✅ Ensure all automated Phase 1 and Phase 2 tasks are complete
2. ✅ Pull latest changes from `claude/modernisation-analysis-plan-011CV4jVbyYcHqDADQTiCmnu` branch
3. ✅ Open `TaskPaper.xcodeproj` in Xcode 15.0+
4. ✅ Ensure macOS 11.0+ is installed (project minimum requirement)

---

## Phase 1 Manual Tasks

### P1-T03: Update Xcode Project for SPM Integration

**Status**: 📋 Manual execution required
**Guide**: `docs/modernisation/P1-T03-T06-MANUAL-STEPS.md` (700+ lines)
**Estimated Time**: 1-2 hours
**Risk**: 🟡 Medium

**Activities**:

1. **Remove Carthage Framework Search Paths**
   - Open project build settings
   - Search for "Framework Search Paths"
   - Remove `$(PROJECT_DIR)/Carthage/Build/Mac`
   - Apply to all targets (TaskPaper, BirchOutline, BirchEditor)

2. **Remove Copy Frameworks Build Phase**
   - Open each target's Build Phases
   - Delete "Copy Frameworks" phase that copies Carthage frameworks
   - Verify no references to Sparkle.framework remain

3. **Add Sparkle via SPM**
   - File → Add Package Dependencies
   - Enter URL: `https://github.com/sparkle-project/Sparkle`
   - Select version: 2.6.0 or later
   - Add to TaskPaper target
   - Link Sparkle to TaskPaper target

4. **Update Import Statements**
   - Find: `import Sparkle` (old Carthage import)
   - Verify imports work with SPM version
   - Located in: `TaskPaper/AppDelegate.swift`, `TaskPaper/UpdateChecker.swift`

5. **Build and Verify**
   - Product → Clean Build Folder (⇧⌘K)
   - Product → Build (⌘B)
   - Verify zero build errors
   - Run app and test auto-update functionality

**Success Criteria**:
- ✅ Build succeeds with zero errors
- ✅ No Carthage framework search paths remain
- ✅ Sparkle 2.6.0+ linked via SPM
- ✅ Auto-update functionality works

---

### P1-T04: Migrate Paddle Framework to Manual Integration

**Status**: 📋 Manual execution required
**Included in**: `docs/modernisation/P1-T03-T06-MANUAL-STEPS.md`
**Estimated Time**: 30 minutes
**Risk**: 🟢 Low

**Activities**:

1. **Download Paddle Framework** (if not already present)
   - Check if `Frameworks/Paddle.framework` exists
   - If missing, download from Paddle SDK v4.4.3+
   - Verify framework is for macOS (not iOS)

2. **Add to Xcode Project**
   - Drag `Paddle.framework` into Xcode project navigator
   - Destination: Copy items if needed ✓
   - Add to targets: TaskPaper ✓

3. **Configure Embedding**
   - Target → General → Frameworks, Libraries, and Embedded Content
   - Set Paddle.framework to "Embed & Sign"
   - Verify code signing is enabled

4. **Verify Licensing Code**
   - Build project (⌘B)
   - Run app
   - Test licensing functionality (if applicable)
   - Verify no runtime errors related to Paddle

**Success Criteria**:
- ✅ Paddle.framework embedded in app bundle
- ✅ Framework properly code signed
- ✅ Licensing code compiles and runs
- ✅ No runtime errors

---

### P1-T05: Remove Carthage from Project

**Status**: 📋 Manual execution required
**Included in**: `docs/modernisation/P1-T03-T06-MANUAL-STEPS.md`
**Estimated Time**: 15 minutes
**Risk**: 🟢 Low

**Activities**:

1. **Delete Carthage Files** (via Xcode or Finder)
   - Delete `Cartfile`
   - Delete `Cartfile.resolved`
   - Delete `Carthage/` directory (entire directory)
   - Move to Trash

2. **Update .gitignore**
   - Open `.gitignore` in Xcode or text editor
   - Remove Carthage entries:
     ```
     # Remove these lines:
     Carthage/
     Cartfile.resolved
     ```
   - Add SPM entries (if not already present):
     ```
     # Swift Package Manager
     .swiftpm/
     .build/
     ```

3. **Clean and Rebuild**
   - Product → Clean Build Folder (⇧⌘K)
   - Product → Build (⌘B)
   - Verify build succeeds
   - Verify no references to Carthage remain

**Success Criteria**:
- ✅ No Cartfile or Carthage/ directory exists
- ✅ .gitignore updated for SPM
- ✅ Build succeeds without Carthage
- ✅ App runs correctly

---

### P1-T21: Add UI Tests for Basic Editor Interaction

**Status**: 📋 Manual execution required
**Guide**: `docs/modernisation/P1-T21-P1-T22-XCODE-REQUIRED.md` (600+ lines)
**Estimated Time**: 3-4 hours
**Risk**: 🟡 Medium

**Activities**:

1. **Create UI Test Target** (if not exists)
   - File → New → Target
   - Select "UI Testing Bundle"
   - Product Name: "TaskPaperUITests"
   - Language: Swift
   - Add to project

2. **Implement UI Tests** (see guide for complete code)
   - `testTypingTask` - Type task text and verify
   - `testTypingProject` - Type project text with colon
   - `testTypingTag` - Type @tag syntax
   - `testFolding` - Test fold/unfold items
   - `testSearchBar` - Test filtering
   - `testIndentation` - Test Tab/Shift-Tab
   - `testBasicEditing` - Test typing, editing, deleting
   - `testDocumentSaveLoad` - Test document persistence
   - `testPerformanceTyping` - Measure typing performance
   - `testPerformanceScrolling` - Measure scrolling performance

3. **Add Accessibility Identifiers** (if needed)
   - Open storyboards or view controllers
   - Add identifiers to key UI elements:
     - Text view: `"mainTextEditor"`
     - Search field: `"searchField"`
     - Sidebar: `"itemSidebar"`

4. **Run UI Tests**
   - Product → Test (⌘U)
   - Or: Test Navigator → Run all UI tests
   - Verify all tests pass
   - Fix any failures

**Success Criteria**:
- ✅ TaskPaperUITests target created
- ✅ 10+ UI test methods implemented
- ✅ All UI tests pass
- ✅ Tests can be run via Xcode Test Navigator

---

### P1-T22: Configure Code Coverage Reporting

**Status**: 📋 Manual execution required
**Guide**: `docs/modernisation/P1-T21-P1-T22-XCODE-REQUIRED.md`
**Estimated Time**: 1-2 hours
**Risk**: 🟢 Low

**Activities**:

1. **Enable Coverage in Test Schemes**
   - Product → Scheme → Edit Scheme (⌘<)
   - Select "Test" action
   - Options tab
   - Enable "Code Coverage" ✓
   - Select "Gather coverage for some targets" ✓
   - Check: TaskPaper, BirchOutline, BirchEditor

2. **Set Coverage Targets**
   - Create `xcov.yml` (optional, for automation):
     ```yaml
     minimum_coverage_percentage: 60.0
     ignore_file_path:
       - ".*Tests.swift"
       - ".*Mock.swift"
     ```

3. **Run Tests with Coverage**
   - Product → Test (⌘U)
   - Wait for tests to complete
   - View coverage: Product → Show Code Coverage

4. **Generate Coverage Reports**
   - Command line (for CI/CD):
     ```bash
     xcodebuild test \
       -scheme TaskPaper \
       -enableCodeCoverage YES \
       -resultBundlePath TestResults.xcresult

     xcrun xccov view --report TestResults.xcresult
     ```

5. **Export Coverage Data**
   - JSON format:
     ```bash
     xcrun xccov view --report --json TestResults.xcresult > coverage.json
     ```
   - HTML format (requires xcpretty):
     ```bash
     xcpretty --report html
     ```

**Success Criteria**:
- ✅ Code coverage enabled in schemes
- ✅ Baseline coverage: 60%+ (Phase 1)
- ✅ Coverage reports generated successfully
- ✅ Coverage data exportable for CI/CD

---

## Phase 2 Manual Tasks

### P2-T01: Swift 6 Language Mode Upgrade

**Status**: 🔴 **CRITICAL** - Requires 2-3 weeks of dedicated Xcode work
**Guide**: `docs/modernisation/Phase-2-Planning.md` (Section: P2-T01)
**Estimated Time**: 2-3 weeks (80-120 hours)
**Risk**: 🔴 High

This is the **most critical and time-consuming** manual task in the entire modernization effort.

#### Stage 1: Audit (Week 1)

**Activities**:
1. **Global State Inventory** (in Xcode)
   - Search project: `var.*=.*{` (global variables)
   - Search project: `static.*var` (static properties)
   - Search project: `static.*let` (static constants)
   - Document each: file, line, purpose, thread-safety status

2. **API Surface Analysis**
   - Review public/open methods in each module
   - Identify synchronous methods that should be async
   - Map call chains (who calls what)
   - Document breaking changes

3. **JavaScriptCore Strategy**
   - Search project: `import JavaScriptCore` (find all 89 usages)
   - Document each: JSContext creation, JSValue usage
   - Plan `@preconcurrency import` strategy
   - Document MainActor isolation decisions

**Deliverable**: `docs/modernisation/Swift-6-Migration-Strategy.md`

---

#### Stage 2: Enable Swift 6 (Week 2, Day 1)

**Activities** (all in Xcode):

1. **Modify Project Build Settings**
   - Open `TaskPaper.xcodeproj`
   - Select project root (blue icon)
   - Select each target (TaskPaper, BirchOutline, BirchEditor)
   - Build Settings tab
   - Search: "Swift Language Version"
   - Change: `Swift 5` → `Swift 6`

2. **Enable Complete Concurrency Checking**
   - Build Settings tab
   - Search: "Strict Concurrency Checking"
   - Set: `SWIFT_CONCURRENCY_COMPLETE_CHECKING = YES`
   - Or add to "Other Swift Flags": `-strict-concurrency=complete`

3. **Build and Collect Errors**
   - Product → Clean Build Folder (⇧⌘K)
   - Product → Build (⌘B)
   - **Expected Result**: Build will FAIL with many errors
   - Issue Navigator → Compiler Errors
   - Export error log:
     ```
     xcodebuild -scheme TaskPaper clean build 2>&1 | tee swift6-migration-errors.log
     ```

4. **Categorize Errors**
   - Tier 1: Critical build errors (MainActor boundaries)
   - Tier 2: Global state isolation warnings
   - Tier 3: JavaScriptCore non-Sendable errors
   - Tier 4: Sendable conformance warnings

**Deliverable**: `swift6-migration-errors.log` (error catalog)

**Time**: 1-2 hours

---

#### Stage 3: Fix Errors (Week 2-3)

**⚠️ CRITICAL**: This is the most time-intensive stage. Each tier must be completed, tested, and committed before proceeding to the next tier.

##### Tier 1: Critical Build Errors (2-3 days)

**Activities** (in Xcode):
1. Address each compiler error one by one
2. Common fixes:
   - Add `@MainActor` to classes/methods
   - Add `nonisolated` to specific methods
   - Use `MainActor.assumeIsolated { }` for verified contexts
3. Build after each fix (⌘B)
4. Commit after each successful build

**Estimated Errors**: 3-10 errors
**Time**: 2-3 days

##### Tier 2: Global State Isolation (3-4 days)

**Activities** (in Xcode):
1. Address ~93 global variables and static properties
2. Common fixes:
   - Add `@MainActor` annotation
   - Add `nonisolated(unsafe)` for verified thread-safe globals
   - Convert to actor-isolated properties
3. Build and test after each batch of 5-10 fixes
4. Commit incremental progress

**Estimated Errors**: 45 global variables + 48 static properties = 93 items
**Time**: 3-4 days

##### Tier 3: JavaScriptCore Non-Sendable (4-5 days)

**Activities** (in Xcode):
1. Add `@preconcurrency import JavaScriptCore` to all files
2. Isolate all JavaScript operations to `@MainActor`
3. Common fixes:
   - Add `@MainActor` to classes using JSContext
   - Ensure all JSValue usage is on main thread
   - Document architectural constraint
4. Build and test after each file
5. Commit incremental progress

**Estimated Errors**: 89 JavaScriptCore usages
**Time**: 4-5 days

##### Tier 4: Sendable Conformance (2-3 days)

**Activities** (in Xcode):
1. Add Sendable conformance to thread-safe value types
2. Common fixes:
   - Add `: Sendable` to struct/enum definitions
   - Add `@unchecked Sendable` with thread-safety justification
   - Fix any mutable properties preventing Sendable
3. Build and test after each type
4. Commit incremental progress

**Estimated Errors**: 10-20 types
**Time**: 2-3 days

**⚠️ WARNING**: This stage requires **compiler-driven development**. You cannot predict all errors upfront due to cascading error patterns. Budget 30-50% time buffer.

---

#### Stage 4: Testing (Week 3, Days 4-5)

**Activities** (in Xcode):

1. **Run Full Test Suite**
   - Product → Test (⌘U)
   - Verify all 180+ tests pass
   - Fix any test failures
   - Repeat until 100% pass rate

2. **Enable Thread Sanitizer**
   - Product → Scheme → Edit Scheme
   - Run action → Diagnostics tab
   - Enable "Thread Sanitizer" ✓
   - Product → Test (⌘U)
   - Fix any threading issues reported

3. **Manual Smoke Testing**
   - Product → Run (⌘R)
   - Test key workflows:
     - Create new document
     - Type tasks, projects, tags
     - Fold/unfold items
     - Search and filter
     - Save and reload document
     - Test on macOS 11, 12, 13, 14 (if possible)

4. **Performance Validation**
   - Product → Profile (⌘I)
   - Select "Time Profiler" instrument
   - Perform typing test (100 characters)
   - Perform scrolling test (1000 items)
   - Compare with Phase 1 baseline
   - **Accept**: <10% regression
   - **Investigate**: 10-20% regression
   - **Reject**: >20% regression (requires architectural rethink)

**Success Criteria**:
- ✅ All 180+ tests pass
- ✅ Thread Sanitizer passes (zero errors)
- ✅ Manual smoke tests pass
- ✅ Performance within 10% of baseline

**Time**: 2-3 days

---

#### Stage 5: Documentation (Week 3, Day 5)

**Activities**:
1. Update `Swift-6-Migration-Strategy.md` with final decisions
2. Document all `nonisolated(unsafe)` annotations with justification
3. Document all `@unchecked Sendable` with thread-safety proof
4. Document JavaScriptCore isolation strategy
5. Add inline comments for non-obvious actor isolation

**Time**: 4-6 hours

---

### P2-T02: Integrate Protocol Files into Xcode Project

**Status**: 🔄 Files created, awaiting Xcode integration
**Guide**: This section
**Estimated Time**: 30 minutes
**Risk**: 🟢 Low
**Priority**: ⚡ High - Blocks protocol-based dependency injection

**Background**:

The protocol-oriented design work (P2-T13 to P2-T19) has been completed, creating:
- Protocol definitions: `StyleSheetProtocol`, `OutlineDocumentProtocol`
- Mock implementations: `MockStyleSheet`, `MockOutlineEditor`, `MockOutlineDocument`
- Example tests: `MockUsageExamplesTests`
- Documentation: `Protocol-Testing-Patterns.md`

However, the protocol files were created but **not added to the Xcode project**, causing build errors. The code that references these protocols has been temporarily reverted.

**Files Ready for Integration**:

```
BirchEditor/BirchEditor.swift/BirchEditor/Protocols/
├── StyleSheetProtocol.swift          [NEEDS: BirchEditor target]
└── OutlineDocumentProtocol.swift     [NEEDS: BirchEditor target]

BirchEditor/BirchEditor.swift/BirchEditorTests/Mocks/
├── MockStyleSheet.swift              [NEEDS: BirchEditorTests target]
├── MockOutlineEditor.swift           [NEEDS: BirchEditorTests target]
└── MockOutlineDocument.swift         [NEEDS: BirchEditorTests target]

BirchEditor/BirchEditor.swift/BirchEditorTests/Examples/
└── MockUsageExamplesTests.swift      [NEEDS: BirchEditorTests target]
```

**Activities** (in Xcode):

**Step 1: Add Protocol Files to BirchEditor Target**

1. Open `TaskPaper.xcodeproj` in Xcode
2. In Project Navigator, select `BirchEditor/BirchEditor.swift/BirchEditor/` folder
3. Right-click → "Add Files to BirchEditor..."
4. Navigate to `BirchEditor/BirchEditor.swift/BirchEditor/Protocols/`
5. Select both protocol files:
   - `StyleSheetProtocol.swift`
   - `OutlineDocumentProtocol.swift`
6. In the dialog:
   - ✓ Check "Copy items if needed" (leave unchecked - files already in place)
   - ✓ Check "Create groups"
   - ✓ Check target: "BirchEditor"
7. Click "Add"
8. Verify files appear in project with target membership

**Step 2: Add Mock Files to BirchEditorTests Target**

1. In Project Navigator, select `BirchEditor/BirchEditor.swift/BirchEditorTests/` folder
2. Right-click → "Add Files to BirchEditorTests..."
3. Navigate to `BirchEditor/BirchEditor.swift/BirchEditorTests/Mocks/`
4. Select all mock files:
   - `MockStyleSheet.swift`
   - `MockOutlineEditor.swift`
   - `MockOutlineDocument.swift`
5. In the dialog:
   - ✓ Check target: "BirchEditorTests"
6. Click "Add"

**Step 3: Add Example Tests to BirchEditorTests Target**

1. Navigate to `BirchEditor/BirchEditor.swift/BirchEditorTests/Examples/`
2. Add file:
   - `MockUsageExamplesTests.swift`
3. Target: "BirchEditorTests"

**Step 4: Verify Build**

1. Build project (⌘B)
2. Should compile without "cannot find type" errors
3. If errors persist, check target membership:
   - Select each file in Project Navigator
   - File Inspector (⌘⌥1)
   - Target Membership section
   - Verify correct targets are checked

**Step 5: Reapply Protocol Usage** (Git)

Once the files build successfully, reapply the protocol usage code:

```bash
# The following commits were reverted to fix build:
# - bfb2af2: P2-T19: Update dependency injection points to use StyleSheetProtocol
# - 463fc7b: P2-T15/T16: Add OutlineDocumentProtocol and OutlineDocument conformance

# Option 1: Cherry-pick the original commits
git cherry-pick bfb2af2
git cherry-pick 463fc7b

# Option 2: Manually reapply changes (if conflicts):
# See commit diffs for exact changes needed
```

**Step 6: Run Tests**

1. Product → Test (⌘U)
2. Verify `MockUsageExamplesTests` pass
3. All 6 test methods should pass:
   - `testMockStyleSheet_BasicUsage`
   - `testMockStyleSheet_KeyPathStubbing`
   - `testMockOutlineEditor_SerializationStubbing`
   - `testMockOutlineDocument_BasicUsage`
   - `testComponentWithMultipleMocks`
   - `testPerformanceComparison`

**Success Criteria**:
- ✅ All protocol files in BirchEditor target
- ✅ All mock files in BirchEditorTests target
- ✅ Project builds without "cannot find type" errors
- ✅ Protocol usage code reapplied successfully
- ✅ All example tests pass

**Documentation**:
- See `docs/modernisation/Protocol-Testing-Patterns.md` for usage guide
- See `BirchEditorTests/Examples/MockUsageExamplesTests.swift` for examples

**Time**: 30 minutes

**Next Step**: Once integrated, use protocols for dependency injection in view controllers to enable testability without JavaScriptCore overhead.

---

### P2-T07: Remove NSWindowTabbedBase Swizzling

**Status**: 📋 Manual execution required
**Guide**: `documentation/method-swizzling-audit.md` (Section: NSWindowTabbedBase)
**Estimated Time**: 1-2 hours
**Risk**: 🟢 Low

**Activities** (in Xcode):

1. **Research Window Tabbing**
   - Open `BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorWindow.swift:22`
   - Review NSWindowTabbedBase usage
   - Understand why it was created (likely macOS 10.12 bug workaround)

2. **Test Without Swizzling**
   - Comment out NSWindowTabbedBase usage
   - Build (⌘B)
   - Run app (⌘R)
   - Test window tabbing:
     - File → New Window
     - Window → Merge All Windows
     - Drag window tab to separate
     - Close window tab
   - Test on macOS 11+ (Big Sur redesigned window system)

3. **Remove Swizzling** (if tests pass)
   - Delete files:
     - `BirchEditor/BirchEditor.swift/BirchEditor/NSWindowTabbedBase.h`
     - `BirchEditor/BirchEditor.swift/BirchEditor/NSWindowTabbedBase.m`
   - Remove from Xcode project
   - Update `OutlineEditorWindow.swift` to use `NSWindow` directly
   - Build and test

4. **Commit Changes**
   ```bash
   git add -A
   git commit -m "P2-T07: Remove NSWindowTabbedBase swizzling (no longer needed on macOS 11+)"
   ```

**Success Criteria**:
- ✅ Window tabs work correctly without swizzling
- ✅ NSWindowTabbedBase files deleted
- ✅ Build succeeds
- ✅ Manual testing passes

---

### P2-T08: Measure NSTextStorage Swizzling Performance

**Status**: 📋 Manual execution required
**Guide**: `documentation/method-swizzling-audit.md` (Section: NSTextStorage-Performance)
**Estimated Time**: 2-3 hours
**Risk**: 🟡 Medium

**Activities** (in Xcode):

1. **Create Performance Test**
   - Open `BirchEditor/BirchEditor.swift/BirchEditorTests/`
   - Create new test file: `NSTextStoragePerformanceTests.swift`
   - Implement benchmark:
     ```swift
     func testTextStoragePerformanceWithSwizzling() {
         measure {
             // Perform 1000 characterAtIndex calls
             // Perform 100 substringWithRange calls
         }
     }
     ```

2. **Benchmark WITH Swizzling** (Baseline)
   - Ensure `NSTextStorage-Performance.m` is compiled
   - Product → Test (⌘U)
   - Run performance test
   - Record baseline time (e.g., "0.125s average")

3. **Benchmark WITHOUT Swizzling**
   - Remove `NSTextStorage-Performance.m` from target
   - Build (⌘B)
   - Product → Test (⌘U)
   - Run performance test
   - Record new time (e.g., "0.138s average")

4. **Calculate Impact**
   - Formula: `((new_time - baseline_time) / baseline_time) * 100%`
   - Example: `((0.138 - 0.125) / 0.125) * 100% = 10.4%`

5. **Document Results**
   - Create: `docs/modernisation/nstextstorage-swizzling-performance.md`
   - Include: baseline time, new time, percentage impact
   - Include: test methodology, hardware specs
   - Include: recommendation (remove/keep/discuss)

**Deliverable**: `docs/modernisation/nstextstorage-swizzling-performance.md`

**Decision Matrix**:
- **<10% impact**: Remove swizzling (proceed to P2-T09 Option A)
- **10-20% impact**: Discuss with user (proceed to P2-T09 Option B)
- **>20% impact**: Keep swizzling (proceed to P2-T09 Option C)

---

### P2-T09: Remove or Refactor NSTextStorage Swizzling

**Status**: 📋 Manual execution required (depends on P2-T08 results)
**Guide**: `documentation/method-swizzling-audit.md` (Section: NSTextStorage-Performance)
**Estimated Time**: 1-3 hours (depends on option)
**Risk**: 🟡 Medium

#### Option A: Remove (<10% impact)

**Activities** (in Xcode):
1. Delete files:
   - `NSTextStorage-Performance.h`
   - `NSTextStorage-Performance.m`
2. Remove from Xcode project
3. Build (⌘B)
4. Run performance tests
5. Verify no regressions
6. Commit:
   ```bash
   git add -A
   git commit -m "P2-T09: Remove NSTextStorage swizzling (<10% performance impact)"
   ```

**Time**: 1 hour

#### Option B: Refactor (10-20% impact)

**Activities** (in Xcode):
1. Create explicit optimized methods (not swizzling)
2. Document performance justification
3. Add performance regression tests
4. Build and test
5. Commit with documentation

**Time**: 2-3 hours

#### Option C: Keep (>20% impact)

**Activities**:
1. Document why swizzling is needed
2. Add inline comments to `.m` file
3. Add TODO for future optimization
4. Update `method-swizzling-audit.md`
5. Commit documentation

**Time**: 1 hour

**Success Criteria**:
- ✅ Decision documented based on performance data
- ✅ Changes tested and committed
- ✅ Performance regression tests added (Options A/B)

---

### P2-T10: Handle NSTextView Accessibility Swizzling

**Status**: 📋 Manual execution required
**Guide**: `documentation/method-swizzling-audit.md` (Section: NSTextView-AccessibilityPerformanceHacks)
**Estimated Time**: 2-4 hours
**Risk**: 🟡 Medium (🔴 High for accessibility users)

**Activities** (in Xcode):

1. **Test Accessibility on Multiple macOS Versions**
   - Enable VoiceOver: System Preferences → Accessibility → VoiceOver → Enable
   - Test WITH swizzling:
     - Open TaskPaper
     - Create large document (100+ items)
     - Navigate with VoiceOver
     - Measure: time to speak each item, beach ball occurrences
   - Test WITHOUT swizzling:
     - Remove `NSTextView-AccessibilityPerformanceHacks.m` from target
     - Build and run
     - Repeat VoiceOver tests
     - Measure performance

2. **Compare Results**
   - Document: macOS version, VoiceOver performance, beach ball count
   - Test matrix:
     - macOS 11 Big Sur (VoiceOver rewrite)
     - macOS 12 Monterey
     - macOS 13 Ventura
     - macOS 14 Sonoma

3. **Decision**
   - **If macOS 11+ performs well**: Remove swizzling entirely
   - **If macOS 11+ still has issues**: Add version check
     ```objc
     if (@available(macOS 11.0, *)) {
         // Use normal accessibility
         return [super accessibilityTextLinks];
     } else {
         // Use swizzled version for older macOS
         return nil;
     }
     ```
   - **If still needed on all versions**: Keep with documentation

4. **Implement Decision**
   - Remove files (if not needed) OR
   - Add version check (if conditional) OR
   - Document justification (if keep)
   - Build and test
   - Commit changes

**⚠️ CRITICAL**: This swizzling affects accessibility. Test thoroughly with VoiceOver users if possible.

**Success Criteria**:
- ✅ VoiceOver performance tested on macOS 11+
- ✅ Decision documented with test results
- ✅ Changes committed and tested
- ✅ No beach balls during VoiceOver navigation

---

### P2-T23: Add Async Operation Tests

**Status**: 📋 Manual execution required (depends on P2-T01-P2-T05 completion)
**Guide**: `docs/modernisation/Phase-2-Planning.md` (Section: P2-T23)
**Estimated Time**: 4-6 hours
**Risk**: 🟡 Medium

**Activities** (in Xcode):

1. **Create Test File**
   - File → New → File → Swift File
   - Name: `AsyncOperationTests.swift`
   - Location: `BirchEditor/BirchEditor.swift/BirchEditorTests/`
   - Target: BirchEditorTests ✓

2. **Implement Async Tests** (see Phase-2-Planning.md for complete code)
   - `testAsyncDelayTiming` - Verify delay accuracy
   - `testAsyncDelayDispatching` - Test cancellation
   - `testRemindersStoreAsync` - Test async RemindersStore methods
   - `testDebouncerActor` - Test actor isolation
   - `testConcurrentEdits` - Test concurrent outline modifications
   - `testActorIsolationBoundaries` - Test MainActor calls
   - `testDeadlockScenarios` - Test for potential deadlocks

3. **Run Tests**
   - Product → Test (⌘U)
   - Verify all async tests pass
   - Fix any failures or flakiness

4. **Enable Thread Sanitizer**
   - Product → Scheme → Edit Scheme
   - Test action → Diagnostics tab
   - Enable "Thread Sanitizer" ✓
   - Run tests again
   - Fix any threading issues

**Success Criteria**:
- ✅ 7+ async operation tests implemented
- ✅ All tests pass consistently (no flakiness)
- ✅ Thread Sanitizer passes with zero errors
- ✅ Tests cover delay, async/await, actors, concurrency

---

## Estimated Time Summary

### Phase 1 Manual Tasks

| Task | Time | Risk | Priority |
|------|------|------|----------|
| P1-T03: SPM Integration | 1-2 hours | 🟡 Medium | High |
| P1-T04: Paddle Framework | 30 minutes | 🟢 Low | High |
| P1-T05: Remove Carthage | 15 minutes | 🟢 Low | High |
| P1-T21: UI Tests | 3-4 hours | 🟡 Medium | Medium |
| P1-T22: Code Coverage | 1-2 hours | 🟢 Low | Medium |
| **Phase 1 Total** | **6-9 hours** | | |

### Phase 2 Manual Tasks

| Task | Time | Risk | Priority |
|------|------|------|----------|
| P2-T01: Swift 6 Migration | 80-120 hours (2-3 weeks) | 🔴 High | **CRITICAL** |
| P2-T02: Protocol Integration | 30 minutes | 🟢 Low | High |
| P2-T07: NSWindowTabbedBase | 1-2 hours | 🟢 Low | Medium |
| P2-T08: Benchmark NSTextStorage | 2-3 hours | 🟡 Medium | Medium |
| P2-T09: Remove/Keep NSTextStorage | 1-3 hours | 🟡 Medium | Medium |
| P2-T10: Accessibility Testing | 2-4 hours | 🟡 Medium | Medium |
| P2-T23: Async Tests | 4-6 hours | 🟡 Medium | High |
| **Phase 2 Total** | **90.5-138.5 hours** | | |

### Grand Total

**Total Estimated Time**: 96.5-147.5 hours (12-18 days of full-time work)

**Critical Path**: P2-T01 (Swift 6 Migration) is the longest and most complex task

---

## Execution Order Recommendations

### Order 1: Complete Phase 1 First (Recommended)

This approach ensures stable foundation before tackling Swift 6 migration.

**Week 1: Phase 1 Foundation**
1. ✅ P1-T03: SPM Integration (1-2 hours)
2. ✅ P1-T04: Paddle Framework (30 minutes)
3. ✅ P1-T05: Remove Carthage (15 minutes)
4. ✅ P1-T22: Code Coverage (1-2 hours)
5. ✅ P1-T21: UI Tests (3-4 hours)
   - **Checkpoint**: Build, run tests, verify app works

**Week 2-4: Phase 2 Swift 6 Migration (CRITICAL)**
1. 🔴 P2-T01: Swift 6 Migration (2-3 weeks full-time)
   - Week 2: Audit + Enable Swift 6 + Tier 1/2
   - Week 3: Tier 3/4 + Testing
   - Week 4: Documentation + cleanup
   - **Checkpoint**: Build in Swift 6 mode, all tests pass

**Week 5: Phase 2 Remaining Tasks**
1. ✅ P2-T07: NSWindowTabbedBase (1-2 hours)
2. ✅ P2-T08: Benchmark NSTextStorage (2-3 hours)
3. ✅ P2-T09: Remove/Keep NSTextStorage (1-3 hours)
4. ✅ P2-T10: Accessibility Testing (2-4 hours)
5. ✅ P2-T23: Async Tests (4-6 hours)
   - **Final Checkpoint**: Full test suite, performance validation

---

### Order 2: Interleaved Approach (Alternative)

This approach mixes Phase 1 and Phase 2 tasks, useful if Swift 6 migration is blocked.

**Week 1: Foundation + Quick Wins**
1. P1-T03-T05: SPM + Carthage removal (2-3 hours)
2. P2-T07: NSWindowTabbedBase (1-2 hours)
3. P1-T22: Code Coverage (1-2 hours)

**Week 2-4: Swift 6 Migration (Core Focus)**
1. P2-T01: Swift 6 Migration (2-3 weeks)

**Week 5: Testing + Performance**
1. P1-T21: UI Tests (3-4 hours)
2. P2-T08-T09: NSTextStorage performance (3-6 hours)
3. P2-T10: Accessibility (2-4 hours)
4. P2-T23: Async Tests (4-6 hours)

---

### Critical Success Factors

1. **P2-T01 Requires Dedicated Time**
   - Block out 2-3 weeks with minimal interruptions
   - Swift 6 migration requires deep focus and sustained effort
   - Compiler-driven development means unpredictable iteration cycles

2. **Test After Every Change**
   - Run full test suite after each phase
   - Use Thread Sanitizer to catch concurrency issues
   - Manual smoke testing before moving to next task

3. **Rollback Safety**
   - Commit after each completed task
   - Keep detailed notes of changes
   - Be prepared to revert if blocked

4. **Performance Monitoring**
   - Benchmark before/after each change
   - Accept <10% regression as reasonable
   - Investigate >10% regression carefully

5. **Documentation**
   - Document all `nonisolated(unsafe)` usage
   - Document all `@unchecked Sendable` with justification
   - Keep migration log for lessons learned

---

## Notes and Warnings

### ⚠️ Swift 6 Migration (P2-T01) Warnings

1. **Cascading Errors**: Each fix may reveal new errors (1.33× multiplier observed in Phase 1)
2. **JavaScriptCore Blocker**: 89 usages of non-Sendable types (fundamental Apple limitation)
3. **Time Buffer**: Budget 30-50% extra time beyond estimates
4. **Rollback Option**: If truly blocked, can revert to Swift 5.0

### ⚠️ Method Swizzling Warnings

1. **Accessibility Risk**: NSTextView swizzling breaks VoiceOver - test thoroughly
2. **Performance Trade-offs**: NSTextStorage swizzling may be needed for performance
3. **Version Checks**: Consider conditional swizzling based on macOS version

### ⚠️ Testing Warnings

1. **UI Tests Flakiness**: UI tests can be flaky - may need timing adjustments
2. **Thread Sanitizer Overhead**: TSan adds ~5× overhead - expect slower tests
3. **Coverage Targets**: 60% is baseline, 70% is Phase 2 target

---

## Support Resources

- **Phase 1 Guide**: `docs/modernisation/P1-T03-T06-MANUAL-STEPS.md`
- **Phase 1 UI/Coverage Guide**: `docs/modernisation/P1-T21-P1-T22-XCODE-REQUIRED.md`
- **Phase 2 Planning**: `docs/modernisation/Phase-2-Planning.md`
- **Method Swizzling Audit**: `documentation/method-swizzling-audit.md`
- **Swift 6 Analysis**: Available on main branch from Phase 1

---

**Document End** | Last Updated: 2025-11-13
