//
//  JavaScriptBridgeTests.swift
//  BirchOutline
//
//  Created for TaskPaper Modernization Phase 1 - Task P1-T16
//  Tests JavaScriptCore bridge functionality: context initialization, type bridging, callbacks, and exception handling
//

import XCTest
import JavaScriptCore
@testable import BirchOutline

class JavaScriptBridgeTests: XCTestCase {
    
    var testContext: JSContext!
    
    override func setUp() {
        super.setUp()
        testContext = JSContext()
    }
    
    override func tearDown() {
        testContext = nil
        super.tearDown()
    }
    
    // MARK: - Test Context Initialization
    
    func testContextInitialization() {
        // Access BirchOutline.sharedContext
        let sharedContext = BirchOutline.sharedContext
        
        // Assert the context is not nil
        XCTAssertNotNil(sharedContext, "BirchOutline.sharedContext should not be nil")
        XCTAssertNotNil(sharedContext.context, "BirchOutline.sharedContext.context should not be nil")
        
        // Verify basic context functionality
        let result = sharedContext.context.evaluateScript("1 + 1")
        XCTAssertNotNil(result, "JavaScript evaluation should return a result")
        XCTAssertEqual(result!.toInt32(), 2, "JavaScript '1 + 1' should equal 2")
        
        // Verify BirchOutline-specific context properties
        XCTAssertNotNil(sharedContext.jsBirchExports, "jsBirchExports should be loaded")
        XCTAssertNotNil(sharedContext.jsOutlineClass, "jsOutlineClass should be available")
        XCTAssertNotNil(sharedContext.jsItemClass, "jsItemClass should be available")
        
        // Verify context name is set
        XCTAssertEqual(sharedContext.context.name, "BirchOutlineJavaScriptContext", "Context should have correct name")
    }
    
    // MARK: - Test JavaScript to Swift Type Bridging
    
    func testJavaScriptToSwiftTypeBridging() {
        // Test string bridging
        let stringResult = testContext.evaluateScript("\"hello\"")
        XCTAssertNotNil(stringResult, "String evaluation should return a result")
        XCTAssertEqual(stringResult!.toString(), "hello", "JavaScript string should bridge to Swift String")
        
        // Test number bridging
        let numberResult = testContext.evaluateScript("42")
        XCTAssertNotNil(numberResult, "Number evaluation should return a result")
        XCTAssertEqual(numberResult!.toInt32(), 42, "JavaScript number should bridge to Int32 with value 42")
        XCTAssertEqual(numberResult!.toNumber() as? NSNumber, NSNumber(value: 42), "JavaScript number should bridge to NSNumber")
        
        // Test boolean bridging - true
        let boolTrueResult = testContext.evaluateScript("true")
        XCTAssertNotNil(boolTrueResult, "Boolean true evaluation should return a result")
        XCTAssertTrue(boolTrueResult!.toBool(), "JavaScript true should bridge to Swift Bool true")
        
        // Test boolean bridging - false
        let boolFalseResult = testContext.evaluateScript("false")
        XCTAssertNotNil(boolFalseResult, "Boolean false evaluation should return a result")
        XCTAssertFalse(boolFalseResult!.toBool(), "JavaScript false should bridge to Swift Bool false")
        
        // Test array bridging
        let arrayResult = testContext.evaluateScript("[1, 2, 3]")
        XCTAssertNotNil(arrayResult, "Array evaluation should return a result")
        XCTAssertTrue(arrayResult!.isArray, "Result should be recognized as an array")
        
        let swiftArray = arrayResult!.toArray() as! [Int]
        XCTAssertEqual(swiftArray.count, 3, "Array should have 3 elements")
        XCTAssertEqual(swiftArray[0], 1, "First element should be 1")
        XCTAssertEqual(swiftArray[1], 2, "Second element should be 2")
        XCTAssertEqual(swiftArray[2], 3, "Third element should be 3")
        
        // Test object bridging
        let objectResult = testContext.evaluateScript("{key: \"value\"}")
        XCTAssertNotNil(objectResult, "Object evaluation should return a result")
        XCTAssertTrue(objectResult!.isObject, "Result should be recognized as an object")
        
        let swiftDict = objectResult!.toDictionary() as! [String: String]
        XCTAssertEqual(swiftDict.count, 1, "Dictionary should have 1 key-value pair")
        XCTAssertEqual(swiftDict["key"], "value", "Dictionary should contain correct key-value pair")
        
        // Test nested object bridging
        let nestedResult = testContext.evaluateScript("{numbers: [1, 2], text: \"hello\", flag: true}")
        XCTAssertNotNil(nestedResult, "Nested object evaluation should return a result")
        
        let nestedDict = nestedResult!.toDictionary()!
        XCTAssertEqual((nestedDict["numbers"] as! [Int]).count, 2, "Nested array should have 2 elements")
        XCTAssertEqual(nestedDict["text"] as! String, "hello", "Nested string should match")
        XCTAssertEqual(nestedDict["flag"] as! Bool, true, "Nested boolean should match")
    }
    
    // MARK: - Test Swift to JavaScript Function Call
    
