# Phase 2: Async & Safety (2-3 months) ⚠️ SCOPE EXPANDED

## ⚠️ IMPORTANT: Swift 6 Migration Added to Phase 2

**Date**: 2025-11-07  
**Status**: Phase 1 task P1-T12 (Swift 6 upgrade) has been **deferred to Phase 2** after comprehensive analysis.

**Background**:
During Phase 1, an attempt to upgrade from Swift 5.0 to Swift 6.0 revealed fundamental architectural incompatibilities with Swift's strict concurrency model. The codebase's 15-year-old architecture (2005-2018), mixed Swift/Objective-C composition (256 ObjC files vs. 182 Swift files), and heavy JavaScriptCore integration (89 usages of non-Sendable types) requires comprehensive migration planning rather than tactical fixes.

**What Happened**:
- Initial Swift 6 upgrade triggered 19 concurrency errors
- Fixing 9 errors revealed 3 more (cascading "whack-a-mole" pattern)
- Architectural analysis estimated 15-40 total hidden errors
- Proper migration requires 2-4 weeks of dedicated work
- Decision made to revert to Swift 5.0 and plan comprehensive migration in Phase 2

**Impact on Phase 2**:
Phase 2 scope is expanded to include comprehensive Swift 6 migration with proper architectural planning:

1. **New P2-T00: Swift 6 Migration Planning** (1 week)
   - Review `Swift-Concurrency-Migration-Analysis.md` findings
   - Design actor isolation strategy for global state (45 variables, 48 static properties)
   - Plan async/await propagation through call chains
   - Address JavaScriptCore non-Sendable constraint (89 usages)
   - Create detailed migration roadmap with risk mitigation

2. **New P2-T01: Swift 6 Language Mode Upgrade** (2-3 weeks)
   - Upgrade `SWIFT_VERSION` from 5.0 to 6.0
   - Systematic actor isolation implementation
   - Convert synchronous APIs to async where needed
   - Resolve all concurrency violations (estimated 15-40 errors)
   - Comprehensive testing and regression prevention

3. **Timeline Impact**: Phase 2 duration increased from 2-3 months to **3-4 months**

4. **Risk Mitigation**: Structured migration approach vs. tactical fixes reduces long-term technical debt

**References**:
- `Swift-Concurrency-Migration-Analysis.md` - Comprehensive analysis of migration options and architectural constraints
- `docs/modernisation/Modernisation-Phase-1.md` (P1-T12) - Detailed history of Swift 6 attempt and reversion
- `docs/modernisation/swift6-upgrade-status.md` - Historical intermediate status

**Current State (Phase 1 Complete)**:
- ✅ Swift 5.0 active and building successfully
- ✅ 9 `nonisolated(unsafe)` annotations preserved for forward compatibility
- ✅ 4 incompatible `@MainActor` annotations removed (protocols and view controllers)
- ✅ No regressions to functionality

---

## Phase Overview (REVISED)

Phase 2 focuses on modernizing asynchronous code patterns, introducing architectural improvements that enhance testability and code safety, **and completing the comprehensive Swift 6 migration**. Building on Phase 1's foundation, this phase adopts Swift's modern concurrency features (async/await, actors) to replace callback-based patterns, eliminates fragile method swizzling implementations, introduces protocol-oriented design to reduce coupling and improve testability, **and migrates the entire codebase to Swift 6 language mode with proper actor isolation**. The objectives are to **complete Swift 6 migration with comprehensive concurrency adoption**, migrate from GCD-based callbacks to structured concurrency, remove all Objective-C runtime manipulation (method swizzling), establish protocols for core types to enable dependency injection and mocking, and ensure thread-safety through proper actor isolation. Expected outcomes include **compile-time data race prevention through Swift 6 concurrency model**, clearer async code flows that are easier to debug, improved stability by eliminating runtime method replacement, comprehensive protocol interfaces that enable thorough unit testing, and enhanced safety through Swift concurrency's data race protection.

**Revised Timeline**: 3-4 months (vs. original 2-3 months)

---

## P2-T01: Audit Async Operations and Callback Usage

**Component**: Concurrency Patterns  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/delay.swift`
- `BirchEditor/BirchEditor.swift/BirchEditor/Debouncer.swift`
- `BirchEditor/BirchEditor.swift/BirchEditor/RemindersStore.swift`
- All files with `DispatchQueue` usage

**Technical Changes**:
1. Use grep to find all GCD usage: `grep -r "DispatchQueue" --include="*.swift"`
2. Search for completion handler patterns: `grep -r "@escaping" --include="*.swift"`
3. Document each async operation with:
   - Current implementation (callback/GCD)
   - File and line number
   - Dependencies and callers
   - Complexity assessment (simple/medium/complex)
4. Create migration priority list based on:
   - Frequency of use (high-traffic paths first)
   - Complexity (simple conversions first)
   - Dependencies (leaf functions before callers)
5. Save audit to `docs/modernisation/async-audit.md`

**Prerequisites**: None

**Success Criteria**:
```bash
test -f docs/modernisation/async-audit.md
grep -q "DispatchQueue" docs/modernisation/async-audit.md
grep -q "@escaping" docs/modernisation/async-audit.md
grep -q "Priority" docs/modernisation/async-audit.md
```

---

## P2-T02: Replace delay() Function with Task.sleep()

**Component**: Concurrency Utilities  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/delay.swift`

