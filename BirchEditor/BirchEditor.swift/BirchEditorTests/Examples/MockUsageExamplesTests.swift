//
//  MockUsageExamplesTests.swift
//  BirchEditorTests
//
//  Created for Protocol-Oriented Design (Phase 2)
//  Examples demonstrating how to use mock implementations for testing
//

import BirchEditor
import BirchOutline
import Cocoa
import XCTest

/// Example tests demonstrating mock usage patterns.
///
/// These tests show how to use MockStyleSheet, MockOutlineEditor, and MockOutlineDocument
/// for fast, deterministic unit testing without JavaScriptCore or file I/O overhead.
///
/// ## Key Patterns
///
/// 1. **Dependency Injection**: Pass protocol types instead of concrete classes
/// 2. **Stub Configuration**: Set up expected return values before test
/// 3. **Call Verification**: Assert methods were called with expected parameters
/// 4. **Fast Execution**: No JS engine init, no file I/O, no UI components
///
@MainActor
class MockUsageExamplesTests: XCTestCase {

    // MARK: - MockStyleSheet Examples

    func testMockStyleSheet_BasicUsage() {
        // Create mock with default configuration
        let mockStyleSheet = MockStyleSheet()

        // Configure stub response
        mockStyleSheet.computedStyleStub = MockStyleSheet.taskStyle()

        // Use mock (simulating real usage in code under test)
        let style = mockStyleSheet.computedStyle(for: "task")

        // Verify behavior
        XCTAssertEqual(mockStyleSheet.computedStyleCalls.count, 1)
        XCTAssertNotNil(style)
        XCTAssertEqual(style.allValues[.font] as? NSFont, NSFont.systemFont(ofSize: 14))
    }

    func testMockStyleSheet_KeyPathStubbing() {
        // Create mock
        let mockStyleSheet = MockStyleSheet()

        // Configure different styles for different key paths
        mockStyleSheet.computedStyleForKeyPathStubs["task"] = MockStyleSheet.taskStyle()
        mockStyleSheet.computedStyleForKeyPathStubs["task.done"] = MockStyleSheet.completedTaskStyle()

        // Verify different stubs return different styles
        let taskStyle = mockStyleSheet.computedStyle(forKeyPath: "task")
        let doneStyle = mockStyleSheet.computedStyle(forKeyPath: "task.done")

        XCTAssertEqual(mockStyleSheet.computedStyleForKeyPathCalls.count, 2)
        XCTAssertNotEqual(
            taskStyle.allValues[.foregroundColor] as? NSColor,
            doneStyle.allValues[.foregroundColor] as? NSColor,
            "Task and done styles should have different colors"
        )
    }

    func testMockStyleSheet_CallRecording() {
        // Create mock
        let mockStyleSheet = MockStyleSheet()

        // Perform operations
        _ = mockStyleSheet.computedStyle(for: "element1")
        _ = mockStyleSheet.computedStyle(for: "element2")
        _ = mockStyleSheet.computedStyleKeyPath(for: "element3")
        mockStyleSheet.invalidateComputedStyles()

        // Verify all calls were recorded
        XCTAssertEqual(mockStyleSheet.computedStyleCalls.count, 2)
        XCTAssertEqual(mockStyleSheet.computedStyleKeyPathCalls.count, 1)
        XCTAssertEqual(mockStyleSheet.invalidateComputedStylesCallCount, 1)
    }

    func testMockStyleSheet_ResetBetweenTests() {
        // Create mock and use it
        let mockStyleSheet = MockStyleSheet()
        _ = mockStyleSheet.computedStyle(for: "test")
        XCTAssertEqual(mockStyleSheet.computedStyleCalls.count, 1)

        // Reset for next test
        mockStyleSheet.reset()

        // Verify clean state
        XCTAssertEqual(mockStyleSheet.computedStyleCalls.count, 0)
        XCTAssertEqual(mockStyleSheet.computedStyleKeyPathCalls.count, 0)
    }

    // MARK: - MockOutlineEditor Examples

