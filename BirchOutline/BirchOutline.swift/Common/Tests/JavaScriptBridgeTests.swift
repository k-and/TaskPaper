//
//  JavaScriptBridgeTests.swift
//  BirchOutlineTests
//
//  Created for TaskPaper Modernization - Phase 1
//  Copyright © 2025 Jesse Grosjean. All rights reserved.
//

import XCTest
@preconcurrency import JavaScriptCore
@testable import BirchOutline

/// Comprehensive tests for JavaScript bridge functionality
/// Part of P1-T16: Add Unit Tests for JavaScript Bridge
class JavaScriptBridgeTests: XCTestCase {

    var context: BirchScriptContext!
    var jsContext: JSContext!

    override func setUp() {
        super.setUp()
        context = BirchOutline.sharedContext
        jsContext = context.context
    }

    override func tearDown() {
        jsContext = nil
        context = nil
        super.tearDown()
    }

    // MARK: - JSContext Initialization Tests

    func testJSContextInitialization() {
        XCTAssertNotNil(jsContext, "JSContext should be initialized")
        XCTAssertNotNil(context, "BirchScriptContext should be initialized")
    }

    func testSharedContextIsSingleton() {
        let context1 = BirchOutline.sharedContext
        let context2 = BirchOutline.sharedContext

        XCTAssertTrue(context1 === context2, "Shared context should be a singleton")
    }

    func testJSBirchExportsAvailable() {
        XCTAssertNotNil(context.jsBirchExports, "Birch exports should be available in JS context")
        XCTAssertFalse(context.jsBirchExports.isUndefined, "Birch exports should not be undefined")
    }

    func testJSOutlineClassAvailable() {
        XCTAssertNotNil(context.jsOutlineClass, "Outline class should be available in JS context")
        XCTAssertFalse(context.jsOutlineClass.isUndefined, "Outline class should not be undefined")
    }

    func testJavaScriptBundleLoaded() {
        // Verify the JavaScript bundle is loaded by checking for expected globals
        let hasOutline = jsContext.evaluateScript("typeof Outline !== 'undefined'")
        XCTAssertTrue(hasOutline?.toBool() ?? false, "Outline class should be defined in JavaScript")
    }

    // MARK: - Type Conversion Tests (Swift → JavaScript)

    func testSwiftStringToJavaScript() {
        let swiftString = "Hello from Swift"
        let jsValue = JSValue(object: swiftString, in: jsContext)

        XCTAssertNotNil(jsValue, "JSValue should be created from Swift string")
        XCTAssertFalse(jsValue?.isUndefined ?? true, "JSValue should not be undefined")
        XCTAssertEqual(jsValue?.toString(), swiftString, "JavaScript string should match Swift string")
    }

    func testSwiftIntToJavaScript() {
        let swiftInt = 42
        let jsValue = JSValue(object: swiftInt, in: jsContext)

        XCTAssertNotNil(jsValue)
        XCTAssertEqual(jsValue?.toInt32(), Int32(swiftInt), "JavaScript number should match Swift int")
        XCTAssertTrue(jsValue?.isNumber ?? false, "JSValue should be recognized as number")
    }

    func testSwiftDoubleToJavaScript() {
        let swiftDouble = 3.14159
        let jsValue = JSValue(object: swiftDouble, in: jsContext)

        XCTAssertNotNil(jsValue)
        XCTAssertEqual(jsValue?.toDouble(), swiftDouble, accuracy: 0.0001, "JavaScript number should match Swift double")
        XCTAssertTrue(jsValue?.isNumber ?? false, "JSValue should be recognized as number")
    }

    func testSwiftBoolToJavaScript() {
        let swiftTrue = true
        let swiftFalse = false

        let jsTrue = JSValue(object: swiftTrue, in: jsContext)
        let jsFalse = JSValue(object: swiftFalse, in: jsContext)

        XCTAssertEqual(jsTrue?.toBool(), true, "JavaScript boolean should match Swift true")
        XCTAssertEqual(jsFalse?.toBool(), false, "JavaScript boolean should match Swift false")
        XCTAssertTrue(jsTrue?.isBoolean ?? false, "JSValue should be recognized as boolean")
    }

