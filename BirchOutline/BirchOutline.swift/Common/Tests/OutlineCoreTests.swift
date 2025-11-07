//
//  OutlineCoreTests.swift
//  BirchOutline
//
//  Created for TaskPaper Modernization Phase 1 - Task P1-T15
//  Tests core outline operations: create, add, remove, move, and attributes
//

import XCTest
import JavaScriptCore
@testable import BirchOutline

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
    }
    
    // MARK: - Test Create Outline
    
    func testCreateOutline() {
        // Test outline instantiation
        XCTAssertNotNil(outline, "Outline should be created successfully")
        
        // Verify default properties
        XCTAssertNotNil(outline.root, "Outline should have a root item")
        XCTAssertNil(outline.root.parent, "Root item should have no parent")
        XCTAssertEqual(outline.items.count, 0, "Empty outline should have zero items (root not counted)")
        
        // Verify root is accessible
        let root = outline.root
        XCTAssertNotNil(root, "Root should be accessible")
        XCTAssertNil(root.firstChild, "Empty outline root should have no children")
        XCTAssertNil(root.lastChild, "Empty outline root should have no children")
    }
    
    // MARK: - Test Add Item
    
    func testAddItem() {
        // Capture initial item count
        let initialCount = outline.items.count
        XCTAssertEqual(initialCount, 0, "Outline should start empty")
        
        // Create and add items to outline
        let item1 = outline.createItem("First item")
        let item2 = outline.createItem("Second item")
        let item3 = outline.createItem("Third item")
        
        XCTAssertNotNil(item1, "First item should be created")
        XCTAssertNotNil(item2, "Second item should be created")
        XCTAssertNotNil(item3, "Third item should be created")
        
        // Add items to root
        outline.root.appendChildren([item1, item2, item3])
        
        // Verify item count increased
        let finalCount = outline.items.count
        XCTAssertEqual(finalCount, 3, "Outline should have 3 items after adding")
        XCTAssertEqual(finalCount - initialCount, 3, "Item count should increase by 3")
        
        // Verify items exist in outline structure
        XCTAssertEqual(outline.root.firstChild?.body, "First item", "First child should match first added item")
        XCTAssertEqual(outline.root.lastChild?.body, "Third item", "Last child should match last added item")
        XCTAssertEqual(outline.items[0].body, "First item", "Items array should contain first item")
        XCTAssertEqual(outline.items[1].body, "Second item", "Items array should contain second item")
        XCTAssertEqual(outline.items[2].body, "Third item", "Items array should contain third item")
        
        // Verify parent relationships
        XCTAssertEqual(item1.parent?.id, outline.root.id, "First item's parent should be root")
        XCTAssertEqual(item2.parent?.id, outline.root.id, "Second item's parent should be root")
        XCTAssertEqual(item3.parent?.id, outline.root.id, "Third item's parent should be root")
    }
    
    // MARK: - Test Remove Item
    
    func testRemoveItem() {
        // Create outline with items
        let item1 = outline.createItem("Item to keep 1")
        let item2 = outline.createItem("Item to remove")
        let item3 = outline.createItem("Item to keep 2")
        
        outline.root.appendChildren([item1, item2, item3])
        
        // Capture initial count
        let initialCount = outline.items.count
        XCTAssertEqual(initialCount, 3, "Outline should have 3 items initially")
        
        // Remove specific item
        item2.removeFromParent()
        
        // Verify item count decreased
        let finalCount = outline.items.count
        XCTAssertEqual(finalCount, 2, "Outline should have 2 items after removal")
        XCTAssertEqual(initialCount - finalCount, 1, "Item count should decrease by 1")
        
        // Verify removed item no longer exists in outline
        XCTAssertNil(item2.parent, "Removed item should have no parent")
        XCTAssertFalse(outline.items.contains { $0.id == item2.id }, "Removed item should not be in items array")
        
        // Verify remaining items are correct
        XCTAssertEqual(outline.items[0].body, "Item to keep 1", "First remaining item should be correct")
        XCTAssertEqual(outline.items[1].body, "Item to keep 2", "Second remaining item should be correct")
        
        // Verify sibling relationships updated
        XCTAssertEqual(item1.nextSibling?.id, item3.id, "First item's next sibling should now be third item")
        XCTAssertEqual(item3.previousSibling?.id, item1.id, "Third item's previous sibling should be first item")
    }
    
    // MARK: - Test Move Item
    
    func testMoveItem() {
        // Create hierarchical structure
        let parent1 = outline.createItem("Parent 1")
        let parent2 = outline.createItem("Parent 2")
        let child1 = outline.createItem("Child 1")
        let child2 = outline.createItem("Child 2")
        
        // Build initial hierarchy: parent1 has child1 and child2, parent2 is empty
        outline.root.appendChildren([parent1, parent2])
        parent1.appendChildren([child1, child2])
        
        // Verify initial structure
        XCTAssertEqual(parent1.children.count, 2, "Parent 1 should have 2 children initially")
        XCTAssertEqual(parent2.children.count, 0, "Parent 2 should have 0 children initially")
        XCTAssertEqual(child1.parent?.id, parent1.id, "Child 1's parent should be Parent 1 initially")
        
        // Move child1 from parent1 to parent2
        child1.removeFromParent()
        parent2.appendChildren([child1])
        
        // Verify item's parent changed
        XCTAssertEqual(child1.parent?.id, parent2.id, "Child 1's parent should now be Parent 2")
        XCTAssertNotEqual(child1.parent?.id, parent1.id, "Child 1's parent should no longer be Parent 1")
        
        // Verify item appears in new parent's children collection
        XCTAssertEqual(parent2.children.count, 1, "Parent 2 should now have 1 child")
        XCTAssertEqual(parent2.firstChild?.id, child1.id, "Parent 2's first child should be Child 1")
        XCTAssertTrue(parent2.children.contains { $0.id == child1.id }, "Parent 2's children should contain Child 1")
        
        // Verify item removed from old parent's children
        XCTAssertEqual(parent1.children.count, 1, "Parent 1 should now have 1 child")
        XCTAssertFalse(parent1.children.contains { $0.id == child1.id }, "Parent 1's children should not contain Child 1")
        XCTAssertEqual(parent1.firstChild?.id, child2.id, "Parent 1's first child should now be Child 2")
    }
    
    // MARK: - Test Item Attributes
    
    func testItemAttributes() {
        // Create outline item
        let item = outline.createItem("Test item with attributes")
        outline.root.appendChildren([item])
        
        // Verify initial attributes (TaskPaper default)
        let initialAttributes = item.attributes
        XCTAssertNotNil(initialAttributes, "Item should have attributes dictionary")
        XCTAssertTrue(initialAttributes.keys.contains("data-type"), "Item should have default data-type attribute")
        
        // Set custom attributes
        item.setAttribute("data-done", value: "")
        item.setAttribute("data-priority", value: "1")
        item.setAttribute("data-custom", value: "test-value")
        
        // Retrieve and verify attributes match set values
        XCTAssertTrue(item.hasAttribute("data-done"), "Item should have data-done attribute")
        XCTAssertTrue(item.hasAttribute("data-priority"), "Item should have data-priority attribute")
        XCTAssertTrue(item.hasAttribute("data-custom"), "Item should have data-custom attribute")
        
        // Verify attribute values
        XCTAssertEqual(item.attributeForName("data-done"), "", "data-done attribute value should be empty string")
        XCTAssertEqual(item.attributeForName("data-priority"), "1", "data-priority attribute value should be '1'")
        XCTAssertEqual(item.attributeForName("data-custom"), "test-value", "data-custom attribute value should be 'test-value'")
        
        // Verify attributes dictionary contains all set attributes
        let finalAttributes = item.attributes
        XCTAssertEqual(finalAttributes["data-done"], "", "Attributes dictionary should contain data-done")
        XCTAssertEqual(finalAttributes["data-priority"], "1", "Attributes dictionary should contain data-priority")
        XCTAssertEqual(finalAttributes["data-custom"], "test-value", "Attributes dictionary should contain data-custom")
        
        // Test attribute removal
        item.removeAttribute("data-custom")
        XCTAssertFalse(item.hasAttribute("data-custom"), "Item should not have data-custom attribute after removal")
        XCTAssertNil(item.attributeForName("data-custom"), "Removed attribute should return nil")
    }
    
}