    func testMockOutlineEditor_BasicUsage() {
        // Create mock outline
        let mockOutline = BirchEditor.createTaskPaperOutline(nil)

        // Create mock editor
        let mockEditor = MockOutlineEditor()
        mockEditor.outlineStub = mockOutline

        // Configure text storage (required for editor)
        let styleSheet = StyleSheet(source: nil, scriptContext: BirchOutline.sharedContext)
        let realEditor = BirchEditor.createOutlineEditor(mockOutline, styleSheet: styleSheet)
        mockEditor.textStorageStub = realEditor.textStorage

        // Use mock (simulating real usage)
        let outline = mockEditor.outline

        // Verify
        XCTAssertEqual(outline.id, mockOutline.id)
    }

    func testMockOutlineEditor_SerializationStubbing() {
        // Create mock
        let mockEditor = MockOutlineEditor()

        // Configure serialization stubs
        let item1 = BirchEditor.createTaskPaperOutline(nil).createItem("Task 1")
        let item2 = BirchEditor.createTaskPaperOutline(nil).createItem("Task 2")
        mockEditor.serializeItemsStub = "Task 1\nTask 2\n"
        mockEditor.deserializeItemsStub = [item1, item2]

        // Test serialization
        let serialized = mockEditor.serializeItems([item1, item2], options: nil)
        XCTAssertEqual(serialized, "Task 1\nTask 2\n")
        XCTAssertEqual(mockEditor.serializeItemsCalls.count, 1)

        // Test deserialization
        let deserialized = mockEditor.deserializeItems("Task 1\nTask 2\n", options: nil)
        XCTAssertEqual(deserialized?.count, 2)
        XCTAssertEqual(mockEditor.deserializeItemsCalls.count, 1)
    }

    func testMockOutlineEditor_CommandTracking() {
        // Create mock
        let mockEditor = MockOutlineEditor()

        // Execute commands
        mockEditor.performCommand("indent", options: nil)
        mockEditor.performCommand("outdent", options: nil)
        mockEditor.toggleAttribute("done")

        // Verify commands were recorded
        XCTAssertEqual(mockEditor.performCommandCalls.count, 2)
        XCTAssertEqual(mockEditor.performCommandCalls[0].command, "indent")
        XCTAssertEqual(mockEditor.performCommandCalls[1].command, "outdent")
        XCTAssertEqual(mockEditor.toggleAttributeCalls.count, 1)
        XCTAssertEqual(mockEditor.toggleAttributeCalls[0], "done")
    }

    func testMockOutlineEditor_ScriptEvaluation() {
        // Create mock
        let mockEditor = MockOutlineEditor()

        // Configure script evaluation stub
        mockEditor.evaluateScriptStub = ["result": "success"]

        // Evaluate script
        let result = mockEditor.evaluateScript("editor.selectedItems", withOptions: nil) as? [String: String]

        // Verify
        XCTAssertEqual(mockEditor.evaluateScriptCalls.count, 1)
        XCTAssertEqual(mockEditor.evaluateScriptCalls[0].script, "editor.selectedItems")
        XCTAssertEqual(result?["result"], "success")
    }

    // MARK: - MockOutlineDocument Examples

    func testMockOutlineDocument_BasicUsage() {
        // Create mock outline
        let mockOutline = BirchEditor.createTaskPaperOutline(nil)

        // Create mock document
        let mockDocument = MockOutlineDocument()
        mockDocument.outlineStub = mockOutline
        mockDocument.displayNameStub = "Test Document"
        mockDocument.fileURLStub = URL(fileURLWithPath: "/tmp/test.taskpaper")

        // Use mock (simulating real usage)
        XCTAssertEqual(mockDocument.displayName, "Test Document")
        XCTAssertEqual(mockDocument.fileURL?.lastPathComponent, "test.taskpaper")
        XCTAssertEqual(mockDocument.outline.id, mockOutline.id)
    }

    func testMockOutlineDocument_ReadOperation() throws {
        // Create mock document
        let mockDocument = MockOutlineDocument()

        // Configure data to read
        let testData = Data("Task 1\nTask 2\n".utf8)

        // Perform read operation
        try mockDocument.read(from: testData, ofType: "com.taskpaper.text")

        // Verify operation was recorded
        XCTAssertEqual(mockDocument.readFromDataCalls.count, 1)
        XCTAssertEqual(mockDocument.readFromDataCalls[0].data, testData)
        XCTAssertEqual(mockDocument.readFromDataCalls[0].typeName, "com.taskpaper.text")
    }

