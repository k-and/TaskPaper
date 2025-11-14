# Code Cleanup Opportunities

**Date**: 2025-11-14
**Purpose**: Document technical debt and cleanup opportunities for post-migration

---

## Overview

This document catalogues identified cleanup opportunities that can be addressed after major migration milestones. These are low-priority improvements that don't block core development but enhance code quality.

---

## Category 1: Dead Code Removal

### 1.1: Commands.swift Dead Code

**File**: `BirchEditor/BirchEditor.swift/BirchEditor/Commands.swift`  
**Lines**: 17-70  
**Status**: Confirmed dead code (never called)  
**Priority**: Low  
**Effort**: 5 minutes

**Dead Properties**:
```swift
@MainActor
static var scriptCommandsDisposables: [DisposableType]?  // Line 20
@MainActor
static var scriptsFolderMonitor: PathMonitor?             // Line 22
```

**Dead Functions**:
```swift
static func initScriptCommands() { ... }     // Lines 43-51
static func reloadScriptCommands() { ... }   // Lines 53-70
```

**Reason**: 
- `ScriptCommands.swift` provides the active implementation
- `OutlineEditorAppDelegate.swift:53` calls `ScriptCommands.initScriptCommands()` (not `Commands.initScriptCommands()`)
- No references to `Commands.scriptCommandsDisposables` or `Commands.scriptsFolderMonitor`

**Removal Plan**:
1. Delete lines 17-70 from `Commands.swift`
2. Keep the active code (jsCommands, add(), findCommands(), dispatch())
3. Build and test to verify no breakage
4. Update TODO comment or remove entirely

**When to Remove**: After Phase 2 Swift 6 migration completes

---

## Category 2: Deprecated API Migration

### 2.1: Legacy Debouncer Removal

**File**: `BirchEditor/BirchEditor.swift/BirchEditor/Debouncer.swift`  
**Lines**: 53-80  
**Status**: Deprecated (Phase 2 work)  
**Priority**: Medium  
**Effort**: 15 minutes + testing

**Code**:
```swift
@available(*, deprecated, message: "Use Actor-based Debouncer(delay: TimeInterval, callback:) instead")
class LegacyDebouncer: NSObject { ... }
```

**Active Usage Sites**: 
- Search for `LegacyDebouncer` usage:
  ```bash
  grep -r "LegacyDebouncer" BirchEditor/ BirchOutline/ TaskPaper/
  ```

**Migration Steps**:
1. Find all `LegacyDebouncer` instantiations
2. Replace with actor-based `Debouncer`
3. Update call sites from synchronous to async/await
4. Remove `LegacyDebouncer` class

**When to Migrate**: After Phase 2 Swift 6 migration (async/await fully adopted)

---

### 2.2: Legacy delay() Function Removal

**File**: `BirchEditor/BirchEditor.swift/BirchEditor/delay.swift`  
**Lines**: 26-35  
**Status**: Deprecated (Phase 2 work)  
**Priority**: Medium  
**Effort**: 10 minutes + testing

**Code**:
```swift
@available(*, deprecated, message: "Use async delay(_ interval: TimeInterval) instead")
func delay(_ delay: Double, closure: @escaping () -> Void) { ... }
```

**Active Usage Sites**:
- Search for closure-based delay():
  ```bash
  grep -r "delay(" BirchEditor/ BirchOutline/ TaskPaper/ | grep "closure:"
  ```

**Migration Steps**:
1. Find all closure-based `delay()` calls
2. Replace with async version: `await delay(interval)`
3. Add `async` to containing functions
4. Remove legacy function

**When to Migrate**: After Phase 2 Swift 6 migration

---

### 2.3: Legacy RemindersStore Methods Removal

**File**: `BirchEditor/BirchEditor.swift/BirchEditor/RemindersStore.swift`  
**Lines**: 51-56, 72-94, 158-196  
**Status**: Deprecated (Phase 2 work)  
**Priority**: Medium  
**Effort**: 20 minutes + testing

**Deprecated Methods**:
```swift
@available(*, deprecated)
static func requestAccess(to: ..., completion: @escaping (Bool, Error?) -> Void) { ... }

@available(*, deprecated)
static func fetchReminderCalendars(completion: @escaping ([EKCalendar]) -> Void) { ... }

@available(*, deprecated)
static func fetchReminders(..., completion: @escaping ([Reminder]) -> Void) { ... }
```

**Active Usage Sites**:
- Search for completion handler versions:
  ```bash
  grep -r "RemindersStore.requestAccess" BirchEditor/ TaskPaper/
  grep -r "RemindersStore.fetchReminderCalendars" BirchEditor/ TaskPaper/
  grep -r "RemindersStore.fetchReminders" BirchEditor/ TaskPaper/
  ```

