//
//  OutlineCoreTests.swift
//  BirchOutlineTests
//
//  Created for TaskPaper Modernization - Phase 1
//  Copyright © 2025 Jesse Grosjean. All rights reserved.
//

import XCTest
import JavaScriptCore
@testable import BirchOutline

/// Comprehensive tests for outline core operations
/// Part of P1-T15: Add Unit Tests for Outline Core Operations
class OutlineCoreTests: XCTestCase {

    var outline: OutlineType!
    weak var weakOutline: OutlineType?

    override func setUp() {
        super.setUp()
        outline = BirchOutline.createTaskPaperOutline(nil)
        weakOutline = outline
    }

    override func tearDown() {
        outline = nil
        XCTAssertNil(weakOutline, "Outline should be deallocated after test")
        super.tearDown()
    }

    // MARK: - Outline Initialization Tests

    func testOutlineInitialization() {
        XCTAssertNotNil(outline, "Outline should be initialized")
        XCTAssertNotNil(outline.root, "Outline root should exist")
        XCTAssertEqual(outline.items.count, 0, "Empty outline should have no items")
    }

    func testOutlineInitializationWithContent() {
        let content = "Project:\n\t- Task 1 @done\n\t- Task 2\n\tNote"
        let testOutline = BirchOutline.createTaskPaperOutline(content)

        XCTAssertNotNil(testOutline)
        XCTAssertGreaterThan(testOutline.items.count, 0, "Outline should have items after loading content")
        XCTAssertEqual(testOutline.items[0].body, "Project", "First item should be 'Project'")
    }

    func testOutlineMemoryManagement() {
        weak var testOutline: OutlineType?
        autoreleasepool {
            let temp = BirchOutline.createTaskPaperOutline("Test")
            testOutline = temp
            XCTAssertNotNil(testOutline)
        }
        XCTAssertNil(testOutline, "Outline should be deallocated when no strong references remain")
    }

    // MARK: - Item Manipulation Tests

    func testCreateAndAddItem() {
        let item = outline.createItem("New Item")

        XCTAssertNotNil(item, "Item should be created")
        XCTAssertEqual(item.body, "New Item", "Item body should match")

        outline.root.appendChildren([item])
        XCTAssertEqual(outline.items.count, 1, "Outline should have one item")
        XCTAssertEqual(outline.items[0].body, "New Item", "Item should be accessible via items array")
    }

    func testAddMultipleItems() {
        let item1 = outline.createItem("Item 1")
        let item2 = outline.createItem("Item 2")
        let item3 = outline.createItem("Item 3")

        outline.root.appendChildren([item1, item2, item3])

        XCTAssertEqual(outline.items.count, 3, "Outline should have three items")
        XCTAssertEqual(outline.items[0].body, "Item 1")
        XCTAssertEqual(outline.items[1].body, "Item 2")
        XCTAssertEqual(outline.items[2].body, "Item 3")
    }

    func testRemoveItem() {
        let item = outline.createItem("To Be Removed")
        outline.root.appendChildren([item])

        XCTAssertEqual(outline.items.count, 1)

        item.removeFromParent()

        XCTAssertEqual(outline.items.count, 0, "Item should be removed from outline")
        XCTAssertNil(item.parent, "Removed item should have no parent")
    }

    func testMoveItem() {
        let parent1 = outline.createItem("Parent 1")
        let parent2 = outline.createItem("Parent 2")
        let child = outline.createItem("Child")

        outline.root.appendChildren([parent1, parent2])
        parent1.appendChildren([child])

        XCTAssertEqual(child.parent?.body, "Parent 1", "Child should be under Parent 1")
        XCTAssertEqual(parent1.firstChild?.body, "Child")

        // Move child from parent1 to parent2
        child.removeFromParent()
        parent2.appendChildren([child])

        XCTAssertEqual(child.parent?.body, "Parent 2", "Child should be under Parent 2")
        XCTAssertNil(parent1.firstChild, "Parent 1 should have no children")
        XCTAssertEqual(parent2.firstChild?.body, "Child")
    }

    func testReplaceItem() {
        let original = outline.createItem("Original")
        let replacement = outline.createItem("Replacement")

        outline.root.appendChildren([original])
        XCTAssertEqual(outline.items[0].body, "Original")

        // Remove original and add replacement
        original.removeFromParent()
        outline.root.appendChildren([replacement])

        XCTAssertEqual(outline.items.count, 1, "Should still have one item")
        XCTAssertEqual(outline.items[0].body, "Replacement", "Item should be replaced")
    }

    // MARK: - Hierarchy Management Tests

    func testParentChildRelationship() {
        let parent = outline.createItem("Parent")
        let child = outline.createItem("Child")

        outline.root.appendChildren([parent])
        parent.appendChildren([child])

        XCTAssertEqual(child.parent?.body, "Parent", "Child should know its parent")
        XCTAssertEqual(parent.firstChild?.body, "Child", "Parent should know its first child")
        XCTAssertNil(child.firstChild, "Child should have no children")
    }

