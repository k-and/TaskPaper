//
//  OutlineDocumentTests.swift
//  Birch
//
//  Created by Jesse Grosjean on 8/22/16.
//
//

import BirchOutline
@preconcurrency import JavaScriptCore
@testable import TaskPaper
import XCTest

class OutlineDocument: XCTestCase {
    var document: TaskPaperDocument?
    weak var weakDocument: TaskPaperDocument?

    override func setUp() {
        super.setUp()
        autoreleasepool {
            document = try! NSDocumentController.shared().makeUntitledDocument(ofType: "com.taskpaper.text") as? TaskPaperDocument
        }
        weakDocument = document
    }

    override func tearDown() {
        autoreleasepool {
            document?.close()
            document = nil
        }

        let expectation = self.expectation(description: "Should Deinit")
        Task { @MainActor in
            await delay(0)
            while self.weakDocument != nil {
                RunLoop.current.run(until: NSDate(timeIntervalSinceNow: 0.1) as Date)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("Error: \(error.localizedDescription)")
            }
        }

        XCTAssertNil(weakDocument)

        super.tearDown()
    }

    func testCreateDocument() {
        XCTAssertNotNil(document)
        XCTAssertNil(document?.undoManager)
        XCTAssertFalse(document!.hasUnautosavedChanges)
        XCTAssertFalse(document!.isDocumentEdited)
    }

    func testInsertText() {
        let item = document?.outline.createItem("Hello world")
        document?.outline.root.appendChildren([item!])
        XCTAssertTrue(document!.hasUnautosavedChanges)
        XCTAssertTrue(document!.isDocumentEdited)
    }