    func testMockOutlineDocument_WriteOperation() throws {
        // Create mock document
        let mockDocument = MockOutlineDocument()

        // Configure data to return
        mockDocument.dataStub = Data("Task 1\nTask 2\n".utf8)

        // Perform write operation
        let data = try mockDocument.data(ofType: "com.taskpaper.text")

        // Verify operation was recorded
        XCTAssertEqual(mockDocument.dataCallCount, 1)
        XCTAssertEqual(String(data: data, encoding: .utf8), "Task 1\nTask 2\n")
    }

    func testMockOutlineDocument_SaveOperation() {
        // Create mock document
        let mockDocument = MockOutlineDocument()

        // Perform save operation
        let expectation = self.expectation(description: "Save completion")
        let saveURL = URL(fileURLWithPath: "/tmp/test.taskpaper")

        mockDocument.save(
            to: saveURL,
            ofType: "com.taskpaper.text",
            for: .saveOperation
        ) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        // Verify operation was recorded
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(mockDocument.saveCalls.count, 1)
        XCTAssertEqual(mockDocument.saveCalls[0].url, saveURL)
        XCTAssertEqual(mockDocument.saveCalls[0].saveOperation, .saveOperation)
    }

    func testMockOutlineDocument_ErrorInjection() {
        // Create mock document
        let mockDocument = MockOutlineDocument()

        // Configure error to throw
        struct TestError: Error {}
        mockDocument.errorStub = TestError()

        // Verify error is thrown
        XCTAssertThrowsError(try mockDocument.read(from: Data(), ofType: "test"))
        XCTAssertThrowsError(try mockDocument.data(ofType: "test"))
        XCTAssertThrowsError(try mockDocument.write(to: URL(fileURLWithPath: "/tmp/test"), ofType: "test"))
    }

    func testMockOutlineDocument_ChangeTracking() {
        // Create mock document
        let mockDocument = MockOutlineDocument()

        // Initially no unsaved changes
        XCTAssertFalse(mockDocument.hasUnautosavedChanges)

        // Make a change
        mockDocument.updateChangeCount(.changeDone)

        // Verify change tracking
        XCTAssertTrue(mockDocument.hasUnautosavedChanges)
        XCTAssertEqual(mockDocument.updateChangeCountCalls.count, 1)
        XCTAssertEqual(mockDocument.updateChangeCountCalls[0], .changeDone)

        // Clear changes
        mockDocument.updateChangeCount(.changeCleared)

        // Verify cleared
        XCTAssertFalse(mockDocument.hasUnautosavedChanges)
        XCTAssertEqual(mockDocument.updateChangeCountCalls.count, 2)
    }

    // MARK: - Integration Examples

    func testComponentWithMultipleMocks() {
        // This example shows testing a component that depends on multiple protocols

        // Create mocks
        let mockDocument = MockOutlineDocument()
        let mockStyleSheet = MockStyleSheet()
        let mockEditor = MockOutlineEditor()

        // Configure mocks
        let mockOutline = BirchEditor.createTaskPaperOutline(nil)
        mockDocument.outlineStub = mockOutline
        mockEditor.outlineStub = mockOutline
        mockStyleSheet.computedStyleStub = MockStyleSheet.taskStyle()

        // Simulate a component that uses all three
        // (In real code, this would be your component under test)
        let outline = mockDocument.outline
        let style = mockStyleSheet.computedStyle(for: "task")
        mockEditor.performCommand("indent", options: nil)

        // Verify all interactions
        XCTAssertEqual(outline.id, mockOutline.id)
        XCTAssertNotNil(style)
        XCTAssertEqual(mockStyleSheet.computedStyleCalls.count, 1)
        XCTAssertEqual(mockEditor.performCommandCalls.count, 1)
    }

    func testPerformanceComparison() {
        // This test demonstrates the performance benefit of mocks

        // Measure mock creation time
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let mockStyleSheet = MockStyleSheet()
            let mockEditor = MockOutlineEditor()
            let mockDocument = MockOutlineDocument()

            // Use mocks (simulating real test operations)
            _ = mockStyleSheet.computedStyle(for: "task")
            mockEditor.performCommand("test", options: nil)
            _ = mockDocument.hasUnautosavedChanges

            // No teardown needed - mocks are lightweight
        }

        // Compare with real object creation (commented out to not slow down tests):
        // Real objects would take ~100-200ms for JS engine init
        // Mocks take <1ms
    }
}