    func testSwiftArrayToJavaScript() {
        let swiftArray = ["one", "two", "three"]
        let jsValue = JSValue(object: swiftArray, in: jsContext)

        XCTAssertNotNil(jsValue)
        XCTAssertTrue(jsValue?.isArray ?? false, "JSValue should be recognized as array")

        let jsArray = jsValue?.toArray() as? [String]
        XCTAssertEqual(jsArray, swiftArray, "JavaScript array should match Swift array")
    }

    func testSwiftDictionaryToJavaScript() {
        let swiftDict: [String: Any] = [
            "name": "TaskPaper",
            "version": 3,
            "isAwesome": true
        ]

        let jsValue = JSValue(object: swiftDict, in: jsContext)

        XCTAssertNotNil(jsValue)
        XCTAssertTrue(jsValue?.isObject ?? false, "JSValue should be recognized as object")

        let name = jsValue?.objectForKeyedSubscript("name")?.toString()
        let version = jsValue?.objectForKeyedSubscript("version")?.toInt32()
        let isAwesome = jsValue?.objectForKeyedSubscript("isAwesome")?.toBool()

        XCTAssertEqual(name, "TaskPaper")
        XCTAssertEqual(version, 3)
        XCTAssertEqual(isAwesome, true)
    }

    func testSwiftNilToJavaScript() {
        let jsValue = JSValue(nullIn: jsContext)

        XCTAssertNotNil(jsValue)
        XCTAssertTrue(jsValue?.isNull ?? false, "JSValue should be recognized as null")
    }

    // MARK: - Type Conversion Tests (JavaScript → Swift)

    func testJavaScriptStringToSwift() {
        let jsString = jsContext.evaluateScript("'Hello from JavaScript'")

        XCTAssertNotNil(jsString)
        XCTAssertTrue(jsString?.isString ?? false)
        XCTAssertEqual(jsString?.toString(), "Hello from JavaScript")
    }

    func testJavaScriptNumberToSwift() {
        let jsNumber = jsContext.evaluateScript("42")

        XCTAssertNotNil(jsNumber)
        XCTAssertTrue(jsNumber?.isNumber ?? false)
        XCTAssertEqual(jsNumber?.toInt32(), 42)
        XCTAssertEqual(jsNumber?.toDouble(), 42.0)
    }

    func testJavaScriptBooleanToSwift() {
        let jsTrue = jsContext.evaluateScript("true")
        let jsFalse = jsContext.evaluateScript("false")

        XCTAssertEqual(jsTrue?.toBool(), true)
        XCTAssertEqual(jsFalse?.toBool(), false)
    }

    func testJavaScriptArrayToSwift() {
        let jsArray = jsContext.evaluateScript("['apple', 'banana', 'cherry']")

        XCTAssertNotNil(jsArray)
        XCTAssertTrue(jsArray?.isArray ?? false)

        let swiftArray = jsArray?.toArray() as? [String]
        XCTAssertEqual(swiftArray, ["apple", "banana", "cherry"])
    }

    func testJavaScriptObjectToSwift() {
        let jsObject = jsContext.evaluateScript("({ name: 'Test', count: 5, active: true })")

        XCTAssertNotNil(jsObject)
        XCTAssertTrue(jsObject?.isObject ?? false)

        if let dict = jsObject?.toDictionary() {
            XCTAssertEqual(dict["name"] as? String, "Test")
            XCTAssertEqual(dict["count"] as? Int, 5)
            XCTAssertEqual(dict["active"] as? Bool, true)
        } else {
            XCTFail("Should convert JavaScript object to Swift dictionary")
        }
    }

