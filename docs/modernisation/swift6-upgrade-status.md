# Swift 6 Upgrade Status (P1-T12)

## Summary

TaskPaper has been partially upgraded to Swift 6, but the build currently fails due to Swift 6's strict concurrency checking requirements. This document explains the current state, challenges encountered, and recommended next steps.

## Changes Completed

### 1. SWIFT_VERSION Updated to 6.0
- **Files Modified**: `TaskPaper.xcodeproj/project.pbxproj`
- **Locations**: 2 project-level build configurations (Debug and Release)
- **Verification**: `grep -c "SWIFT_VERSION = 6.0" TaskPaper.xcodeproj/project.pbxproj` → 2

### 2. Initial Concurrency Fixes Applied
Fixed 9 Swift 6 concurrency errors by adding `nonisolated(unsafe)` annotations and `@MainActor` isolation:

#### Files Modified:
1. `BirchEditor/BirchEditor.swift/BirchEditor/Commands.swift`
   - Added `nonisolated(unsafe)` to 3 static properties (jsCommands, scriptCommandsDisposables, scriptsFolderMonitor)

2. `BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorWindow.swift`
   - Added `nonisolated(unsafe)` to 2 global variables (TabbedWindowsKey, tabbedWindowsContext)

3. `BirchEditor/BirchEditor.swift/BirchEditor/PreferencesWindowController.swift`
   - Added `nonisolated(unsafe)` to preferencesStoryboard

4. `BirchEditor/BirchEditor.swift/BirchEditor/PreviewTitlebarAccessoryViewController.swift`
   - Added `nonisolated(unsafe)` to previewTitlebarAccessoryStoryboard

5. `BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorTextStorageItem.swift`
   - Added `nonisolated(unsafe)` to SharedHandlePath

6. `BirchEditor/BirchEditor.swift/BirchEditor/ChoicePaletteRowView.swift`
   - Added `nonisolated(unsafe)` to sharedTableRowView

7. `BirchEditor/BirchEditor.swift/BirchEditor/SearchBarViewController.swift`
   - Added `@MainActor` to SearchBarViewController class

8. `BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorType.swift`
   - Added `@MainActor` to OutlineEditorHolderType protocol

9. `BirchEditor/BirchEditor.swift/BirchEditor/StyleSheet.swift`
   - Added `@MainActor` to StylesheetHolder protocol

10. `BirchEditor/BirchEditor.swift/BirchEditor/SearchBarSearchField.swift`
    - Added `@MainActor` to FirstResponderDelegate protocol

## Current Build Status

**Status**: BUILD FAILED  
**Remaining Errors**: 3 concurrency-related errors in ItemPasteboardUtilities.swift

### Error Details:
```
/BirchEditor/BirchEditor.swift/BirchEditor/ItemPasteboardUtilities.swift:38:27: 
error: call to main actor-isolated instance method 'deserializeItems(_:options:)' 
in a synchronous nonisolated context

/BirchEditor/BirchEditor.swift/BirchEditor/ItemPasteboardUtilities.swift:61:27: 
error: call to main actor-isolated instance method 'deserializeItems(_:options:)' 
in a synchronous nonisolated context

/BirchEditor/BirchEditor.swift/BirchEditor/ItemPasteboardUtilities.swift:159:28: 
error: call to main actor-isolated instance method 'moveBranches(_:parent:nextSibling:options:)' 
in a synchronous nonisolated context
```

## Challenges Encountered

### 1. Swift 6 Concurrency Model
Swift 6 enforces strict concurrency checking by default, even without explicit opt-in settings. The original task specification (P1-T12) mentioned setting `SWIFT_CONCURRENCY_COMPLETE_CHECKING = minimal` for compatibility mode, but in practice:

- Swift 6 still reports concurrency violations as **errors**, not warnings
- The `minimal` setting doesn't provide the expected backward compatibility
- Fixing one concurrency error often exposes more errors in a cascading pattern