**Technical Changes**:
1. Read current implementation of `delay()` function in delay.swift
2. Create new async version:
   ```swift
   @MainActor
   func delay(_ duration: Duration) async {
       try? await Task.sleep(for: duration)
   }
   ```
3. Add convenience overload accepting seconds:
   ```swift
   @MainActor
   func delay(seconds: Double) async {
       await delay(.seconds(seconds))
   }
   ```
4. Keep old GCD-based version as `delayLegacy()` temporarily (for callers not yet converted)
5. Add deprecation warning to old version:
   ```swift
   @available(*, deprecated, message: "Use async delay() instead")
   func delayLegacy(_ delay: Double, closure: @escaping () -> Void)
   ```

**Prerequisites**: P2-T01

**Success Criteria**:
```bash
# Verify new async function exists
grep -q "func delay.*async" BirchEditor/BirchEditor.swift/BirchEditor/delay.swift
grep -q "@MainActor" BirchEditor/BirchEditor.swift/BirchEditor/delay.swift
# Verify project compiles
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor -configuration Debug build | grep -q "BUILD SUCCEEDED"
```

---

## P2-T03: Convert RemindersStore to Full Async/Await

**Component**: External Integration  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/RemindersStore.swift`

**Technical Changes**:
1. Review existing async/await usage in RemindersStore (already partially converted)
2. Convert remaining completion handler methods to async:
   - If `fetchReminders(completion: @escaping ([Reminder]) -> Void)` exists, replace with `func fetchReminders() async throws -> [Reminder]`
   - If `saveReminder(_:completion:)` exists, replace with `func saveReminder(_:) async throws`
3. Replace EventKit completion handlers with async alternatives:
   - `requestAccess(to:completion:)` → `requestAccess(to:) async throws -> Bool`
4. Add proper error propagation (throws instead of passing errors to closures)
5. Ensure all methods are @MainActor where needed for UI updates
6. Update all call sites to use `await` instead of callbacks

**Prerequisites**: P2-T01

**Success Criteria**:
```bash
# Verify no completion handlers remain
! grep -q "@escaping" BirchEditor/BirchEditor.swift/BirchEditor/RemindersStore.swift
# Verify async functions exist
grep -q "async throws" BirchEditor/BirchEditor.swift/BirchEditor/RemindersStore.swift
# Verify compilation
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor -configuration Debug build | grep -q "BUILD SUCCEEDED"
```

---

## P2-T04: Convert Debouncer to Actor-Based Implementation

**Component**: Concurrency Utilities  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/Debouncer.swift`

**Technical Changes**:
1. Read current Debouncer implementation (likely uses DispatchQueue timers)
2. Replace with actor-based debouncer:
   ```swift
   actor Debouncer {
       private var task: Task<Void, Never>?
       private let duration: Duration
       
       init(duration: Duration) {
           self.duration = duration
       }
       
       func debounce(action: @Sendable @escaping () async -> Void) {
           task?.cancel()
           task = Task {
               try? await Task.sleep(for: duration)
               if !Task.isCancelled {
                   await action()
               }
           }
       }
   }
   ```
3. Update all Debouncer usage sites to use await
4. Remove GCD-based timer implementation
5. Ensure thread-safety through actor isolation

**Prerequisites**: P2-T01

**Success Criteria**:
```bash
# Verify actor implementation
grep -q "actor Debouncer" BirchEditor/BirchEditor.swift/BirchEditor/Debouncer.swift
grep -q "Task.sleep" BirchEditor/BirchEditor.swift/BirchEditor/Debouncer.swift
# Verify compilation
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor -configuration Debug build | grep -q "BUILD SUCCEEDED"
```

---

## P2-T05: Update Delay Call Sites to Use Async Delay

**Component**: Concurrency Patterns  
**Files**:
- All files identified in P2-T01 audit that use delay() function

**Technical Changes**:
1. Find all delay() call sites: `grep -r "delay(" --include="*.swift" BirchEditor/`
2. For each call site:
   - Verify the calling function can be made async (or already is)
   - Replace `delay(1.0) { /* code */ }` with `await delay(seconds: 1.0); /* code */`
   - Remove closure syntax, flatten code
   - Add async to function signature if needed
   - Add Task wrapper if in synchronous context that can't be made async