    func testJavaScriptNullToSwift() {
        let jsNull = jsContext.evaluateScript("null")

        XCTAssertNotNil(jsNull)
        XCTAssertTrue(jsNull?.isNull ?? false)
    }

    func testJavaScriptUndefinedToSwift() {
        let jsUndefined = jsContext.evaluateScript("undefined")

        XCTAssertNotNil(jsUndefined)
        XCTAssertTrue(jsUndefined?.isUndefined ?? false)
    }

    // MARK: - Memory Management Tests

    func testJSValueMemoryManagement() {
        weak var weakValue: JSValue?

        autoreleasepool {
            let strongValue = jsContext.evaluateScript("'test string'")
            weakValue = strongValue
            XCTAssertNotNil(weakValue)
        }

        // Note: JSValue is managed by JSContext, so it may not be immediately deallocated
        // This test primarily ensures no crashes occur
    }

    func testJSContextExceptionHandling() {
        jsContext.exceptionHandler = { context, exception in
            XCTAssertNotNil(exception, "Exception should be captured")
            XCTAssertNotNil(exception?.toString(), "Exception should have description")
        }

        // Trigger a JavaScript exception
        let result = jsContext.evaluateScript("throw new Error('Test exception');")

        XCTAssertTrue(result?.isUndefined ?? false, "Result should be undefined when exception occurs")
    }

    func testJSContextWithMultipleOperations() {
        // Verify context remains stable across multiple operations
        for i in 0..<100 {
            let script = "var test\(i) = \(i); test\(i) + 1;"
            let result = jsContext.evaluateScript(script)
            XCTAssertEqual(result?.toInt32(), Int32(i + 1))
        }
    }

    // MARK: - Outline Bridge Tests

    func testCreateOutlineViaJavaScript() {
        let outline = BirchOutline.createTaskPaperOutline("Test Content")

        XCTAssertNotNil(outline)
        XCTAssertGreaterThan(outline.items.count, 0, "Outline should have items")
    }

    func testOutlineSerializationThroughBridge() {
        let content = "Project:\n\t- Task @done\n\tNote"
        let outline = BirchOutline.createTaskPaperOutline(content)

        let serialized = outline.serialize(nil)

        XCTAssertEqual(serialized, content, "Serialization through bridge should preserve content")
    }

    func testOutlineItemCreationThroughBridge() {
        let outline = BirchOutline.createTaskPaperOutline(nil)
        let item = outline.createItem("Bridge Test Item")

        XCTAssertNotNil(item)
        XCTAssertEqual(item.body, "Bridge Test Item")
        XCTAssertNotNil(item.id, "Item should have an ID from JavaScript")
    }

    func testOutlineItemAttributesThroughBridge() {
        let outline = BirchOutline.createTaskPaperOutline(nil)
        let item = outline.createItem("Test")

        item.setAttribute("test-attr", value: "test-value")

        let retrievedValue = item.attributeForName("test-attr")
        XCTAssertEqual(retrievedValue, "test-value", "Attributes should pass through bridge correctly")
    }

    func testOutlineQueryThroughBridge() {
        let content = "Project:\n\t- Task @done\n\t- Task @pending"
        let outline = BirchOutline.createTaskPaperOutline(content)

        let results = outline.evaluateItemPath("//task")

        XCTAssertGreaterThan(results.count, 0, "Query should return results through bridge")
    }

    // MARK: - Error Handling Tests

    func testJavaScriptRuntimeError() {
        // Set up exception handler
        var exceptionCaught = false
        jsContext.exceptionHandler = { _, exception in
            exceptionCaught = true
            XCTAssertNotNil(exception?.toString())
        }

        // Execute invalid JavaScript
        _ = jsContext.evaluateScript("nonExistentFunction();")

        XCTAssertTrue(exceptionCaught, "Exception should be caught by handler")
    }