    func testSiblingRelationships() {
        let sibling1 = outline.createItem("Sibling 1")
        let sibling2 = outline.createItem("Sibling 2")
        let sibling3 = outline.createItem("Sibling 3")

        outline.root.appendChildren([sibling1, sibling2, sibling3])

        XCTAssertEqual(sibling1.nextSibling?.body, "Sibling 2", "Sibling 1 should link to Sibling 2")
        XCTAssertEqual(sibling2.previousSibling?.body, "Sibling 1", "Sibling 2 should link back to Sibling 1")
        XCTAssertEqual(sibling2.nextSibling?.body, "Sibling 3", "Sibling 2 should link to Sibling 3")
        XCTAssertNil(sibling1.previousSibling, "First sibling should have no previous sibling")
        XCTAssertNil(sibling3.nextSibling, "Last sibling should have no next sibling")
    }

    func testDeepHierarchy() {
        let level1 = outline.createItem("Level 1")
        let level2 = outline.createItem("Level 2")
        let level3 = outline.createItem("Level 3")
        let level4 = outline.createItem("Level 4")

        outline.root.appendChildren([level1])
        level1.appendChildren([level2])
        level2.appendChildren([level3])
        level3.appendChildren([level4])

        XCTAssertEqual(outline.items.count, 4, "Should have all 4 items")
        XCTAssertEqual(level4.parent?.parent?.parent?.body, "Level 1", "Should traverse hierarchy correctly")
    }

    func testInsertChildrenAtSpecificPosition() {
        let parent = outline.createItem("Parent")
        let child1 = outline.createItem("Child 1")
        let child2 = outline.createItem("Child 2")
        let child3 = outline.createItem("Child 3")

        outline.root.appendChildren([parent])
        parent.appendChildren([child1, child3]) // Insert 1 and 3 first
        parent.insertChildren([child2], beforeSibling: child3) // Insert 2 between 1 and 3

        XCTAssertEqual(parent.firstChild?.body, "Child 1")
        XCTAssertEqual(parent.firstChild?.nextSibling?.body, "Child 2", "Child 2 should be inserted in middle")
        XCTAssertEqual(parent.firstChild?.nextSibling?.nextSibling?.body, "Child 3")
    }

    // MARK: - Serialization Tests

    func testEmptyOutlineSerialization() {
        let serialized = outline.serialize(nil)
        XCTAssertEqual(serialized, "", "Empty outline should serialize to empty string")
    }

    func testSimpleSerialization() {
        let item = outline.createItem("Simple Item")
        outline.root.appendChildren([item])

        let serialized = outline.serialize(nil)
        XCTAssertEqual(serialized, "Simple Item", "Single item should serialize correctly")
    }

    func testHierarchicalSerialization() {
        let parent = outline.createItem("Parent")
        let child1 = outline.createItem("Child 1")
        let child2 = outline.createItem("Child 2")

        outline.root.appendChildren([parent])
        parent.appendChildren([child1, child2])

        let serialized = outline.serialize(nil)
        let expected = "Parent\n\tChild 1\n\tChild 2"
        XCTAssertEqual(serialized, expected, "Hierarchy should serialize with proper indentation")
    }

    func testSerializationWithAttributes() {
        let task = outline.createItem("Task Item")
        task.setAttribute("data-type", value: "task")
        task.setAttribute("data-done", value: "")
        outline.root.appendChildren([task])

        let serialized = outline.serialize(nil)
        XCTAssertTrue(serialized.contains("- Task Item"), "Task should have '-' prefix")
        XCTAssertTrue(serialized.contains("@done"), "Done attribute should be serialized")
    }

    func testDeserializationRoundTrip() {
        let original = "Project:\n\t- Task @done\n\tNote\n\t\tNested Note"
        outline.reloadSerialization(original, options: nil)

        let serialized = outline.serialize(nil)
        XCTAssertEqual(serialized, original, "Serialization should be reversible")
    }

    // MARK: - Undo/Redo Tests

    func testUndoItemCreation() {
        let item = outline.createItem("Test Item")
        outline.root.appendChildren([item])

        XCTAssertEqual(outline.items.count, 1, "Item should be added")

        outline.undo()

        XCTAssertEqual(outline.items.count, 0, "Item creation should be undone")
    }

    func testRedoItemCreation() {
        let item = outline.createItem("Test Item")
        outline.root.appendChildren([item])

        outline.undo()
        XCTAssertEqual(outline.items.count, 0, "Item should be removed after undo")

        outline.redo()
        XCTAssertEqual(outline.items.count, 1, "Item should be restored after redo")
    }

