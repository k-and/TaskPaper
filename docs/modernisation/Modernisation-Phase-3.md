# Phase 3: UI Modernization (3-6 months)

## Phase Overview

Phase 3 focuses on modernizing the user interface layer by gradually introducing SwiftUI for appropriate components, migrating to Apple's modern text system (TextKit 2), and adding contemporary macOS features that enhance user experience. This phase adopts an incremental approach to UI modernization, starting with simpler UI components (preferences, palettes, search) before considering the complex editor view, migrating the custom NSTextView-based editor to TextKit 2 for improved performance and reduced custom code, and implementing modern macOS features like Touch Bar support and enhanced system integration. The objectives are to reduce reliance on legacy AppKit patterns by introducing SwiftUI where beneficial, improve text rendering performance and maintainability through TextKit 2, enhance user experience with native macOS features, and maintain stability by preserving the editor's core functionality during migration. Expected outcomes include hybrid AppKit/SwiftUI architecture with clear boundaries, significantly reduced custom text system code through TextKit 2 adoption, improved performance in text rendering and layout, and enhanced platform integration with native macOS features.

---

## P3-T01: Audit UI Components for SwiftUI Migration Candidates

**Component**: UI Architecture Planning  
**Files**:
- All view controllers in `BirchEditor/BirchEditor.swift/BirchEditor/`
- All .storyboard and .xib files
- `TaskPaper/` UI files

**Technical Changes**:
1. List all view controllers: `grep -r "NSViewController" --include="*.swift" BirchEditor/`
2. List all custom views: `grep -r "NSView" --include="*.swift" BirchEditor/`
3. Categorize each UI component by migration priority:
   - **High priority (simple, stateless)**: Preferences, alerts, simple dialogs
   - **Medium priority (moderate complexity)**: Palettes, sidebar, search bar
   - **Low priority (complex, AppKit-dependent)**: Main editor (OutlineEditorView)
4. For each candidate, assess:
   - Complexity (lines of code, dependencies)
   - AppKit dependencies (custom drawing, text system, etc.)
   - User-facing impact (how often used)
   - SwiftUI readiness (can it be done purely in SwiftUI?)
5. Create migration roadmap: `docs/modernisation/swiftui-migration-roadmap.md`
6. Document components that should REMAIN in AppKit (editor core)

**Prerequisites**: None

**Success Criteria**:
```bash
test -f docs/modernisation/swiftui-migration-roadmap.md
grep -q "High priority" docs/modernisation/swiftui-migration-roadmap.md
grep -q "OutlineEditorView" docs/modernisation/swiftui-migration-roadmap.md
grep -q "REMAIN in AppKit" docs/modernisation/swiftui-migration-roadmap.md
```

---

## P3-T02: Create SwiftUI Integration Infrastructure

**Component**: UI Framework  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/SwiftUI/SwiftUIIntegration.swift` (new)

**Technical Changes**:
1. Create `SwiftUI/` directory in BirchEditor module
2. Create helper for embedding SwiftUI in AppKit:
   ```swift
   import SwiftUI
   import AppKit
   
   extension NSViewController {
       func embedSwiftUIView<Content: View>(_ swiftUIView: Content) -> NSView {
           let hostingController = NSHostingController(rootView: swiftUIView)
           addChild(hostingController)
           return hostingController.view
       }
   }
   ```
3. Create helper for embedding AppKit in SwiftUI:
   ```swift
   struct AppKitViewWrapper<T: NSView>: NSViewRepresentable {
       let makeView: () -> T
       let updateView: (T) -> Void
       
       func makeNSView(context: Context) -> T {
           makeView()
       }
       
       func updateNSView(_ nsView: T, context: Context) {
           updateView(nsView)
       }
   }
   ```
4. Document integration patterns and best practices
5. Add unit tests for hosting controller lifecycle

**Prerequisites**: None

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditor/SwiftUI/SwiftUIIntegration.swift
grep -q "NSHostingController" BirchEditor/BirchEditor.swift/BirchEditor/SwiftUI/SwiftUIIntegration.swift
grep -q "NSViewRepresentable" BirchEditor/BirchEditor.swift/BirchEditor/SwiftUI/SwiftUIIntegration.swift
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor build | grep -q "BUILD SUCCEEDED"
```

---

## P3-T03: Migrate Preferences Window to SwiftUI

**Component**: Preferences UI  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/PreferencesWindowController.swift`
- `BirchEditor/BirchEditor.swift/BirchEditor/SwiftUI/PreferencesView.swift` (new)
- Related .xib files

**Technical Changes**:
1. Analyze current preferences implementation (likely .xib-based)
2. Create `PreferencesView.swift` SwiftUI view:
   ```swift
   struct PreferencesView: View {
       @AppStorage("fontSize") private var fontSize: Double = 14.0
       @AppStorage("theme") private var theme: String = "light"
       
       var body: some View {
           Form {
               Section("Appearance") {
                   Slider(value: $fontSize, in: 10...24) {
                       Text("Font Size: \(Int(fontSize))")
                   }
                   Picker("Theme", selection: $theme) {
                       Text("Light").tag("light")
                       Text("Dark").tag("dark")
                   }
               }
               // Additional preference sections
           }
           .formStyle(.grouped)
           .frame(width: 450, height: 300)
       }
   }
   ```
3. Update PreferencesWindowController to host SwiftUI view:
   ```swift
   class PreferencesWindowController: NSWindowController {
       override func windowDidLoad() {
           super.windowDidLoad()
           let preferencesView = PreferencesView()
           let hostingController = NSHostingController(rootView: preferencesView)
           window?.contentViewController = hostingController
       }
   }
   ```
4. Migrate all existing preference settings to @AppStorage or ObservableObject
5. Test all preference changes persist correctly
6. Remove old .xib file after migration verified

**Prerequisites**: P3-T02

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditor/SwiftUI/PreferencesView.swift
grep -q "struct PreferencesView: View" BirchEditor/BirchEditor.swift/BirchEditor/SwiftUI/PreferencesView.swift
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct build | grep -q "BUILD SUCCEEDED"
echo "Manual test: Open preferences and verify all settings work"
```

