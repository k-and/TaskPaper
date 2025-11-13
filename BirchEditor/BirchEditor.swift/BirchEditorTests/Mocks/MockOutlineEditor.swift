//
//  MockOutlineEditor.swift
//  BirchEditorTests
//
//  Created for Protocol-Oriented Design (Phase 2)
//  Mock outline editor for testing without JavaScriptCore
//

import BirchEditor
import BirchOutline
import Cocoa
import Foundation

/// Mock OutlineEditorType implementation for testing.
///
/// This mock enables testing editor-dependent code without:
/// - Initializing JavaScriptCore (slow)
/// - Loading JavaScript bundles (I/O overhead)
/// - Complex editor state management
///
/// ## Benefits
///
/// - **Fast**: No JS engine initialization (~100-200ms saved per test)
/// - **Predictable**: Stub responses ensure deterministic tests
/// - **Inspectable**: Records all method calls for verification
///
/// ## Usage
///
/// ```swift
/// class MyEditorTests: XCTestCase {
///     func testEditorOperation() {
///         let mockEditor = MockOutlineEditor()
///
///         // Configure the editor
///         mockEditor.outlineStub = mockOutline
///         mockEditor.deserializeItemsStub = [item1, item2]
///
///         // Use in test
///         let result = mockEditor.deserializeItems("task1\ntask2", options: nil)
///
///         // Verify behavior
///         XCTAssertEqual(mockEditor.deserializeItemsCalls.count, 1)
///         XCTAssertEqual(result?.count, 2)
///     }
/// }
/// ```
///
/// ## Recording
///
/// All method calls are recorded in `*Calls` arrays for verification:
/// - `deserializeItemsCalls`: Records `deserializeItems(_:options:)` calls
/// - `serializeItemsCalls`: Records `serializeItems(_:options:)` calls
/// - `moveBranchesCalls`: Records `moveBranches(_:parent:nextSibling:options:)` calls
/// - `performCommandCalls`: Records `performCommand(_:options:)` calls
/// - `evaluateScriptCalls`: Records `evaluateScript(_:withOptions:)` calls
///
/// ## Stubbing
///
/// Set stub properties to control return values:
/// - `outlineStub`: The outline instance to return
/// - `textStorageStub`: The text storage instance to return
/// - `deserializeItemsStub`: Items to return from deserialization
/// - `serializeItemsStub`: String to return from serialization
/// - `evaluateScriptStub`: Value to return from script evaluation
///
@MainActor
public final class MockOutlineEditor: NSObject, OutlineEditorType {

    // MARK: - Stubs

    /// Stub outline instance
    public var outlineStub: OutlineType!

    /// Stub outline sidebar
    public var outlineSidebarStub: OutlineSidebarType?

    /// Stub text storage
    public var textStorageStub: OutlineEditorTextStorage!

    /// Stub for deserializeItems return value
    public var deserializeItemsStub: [ItemType]?

    /// Stub for serializeItems return value
    public var serializeItemsStub: String = ""

    /// Stub for evaluateScript return value
    public var evaluateScriptStub: Any?

    /// Stub for selectedItems return value
    public var selectedItemsStub: [ItemType] = []

    /// Stub for displayedSelectedItems return value
    public var displayedSelectedItemsStub: [ItemType] = []

    /// Stub for displayedItem return value (indexed by index)
    public var displayedItemsStub: [Int: ItemType] = [:]

    /// Stub for firstDisplayedItem
    public var firstDisplayedItemStub: ItemType?

    /// Stub for lastDisplayedItem
    public var lastDisplayedItemStub: ItemType?

    /// Stub for computed style
    public var computedStyleStub: ComputedStyle?

    /// Stub for computed item indent
    public var computedItemIndentStub: Int = 17

    // MARK: - Call Recording

    /// Records all calls to deserializeItems
    public private(set) var deserializeItemsCalls: [(serializedItems: String, options: [String: Any]?)] = []

    /// Records all calls to serializeItems
    public private(set) var serializeItemsCalls: [(items: [ItemType], options: [String: Any]?)] = []

    /// Records all calls to serializeRange
    public private(set) var serializeRangeCalls: [(range: NSRange, options: [String: Any]?)] = []

    /// Records all calls to moveBranches
    public private(set) var moveBranchesCalls: [(items: [ItemType]?, parent: ItemType, nextSibling: ItemType?, options: [String: Any]?)] = []