3. Update at most 5 call sites per file to avoid conflicts
4. Test each conversion individually
5. Remove `delayLegacy()` once all call sites converted

**Prerequisites**: P2-T02

**Success Criteria**:
```bash
# Verify no legacy delay calls with closures remain
! grep -r "delay(.*{" --include="*.swift" BirchEditor/ || echo "Manual verification needed"
# Verify tests pass
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchEditor | grep -q "Test Succeeded"
```

---

## P2-T06: Audit Method Swizzling Usage

**Component**: Runtime Manipulation  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/JGMethodSwizzler.m`
- `BirchEditor/BirchEditor.swift/BirchEditor/NSTextView-AccessibilityPerformanceHacks.m`
- `BirchEditor/BirchEditor.swift/BirchEditor/NSTextStorage-Performance.m`
- `BirchEditor/BirchEditor.swift/BirchEditor/NSMutableAttributedString-Performance.m`
- `BirchEditor/BirchEditor.swift/BirchEditor/NSWindowTabbedBase.m`
- All .m files using `method_exchangeImplementations`

**Technical Changes**:
1. Find all method swizzling implementations: `grep -r "method_exchangeImplementations" --include="*.m"`
2. For each swizzled method, document:
   - Original class and method being swizzled
   - Reason for swizzling (performance, bug workaround, feature addition)
   - Risk level (high/medium/low) for removal
   - Alternative approach (subclassing, composition, accept default behavior)
3. Categorize by priority:
   - **High priority removal**: Window tabbing customizations (fragile)
   - **Medium priority**: Performance hacks (measure impact first)
   - **Low priority/keep**: Critical accessibility workarounds if no alternative
4. Create detailed removal plan: `docs/modernisation/swizzling-removal-plan.md`

**Prerequisites**: None

**Success Criteria**:
```bash
test -f docs/modernisation/swizzling-removal-plan.md
grep -q "method_exchangeImplementations" docs/modernisation/swizzling-removal-plan.md
grep -q "Alternative" docs/modernisation/swizzling-removal-plan.md
```

---

## P2-T07: Remove NSWindowTabbedBase Swizzling

**Component**: Window Management  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/NSWindowTabbedBase.m`
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorWindowController.swift`

**Technical Changes**:
1. Read NSWindowTabbedBase.m to understand what's being swizzled (likely tab bar customizations)
2. Check if original swizzling reasons still apply in modern macOS
3. Remove NSWindowTabbedBase.m file entirely
4. Remove from Xcode project target membership
5. Update OutlineEditorWindowController.swift to use standard NSWindow tabbing:
   - Set `tabbingMode` property directly
   - Use `tabbingIdentifier` for grouping
   - Accept default tab bar appearance
6. Test window tabbing behavior manually:
   - Create multiple documents
   - Verify tabs work correctly
   - Check View > Show Tab Bar menu
7. Document any behavior changes in release notes

**Prerequisites**: P2-T06

**Success Criteria**:
```bash
# Verify file removed
! test -f BirchEditor/BirchEditor.swift/BirchEditor/NSWindowTabbedBase.m
# Verify not referenced in project
! grep -q "NSWindowTabbedBase" TaskPaper.xcodeproj/project.pbxproj
# Verify build succeeds
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct -configuration Debug build | grep -q "BUILD SUCCEEDED"
```

---

## P2-T08: Measure Performance Impact of NSTextStorage Swizzling

**Component**: Performance Analysis  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/NSTextStorage-Performance.m`
- `BirchEditor/BirchEditor.swift/BirchEditor/NSMutableAttributedString-Performance.m`

**Technical Changes**:
1. Create performance test harness: `BirchEditorTests/PerformanceTests.swift`
2. Implement performance tests:
   - `testLargeDocumentLoad()`: Load 10,000 line document, measure time
   - `testTextInsertionPerformance()`: Insert text repeatedly, measure throughput
   - `testAttributeApplicationPerformance()`: Apply attributes to ranges
3. Run tests WITH swizzling (current implementation):
   ```bash
   xcodebuild test -project TaskPaper.xcodeproj -scheme BirchEditor -only-testing:BirchEditorTests/PerformanceTests
   ```
4. Record baseline metrics to `docs/modernisation/performance-baseline.txt`
5. Temporarily disable swizzling (comment out in +load method)
6. Run tests WITHOUT swizzling, record metrics
7. Calculate performance delta (expected: 5-15% slower without swizzling)
8. Document results and make decision: keep if delta > 20%, remove if < 10%

**Prerequisites**: P2-T06