---

## P3-T04: Migrate Choice Palette to SwiftUI

**Component**: Palette UI  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/ChoicePaletteViewController.swift`
- `BirchEditor/BirchEditor.swift/BirchEditor/SwiftUI/ChoicePaletteView.swift` (new)

**Technical Changes**:
1. Analyze current ChoicePaletteViewController (command palette-style picker)
2. Create SwiftUI equivalent with search and filtering:
   ```swift
   struct ChoicePaletteView: View {
       @State private var searchText = ""
       let choices: [PaletteChoice]
       let onSelect: (PaletteChoice) -> Void
       
       var filteredChoices: [PaletteChoice] {
           if searchText.isEmpty {
               return choices
           }
           return choices.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
       }
       
       var body: some View {
           VStack(spacing: 0) {
               TextField("Search", text: $searchText)
                   .textFieldStyle(.roundedBorder)
                   .padding()
               
               List(filteredChoices) { choice in
                   Button(action: { onSelect(choice) }) {
                       HStack {
                           Text(choice.title)
                           Spacer()
                           if let shortcut = choice.keyboardShortcut {
                               Text(shortcut)
                                   .foregroundColor(.secondary)
                           }
                       }
                   }
               }
           }
           .frame(width: 400, height: 300)
       }
   }
   ```
3. Update ChoicePaletteViewController to host SwiftUI view
4. Maintain keyboard navigation behavior (arrow keys, return to select)
5. Preserve NSPanel floating behavior
6. Test all palette invocation scenarios

**Prerequisites**: P3-T02

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditor/SwiftUI/ChoicePaletteView.swift
grep -q "struct ChoicePaletteView: View" BirchEditor/BirchEditor.swift/BirchEditor/SwiftUI/ChoicePaletteView.swift
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct build | grep -q "BUILD SUCCEEDED"
echo "Manual test: Invoke choice palette (likely Cmd+Shift+P) and verify functionality"
```

---

## P3-T05: Migrate Date Picker to SwiftUI

**Component**: Palette UI  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/DatePickerViewController.swift`
- `BirchEditor/BirchEditor.swift/BirchEditor/SwiftUI/DatePickerPaletteView.swift` (new)

**Technical Changes**:
1. Analyze current DatePickerViewController (used for @date tag insertion)
2. Create SwiftUI date picker:
   ```swift
   struct DatePickerPaletteView: View {
       @State private var selectedDate = Date()
       let onDateSelected: (Date) -> Void
       let onCancel: () -> Void
       
       var body: some View {
           VStack {
               DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                   .datePickerStyle(.graphical)
               
               HStack {
                   Button("Cancel", action: onCancel)
                   Spacer()
                   Button("Insert") {
                       onDateSelected(selectedDate)
                   }
                   .keyboardShortcut(.return)
               }
               .padding()
           }
           .frame(width: 320, height: 380)
       }
   }
   ```
3. Integrate with outline editor to insert @date(value) tags
4. Update DatePickerViewController to host SwiftUI view
5. Preserve keyboard shortcuts for date manipulation
6. Test date formatting matches TaskPaper expectations

**Prerequisites**: P3-T02

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditor/SwiftUI/DatePickerPaletteView.swift
grep -q "DatePicker" BirchEditor/BirchEditor.swift/BirchEditor/SwiftUI/DatePickerPaletteView.swift
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct build | grep -q "BUILD SUCCEEDED"
echo "Manual test: Insert date tag and verify correct format"
```

---

## P3-T06: Audit TextKit 2 Migration Requirements

**Component**: Text System Planning  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorTextStorage.swift`
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorLayoutManager.swift`
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorTextContainer.swift`
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorView.swift`

**Technical Changes**:
1. Document current TextKit 1 architecture:
   - NSTextStorage customizations (bidirectional JS sync)
   - NSLayoutManager customizations (handle rendering, guide lines)
   - NSTextContainer customizations (outline layout)
   - NSTextView customizations (outline-specific editing)
2. Research TextKit 2 equivalents:
   - NSTextLayoutManager replaces NSLayoutManager
   - NSTextContentStorage replaces NSTextStorage
   - NSTextViewportLayoutController for viewport management
3. Identify migration challenges:
   - JavaScript bridge synchronization
   - Custom layout for outline items
   - Handle (disclosure triangle) rendering
   - Guide line drawing
   - Attribute management
4. Create migration plan: `docs/modernisation/textkit2-migration-plan.md`
5. Assess risk and effort (high complexity)
6. Determine macOS version requirement (12.0+ for TextKit 2)

**Prerequisites**: None

**Success Criteria**:
```bash
test -f docs/modernisation/textkit2-migration-plan.md
grep -q "NSTextLayoutManager" docs/modernisation/textkit2-migration-plan.md
grep -q "NSTextContentStorage" docs/modernisation/textkit2-migration-plan.md
grep -q "risk" docs/modernisation/textkit2-migration-plan.md
```

---

## P3-T07: Update Minimum macOS Version to 12.0

**Component**: Build Configuration  
**Files**:
- `TaskPaper.xcodeproj/project.pbxproj`
- `README.md`

