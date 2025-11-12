# TaskPaper Modernisation: Complete Implementation Roadmap

**Document Version**: 1.0
**Date**: 2025-11-12
**Total Duration**: 12-23 months
**Total Tasks**: 103 tasks across 4 phases

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Phase Overview](#phase-overview)
3. [Phase 1: Foundation Modernization](#phase-1-foundation-modernization)
4. [Phase 2: Async & Safety](#phase-2-async--safety)
5. [Phase 3: UI Modernization](#phase-3-ui-modernization)
6. [Phase 4: Deep Architecture Evolution](#phase-4-deep-architecture-evolution)
7. [Critical Path Analysis](#critical-path-analysis)
8. [Risk Assessment](#risk-assessment)
9. [Success Metrics](#success-metrics)
10. [Getting Started](#getting-started)

---

## Executive Summary

This roadmap outlines the complete modernisation strategy for TaskPaper, transforming a 15-year-old codebase (2005-2018) into a modern Swift application leveraging the latest Apple technologies. The modernisation is structured as 4 sequential phases, each building upon the previous phase's foundation.

### Key Objectives

1. **Eliminate Technical Debt**: Replace deprecated tools (Carthage, Node.js v11) with modern alternatives (SPM, Node.js v20)
2. **Adopt Modern Concurrency**: Migrate to Swift 6 with full async/await and actor isolation
3. **Modernize UI**: Introduce SwiftUI where appropriate, migrate to TextKit 2
4. **Simplify Architecture**: Replace JavaScript bridge with pure Swift implementation
5. **Enhance Integration**: Add iCloud sync, Touch Bar support, modern accessibility

### Overall Timeline

- **Phase 1**: 1-2 months (Foundation)
- **Phase 2**: 3-4 months (Async & Safety) - **Extended due to Swift 6 migration**
- **Phase 3**: 3-6 months (UI Modernization)
- **Phase 4**: 6-12 months (Deep Architecture)
- **Total**: 13-24 months

### Code Coverage Goals

- Phase 1 baseline: 60%
- Phase 2 target: 70%
- Phase 3 target: 75%
- Phase 4 target: 80%

---

## Phase Overview

### Phase 1: Foundation Modernization (1-2 months)
**Status**: Partially Complete
**Focus**: Build infrastructure, dependency management, testing foundation

**Key Deliverables**:
- ✅ Swift Package Manager (replacing Carthage)
- ✅ Node.js v20 LTS (from v11.15.0)
- ⚠️ Swift 6 migration **DEFERRED to Phase 2**
- ✅ Comprehensive test suite (60% coverage)
- ✅ Test plans for BirchOutline and BirchEditor

**Blockers Resolved**:
- Swift 6 attempted but required 2-4 weeks dedicated work
- Reverted to Swift 5.0 to complete Phase 1
- Test plan created but code signing required for execution

### Phase 2: Async & Safety (3-4 months)
**Status**: Planned
**Focus**: Swift 6 migration, async/await, protocol architecture

**Key Deliverables**:
- Swift 6 language mode with comprehensive concurrency adoption
- Async/await throughout codebase
- Protocol-oriented architecture for testability
- Elimination of method swizzling
- 70% code coverage

**Timeline Extension**: +1 month due to Swift 6 complexity

### Phase 3: UI Modernization (3-6 months)
**Status**: Planned
**Focus**: SwiftUI components, TextKit 2, platform features

**Key Deliverables**:
- SwiftUI for preferences, palettes, dialogs
- TextKit 2 migration for main editor
- Touch Bar support
- Modern accessibility APIs
- Enhanced localization
- 75% code coverage

**Dependencies**: Benefits from Phase 2 Swift 6 completion

### Phase 4: Deep Architecture Evolution (6-12 months)
**Status**: Planned
**Focus**: JavaScript elimination, Combine, iCloud sync

**Key Deliverables**:
- Pure Swift outline model (replacing JavaScript)
- Query language parser in Swift
- Combine framework adoption
- iCloud document synchronization
- 80% code coverage
- JavaScript deprecation timeline

**Major Achievement**: 5,000-10,000 lines of JavaScript eliminated

---

## Phase 1: Foundation Modernization

### Overview
Duration: 1-2 months | Tasks: 23 | Status: Partially Complete

### Task List

#### Dependency Management (Tasks 1-6)

**P1-T01: Audit Current Carthage Dependencies**
- Files: `Cartfile`, `Cartfile.resolved`
- Document Sparkle and Paddle frameworks
- Verify SPM compatibility
- Create audit document

**P1-T02: Create Swift Package Manifest**
- Files: `Package.swift` (new)
- Swift tools version 5.9+
- Add Sparkle dependency
- Define library products

**P1-T03: Update Xcode Project for SPM Integration**
- Files: `TaskPaper.xcodeproj/project.pbxproj`
- Remove Carthage framework search paths
- Remove copy-frameworks build phase
- Link SPM dependencies

**P1-T04: Handle Paddle Framework Integration**
- Document manual integration if needed
- Preserve licensing code (per contribution guidelines)
- Test license validation

**P1-T05: Remove Carthage Files and Configuration**
- Delete `Cartfile`, `Cartfile.resolved`, `Carthage/` directory
- Update `.gitignore` for SPM
- Verify build succeeds

**P1-T06: Update README.md for SPM Instructions**
- Replace Carthage documentation with SPM
- Update build instructions
- Document dependency resolution

#### JavaScript Build System (Tasks 7-11)

**P1-T07: Audit Node.js Dependencies in birch-outline.js**
- Files: `BirchOutline/birch-outline.js/package.json`
- Document 54 vulnerabilities (18 critical, 27 high)
- Identify webpack/babel compatibility with Node.js v20
- Create upgrade plan document

**P1-T08: Update birch-outline.js Package Configuration**
- Change `engines.node` to `>=20.0.0`
- Update webpack to v5+
- Update babel to v7.x
- Create `.nvmrc` file

**P1-T09: Update birch-editor.js Package Configuration**
- Mirror birch-outline.js updates
- Ensure npm link compatibility
- Verify JavaScriptCore bundle compatibility

**P1-T10: Test JavaScript Build Process with Node.js 20**
- Clean build artifacts
- Install dependencies with Node.js 20
- Verify output bundles
- Test npm link workflow

**P1-T11: Update README.md Node.js Requirements**
- Replace v11.15.0 with v20.x LTS
- Add nvm usage recommendation
- Document .nvmrc files

#### Swift Version & Testing (Tasks 12-23)

**P1-T12: Upgrade Xcode Project to Swift 6** ⚠️ **REVISED - DEFERRED TO PHASE 2**
- **Status**: DEFERRED after discovering architectural incompatibilities
- **Original Plan**: Upgrade SWIFT_VERSION to 6.0 with minimal concurrency checking
- **What Happened**:
  - Attempted upgrade triggered 19 concurrency errors
  - Fixed 9 errors, revealed 3 more (cascading pattern)
  - Root cause: 15-year-old architecture pre-dates Swift Concurrency
  - JavaScriptCore blocker: 89 usages of non-Sendable types
- **Decision**: Reverted to Swift 5.0, comprehensive migration planned for Phase 2
- **Impact**: 9 `nonisolated(unsafe)` annotations preserved for future compatibility
- **See**: `Swift-Concurrency-Migration-Analysis.md` for detailed analysis

**P1-T13: Resolve Swift 6 Compatibility Warnings** ⚠️ **NOT APPLICABLE**
- Skipped due to P1-T12 deferral

**P1-T14: Create Test Plan for BirchOutline Module**
- Files: `BirchOutline/.../BirchOutlineTests/BirchOutlineTestPlan.xctestplan`
- Configure Thread Sanitizer (Debug only)
- Enable code coverage
- Document test execution

**P1-T15: Add Unit Tests for Outline Core Operations**
- Files: `OutlineCoreTests.swift` (new)
- Test outline initialization, item manipulation
- Test hierarchy management
- Test serialization

**P1-T16: Add Unit Tests for JavaScript Bridge**
- Files: `JavaScriptBridgeTests.swift` (new)
- Test JSContext initialization
- Test type conversions (Swift ↔ JavaScript)
- Test memory management

**P1-T17: Create Test Plan for BirchEditor Module** ⚠️ **PARTIALLY COMPLETE**
- **Status**: Test plan created but code signing blocks execution
- Files: `BirchEditor/.../BirchEditorTests/BirchEditorTestPlan.xctestplan`
- **Blockers**:
  - No BirchEditor scheme in TaskPaper.xcodeproj
  - Code signing required for test execution
  - Test plan exists but cannot be used via xcodebuild
- **Workaround**: Use TaskPaper scheme with `-only-testing` filters
- **See**: `docs/modernisation/P1-T17-final-report.md` for details

**P1-T18: Add Unit Tests for OutlineEditorTextStorage**
- Test bidirectional sync (NSTextStorage ↔ JavaScript)
- Test isUpdatingFromJS flag
- Test attribute management

**P1-T19: Add Unit Tests for StyleSheet Compilation**
- Test LESS → CSS compilation
- Test variable substitution ($APPEARANCE, $USER_FONT_SIZE)
- Test light/dark mode styles

**P1-T20: Create Integration Test for Document Load/Save**
- Test TaskPaper format parsing
- Test document round-trip
- Test project/task/tag parsing
- Use Welcome.txt as fixture

**P1-T21: Add UI Tests for Basic Editor Interaction**
- Create TaskPaperUITests target if needed
- Test typing (tasks, projects, tags)
- Test folding/unfolding
- Test search bar filtering

**P1-T22: Configure Code Coverage Reporting**
- Enable coverage in scheme settings
- Set 60% baseline target
- Generate coverage report
- Document coverage gaps

**P1-T23: Document Phase 1 Completion and Metrics**
- Files: `docs/modernisation/Phase-1-Completion-Report.md`
- Document all tasks completed
- Metrics: tests added, coverage %, build times
- List Phase 2 blockers

### Phase 1 Success Criteria

✅ **Completed**:
- SPM migration complete (Carthage removed)
- Node.js v20 LTS upgrade complete
- Test infrastructure established
- 60% code coverage baseline

⚠️ **Deferred**:
- Swift 6 migration → Phase 2 (requires 2-4 weeks dedicated work)
- Some test execution → blocked by code signing

❌ **Remaining**:
- Owner action required: Configure code signing for test execution

---

## Phase 2: Async & Safety

### Overview
Duration: 3-4 months (extended +1 month) | Tasks: 26 | Status: Planned

### Critical Addition: Swift 6 Migration (NEW)

**P2-T00: Swift 6 Migration Planning** (1 week)
- Review `Swift-Concurrency-Migration-Analysis.md` findings
- Design actor isolation strategy for 45 global variables + 48 static properties
- Plan async/await propagation through call chains
- Address JavaScriptCore non-Sendable constraint (89 usages)
- Create detailed migration roadmap with risk mitigation

**P2-T01: Swift 6 Language Mode Upgrade** (2-3 weeks)
- Upgrade SWIFT_VERSION from 5.0 to 6.0
- Systematic actor isolation implementation
- Convert synchronous APIs to async where needed
- Resolve all concurrency violations (estimated 15-40 errors)
- Comprehensive testing and regression prevention

### Task List

#### Async/Await Migration (Tasks 1-5)

**P2-T01: Audit Async Operations and Callback Usage**
- Search for DispatchQueue usage
- Search for @escaping completion handlers
- Create priority list for migration
- Document in `async-audit.md`

**P2-T02: Replace delay() Function with Task.sleep()**
- Files: `BirchEditor/BirchEditor.swift/BirchEditor/delay.swift`
- Create async version with @MainActor
- Deprecate legacy GCD version
- Keep fallback temporarily

**P2-T03: Convert RemindersStore to Full Async/Await**
- Replace completion handlers with async throws
- Use EventKit async APIs
- Update all call sites to use await

**P2-T04: Convert Debouncer to Actor-Based Implementation**
- Replace GCD timer with Actor + Task.sleep
- Ensure thread-safety through actor isolation
- Update usage sites

**P2-T05: Update Delay Call Sites to Use Async Delay**
- Find all delay() calls
- Replace closure syntax with await
- Add async to function signatures
- Wrap in Task if needed

#### Method Swizzling Removal (Tasks 6-10)

**P2-T06: Audit Method Swizzling Usage**
- Files: JGMethodSwizzler.m, NSTextView-AccessibilityPerformanceHacks.m
- Document each swizzled method
- Categorize by risk level
- Create removal plan

**P2-T07: Remove NSWindowTabbedBase Swizzling**
- Delete NSWindowTabbedBase.m
- Use standard NSWindow tabbing APIs
- Test window tab behavior

**P2-T08: Measure Performance Impact of NSTextStorage Swizzling**
- Create performance test harness
- Benchmark with and without swizzling
- Document performance delta
- Decision: keep if >20% impact, remove if <10%

**P2-T09: Remove or Refactor NSTextStorage Performance Swizzling**
- Based on P2-T08 results
- Option A: Remove entirely
- Option B: Refactor to explicit optimized methods

**P2-T10: Handle NSTextView Accessibility Performance Hacks**
- Test accessibility without hacks on macOS 11+
- Remove if macOS fixed issues
- Keep with version check if still needed

#### Protocol-Oriented Design (Tasks 11-19)

**P2-T11: Define OutlineEditorProtocol**
- Files: `Protocols/OutlineEditorProtocol.swift` (new)
- Extract protocol from OutlineEditor concrete type
- Document all requirements
- Ensure Sendable compatibility

**P2-T12: Conform OutlineEditor to OutlineEditorProtocol**
- Add protocol conformance
- Implement any missing requirements
- Verify tests pass

**P2-T13: Define StyleSheetProtocol**
- Extract protocol for LESS compilation
- Define computed style methods

**P2-T14: Conform StyleSheet to StyleSheetProtocol**
- Add conformance
- Run StyleSheetTests to verify

**P2-T15: Define OutlineDocumentProtocol**
- Protocol for document operations
- Abstract NSDocument dependencies

**P2-T16: Conform OutlineDocument to OutlineDocumentProtocol**
- Add conformance
- Run DocumentIntegrationTests

**P2-T17: Create Mock OutlineEditor for Testing**
- Files: `Mocks/MockOutlineEditor.swift` (new)
- Implement protocol with call recording
- Enable dependency injection in tests

**P2-T18: Refactor OutlineEditorTextStorage Tests to Use Mock**
- Update tests to use MockOutlineEditor
- Remove JavaScript context dependencies
- Verify faster test execution

**P2-T19: Add Dependency Injection to OutlineEditorViewController**
- Allow protocol injection for testing
- Default to concrete implementation
- Enable mock injection in tests

#### Concurrency Safety (Tasks 20-23)

**P2-T20: Enable Swift 6 Strict Concurrency Checking**
- Set SWIFT_CONCURRENCY_COMPLETE_CHECKING = targeted
- Collect all warnings/errors
- Categorize by severity

**P2-T21: Fix Main Actor Isolation Warnings in View Controllers**
- Add @MainActor to view controllers
- Fix cross-actor references
- Use await MainActor.run for UI updates

**P2-T22: Fix Sendable Conformance Warnings**
- Add Sendable to thread-safe value types
- Use @unchecked Sendable where verified safe
- Document thread-safety assumptions

**P2-T23: Add Unit Tests for Async Operations**
- Files: `AsyncOperationTests.swift` (new)
- Test async delay, RemindersStore, Debouncer
- Test concurrent edits
- Test actor isolation

#### Documentation & Completion (Tasks 24-26)

**P2-T24: Document Protocol Architecture**
- Files: `Protocol-Architecture.md` (new)
- Document each protocol's purpose
- Provide usage examples
- Explain dependency injection

**P2-T25: Update Code Coverage Metrics**
- Target: 70%+ (up from 60%)
- Compare with Phase 1 baseline
- Highlight async code coverage

**P2-T26: Document Phase 2 Completion and Metrics**
- Files: `Phase-2-Completion-Report.md`
- Document Swift 6 migration completion
- Async/await adoption statistics
- Protocol architecture summary

### Phase 2 Success Criteria

- All 26 tasks completed
- Swift 6 language mode active with zero errors
- 100% async/await adoption (no legacy callbacks)
- At least 3 core protocols defined
- Method swizzling eliminated or documented
- 70%+ code coverage
- All tests passing

---

## Phase 3: UI Modernization

### Overview
Duration: 3-6 months | Tasks: 27 | Status: Planned

### Task List

#### SwiftUI Migration (Tasks 1-5)

**P3-T01: Audit UI Components for SwiftUI Migration Candidates**
- Categorize by priority: High (preferences), Medium (palettes), Low (editor)
- Assess complexity and AppKit dependencies
- Create migration roadmap

**P3-T02: Create SwiftUI Integration Infrastructure**
- Files: `SwiftUI/SwiftUIIntegration.swift` (new)
- Helper for embedding SwiftUI in AppKit
- Helper for embedding AppKit in SwiftUI
- Document integration patterns

**P3-T03: Migrate Preferences Window to SwiftUI**
- Create PreferencesView using SwiftUI Form
- Use @AppStorage for persistence
- Replace .xib file

**P3-T04: Migrate Choice Palette to SwiftUI**
- Create ChoicePaletteView with search
- Maintain keyboard navigation
- Preserve NSPanel behavior

**P3-T05: Migrate Date Picker to SwiftUI**
- Create DatePickerPaletteView
- Use SwiftUI DatePicker
- Integrate with @date tag insertion

#### TextKit 2 Migration (Tasks 6-15)

**P3-T06: Audit TextKit 2 Migration Requirements**
- Document current TextKit 1 customizations
- Research TextKit 2 equivalents
- Identify migration challenges (JS bridge, handles, guide lines)
- Assess risk and effort

**P3-T07: Update Minimum macOS Version to 12.0**
- Change MACOSX_DEPLOYMENT_TARGET to 12.0
- Update Info.plist LSMinimumSystemVersion
- Update README.md
- Document reason (TextKit 2)

**P3-T08: Create TextKit 2 Content Storage Subclass**
- Files: `OutlineTextContentStorage.swift` (new)
- Subclass NSTextContentStorage
- Implement JavaScript sync
- Preserve outline attributes

**P3-T09: Create TextKit 2 Layout Manager Delegate**
- Files: `OutlineTextLayoutManagerDelegate.swift` (new)
- Implement NSTextLayoutManagerDelegate
- Handle custom layout for outline items
- Manage disclosure triangles and guide lines

**P3-T10: Create Custom NSTextLayoutFragment for Outline Items**
- Files: `OutlineTextLayoutFragment.swift` (new)
- Subclass NSTextLayoutFragment
- Implement custom drawing (guide lines, handles)
- Calculate indentation

**P3-T11: Create TextKit 2-Based Text View**
- Files: `OutlineTextView.swift` (new)
- Create NSTextView subclass using TextKit 2
- Port editing behaviors from OutlineEditorView
- Handle disclosure triangle clicks

**P3-T12: Add TextKit Version Abstraction Layer**
- Files: `TextKitVersionAdapter.swift` (new)
- Support both TextKit 1 and 2
- Allow runtime switching for testing
- Add user preference for fallback

**P3-T13: Update OutlineEditorViewController to Use TextKit 2**
- Use TextKitVersionAdapter for text view creation
- Ensure compatibility with both versions
- Test with TextKit 1 (legacy) and TextKit 2 (new)

**P3-T14: Test TextKit 2 Implementation with Sample Documents**
- Files: `TextKit2IntegrationTests.swift` (new)
- Test large documents, item rendering, handles
- Test guide lines, editing, JavaScript sync

**P3-T15: Performance Benchmark TextKit 1 vs TextKit 2**
- Files: `TextKitPerformanceTests.swift`, `textkit-performance-comparison.md`
- Benchmark loading, typing, scrolling
- Compare memory usage
- Target: 10-30% faster with TextKit 2

#### Platform Features (Tasks 16-22)

**P3-T16: Add Touch Bar Support Infrastructure**
- Files: `TouchBar/TouchBarProvider.swift` (new)
- Create NSTouchBarDelegate
- Design Touch Bar layout
- Add icons for buttons

**P3-T17: Implement Touch Bar Quick Formatting Actions**
- Buttons for task, project, tag
- Connect to outline editor operations
- Update button states

**P3-T18: Implement Touch Bar Navigation Scrubber**
- NSScrubber for outline navigation
- Show project names
- Update on outline changes

**P3-T19: Integrate Touch Bar with OutlineEditorViewController**
- Override makeTouchBar()
- Update on editor state changes
- Respect system customization

**P3-T20: Add Continuity Features (Handoff Support)**
- Add NSUserActivityTypes to Info.plist
- Implement updateUserActivityState
- Enable document handoff between Macs

**P3-T21: Improve Accessibility with Modern APIs**
- Files: `OutlineEditorAccessibility.swift` (new)
- Expose outline structure to VoiceOver
- Custom accessibility elements
- Test with VoiceOver

**P3-T22: Add Localization Infrastructure for Additional Languages**
- Extract strings to .strings files
- Replace hardcoded strings with NSLocalizedString
- Create en/es/fr/de.lproj
- Export XLIFF for translation

#### Testing & Documentation (Tasks 23-27)

**P3-T23: Update UI Tests for SwiftUI Components**
- Files: `SwiftUIComponentTests.swift` (new)
- Test preferences, palettes, date picker
- Test keyboard navigation
- Test light/dark mode

**P3-T24: Performance Test UI Responsiveness**
- Files: `UIPerformanceTests.swift`, `ui-performance-metrics.md`
- Measure scrolling, typing latency
- Target: 60fps scrolling
- Compare TextKit 1 vs 2

**P3-T25: Update Documentation for UI Modernization**
- Files: `UI-Modernization-Guide.md` (new)
- Document SwiftUI strategy
- Document TextKit 2 migration
- Document Touch Bar implementation

**P3-T26: Update Code Coverage and Metrics**
- Target: 75%+ (up from 70%)
- Analyze SwiftUI and TextKit 2 coverage

**P3-T27: Document Phase 3 Completion and Metrics**
- Files: `Phase-3-Completion-Report.md`
- SwiftUI adoption summary
- TextKit 2 performance results
- Touch Bar implementation

### Phase 3 Success Criteria

- All 27 tasks completed
- At least 3 UI components migrated to SwiftUI
- TextKit 2 fully functional with performance improvement
- Touch Bar working on compatible hardware
- Zero accessibility regressions
- 75%+ code coverage
- macOS 12.0+ deployment target

---

## Phase 4: Deep Architecture Evolution

### Overview
Duration: 6-12 months | Tasks: 27 | Status: Planned

### Task List

#### JavaScript Bridge Analysis & Swift Model (Tasks 1-10)

**P4-T01: Comprehensive JavaScript Bridge Audit**
- Document complete JSContext architecture
- Analyze birch-outline.js functionality
- Measure performance overhead
- Assess migration feasibility
- Create `javascript-bridge-analysis.md`

**P4-T02: Design Pure Swift Outline Model Architecture**
- Files: `swift-outline-model-design.md`
- Design SwiftUI @Observable model
- Design query language interpreter
- Design undo/redo system
- Estimate 8-12 weeks effort

**P4-T03: Implement Swift Query Language Parser**
- Files: `QueryParser.swift`, `QueryAST.swift`
- Add swift-parsing dependency
- Define query AST nodes
- Implement parser
- Target: <1ms for typical queries

**P4-T04: Implement Swift Query Execution Engine**
- Files: `QueryExecutor.swift`
- Execute queries against OutlineModel
- Support all query types (type, tag, union, intersection, descendants)
- Add caching for repeated queries
- Target: <10ms for 1000-item documents

**P4-T05: Implement Swift Outline Model with Observation**
- Files: `SwiftOutlineModel.swift`, `OutlineItem.swift`
- Use @Observable from Swift 5.9+
- Implement undo/redo with UndoManager
- Support large documents (10,000+ items)

**P4-T06: Implement TaskPaper Format Parser in Swift**
- Files: `TaskPaperParser.swift`
- Parse indentation and item types
- Extract tags with regex
- Ensure 100% format compatibility
- Implement serializer (OutlineItem → text)

**P4-T07: Create Parallel Swift Outline Implementation**
- Files: `SwiftBirchOutline.swift`
- Implement feature parity with JavaScript
- Add runtime flag to choose implementation
- Keep both implementations during transition

**P4-T08: Add Feature Flag System for Implementation Switching**
- Files: `FeatureFlags.swift`
- Create @AppStorage-based feature flags
- Add debug UI to toggle Swift outline
- Add telemetry tracking

**P4-T09: Extensive Testing of Swift Outline Implementation**
- Files: `SwiftImplementationTests.swift`
- Compare JavaScript vs Swift behavior
- Test query execution parity
- Test undo/redo compatibility
- Verify serialization compatibility

**P4-T10: Performance Benchmark Swift vs JavaScript Implementation**
- Files: `swift-vs-javascript-performance.md`
- Benchmark loading, querying, manipulation
- Compare memory footprint
- Target: 2-5x faster than JavaScript
- Decision point: proceed if Swift is better

#### Combine Framework Adoption (Tasks 11-15)

**P4-T11: Audit Combine Adoption Opportunities**
- Find KVO, NotificationCenter, custom observers
- Categorize by complexity
- Create `combine-adoption-plan.md`

**P4-T12: Add Combine Publishers to SwiftOutlineModel**
- Add PassthroughSubject for changes
- Add @Published for derived state
- Ensure all mutations publish events

**P4-T13: Convert Search Bar to Use Combine**
- Replace manual handling with Combine
- Add debouncing (300ms)
- Handle errors in pipeline

**P4-T14: Convert Sidebar to Use Combine**
- React to outline changes
- Bind sidebar UI to model publishers
- Optimize with debouncing

**P4-T15: Replace Custom Observers with Combine**
- Find custom observer patterns
- Replace with Combine publishers
- Simplify notification code

#### iCloud Sync (Tasks 16-20)

**P4-T16: Design iCloud Sync Architecture**
- Files: `icloud-sync-design.md`
- Research options (NSDocument + iCloud Drive vs CloudKit)
- Design conflict resolution
- Document privacy/security
- Estimate 4-6 weeks

**P4-T17: Add iCloud Entitlements and Configuration**
- Update entitlements files
- Configure iCloud container
- Update provisioning profiles
- Note: Setapp may not support iCloud

**P4-T18: Implement iCloud Document Sync**
- Files: `iCloudDocumentSync.swift`
- Use NSFileCoordinator for iCloud
- Implement presentedItemDidChange
- Add sync status indicator

**P4-T19: Implement Conflict Resolution UI**
- Files: `ConflictResolutionView.swift` (SwiftUI)
- Present local vs cloud versions
- Implement "Keep Local" and "Keep Cloud"
- Document merge strategy (manual for now)

**P4-T20: Add Sync Status Indicator to UI**
- Files: `SyncStatusView.swift` (SwiftUI)
- Show iCloud sync status
- Display last sync time
- Show errors when sync fails

#### Final Tasks (Tasks 21-27)

**P4-T21: Explore Full SwiftUI Editor (Research Phase)**
- Files: `swiftui-editor-feasibility.md`
- Research TextEditor capabilities
- Create proof-of-concept
- Document limitations
- Decision: likely NOT FEASIBLE for full editor yet

**P4-T22: Comprehensive Testing of Phase 4 Features**
- Files: `Phase4IntegrationTests.swift`
- Test Swift outline full workflow
- Test Combine reactivity
- Test iCloud sync

**P4-T23: Performance Validation of Phase 4 Changes**
- Files: `phase4-performance-report.md`
- Benchmark Swift outline (target: 2-5x faster)
- Measure Combine overhead (target: <5%)
- Measure iCloud sync latency (target: <2s)

**P4-T24: Update Code Coverage Metrics**
- Target: 80%+ (up from 75%)
- Analyze Swift outline model coverage
- Check Combine integration coverage

**P4-T25: Document Architecture Evolution**
- Files: `Architecture-Evolution.md`
- Document original vs current architecture
- Explain JavaScript → Swift migration
- Document Combine adoption
- Document iCloud sync

**P4-T26: Plan JavaScript Bridge Deprecation Timeline**
- Files: `JavaScript-Deprecation-Plan.md`
- Release N: Swift outline opt-in beta
- Release N+1: Swift becomes default
- Release N+2: JavaScript deprecated
- Release N+3: JavaScript removed
- Timeline: 12-18 months

**P4-T27: Document Phase 4 Completion and Metrics**
- Files: `Phase-4-Completion-Report.md`, `Modernisation-Complete.md`
- Document Swift outline implementation
- Combine adoption metrics
- iCloud sync summary
- Overall modernization achievements

### Phase 4 Success Criteria

- All 27 tasks completed
- Swift outline feature parity achieved
- Performance improvement: 2-5x faster
- Combine successfully integrated
- iCloud sync functional
- 80%+ code coverage
- JavaScript deprecation timeline defined

---

## Critical Path Analysis

### 1. Swift 6 Migration (Critical)

**Why Critical**: Blocks Phase 2 progress, affects concurrency throughout codebase

**Complexity**: High
- 15-40 concurrency errors estimated
- 45 global variables requiring actor isolation decisions
- 48 static properties needing isolation
- 89 JavaScriptCore usages (non-Sendable types)
- Cascading error pattern ("whack-a-mole")

**Timeline**: 2-4 weeks dedicated work

**Risk Mitigation**:
- Follow comprehensive migration plan in Phase 2
- Use `@MainActor` for UI code systematically
- Document `nonisolated(unsafe)` usage thoroughly
- Test incrementally after each major change
- Monitor Apple's JavaScriptCore Sendable progress

### 2. Node.js Security Vulnerabilities (Critical)

**Why Critical**: 54 vulnerabilities (18 critical, 27 high) in birch-outline.js

**Key Vulnerabilities**:
- growl: Command injection (CVSS 9.8)
- minimist: Prototype pollution (CVSS 9.8)
- underscore: Arbitrary code execution (CVSS 9.8)
- lodash: Multiple vulnerabilities (CVSS 9.1)

**Timeline**: Address in P1-T07 through P1-T11

**Risk Mitigation**:
- Upgrade to Node.js v20 immediately
- Run `npm audit fix` for auto-fixes
- Manually address packages with no fix available
- Consider removing birch-doc (no fix available)

### 3. TextKit 2 Migration (High Impact)

**Why Important**: Reduces custom text system code, improves performance

**Complexity**: High
- Custom layout for outline items
- Disclosure triangle rendering
- Guide line drawing
- JavaScript bridge synchronization

**Timeline**: P3-T06 through P3-T15 (significant portion of Phase 3)

**Risk Mitigation**:
- Keep TextKit 1 as fallback via abstraction layer
- Add user preference to force TextKit 1
- Performance benchmark before full switch
- Extensive testing with large documents

### 4. JavaScript → Swift Migration (Transformative)

**Why Important**: Eliminates 5,000-10,000 lines of code, simplifies architecture

**Complexity**: Very High
- Query language parser (PEG.js → swift-parsing)
- Undo/redo system replication
- Serialization compatibility
- Feature parity verification

**Timeline**: P4-T03 through P4-T07 (8-12 weeks estimated)

**Risk Mitigation**:
- Parallel implementation (keep JavaScript working)
- Feature flags for gradual rollout
- Extensive comparison testing
- Performance benchmarking before switch
- 12-18 month deprecation timeline

---

## Risk Assessment

### High-Risk Items

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Swift 6 migration takes longer than 4 weeks | High | Medium | Allocate buffer time, incremental approach |
| TextKit 2 performance regression | High | Low | Keep TextKit 1 fallback, benchmark early |
| Swift outline missing features vs JavaScript | High | Medium | Extensive comparison tests, parallel implementation |
| JavaScriptCore never becomes Sendable | High | Medium | Document workarounds, use @unchecked Sendable |
| iCloud sync data corruption | Critical | Low | Extensive testing, conflict resolution UI |

### Medium-Risk Items

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Node.js v20 breaks JavaScript build | Medium | Low | Keep Node.js v11 environment for fallback |
| SPM migration breaks Paddle integration | Medium | Low | Document manual framework integration |
| SwiftUI components don't match AppKit look | Medium | Medium | Careful UI design, user testing |
| Code signing blocks test execution | Medium | High | Provide command-line alternatives |
| Touch Bar adoption low (limited hardware) | Low | High | Make optional, don't over-invest |

### Low-Risk Items

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Documentation becomes outdated | Low | High | Update docs with each phase completion |
| Test coverage doesn't reach targets | Medium | Low | Add tests incrementally, track progress |
| Localization strings incomplete | Low | Medium | Use XLIFF export, professional translation |

---

## Success Metrics

### Phase 1 Metrics
- ✅ SPM migration: Zero Carthage references remaining
- ✅ Node.js upgrade: v20 LTS functional
- ⚠️ Swift version: Remain on 5.0 (Swift 6 deferred)
- ✅ Test coverage: 60% baseline
- ✅ Test plans: Created for BirchOutline and BirchEditor
- ✅ Build success: All targets compile (Direct, AppStore, Setapp)

### Phase 2 Metrics
- Swift 6: Zero concurrency errors/warnings
- Async/await: 100% adoption (no legacy callbacks)
- Protocols: Minimum 3 core protocols defined
- Method swizzling: Zero or documented exceptions
- Test coverage: 70%+
- Performance: No regressions from Phase 1

### Phase 3 Metrics
- SwiftUI: Minimum 3 components migrated
- TextKit 2: Performance improvement 10-30%
- Touch Bar: Functional on compatible hardware
- Accessibility: Zero regressions (VoiceOver tested)
- Test coverage: 75%+
- macOS: 12.0+ deployment target

### Phase 4 Metrics
- Swift outline: 100% feature parity with JavaScript
- Performance: 2-5x faster than JavaScript bridge
- Combine: Successfully integrated (search, sidebar, model)
- iCloud sync: Functional with conflict resolution
- Test coverage: 80%+
- Code reduction: 5,000-10,000 lines removed

### Overall Success
- Timeline: Complete within 24 months
- Quality: All tests passing across all phases
- Stability: No user-facing regressions
- Performance: 2-5x overall improvement
- Maintainability: Modern Swift patterns throughout
- Security: Zero critical vulnerabilities

---

## Getting Started

### Prerequisites

**Development Environment**:
- macOS 12.0+ (for development)
- Xcode 15+ (for Swift 6 support in Phase 2)
- Node.js v20 LTS (via nvm)
- Git command-line tools

**Repository Setup**:
```bash
# Clone repository
git clone [repository-url]
cd TaskPaper

# Create Phase 1 branch
git checkout -b phase-1-foundation

# Install Node.js v20
nvm install 20
nvm use 20
```

### Recommended Approach

**Sequential Phase Execution**:
1. Complete all Phase 1 tasks before starting Phase 2
2. Complete all Phase 2 tasks before starting Phase 3
3. Complete all Phase 3 tasks before starting Phase 4

**Within Each Phase**:
1. Follow task order (dependencies built into sequence)
2. Run tests after each major change
3. Document any deviations from plan
4. Update phase completion report at end

**Best Practices**:
- Create separate branches for each phase
- Commit frequently with descriptive messages
- Run full test suite before phase completion
- Update documentation as you go
- Track metrics throughout (coverage, performance)

### Phase 1 Quick Start

**Week 1: Dependency Management**
```bash
# P1-T01: Audit Carthage dependencies
ls -la Cartfile* Carthage/

# P1-T02: Create Package.swift
# (Manual: Create Swift package manifest)

# P1-T03: Update Xcode project
# (Manual: Remove Carthage, add SPM in Xcode)

# P1-T04: Handle Paddle integration
# (Manual: Verify licensing works)

# P1-T05: Remove Carthage
rm -rf Cartfile* Carthage/

# P1-T06: Update README
# (Manual: Edit README.md)
```

**Week 2-3: JavaScript Build System**
```bash
# P1-T07: Audit Node.js dependencies
cd BirchOutline/birch-outline.js
npm audit
npm outdated

# P1-T08-09: Update package configurations
# (Edit package.json, create .nvmrc)

# P1-T10: Test build with Node.js v20
nvm use 20
npm install
npm run build

# P1-T11: Update README
# (Edit main README.md)
```

**Week 3-6: Testing Infrastructure**
```bash
# P1-T14: BirchOutline test plan
# (Manual: Create in Xcode or via JSON)

# P1-T15-16: Add unit tests
# (Write Swift test files)

# P1-T17: BirchEditor test plan
# (Create test plan, note code signing issues)

# P1-T18-21: More tests
# (Write additional test files)

# P1-T22: Configure coverage
# (Enable in Xcode scheme)

# P1-T23: Document completion
# (Write Phase-1-Completion-Report.md)
```

### Immediate Next Steps

**If Starting Phase 1**:
1. Read all Phase 1 tasks in `Modernisation-Phase-1.md`
2. Create phase-1-foundation branch
3. Start with P1-T01 (Carthage audit)
4. Follow task order sequentially

**If Phase 1 Complete**:
1. Review `Swift-Concurrency-Migration-Analysis.md`
2. Read all Phase 2 tasks in `Modernisation-Phase-2.md`
3. Allocate 2-4 weeks for Swift 6 migration
4. Create phase-2-async-safety branch
5. Start with P2-T00 (Swift 6 planning)

**If Continuing from Partial Phase 1**:
1. Review `P1-T17-final-report.md` for code signing issue
2. Review `swift6-upgrade-status.md` for Swift 6 deferral
3. Complete remaining Phase 1 tasks (if any)
4. Run full test suite
5. Write Phase-1-Completion-Report.md

### Support Resources

**Documentation Files**:
- `Modernisation-Phase-1.md` - Detailed Phase 1 tasks
- `Modernisation-Phase-2.md` - Detailed Phase 2 tasks
- `Modernisation-Phase-3.md` - Detailed Phase 3 tasks
- `Modernisation-Phase-4.md` - Detailed Phase 4 tasks
- `Swift-Concurrency-Migration-Analysis.md` - Swift 6 analysis
- `nodejs-upgrade-plan.md` - Node.js migration details
- `P1-T17-final-report.md` - Test plan blockers

**Key Commands**:
```bash
# Build all targets
xcodebuild -project TaskPaper.xcodeproj -scheme "TaskPaper Direct" build

# Run tests
xcodebuild test -project TaskPaper.xcodeproj -scheme "TaskPaper"

# Code coverage
xcodebuild test -enableCodeCoverage YES ...

# Node.js build
cd BirchOutline/birch-outline.js && npm run build
cd BirchEditor/birch-editor.js && npm run build
```

---

## Conclusion

This roadmap provides a comprehensive guide to modernising TaskPaper over 12-24 months across 103 tasks. The sequential phase approach ensures each foundation is solid before building the next layer. Key milestones include Swift 6 adoption (Phase 2), TextKit 2 migration (Phase 3), and JavaScript elimination (Phase 4).

**Total Transformation**:
- From Carthage → Swift Package Manager
- From Node.js v11 → v20 LTS
- From Swift 5.0 → 6.0 with full concurrency
- From AppKit only → SwiftUI hybrid
- From TextKit 1 → TextKit 2
- From JavaScript bridge → Pure Swift
- From 60% → 80% test coverage
- From 0 → iCloud sync support

**Expected Benefits**:
- 2-5x performance improvement
- ~10,000 lines of code removed
- Modern Swift concurrency safety
- Enhanced platform integration
- Simplified architecture
- Improved maintainability

**Success Factors**:
1. Follow sequential phase approach
2. Test thoroughly at each step
3. Document deviations from plan
4. Track metrics throughout
5. Address blockers promptly (code signing, Swift 6)
6. Communicate progress regularly

Good luck with your modernisation journey! 🚀
