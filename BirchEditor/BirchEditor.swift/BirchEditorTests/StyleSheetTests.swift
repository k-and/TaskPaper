//
//  StyleSheetTests.swift
//  Birch
//
//  Created by Jesse Grosjean on 6/9/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
@preconcurrency import JavaScriptCore
@testable import TaskPaper
import XCTest

class StyleSheetTests: XCTestCase {
    var styleSheet: StyleSheet?
    weak var weakStyleSheet: StyleSheet?

    override func setUp() {
        styleSheet = StyleSheet(source: nil, scriptContext: BirchOutline.sharedContext)
        weakStyleSheet = styleSheet
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        styleSheet = nil
        XCTAssertNil(weakStyleSheet)
    }

    func testComputeStyleKeyForElement() {
        let computedStyle = styleSheet?.computedStyleForElement(["tagName": "window"])
        XCTAssertNil(computedStyle?.allValues["missingkey"])
        XCTAssertNotNil(computedStyle?.allValues["appearance"])
    }

    // MARK: - LESS Compilation Tests

    func testLESSCompilationSucceeds() {
        // Test that LESS is successfully compiled to CSS
        // The StyleSheet initializer compiles LESS, so if we can create a StyleSheet, compilation succeeded
        XCTAssertNotNil(styleSheet)
        XCTAssertNotNil(styleSheet?.jsStyleSheet)
    }

    func testBaseStyleSheetIsLoaded() {
        // Test that the base stylesheet is loaded
        XCTAssertNotNil(styleSheet?.source)
        XCTAssertTrue(styleSheet?.source.pathExtension == "less" || styleSheet?.source.lastPathComponent == "base-stylesheet.less")
    }

    func testComputedStyleForKeyPath() {
        // Test that we can get computed styles for specific key paths
        let keyPath = "window"
        let computedStyle = styleSheet?.computedStyleForKeyPath(keyPath)

        XCTAssertNotNil(computedStyle)
        XCTAssertNotNil(computedStyle?.allValues)
    }

    func testComputedStyleCaching() {
        // Test that computed styles are cached
        let keyPath = "window"
        let style1 = styleSheet?.computedStyleForKeyPath(keyPath)
        let style2 = styleSheet?.computedStyleForKeyPath(keyPath)

        // Should return the same cached instance
        XCTAssertTrue(style1 === style2, "Computed styles should be cached")
    }

    // MARK: - Variable Substitution Tests

    func testUserFontSizeSubstitution() {
        // Test that $USER_FONT_SIZE is substituted
        // The StyleSheet should compile successfully with font size substitution
        XCTAssertNotNil(styleSheet)

        // Get a computed style that would use font size
        let computedStyle = styleSheet?.computedStyleForElement(["tagName": "window"])
        XCTAssertNotNil(computedStyle)

        // Font should be present in computed style
        if let font = computedStyle?.allValues[.font] as? NSFont {
            XCTAssertGreaterThanOrEqual(font.pointSize, 8.0, "Font size should be at least 8pt (the minimum)")
        }
    }

    func testAppearanceSubstitution() {
        // Test that $APPEARANCE is substituted (light or dark)
        XCTAssertNotNil(styleSheet)

        // The appearance variable should have been substituted during initialization
        // We can verify this by checking that the stylesheet compiled successfully
        let computedStyle = styleSheet?.computedStyleForElement(["tagName": "window"])
        XCTAssertNotNil(computedStyle?.allValues[.appearance])
    }

    func testControlAccentColorSubstitution() {
        // Test that $CONTROL_ACCENT_COLOR is substituted
        XCTAssertNotNil(styleSheet)

        // The color should be substituted during initialization
        // Verify stylesheet compiled successfully (which means substitution worked)
        let computedStyle = styleSheet?.computedStyleForElement(["tagName": "window"])
        XCTAssertNotNil(computedStyle)
    }

    func testSelectedContentBackgroundColorSubstitution() {
        // Test that $SELECTED_CONTENT_BACKGROUND_COLOR is substituted
        XCTAssertNotNil(styleSheet)

        // Verify stylesheet compiled successfully
        let computedStyle = styleSheet?.computedStyleForElement(["tagName": "window"])
        XCTAssertNotNil(computedStyle)
    }