**Technical Changes**:
1. Update deployment target in Xcode project settings:
   - Change `MACOSX_DEPLOYMENT_TARGET` from `11.0` to `12.0` for all targets
2. Update Info.plist files:
   - Update `LSMinimumSystemVersion` to `12.0`
3. Update README.md to reflect new requirement:
   ```markdown
   ## Requirements
   - macOS 12.0 (Monterey) or later
   - Xcode 14+ for building from source
   ```
4. Verify all build configurations (Direct, AppStore, Setapp)
5. Test on macOS 12.0 virtual machine or device
6. Document reason for version bump (TextKit 2 adoption)
7. Consider user communication strategy (release notes)

**Prerequisites**: P3-T06 (decision made to adopt TextKit 2)

**Success Criteria**:
```bash
grep -q "MACOSX_DEPLOYMENT_TARGET = 12.0" TaskPaper.xcodeproj/project.pbxproj
grep -q "macOS 12" README.md
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct -configuration Debug build | grep -q "BUILD SUCCEEDED"
```

---

## P3-T08: Create TextKit 2 Content Storage Subclass

**Component**: Text System  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineTextContentStorage.swift` (new)

**Technical Changes**:
1. Create new NSTextContentStorage subclass:
   ```swift
   import AppKit
   
   @available(macOS 12.0, *)
   final class OutlineTextContentStorage: NSTextContentStorage {
       weak var outlineEditor: OutlineEditorProtocol?
       private var isUpdatingFromJS = false
       
       // Override to sync with JavaScript model
       override func performEditingTransaction(using transaction: () -> Void) {
           if !isUpdatingFromJS {
               // Update JavaScript before applying edit
               transaction()
               notifyJavaScriptOfChange()
           } else {
               transaction()
           }
       }
       
       private func notifyJavaScriptOfChange() {
           guard let editor = outlineEditor else { return }
           // Sync content to JavaScript model
           // Similar logic to OutlineEditorTextStorage bidirectional sync
       }
   }
   ```
2. Implement text content synchronization with JavaScript
3. Preserve outline item attributes during editing
4. Ensure thread-safety with @MainActor
5. Add comprehensive documentation for sync mechanism

**Prerequisites**: P3-T07

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditor/OutlineTextContentStorage.swift
grep -q "class OutlineTextContentStorage: NSTextContentStorage" BirchEditor/BirchEditor.swift/BirchEditor/OutlineTextContentStorage.swift
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor -configuration Debug build | grep -q "BUILD SUCCEEDED"
```

---

## P3-T09: Create TextKit 2 Layout Manager Delegate

**Component**: Text System  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineTextLayoutManagerDelegate.swift` (new)

**Technical Changes**:
1. Create NSTextLayoutManagerDelegate implementation:
   ```swift
   @available(macOS 12.0, *)
   final class OutlineTextLayoutManagerDelegate: NSObject, NSTextLayoutManagerDelegate {
       weak var outlineEditor: OutlineEditorProtocol?
       
       // Handle custom layout for outline items
       func textLayoutManager(
           _ textLayoutManager: NSTextLayoutManager,
           textLayoutFragmentFor location: NSTextLocation,
           in textElement: NSTextElement
       ) -> NSTextLayoutFragment {
           // Create custom layout fragment for outline item
           // Include space for handle (disclosure triangle)
           // Apply indentation based on outline level
           let layoutFragment = OutlineTextLayoutFragment(textElement: textElement, range: textElement.elementRange)
           return layoutFragment
       }
   }
   ```
2. Implement custom text layout fragment for outline items
3. Handle disclosure triangle rendering
4. Implement guide line drawing
5. Apply indentation based on outline hierarchy
6. Optimize layout for large documents

**Prerequisites**: P3-T08

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditor/OutlineTextLayoutManagerDelegate.swift
grep -q "NSTextLayoutManagerDelegate" BirchEditor/BirchEditor.swift/BirchEditor/OutlineTextLayoutManagerDelegate.swift
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor build | grep -q "BUILD SUCCEEDED"
```

---

## P3-T10: Create Custom NSTextLayoutFragment for Outline Items

**Component**: Text System  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineTextLayoutFragment.swift` (new)

**Technical Changes**:
1. Subclass NSTextLayoutFragment:
   ```swift
   @available(macOS 12.0, *)
   final class OutlineTextLayoutFragment: NSTextLayoutFragment {
       var outlineLevel: Int = 0
       var hasHandle: Bool = false
       var isExpanded: Bool = true
       
       override func draw(at point: CGPoint, in context: CGContext) {
           // Draw guide lines if needed
           drawGuideLines(at: point, in: context)
           
           // Draw disclosure triangle (handle)
           if hasHandle {
               drawHandle(at: point, in: context, expanded: isExpanded)
           }
           
           // Draw text content
           super.draw(at: point, in: context)
       }
       
       private func drawGuideLines(at point: CGPoint, in context: CGContext) {
           // Custom guide line rendering
           // Similar to current OutlineEditorLayoutManager implementation
       }
       
       private func drawHandle(at point: CGPoint, in context: CGContext, expanded: Bool) {
           // Draw disclosure triangle
           // Position based on indentation level
       }
   }
   ```
2. Implement guide line rendering logic
3. Implement handle (disclosure triangle) drawing
4. Calculate proper indentation based on outline level
5. Optimize drawing for performance

**Prerequisites**: P3-T09

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditor/OutlineTextLayoutFragment.swift
grep -q "class OutlineTextLayoutFragment: NSTextLayoutFragment" BirchEditor/BirchEditor.swift/BirchEditor/OutlineTextLayoutFragment.swift
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor build | grep -q "BUILD SUCCEEDED"
```