    func testSwiftToJavaScriptFunctionCall() {
        // Create flag to track callback execution
        var callbackExecuted = false
        var callbackParameter: String?
        
        // Define Swift closure
        let swiftCallback: @convention(block) (String) -> Void = { parameter in
            callbackExecuted = true
            callbackParameter = parameter
        }
        
        // Add closure to context
        testContext.setObject(swiftCallback, forKeyedSubscript: "swiftCallback" as NSString)
        
        // Verify callback was added to context
        let callbackObject = testContext.objectForKeyedSubscript("swiftCallback")
        XCTAssertNotNil(callbackObject, "Callback should be added to context")
        
        // Execute JavaScript code that calls the Swift function
        testContext.evaluateScript("swiftCallback('test parameter')")
        
        // Assert the flag was set
        XCTAssertTrue(callbackExecuted, "Swift callback should have been executed by JavaScript")
        XCTAssertEqual(callbackParameter, "test parameter", "Callback should receive correct parameter")
        
        // Test with return value
        var counter = 0
        let incrementCallback: @convention(block) () -> Int = {
            counter += 1
            return counter
        }
        
        testContext.setObject(incrementCallback, forKeyedSubscript: "increment" as NSString)
        
        // Call multiple times and verify return values
        let result1 = testContext.evaluateScript("increment()")
        XCTAssertEqual(result1!.toInt32(), 1, "First call should return 1")
        
        let result2 = testContext.evaluateScript("increment()")
        XCTAssertEqual(result2!.toInt32(), 2, "Second call should return 2")
        
        let result3 = testContext.evaluateScript("increment() + increment()")
        XCTAssertEqual(result3!.toInt32(), 7, "Third and fourth calls should return 3 + 4 = 7")
        
        XCTAssertEqual(counter, 4, "Counter should have been incremented 4 times")
        
        // Test with multiple parameters and object return
        let mathOperation: @convention(block) (Int, Int, String) -> [String: Any] = { a, b, operation in
            let result: Int
            switch operation {
            case "add":
                result = a + b
            case "multiply":
                result = a * b
            case "subtract":
                result = a - b
            default:
                result = 0
            }
            return ["operation": operation, "result": result, "inputs": [a, b]]
        }
        
        testContext.setObject(mathOperation, forKeyedSubscript: "calculate" as NSString)
        
        let calcResult = testContext.evaluateScript("calculate(5, 3, 'add')")
        XCTAssertNotNil(calcResult, "Calculate should return a result")
        
        let calcDict = calcResult!.toDictionary()!
        XCTAssertEqual(calcDict["operation"] as! String, "add", "Operation should be 'add'")
        XCTAssertEqual(calcDict["result"] as! Int, 8, "Result should be 8")
        XCTAssertEqual((calcDict["inputs"] as! [Int]).count, 2, "Inputs array should have 2 elements")
    }
    
    // MARK: - Test JavaScript Exception Handling
    
    func testJavaScriptExceptionHandling() {
        // Create variables to capture exception
        var exceptionCaught = false
        var caughtException: JSValue?
        
        // Set up exception handler
        testContext.exceptionHandler = { context, exception in
            exceptionCaught = true
            caughtException = exception
        }
        
        // Execute deliberately invalid JavaScript - undefined function
        let result1 = testContext.evaluateScript("nonExistentFunction()")
        
        // Assert exception handler was called
        XCTAssertTrue(exceptionCaught, "Exception handler should have been called for undefined function")
        XCTAssertNotNil(caughtException, "Exception should have been captured")
        XCTAssertTrue(caughtException!.toString().contains("nonExistentFunction"), 
                     "Exception message should mention the undefined function")
        
        // Reset for next test
        exceptionCaught = false
        caughtException = nil
        
        // Test syntax error
        let result2 = testContext.evaluateScript("var x = {")
        
        // Assert exception handler was called for syntax error
        XCTAssertTrue(exceptionCaught, "Exception handler should have been called for syntax error")
        XCTAssertNotNil(caughtException, "Syntax error exception should have been captured")
        
        // Verify exception contains error information
        let exceptionString = caughtException!.toString()
        XCTAssertFalse(exceptionString.isEmpty, "Exception should contain error message")
        
        // Reset for next test
        exceptionCaught = false
        caughtException = nil
        
        // Test runtime error - accessing property of undefined
        testContext.evaluateScript("var obj = undefined; obj.property;")
        
        XCTAssertTrue(exceptionCaught, "Exception handler should have been called for runtime error")
        XCTAssertNotNil(caughtException, "Runtime error exception should have been captured")
        
        // Test that valid code after setting up exception handler still works
        exceptionCaught = false
        caughtException = nil
        
        let validResult = testContext.evaluateScript("2 + 2")
        XCTAssertFalse(exceptionCaught, "Exception handler should not be called for valid code")
        XCTAssertNil(caughtException, "No exception should be captured for valid code")
        XCTAssertEqual(validResult!.toInt32(), 4, "Valid code should execute correctly")
        
        // Test exception handler receives context parameter
        var contextReceived: JSContext?
        testContext.exceptionHandler = { context, exception in
            contextReceived = context
        }
        
        testContext.evaluateScript("invalid code {")
        
        XCTAssertNotNil(contextReceived, "Exception handler should receive context parameter")
        XCTAssertEqual(contextReceived, testContext, "Received context should match test context")
    }
    
}