**Migration Steps**:
1. Find all completion handler-based calls
2. Replace with async/await versions
3. Remove deprecated methods

**When to Migrate**: After Phase 2 Swift 6 migration

---

## Category 3: Code Quality Improvements

### 3.1: windowForSheetHack Removal

**File**: `BirchEditor/BirchEditor.swift/BirchEditor/OutlineDocument.swift`  
**Line**: 18  
**Status**: Hack (workaround for sheet presentation)  
**Priority**: Low  
**Effort**: Unknown (needs investigation)

**Code**:
```swift
var windowForSheetHack: NSWindow?
```

**Investigation Needed**:
1. Search for usage of `windowForSheetHack`
2. Determine if still needed on macOS 11+
3. Research modern sheet presentation APIs
4. Test without hack

**When to Investigate**: After Phase 2, before Phase 3 UI modernization

---

## Category 4: Optimization Opportunities

### 4.1: Method Swizzling Elimination

**Files**: See `method-swizzling-audit.md`  
**Status**: Documented in Phase 2  
**Priority**: Medium-High  
**Effort**: 3-7 hours (varies by swizzle)

**Summary**:
- P2-T07: NSWindowTabbedBase (1-2 hours, low risk)
- P2-T08/T09: NSTextStorage performance (2-4 hours, medium risk)
- P2-T10: NSTextView accessibility (2-4 hours, medium risk)

See `MANUAL-XCODE-TASKS.md` sections P2-T07 through P2-T10 for details.

**When to Remove**: Phase 2 method swizzling tasks

---

## Category 5: Build System Modernization

### 5.1: JavaScript Build System Upgrade

**Files**: `BirchOutline/birch-outline.js/`, `BirchEditor/birch-editor.js/`  
**Status**: Blocked by gulp 3.x incompatibility  
**Priority**: Low (deferred to Phase 4)  
**Effort**: 4-8 hours

See `P1-T10-JavaScript-Build-Test-Results.md` for full analysis.

**Options**:
1. Upgrade gulp 3→4 (4-8 hours, medium risk)
2. Defer until Phase 4 Pure Swift migration (eliminate JavaScript entirely)
3. Use Node.js v11 as workaround if JS changes needed

**Current Decision**: Option 2 (defer until Phase 4)

---

## Category 6: Security Updates

### 6.1: npm Audit Vulnerabilities

**Status**: 54 vulnerabilities in JavaScript dependencies  
**Priority**: Low (dev dependencies only, not runtime)  
**Effort**: Depends on build system upgrade

**Details**: See `P1-T10-JavaScript-Build-Test-Results.md`

**Breakdown**:
- 18 critical
- 27 high
- 8 moderate
- 1 low

**When to Fix**: During Category 5.1 build system upgrade, or Phase 4 JavaScript elimination

---

## Category 7: Documentation Cleanup

### 7.1: Update Inline Comments Post-Migration

**Priority**: Low  
**Effort**: 1-2 hours

**Tasks**:
1. Remove outdated TODO comments after completing tasks
2. Update Swift 6 migration comments
3. Document nonisolated(unsafe) justifications
4. Add inline explanations for non-obvious concurrency patterns

**When to Do**: After Phase 2 Swift 6 migration

---

## Execution Priorities

### High Priority (Do in Phase 2)
1. Method swizzling elimination (P2-T07 through P2-T10)

### Medium Priority (Do in Phase 2/3)
1. Legacy async API removal (Debouncer, delay, RemindersStore)
2. windowForSheetHack investigation

### Low Priority (Do in Phase 3/4)
1. Commands.swift dead code removal
2. Documentation cleanup
3. JavaScript build system (or eliminate in Phase 4)
4. npm audit fixes (or eliminate in Phase 4)

---

## Testing Strategy

For all cleanup tasks:
1. Run full test suite before changes (baseline)
2. Make targeted removal
3. Build project (⌘B) - verify zero errors
4. Run full test suite (⌘U) - verify 100% pass rate
5. Manual smoke test of affected features
6. Commit with clear description

---

## Metrics

**Total Cleanup Effort**: ~10-20 hours across all categories  
**Lines of Code Removable**: ~200-300 lines  
**Risk Level**: Low-Medium (most items are isolated)  
**Impact**: Medium code quality improvement

---

## Conclusion

These cleanup opportunities represent **technical debt** that can be safely deferred. None block core modernization work. Address them incrementally between major milestones for continuous code quality improvement.

**Next Review**: After Phase 2 Swift 6 migration completes