---

## P3-T11: Create TextKit 2-Based Text View

**Component**: Text System  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineTextView.swift` (new)

**Technical Changes**:
1. Create new NSTextView subclass using TextKit 2:
   ```swift
   @available(macOS 12.0, *)
   final class OutlineTextView: NSTextView {
       var outlineEditor: OutlineEditorProtocol?
       
       override init(frame: CGRect, textContainer: NSTextContainer?) {
           // Initialize with TextKit 2 stack
           super.init(frame: frame, textContainer: textContainer)
           configureTextKit2()
       }
       
       private func configureTextKit2() {
           // Set up NSTextLayoutManager
           // Set up OutlineTextContentStorage
           // Configure viewport layout controller
       }
       
       // Override editing methods for outline-specific behavior
       override func insertNewline(_ sender: Any?) {
           // Custom newline handling for outline items
       }
       
       override func deleteBackward(_ sender: Any?) {
           // Custom deletion behavior
       }
       
       // Handle disclosure triangle clicks
       override func mouseDown(with event: NSEvent) {
           let location = convert(event.locationInWindow, from: nil)
           if handleClickDetected(at: location) {
               toggleItemExpansion(at: location)
           } else {
               super.mouseDown(with: event)
           }
       }
   }
   ```
2. Port editing behaviors from OutlineEditorView
3. Implement handle click detection and item folding
4. Preserve keyboard shortcuts and commands
5. Ensure accessibility features work correctly

**Prerequisites**: P3-T08, P3-T09, P3-T10

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditor/OutlineTextView.swift
grep -q "class OutlineTextView: NSTextView" BirchEditor/BirchEditor.swift/BirchEditor/OutlineTextView.swift
grep -q "configureTextKit2" BirchEditor/BirchEditor.swift/BirchEditor/OutlineTextView.swift
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor build | grep -q "BUILD SUCCEEDED"
```

---

## P3-T12: Add TextKit Version Abstraction Layer

**Component**: Text System  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/TextKitVersionAdapter.swift` (new)

**Technical Changes**:
1. Create adapter to support both TextKit 1 and 2:
   ```swift
   enum TextKitVersion {
       case textKit1
       case textKit2
       
       static var preferred: TextKitVersion {
           if #available(macOS 12.0, *) {
               return .textKit2
           }
           return .textKit1
       }
   }
   
   final class TextKitVersionAdapter {
       static func createTextView(outlineEditor: OutlineEditorProtocol) -> NSTextView {
           switch TextKitVersion.preferred {
           case .textKit1:
               return OutlineEditorView(outlineEditor: outlineEditor) // Legacy
           case .textKit2:
               if #available(macOS 12.0, *) {
                   return OutlineTextView(outlineEditor: outlineEditor) // New
               }
               return OutlineEditorView(outlineEditor: outlineEditor)
           }
       }
   }
   ```
2. Allow runtime switching between TextKit versions for testing
3. Add user preference to force TextKit 1 (for fallback if issues arise)
4. Document migration path and feature parity
5. Ensure API compatibility across both versions

**Prerequisites**: P3-T11

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditor/TextKitVersionAdapter.swift
grep -q "enum TextKitVersion" BirchEditor/BirchEditor.swift/BirchEditor/TextKitVersionAdapter.swift
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor build | grep -q "BUILD SUCCEEDED"
```

---

## P3-T13: Update OutlineEditorViewController to Use TextKit 2

**Component**: View Controller  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorViewController.swift`

**Technical Changes**:
1. Update text view creation logic:
   ```swift
   open var outlineEditor: OutlineEditorProtocol? {
       didSet {
           if let outlineEditor = outlineEditor {
               // Use adapter to create appropriate text view version
               let textView = TextKitVersionAdapter.createTextView(outlineEditor: outlineEditor)
               self.outlineEditorView = textView
               
               // Configure scroll view and other UI elements
               configureTextViewContainer()
           }
       }
   }
   ```
2. Update any TextKit 1-specific code paths to be version-agnostic
3. Ensure scroll view and container view setup works with both versions
4. Preserve all view controller functionality
5. Test with both TextKit 1 (legacy) and TextKit 2 (new)

**Prerequisites**: P3-T12

**Success Criteria**:
```bash
grep -q "TextKitVersionAdapter" BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorViewController.swift
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct build | grep -q "BUILD SUCCEEDED"
echo "Manual test: Open document and verify editor works correctly"
```

---

## P3-T14: Test TextKit 2 Implementation with Sample Documents

**Component**: Integration Testing  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditorTests/TextKit2IntegrationTests.swift` (new)

**Technical Changes**:
1. Create comprehensive TextKit 2 integration tests:
   ```swift
   @available(macOS 12.0, *)
   final class TextKit2IntegrationTests: XCTestCase {
       func testLoadLargeDocument() throws {
           // Load 10,000 line document with TextKit 2
           // Measure load time and memory
       }
       
       func testOutlineItemRendering() throws {
           // Verify projects, tasks, notes render correctly
           // Check indentation and handles
       }
       
       func testHandleInteraction() throws {
           // Test disclosure triangle clicks
           // Verify expand/collapse behavior
       }
       
       func testGuideLineRendering() throws {
           // Verify guide lines draw correctly
       }
       
       func testTextEditing() throws {
           // Type text, verify outline updates
           // Test deletion, insertion, formatting
       }
       
       func testJavaScriptSync() throws {
           // Verify bidirectional TextKit 2 ↔ JS sync
       }
   }
   ```