    /// Records all calls to performCommand
    public private(set) var performCommandCalls: [(command: String, options: Any?)] = []

    /// Records all calls to evaluateScript
    public private(set) var evaluateScriptCalls: [(script: String, options: Any?)] = []

    /// Records all calls to replaceRangeWithString
    public private(set) var replaceRangeWithStringCalls: [(range: NSRange, string: String)] = []

    /// Records all calls to replaceRangeWithItems
    public private(set) var replaceRangeWithItemsCalls: [(range: NSRange, items: [ItemType])] = []

    /// Records all calls to toggleAttribute
    public private(set) var toggleAttributeCalls: [String] = []

    /// Records all calls to clickedOnItem
    public private(set) var clickedOnItemCalls: [(item: ItemType, link: String)] = []

    // MARK: - Properties

    public var outline: OutlineType {
        return outlineStub
    }

    public var outlineSidebar: OutlineSidebarType? {
        return outlineSidebarStub
    }

    public var textStorage: OutlineEditorTextStorage {
        return textStorageStub
    }

    public weak var outlineEditorViewController: OutlineEditorViewController?

    public var selectedRange: NSRange = NSRange(location: 0, length: 0)

    public var selectedItems: [ItemType] {
        return selectedItemsStub
    }

    public var displayedSelectedItems: [ItemType] {
        return displayedSelectedItemsStub
    }

    public var hoistedItem: ItemType = DummyItem()

    public var focusedItem: ItemType?

    public var itemPathFilter: String = ""

    public var editorState: OutlineEditorState {
        get {
            return (hoistedItem: hoistedItem, focusedItem: focusedItem, itemPathFilter: itemPathFilter)
        }
        set {
            hoistedItem = newValue.hoistedItem ?? DummyItem()
            focusedItem = newValue.focusedItem
            itemPathFilter = newValue.itemPathFilter ?? ""
        }
    }

    public var firstDisplayedItem: ItemType? {
        return firstDisplayedItemStub
    }

    public var lastDisplayedItem: ItemType? {
        return lastDisplayedItemStub
    }

    public var numberOfDisplayedItems: Int = 0

    public var heightOfDisplayedItems: CGFloat = 0

    public var styleSheet: StyleSheet?

    public var computedStyle: ComputedStyle? {
        return computedStyleStub
    }

    public var computedItemIndent: Int {
        return computedItemIndentStub
    }

    public var mouseOverItem: ItemType?

    public var mouseOverItemHandle: ItemType?

    public var restorableState: Any = [:]

    public var serializedRestorableState: String = ""

    // MARK: - Initialization

    public override init() {
        super.init()
    }

    // MARK: - Methods

    public func moveSelectionToItems(_ headItem: ItemType, headOffset: Int?, anchorItem: ItemType?, anchorOffset: Int?) {
        // Mock implementation - no-op
    }

    public func moveSelectionToRange(_ headLocation: Int, anchorLocation: Int?) {
        // Mock implementation - no-op
    }

    public func focus() {
        // Mock implementation - no-op
    }

    public func displayedItem(at index: Int) -> ItemType {
        return displayedItemsStub[index] ?? DummyItem()
    }

    public func displayedItemYOffset(at index: Int) -> CGFloat {
        return CGFloat(index) * 20.0 // Simple stub calculation
    }

    public func displayedItemIndexAtYOffset(at yOffset: CGFloat) -> Int {
        return Int(yOffset / 20.0) // Simple stub calculation
    }

    public func setDisplayedItemHeight(_ height: CGFloat, at index: Int) {
        // Mock implementation - no-op
    }

    public func toggleAttribute(_ attribute: String) {
        toggleAttributeCalls.append(attribute)
    }

    public func onDidChangeHoistedItem(_ callback: @escaping () -> Void) -> DisposableType {
        return DummyDisposable()
    }

    public func onDidChangeFocusedItem(_ callback: @escaping () -> Void) -> DisposableType {
        return DummyDisposable()
    }

    public func onDidChangeItemPathFilter(_ callback: @escaping () -> Void) -> DisposableType {
        return DummyDisposable()
    }

    public func serializeItems(_ items: [ItemType], options: [String: Any]?) -> String {
        serializeItemsCalls.append((items: items, options: options))
        return serializeItemsStub
    }

    public func serializeRange(_ range: NSRange, options: [String: Any]?) -> String {
        serializeRangeCalls.append((range: range, options: options))
        return serializeItemsStub
    }