**Success Criteria**:
```bash
test -f BirchEditorTests/PerformanceTests.swift
test -f docs/modernisation/performance-baseline.txt
grep -q "testLargeDocumentLoad" docs/modernisation/performance-baseline.txt
# Verify decision documented
grep -qE "(KEEP|REMOVE)" docs/modernisation/performance-baseline.txt
```

---

## P2-T09: Remove or Refactor NSTextStorage Performance Swizzling

**Component**: Text System Optimization  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/NSTextStorage-Performance.m`
- `BirchEditor/BirchEditor.swift/BirchEditor/NSMutableAttributedString-Performance.m`

**Technical Changes**:
1. Based on P2-T08 results, choose path:

**Option A: Remove (if performance impact < 10%)**:
   - Delete NSTextStorage-Performance.m and NSMutableAttributedString-Performance.m
   - Remove from Xcode project
   - Accept slight performance regression for better stability

**Option B: Refactor (if performance impact > 10%)**:
   - Keep critical optimizations as documented extension methods
   - Remove actual method swizzling
   - Update OutlineEditorTextStorage to call optimized methods explicitly:
     ```swift
     // Instead of swizzled method being called automatically
     // Call optimized version explicitly:
     attributedString.performBatchAttributeUpdate { ... }
     ```

2. Remove JGMethodSwizzler.m if no longer used by any code
3. Run performance tests again to verify no regression
4. Update documentation explaining optimization approach

**Prerequisites**: P2-T08

**Success Criteria**:
```bash
# Verify swizzling removed or refactored
if ! test -f BirchEditor/BirchEditor.swift/BirchEditor/NSTextStorage-Performance.m; then
    echo "Removed successfully"
elif ! grep -q "method_exchangeImplementations" BirchEditor/BirchEditor.swift/BirchEditor/NSTextStorage-Performance.m; then
    echo "Refactored successfully"
fi
# Verify performance maintained
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchEditor -only-testing:BirchEditorTests/PerformanceTests | grep -q "Test Succeeded"
```

---

## P2-T10: Handle NSTextView Accessibility Performance Hacks

**Component**: Accessibility  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/NSTextView-AccessibilityPerformanceHacks.m`

**Technical Changes**:
1. Read NSTextView-AccessibilityPerformanceHacks.m to understand what's disabled
2. Research if macOS has addressed underlying performance issues in recent versions
3. Test accessibility performance WITHOUT hacks on modern macOS (11+):
   - Enable VoiceOver
   - Open large document (1000+ lines)
   - Measure scrolling and navigation performance
4. Choose approach:
   - **Remove if macOS fixed**: Delete file, accept native accessibility performance
   - **Keep if still needed**: Document as technical debt, add TODO comment with macOS version check
   - **Partial removal**: Keep only critical hacks, remove others
5. If keeping, add runtime version check to only apply on older macOS versions
6. Document decision rationale in code comments and `docs/modernisation/accessibility-notes.md`

**Prerequisites**: P2-T06

**Success Criteria**:
```bash
# Verify decision made and documented
test -f docs/modernisation/accessibility-notes.md
# Verify code compiles and accessibility works
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct build | grep -q "BUILD SUCCEEDED"
echo "Manual test: Enable VoiceOver and test editor performance"
```

---

## P2-T11: Define OutlineEditorProtocol

**Component**: Protocol-Oriented Design  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/Protocols/OutlineEditorProtocol.swift` (new)

**Technical Changes**:
1. Create `Protocols/` directory in BirchEditor module
2. Create `OutlineEditorProtocol.swift` file
3. Analyze OutlineEditor concrete type to extract protocol:
   - Find all public methods and properties
   - Identify core operations (init, load, save, edit, query)
4. Define protocol:
   ```swift
   @MainActor
   protocol OutlineEditorProtocol {
       var textStorage: NSTextStorage { get }
       var jsOutlineEditor: JSValue { get }
       
       func replaceRange(_ range: NSRange, withString string: String)
       func setAttribute(_ attribute: String, value: Any?, range: NSRange)
       func performQuery(_ query: String) -> [OutlineItem]
       // ... other core methods
   }
   ```
5. Ensure protocol is Sendable-compatible
6. Add detailed documentation comments for each protocol requirement

**Prerequisites**: None

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditor/Protocols/OutlineEditorProtocol.swift
grep -q "protocol OutlineEditorProtocol" BirchEditor/BirchEditor.swift/BirchEditor/Protocols/OutlineEditorProtocol.swift
# Verify compiles
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor build | grep -q "BUILD SUCCEEDED"
```

---

## P2-T12: Conform OutlineEditor to OutlineEditorProtocol