2. Test with various document sizes (small, medium, large)
3. Test all outline item types (projects, tasks, tags, notes)
4. Verify performance meets or exceeds TextKit 1
5. Test edge cases (empty document, malformed input)

**Prerequisites**: P3-T13

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditorTests/TextKit2IntegrationTests.swift
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchEditor -only-testing:BirchEditorTests/TextKit2IntegrationTests | grep -q "Test Succeeded"
```

---

## P3-T15: Performance Benchmark TextKit 1 vs TextKit 2

**Component**: Performance Analysis  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditorTests/TextKitPerformanceTests.swift` (new)
- `docs/modernisation/textkit-performance-comparison.md` (new)

**Technical Changes**:
1. Create performance test suite:
   ```swift
   final class TextKitPerformanceTests: XCTestCase {
       func testTextKit1LoadTime() throws {
           measure {
               // Load large document with TextKit 1
           }
       }
       
       func testTextKit2LoadTime() throws {
           measure {
               // Load same document with TextKit 2
           }
       }
       
       func testTextKit1TypingPerformance() throws {
           measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
               // Simulate rapid typing with TextKit 1
           }
       }
       
       func testTextKit2TypingPerformance() throws {
           measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
               // Simulate rapid typing with TextKit 2
           }
       }
   }
   ```
2. Benchmark key operations:
   - Document loading (various sizes)
   - Typing performance
   - Scrolling large documents
   - Attribute application
   - Outline item folding/unfolding
3. Compare memory usage between versions
4. Document results in `textkit-performance-comparison.md`
5. Target: TextKit 2 should be 10-30% faster

**Prerequisites**: P3-T14

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditorTests/TextKitPerformanceTests.swift
test -f docs/modernisation/textkit-performance-comparison.md
grep -q "TextKit 1" docs/modernisation/textkit-performance-comparison.md
grep -q "TextKit 2" docs/modernisation/textkit-performance-comparison.md
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchEditor -only-testing:BirchEditorTests/TextKitPerformanceTests | grep -q "Test Succeeded"
```

---

## P3-T16: Add Touch Bar Support Infrastructure

**Component**: Modern macOS Features  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/TouchBar/TouchBarProvider.swift` (new)

**Technical Changes**:
1. Create Touch Bar support directory and base class:
   ```swift
   @available(macOS 10.12.2, *)
   extension NSTouchBarItem.Identifier {
       static let outlineFormatting = NSTouchBarItem.Identifier("com.taskpaper.formatting")
       static let outlineNavigation = NSTouchBarItem.Identifier("com.taskpaper.navigation")
       static let search = NSTouchBarItem.Identifier("com.taskpaper.search")
   }
   
   @MainActor
   final class TouchBarProvider: NSObject, NSTouchBarDelegate {
       weak var outlineEditor: OutlineEditorProtocol?
       
       func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
           switch identifier {
           case .outlineFormatting:
               return makeFormattingItem()
           case .outlineNavigation:
               return makeNavigationItem()
           case .search:
               return makeSearchItem()
           default:
               return nil
           }
       }
       
       private func makeFormattingItem() -> NSTouchBarItem {
           // Create buttons for quick formatting (task, project, tag)
       }
   }
   ```
2. Design Touch Bar layout appropriate for outlining
3. Ensure Touch Bar respects user preferences (can be disabled)
4. Add icons for Touch Bar buttons
5. Document Touch Bar interactions

**Prerequisites**: None

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditor/TouchBar/TouchBarProvider.swift
grep -q "NSTouchBarDelegate" BirchEditor/BirchEditor.swift/BirchEditor/TouchBar/TouchBarProvider.swift
xcodebuild -project TaskPaper.xcodeproj -scheme BirchEditor build | grep -q "BUILD SUCCEEDED"
```

---

## P3-T17: Implement Touch Bar Quick Formatting Actions

**Component**: Touch Bar Features  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/TouchBar/TouchBarFormattingItem.swift` (new)

**Technical Changes**:
1. Create formatting touch bar item:
   ```swift
   @available(macOS 10.12.2, *)
   extension TouchBarProvider {
       func makeFormattingItem() -> NSTouchBarItem {
           let item = NSCustomTouchBarItem(identifier: .outlineFormatting)
           
           let taskButton = NSButton(
               title: "Task",
               image: NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "Task")!,
               target: self,
               action: #selector(makeTask)
           )
           
           let projectButton = NSButton(
               title: "Project",
               image: NSImage(systemSymbolName: "folder", accessibilityDescription: "Project")!,
               target: self,
               action: #selector(makeProject)
           )
           
           let tagButton = NSButton(
               title: "Tag",
               image: NSImage(systemSymbolName: "number", accessibilityDescription: "Tag")!,
               target: self,
               action: #selector(insertTag)
           )
           
           let stackView = NSStackView(views: [taskButton, projectButton, tagButton])
           item.view = stackView
           return item
       }
       
       @objc private func makeTask() {
           outlineEditor?.convertSelectionTo(type: .task)
       }
       
       @objc private func makeProject() {
           outlineEditor?.convertSelectionTo(type: .project)
       }
       
       @objc private func insertTag() {
           outlineEditor?.showTagPalette()
       }
   }
   ```
2. Connect actions to outline editor operations
3. Update button states based on current selection
4. Test on MacBook Pro with Touch Bar (or simulator)

**Prerequisites**: P3-T16

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditor/TouchBar/TouchBarFormattingItem.swift
grep -q "makeFormattingItem" BirchEditor/BirchEditor.swift/BirchEditor/TouchBar/TouchBarFormattingItem.swift
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct build | grep -q "BUILD SUCCEEDED"
echo "Manual test: Verify Touch Bar buttons work on compatible hardware"
```

---

## P3-T18: Implement Touch Bar Navigation Scrubber

**Component**: Touch Bar Features  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/TouchBar/TouchBarNavigationItem.swift` (new)

