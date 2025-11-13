//
//  MockStyleSheet.swift
//  BirchEditorTests
//
//  Created for Protocol-Oriented Design (Phase 2)
//  Mock stylesheet for testing without JavaScriptCore
//

import BirchEditor
import BirchOutline
import Cocoa
import Foundation

/// Mock StyleSheet implementation for testing.
///
/// This mock enables testing stylesheet-dependent code without:
/// - Initializing JavaScriptCore (slow)
/// - Loading LESS files (I/O overhead)
/// - Compiling CSS (CPU overhead)
///
/// ## Benefits
///
/// - **Fast**: No JS engine initialization (~100ms saved per test)
/// - **Predictable**: Stub responses ensure deterministic tests
/// - **Inspectable**: Records all method calls for verification
///
/// ## Usage
///
/// ```swift
/// class MyEditorTests: XCTestCase {
///     func testStyling() {
///         let mockStyleSheet = MockStyleSheet(source: URL(string: "file:///test.less")!)
///
///         // Stub the response
///         mockStyleSheet.computedStyleStub = ComputedStyle(
///             font: NSFont.systemFont(ofSize: 14),
///             color: NSColor.black
///         )
///
///         // Use in test
///         let editor = configureEditor(styleSheet: mockStyleSheet)
///
///         // Verify behavior
///         XCTAssertEqual(mockStyleSheet.computedStyleCalls.count, 1)
///         XCTAssertEqual(mockStyleSheet.computedStyleCalls[0] as? String, "task")
///     }
/// }
/// ```
///
/// ## Recording
///
/// All method calls are recorded in `*Calls` arrays:
/// - `computedStyleCalls`: Records all `computedStyle(for:)` calls
/// - `computedStyleKeyPathCalls`: Records all `computedStyleKeyPath(for:)` calls
/// - `computedStyleForKeyPathCalls`: Records all `computedStyle(forKeyPath:)` calls
///
/// ## Stubbing
///
/// Set stub properties to control return values:
/// - `computedStyleStub`: Return value for `computedStyle(for:)`
/// - `computedStyleKeyPathStub`: Return value for `computedStyleKeyPath(for:)`
/// - `computedStyleForKeyPathStub`: Return value for `computedStyle(forKeyPath:)`
@MainActor
public final class MockStyleSheet: StyleSheetProtocol {

    // MARK: - Properties

    public let source: URL

    // MARK: - Call Recording

    /// Records all calls to `computedStyle(for:)`
    public private(set) var computedStyleCalls: [Any] = []

    /// Records all calls to `computedStyleKeyPath(for:)`
    public private(set) var computedStyleKeyPathCalls: [Any] = []

    /// Records all calls to `computedStyle(forKeyPath:)`
    public private(set) var computedStyleForKeyPathCalls: [String] = []

    /// Records all calls to `invalidateComputedStyles()`
    public private(set) var invalidateComputedStylesCallCount: Int = 0

    // MARK: - Stubs

    /// Stub response for `computedStyle(for:)`. Default is a basic black-on-white style.
    public var computedStyleStub: ComputedStyle

    /// Stub response for `computedStyleKeyPath(for:)`. Default is "default".
    public var computedStyleKeyPathStub: String = "default"

    /// Stub responses for `computedStyle(forKeyPath:)` keyed by key path.
    /// Falls back to `computedStyleStub` if key path not found.
    public var computedStyleForKeyPathStubs: [String: ComputedStyle] = [:]

    // MARK: - Initialization

    public init(source: URL = URL(fileURLWithPath: "/mock/test.less")) {
        self.source = source
        self.computedStyleStub = MockStyleSheet.defaultComputedStyle()
    }

    // MARK: - Protocol Implementation

    public func computedStyle(for element: Any) -> ComputedStyle {
        computedStyleCalls.append(element)
        return computedStyleStub
    }

    public func computedStyleKeyPath(for element: Any) -> String {
        computedStyleKeyPathCalls.append(element)
        return computedStyleKeyPathStub
    }

    public func computedStyle(forKeyPath keyPath: String) -> ComputedStyle {
        computedStyleForKeyPathCalls.append(keyPath)
        return computedStyleForKeyPathStubs[keyPath] ?? computedStyleStub
    }

    public func invalidateComputedStyles() {
        invalidateComputedStylesCallCount += 1
    }

    // MARK: - Reset

    /// Resets all recorded calls and stubs to initial state.
    ///
    /// Call this in test `tearDown()` or between test cases.
    public func reset() {
        computedStyleCalls.removeAll()
        computedStyleKeyPathCalls.removeAll()
        computedStyleForKeyPathCalls.removeAll()
        invalidateComputedStylesCallCount = 0
        computedStyleStub = MockStyleSheet.defaultComputedStyle()
        computedStyleKeyPathStub = "default"
        computedStyleForKeyPathStubs.removeAll()
    }

    // MARK: - Default Styles

    /// Creates a basic default computed style for testing.
    ///
    /// Uses:
    /// - System font at 14pt
    /// - Black text
    /// - White background
    /// - Left-aligned
    ///
    /// Override with custom stubs for specific test needs.
    public static func defaultComputedStyle() -> ComputedStyle {
        let font = NSFont.systemFont(ofSize: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping

        let allValues: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black,
            .backgroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle
        ]

        return ComputedStyle(allValues: allValues)
    }

    /// Creates a computed style for task items.
    public static func taskStyle() -> ComputedStyle {
        let font = NSFont.systemFont(ofSize: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.paragraphSpacing = 4

        let allValues: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black,
            .backgroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle
        ]

        return ComputedStyle(allValues: allValues)
    }

    /// Creates a computed style for completed tasks.
    public static func completedTaskStyle() -> ComputedStyle {
        let font = NSFont.systemFont(ofSize: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let allValues: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.gray,
            .backgroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle,
            .strikethroughStyle: NSUnderlineStyle.single.rawValue
        ]

        return ComputedStyle(allValues: allValues)
    }

    /// Creates a computed style for note items.
    public static func noteStyle() -> ComputedStyle {
        let font = NSFont.systemFont(ofSize: 13)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.firstLineHeadIndent = 20

        let allValues: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.darkGray,
            .backgroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle
        ]

        return ComputedStyle(allValues: allValues)
    }
}