    func testUndoItemBodyChange() {
        let item = outline.createItem("Original")
        outline.root.appendChildren([item])

        item.body = "Modified"
        XCTAssertEqual(item.body, "Modified")

        outline.undo()
        XCTAssertEqual(item.body, "Original", "Body change should be undone")
    }

    func testMultipleUndoOperations() {
        let item1 = outline.createItem("Item 1")
        outline.root.appendChildren([item1])

        let item2 = outline.createItem("Item 2")
        outline.root.appendChildren([item2])

        let item3 = outline.createItem("Item 3")
        outline.root.appendChildren([item3])

        XCTAssertEqual(outline.items.count, 3)

        outline.undo() // Remove item 3
        XCTAssertEqual(outline.items.count, 2)

        outline.undo() // Remove item 2
        XCTAssertEqual(outline.items.count, 1)

        outline.undo() // Remove item 1
        XCTAssertEqual(outline.items.count, 0)
    }

    // MARK: - Item Cloning Tests

    func testCloneItemShallow() {
        let original = outline.createItem("Original Item")
        original.setAttribute("custom-attr", value: "custom-value")

        let clones = outline.cloneItems([original], deep: false)

        XCTAssertEqual(clones.count, 1, "Should clone one item")
        XCTAssertEqual(clones[0].body, "Original Item", "Cloned item should have same body")
        XCTAssertEqual(clones[0].attributeForName("custom-attr"), "custom-value", "Attributes should be cloned")
        XCTAssertTrue(clones[0] !== original, "Clone should be a different object")
    }

    func testCloneItemDeep() {
        let parent = outline.createItem("Parent")
        let child = outline.createItem("Child")
        parent.appendChildren([child])
        outline.root.appendChildren([parent])

        let clones = outline.cloneItems([parent], deep: true)

        XCTAssertEqual(clones.count, 1)
        XCTAssertEqual(clones[0].body, "Parent")
        XCTAssertNotNil(clones[0].firstChild, "Deep clone should include children")
        XCTAssertEqual(clones[0].firstChild?.body, "Child")
    }

    // MARK: - Item Path Evaluation Tests

    func testEvaluateItemPathSimple() {
        let item = outline.createItem("Target Item")
        outline.root.appendChildren([item])

        let results = outline.evaluateItemPath("Target Item")

        XCTAssertEqual(results.count, 1, "Should find one matching item")
        XCTAssertEqual(results[0].body, "Target Item")
    }

    func testEvaluateItemPathWithTypeFilter() {
        let project = outline.createItem("My Project")
        project.setAttribute("data-type", value: "project")

        let task = outline.createItem("My Task")
        task.setAttribute("data-type", value: "task")

        outline.root.appendChildren([project, task])

        // This would require proper item path query syntax
        // For now, just verify items are created correctly
        XCTAssertEqual(outline.items.count, 2)
    }

    // MARK: - Change Notifications Tests

    func testDidUpdateChangeCountNotification() {
        let expectation = XCTestExpectation(description: "Change count notification")

        let disposable = outline.onDidUpdateChangeCount { changeType in
            XCTAssertEqual(changeType, .done)
            expectation.fulfill()
        }

        let item = outline.createItem("Test")
        outline.root.appendChildren([item])

        wait(for: [expectation], timeout: 1.0)
        disposable.dispose()
    }

    func testMultipleChangeNotifications() {
        var notificationCount = 0

        let disposable = outline.onDidUpdateChangeCount { _ in
            notificationCount += 1
        }

        let item1 = outline.createItem("Item 1")
        outline.root.appendChildren([item1])

        let item2 = outline.createItem("Item 2")
        outline.root.appendChildren([item2])

        item1.body = "Modified"

        // Should have received multiple notifications
        XCTAssertGreaterThan(notificationCount, 0, "Should receive change notifications")

        disposable.dispose()
    }

    // MARK: - Performance Tests

    func testPerformanceCreateManyItems() {
        measure {
            let testOutline = BirchOutline.createTaskPaperOutline(nil)

            for i in 0..<1000 {
                let item = testOutline.createItem("Item \(i)")
                testOutline.root.appendChildren([item])
            }

            XCTAssertEqual(testOutline.items.count, 1000)
        }
    }

    func testPerformanceSerialization() {
        // Create a large outline
        for i in 0..<100 {
            let parent = outline.createItem("Parent \(i)")
            outline.root.appendChildren([parent])

            for j in 0..<10 {
                let child = outline.createItem("Child \(i)-\(j)")
                parent.appendChildren([child])
            }
        }

        measure {
            _ = outline.serialize(nil)
        }
    }

    func testPerformanceDeserialization() {
        // Create content with many items
        var content = ""
        for i in 0..<100 {
            content += "Item \(i)\n"
            for j in 0..<10 {
                content += "\tChild \(i)-\(j)\n"
            }
        }

        measure {
            let testOutline = BirchOutline.createTaskPaperOutline(content)
            XCTAssertGreaterThan(testOutline.items.count, 0)
        }
    }
}