**Technical Changes**:
1. Create navigation scrubber for Touch Bar:
   ```swift
   @available(macOS 10.12.2, *)
   extension TouchBarProvider {
       func makeNavigationItem() -> NSTouchBarItem {
           let item = NSCustomTouchBarItem(identifier: .outlineNavigation)
           
           let scrubber = NSScrubber()
           scrubber.register(NSScrubberTextItemView.self, forItemIdentifier: NSUserInterfaceItemIdentifier("TextItem"))
           scrubber.mode = .free
           scrubber.selectionBackgroundStyle = .roundedBackground
           scrubber.delegate = self
           scrubber.dataSource = self
           
           item.view = scrubber
           return item
       }
   }
   
   extension TouchBarProvider: NSScrubberDelegate, NSScrubberDataSource {
       func numberOfItems(for scrubber: NSScrubber) -> Int {
           // Return number of top-level outline items
           return outlineEditor?.topLevelItems.count ?? 0
       }
       
       func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
           let itemView = scrubber.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("TextItem"), owner: nil) as! NSScrubberTextItemView
           itemView.textField.stringValue = outlineEditor?.topLevelItems[index].title ?? ""
           return itemView
       }
       
       func scrubber(_ scrubber: NSScrubber, didSelectItemAt selectedIndex: Int) {
           // Navigate to selected item
           outlineEditor?.scrollToItem(at: selectedIndex)
       }
   }
   ```
2. Show project names in scrubber for quick navigation
3. Update scrubber when outline structure changes
4. Test scrolling and selection behavior

**Prerequisites**: P3-T16

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditor/TouchBar/TouchBarNavigationItem.swift
grep -q "NSScrubber" BirchEditor/BirchEditor.swift/BirchEditor/TouchBar/TouchBarNavigationItem.swift
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct build | grep -q "BUILD SUCCEEDED"
echo "Manual test: Verify scrubber navigation works"
```

---

## P3-T19: Integrate Touch Bar with OutlineEditorViewController

**Component**: Touch Bar Integration  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorViewController.swift`

**Technical Changes**:
1. Add Touch Bar support to view controller:
   ```swift
   @available(macOS 10.12.2, *)
   extension OutlineEditorViewController {
       override func makeTouchBar() -> NSTouchBar? {
           let touchBar = NSTouchBar()
           touchBar.delegate = touchBarProvider
           touchBar.defaultItemIdentifiers = [
               .outlineFormatting,
               .outlineNavigation,
               .search,
               .otherItemsProxy
           ]
           return touchBar
       }
       
       private lazy var touchBarProvider: TouchBarProvider = {
           let provider = TouchBarProvider()
           provider.outlineEditor = self.outlineEditor
           return provider
       }()
   }
   ```
2. Update Touch Bar when editor state changes
3. Respect system Touch Bar customization preferences
4. Ensure Touch Bar updates don't impact performance
5. Test on both Touch Bar and non-Touch Bar Macs

**Prerequisites**: P3-T17, P3-T18

**Success Criteria**:
```bash
grep -q "makeTouchBar" BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorViewController.swift
grep -q "TouchBarProvider" BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorViewController.swift
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct build | grep -q "BUILD SUCCEEDED"
echo "Manual test: Open document and verify Touch Bar appears and functions"
```

---

## P3-T20: Add Continuity Features (Handoff Support)

**Component**: System Integration  
**Files**:
- `TaskPaper/TaskPaperDocument.swift`
- `TaskPaper/Info.plist`

**Technical Changes**:
1. Add Handoff support to Info.plist:
   ```xml
   <key>NSUserActivityTypes</key>
   <array>
       <string>com.hogbaysoftware.taskpaper.editing</string>
   </array>
   ```
2. Implement user activity in document:
   ```swift
   extension TaskPaperDocument {
       override func updateUserActivityState(_ userActivity: NSUserActivity) {
           super.updateUserActivityState(userActivity)
           userActivity.title = displayName
           userActivity.userInfo = [
               "documentURL": fileURL?.absoluteString ?? "",
               "selection": currentSelection()
           ]
       }
       
       override func restoreUserActivityState(_ userActivity: NSUserActivity) {
           super.restoreUserActivityState(userActivity)
           if let urlString = userActivity.userInfo?["documentURL"] as? String,
              let url = URL(string: urlString) {
               // Restore document and selection
           }
       }
   }
   ```
3. Create and update user activity when document edited
4. Invalidate activity when document closed
5. Test Handoff between multiple Macs (requires iCloud-signed app)

**Prerequisites**: None

**Success Criteria**:
```bash
grep -q "NSUserActivityTypes" TaskPaper/Info.plist
grep -q "updateUserActivityState" TaskPaper/TaskPaperDocument.swift
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct build | grep -q "BUILD SUCCEEDED"
echo "Manual test: Open document on one Mac, verify Handoff icon on another"
```

---

## P3-T21: Improve Accessibility with Modern APIs

**Component**: Accessibility  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineTextView.swift`
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorAccessibility.swift` (new)

