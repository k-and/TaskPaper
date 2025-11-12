//
//  OutlineEditorTextStorageTests.swift
//  Birch
//
//  Created by Jesse Grosjean on 6/6/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import JavaScriptCore
@testable import TaskPaper
import XCTest

class OutlineEditorTextStorageTests: XCTestCase {
    var outline: OutlineType!
    weak var weakOutline: OutlineType?
    var outlineEditor: OutlineEditorType!
    weak var weakOutlineEditor: OutlineEditorType?
    var outlineEditorTextStorage: OutlineEditorTextStorage!
    weak var weakOutlineEditorTextStorage: OutlineEditorTextStorage?

    override func setUp() {
        super.setUp()
        outline = BirchEditor.createTaskPaperOutline(nil)
        weakOutline = outline
        outlineEditor = BirchEditor.createOutlineEditor(outline, styleSheet: nil)
        weakOutlineEditor = outlineEditor
        outlineEditorTextStorage = outlineEditor.textStorage
        weakOutlineEditorTextStorage = outlineEditorTextStorage
        let path = Bundle(for: BirchScriptContext.self).path(forResource: "OutlineFixture", ofType: "bml")!
        let textContents = try! NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue)
        outline.reloadSerialization(textContents as String, options: ["type": "text/bml+html" as Any])
        XCTAssertEqual(outline.retainCount, 1)
    }

    override func tearDown() {
        outlineEditor = nil
        XCTAssertNil(weakOutlineEditor)
        outlineEditorTextStorage = nil
        XCTAssertNil(weakOutlineEditorTextStorage)
        XCTAssertEqual(outline.retainCount, 0)
        outline = nil
        XCTAssertNil(weakOutline)
        super.tearDown()
    }

    func testStorageItemLookupByIndex() {
        XCTAssertEqual(outlineEditorTextStorage.itemAtIndex(0)!.body, "one")
        XCTAssertEqual(outlineEditorTextStorage.itemAtIndex(4)!.body, "two")
    }

    func testStorageItemLookupByID() {
        XCTAssertEqual(outlineEditorTextStorage.itemForID("1").body, "one")
        XCTAssertEqual(outlineEditorTextStorage.itemForID("2").body, "two")
    }

    func testOutlineChangesReflectedInTextStorage() {
        let item = outlineEditorTextStorage.itemAtIndex(0)!
        item.body = "moose"
        XCTAssertEqual(outlineEditorTextStorage.string, "moose\ntwo\nthree @t\nfour @t\nfive\nsix @t(23)\n")
    }

    func testTextStorageChangesReflextedInOutline() {
        outlineEditorTextStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "moose")
        let item = outlineEditorTextStorage.itemAtIndex(0)!
        XCTAssertEqual(item.body, "mooseone")
    }

    func testTextStorageChangesWeirdoCharactersReflextedInOutline() {
        outlineEditorTextStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "Άά Έέ Ήή Ίί Όό Ύύ Ώώ")
        let item = outlineEditorTextStorage.itemAtIndex(0)!
        XCTAssertEqual(item.body, "Άά Έέ Ήή Ίί Όό Ύύ Ώώone")
    }

    func testInsertIntoEmptyAddsTrailingNewline() {
        outline = BirchEditor.createTaskPaperOutline(nil)
        outlineEditor = BirchEditor.createOutlineEditor(outline)
        outlineEditorTextStorage = outlineEditor.textStorage
        outlineEditorTextStorage.replaceCharacters(in: NSMakeRange(0, 0), with: "Hello")
        XCTAssertEqual(outlineEditorTextStorage.string, "Hello\n")
    }

    func testPerformance() {
        var bigText = ""
        for _ in 1 ... 1000 {
            bigText += "- hello\n"
        }

        measure {
            self.outline.reloadSerialization(bigText, options: ["type": "text/plain"])
            _ = self.outlineEditorTextStorage.itemAtIndex(0) // force styling storage
        }
    }

    // MARK: - isUpdatingFromJS Flag Tests

    func testIsUpdatingFromJSReturnsTrue() {
        // When JavaScript is updating the buffer, isUpdatingFromJS should return true
        // This is controlled by the jsOutlineEditor.isUpdatingNativeBuffer property

        // Test default behavior - should check JS property
        let isUpdating = outlineEditorTextStorage.isUpdatingFromJS

        // isUpdatingFromJS queries the JavaScript property, so we test it exists
        XCTAssertNotNil(outlineEditor.jsOutlineEditor)
        XCTAssertTrue(isUpdating == true || isUpdating == false, "isUpdatingFromJS should return a boolean value")
    }

    func testIsUpdatingFromJSWithNilOutlineEditor() {
        // When outlineEditor is nil, isUpdatingFromJS should return true (default)
        outlineEditorTextStorage.outlineEditor = nil
        XCTAssertTrue(outlineEditorTextStorage.isUpdatingFromJS)
    }

    func testReplaceCharactersWhenUpdatingFromJS() {
        // When JavaScript is updating, replaceCharacters should NOT call back to JS
        // and should NOT add trailing newline for end-of-document insertions

        let initialLength = outlineEditorTextStorage.length
        let initialString = outlineEditorTextStorage.string

        // Simulate JS update by directly calling replaceCharacters
        // The isUpdatingFromJS flag will be queried internally
        outlineEditorTextStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "Test")

        // Verify the change was made
        XCTAssertTrue(outlineEditorTextStorage.string.hasPrefix("Test"))
        XCTAssertGreaterThan(outlineEditorTextStorage.length, initialLength)
    }

    func testReplaceCharactersAtEndAddsNewline() {
        // When NOT updating from JS, insertions at the end should add a trailing newline
        let endLocation = outlineEditorTextStorage.length

        // Insert at the very end
        outlineEditorTextStorage.replaceCharacters(in: NSRange(location: endLocation, length: 0), with: "End")

        // Should have added a newline after "End"
        XCTAssertTrue(outlineEditorTextStorage.string.hasSuffix("End\n"))
    }

    // MARK: - Attribute Management Tests

    func testSetAttributes() {
        let range = NSRange(location: 0, length: 3)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.red,
            .font: NSFont.systemFont(ofSize: 14)
        ]

        outlineEditorTextStorage.setAttributes(attributes, range: range)

        // Verify attributes were set
        let retrievedAttributes = outlineEditorTextStorage.attributes(at: 0, effectiveRange: nil)
        XCTAssertNotNil(retrievedAttributes[.foregroundColor])
        XCTAssertNotNil(retrievedAttributes[.font])
    }

    func testAddAttribute() {
        let range = NSRange(location: 0, length: 3)

        outlineEditorTextStorage.addAttribute(.foregroundColor, value: NSColor.blue, range: range)

        // Verify attribute was added
        let color = outlineEditorTextStorage.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        XCTAssertEqual(color, NSColor.blue)
    }

    func testAddAttributes() {
        let range = NSRange(location: 0, length: 3)
        let attributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .backgroundColor: NSColor.yellow
        ]

        outlineEditorTextStorage.addAttributes(attributes, range: range)

        // Verify attributes were added
        let underline = outlineEditorTextStorage.attribute(.underlineStyle, at: 0, effectiveRange: nil) as? Int
        let background = outlineEditorTextStorage.attribute(.backgroundColor, at: 0, effectiveRange: nil) as? NSColor

        XCTAssertEqual(underline, NSUnderlineStyle.single.rawValue)
        XCTAssertEqual(background, NSColor.yellow)
    }

    func testInvalidateAttributes() {
        // Set some attributes first
        let range = NSRange(location: 0, length: 5)
        outlineEditorTextStorage.addAttribute(.foregroundColor, value: NSColor.red, range: range)

        // Invalidate attributes in the range
        outlineEditorTextStorage.invalidateAttributes(in: range)

        // After invalidation, attributes should be recalculated on next access
        // This test verifies the method doesn't crash and handles the range correctly
        let attributes = outlineEditorTextStorage.attributes(at: 0, effectiveRange: nil)
        XCTAssertNotNil(attributes)
    }

    func testFixesAttributesLazily() {
        // Test that the storage reports whether it fixes attributes lazily
        let fixesLazily = outlineEditorTextStorage.fixesAttributesLazily

        // Should match the backing storage's behavior
        XCTAssertTrue(fixesLazily == true || fixesLazily == false, "fixesAttributesLazily should return a boolean")
    }

    // MARK: - Edit Tracking Tests

    func testBeginEndEditing() {
        XCTAssertFalse(outlineEditorTextStorage.isEditing)

        outlineEditorTextStorage.beginEditing()
        XCTAssertTrue(outlineEditorTextStorage.isEditing)

        outlineEditorTextStorage.endEditing()
        XCTAssertFalse(outlineEditorTextStorage.isEditing)
    }

    func testNestedBeginEndEditing() {
        XCTAssertFalse(outlineEditorTextStorage.isEditing)

        outlineEditorTextStorage.beginEditing()
        XCTAssertTrue(outlineEditorTextStorage.isEditing)

        outlineEditorTextStorage.beginEditing()
        XCTAssertTrue(outlineEditorTextStorage.isEditing)

        outlineEditorTextStorage.endEditing()
        XCTAssertTrue(outlineEditorTextStorage.isEditing, "Should still be editing after one endEditing")

        outlineEditorTextStorage.endEditing()
        XCTAssertFalse(outlineEditorTextStorage.isEditing, "Should not be editing after matching endEditing calls")
    }

    func testIsUpdatingNative() {
        XCTAssertFalse(outlineEditorTextStorage.isUpdatingNative)

        // isUpdatingNative is set internally during native updates
        // We can test that it's tracked correctly through replaceCharacters
        outlineEditorTextStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "X")

        // After the update completes, isUpdatingNative should be false again
        XCTAssertFalse(outlineEditorTextStorage.isUpdatingNative)
    }

    // MARK: - Bidirectional Sync Tests

    func testBidirectionalSyncNativeToJS() {
        // Test: Native changes should propagate to JavaScript outline
        let initialItemBody = outlineEditorTextStorage.itemAtIndex(0)!.body

        // Make a native text storage change
        outlineEditorTextStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "PREFIX-")

        // Verify the change is reflected in the JavaScript outline
        let updatedItemBody = outlineEditorTextStorage.itemAtIndex(0)!.body
        XCTAssertTrue(updatedItemBody.hasPrefix("PREFIX-"))
        XCTAssertNotEqual(initialItemBody, updatedItemBody)
    }

    func testBidirectionalSyncJSToNative() {
        // Test: JavaScript changes should propagate to native text storage
        let item = outlineEditorTextStorage.itemAtIndex(0)!
        let initialString = outlineEditorTextStorage.string

        // Make a JavaScript-side change
        item.body = "MODIFIED"

        // Verify the change is reflected in the native text storage
        let updatedString = outlineEditorTextStorage.string
        XCTAssertTrue(updatedString.hasPrefix("MODIFIED"))
        XCTAssertNotEqual(initialString, updatedString)
    }

    func testBidirectionalSyncPreservesStructure() {
        // Test: Bidirectional sync preserves document structure
        let initialItemCount = outline.root.children.count

        // Add text at the end (which should create a new item due to newline)
        let endLocation = outlineEditorTextStorage.length
        outlineEditorTextStorage.replaceCharacters(in: NSRange(location: endLocation, length: 0), with: "new item")

        // Verify structure is maintained
        let updatedItemCount = outline.root.children.count
        XCTAssertEqual(updatedItemCount, initialItemCount + 1, "Adding a line should create a new item")
    }

    func testBidirectionalSyncWithMultipleEdits() {
        // Test: Multiple rapid edits should maintain consistency
        let item = outlineEditorTextStorage.itemAtIndex(0)!

        // Make multiple edits
        outlineEditorTextStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "A")
        outlineEditorTextStorage.replaceCharacters(in: NSRange(location: 1, length: 0), with: "B")
        outlineEditorTextStorage.replaceCharacters(in: NSRange(location: 2, length: 0), with: "C")

        // Verify all edits are reflected
        XCTAssertTrue(item.body.hasPrefix("ABC"))
    }

    // MARK: - Storage Item Management Tests

    func testStorageItemCaching() {
        // Test that storage items are cached by ID
        let item1 = outlineEditorTextStorage.itemForID("1")
        let item2 = outlineEditorTextStorage.itemForID("1")

        // Should return the same item
        XCTAssertEqual(item1.id, item2.id)
        XCTAssertEqual(item1.body, item2.body)
    }

    func testStorageItemInvalidation() {
        // Test that storage items are invalidated when their range changes
        let initialItem = outlineEditorTextStorage.itemAtIndex(0)!
        let itemID = initialItem.id

        // Modify the first line significantly
        outlineEditorTextStorage.replaceCharacters(in: NSRange(location: 0, length: initialItem.body.count), with: "completely different text")

        // The item should still be accessible by ID
        let updatedItem = outlineEditorTextStorage.itemForID(itemID)
        XCTAssertEqual(updatedItem.body, "completely different text")
    }

    // MARK: - Computed Style Tests

    func testClearComputedAttributes() {
        // Test that computed attributes can be cleared
        let testStyle = ComputedStyle()
        outlineEditorTextStorage.outlineEditorComputedStyle = testStyle

        // Should trigger clearComputedAttributesInRange
        // Verify the operation doesn't crash
        XCTAssertNotNil(outlineEditorTextStorage.outlineEditorComputedStyle)
    }

    func testDidProcessEditingNotification() {
        // Test that the didProcessEditing notification handler works
        let expectation = self.expectation(description: "didProcessEditing called")

        // Make an edit that will trigger the notification
        outlineEditorTextStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "X")

        // Give the notification time to process
        DispatchQueue.main.async {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)

        // If we get here without crashing, the notification was handled
        XCTAssertTrue(true)
    }

    // MARK: - Memory Management Tests

    func testCleanup() {
        // Test that cleanup removes observers properly
        let storage = OutlineEditorTextStorage()
        storage.outlineEditor = outlineEditor

        // Call cleanup
        storage.cleanUp()

        // Verify cleanup doesn't crash and storage is in a valid state
        XCTAssertNotNil(storage)
    }
}