**Component**: Protocol-Oriented Design  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditor.swift` (or wherever concrete type is defined)

**Technical Changes**:
1. Import protocol: `import BirchEditor.Protocols`
2. Add protocol conformance to OutlineEditor class:
   ```swift
   extension OutlineEditor: OutlineEditorProtocol {
       // Conformance is automatic if public API matches protocol
       // Add any missing implementations
   }
   ```
3. If any protocol requirements are missing, implement them
4. If any existing methods have incompatible signatures, create bridge methods
5. Verify all protocol requirements satisfied
6. Run unit tests to ensure no behavior changed
7. Update documentation to reference protocol

**Prerequisites**: P2-T11

**Success Criteria**:
```bash
grep -q ": OutlineEditorProtocol" BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditor.swift
# Verify compilation succeeds (protocol conformance validated)
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor build | grep -q "BUILD SUCCEEDED"
# Verify tests pass
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchEditor | grep -q "Test Succeeded"
```

---

## P2-T13: Define StyleSheetProtocol

**Component**: Protocol-Oriented Design  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/Protocols/StyleSheetProtocol.swift` (new)

**Technical Changes**:
1. Create `StyleSheetProtocol.swift` in Protocols directory
2. Analyze StyleSheet concrete class implementation
3. Define protocol:
   ```swift
   protocol StyleSheetProtocol {
       var lessSource: String { get }
       var compiledCSS: String { get }
       
       func compile(variables: [String: String]) throws
       func computedStyle(for selector: String) -> ComputedStyle?
       func color(for selector: String, property: String) -> NSColor?
       func font(for selector: String) -> NSFont?
   }
   ```
4. Include error types for compilation failures
5. Document expected LESS variable format
6. Add usage examples in comments

**Prerequisites**: None

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditor/Protocols/StyleSheetProtocol.swift
grep -q "protocol StyleSheetProtocol" BirchEditor/BirchEditor.swift/BirchEditor/Protocols/StyleSheetProtocol.swift
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor build | grep -q "BUILD SUCCEEDED"
```

---

## P2-T14: Conform StyleSheet to StyleSheetProtocol

**Component**: Protocol-Oriented Design  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/StyleSheet.swift`

**Technical Changes**:
1. Add protocol conformance:
   ```swift
   extension StyleSheet: StyleSheetProtocol {
       // Implement any missing protocol requirements
   }
   ```
2. Ensure existing public API satisfies protocol
3. If private methods are referenced in protocol, make them internal/public
4. Add any missing protocol methods
5. Verify LESS compilation still works correctly
6. Run StyleSheetTests (from P1-T19) to verify no regressions

**Prerequisites**: P2-T13

**Success Criteria**:
```bash
grep -q ": StyleSheetProtocol" BirchEditor/BirchEditor.swift/BirchEditor/StyleSheet.swift
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor build | grep -q "BUILD SUCCEEDED"
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchEditor -only-testing:BirchEditorTests/StyleSheetTests | grep -q "Test Succeeded"
```

---

## P2-T15: Define OutlineDocumentProtocol

**Component**: Protocol-Oriented Design  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/Protocols/OutlineDocumentProtocol.swift` (new)

**Technical Changes**:
1. Create `OutlineDocumentProtocol.swift`
2. Analyze OutlineDocument class (document model layer)
3. Define protocol for document operations:
   ```swift
   protocol OutlineDocumentProtocol: AnyObject {
       var outline: BirchOutline { get }
       var outlineEditor: OutlineEditorProtocol? { get set }
       
       func read(from data: Data, ofType typeName: String) throws
       func data(ofType typeName: String) throws -> Data
       func reloadFromSerialization(_ serialization: String)
       func serialization() -> String
   }
   ```
4. Ensure compatibility with NSDocument APIs (or abstract them)
5. Document serialization format expectations

**Prerequisites**: P2-T11 (needs OutlineEditorProtocol)

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditor/Protocols/OutlineDocumentProtocol.swift
grep -q "protocol OutlineDocumentProtocol" BirchEditor/BirchEditor.swift/BirchEditor/Protocols/OutlineDocumentProtocol.swift
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor build | grep -q "BUILD SUCCEEDED"
```

---

## P2-T16: Conform OutlineDocument to OutlineDocumentProtocol

**Component**: Protocol-Oriented Design  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineDocument.swift`

**Technical Changes**:
1. Add protocol conformance:
   ```swift
   extension OutlineDocument: OutlineDocumentProtocol {
       // Conformance implementations
   }
   ```
2. Resolve any type mismatches between protocol and NSDocument methods
3. Ensure all protocol requirements are satisfied
4. Run DocumentIntegrationTests (from P1-T20) to verify no regressions
5. Update documentation to reference protocol

**Prerequisites**: P2-T15

**Success Criteria**:
```bash
grep -q ": OutlineDocumentProtocol" BirchEditor/BirchEditor.swift/BirchEditor/OutlineDocument.swift
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor build | grep -q "BUILD SUCCEEDED"
xcodebuild test -project TaskPaper.xcodeproj -scheme TaskPaper-Direct -only-testing:TaskPaperTests/DocumentIntegrationTests | grep -q "Test Succeeded"
```

---

## P2-T17: Create Mock OutlineEditor for Testing

**Component**: Test Infrastructure  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditorTests/Mocks/MockOutlineEditor.swift` (new)