**Technical Changes**:
1. Create accessibility helper:
   ```swift
   extension OutlineTextView {
       override func accessibilityRole() -> NSAccessibility.Role? {
           return .outline
       }
       
       override func accessibilityChildren() -> [Any]? {
           // Return outline items as accessibility elements
           return outlineEditor?.visibleItems.map { item in
               OutlineItemAccessibilityElement(item: item, parent: self)
           }
       }
   }
   
   final class OutlineItemAccessibilityElement: NSAccessibilityElement {
       let item: OutlineItem
       
       init(item: OutlineItem, parent: Any) {
           self.item = item
           super.init()
           accessibilityParent = parent
       }
       
       override func accessibilityRole() -> NSAccessibility.Role? {
           switch item.type {
           case .project: return .group
           case .task: return .checkBox
           case .note: return .staticText
           }
       }
       
       override func accessibilityLabel() -> String? {
           return item.text
       }
       
       override func accessibilityValue() -> Any? {
           if item.type == .task {
               return item.hasTag("@done")
           }
           return nil
       }
   }
   ```
2. Expose outline structure to VoiceOver
3. Support keyboard navigation for accessibility
4. Announce state changes (item completed, expanded/collapsed)
5. Test with VoiceOver enabled

**Prerequisites**: P3-T11 (TextKit 2 text view)

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorAccessibility.swift
grep -q "OutlineItemAccessibilityElement" BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorAccessibility.swift
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct build | grep -q "BUILD SUCCEEDED"
echo "Manual test: Enable VoiceOver and verify outline navigation works"
```

---

## P3-T22: Add Localization Infrastructure for Additional Languages

**Component**: Internationalization  
**Files**:
- `TaskPaper/Localizations/` (new localization directories)
- `BirchEditor/BirchEditor.swift/Localizations/`

**Technical Changes**:
1. Audit current localization (es.lproj exists, minimal coverage)
2. Extract all user-facing strings to .strings files:
   ```bash
   genstrings -o en.lproj *.swift
   ```
3. Create localization structure:
   ```
   Localizations/
   ├── en.lproj/
   │   └── Localizable.strings
   ├── es.lproj/
   │   └── Localizable.strings
   ├── fr.lproj/
   │   └── Localizable.strings
   └── de.lproj/
       └── Localizable.strings
   ```
4. Replace hardcoded strings with NSLocalizedString:
   ```swift
   // Before: "Task"
   // After: NSLocalizedString("task.type.label", comment: "Label for task item type")
   ```
5. Export strings for translation (XLIFF format)
6. Document localization workflow in README.md
7. Test language switching

**Prerequisites**: None

**Success Criteria**:
```bash
test -d TaskPaper/Localizations/en.lproj
test -f TaskPaper/Localizations/en.lproj/Localizable.strings
grep -q "NSLocalizedString" TaskPaper/TaskPaperAppDelegate.swift
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct build | grep -q "BUILD SUCCEEDED"
```

---

## P3-T23: Update UI Tests for SwiftUI Components

**Component**: Testing  
**Files**:
- `TaskPaperUITests/SwiftUIComponentTests.swift` (new)

**Technical Changes**:
1. Create UI tests for SwiftUI migrations:
   ```swift
   final class SwiftUIComponentTests: XCTestCase {
       func testPreferencesWindowSwiftUI() throws {
           let app = XCUIApplication()
           app.launch()
           
           // Open preferences
           app.menuBars.menuItems["Preferences…"].click()
           
           // Verify SwiftUI controls exist
           let preferencesWindow = app.windows["Preferences"]
           XCTAssertTrue(preferencesWindow.exists)
           
           // Test font size slider
           let slider = preferencesWindow.sliders["Font Size"]
           XCTAssertTrue(slider.exists)
           slider.adjust(toNormalizedSliderPosition: 0.7)
           
           // Verify change applied
       }
       
       func testChoicePaletteSwiftUI() throws {
           let app = XCUIApplication()
           app.launch()
           
           // Open choice palette (Cmd+Shift+P or similar)
           app.typeKey("p", modifierFlags: [.command, .shift])
           
           // Verify SwiftUI palette appears
           let palette = app.windows.element(matching: .dialog, identifier: "Choice Palette")
           XCTAssertTrue(palette.waitForExistence(timeout: 1))
           
           // Test search field
           let searchField = palette.searchFields.firstMatch
           searchField.typeText("task")
           
           // Verify filtering works
       }
   }
   ```
2. Test all migrated SwiftUI components
3. Verify keyboard navigation works
4. Test light/dark mode appearance
5. Verify accessibility labels exist

**Prerequisites**: P3-T03, P3-T04, P3-T05

**Success Criteria**:
```bash
test -f TaskPaperUITests/SwiftUIComponentTests.swift
xcodebuild test -project TaskPaper.xcodeproj -scheme TaskPaper-Direct -only-testing:TaskPaperUITests/SwiftUIComponentTests | grep -q "Test Succeeded"
```

---

## P3-T24: Performance Test UI Responsiveness

**Component**: Performance Testing  
**Files**:
- `TaskPaperUITests/UIPerformanceTests.swift` (new)
- `docs/modernisation/ui-performance-metrics.md` (new)

**Technical Changes**:
1. Create UI performance tests:
   ```swift
   final class UIPerformanceTests: XCTestCase {
       func testEditorScrollingPerformance() throws {
           let app = XCUIApplication()
           app.launchArguments = ["--load-large-document"]
           app.launch()
           
           measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
               let editor = app.textViews.firstMatch
               editor.swipeUp(velocity: .fast)
           }
       }
       
       func testTypingLatency() throws {
           let app = XCUIApplication()
           app.launch()
           
           let editor = app.textViews.firstMatch
           measure(metrics: [XCTOSSignpostMetric.applicationLaunchMetric]) {
               for _ in 0..<100 {
                   editor.typeText("test\n")
               }
           }
       }
       
       func testPreferencesOpen() throws {
           let app = XCUIApplication()
           app.launch()
           
           measure {
               app.menuBars.menuItems["Preferences…"].click()
               let prefsWindow = app.windows["Preferences"]
               XCTAssertTrue(prefsWindow.waitForExistence(timeout: 2))
               prefsWindow.buttons[XCUIIdentifierCloseWindow].click()
           }
       }
   }
   ```
2. Measure key UI operations
3. Compare TextKit 1 vs TextKit 2 responsiveness
4. Document performance targets (e.g., 60fps scrolling)
5. Save baseline metrics for future comparison

**Prerequisites**: P3-T13, P3-T14

**Success Criteria**:
```bash
test -f TaskPaperUITests/UIPerformanceTests.swift
test -f docs/modernisation/ui-performance-metrics.md
xcodebuild test -project TaskPaper.xcodeproj -scheme TaskPaper-Direct -only-testing:TaskPaperUITests/UIPerformanceTests | grep -q "Test Succeeded"
```

---

## P3-T25: Update Documentation for UI Modernization

**Component**: Documentation  
**Files**:
- `docs/modernisation/UI-Modernization-Guide.md` (new)

**Technical Changes**:
1. Create comprehensive UI modernization documentation:
   - SwiftUI adoption strategy and rationale
   - Components migrated to SwiftUI (preferences, palettes, etc.)
   - Components remaining in AppKit (main editor)
   - TextKit 2 migration details
   - Performance improvements achieved
   - Touch Bar implementation guide
   - Accessibility enhancements
   - Localization expansion
2. Document AppKit/SwiftUI integration patterns used
3. Provide guidelines for future UI additions
4. Include screenshots of modernized UI
5. Document any behavior changes from modernization
6. Create migration guide for users (if UI changed)

**Prerequisites**: All P3 UI tasks (P3-T01 through P3-T24)

**Success Criteria**:
```bash
test -f docs/modernisation/UI-Modernization-Guide.md
grep -q "SwiftUI" docs/modernisation/UI-Modernization-Guide.md
grep -q "TextKit 2" docs/modernisation/UI-Modernization-Guide.md
grep -q "Touch Bar" docs/modernisation/UI-Modernization-Guide.md
```

---

## P3-T26: Update Code Coverage and Metrics

**Component**: Testing Infrastructure  
**Files**:
- `docs/modernisation/phase3-coverage-report.txt` (new)

**Technical Changes**:
1. Run full test suite with coverage:
   ```bash
   xcodebuild test -project TaskPaper.xcodeproj -scheme TaskPaper-Direct -enableCodeCoverage YES
   xcrun xccov view --report $(find ~/Library/Developer/Xcode/DerivedData -name '*.xcresult' | head -1) > docs/modernisation/phase3-coverage-report.txt
   ```
2. Target: 75%+ code coverage (up from 70% in Phase 2)
3. Analyze coverage of new SwiftUI components
4. Identify TextKit 2 code coverage
5. Compare with Phase 2 baseline
6. Document areas needing additional tests

**Prerequisites**: All P3 tasks complete

**Success Criteria**:
```bash
test -f docs/modernisation/phase3-coverage-report.txt
grep -q "%" docs/modernisation/phase3-coverage-report.txt
echo "Verify coverage >= 75%"
```

---

## P3-T27: Document Phase 3 Completion and Metrics

**Component**: Documentation  
**Files**:
- `docs/modernisation/Phase-3-Completion-Report.md` (new)

**Technical Changes**:
1. Create completion report:
   - All 27 Phase 3 tasks completed
   - SwiftUI adoption summary (components migrated)
   - TextKit 2 migration results (performance improvements)
   - Touch Bar implementation summary
   - Accessibility improvements documented
   - Localization expansion completed
   - Code coverage improvement (70% → 75%+)
2. Include metrics:
   - Lines of AppKit code replaced with SwiftUI
   - Lines of TextKit 1 code removed
   - Performance improvements (load time, scrolling, etc.)
   - Number of new languages supported
   - UI test coverage for new components
3. Document user-facing changes
4. List remaining technical debt
5. Update README.md with Phase 3 status
6. Prepare recommendations for Phase 4

**Prerequisites**: All P3 tasks (P3-T01 through P3-T26)

**Success Criteria**:
```bash
test -f docs/modernisation/Phase-3-Completion-Report.md
grep -q "Phase 3 Complete" docs/modernisation/Phase-3-Completion-Report.md
grep -q "SwiftUI" docs/modernisation/Phase-3-Completion-Report.md
grep -q "TextKit 2" docs/modernisation/Phase-3-Completion-Report.md
grep -q "Touch Bar" docs/modernisation/Phase-3-Completion-Report.md
```

---

## Phase 3 Summary

**Total Tasks**: 27  
**Estimated Duration**: 3-6 months  
**Key Deliverables**:
- ✅ SwiftUI adoption for preferences, palettes, and simple UI
- ✅ TextKit 2 migration complete for main editor
- ✅ Touch Bar support implemented
- ✅ Accessibility improvements with modern APIs
- ✅ Localization infrastructure expanded
- ✅ Performance improvements from TextKit 2
- ✅ Code coverage improved to 75%+
- ✅ Hybrid AppKit/SwiftUI architecture established

**Phase 3 Success Metrics**:
- All 27 tasks completed and verified
- At least 3 UI components migrated to SwiftUI
- TextKit 2 fully functional with performance improvement
- Touch Bar working on compatible hardware
- Zero accessibility regressions (VoiceOver tested)
- Code coverage ≥ 75%
- macOS 12.0+ deployment target
- All tests passing (unit, integration, UI, performance)
- User-facing features preserved or enhanced
