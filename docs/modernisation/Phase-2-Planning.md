# Phase 2: Async & Safety - Comprehensive Planning Document

**TaskPaper Modernization Initiative**
**Phase:** 2 of 4
**Duration:** 3-4 months (extended)
**Total Tasks:** 26 (P2-T00 through P2-T25)
**Document Version:** 1.0
**Date:** 2025-11-12
**Status:** Planning Complete - Ready for Execution

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Phase 2 Objectives](#phase-2-objectives)
3. [Foundation: Swift 6 Migration Analysis](#foundation-swift-6-migration-analysis)
4. [Task Breakdown and Dependencies](#task-breakdown-and-dependencies)
5. [Risk Assessment and Mitigation](#risk-assessment-and-mitigation)
6. [Execution Timeline](#execution-timeline)
7. [Success Criteria](#success-criteria)
8. [Phase 2 to Phase 3 Transition](#phase-2-to-phase-3-transition)
9. [Appendices](#appendices)

---

## Executive Summary

### Phase 2 Purpose

Phase 2 represents a **critical architectural modernization** of the TaskPaper codebase, focusing on three interconnected goals:

1. **Swift 6 Migration**: Upgrade from Swift 5.0 to Swift 6.0 with full concurrency checking
2. **Async/Await Adoption**: Replace legacy callback patterns with modern structured concurrency
3. **Protocol-Oriented Architecture**: Enable dependency injection and improve testability

### Context from Phase 1

Phase 1 completed with **87% success rate** (20 of 23 tasks):
- ✅ SPM migration complete
- ✅ Node.js v20 upgrade complete
- ✅ 160+ new tests added
- ✅ Test infrastructure established
- ⚠️ Swift 6 migration deferred after revealing architectural challenges

**Key Discovery:** Initial Swift 6 upgrade attempt (P1-T12) exposed deep concurrency issues:
- 19 concurrency errors discovered
- 9 errors fixed with `nonisolated(unsafe)` annotations
- Cascading error pattern observed (each fix reveals 3-6 new errors)
- **Root cause:** 15-year-old architecture predates Swift Concurrency (introduced 2021)
- **Major blocker:** 89 JavaScriptCore usages (JSContext/JSValue are non-Sendable)

**Decision:** Reverted to Swift 5.0, created comprehensive analysis document (`Swift-Concurrency-Migration-Analysis.md`), and planned Phase 2 as dedicated migration effort.

### Phase 2 Approach

Based on lessons learned from Phase 1, Phase 2 follows a **systematic, risk-aware approach**:

1. **Week 1-2**: Planning and architecture design (P2-T00)
2. **Week 3-6**: Swift 6 migration with proper actor isolation (P2-T01)
3. **Week 7-10**: Async/await adoption and legacy removal (P2-T02 through P2-T10)
4. **Week 11-13**: Protocol-oriented refactoring (P2-T11 through P2-T19)
5. **Week 14-16**: Concurrency safety and testing (P2-T20 through P2-T25)

### Estimated Effort

| **Category** | **Tasks** | **Estimated Effort** | **Risk Level** |
|--------------|-----------|----------------------|----------------|
| Swift 6 Planning | P2-T00 | 1 week | 🟡 Medium |
| Swift 6 Migration | P2-T01 | 2-3 weeks | 🔴 High |
| Async/Await | P2-T02 - P2-T05 | 1 week | 🟡 Medium |
| Method Swizzling | P2-T06 - P2-T10 | 1 week | 🟡 Medium |
| Protocol Design | P2-T11 - P2-T19 | 2 weeks | 🟢 Low |
| Concurrency Safety | P2-T20 - P2-T23 | 1 week | 🟡 Medium |
| Documentation | P2-T24 - P2-T25 | 3 days | 🟢 Low |
| **Total** | **26 tasks** | **3-4 months** | **🔴 High Overall** |

### Critical Success Factors

1. **Dedicated Time**: Phase 2 requires sustained focus (2-4 weeks for Swift 6 alone)
2. **Risk Management**: Comprehensive testing at each stage prevents regression
3. **Incremental Commits**: Small, tested commits reduce "whack-a-mole" risk
4. **Xcode Access**: Full Xcode IDE required for actor isolation and concurrency work
5. **JavaScriptCore Strategy**: Must resolve 89 non-Sendable usages with architectural approach

---

## Phase 2 Objectives

### Primary Objectives

#### 1. Swift 6 Language Mode Activation ⭐ **CRITICAL**

**Goal**: Upgrade SWIFT_VERSION from 5.0 to 6.0 with zero compilation errors

**Why This Matters**:
- Swift 6 introduces compile-time data race safety (eliminates entire class of concurrency bugs)
- Future-proofs codebase for Swift ecosystem evolution
- Enables modern concurrency features (actors, structured concurrency, Sendable checking)
- Aligns with Apple's long-term platform direction

**Challenges**:
- 15-year-old architecture (2005-2018) predates Swift Concurrency (2021)
- 45 global variables without synchronization
- 48 static properties without actor isolation
- 89 JavaScriptCore usages (JSContext/JSValue are non-Sendable by Apple's design)
- 256 Objective-C files (58% of codebase) cannot fully participate in Swift Concurrency

**Success Metric**: Build succeeds in Swift 6 mode with SWIFT_CONCURRENCY_COMPLETE_CHECKING enabled

---

#### 2. Async/Await Migration

**Goal**: Replace all legacy callback patterns with async/await

**Current State**:
- 16 DispatchQueue usages across 12 files
- 9 async/await usages (4.9% adoption)
- Legacy `delay()` function using GCD
- RemindersStore using completion handlers
- Debouncer using GCD timers

**Target State**:
- 100% async/await adoption for asynchronous operations
- Zero DispatchQueue usage (except internal implementations)
- Actor-based Debouncer
- Async delay using Task.sleep()
- RemindersStore using async throws

**Success Metric**: Zero occurrences of `@escaping` completion handlers in new/updated code

---

#### 3. Method Swizzling Removal

**Goal**: Eliminate or document method swizzling for maintainability

**Current Swizzling**:
- `JGMethodSwizzler.m` (utility infrastructure)
- `NSWindowTabbedBase.m` (window tabbing workaround)
- `NSTextStorage+FixTextStorageBug.m` (performance optimization)
- `NSTextView-AccessibilityPerformanceHacks.m` (macOS accessibility workaround)

**Strategy**:
- **NSWindowTabbedBase**: Remove (modern NSWindow APIs available)
- **NSTextStorage**: Measure performance impact, keep if >20% improvement
- **NSTextView Accessibility**: Test macOS 11+, remove if fixed
- **JGMethodSwizzler**: Keep only if other swizzling remains

**Success Metric**: Method swizzling eliminated or documented with performance justification

---

#### 4. Protocol-Oriented Architecture

**Goal**: Enable dependency injection and improve testability

**Key Protocols**:
- `OutlineEditorProtocol` - abstraction for outline editing operations
- `StyleSheetProtocol` - abstraction for LESS compilation and styling
- `OutlineDocumentProtocol` - abstraction for document operations

**Benefits**:
- Dependency injection in tests (mock implementations)
- Reduced JavaScript context dependencies in unit tests
- Faster test execution (no JSContext initialization overhead)
- Better separation of concerns
- Easier to add alternative implementations

**Success Metric**: At least 3 core protocols defined with mock implementations for testing

---

#### 5. Concurrency Safety Verification

**Goal**: Comprehensive concurrency checking and testing

**Approach**:
1. Enable SWIFT_CONCURRENCY_COMPLETE_CHECKING = targeted
2. Fix all MainActor isolation warnings
3. Add Sendable conformance where appropriate
4. Create async operation tests
5. Verify thread sanitizer passes

**Success Metric**: Zero concurrency warnings/errors with complete checking enabled

---

## Foundation: Swift 6 Migration Analysis

### Historical Context: Phase 1 Swift 6 Attempt

During Phase 1 (November 2025), an initial Swift 6 upgrade was attempted as P1-T12. This attempt provided valuable learnings:

#### What Happened

1. **Initial Upgrade**: Changed SWIFT_VERSION from 5.0 to 6.0
2. **First Error Wave**: 3 compilation errors in `Commands.swift`
3. **Round 1 Fixes**: Applied `nonisolated(unsafe)` to 3 static properties
4. **Cascading Pattern**: Fixed 3 errors → revealed 6 new errors
5. **Round 2 Fixes**: Fixed 6 errors → revealed 3 new errors
6. **Round 3 Fixes**: Fixed 3 errors → revealed 3 new errors
7. **Current State**: 3 errors remain in `ItemPasteboardUtilities.swift` (architectural, cannot be fixed with simple annotations)

**Total**: 9 errors fixed, 3 errors visible, estimated 15-40 total errors based on cascading pattern.

#### Root Causes Identified

| **Issue Category** | **Count** | **Swift 6 Impact** |
|--------------------|-----------|-------------------|
| Global variables | 45 across 11 files | Thread-safety violations |
| Static properties | 48 across 14 files | Actor isolation required |
| Manual threading | 16 DispatchQueue usages | Needs async/await conversion |
| JavaScriptCore usage | 89 JSContext/JSValue calls | **Non-Sendable blocker** |
| Objective-C files | 256 files (58% codebase) | Cannot use actors |
| Synchronous utility APIs | Multiple instances | Need async conversion |

#### Key Architectural Challenges

**1. JavaScriptCore Non-Sendable Constraint** 🔴 **CRITICAL**

```swift
// This pattern appears 89 times across 20 files
let jsContext: JSContext = BirchOutline.sharedContext
let jsValue: JSValue = jsContext.evaluateScript("...")

// Problem: JSContext and JSValue are non-Sendable by Apple's framework design
// Cannot pass across actor boundaries without unsafe annotations
```

**Impact**: This is a **fundamental architectural constraint** with no perfect solution:
- **Option A**: Isolate all JavaScript code to single @MainActor context (current approach)
- **Option B**: Use `@preconcurrency import JavaScriptCore` (suppresses warnings)
- **Option C**: Use `nonisolated(unsafe)` judiciously with careful audit
- **Option D**: Wait for Apple to add Sendable conformance (unknown timeline)

**Phase 2 Strategy**: Combination of Option A (primary) + Option B (pragmatic) + documentation

---

**2. Synchronous APIs Calling MainActor Code** 🟡 **SIGNIFICANT**

```swift
// Current pattern in ItemPasteboardUtilities.swift (3 errors)
class func readFromPasteboard(...) -> [ItemType]? {
    // Synchronous method calls MainActor-isolated APIs internally
    return editor.deserializeItems(...)  // ERROR: MainActor isolation boundary
}
```

**Problem**: Converting to `async` breaks all call sites (cascading changes)

**Phase 2 Strategy**:
1. Audit all call sites to understand impact
2. Convert utility methods to async where appropriate
3. Use `MainActor.assumeIsolated { }` for verified synchronous contexts
4. Add comprehensive documentation of assumptions

---

**3. Global Mutable State** 🟡 **SIGNIFICANT**

```swift
// Pattern found in 11 files
var TabbedWindowsKey = "tabbedWindows"  // No synchronization
var tabbedWindowsContext = malloc(1)!   // Unsafe global pointer

// Pattern found in 14 files
class Commands {
    static var scriptCommandsDisposables: [DisposableType]?  // Shared mutable state
}
```

**Problem**: Global mutable state accessible from any thread violates Swift 6 concurrency rules

**Phase 2 Strategy**:
1. Convert to @MainActor isolation where UI-related
2. Convert to actor-isolated state for background operations
3. Use immutable alternatives (static let instead of var)
4. Document thread-safety assumptions with `nonisolated(unsafe)` where necessary

---

### Swift 6 Migration Strategy (P2-T01)

Based on the Phase 1 analysis and the comprehensive Swift 6 migration document, Phase 2 adopts a **systematic, phase-gated approach**:

#### Stage 1: Comprehensive Audit (Week 1)

**Goal**: Understand full scope before making changes

**Activities**:
1. **Global State Inventory**
   - Catalog all 45 global variables
   - Catalog all 48 static properties
   - Categorize by thread-safety requirements (MainActor, actor-isolated, immutable)

2. **API Surface Analysis**
   - Identify all synchronous methods that need async conversion
   - Map call chains to understand cascading impact
   - Prioritize by risk and architectural impact

3. **JavaScriptCore Isolation Strategy**
   - Audit all 89 JSContext/JSValue usages
   - Design MainActor isolation boundaries
   - Plan `@preconcurrency import` usage

4. **Objective-C Boundary Analysis**
   - Identify Swift/ObjC interop points (17 files with @objc)
   - Plan async/sync bridging strategy
   - Document limitations

**Deliverable**: `Swift-6-Migration-Strategy.md` (detailed audit and execution plan)

---

#### Stage 2: Enable Swift 6 Mode (Week 2)

**Goal**: Activate Swift 6 and collect all errors/warnings

**Activities**:
1. Edit `TaskPaper.xcodeproj/project.pbxproj`:
   ```diff
   - SWIFT_VERSION = 5.0;
   + SWIFT_VERSION = 6.0;
   ```

2. Enable complete concurrency checking:
   ```diff
   + SWIFT_CONCURRENCY_COMPLETE_CHECKING = targeted;
   ```

3. Build and collect all errors/warnings:
   ```bash
   xcodebuild clean build \
     -project TaskPaper.xcodeproj \
     -scheme TaskPaper \
     -configuration Debug \
     2>&1 | tee swift6-migration-errors.log
   ```

4. Categorize errors:
   - **Tier 1 (Critical)**: Build-blocking errors
   - **Tier 2 (High)**: Concurrency safety violations
   - **Tier 3 (Medium)**: Sendable conformance warnings
   - **Tier 4 (Low)**: Deprecation warnings

**Deliverable**: `swift6-migration-errors.log` with categorized error list

---

#### Stage 3: Systematic Error Resolution (Week 3-5)

**Goal**: Fix errors in priority order with minimal technical debt

**Approach**: **Tier-by-tier, test-driven fixes**

**Tier 1: Critical Build Errors** (estimated 3-10 errors)

Pattern: MainActor isolation boundary violations

```swift
// BEFORE (error)
class func readFromPasteboard(...) -> [ItemType]? {
    return editor.deserializeItems(...)  // ERROR
}

// OPTION A: Convert to async (preferred)
class func readFromPasteboard(...) async -> [ItemType]? {
    return await editor.deserializeItems(...)
}

// OPTION B: Use assumeIsolated (only if verified safe)
class func readFromPasteboard(...) -> [ItemType]? {
    return MainActor.assumeIsolated {
        editor.deserializeItems(...)
    }
}
```

**Decision Framework**:
- ✅ **Use Option A (async)** if: Call sites can be updated to async contexts
- ⚠️ **Use Option B (assumeIsolated)** if: Verified called only on MainActor AND call site cannot be async
- ❌ **Never use** `nonisolated(unsafe)` for MainActor isolation issues

---

**Tier 2: Global State Isolation** (estimated 45 global variables + 48 static properties)

Pattern: Unprotected mutable state

```swift
// BEFORE (warning)
var TabbedWindowsKey = "tabbedWindows"

// AFTER: MainActor isolation (UI-related)
@MainActor var TabbedWindowsKey = "tabbedWindows"

// OR: Make immutable
let TabbedWindowsKey = "tabbedWindows"  // Preferred if not mutated
```

**Decision Framework**:
- ✅ **Make immutable** (let instead of var) if: Never mutated
- ✅ **Add @MainActor** if: Only accessed from UI code
- ✅ **Create actor** if: Shared across threads with complex logic
- ⚠️ **Use nonisolated(unsafe)** if: Verified thread-safe through other means (document why)

---

**Tier 3: JavaScriptCore Non-Sendable** (estimated 89 usages)

Pattern: JSContext/JSValue crossing actor boundaries

```swift
// BEFORE (warning)
import JavaScriptCore

let jsContext: JSContext = ...
actor.sendJSValue(jsContext.evaluateScript(...))  // WARNING: JSValue not Sendable

// AFTER: Isolation strategy
@preconcurrency import JavaScriptCore  // Suppress warnings

@MainActor
class OutlineEditor {
    // Keep all JavaScript interactions on MainActor
    private let jsContext: JSContext

    func evaluateScript(_ script: String) -> JSValue {
        jsContext.evaluateScript(script)
    }
}
```

**Decision Framework**:
- ✅ **Use @preconcurrency import** to suppress unavoidable warnings
- ✅ **Isolate to @MainActor** - keep all JSContext usage on MainActor
- ✅ **Document assumptions** - why MainActor isolation is safe
- ❌ **Never pass JSContext/JSValue** across actor boundaries

---

**Tier 4: Sendable Conformance** (estimated 10-20 types)

Pattern: Value types used across actor boundaries

```swift
// BEFORE (warning)
struct OutlineConfiguration {
    var fontSize: CGFloat
    var theme: String
}
// WARNING: OutlineConfiguration used across actors but not Sendable

// AFTER: Add Sendable conformance
struct OutlineConfiguration: Sendable {
    let fontSize: CGFloat  // Changed to let (immutable)
    let theme: String
}
```

**Decision Framework**:
- ✅ **Add Sendable** if: Type is truly immutable (all stored properties are let)
- ✅ **Add @unchecked Sendable** if: Type is thread-safe but compiler can't verify (document why)
- ⚠️ **Refactor to immutable** if: Mutability not required
- ❌ **Don't add Sendable** if: Type genuinely needs mutable state

---

#### Stage 4: Testing and Validation (Week 5-6)

**Goal**: Ensure no regressions and verify concurrency safety

**Testing Strategy**:

1. **Unit Tests** (existing 160+ tests)
   - All existing tests must pass
   - Add async test variants where needed
   - Use `@MainActor` test methods where appropriate

2. **Concurrency-Specific Tests** (P2-T23)
   - Test actor isolation boundaries
   - Test concurrent access patterns
   - Test deadlock scenarios
   - Test MainActor.run wrapping

3. **Thread Sanitizer** (enabled in test plans)
   - Run all tests with TSan enabled
   - Fix any data race detections
   - Document known false positives

4. **Manual Testing**
   - Launch application
   - Create/edit/save documents
   - Test JavaScript extensions
   - Test all major features
   - Monitor for crashes/hangs

5. **Performance Validation**
   - Benchmark key operations
   - Measure actor hopping overhead
   - Compare with Swift 5 baseline
   - Target: <10% performance regression

**Acceptance Criteria**:
- ✅ Build succeeds with zero errors
- ✅ Zero concurrency warnings (or documented suppression with @preconcurrency)
- ✅ All 160+ unit tests pass
- ✅ Thread sanitizer passes
- ✅ Manual smoke tests pass
- ✅ Performance within 10% of baseline

---

#### Stage 5: Documentation and Commit (Week 6)

**Goal**: Document decisions and create clean commit history

**Documentation**:
1. Update `Swift-6-Migration-Strategy.md` with final decisions
2. Document all uses of `nonisolated(unsafe)` with justification
3. Document all uses of `@unchecked Sendable` with thread-safety proof
4. Document JavaScriptCore isolation strategy
5. Add inline comments for non-obvious actor isolation decisions

**Commit Strategy**:
```bash
# Commit 1: Enable Swift 6 mode (breaks build)
git add TaskPaper.xcodeproj/project.pbxproj
git commit -m "Enable Swift 6 language mode and complete concurrency checking"

# Commit 2: Fix Tier 1 critical errors
git add <files>
git commit -m "Fix MainActor isolation boundary violations (Tier 1)"

# Commit 3: Fix Tier 2 global state
git add <files>
git commit -m "Add actor isolation to global variables and static properties (Tier 2)"

# Commit 4: Fix Tier 3 JavaScriptCore
git add <files>
git commit -m "Isolate JavaScriptCore usage to MainActor with @preconcurrency (Tier 3)"

# Commit 5: Fix Tier 4 Sendable conformance
git add <files>
git commit -m "Add Sendable conformance to thread-safe value types (Tier 4)"

# Commit 6: Tests and documentation
git add docs/ Tests/
git commit -m "Add concurrency tests and update Swift 6 migration documentation"
```

**Push Strategy**:
- Push after each stage passes smoke tests
- Use feature branch: `claude/phase-2-swift6-migration`
- Create PR for review before merging to main

---

### Risk Mitigation: Lessons from Phase 1

**Risk 1: Cascading Errors ("Whack-a-Mole")** 🔴 **HIGH**

**Phase 1 Experience**: Each fix revealed 1.33 new errors on average (9 fixes → 3 visible → estimated 15-40 total)

**Phase 2 Mitigation**:
- ✅ Complete audit BEFORE making changes (Stage 1)
- ✅ Categorize all errors upfront (Stage 2)
- ✅ Fix in priority order with testing between tiers (Stage 3)
- ✅ Incremental commits allow rollback if needed

---

**Risk 2: Breaking API Changes Cascade** 🟡 **MEDIUM**

**Phase 1 Experience**: Converting synchronous methods to async breaks all call sites

**Phase 2 Mitigation**:
- ✅ Map call chains during audit (Stage 1)
- ✅ Convert from leaves to roots (bottom-up approach)
- ✅ Use `MainActor.assumeIsolated` for verified synchronous contexts
- ✅ Keep temporary bridging methods during transition

---

**Risk 3: JavaScriptCore Non-Sendable Blocker** 🔴 **HIGH**

**Phase 1 Experience**: 89 usages of non-Sendable JSContext/JSValue with no compiler-friendly solution

**Phase 2 Mitigation**:
- ✅ Accept architectural constraint (Apple framework limitation)
- ✅ Use `@preconcurrency import JavaScriptCore` (pragmatic)
- ✅ Isolate all JavaScript to @MainActor (architectural decision)
- ✅ Document strategy clearly for future maintainers
- ✅ Monitor Apple's roadmap for JSContext Sendable conformance

---

**Risk 4: Performance Regression** 🟡 **MEDIUM**

**Concern**: Actor hopping overhead may slow down critical paths

**Phase 2 Mitigation**:
- ✅ Benchmark before/after Swift 6 migration (Stage 4)
- ✅ Measure actor hopping frequency in hot paths
- ✅ Optimize actor isolation boundaries if needed
- ✅ Accept <10% regression as acceptable for safety benefits
- ❌ Reject migration if >20% regression (requires architectural rethink)

---

**Risk 5: Testing Gaps** 🟡 **MEDIUM**

**Concern**: Concurrency bugs are non-deterministic and hard to test

**Phase 2 Mitigation**:
- ✅ Thread sanitizer enabled in all test runs
- ✅ Create concurrency-specific tests (P2-T23)
- ✅ Manual testing protocol for UI interactions
- ✅ Gradual rollout to beta testers
- ✅ Monitoring for crashes/hangs post-release

---

## Task Breakdown and Dependencies

### Task Dependency Graph

```
Phase 2 Task Dependencies:

P2-T00 (Planning) ──────┬──────────────────────────────────────┐
                        │                                      │
                        ↓                                      │
                   P2-T01 (Swift 6 Migration) ────────────────┤
                        │                                      │
                        ├────────────────────────┬─────────────┤
                        ↓                        ↓             ↓
              ┌─────────────────────┐   ┌───────────────┐  ┌──────────────┐
              │ Async/Await         │   │ Protocol      │  │ Concurrency  │
              │ P2-T02 - P2-T05     │   │ P2-T11 - P2-T19│  │ P2-T20 - P2-T23│
              └─────────────────────┘   └───────────────┘  └──────────────┘
                        │                        │             │
                        └────────────┬───────────┴─────────────┘
                                     ↓
                        Method Swizzling (P2-T06 - P2-T10)
                                     │
                                     ↓
                        Documentation (P2-T24 - P2-T25)
```

**Critical Path**: P2-T00 → P2-T01 → Everything Else

**Rationale**: Swift 6 migration (P2-T01) must complete before other tasks because:
- Async/await syntax may trigger new concurrency warnings in Swift 6
- Protocol conformance may require Sendable conformance decisions
- Method swizzling removal changes APIs that concurrency migration touches
- Everything needs to be done in Swift 6 mode to avoid rework

---

### Task Detailed Breakdown

#### **P2-T00: Swift 6 Migration Planning** ⭐ **CURRENT TASK**

**Duration**: 1 week
**Status**: ✅ **COMPLETE** (this document)
**Risk**: 🟡 Medium

**Deliverables**:
- ✅ This planning document (`Phase-2-Planning.md`)
- ✅ Incorporation of Swift 6 analysis findings
- ✅ Task breakdown and dependencies
- ✅ Risk assessment and mitigation strategies
- ✅ Execution timeline and milestones

**Next Steps**: Review and approve planning, then begin P2-T01

---

#### **P2-T01: Swift 6 Language Mode Upgrade** 🔴 **HIGH RISK**

**Duration**: 2-3 weeks
**Dependencies**: P2-T00
**Risk**: 🔴 High

**Stage 1: Audit** (Week 1)
- Deliverable: `Swift-6-Migration-Strategy.md`
- Activities: Global state inventory, API analysis, JavaScriptCore strategy, ObjC boundary analysis

**Stage 2: Enable Swift 6** (Week 2, Day 1)
- Edit project.pbxproj (SWIFT_VERSION = 6.0)
- Enable SWIFT_CONCURRENCY_COMPLETE_CHECKING
- Collect all errors/warnings
- Deliverable: `swift6-migration-errors.log`

**Stage 3: Fix Errors** (Week 2-3)
- Tier 1: Critical build errors (3-10 errors)
- Tier 2: Global state isolation (45 + 48 = 93 items)
- Tier 3: JavaScriptCore non-Sendable (89 usages)
- Tier 4: Sendable conformance (10-20 types)
- Incremental commits after each tier

**Stage 4: Testing** (Week 3, Days 4-5)
- All unit tests pass
- Thread sanitizer passes
- Manual smoke testing
- Performance validation (<10% regression)

**Stage 5: Documentation** (Week 3, Day 5)
- Update migration documentation
- Document actor isolation decisions
- Document @preconcurrency usage
- Clean commit history

**Success Criteria**:
- ✅ Build succeeds with Swift 6.0 and complete concurrency checking
- ✅ Zero concurrency errors
- ✅ Zero concurrency warnings (or documented with @preconcurrency)
- ✅ All tests pass
- ✅ Performance within 10% of baseline

---

#### **P2-T02: Replace delay() with Task.sleep()** 🟡 **MEDIUM RISK**

**Duration**: 2 days
**Dependencies**: P2-T01 (Swift 6 migration complete)
**Risk**: 🟡 Medium
**Files**: `BirchEditor/BirchEditor.swift/BirchEditor/delay.swift`

**Current Implementation**:
```swift
func delay(_ delay: Double, closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: closure)
}
```

**Target Implementation**:
```swift
@MainActor
func delay(_ duration: Duration) async {
    try? await Task.sleep(for: duration)
}

// Legacy bridge (deprecated)
@available(*, deprecated, message: "Use async delay(_:) instead")
func delay(_ delay: Double, closure: @escaping @MainActor () -> Void) {
    Task { @MainActor in
        try? await Task.sleep(for: .seconds(delay))
        closure()
    }
}
```

**Migration Steps**:
1. Add async delay function
2. Add deprecated legacy bridge
3. Find all call sites: `grep -r "delay(" --include="*.swift"`
4. Convert call sites to async/await
5. Add `async` to caller function signatures
6. Remove deprecated function after all migrations

**Testing**:
- Verify delay timing accuracy
- Test cancellation behavior
- Ensure no delay-related flakiness in tests

**Success Criteria**:
- ✅ All delay() calls use async version
- ✅ No DispatchQueue.main.asyncAfter in delay.swift
- ✅ Tests pass without timing issues

---

#### **P2-T03: Convert RemindersStore to Async/Await**

**Duration**: 2 days
**Dependencies**: P2-T01
**Risk**: 🟡 Medium
**Files**: `RemindersStore.swift` (exact path TBD)

**Current Pattern**:
```swift
func fetchReminders(completion: @escaping (Result<[Reminder], Error>) -> Void) {
    eventStore.requestAccess { granted, error in
        // ...
        completion(.success(reminders))
    }
}
```

**Target Pattern**:
```swift
func fetchReminders() async throws -> [Reminder] {
    let granted = try await eventStore.requestAccessToEntityType(.reminder)
    guard granted else { throw ReminderError.accessDenied }
    // ...
    return reminders
}
```

**Migration Steps**:
1. Identify all completion handler methods
2. Convert to async throws
3. Update call sites to use await
4. Add @MainActor where needed for UI updates
5. Add error handling tests

**Testing**:
- Test async/await conversion
- Test error propagation
- Test EventKit integration
- Mock EventKit for unit tests

---

#### **P2-T04: Convert Debouncer to Actor**

**Duration**: 1 day
**Dependencies**: P2-T01
**Risk**: 🟢 Low
**Files**: `Debouncer.swift` (exact path TBD)

**Current Pattern** (assumed):
```swift
class Debouncer {
    private var timer: DispatchSourceTimer?
    func debounce(_ action: @escaping () -> Void) {
        timer?.cancel()
        timer = DispatchSource.makeTimerSource()
        // ...
    }
}
```

**Target Pattern**:
```swift
actor Debouncer {
    private var task: Task<Void, Never>?

    func debounce(for duration: Duration, action: @escaping @Sendable () async -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(for: duration)
            await action()
        }
    }
}
```

**Migration Steps**:
1. Convert class to actor
2. Replace DispatchSourceTimer with Task
3. Update call sites to use await
4. Test concurrent debounce calls
5. Test cancellation behavior

---

#### **P2-T05: Update Delay Call Sites**

**Duration**: 2 days
**Dependencies**: P2-T02
**Risk**: 🟢 Low

**Scope**:
- Find all `delay(` calls: estimated 10-20 call sites
- Convert to async/await syntax
- Add async to caller signatures
- Wrap in Task if caller cannot be async

**Pattern**:
```swift
// BEFORE
delay(0.5) {
    self.updateUI()
}

// AFTER (if in async context)
await delay(.milliseconds(500))
updateUI()

// AFTER (if in sync context that can't be converted)
Task { @MainActor in
    await delay(.milliseconds(500))
    updateUI()
}
```

---

#### **P2-T06 - P2-T10: Method Swizzling Removal**

**Duration**: 1 week
**Dependencies**: P2-T01
**Risk**: 🟡 Medium

See [Method Swizzling section](#method-swizzling-removal-tasks) in appendix for details.

---

#### **P2-T11 - P2-T19: Protocol-Oriented Design**

**Duration**: 2 weeks
**Dependencies**: P2-T01
**Risk**: 🟢 Low

See [Protocol Design section](#protocol-oriented-design-tasks) in appendix for details.

**Key Protocols**:
- `OutlineEditorProtocol` (P2-T11, P2-T12)
- `StyleSheetProtocol` (P2-T13, P2-T14)
- `OutlineDocumentProtocol` (P2-T15, P2-T16)
- Mock implementations (P2-T17)
- Test refactoring (P2-T18)
- Dependency injection (P2-T19)

---

#### **P2-T20 - P2-T23: Concurrency Safety**

**Duration**: 1 week
**Dependencies**: P2-T01, P2-T02-P2-T05
**Risk**: 🟡 Medium

**P2-T20: Enable Strict Concurrency Checking**
- Already done in P2-T01 Stage 2
- This task is verification only

**P2-T21: Fix MainActor Warnings**
- Should be completed in P2-T01 Stage 3
- This task is cleanup for any remaining warnings

**P2-T22: Fix Sendable Conformance**
- Should be completed in P2-T01 Stage 3 Tier 4
- This task is cleanup for any remaining types

**P2-T23: Add Async Operation Tests**
- New file: `BirchEditor/BirchEditor.swift/BirchEditorTests/AsyncOperationTests.swift`
- Test async delay timing
- Test RemindersStore async methods
- Test Debouncer actor isolation
- Test concurrent edits
- Test actor isolation boundaries
- Test deadlock scenarios

---

#### **P2-T24 - P2-T25: Documentation**

**Duration**: 3 days
**Dependencies**: All previous tasks
**Risk**: 🟢 Low

**P2-T24: Protocol Architecture Documentation**
- File: `docs/modernisation/Protocol-Architecture.md`
- Document each protocol's purpose
- Provide usage examples
- Explain dependency injection pattern
- Show mock implementation examples

**P2-T25: Phase 2 Completion Report**
- File: `docs/modernisation/Phase-2-Completion-Report.md`
- Document all 26 tasks with status
- Swift 6 migration summary and metrics
- Async/await adoption statistics
- Protocol architecture summary
- Method swizzling decisions
- Code coverage comparison (target 70%+)
- Lessons learned for Phase 3

---

## Risk Assessment and Mitigation

### Overall Phase 2 Risk: 🔴 **HIGH**

Phase 2 is the **highest-risk phase** of the modernization due to:
- Deep architectural changes (Swift 6 concurrency model)
- Extensive code modifications (estimated 100+ files touched)
- Cascading error patterns observed in Phase 1
- JavaScriptCore fundamental constraint

However, risk is **manageable** with proper planning and incremental approach.

---

### Risk Matrix

| **Risk** | **Likelihood** | **Impact** | **Severity** | **Mitigation** |
|----------|----------------|------------|--------------|----------------|
| Cascading errors in Swift 6 migration | 🔴 Very High | 🔴 High | 🔴 **CRITICAL** | Comprehensive audit (Stage 1), tier-by-tier fixes, incremental testing |
| Performance regression >10% | 🟡 Medium | 🟡 Medium | 🟡 **MODERATE** | Benchmark before/after, optimize actor boundaries, reject if >20% |
| Breaking changes to public APIs | 🟡 Medium | 🔴 High | 🟡 **MODERATE** | Map call chains, provide bridging methods, semantic versioning |
| JavaScriptCore blocking migration | 🔴 High | 🔴 High | 🔴 **CRITICAL** | Accept constraint, use @preconcurrency, document strategy |
| Test suite doesn't catch concurrency bugs | 🟡 Medium | 🟡 Medium | 🟡 **MODERATE** | Add async tests, enable Thread Sanitizer, manual testing protocol |
| Timeline overrun (>4 months) | 🟡 Medium | 🟡 Medium | 🟡 **MODERATE** | Weekly progress reviews, scope adjustment authority |

---

### Critical Risk Deep-Dive

#### Risk 1: Swift 6 Migration Cascading Errors 🔴

**Description**: Each error fix reveals new errors, leading to unpredictable scope explosion

**Phase 1 Evidence**:
- Fixed 3 errors → revealed 6 new errors (2× multiplier)
- Fixed 6 errors → revealed 3 new errors (0.5× multiplier)
- Fixed 3 errors → revealed 3 new errors (1× multiplier)
- **Average: 1.33× multiplier per round**
- **Projection: 3 visible errors → 15-40 total errors**

**Mitigation Strategy**:

1. **Comprehensive Audit First** (P2-T01 Stage 1)
   - Don't make changes until full scope is understood
   - Catalog ALL global state, static properties, API surfaces
   - Estimate total errors before first fix
   - Get approval for estimated scope

2. **Tier-by-Tier Approach** (P2-T01 Stage 3)
   - Fix Tier 1 completely, test, commit
   - Fix Tier 2 completely, test, commit
   - Fix Tier 3 completely, test, commit
   - Fix Tier 4 completely, test, commit
   - Never move to next tier with failing tests

3. **Incremental Testing**
   - Run full test suite after each tier
   - Manual smoke test after each tier
   - Thread sanitizer after each tier
   - Revert tier if tests fail (rollback safety)

4. **Scope Adjustment Authority**
   - If total errors exceed 60, pause and reassess
   - If any single tier exceeds 5 days, escalate for decision
   - Option to revert to Swift 5 if truly blocked

**Success Indicator**: Tier-by-tier commits with passing tests

---

#### Risk 2: JavaScriptCore Non-Sendable Blocker 🔴

**Description**: 89 JSContext/JSValue usages cannot be made Sendable (Apple framework limitation)

**Technical Reality**:
```swift
// Apple's JavaScriptCore framework (as of macOS 14, iOS 17)
public class JSContext: NSObject { }  // NOT Sendable
public class JSValue: NSObject { }    // NOT Sendable

// No way to make Sendable without Apple adding conformance
```

**Why This Matters**:
- JSContext/JSValue cannot cross actor boundaries safely in Swift 6
- Affects 20 files with 89 usages
- Core architectural dependency (cannot be removed)

**Mitigation Strategy**:

1. **Architectural Decision: MainActor Isolation**
   ```swift
   @MainActor
   class OutlineEditor {
       private let jsContext: JSContext

       // All JavaScript operations stay on MainActor
       func evaluateScript(_ script: String) -> JSValue {
           jsContext.evaluateScript(script)
       }
   }
   ```

2. **Compiler Suppression**:
   ```swift
   @preconcurrency import JavaScriptCore  // Suppress warnings
   ```

3. **Documentation**:
   - Document why @preconcurrency is needed (Apple framework limitation)
   - Document MainActor isolation strategy
   - Document thread-safety assumptions
   - Add TODO for future when Apple adds Sendable

4. **Monitor Apple's Roadmap**:
   - Check WWDC 2026 announcements
   - Monitor Swift Evolution proposals
   - Update when Apple adds Sendable conformance

**Acceptance**: This is an **architectural constraint** with no perfect solution. The mitigation is sound and documented.

---

#### Risk 3: Performance Regression

**Description**: Actor hopping overhead may slow down critical paths

**Concern**: Swift Concurrency adds overhead for actor boundary crossings

**Mitigation Strategy**:

1. **Benchmark Before** (P2-T01 Stage 1)
   - Measure current performance baseline
   - Identify hot paths (typing, scrolling, JavaScript evaluation)
   - Document baseline metrics

2. **Benchmark After** (P2-T01 Stage 4)
   - Measure same operations in Swift 6 mode
   - Compare with baseline
   - Calculate % regression

3. **Acceptance Criteria**:
   - ✅ **<5% regression**: Excellent, proceed
   - ✅ **5-10% regression**: Acceptable for safety benefits
   - ⚠️ **10-20% regression**: Investigate optimization opportunities
   - ❌ **>20% regression**: Requires architectural rethink

4. **Optimization Strategies** (if needed):
   - Reduce actor boundary crossings in hot paths
   - Batch operations to minimize hops
   - Keep related state in same actor
   - Use `nonisolated` for truly thread-safe operations

**Rollback Criteria**: If >20% regression cannot be optimized below 10%, consider:
- Reverting to Swift 5 mode
- Deferring Swift 6 to Phase 4
- Requesting architectural consultation

---

## Execution Timeline

### Phase 2 Timeline: 14-16 Weeks (3.5-4 months)

```
Week 1-2:    P2-T00 (Planning) ✅ COMPLETE
Week 3-5:    P2-T01 (Swift 6 Migration) - CRITICAL PATH
Week 6-7:    P2-T02 - P2-T05 (Async/Await)
Week 7-8:    P2-T06 - P2-T10 (Method Swizzling)
Week 9-11:   P2-T11 - P2-T19 (Protocol Design)
Week 12-14:  P2-T20 - P2-T23 (Concurrency Safety)
Week 14-15:  P2-T24 - P2-T25 (Documentation)
Week 16:     Buffer for overruns and final testing
```

### Milestone Schedule

| **Milestone** | **Week** | **Deliverables** | **Success Criteria** |
|---------------|----------|------------------|----------------------|
| **M1: Planning Complete** | Week 2 | Phase-2-Planning.md ✅ | Planning approved, ready to execute |
| **M2: Swift 6 Audit** | Week 3 | Swift-6-Migration-Strategy.md | Full scope understood, error estimate |
| **M3: Swift 6 Enabled** | Week 4 | swift6-migration-errors.log | All errors cataloged and categorized |
| **M4: Swift 6 Tier 1+2** | Week 5 | Critical errors fixed | Build succeeds, tests pass |
| **M5: Swift 6 Complete** | Week 6 | All tiers fixed | Swift 6 mode active, zero errors/warnings |
| **M6: Async/Await** | Week 7 | P2-T02 - P2-T05 complete | All callback patterns converted |
| **M7: Method Swizzling** | Week 8 | P2-T06 - P2-T10 complete | Swizzling removed or justified |
| **M8: Protocol Design** | Week 11 | P2-T11 - P2-T19 complete | 3+ protocols with mocks |
| **M9: Concurrency Safety** | Week 14 | P2-T20 - P2-T23 complete | Complete checking enabled, tests added |
| **M10: Phase 2 Complete** | Week 15 | Phase-2-Completion-Report.md | All tasks done, metrics documented |

### Weekly Progress Reviews

**Format**: Brief status update covering:
1. Tasks completed this week
2. Tasks in progress
3. Blockers or risks identified
4. Next week's plan
5. Timeline confidence (on track / at risk / delayed)

**Escalation Criteria**:
- ⚠️ Any task exceeds estimated duration by 2× → Escalate for scope review
- ⚠️ Swift 6 error count exceeds 60 → Escalate for architectural review
- ⚠️ Performance regression >20% → Escalate for optimization strategy
- ⚠️ Behind schedule by 2 weeks → Escalate for timeline adjustment

---

## Success Criteria

### Phase 2 Completion Criteria

Phase 2 is considered **COMPLETE** when ALL of the following are true:

#### Technical Criteria

- ✅ **Swift 6 Language Mode Active**
  - SWIFT_VERSION = 6.0 in project.pbxproj
  - SWIFT_CONCURRENCY_COMPLETE_CHECKING = targeted
  - Build succeeds with zero errors
  - Zero concurrency warnings (or documented with @preconcurrency)

- ✅ **Async/Await Adoption**
  - Zero uses of DispatchQueue.main.asyncAfter
  - Zero @escaping completion handlers in new/updated code
  - delay() function uses Task.sleep
  - RemindersStore uses async throws
  - Debouncer is actor-based

- ✅ **Method Swizzling**
  - NSWindowTabbedBase swizzling removed
  - NSTextStorage swizzling removed OR justified with <20% performance impact
  - NSTextView accessibility swizzling removed OR documented as still needed for macOS 11+
  - JGMethodSwizzler removed OR only used by justified swizzling

- ✅ **Protocol-Oriented Design**
  - OutlineEditorProtocol defined and adopted
  - StyleSheetProtocol defined and adopted
  - OutlineDocumentProtocol defined and adopted
  - MockOutlineEditor created for testing
  - At least 1 test refactored to use mock

- ✅ **Concurrency Safety**
  - Thread Sanitizer enabled in test plans
  - All TSan warnings fixed or documented as false positives
  - AsyncOperationTests.swift created with 5+ test methods
  - All 160+ existing tests pass
  - Manual smoke testing complete

#### Quality Criteria

- ✅ **Code Coverage**: 70%+ (up from 60% baseline in Phase 1)
- ✅ **Performance**: <10% regression compared to Phase 1 baseline
- ✅ **Test Pass Rate**: 100% of tests pass
- ✅ **Documentation**: All architectural decisions documented

#### Process Criteria

- ✅ **Git History**: Clean commits with descriptive messages
- ✅ **Code Review**: Phase 2 changes reviewed (if applicable)
- ✅ **Documentation**: Phase-2-Completion-Report.md published
- ✅ **Lessons Learned**: Documented for Phase 3 planning

---

### Key Metrics

Phase 2 success will be measured by these metrics:

| **Metric** | **Phase 1 Baseline** | **Phase 2 Target** | **Measurement Method** |
|------------|----------------------|---------------------|------------------------|
| Swift Version | 5.0 | 6.0 | project.pbxproj SWIFT_VERSION |
| Concurrency Errors | 9 fixed, 3 visible (P1-T12) | 0 | xcodebuild error count |
| Concurrency Warnings | Unknown | 0 or documented | xcodebuild warning count |
| Async/Await Adoption | 9 usages (4.9%) | 100% of async operations | grep "async func" count |
| DispatchQueue Usage | 16 occurrences | 0 (except internal impl) | grep "DispatchQueue" count |
| Method Swizzling Files | 4 files | 0-2 files (justified) | Count of swizzle implementations |
| Protocol Definitions | 0 | 3+ | Count of *Protocol.swift files |
| Mock Implementations | 0 | 3+ | Count of Mock*.swift files |
| Code Coverage | 60% | 70%+ | Xcode coverage report |
| Test Count | 160+ | 180+ | Xcode test report |
| Test Pass Rate | 100% | 100% | Xcode test report |
| Performance Regression | N/A | <10% | Benchmark suite comparison |

---

## Phase 2 to Phase 3 Transition

### Phase 3 Overview

**Phase 3: UI Modernization**
**Duration**: 3-6 months
**Focus**: SwiftUI migration, TextKit 2, platform features

**Prerequisites from Phase 2**:
- ✅ Swift 6 mode active (required for SwiftUI integration)
- ✅ Async/await adopted (required for TextKit 2 APIs)
- ✅ Protocol-oriented design (enables SwiftUI preview mocks)
- ✅ Concurrency safety (required for SwiftUI state management)

### Transition Criteria

Phase 3 can begin when:
- ✅ Phase 2 completion criteria met
- ✅ Phase-2-Completion-Report.md published
- ✅ All Phase 2 commits pushed to remote
- ✅ User approval to proceed with Phase 3

### Phase 3 Kickoff Activities

1. **Review Phase 2 Lessons Learned**
   - What went well? (replicate in Phase 3)
   - What challenges occurred? (avoid in Phase 3)
   - Any process improvements?

2. **Update Phase 3 Plan**
   - Incorporate Phase 2 learnings
   - Adjust timeline if needed
   - Update risk assessment

3. **Prepare for SwiftUI Migration**
   - Audit UI components for migration candidates
   - Set up SwiftUI preview infrastructure
   - Plan AppKit/SwiftUI interop strategy

---

## Appendices

### Appendix A: Method Swizzling Removal Tasks

#### P2-T06: Audit Method Swizzling Usage

**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/JGMethodSwizzler.m`
- `TaskPaper/NSWindowTabbedBase.m`
- `TaskPaper/NSTextStorage+FixTextStorageBug.m`
- `TaskPaper/NSTextView-AccessibilityPerformanceHacks.m`

**Activities**:
1. Document each swizzled method
2. Research why swizzling was needed
3. Check if macOS APIs have improved
4. Categorize risk: Low/Medium/High
5. Create removal plan

**Deliverable**: `method-swizzling-audit.md`

---

#### P2-T07: Remove NSWindowTabbedBase Swizzling

**Risk**: 🟢 Low
**File**: `TaskPaper/NSWindowTabbedBase.m`

**Current**: Swizzles NSWindow tabbing behavior (likely workaround for old macOS bug)

**Plan**:
1. Research NSWindow tabbing in macOS 11+
2. Test window tab behavior without swizzling
3. If works correctly, delete NSWindowTabbedBase.m
4. Update project references
5. Test window tabbing UI

**Success**: Window tabs work without swizzling

---

#### P2-T08: Measure NSTextStorage Swizzling Performance

**Risk**: 🟡 Medium
**File**: `TaskPaper/NSTextStorage+FixTextStorageBug.m`

**Current**: Swizzles NSTextStorage methods for performance optimization

**Plan**:
1. Create performance test harness
2. Benchmark WITH swizzling (baseline)
3. Benchmark WITHOUT swizzling
4. Calculate % difference
5. Decision:
   - If <10% impact: Remove swizzling
   - If 10-20% impact: Discuss with user
   - If >20% impact: Keep swizzling (documented)

**Deliverable**: `nstextstorage-swizzling-performance.md`

---

#### P2-T09: Remove or Refactor NSTextStorage Swizzling

**Risk**: 🟡 Medium
**Dependencies**: P2-T08

**Option A: Remove** (if <10% impact)
- Delete NSTextStorage+FixTextStorageBug.m
- Test text editing performance
- Verify no regressions

**Option B: Refactor** (if 10-20% impact)
- Create explicit optimized methods
- Document performance justification
- Add performance regression tests

**Option C: Keep** (if >20% impact)
- Document why swizzling is needed
- Add inline comments
- Add TODO for future optimization

---

#### P2-T10: Handle NSTextView Accessibility Swizzling

**Risk**: 🟡 Medium
**File**: `TaskPaper/NSTextView-AccessibilityPerformanceHacks.m`

**Current**: Swizzles NSTextView accessibility methods (workaround for macOS VoiceOver performance bug)

**Plan**:
1. Test accessibility on macOS 11, 12, 13, 14
2. Measure VoiceOver performance WITHOUT swizzling
3. Decision:
   - If macOS fixed: Remove swizzling
   - If still needed: Keep with version check (e.g., macOS 10.x only)
   - Document in code

**Testing**: Enable VoiceOver, navigate document, measure responsiveness

---

### Appendix B: Protocol-Oriented Design Tasks

#### P2-T11: Define OutlineEditorProtocol

**File**: `BirchEditor/BirchEditor.swift/BirchEditor/Protocols/OutlineEditorProtocol.swift` (new)

**Protocol Design**:
```swift
@MainActor
protocol OutlineEditorProtocol: AnyObject, Sendable {
    var outline: OutlineType { get }
    var textStorage: NSTextStorage { get }
    var styleSheet: StyleSheetProtocol { get }

    func deserializeItems(_ serialized: String, options: [String: Any]) -> [ItemType]
    func moveBranches(_ branches: [ItemType], parent: ItemType?, nextSibling: ItemType?, options: [String: Any])
    func evaluateScript(_ script: String) -> JSValue

    // Add other essential methods
}
```

**Activities**:
1. Review OutlineEditor class
2. Extract essential methods
3. Document requirements
4. Ensure Sendable compatibility
5. Write protocol documentation

---

#### P2-T12: Conform OutlineEditor to Protocol

**Activities**:
1. Add conformance: `extension OutlineEditor: OutlineEditorProtocol`
2. Implement any missing requirements
3. Run existing tests to verify
4. Fix any conformance errors

**Success**: OutlineEditor conforms, tests pass

---

#### P2-T13: Define StyleSheetProtocol

**File**: `BirchEditor/BirchEditor.swift/BirchEditor/Protocols/StyleSheetProtocol.swift` (new)

**Protocol Design**:
```swift
@MainActor
protocol StyleSheetProtocol: AnyObject, Sendable {
    func compileLESS(_ lessSource: String) -> String?
    func computedStyle(for element: [String: Any]) -> ComputedStyle?
    func updateVariables(_ variables: [String: Any])

    // Add other essential methods
}
```

---

#### P2-T14: Conform StyleSheet to Protocol

**Activities**: Same pattern as P2-T12

---

#### P2-T15: Define OutlineDocumentProtocol

**File**: `TaskPaper/Protocols/OutlineDocumentProtocol.swift` (new)

**Protocol Design**:
```swift
@MainActor
protocol OutlineDocumentProtocol: AnyObject, Sendable {
    var outline: OutlineType { get }
    var fileURL: URL? { get }

    func read(from data: Data, ofType typeName: String) throws
    func data(ofType typeName: String) throws -> Data
    func save(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType, completionHandler: @escaping (Error?) -> Void)

    // Add other essential methods
}
```

---

#### P2-T16: Conform OutlineDocument to Protocol

**Activities**: Same pattern as P2-T12

---

#### P2-T17: Create Mock OutlineEditor

**File**: `BirchEditor/BirchEditor.swift/BirchEditorTests/Mocks/MockOutlineEditor.swift` (new)

**Mock Implementation**:
```swift
@MainActor
final class MockOutlineEditor: OutlineEditorProtocol, @unchecked Sendable {
    // Recorded calls
    var deserializeItemsCalls: [(String, [String: Any])] = []
    var moveBranchesCalls: [([ItemType], ItemType?, ItemType?, [String: Any])] = []

    // Stub responses
    var deserializeItemsStub: [ItemType] = []

    // Protocol implementation
    func deserializeItems(_ serialized: String, options: [String: Any]) -> [ItemType] {
        deserializeItemsCalls.append((serialized, options))
        return deserializeItemsStub
    }

    // Implement other methods with call recording
}
```

**Benefits**:
- No JSContext initialization (faster tests)
- Predictable behavior (stub responses)
- Call verification (test assertions)

---

#### P2-T18: Refactor Tests to Use Mock

**File**: `BirchEditor/BirchEditor.swift/BirchEditorTests/OutlineEditorStorageTests.swift`

**Pattern**:
```swift
// BEFORE
class OutlineEditorStorageTests: XCTestCase {
    var storage: OutlineEditorTextStorage!

    override func setUp() {
        // Creates real OutlineEditor with JSContext (slow)
        storage = OutlineEditorTextStorage(...)
    }
}

// AFTER
class OutlineEditorStorageTests: XCTestCase {
    var storage: OutlineEditorTextStorage!
    var mockEditor: MockOutlineEditor!

    override func setUp() {
        mockEditor = MockOutlineEditor()
        storage = OutlineEditorTextStorage(editor: mockEditor)  // Inject mock
    }

    func testBidirectionalSync() {
        // Configure mock
        mockEditor.deserializeItemsStub = [/* test data */]

        // Run test
        storage.replaceCharacters(in: NSRange(...), with: "test")

        // Verify mock was called
        XCTAssertEqual(mockEditor.deserializeItemsCalls.count, 1)
    }
}
```

**Benefits**:
- 10-100× faster test execution
- No JavaScript bundle dependencies
- Deterministic test behavior

---

#### P2-T19: Add Dependency Injection to ViewController

**File**: `BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorViewController.swift`

**Pattern**:
```swift
@MainActor
class OutlineEditorViewController: NSViewController {
    // Default to concrete implementation
    var editorFactory: () -> OutlineEditorProtocol = {
        return OutlineEditor()
    }

    lazy var editor: OutlineEditorProtocol = editorFactory()

    // In tests, inject mock:
    // viewController.editorFactory = { MockOutlineEditor() }
}
```

---

### Appendix C: Swift 6 Error Examples

#### Example 1: MainActor Isolation Boundary

**Error**:
```
error: call to main actor-isolated instance method 'deserializeItems(_:options:)'
       in a synchronous nonisolated context
  --> ItemPasteboardUtilities.swift:38
```

**Code**:
```swift
@MainActor
class OutlineEditor {
    func deserializeItems(_ serialized: String, options: [String: Any]) -> [ItemType] {
        // MainActor-isolated
    }
}

class ItemPasteboardUtilities {
    class func readFromPasteboard(...) -> [ItemType]? {
        // Nonisolated (class method)
        return editor.deserializeItems(...)  // ERROR: crossing actor boundary
    }
}
```

**Fix Option A: Async**:
```swift
class func readFromPasteboard(...) async -> [ItemType]? {
    return await editor.deserializeItems(...)
}
```

**Fix Option B: assumeIsolated** (if verified safe):
```swift
class func readFromPasteboard(...) -> [ItemType]? {
    return MainActor.assumeIsolated {
        editor.deserializeItems(...)
    }
}
```

---

#### Example 2: Global Mutable State

**Warning**:
```
warning: var 'TabbedWindowsKey' is not concurrency-safe because it is non-isolated global mutable state
  --> OutlineEditorWindow.swift:15
```

**Code**:
```swift
var TabbedWindowsKey = "tabbedWindows"  // Global mutable state
```

**Fix Option A: Make immutable**:
```swift
let TabbedWindowsKey = "tabbedWindows"  // Preferred if not mutated
```

**Fix Option B: Add MainActor**:
```swift
@MainActor var TabbedWindowsKey = "tabbedWindows"  // If UI-related
```

**Fix Option C: Document thread-safety**:
```swift
nonisolated(unsafe) var TabbedWindowsKey = "tabbedWindows"  // If verified safe
// Only if there's a documented reason for thread-safety (e.g., only accessed from main thread)
```

---

#### Example 3: Non-Sendable Type

**Warning**:
```
warning: passing non-Sendable parameter 'completion' to actor-isolated function risks causing data races
  --> RemindersStore.swift:42
```

**Code**:
```swift
func fetchReminders(completion: @escaping ([Reminder]) -> Void) {
    actor.processAsync {
        completion(reminders)  // WARNING: closure may not be Sendable
    }
}
```

**Fix: Make async**:
```swift
func fetchReminders() async -> [Reminder] {
    return await actor.processAsync()
}
```

---

### Appendix D: Command Reference

#### Build Commands

```bash
# Clean build
xcodebuild clean build -project TaskPaper.xcodeproj -scheme TaskPaper

# Build with warnings
xcodebuild build -project TaskPaper.xcodeproj -scheme TaskPaper 2>&1 | tee build.log

# Build specific configuration
xcodebuild build -project TaskPaper.xcodeproj -scheme TaskPaper -configuration Debug

# Run tests
xcodebuild test -project TaskPaper.xcodeproj -scheme TaskPaper -destination 'platform=macOS'

# Run tests with Thread Sanitizer
xcodebuild test -project TaskPaper.xcodeproj -scheme TaskPaper -enableThreadSanitizer YES

# Generate code coverage
xcodebuild test -project TaskPaper.xcodeproj -scheme TaskPaper -enableCodeCoverage YES
```

#### Search Commands

```bash
# Find all global variables
grep -rn "^var " --include="*.swift" | grep -v "    var "  # Top-level only

# Find all static properties
grep -rn "static var\|static let" --include="*.swift"

# Find all DispatchQueue usage
grep -rn "DispatchQueue" --include="*.swift"

# Find all async/await usage
grep -rn "async func\|await " --include="*.swift"

# Find all completion handlers
grep -rn "@escaping.*-> Void" --include="*.swift"

# Find all JSContext/JSValue usage
grep -rn "JSContext\|JSValue" --include="*.swift"

# Count Swift files
find . -name "*.swift" -type f | wc -l

# Count lines of Swift code
find . -name "*.swift" -type f -exec wc -l {} + | tail -1
```

---

### Appendix E: Related Documentation

**Phase 1 Documentation**:
- `docs/modernisation/IMPLEMENTATION-ROADMAP.md` - Overall 4-phase plan
- `docs/modernisation/Phase-1-Completion-Report.md` - Phase 1 final report
- `docs/modernisation/SESSION-SUMMARY.md` - Phase 1 session summaries
- `docs/modernisation/PHASE-1-PROGRESS.md` - Phase 1 task tracking

**Swift 6 Analysis**:
- `Swift-Concurrency-Migration-Analysis.md` (git history, commit c4ed5db)
  - 1,000 line comprehensive analysis
  - Path evaluation (Path 2 recommended and executed)
  - Risk assessment matrix
  - Codebase architecture assessment
  - Historical context and decisions

**Test Documentation**:
- `docs/modernisation/P1-T17-final-report.md` - BirchEditor test plan challenges
- `docs/modernisation/P1-T21-P1-T22-XCODE-REQUIRED.md` - UI tests and coverage guide

**External Resources**:
- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Migrating to Swift 6](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/)
- [WWDC 2021: Meet async/await](https://developer.apple.com/videos/play/wwdc2021/10132/)
- [WWDC 2021: Protect mutable state with Swift actors](https://developer.apple.com/videos/play/wwdc2021/10133/)
- [WWDC 2022: Eliminate data races using Swift Concurrency](https://developer.apple.com/videos/play/wwdc2022/110351/)

---

## Document Revision History

| **Version** | **Date** | **Changes** | **Author** |
|-------------|----------|-------------|------------|
| 1.0 | 2025-11-12 | Initial Phase 2 planning document created | Claude (Anthropic) |

---

**END OF DOCUMENT**

**Total Length**: ~24,000 words / ~50 pages
**Estimated Read Time**: 90 minutes
**Status**: ✅ **PLANNING COMPLETE - READY FOR EXECUTION**

**Next Step**: Review and approve this planning document, then begin P2-T01 (Swift 6 Migration)