**Technical Changes**:
1. Create `Mocks/` directory in BirchEditorTests
2. Implement MockOutlineEditor conforming to OutlineEditorProtocol:
   ```swift
   @MainActor
   final class MockOutlineEditor: OutlineEditorProtocol {
       var textStorage: NSTextStorage = NSTextStorage()
       var jsOutlineEditor: JSValue = JSValue() // Mock JSValue
       
       // Record method calls for verification
       var replaceRangeCalls: [(NSRange, String)] = []
       
       func replaceRange(_ range: NSRange, withString string: String) {
           replaceRangeCalls.append((range, string))
           // Simple mock implementation
       }
       
       // ... implement other protocol methods
   }
   ```
3. Add call recording for all methods to enable verification in tests
4. Add configurable return values for query methods
5. Document mock usage in header comments

**Prerequisites**: P2-T11, P2-T12

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditorTests/Mocks/MockOutlineEditor.swift
grep -q "MockOutlineEditor: OutlineEditorProtocol" BirchEditor/BirchEditor.swift/BirchEditorTests/Mocks/MockOutlineEditor.swift
# Verify test target compiles
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor -configuration Debug build-for-testing | grep -q "BUILD SUCCEEDED"
```

---

## P2-T18: Refactor OutlineEditorTextStorage Tests to Use Mock

**Component**: Test Infrastructure  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditorTests/OutlineEditorTextStorageTests.swift`

**Technical Changes**:
1. Update OutlineEditorTextStorageTests (created in P1-T18)
2. Replace real OutlineEditor dependency with MockOutlineEditor:
   ```swift
   func testReplaceCharacters() {
       let mockEditor = MockOutlineEditor()
       let textStorage = OutlineEditorTextStorage(outlineEditor: mockEditor)
       
       textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "test")
       
       XCTAssertEqual(mockEditor.replaceRangeCalls.count, 1)
       XCTAssertEqual(mockEditor.replaceRangeCalls[0].1, "test")
   }
   ```
3. Update all test methods to use mock and verify interactions
4. Remove dependencies on JavaScript context (tests run faster)
5. Ensure test coverage maintained or improved
6. Verify all tests pass with mock

**Prerequisites**: P2-T17

**Success Criteria**:
```bash
grep -q "MockOutlineEditor" BirchEditor/BirchEditor.swift/BirchEditorTests/OutlineEditorTextStorageTests.swift
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchEditor -only-testing:BirchEditorTests/OutlineEditorTextStorageTests | grep -q "Test Succeeded"
```

---

## P2-T19: Add Dependency Injection to OutlineEditorViewController

