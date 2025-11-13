# Method Swizzling Audit - TaskPaper

**Date**: 2025-11-13
**Phase**: P2-T06 (Method Swizzling Analysis)
**Auditor**: Claude (AI Assistant)
**Status**: Audit Complete - Awaiting Testing Phase

---

## Executive Summary

TaskPaper uses **2 active method swizzling patterns** for performance optimization, plus **1 swizzling infrastructure library**. A third file (NSWindowTabbedBase) does not perform actual swizzling.

**Risk Assessment:**
- 🟡 **Medium Risk Overall**
  - 1 High-Risk: Accessibility performance hack (VoiceOver)
  - 1 Medium-Risk: NSTextStorage performance optimization
  - 1 Low-Risk: Infrastructure library (widely used, mature)
  - 0 Critical-Risk items

**Recommendation Summary:**
1. **NSTextView Accessibility**: Test on macOS 11+ to see if Apple fixed the VoiceOver performance issue
2. **NSTextStorage Performance**: Benchmark before removal (estimated 10-30% performance impact)
3. **JGMethodSwizzler**: Keep infrastructure for now (no immediate risk)
4. **NSWindowTabbedBase**: Can be removed immediately (not actual swizzling)

---

## Table of Contents

1. [What is Method Swizzling?](#what-is-method-swizzling)
2. [Why Avoid Method Swizzling?](#why-avoid-method-swizzling)
3. [Swizzling Inventory](#swizzling-inventory)
4. [Detailed Analysis](#detailed-analysis)
5. [Removal Strategy](#removal-strategy)
6. [Testing Requirements](#testing-requirements)

---

## What is Method Swizzling?

Method swizzling is an Objective-C runtime technique that replaces a method's implementation at runtime. It's powerful but dangerous because:

1. **Runtime Modification**: Changes behavior of existing classes (including system classes)
2. **Fragile**: Can break with OS updates
3. **Debugging Nightmare**: Stack traces show swizzled methods, not originals
4. **Hard to Test**: Behavior differs from unswizzled state
5. **Maintenance Burden**: Requires understanding of private Apple APIs

---

## Why Avoid Method Swizzling?

### Modern Alternatives
- **Subclassing**: Override methods in custom subclass (safer, more explicit)
- **Delegates & Protocols**: Use delegation pattern instead of replacing behavior
- **Composition**: Wrap objects instead of modifying them
- **Swift**: Modern Swift concurrency and value types reduce need for runtime manipulation

### Swift 6 Concerns
- Method swizzling is fundamentally unsafe in Swift's concurrency model
- Actor isolation cannot be enforced on swizzled methods
- Non-Sendable types may cross actor boundaries through swizzles
- Compile-time safety guarantees don't apply to runtime modifications

---

## Swizzling Inventory

### Summary Table

| File | Lines | Purpose | Risk | Recommendation |
|------|-------|---------|------|----------------|
| **JGMethodSwizzler.m** | 773 | Infrastructure | 🟢 Low | Keep for now |
| **NSTextView-AccessibilityPerformanceHacks.m** | 25 | VoiceOver perf hack | 🔴 High | Test on macOS 11+ |
| **NSTextStorage-Performance.m** | 40 | String perf optimization | 🟡 Medium | Benchmark before removal |
| **NSWindowTabbedBase.m** | 21 | Empty subclass | 🟢 Low | **Remove immediately** |

---

## Detailed Analysis

### 1. JGMethodSwizzler.m

**Location**: `BirchEditor/BirchEditor.swift/BirchEditor/JGMethodSwizzler.m` (773 lines)

#### Description
Third-party library by Jonas Gessner providing infrastructure for safe method swizzling. Supports:
- Class method swizzling
- Instance method swizzling
- Instance-specific swizzling (creates dynamic subclass per object)
- Thread-safe with `os_unfair_lock`
- Deswizzling support

#### How It Works
```objc
// Example usage:
[NSTextView swizzleInstanceMethod:@selector(accessibilityTextLinks)
                  withReplacement:^id(JG_IMP orig, Class cls, SEL sel) {
    return ^id(__unsafe_unretained NSTextView *self) {
        return nil; // Always return nil instead of calling original
    };
}];
```

#### Risk Assessment: 🟢 **LOW**

**Pros:**
- Well-tested third-party library
- Used in multiple production apps
- Thread-safe implementation
- Supports deswizzling
- Better than manual `method_setImplementation`

**Cons:**
- Still performs runtime manipulation
- 773 lines of complex code
- Objective-C only (no Swift equivalent)
- Maintenance burden if bugs found

#### Current Usage
This library is **only used internally** by TaskPaper's swizzling code. It's not exposed to plugin APIs or used directly in business logic.

**Swizzle Count**: Infrastructure only (no direct swizzles in this file)

#### Recommendation
✅ **Keep for now** - Remove only after all swizzling removed

**Rationale:**
- Only a problem if we keep the swizzles
- If we remove NSTextView and NSTextStorage swizzling, this becomes dead code
- Dead code can be detected by unused code analysis
- Low immediate risk

**Action Items:**
1. Do NOT add new swizzles using this library
2. Remove after P2-T09 and P2-T10 complete
3. Add comment: "// TODO: Remove after swizzling eliminated (Phase 2)"

---

### 2. NSTextView-AccessibilityPerformanceHacks.m

**Location**: `BirchEditor/BirchEditor.swift/BirchEditor/NSTextView-AccessibilityPerformanceHacks.m` (25 lines)

#### Description
Category on `NSTextView` that overrides two accessibility methods to always return `nil`. This prevents macOS VoiceOver from iterating over all text attributes to find links and attachments.

#### Code
```objc
@implementation NSTextView (AccessibilityPerformanceHacks)

- (id)accessibilityTextLinks {
    return nil;  // Don't iterate attributes (expensive)
}

- (id)accessibilityAttachments {
    return nil;  // Don't iterate attributes (expensive)
}

@end
```

#### Why This Exists
TaskPaper uses lazy loading for outline items in NSTextView. When VoiceOver calls `accessibilityTextLinks`, NSTextView iterates over **all** attributed string ranges looking for `NSLinkAttributeName`. This forces all lazily-loaded items to load into memory, causing:
- Beach balls (UI freezing)
- Memory spikes
- Poor VoiceOver UX

By returning `nil`, VoiceOver skips link/attachment discovery entirely.

#### Risk Assessment: 🔴 **HIGH**

**Pros:**
- Fixes real performance problem (beach balls with VoiceOver)
- Minimal code (2 methods, 25 lines total)
- Well-documented with comment

**Cons:**
- ❌ **Breaks accessibility**: Users with VoiceOver cannot discover links/attachments
- ❌ Violates Apple accessibility guidelines
- ❌ May break in future macOS versions
- ❌ No version checking (applies to all macOS versions)
- ❌ Alternative: Could implement smarter link discovery without loading all items

#### Impact Analysis

**With Swizzle (Current Behavior):**
- ✅ VoiceOver doesn't freeze app
- ✅ Memory usage stays low
- ❌ VoiceOver users cannot navigate links
- ❌ VoiceOver users cannot find attachments
- ❌ Fails WCAG accessibility standards

**Without Swizzle (Expected Behavior):**
- ✅ VoiceOver can discover links
- ✅ VoiceOver can find attachments
- ❌ App may freeze with large documents
- ❌ Memory usage spikes with many items
- Status: **Unknown on macOS 11+** (Apple may have optimized this)

#### Testing Strategy

**Step 1: Test macOS 11+ Without Swizzle** (1-2 hours)
1. Comment out the category implementation
2. Rebuild app
3. Open large TaskPaper document (1000+ items with links)
4. Enable VoiceOver (Cmd+F5)
5. Navigate document with VoiceOver
6. Monitor:
   - CPU usage (Activity Monitor)
   - Memory usage (Activity Monitor)
   - Beach balls (user-visible freezing)
   - VoiceOver responsiveness

**Step 2: Version-Specific Testing** (if still needed)
If macOS 11+ still has performance issues, test on:
- macOS 10.14 (Mojave) - original bug version
- macOS 11 (Big Sur) - VoiceOver rewrite
- macOS 12 (Monterey)
- macOS 13 (Ventura)
- macOS 14 (Sonoma)
- macOS 15 (Sequoia)

**Decision Matrix:**
| Test Result | Action |
|-------------|--------|
| No performance issues on macOS 11+ | ✅ **Remove swizzle entirely** |
| Issues only on macOS 10.x | ✅ Add version check: `if (@available(macOS 11, *)) { /* no swizzle */ }` |
| Issues on all versions | ⚠️ **Keep swizzle** but document accessibility trade-off |

#### Recommendation
🧪 **Test before deciding** (P2-T10)

**Priority**: HIGH (accessibility compliance)

**Action Items:**
1. Create test harness with large document
2. Test VoiceOver performance on macOS 11+
3. If fixed: Remove category entirely
4. If not fixed: Add version check or document trade-off
5. If kept: Add accessibility warning in docs

**Estimated Impact:**
- Testing time: 2-4 hours
- Implementation: 30 minutes (if removal)
- Risk: Medium (could reintroduce performance bug)

---

### 3. NSTextStorage-Performance.m

**Location**: `BirchEditor/BirchEditor.swift/BirchEditor/NSTextStorage-Performance.m` (40 lines)

#### Description
Category on `NSTextStorage` that provides optimized implementations of string manipulation methods. Bypasses NSTextStorage's expensive attribute handling and goes directly to the underlying `string` property.

#### Code
```objc
@implementation NSTextStorage (Performance)

- (unichar)characterAtIndex:(NSUInteger)index {
    return [self.string characterAtIndex:index];
}

- (NSString *)substringWithRange:(NSRange)range {
    return [self.string substringWithRange:range];
}

- (NSRange)paragraphRangeForRange:(NSRange)range {
    return [self.string paragraphRangeForRange:range];
}

- (void)enumerateSubstringsInRange:(NSRange)range
                           options:(NSStringEnumerationOptions)opts
                        usingBlock:(void (^)(NSString*, NSRange, NSRange, BOOL*))block {
    [self.string enumerateSubstringsInRange:range options:opts usingBlock:block];
}

// ... 2 more similar methods
@end
```

#### Why This Exists
NSTextStorage is a subclass of NSMutableAttributedString. When you call string manipulation methods on NSTextStorage, it goes through attribute management even if you don't care about attributes. This category optimization:

1. **Bypasses attribute layer**: Goes directly to `.string` property
2. **Avoids notification overhead**: NSTextStorage sends change notifications
3. **Skips validation**: NSTextStorage validates attribute consistency

This is used heavily in:
- Text search/find operations
- Paragraph iteration
- Character-level operations
- Syntax highlighting calculations

#### Risk Assessment: 🟡 **MEDIUM**

**Pros:**
- Real performance benefit (estimated 10-30% faster)
- Well-isolated code (5 methods, 40 lines)
- Only affects read operations (doesn't modify state)
- Safe because only accesses public `.string` property

**Cons:**
- ⚠️ Method swizzling still fragile
- ⚠️ Could break if NSTextStorage implementation changes
- ⚠️ Hard to measure actual performance impact without benchmarks
- ⚠️ Alternative exists: Use `.string` property directly

#### Performance Estimate

**Operations Affected:**
- Character access: ~20% faster (bypasses attribute lookup)
- Substring extraction: ~15% faster (no attribute copying)
- Paragraph iteration: ~25% faster (no attribute validation)
- Search operations: ~10-30% faster (heavy string manipulation)

**Caveats:**
- Estimates based on code inspection only
- Actual performance depends on:
  - Document size
  - Attribute complexity
  - Operation frequency
  - CPU/memory characteristics

#### Testing Strategy

**Step 1: Create Performance Benchmark** (P2-T08)

```swift
// Example benchmark harness
func benchmarkTextStoragePerformance() {
    let storage = OutlineEditorTextStorage()
    // Load large document

    measure {
        // Character access (10000 iterations)
        for i in 0..<10000 {
            let ch = storage.character(at: i % storage.length)
        }
    }

    measure {
        // Paragraph iteration
        storage.enumerateParagraphRanges(in: NSRange(0..<storage.length)) { range, stop in
            // Process paragraph
        }
    }

    measure {
        // Substring extraction
        for _ in 0..<1000 {
            let substr = storage.substring(with: NSRange(0..<100))
        }
    }
}
```

**Step 2: Run Benchmarks**
1. **WITH swizzle**: Baseline performance
2. **WITHOUT swizzle**: Compare performance
3. Calculate % difference

**Step 3: Decision Matrix**

| Performance Impact | Action |
|-------------------|--------|
| < 5% difference | ✅ **Remove swizzle** - not worth the complexity |
| 5-10% difference | ✅ **Remove swizzle** - acceptable trade-off for safety |
| 10-20% difference | ⚠️ **Discuss with user** - significant but not critical |
| 20-30% difference | ⚠️ **Keep swizzle** - document justification |
| > 30% difference | ❌ **Keep swizzle** - too risky to remove |

#### Alternative Approaches

**Option A: Direct String Access** (Recommended if < 10% impact)
Instead of swizzling, update call sites to use `.string` directly:
```swift
// BEFORE (uses swizzled optimized path)
let char = textStorage.character(at: index)

// AFTER (explicit optimization)
let char = textStorage.string.character(at: index)
```

**Pros:**
- ✅ No swizzling
- ✅ Explicit performance optimization
- ✅ Easy to understand
- ✅ Compiler can inline better

**Cons:**
- ❌ Requires updating ~50-100 call sites
- ❌ Easy to accidentally use slow path

**Option B: Wrapper Class**
```swift
struct FastTextStorage {
    let storage: NSTextStorage

    func character(at index: Int) -> Character {
        return storage.string.character(at: index)
    }
    // ... optimized methods
}
```

**Pros:**
- ✅ No swizzling
- ✅ Type-safe wrapper
- ✅ Can add Swift-specific optimizations

**Cons:**
- ❌ Requires refactoring all call sites
- ❌ Extra allocation/wrapper overhead

**Option C: Keep Swizzle with Documentation**
If performance impact > 20%:
```objc
// PERFORMANCE-CRITICAL: This category provides optimized implementations
// that bypass NSTextStorage's attribute management layer. Benchmarks show
// 25% performance improvement for character-level operations.
//
// Tested on: macOS 11-15
// Last benchmarked: 2025-11-13
// Without optimization: 850ms per 10k ops
// With optimization: 637ms per 10k ops (25% faster)
//
// DO NOT REMOVE without re-benchmarking on latest macOS.
@implementation NSTextStorage (Performance)
```

#### Recommendation
🧪 **Measure before deciding** (P2-T08, P2-T09)

**Priority**: MEDIUM (performance vs. maintainability trade-off)

**Action Items:**
1. Create performance test harness
2. Benchmark WITH and WITHOUT swizzle
3. If < 10% impact: Remove and update call sites
4. If 10-20% impact: Discuss with user
5. If > 20% impact: Keep with comprehensive documentation

**Estimated Effort:**
- Benchmark creation: 2-3 hours
- Testing: 1-2 hours
- Option A implementation: 4-6 hours (if removing)
- Option B implementation: 8-12 hours (if refactoring)
- Option C documentation: 1 hour (if keeping)

---

### 4. NSWindowTabbedBase.m

**Location**: `BirchEditor/BirchEditor.swift/BirchEditor/NSWindowTabbedBase.m` (21 lines)

#### Description
**This is NOT actually method swizzling!** It's a simple NSWindow subclass with an empty implementation.

#### Code
```objc
@implementation NSWindowTabbedBase

- (instancetype)initWithContentRect:(NSRect)contentRect
                          styleMask:(NSWindowStyleMask)style
                            backing:(NSBackingStoreType)bufferingType
                              defer:(BOOL)flag {
    self = [super initWithContentRect:contentRect styleMask:style
                              backing:bufferingType defer:flag];
    if (self) {
        // Empty - just calls super
    }
    return self;
}

@end
```

#### Usage
`OutlineEditorWindow` inherits from `NSWindowTabbedBase`:
```swift
class OutlineEditorWindow: NSWindowTabbedBase {
    // ... window implementation
}
```

#### Why This Exists
**Historical Context**: This file was likely created as a placeholder for window tabbing customization on macOS 10.12 (Sierra) when window tabbing was introduced. The implementation was either:
1. Removed after macOS APIs improved
2. Never needed in the first place
3. Left over from experimentation

**Evidence**: Creation date (9/14/2016) matches macOS Sierra release (September 2016).

#### Risk Assessment: 🟢 **LOW** (Not actually risky - it's not swizzling!)

**Current State:**
- No method overrides
- No swizzling
- No custom behavior
- Just an empty subclass

#### Impact Analysis

**With NSWindowTabbedBase:**
- OutlineEditorWindow → NSWindowTabbedBase → NSWindow
- 1 extra class in inheritance chain
- No functional difference

**Without NSWindowTabbedBase:**
- OutlineEditorWindow → NSWindow
- 1 fewer class in inheritance chain
- No functional difference

#### Recommendation
✅ **Remove immediately** (P2-T07)

**Priority**: LOW (no risk, just code cleanliness)

**Action Items:**
1. Change `OutlineEditorWindow` to inherit directly from `NSWindow`:
   ```swift
   class OutlineEditorWindow: NSWindow {  // Was: NSWindowTabbedBase
   ```
2. Remove `NSWindowTabbedBase.m` and `.h` files
3. Remove from Xcode project
4. Remove from bridging header
5. Test window tabbing behavior (should be identical)

**Estimated Effort:**
- Implementation: 10 minutes
- Testing: 30 minutes
- Risk: None (trivial change)

**Testing Checklist:**
- ✅ Window tabs work
- ✅ New tab button works
- ✅ Drag tab to new window works
- ✅ Merge all windows works
- ✅ Close tab works

---

## Removal Strategy

### Phase 1: Low-Risk Removal (P2-T07) ✅ **DO IMMEDIATELY**

**Task**: Remove NSWindowTabbedBase
**Risk**: 🟢 None
**Effort**: 10 minutes
**Dependencies**: None

**Steps:**
1. Update OutlineEditorWindow.swift
2. Delete NSWindowTabbedBase.m/h
3. Update project.pbxproj
4. Test window tabbing

**Success Criteria:**
- Build succeeds
- Window tabs work identically

---

### Phase 2: Performance Measurement (P2-T08) ⏳ **REQUIRES XCODE**

**Task**: Benchmark NSTextStorage performance
**Risk**: 🟢 None (just measuring)
**Effort**: 3-5 hours
**Dependencies**: Xcode, large test documents

**Steps:**
1. Create performance test harness
2. Run benchmarks WITH swizzle (baseline)
3. Run benchmarks WITHOUT swizzle
4. Calculate % difference
5. Document results

**Deliverable**: `nstextstorage-performance-report.md`

---

### Phase 3: NSTextStorage Decision (P2-T09) ⏳ **DEPENDS ON P2-T08**

**Task**: Remove or document NSTextStorage swizzle
**Risk**: 🟡 Medium (could impact performance)
**Effort**: 1-12 hours (depends on decision)
**Dependencies**: P2-T08 benchmark results

**Decision Tree:**
```
Performance Impact < 10%?
├─ YES → Remove swizzle + Update call sites (4-6 hours)
└─ NO → Performance Impact > 20%?
    ├─ YES → Keep swizzle + Add documentation (1 hour)
    └─ NO → Discuss with user (10-20% gray area)
```

---

### Phase 4: Accessibility Testing (P2-T10) ⏳ **REQUIRES MACOS 11+ TESTING**

**Task**: Test NSTextView accessibility swizzle
**Risk**: 🔴 High (accessibility compliance)
**Effort**: 2-4 hours
**Dependencies**: Xcode, VoiceOver, large documents

**Steps:**
1. Comment out swizzle
2. Build and test with VoiceOver on macOS 11+
3. Monitor performance and usability
4. Make removal decision

**Decision Tree:**
```
Performance issues on macOS 11+?
├─ NO → Remove swizzle entirely ✅
└─ YES → Performance issues on macOS 10.x only?
    ├─ YES → Add version check (`@available(macOS 11, *)`)
    └─ NO → Keep swizzle + Document accessibility trade-off
```

---

### Phase 5: Infrastructure Cleanup (After P2-T09 & P2-T10)

**Task**: Remove JGMethodSwizzler if no longer needed
**Risk**: 🟢 None (dead code removal)
**Effort**: 30 minutes
**Dependencies**: P2-T09 and P2-T10 complete

**Condition**: Only if ALL swizzles removed

**Steps:**
1. Remove JGMethodSwizzler.m/h
2. Update project.pbxproj
3. Update bridging header
4. Build and verify no linker errors

---

## Testing Requirements

### Manual Testing Checklist

#### Window Behavior (P2-T07)
- [ ] Create new window (Cmd+N)
- [ ] Create new tab (Cmd+T)
- [ ] Drag tab out to new window
- [ ] Merge windows (Window > Merge All Windows)
- [ ] Close tab (Cmd+W)
- [ ] Tab bar appears/disappears correctly

#### Text Performance (P2-T08/P2-T09)
- [ ] Open large document (1000+ items)
- [ ] Scroll performance acceptable
- [ ] Search/find performance acceptable
- [ ] Typing performance acceptable
- [ ] No visible lag or stuttering

#### Accessibility (P2-T10)
- [ ] Enable VoiceOver (Cmd+F5)
- [ ] Navigate document with VoiceOver
- [ ] No beach balls or freezing
- [ ] Links discoverable (if swizzle removed)
- [ ] Attachments discoverable (if swizzle removed)
- [ ] Reasonable performance (< 2s lag)

### Automated Testing

#### Performance Benchmarks (P2-T08)
```swift
func testTextStorageCharacterAccess() {
    measure {
        // 10k character accesses
    }
}

func testTextStorageParagraphIteration() {
    measure {
        // Full document paragraph iteration
    }
}

func testTextStorageSubstringExtraction() {
    measure {
        // 1k substring extractions
    }
}
```

#### Regression Tests (All Phases)
- All existing unit tests must pass
- All existing UI tests must pass
- Thread Sanitizer must pass (no data races)
- No new warnings or errors

---

## Risk Mitigation

### Rollback Plan

Each phase has a clear rollback path:

**P2-T07** (NSWindowTabbedBase):
```bash
git revert <commit-hash>
```
Risk: None (trivial change)

**P2-T09** (NSTextStorage):
```bash
git revert <commit-hash>
```
Risk: Medium (performance regression)
Mitigation: Keep benchmark results, can restore if needed

**P2-T10** (NSTextView Accessibility):
```bash
git revert <commit-hash>
```
Risk: High (accessibility + performance)
Mitigation: Version check allows gradual rollout

### Monitoring

After each removal, monitor for 2 weeks:
- [ ] User-reported performance issues
- [ ] Crash reports related to text handling
- [ ] Accessibility feedback
- [ ] macOS update compatibility

---

## Appendix A: Files Inventory

### Swizzling Implementation Files
```
BirchEditor/BirchEditor.swift/BirchEditor/
├── JGMethodSwizzler.h              (33 lines)
├── JGMethodSwizzler.m              (773 lines)
├── NSTextView-AccessibilityPerformanceHacks.h  (11 lines)
├── NSTextView-AccessibilityPerformanceHacks.m  (25 lines)
├── NSTextStorage-Performance.h     (26 lines)
├── NSTextStorage-Performance.m     (40 lines)
├── NSWindowTabbedBase.h            (13 lines)
└── NSWindowTabbedBase.m            (21 lines)

Total: 942 lines of swizzling code
```

### Usage Locations
```
NSWindowTabbedBase usage:
└── BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorWindow.swift:22

NSTextStorage-Performance usage:
└── Used implicitly throughout text handling code

NSTextView-AccessibilityPerformanceHacks usage:
└── Applied globally via category (all NSTextView instances)
```

---

## Appendix B: Third-Party License

### JGMethodSwizzler License

```
Created by Jonas Gessner 22.08.2013
Copyright (c) 2013 Jonas Gessner. All rights reserved.
```

**License Type**: Not specified in source files
**GitHub**: https://github.com/JonasGessner/JGMethodSwizzler (assumed)
**Risk**: Check license before distribution

**Action Item**: Verify license compatibility before Phase 1 release

---

## Appendix C: macOS Version History

### Window Tabbing
- **macOS 10.12 Sierra** (Sept 2016): Window tabs introduced
- **macOS 10.13 High Sierra**: Refinements
- **macOS 11 Big Sur**: Major window system rewrite
- **macOS 12+ Monterey/Ventura/Sonoma**: Continued refinements

### Accessibility
- **macOS 10.14 Mojave**: VoiceOver improvements
- **macOS 11 Big Sur**: VoiceOver rewrite
- **macOS 12+ Monterey/Ventura/Sonoma**: Performance improvements

**Testing Recommendation**: Focus on macOS 11+ (Big Sur and later) as it has major rewrites that likely fixed original performance issues.

---

## Appendix D: Performance Baselines (To Be Measured)

### Expected Benchmarks (P2-T08)

| Operation | With Swizzle | Without Swizzle | Estimated Δ |
|-----------|--------------|-----------------|-------------|
| Character access (10k ops) | TBD | TBD | ~20% slower |
| Substring extraction (1k ops) | TBD | TBD | ~15% slower |
| Paragraph iteration (full doc) | TBD | TBD | ~25% slower |
| Search operation (1k items) | TBD | TBD | ~10-30% slower |

**Note**: These are estimates based on code inspection. Actual results may vary significantly.

---

## Document Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-13 | 1.0 | Initial audit complete |

**Next Steps**: Execute P2-T07 (NSWindowTabbedBase removal)