### 2. Whack-a-Mole Pattern
Initial concurrency fixes created new errors:
- Adding `@MainActor` to protocols caused callers to violate actor isolation
- Global variables needed `nonisolated(unsafe)` annotations
- Protocol conformances crossing actor boundaries created new errors
- Each fix revealed deeper architectural concurrency issues

### 3. Architectural Considerations
The codebase was designed before Swift's structured concurrency model. Key issues:
- Global mutable state (singletons, static properties)
- Synchronous APIs that need to call MainActor-isolated code
- Protocol hierarchies that weren't designed with actor isolation in mind
- Mixed use of AppKit (MainActor-isolated) and business logic

## Recommended Next Steps

### Option 1: Comprehensive Swift 6 Concurrency Migration (Recommended)
Treat Swift 6 upgrade as a Phase 2 task requiring:
1. **Architectural audit** of concurrency patterns
2. **Systematic migration** of global state to actor-isolated state
3. **API redesign** for async/await where needed
4. **Protocol refactoring** to clarify actor isolation boundaries
5. **Comprehensive testing** after each major change

**Estimated effort**: 2-4 weeks  
**Risk**: Medium (requires careful testing)  
**Benefit**: Modern, safe concurrency model

### Option 2: Revert to Swift 5.0 (Temporary)
Revert SWIFT_VERSION to 5.0 until comprehensive concurrency work can be scheduled:
```bash
# Revert project file
git checkout TaskPaper.xcodeproj/project.pbxproj

# Or manually change SWIFT_VERSION = 6.0 back to 5.0
```

**Estimated effort**: 5 minutes  
**Risk**: Low  
**Benefit**: Maintains stable build while planning proper migration

### Option 3: Continue Incremental Fixes
Continue fixing concurrency errors one-by-one:
- Fix ItemPasteboardUtilities.swift errors (make functions async or use MainActor.assumeIsolated)
- Address cascading errors as they appear
- Document all unsafe concurrency patterns

**Estimated effort**: Unknown (could be 1-3 days)  
**Risk**: High (may uncover deeper issues)  
**Benefit**: Incremental progress toward Swift 6

## Task Specification vs. Reality

### Original P1-T12 Expectations:
```bash
# Success Criteria from Modernisation-Phase-1.md
grep -q "SWIFT_VERSION = 6.0" TaskPaper.xcodeproj/project.pbxproj  ✅ DONE
xcodebuild ... | grep -q "BUILD SUCCEEDED"  ❌ FAILED
```

### Gap Analysis:
The task specification assumed:
1. Swift 6 would have better backward compatibility with `minimal` concurrency checking
2. Changing SWIFT_VERSION would be primarily a compiler flag change
3. Concurrency warnings (not errors) could be deferred to P1-T13

**Reality**: Swift 6's strict concurrency checking makes this a more significant migration than anticipated.

## Files Created/Modified

### Documentation:
- `docs/modernisation/swift6-upgrade-status.md` (this file)
- `docs/modernisation/swift6-upgrade-build.log` (build log with 6 errors fixed)
- `docs/modernisation/swift6-final-build.log` (build log with 3 remaining errors)

### Code Changes:
- 11 Swift source files modified with concurrency annotations
- 1 project configuration file (SWIFT_VERSION = 6.0)

## Conclusion

P1-T12 successfully updated the Swift version to 6.0 and fixed 9 initial concurrency errors, but achieving a successful build requires more comprehensive concurrency work than originally scoped. 

**Recommendation**: Consider this task "partially complete" and either:
1. Schedule comprehensive Swift 6 concurrency migration as a dedicated phase
2. Revert to Swift 5.0 temporarily
3. Continue with incremental fixes (estimated 1-3 additional days)

The decision should be based on project priorities, timeline constraints, and risk tolerance for ongoing concurrency-related issues during Phase 1.