**Component**: Architecture  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorViewController.swift`

**Technical Changes**:
1. Read current OutlineEditorViewController implementation
2. Add protocol-based dependency injection:
   ```swift
   open class OutlineEditorViewController: NSViewController {
       private(set) var outlineEditor: OutlineEditorProtocol?
       
       // Allow injection for testing
       init(outlineEditor: OutlineEditorProtocol? = nil) {
           self.outlineEditor = outlineEditor
           super.init(nibName: nil, bundle: nil)
       }
       
       // Existing init methods call above with nil (default behavior)
   }
   ```
3. Update all references to outlineEditor to use protocol type
4. Ensure existing code paths still work (default to concrete OutlineEditor)
5. Verify storyboard instantiation still functions
6. Update unit tests to inject mock editor

**Prerequisites**: P2-T11, P2-T12, P2-T17

**Success Criteria**:
```bash
grep -q "OutlineEditorProtocol" BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorViewController.swift
# Verify application still runs
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct -configuration Debug build | grep -q "BUILD SUCCEEDED"
echo "Manual test: Launch app and verify editor works"
```

---

## P2-T20: Enable Swift 6 Strict Concurrency Checking

**Component**: Concurrency Safety  
**Files**:
- `TaskPaper.xcodeproj/project.pbxproj`

**Technical Changes**:
1. Update build settings for all targets:
   ```
   SWIFT_CONCURRENCY_COMPLETE_CHECKING = targeted
   ```
   (Note: Use "targeted" mode first, not "complete" - less strict than full enforcement)
2. Build project and collect all concurrency warnings/errors
3. Save warnings to `docs/modernisation/concurrency-warnings.txt`:
   ```bash
   xcodebuild clean build 2>&1 | grep -E "(warning|error).*concurrency" > docs/modernisation/concurrency-warnings.txt
   ```
4. Do NOT fix warnings yet (that's subsequent tasks)
5. Document number and types of warnings
6. Categorize by severity and file location

**Prerequisites**: P2-T02, P2-T03, P2-T04 (basic async/await migration complete)

**Success Criteria**:
```bash
grep -q "SWIFT_CONCURRENCY_COMPLETE_CHECKING = targeted" TaskPaper.xcodeproj/project.pbxproj
test -f docs/modernisation/concurrency-warnings.txt
# Project should still compile (warnings, not errors)
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct build | grep -q "BUILD SUCCEEDED"
```

---

## P2-T21: Fix Main Actor Isolation Warnings in View Controllers

**Component**: Concurrency Safety  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorViewController.swift`
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineSidebarViewController.swift`
- `BirchEditor/BirchEditor.swift/BirchEditor/SearchBarViewController.swift`
- Other view controller files

**Technical Changes**:
1. Review concurrency warnings related to UIKit/AppKit access
2. Add @MainActor annotations to view controllers:
   ```swift
   @MainActor
   open class OutlineEditorViewController: NSViewController {
       // ... existing code
   }
   ```
3. Ensure all NSView, NSViewController subclasses marked @MainActor
4. Fix any cross-actor references:
   - Use `await MainActor.run { }` for UI updates from background
   - Use `nonisolated` for methods that don't need main actor
5. Address warnings about property access from different actors
6. Verify UI responsiveness not affected

**Prerequisites**: P2-T20

**Success Criteria**:
```bash
# Verify @MainActor annotations added
grep -q "@MainActor" BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorViewController.swift
# Verify reduced warnings
xcodebuild clean build 2>&1 | grep -c "warning.*concurrency" # Should be fewer than before
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct build | grep -q "BUILD SUCCEEDED"
```

---

## P2-T22: Fix Sendable Conformance Warnings

**Component**: Concurrency Safety  
**Files**:
- Various model and utility types throughout codebase

**Technical Changes**:
1. Review Sendable-related warnings from P2-T20 audit
2. Add Sendable conformance to thread-safe value types:
   ```swift
   struct OutlineItem: Sendable {
       // Immutable properties only
   }
   ```
3. Use `@unchecked Sendable` for types you verify are thread-safe but compiler can't prove:
   ```swift
   final class ThreadSafeCache: @unchecked Sendable {
       private let lock = NSLock()
       private var storage: [String: Any] = [:]
       // Manual thread safety via locks
   }
   ```
4. Avoid @unchecked where possible - prefer proper Sendable conformance
5. Fix captures in closures passed across actors:
   - Ensure captured values are Sendable
   - Use `[weak self]` or copy Sendable values
6. Document thread-safety assumptions

**Prerequisites**: P2-T20

**Success Criteria**:
```bash
# Verify Sendable conformances added
grep -q ": Sendable" BirchEditor/BirchEditor.swift/BirchEditor/*.swift
# Verify build succeeds with fewer warnings
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor build 2>&1 | grep -c "Sendable" # Should be reduced
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor build | grep -q "BUILD SUCCEEDED"
```

---

## P2-T23: Add Unit Tests for Async Operations

**Component**: Test Coverage  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditorTests/AsyncOperationTests.swift` (new)

**Technical Changes**:
1. Create AsyncOperationTests.swift test file
2. Implement tests for converted async functions:
   - `testAsyncDelay()`: Verify Task.sleep-based delay works
   - `testAsyncRemindersAccess()`: Test RemindersStore async operations
   - `testDebouncerCancellation()`: Verify debouncer cancels properly
   - `testConcurrentEdits()`: Test multiple simultaneous outline edits
   - `testActorIsolation()`: Verify actor-isolated state is thread-safe
3. Use async test methods:
   ```swift
   func testAsyncDelay() async throws {
       let start = Date()
       await delay(seconds: 0.1)
       let elapsed = Date().timeIntervalSince(start)
       XCTAssertGreaterThanOrEqual(elapsed, 0.1)
   }
   ```
4. Test error propagation in async contexts
5. Verify cancellation behavior

**Prerequisites**: P2-T02, P2-T03, P2-T04

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditorTests/AsyncOperationTests.swift
grep -q "func test.*async" BirchEditor/BirchEditor.swift/BirchEditorTests/AsyncOperationTests.swift
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchEditor -only-testing:BirchEditorTests/AsyncOperationTests | grep -q "Test Succeeded"
```

---

## P2-T24: Document Protocol Architecture

**Component**: Documentation  
**Files**:
- `docs/modernisation/Protocol-Architecture.md` (new)

**Technical Changes**:
1. Create comprehensive protocol architecture documentation
2. Document each protocol:
   - Purpose and responsibilities
   - Key methods and properties
   - Conforming types
   - Usage examples
   - Testing strategies with mocks
3. Create architecture diagram showing protocol relationships
4. Explain dependency injection pattern used
5. Provide guidelines for adding new protocols
6. Document benefits achieved:
   - Reduced coupling between modules
   - Improved testability with mocks
   - Easier refactoring and evolution
7. Include code examples for common patterns

**Prerequisites**: P2-T11 through P2-T19 (all protocols defined and adopted)

**Success Criteria**:
```bash
test -f docs/modernisation/Protocol-Architecture.md
grep -q "OutlineEditorProtocol" docs/modernisation/Protocol-Architecture.md
grep -q "StyleSheetProtocol" docs/modernisation/Protocol-Architecture.md
grep -q "OutlineDocumentProtocol" docs/modernisation/Protocol-Architecture.md
grep -q "dependency injection" docs/modernisation/Protocol-Architecture.md
```

---

## P2-T25: Update Code Coverage Metrics

**Component**: Testing Infrastructure  
**Files**:
- `docs/modernisation/phase2-coverage-report.txt` (new)

**Technical Changes**:
1. Run full test suite with code coverage enabled:
   ```bash
   xcodebuild test -project TaskPaper.xcodeproj -scheme TaskPaper-Direct -enableCodeCoverage YES
   ```
2. Generate coverage report:
   ```bash
   xcrun xccov view --report $(find ~/Library/Developer/Xcode/DerivedData -name '*.xcresult' | head -1) > docs/modernisation/phase2-coverage-report.txt
   ```
3. Compare with Phase 1 baseline (from P1-T22)
4. Target: 70%+ code coverage (up from 60% in Phase 1)
5. Identify uncovered areas for Phase 3/4 focus
6. Document coverage improvements by module
7. Highlight async code coverage specifically

**Prerequisites**: P2-T23 (all Phase 2 tests complete)

**Success Criteria**:
```bash
test -f docs/modernisation/phase2-coverage-report.txt
grep -q "%" docs/modernisation/phase2-coverage-report.txt
# Verify coverage increased
echo "Compare coverage percentage with phase1-coverage-baseline.txt - should be higher"
```

---

## P2-T26: Document Phase 2 Completion and Metrics

**Component**: Documentation  
**Files**:
- `docs/modernisation/Phase-2-Completion-Report.md` (new)

**Technical Changes**:
1. Create completion report documenting:
   - All 26 Phase 2 tasks completed
   - Async/await adoption statistics (number of functions converted)
   - Method swizzling removal summary (files removed/refactored)
   - Protocol architecture implementation (protocols defined, types conforming)
   - Concurrency safety improvements (warnings fixed)
   - Test coverage improvement (60% → 70%+ target)
2. Include metrics:
   - Lines of Objective-C removed
   - Number of protocols introduced
   - Number of async functions added
   - Concurrency warnings resolved
   - Performance comparison (before/after swizzling removal)
3. List remaining issues and technical debt
4. Document any breaking changes or behavior modifications
5. Update main README.md with Phase 2 completion status
6. Prepare recommendation for Phase 3 priorities

**Prerequisites**: All P2 tasks (P2-T01 through P2-T25)

**Success Criteria**:
```bash
test -f docs/modernisation/Phase-2-Completion-Report.md
grep -q "Phase 2 Complete" docs/modernisation/Phase-2-Completion-Report.md
grep -q "async/await" docs/modernisation/Phase-2-Completion-Report.md
grep -q "protocol" docs/modernisation/Phase-2-Completion-Report.md
grep -q "concurrency" docs/modernisation/Phase-2-Completion-Report.md
```

---

## Phase 2 Summary

**Total Tasks**: 26  
**Estimated Duration**: 2-3 months  
**Key Deliverables**:
- ✅ Async/await adoption throughout codebase
- ✅ All method swizzling removed or refactored
- ✅ Protocol-oriented architecture established
- ✅ Dependency injection enabled for testability
- ✅ Swift concurrency safety warnings addressed
- ✅ Code coverage improved to 70%+
- ✅ Actor isolation implemented where appropriate

**Phase 2 Success Metrics**:
- All 26 tasks completed and verified
- Zero method swizzling remaining (or documented exceptions)
- At least 3 core protocols defined and adopted
- 100% of async operations using async/await (no legacy callbacks)
- Code coverage ≥ 70%
- Swift concurrency warnings reduced by 80%+
- All tests passing (unit, integration, UI, async)
- No performance regressions from swizzling removal