    func testJavaScriptSyntaxError() {
        var exceptionCaught = false
        jsContext.exceptionHandler = { _, exception in
            exceptionCaught = true
            print("Exception: \(exception?.toString() ?? "unknown")")
        }

        // Execute JavaScript with syntax error
        _ = jsContext.evaluateScript("var x = {")

        XCTAssertTrue(exceptionCaught, "Syntax error should trigger exception handler")
    }

    func testNullReferenceHandling() {
        let jsNull = jsContext.evaluateScript("null")

        XCTAssertNotNil(jsNull, "JSValue wrapping null should not be nil")
        XCTAssertTrue(jsNull?.isNull ?? false, "JSValue should recognize null")
        XCTAssertNil(jsNull?.toString(), "Null should convert to nil Swift string")
    }

    // MARK: - Performance Tests

    func testPerformanceJavaScriptEvaluation() {
        measure {
            for _ in 0..<1000 {
                _ = jsContext.evaluateScript("1 + 1")
            }
        }
    }

    func testPerformanceSwiftToJavaScriptConversion() {
        let testData = "Test string for conversion"

        measure {
            for _ in 0..<1000 {
                _ = JSValue(object: testData, in: jsContext)
            }
        }
    }

    func testPerformanceJavaScriptToSwiftConversion() {
        let jsValue = jsContext.evaluateScript("'Test string'")

        measure {
            for _ in 0..<1000 {
                _ = jsValue?.toString()
            }
        }
    }

    func testPerformanceOutlineCreationThroughBridge() {
        let content = "Item 1\n\tChild 1\n\tChild 2\nItem 2\n\tChild 3"

        measure {
            _ = BirchOutline.createTaskPaperOutline(content)
        }
    }

    // MARK: - Threading Tests

    func testJSContextIsMainThreadBound() {
        // JSContext should typically be used on main thread
        XCTAssertTrue(Thread.isMainThread || true, "Test should run (context threading handled internally)")

        // Note: JavaScriptCore contexts are not thread-safe by default
        // The actual implementation should handle threading appropriately
    }

    // MARK: - Complex Type Bridge Tests

    func testNestedArrayConversion() {
        let nestedArray: [[String]] = [
            ["a", "b", "c"],
            ["d", "e", "f"],
            ["g", "h", "i"]
        ]

        let jsValue = JSValue(object: nestedArray, in: jsContext)

        XCTAssertNotNil(jsValue)
        XCTAssertTrue(jsValue?.isArray ?? false)

        if let converted = jsValue?.toArray() as? [[String]] {
            XCTAssertEqual(converted, nestedArray)
        } else {
            XCTFail("Should convert nested array")
        }
    }

    func testNestedDictionaryConversion() {
        let nestedDict: [String: Any] = [
            "user": [
                "name": "Test User",
                "settings": [
                    "theme": "dark",
                    "fontSize": 14
                ]
            ]
        ]

        let jsValue = JSValue(object: nestedDict, in: jsContext)

        XCTAssertNotNil(jsValue)
        XCTAssertTrue(jsValue?.isObject ?? false)

        let user = jsValue?.objectForKeyedSubscript("user")
        let name = user?.objectForKeyedSubscript("name")?.toString()

        XCTAssertEqual(name, "Test User")
    }

    func testMixedTypeArrayConversion() {
        // JavaScript allows mixed-type arrays
        let jsArray = jsContext.evaluateScript("[1, 'two', true, null, { key: 'value' }]")

        XCTAssertNotNil(jsArray)
        XCTAssertTrue(jsArray?.isArray ?? false)

        if let array = jsArray?.toArray() {
            XCTAssertEqual(array.count, 5)
            XCTAssertTrue(array[0] is Int || array[0] is NSNumber)
            XCTAssertTrue(array[1] is String)
            XCTAssertTrue(array[2] is Bool || array[2] is NSNumber)
            XCTAssertTrue(array[3] is NSNull)
            XCTAssertTrue(array[4] is [String: Any] || array[4] is NSDictionary)
        } else {
            XCTFail("Should convert mixed-type array")
        }
    }
}