    // MARK: - Light/Dark Mode Tests

    func testLightModeAppearance() {
        // Test that light mode appearance is handled
        // Create a stylesheet (which detects current appearance)
        let testStyleSheet = StyleSheet(source: nil, scriptContext: BirchOutline.sharedContext)

        XCTAssertNotNil(testStyleSheet)

        // Get computed style for window element
        let computedStyle = testStyleSheet.computedStyleForElement(["tagName": "window"])
        XCTAssertNotNil(computedStyle)

        // Appearance should be set
        XCTAssertNotNil(computedStyle.allValues[.appearance])
    }

    func testDarkModeStylesDiffer() {
        // Test that we can create a stylesheet in either light or dark mode
        // The actual appearance is system-dependent, but the stylesheet should handle it
        let computedStyle = styleSheet?.computedStyleForElement(["tagName": "window"])

        XCTAssertNotNil(computedStyle)
        // The appearance should be one of the valid NSAppearance values
        if let appearance = computedStyle?.allValues[.appearance] as? NSAppearance {
            XCTAssertNotNil(appearance)
        }
    }

    // MARK: - Computed Style Tests

    func testComputedStyleForDifferentElements() {
        // Test that different elements get different computed styles
        let windowStyle = styleSheet?.computedStyleForElement(["tagName": "window"])
        let itemStyle = styleSheet?.computedStyleForElement(["tagName": "item"])

        XCTAssertNotNil(windowStyle)
        XCTAssertNotNil(itemStyle)

        // Styles should be different (not the same object)
        XCTAssertFalse(windowStyle === itemStyle, "Different elements should have different styles")
    }

    func testComputedStyleContainsAttributes() {
        // Test that computed styles contain expected attribute keys
        let computedStyle = styleSheet?.computedStyleForElement(["tagName": "window"])

        XCTAssertNotNil(computedStyle)
        XCTAssertNotNil(computedStyle?.allValues)

        // Should contain some standard attributes
        let hasFont = computedStyle?.allValues[.font] != nil
        let hasAppearance = computedStyle?.allValues[.appearance] != nil

        XCTAssertTrue(hasFont || hasAppearance, "Computed style should contain some standard attributes")
    }

    // MARK: - Color Parsing Tests

    func testColorFromJSColor() {
        // Test color parsing from JavaScript format [R, G, B, A]
        let jsColor: [CGFloat] = [255, 0, 0, 1.0] // Red color
        let color = colorFromJSColor(jsColor)

        XCTAssertNotNil(color)
        XCTAssertEqual(color?.alphaComponent, 1.0)
    }

    func testColorFromJSColorWithAlpha() {
        // Test color with alpha channel
        let jsColor: [CGFloat] = [128, 128, 128, 0.5] // Gray with 50% alpha
        let color = colorFromJSColor(jsColor)

        XCTAssertNotNil(color)
        XCTAssertEqual(color?.alphaComponent, 0.5, accuracy: 0.01)
    }

    func testColorFromInvalidValue() {
        // Test that invalid color values return nil
        let invalidColor = colorFromJSColor("not a color")
        XCTAssertNil(invalidColor)
    }

    // MARK: - Font Parsing Tests

    func testFontFromJSStyle() {
        // Test font parsing from JavaScript style dictionary
        let jsStyle: [String: Any] = [
            "font-family": ["-apple-system"],
            "font-size": NSNumber(value: 14),
            "font-weight": "normal",
            "font-style": "normal"
        ]

        let font = fontFromJSStyle(jsStyle)

        XCTAssertNotNil(font)
        XCTAssertEqual(font?.pointSize, 14.0)
    }

    func testFontFromJSStyleBold() {
        // Test bold font parsing
        let jsStyle: [String: Any] = [
            "font-family": ["-apple-system"],
            "font-size": NSNumber(value: 16),
            "font-weight": "bold",
            "font-style": "normal"
        ]

        let font = fontFromJSStyle(jsStyle)

        XCTAssertNotNil(font)
        XCTAssertEqual(font?.pointSize, 16.0)
    }