    public func deserializeItems(_ serializedItems: String, options: [String: Any]?) -> [ItemType]? {
        deserializeItemsCalls.append((serializedItems: serializedItems, options: options))
        return deserializeItemsStub
    }

    public func replaceRangeWithString(_ range: NSRange, string: String) {
        replaceRangeWithStringCalls.append((range: range, string: string))
    }

    public func replaceRangeWithItems(_ range: NSRange, items: [ItemType]) {
        replaceRangeWithItemsCalls.append((range: range, items: items))
    }

    public func moveBranches(_ items: [ItemType]?, parent: ItemType, nextSibling: ItemType?, options: [String: Any]?) {
        moveBranchesCalls.append((items: items, parent: parent, nextSibling: nextSibling, options: options))
    }

    public func performCommand(_ command: String, options: Any?) {
        performCommandCalls.append((command: command, options: options))
    }

    public func evaluateScript(_ script: String, withOptions options: Any?) -> Any? {
        evaluateScriptCalls.append((script: script, options: options))
        return evaluateScriptStub
    }

    public func guideRangesForVisibleRange(_ characterRange: NSRange) -> [NSRange] {
        return []
    }

    public func gapLocationsForVisibleRange(_ characterRange: NSRange) -> [Int] {
        return []
    }

    public func clickedOnItem(_ item: ItemType, link: String) -> Bool {
        clickedOnItemCalls.append((item: item, link: link))
        return false
    }

    public func createPasteboardItem(_ item: ItemType) -> NSPasteboardItem {
        return NSPasteboardItem()
    }

    // MARK: - Reset

    /// Resets all recorded calls and stubs to initial state.
    ///
    /// Call this in test `tearDown()` or between test cases.
    public func reset() {
        deserializeItemsCalls.removeAll()
        serializeItemsCalls.removeAll()
        serializeRangeCalls.removeAll()
        moveBranchesCalls.removeAll()
        performCommandCalls.removeAll()
        evaluateScriptCalls.removeAll()
        replaceRangeWithStringCalls.removeAll()
        replaceRangeWithItemsCalls.removeAll()
        toggleAttributeCalls.removeAll()
        clickedOnItemCalls.removeAll()

        selectedRange = NSRange(location: 0, length: 0)
        selectedItemsStub = []
        displayedSelectedItemsStub = []
        hoistedItem = DummyItem()
        focusedItem = nil
        itemPathFilter = ""
        numberOfDisplayedItems = 0
        heightOfDisplayedItems = 0
        mouseOverItem = nil
        mouseOverItemHandle = nil
        restorableState = [:]
        serializedRestorableState = ""

        deserializeItemsStub = nil
        serializeItemsStub = ""
        evaluateScriptStub = nil
        displayedItemsStub.removeAll()
        firstDisplayedItemStub = nil
        lastDisplayedItemStub = nil
    }
}

// MARK: - Dummy Types

/// Dummy item for default stub values
@MainActor
private class DummyItem: ItemType {
    var id: String = "dummy"
    var bodyString: String = ""
    var attributedBodyString: NSAttributedString = NSAttributedString()
    var depth: UInt = 0
    var parent: ItemType?
    var firstChild: ItemType?
    var lastChild: ItemType?
    var previousSibling: ItemType?
    var nextSibling: ItemType?
    var previousItem: ItemType?
    var nextItem: ItemType?
    var ancestors: [ItemType] = []
    var descendants: [ItemType] = []
    var attributeNames: [String] = []

    func hasAttribute(_ name: String) -> Bool { return false }
    func getAttribute(_ name: String, inherited: Bool) -> Any? { return nil }
    func setAttribute(_ name: String, value: Any?) {}
    func appendChildren(_ items: [ItemType]) {}
    func insertChildrenBefore(_ items: [ItemType], referenceSibling: ItemType?) {}
    func removeChildren(_ items: [ItemType]) {}
    func removeFromParent() {}
    func addBodyAttributeInRange(_ attribute: String, value: Any, location: Int, length: Int) {}
    func addBodyAttributesInRange(_ attributes: [String: Any], location: Int, length: Int) {}
    func removeBodyAttributeInRange(_ attribute: String, location: Int, length: Int) {}
}

/// Dummy disposable for event handlers
private class DummyDisposable: DisposableType {
    func dispose() {}
}
