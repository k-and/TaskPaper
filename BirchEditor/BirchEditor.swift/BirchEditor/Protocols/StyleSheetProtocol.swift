//
//  StyleSheetProtocol.swift
//  BirchEditor
//
//  Created for Protocol-Oriented Design (Phase 2)
//  Enables dependency injection and testing
//

import BirchOutline
import Cocoa

/// Protocol abstraction for stylesheet operations.
///
/// This protocol enables dependency injection of stylesheet implementations,
/// allowing for:
/// - Mock stylesheets in tests (no JavaScriptCore initialization)
/// - Alternative styling engines
/// - Predictable test behavior with stub responses
///
/// ## Usage
///
/// ```swift
/// func configureEditor(with styleSheet: StyleSheetProtocol) {
///     let style = styleSheet.computedStyle(for: element)
///     // Apply style...
/// }
/// ```
///
/// ## Testing
///
/// ```swift
/// let mockStyleSheet = MockStyleSheet()
/// mockStyleSheet.computedStyleStub = ComputedStyle(...)
/// configureEditor(with: mockStyleSheet)
/// ```
///
/// ## Concurrency
///
/// All methods are @MainActor isolated because:
/// - Styling operations interact with UI
/// - LESS compilation uses JavaScriptCore (main thread only)
/// - Computed styles are applied to views (main thread only)
///
/// Note: This protocol is NOT Sendable because:
/// - StyleSheet implementations hold JSValue references
/// - JSValue is non-Sendable by Apple's framework design
/// - @MainActor isolation provides thread safety
@MainActor
public protocol StyleSheetProtocol: AnyObject {

    /// The source URL of the stylesheet file
    var source: URL { get }

    // MARK: - Computed Style Operations

    /// Computes the style for a given element.
    ///
    /// - Parameter element: The element to compute style for (typically item/line metadata)
    /// - Returns: A computed style with font, color, and paragraph attributes
    ///
    /// Example:
    /// ```swift
    /// let element = ["type": "task", "data-done": ""]
    /// let style = styleSheet.computedStyle(for: element)
    /// textView.typingAttributes = style.attributes
    /// ```
    func computedStyle(for element: Any) -> ComputedStyle

    /// Gets the computed style key path for an element without computing the full style.
    ///
    /// This is useful for caching - elements with the same key path share computed styles.
    ///
    /// - Parameter element: The element to get key path for
    /// - Returns: A string key path (e.g., "task.done" or "note")
    func computedStyleKeyPath(for element: Any) -> String

    /// Gets a cached computed style for a key path.
    ///
    /// - Parameter keyPath: The style key path
    /// - Returns: Cached computed style for the key path
    func computedStyle(forKeyPath keyPath: String) -> ComputedStyle

    // MARK: - Style Invalidation

    /// Invalidates all cached computed styles, forcing recomputation.
    ///
    /// Call this when:
    /// - Stylesheet source changes
    /// - User font size changes
    /// - Appearance (light/dark mode) changes
    func invalidateComputedStyles()
}

// MARK: - Default Implementations

extension StyleSheetProtocol {
    /// Convenience method to compute style using key path.
    public func computedStyle(for element: Any) -> ComputedStyle {
        let keyPath = computedStyleKeyPath(for: element)
        return computedStyle(forKeyPath: keyPath)
    }
}

// MARK: - StyleSheet Conformance

/// Extend the concrete StyleSheet class to conform to the protocol.
/// This allows gradual migration - code can use StyleSheetProtocol while
/// implementation remains unchanged.
extension StyleSheet: StyleSheetProtocol {
    public func computedStyle(for element: Any) -> ComputedStyle {
        return computedStyleForElement(element)
    }

    public func computedStyleKeyPath(for element: Any) -> String {
        return computedStyleKeyPathForElement(element)
    }

    public func computedStyle(forKeyPath keyPath: String) -> ComputedStyle {
        return computedStyleForKeyPath(keyPath)
    }

    public func invalidateComputedStyles() {
        styleKeysToCocoaStyles.removeAll()
    }
}