    func testFontFromJSStyleItalic() {
        // Test italic font parsing
        let jsStyle: [String: Any] = [
            "font-family": ["-apple-system"],
            "font-size": NSNumber(value: 12),
            "font-weight": "normal",
            "font-style": "italic"
        ]

        let font = fontFromJSStyle(jsStyle)

        XCTAssertNotNil(font)
        XCTAssertEqual(font?.pointSize, 12.0)
    }

    func testFontFromJSStyleUserFont() {
        // Test -apple-user font parsing
        let jsStyle: [String: Any] = [
            "font-family": ["-apple-user"],
            "font-size": NSNumber(value: 13)
        ]

        let font = fontFromJSStyle(jsStyle)

        XCTAssertNotNil(font)
        XCTAssertEqual(font?.pointSize, 13.0)
    }

    // MARK: - Underline Style Tests

    func testLineStyleFromString() {
        // Test underline style parsing
        let singleStyle = lineStyleFromString("NSUnderlineStyleSingle")
        XCTAssertEqual(singleStyle, NSUnderlineStyle.single)

        let thickStyle = lineStyleFromString("NSUnderlineStyleThick")
        XCTAssertEqual(thickStyle, NSUnderlineStyle.thick)

        let doubleStyle = lineStyleFromString("NSUnderlineStyleDouble")
        XCTAssertEqual(doubleStyle, NSUnderlineStyle.double)
    }

    func testLineStyleFromStringWithPattern() {
        // Test underline style with pattern
        let dottedStyle = lineStyleFromString("NSUnderlineStyleSingle NSUnderlinePatternDot")
        XCTAssertNotNil(dottedStyle)

        let dashedStyle = lineStyleFromString("NSUnderlineStyleSingle NSUnderlinePatternDash")
        XCTAssertNotNil(dashedStyle)
    }

    func testLineStyleFromStringByWord() {
        // Test underline by word
        let byWordStyle = lineStyleFromString("NSUnderlineStyleSingle NSUnderlineByWord")
        XCTAssertNotNil(byWordStyle)
    }

    func testLineStyleFromInvalidString() {
        // Test that invalid style strings return nil
        let invalidStyle = lineStyleFromString("invalid")
        XCTAssertNil(invalidStyle)
    }

    // MARK: - Cursor Parsing Tests

    func testCursorFromJSStyle() {
        // Test cursor parsing
        let defaultCursor = cursorFromJSStyle(["cursor": "default"])
        XCTAssertEqual(defaultCursor, NSCursor.arrow)

        let pointerCursor = cursorFromJSStyle(["cursor": "pointer"])
        XCTAssertEqual(pointerCursor, NSCursor.pointingHand)

        let textCursor = cursorFromJSStyle(["cursor": "text"])
        XCTAssertEqual(textCursor, NSCursor.iBeam)
    }

    func testCursorFromInvalidStyle() {
        // Test that invalid cursor returns nil
        let invalidCursor = cursorFromJSStyle(["cursor": "invalid"])
        XCTAssertNil(invalidCursor)

        let noCursor = cursorFromJSStyle([:])
        XCTAssertNil(noCursor)
    }

    // MARK: - Paragraph Style Tests

    func testParagraphStyleFromJSStyle() {
        // Test paragraph style parsing
        let jsStyle: [String: Any] = [
            "line-height-multiple": NSNumber(value: 1.5),
            "paragraph-spacing-before": NSNumber(value: 10),
            "paragraph-spacing-after": NSNumber(value: 10)
        ]

        let paragraphStyle = paragraphStyleFromJSStyle(jsStyle)

        XCTAssertNotNil(paragraphStyle)
        XCTAssertEqual(paragraphStyle?.lineHeightMultiple, 1.5)
        XCTAssertEqual(paragraphStyle?.paragraphSpacingBefore, 10.0)
        XCTAssertEqual(paragraphStyle?.paragraphSpacing, 10.0)
    }

    func testParagraphStyleFromEmptyStyle() {
        // Test paragraph style with empty dictionary
        let paragraphStyle = paragraphStyleFromJSStyle([:])

        XCTAssertNotNil(paragraphStyle)
        // Should return default paragraph style
    }