    func testSave() {
        autoreleasepool {
            let item = document?.outline.createItem("Hello world")
            let expectation = self.expectation(description: "Should Save")
            document?.outline.root.appendChildren([item!])
            let url = URL(fileURLWithPath: "\(NSTemporaryDirectory())/test.taskpaper")

            document?.save(to: url, ofType: "com.taskpaper.text", for: .saveOperation, completionHandler: { _ in
                XCTAssertFalse(self.document!.isDocumentEdited)
                XCTAssertFalse(self.document!.hasUnautosavedChanges)
                expectation.fulfill()
            })

            waitForExpectations(timeout: 1.0) { error in
                if let error = error {
                    XCTFail("Error: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Document Load/Save Integration Tests

    func testLoadWelcomeDocument() {
        // Test loading the Welcome.txt document
        guard let welcomeURL = Bundle.main.url(forResource: "Welcome", withExtension: "txt") else {
            XCTFail("Welcome.txt not found in bundle")
            return
        }

        guard let welcomeText = try? String(contentsOf: welcomeURL, encoding: .utf8) else {
            XCTFail("Failed to read Welcome.txt")
            return
        }

        guard let data = welcomeText.data(using: .utf8) else {
            XCTFail("Failed to convert Welcome.txt to data")
            return
        }

        do {
            try document?.read(from: data, ofType: "com.taskpaper.text")
            XCTAssertNotNil(document?.outline)
            XCTAssertGreaterThan(document?.outline.root.children.count ?? 0, 0, "Welcome.txt should have items")
        } catch {
            XCTFail("Failed to load Welcome.txt: \(error)")
        }
    }

    func testParseTaskPaperProjects() {
        // Test parsing TaskPaper projects (lines ending with :)
        let taskPaperText = """
        Project One:
        Project Two:
            Nested Project:
        """

        guard let data = taskPaperText.data(using: .utf8) else {
            XCTFail("Failed to convert text to data")
            return
        }

        do {
            try document?.read(from: data, ofType: "com.taskpaper.text")

            let items = document?.outline.root.children ?? []
            XCTAssertGreaterThanOrEqual(items.count, 2, "Should have at least 2 projects")

            // Check that projects are identified
            if items.count >= 2 {
                XCTAssertTrue(items[0].hasAttribute("data-type", value: "project"), "First item should be a project")
                XCTAssertTrue(items[1].hasAttribute("data-type", value: "project"), "Second item should be a project")
            }
        } catch {
            XCTFail("Failed to parse projects: \(error)")
        }
    }

    func testParseTaskPaperTasks() {
        // Test parsing TaskPaper tasks (lines starting with -)
        let taskPaperText = """
        - Task one
        - Task two
        - Task three @tag
        """

        guard let data = taskPaperText.data(using: .utf8) else {
            XCTFail("Failed to convert text to data")
            return
        }

        do {
            try document?.read(from: data, ofType: "com.taskpaper.text")

            let items = document?.outline.root.children ?? []
            XCTAssertGreaterThanOrEqual(items.count, 3, "Should have at least 3 tasks")

            // Check that tasks are identified
            if items.count >= 3 {
                XCTAssertTrue(items[0].hasAttribute("data-type", value: "task"), "First item should be a task")
                XCTAssertTrue(items[1].hasAttribute("data-type", value: "task"), "Second item should be a task")
                XCTAssertTrue(items[2].hasAttribute("data-type", value: "task"), "Third item should be a task")
            }
        } catch {
            XCTFail("Failed to parse tasks: \(error)")
        }
    }

    func testParseTaskPaperTags() {
        // Test parsing TaskPaper tags (@tagname)
        let taskPaperText = """
        - Task with @tag1
        - Task with @tag2(value)
        - Task with @priority(high) and @due(2025-12-31)
        """

        guard let data = taskPaperText.data(using: .utf8) else {
            XCTFail("Failed to convert text to data")
            return
        }

        do {
            try document?.read(from: data, ofType: "com.taskpaper.text")

            let items = document?.outline.root.children ?? []
            XCTAssertGreaterThanOrEqual(items.count, 3, "Should have at least 3 items")

            if items.count >= 3 {
                // First item should have @tag1
                XCTAssertTrue(items[0].hasAttribute("data-tag1"), "First item should have @tag1")

                // Second item should have @tag2 with value
                XCTAssertTrue(items[1].hasAttribute("data-tag2"), "Second item should have @tag2")

                // Third item should have multiple tags
                XCTAssertTrue(items[2].hasAttribute("data-priority"), "Third item should have @priority")
                XCTAssertTrue(items[2].hasAttribute("data-due"), "Third item should have @due")
            }
        } catch {
            XCTFail("Failed to parse tags: \(error)")
        }
    }

    func testDocumentRoundTrip() {
        // Test that a document can be saved and loaded without data loss
        let taskPaperText = """
        My Project:
            - Task one
            - Task two @done
            Subproject:
                - Nested task @priority(high)
        Another Project:
            - Another task
        """

        guard let originalData = taskPaperText.data(using: .utf8) else {
            XCTFail("Failed to convert text to data")
            return
        }

        do {
            // Load the document
            try document?.read(from: originalData, ofType: "com.taskpaper.text")

            // Save the document to data
            let savedData = try document?.data(ofType: "com.taskpaper.text")
            XCTAssertNotNil(savedData, "Should be able to serialize document")

            // Create a new document and load the saved data
            let roundTripDocument = try! NSDocumentController.shared().makeUntitledDocument(ofType: "com.taskpaper.text") as? TaskPaperDocument
            try roundTripDocument?.read(from: savedData!, ofType: "com.taskpaper.text")

            // Compare structure
            let originalItemCount = document?.outline.root.descendants().count ?? 0
            let roundTripItemCount = roundTripDocument?.outline.root.descendants().count ?? 0

            XCTAssertEqual(originalItemCount, roundTripItemCount, "Round-trip should preserve item count")

            // Clean up
            roundTripDocument?.close()
        } catch {
            XCTFail("Round-trip test failed: \(error)")
        }
    }

    func testDocumentRoundTripWithWelcome() {
        // Test round-trip with the actual Welcome.txt file
        guard let welcomeURL = Bundle.main.url(forResource: "Welcome", withExtension: "txt") else {
            XCTFail("Welcome.txt not found in bundle")
            return
        }

        guard let welcomeText = try? String(contentsOf: welcomeURL, encoding: .utf8),
              let originalData = welcomeText.data(using: .utf8) else {
            XCTFail("Failed to read Welcome.txt")
            return
        }

        do {
            // Load Welcome.txt
            try document?.read(from: originalData, ofType: "com.taskpaper.text")

            let originalItemCount = document?.outline.root.descendants().count ?? 0
            XCTAssertGreaterThan(originalItemCount, 0, "Welcome.txt should have items")

            // Save and reload
            let savedData = try document?.data(ofType: "com.taskpaper.text")
            XCTAssertNotNil(savedData)

            let roundTripDocument = try! NSDocumentController.shared().makeUntitledDocument(ofType: "com.taskpaper.text") as? TaskPaperDocument
            try roundTripDocument?.read(from: savedData!, ofType: "com.taskpaper.text")

            let roundTripItemCount = roundTripDocument?.outline.root.descendants().count ?? 0
            XCTAssertEqual(originalItemCount, roundTripItemCount, "Welcome.txt round-trip should preserve all items")

            // Clean up
            roundTripDocument?.close()
        } catch {
            XCTFail("Welcome.txt round-trip failed: \(error)")
        }
    }

    func testParseComplexHierarchy() {
        // Test parsing complex nested structure
        let taskPaperText = """
        Top Level Project:
            - Task 1
            - Task 2 @done
            Middle Level Project:
                - Nested task
                    Note: This is a note under the task
                Deep Level Project:
                    - Very nested task @priority(high)
        """

        guard let data = taskPaperText.data(using: .utf8) else {
            XCTFail("Failed to convert text to data")
            return
        }

        do {
            try document?.read(from: data, ofType: "com.taskpaper.text")

            let items = document?.outline.root.children ?? []
            XCTAssertGreaterThan(items.count, 0, "Should have top-level items")

            // Verify hierarchy is preserved
            if let topProject = items.first {
                XCTAssertTrue(topProject.hasAttribute("data-type", value: "project"))
                XCTAssertGreaterThan(topProject.children.count, 0, "Top project should have children")
            }
        } catch {
            XCTFail("Failed to parse complex hierarchy: \(error)")
        }
    }

    func testParseMixedContent() {
        // Test parsing a document with projects, tasks, notes, and tags mixed together
        let taskPaperText = """
        Project A:
            - Task 1 @tag1
            Regular note line
            - Task 2 @tag2(value) @done
            Another note
        Project B:
            - Task 3
        """

        guard let data = taskPaperText.data(using: .utf8) else {
            XCTFail("Failed to convert text to data")
            return
        }

        do {
            try document?.read(from: data, ofType: "com.taskpaper.text")

            let items = document?.outline.root.children ?? []
            XCTAssertGreaterThanOrEqual(items.count, 2, "Should have at least 2 projects")

            // Verify mixed content is parsed correctly
            if items.count >= 2 {
                XCTAssertTrue(items[0].hasAttribute("data-type", value: "project"), "First item should be Project A")
                XCTAssertTrue(items[1].hasAttribute("data-type", value: "project"), "Second item should be Project B")

                // Project A should have children
                XCTAssertGreaterThan(items[0].children.count, 0, "Project A should have children")
            }
        } catch {
            XCTFail("Failed to parse mixed content: \(error)")
        }
    }

    func testSaveAndLoadPreservesAttributes() {
        // Test that saving and loading preserves item attributes
        let item1 = document?.outline.createItem("Task with tag")
        item1?.setAttribute("data-priority", value: "high")
        item1?.setAttribute("data-done", value: "")

        document?.outline.root.appendChildren([item1!])

        do {
            let savedData = try document?.data(ofType: "com.taskpaper.text")
            XCTAssertNotNil(savedData)

            // Create new document and load
            let newDocument = try! NSDocumentController.shared().makeUntitledDocument(ofType: "com.taskpaper.text") as? TaskPaperDocument
            try newDocument?.read(from: savedData!, ofType: "com.taskpaper.text")

            // Check attributes are preserved
            let loadedItems = newDocument?.outline.root.children ?? []
            XCTAssertGreaterThan(loadedItems.count, 0, "Should have loaded items")

            if let loadedItem = loadedItems.first {
                XCTAssertTrue(loadedItem.hasAttribute("data-priority", value: "high"), "Should preserve @priority attribute")
                XCTAssertTrue(loadedItem.hasAttribute("data-done"), "Should preserve @done attribute")
            }

            // Clean up
            newDocument?.close()
        } catch {
            XCTFail("Failed to preserve attributes: \(error)")
        }
    }

    func testLoadEmptyDocument() {
        // Test loading an empty document
        let emptyText = ""
        guard let data = emptyText.data(using: .utf8) else {
            XCTFail("Failed to convert empty text to data")
            return
        }

        do {
            try document?.read(from: data, ofType: "com.taskpaper.text")
            XCTAssertNotNil(document?.outline)
            XCTAssertEqual(document?.outline.root.children.count ?? -1, 0, "Empty document should have no children")
        } catch {
            XCTFail("Failed to load empty document: \(error)")
        }
    }

    func testLoadDocumentWithUnicodeCharacters() {
        // Test loading document with various Unicode characters
        let unicodeText = """
        Άά Έέ Ήή Project:
            - Task with emoji 🎉 @done
            - Task with Chinese 中文字符
            - Task with Arabic العربية
        """

        guard let data = unicodeText.data(using: .utf8) else {
            XCTFail("Failed to convert Unicode text to data")
            return
        }

        do {
            try document?.read(from: data, ofType: "com.taskpaper.text")

            let items = document?.outline.root.children ?? []
            XCTAssertGreaterThan(items.count, 0, "Should parse Unicode content")

            // Verify Unicode is preserved
            if let project = items.first {
                XCTAssertTrue(project.body.contains("Άά Έέ Ήή"), "Should preserve Greek characters")
            }
        } catch {
            XCTFail("Failed to load Unicode document: \(error)")
        }
    }

    // MARK: - Performance Tests

    func testLoadPerformance() {
        // Test performance of loading a document
        guard let welcomeURL = Bundle.main.url(forResource: "Welcome", withExtension: "txt"),
              let welcomeText = try? String(contentsOf: welcomeURL, encoding: .utf8),
              let data = welcomeText.data(using: .utf8) else {
            XCTFail("Failed to read Welcome.txt")
            return
        }

        measure {
            do {
                try self.document?.read(from: data, ofType: "com.taskpaper.text")
            } catch {
                XCTFail("Failed to load in performance test: \(error)")
            }
        }
    }

    func testSavePerformance() {
        // Test performance of saving a document
        guard let welcomeURL = Bundle.main.url(forResource: "Welcome", withExtension: "txt"),
              let welcomeText = try? String(contentsOf: welcomeURL, encoding: .utf8),
              let data = welcomeText.data(using: .utf8) else {
            XCTFail("Failed to read Welcome.txt")
            return
        }

        do {
            try document?.read(from: data, ofType: "com.taskpaper.text")

            measure {
                do {
                    _ = try self.document?.data(ofType: "com.taskpaper.text")
                } catch {
                    XCTFail("Failed to save in performance test: \(error)")
                }
            }
        } catch {
            XCTFail("Failed to setup performance test: \(error)")
        }
    }
}