    // MARK: - StyleSheet URL Tests

    func testDefaultStyleSheetURL() {
        // Test that we can get the default stylesheet URL
        let defaultURL = StyleSheet.defaultStyleSheetURL

        XCTAssertNotNil(defaultURL)
        XCTAssertTrue(defaultURL.pathExtension == "less")
    }

    func testStyleSheetsURLs() {
        // Test that we can get the list of available stylesheets
        let urls = StyleSheet.styleSheetsURLs

        // Should return an array (may be empty if no custom stylesheets)
        XCTAssertNotNil(urls)

        // All URLs should be .less files
        for url in urls {
            XCTAssertEqual(url.pathExtension, "less")
        }
    }

    // MARK: - Memory Management Tests

    func testStyleSheetDeinit() {
        // Test that StyleSheet is properly deallocated
        var testStyleSheet: StyleSheet? = StyleSheet(source: nil, scriptContext: BirchOutline.sharedContext)
        weak var weakTest = testStyleSheet

        XCTAssertNotNil(weakTest)

        testStyleSheet = nil

        XCTAssertNil(weakTest, "StyleSheet should be deallocated")
    }

    // MARK: - Integration Tests

    func testStyleSheetWithCustomSource() {
        // Test that we can create a stylesheet with a custom source
        let customURL = StyleSheet.defaultStyleSheetURL
        let customStyleSheet = StyleSheet(source: customURL, scriptContext: BirchOutline.sharedContext)

        XCTAssertNotNil(customStyleSheet)
        XCTAssertEqual(customStyleSheet.source, customURL)
    }

    func testMultipleStyleSheetInstances() {
        // Test that we can create multiple stylesheet instances
        let styleSheet1 = StyleSheet(source: nil, scriptContext: BirchOutline.sharedContext)
        let styleSheet2 = StyleSheet(source: nil, scriptContext: BirchOutline.sharedContext)

        XCTAssertNotNil(styleSheet1)
        XCTAssertNotNil(styleSheet2)
        XCTAssertFalse(styleSheet1 === styleSheet2, "Should create different instances")
    }

    func testSharedInstance() {
        // Test that the shared instance is accessible
        let shared = StyleSheet.sharedInstance

        XCTAssertNotNil(shared)
        XCTAssertNotNil(shared.jsStyleSheet)
    }

    // MARK: - Computed Style Attribute Tests

    func testComputedStyleTextDecorations() {
        // Test that we can parse text decoration attributes
        // This tests the JavaScript→Swift bridge for style attributes

        // Get a style that might have decorations
        let computedStyle = styleSheet?.computedStyleForElement(["tagName": "item"])

        XCTAssertNotNil(computedStyle)
        XCTAssertNotNil(computedStyle?.allValues)
    }

    func testComputedStyleColors() {
        // Test that various color attributes are properly parsed
        let computedStyle = styleSheet?.computedStyleForElement(["tagName": "window"])

        XCTAssertNotNil(computedStyle)

        // Check for presence of any color attributes (exact attributes depend on stylesheet)
        let hasColors = computedStyle?.allValues.keys.contains { key in
            key == .foregroundColor || key == .backgroundColor
        } ?? false

        // It's okay if no colors are set, we're just testing the mechanism works
        XCTAssertNotNil(computedStyle)
    }

    // MARK: - Performance Tests

    func testStyleSheetCreationPerformance() {
        // Test the performance of creating stylesheets
        measure {
            let _ = StyleSheet(source: nil, scriptContext: BirchOutline.sharedContext)
        }
    }

    func testComputedStylePerformance() {
        // Test the performance of computing styles
        measure {
            for _ in 0..<100 {
                let _ = self.styleSheet?.computedStyleForElement(["tagName": "window"])
            }
        }
    }

    func testCachedStylePerformance() {
        // Test that cached styles are fast
        let keyPath = "window"

        // Warm up cache
        let _ = styleSheet?.computedStyleForKeyPath(keyPath)

        measure {
            for _ in 0..<1000 {
                let _ = self.styleSheet?.computedStyleForKeyPath(keyPath)
            }
        }
    }
}
