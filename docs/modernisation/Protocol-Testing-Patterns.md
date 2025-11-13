# Protocol-Oriented Testing & Dependency Injection Patterns

**Phase 2 Modernization - Testing Guide**

This document provides patterns and best practices for using protocol-oriented design for dependency injection and testing in the TaskPaper codebase.

---

## Table of Contents

1. [Overview](#overview)
2. [Protocol Abstractions](#protocol-abstractions)
3. [Mock Implementations](#mock-implementations)
4. [Testing Patterns](#testing-patterns)
5. [Dependency Injection Patterns](#dependency-injection-patterns)
6. [Migration Guide](#migration-guide)

---

## Overview

### Why Protocol-Oriented Design?

The TaskPaper codebase uses protocol-oriented design to:

1. **Enable Dependency Injection**: Accept protocol types instead of concrete classes
2. **Improve Testability**: Create lightweight mocks for fast unit testing
3. **Reduce Test Dependencies**: Eliminate JavaScriptCore and file I/O overhead in tests
4. **Increase Test Speed**: 10-100× faster test execution with mocks

### Performance Benefits

| Component | Real Object Init Time | Mock Init Time | Speedup |
|-----------|----------------------|----------------|---------|
| StyleSheet | ~100ms (JS engine) | <1ms | 100× |
| OutlineEditor | ~150ms (JS + outline) | <1ms | 150× |
| OutlineDocument | ~50ms (file I/O) | <1ms | 50× |

---

## Protocol Abstractions

### StyleSheetProtocol

**File**: `BirchEditor/Protocols/StyleSheetProtocol.swift`

**Purpose**: Abstracts stylesheet operations (LESS compilation, style computation)

```swift
@MainActor
public protocol StyleSheetProtocol: AnyObject {
    var source: URL { get }

    func computedStyle(for element: Any) -> ComputedStyle
    func computedStyleKeyPath(for element: Any) -> String
    func computedStyle(forKeyPath keyPath: String) -> ComputedStyle
    func invalidateComputedStyles()
}
```

**Conforming Types**:
- `StyleSheet` - Production implementation using JavaScriptCore
- `MockStyleSheet` - Test implementation with stub responses

---

### OutlineEditorType (Protocol)

**File**: `BirchEditor/OutlineEditorType.swift`

**Purpose**: Abstracts outline editing operations

**Key Methods**:
- `deserializeItems(_:options:)` - Parse text into items
- `serializeItems(_:options:)` - Convert items to text
- `moveBranches(_:parent:nextSibling:options:)` - Move items in outline
- `performCommand(_:options:)` - Execute editor commands
- `evaluateScript(_:withOptions:)` - Run JavaScript in editor context

**Conforming Types**:
- `OutlineEditor` - Production implementation using JavaScriptCore
- `MockOutlineEditor` - Test implementation with call recording

---

### OutlineDocumentProtocol

**File**: `BirchEditor/Protocols/OutlineDocumentProtocol.swift`

**Purpose**: Abstracts document operations (read, write, save)

```swift
@MainActor
public protocol OutlineDocumentProtocol: AnyObject {
    var outline: OutlineType { get }
    var fileURL: URL? { get }
    var displayName: String { get }
    var hasUnautosavedChanges: Bool { get }

    func read(from data: Data, ofType typeName: String) throws
    func data(ofType typeName: String) throws -> Data
    func save(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType, completionHandler: @escaping (Error?) -> Void)
    func updateChangeCount(_ changeType: NSDocument.ChangeType)
}
```

**Conforming Types**:
- `OutlineDocument` - Production implementation using NSDocument
- `MockOutlineDocument` - Test implementation with call recording

---

## Mock Implementations

### MockStyleSheet

**File**: `BirchEditorTests/Mocks/MockStyleSheet.swift`

**Features**:
- Call recording for all method invocations
- Configurable stub responses
- Helper methods for common styles (task, completed, note)
- Reset method for test isolation

**Usage**:

```swift
func testStyling() {
    let mockStyleSheet = MockStyleSheet()

    // Configure stub
    mockStyleSheet.computedStyleStub = MockStyleSheet.taskStyle()

    // Use in code under test
    let component = MyComponent(styleSheet: mockStyleSheet)
    component.applyStyling()

    // Verify behavior
    XCTAssertEqual(mockStyleSheet.computedStyleCalls.count, 1)
}
```

---

### MockOutlineEditor

**File**: `BirchEditorTests/Mocks/MockOutlineEditor.swift`

**Features**:
- Records all editor operations
- Configurable stubs for serialization, deserialization, script evaluation
- Dummy implementations for complex types (DummyItem, DummyDisposable)
- Reset method for test isolation

**Usage**:

```swift
func testEditorOperation() {
    let mockEditor = MockOutlineEditor()

    // Configure stubs
    mockEditor.deserializeItemsStub = [item1, item2]

    // Use in code under test
    let result = mockEditor.deserializeItems("task1\ntask2", options: nil)

    // Verify behavior
    XCTAssertEqual(mockEditor.deserializeItemsCalls.count, 1)
    XCTAssertEqual(result?.count, 2)
}
```

---

### MockOutlineDocument

**File**: `BirchEditorTests/Mocks/MockOutlineDocument.swift`

**Features**:
- Records all document operations
- Configurable stubs for data, file URL, display name
- Error injection for failure testing
- Automatic change tracking
- Reset method for test isolation

**Usage**:

```swift
func testDocumentSave() {
    let mockDocument = MockOutlineDocument()

    // Configure stubs
    mockDocument.dataStub = Data("task1\ntask2".utf8)

    // Use in code under test
    let data = try mockDocument.data(ofType: "com.taskpaper")

    // Verify behavior
    XCTAssertEqual(mockDocument.dataCallCount, 1)
}
```

---

## Testing Patterns

### Pattern 1: Mock Configuration

**Problem**: Tests need predictable behavior from dependencies

**Solution**: Configure stub responses before test execution

```swift
func testComponentBehavior() {
    // 1. Create mocks
    let mockStyleSheet = MockStyleSheet()
    let mockEditor = MockOutlineEditor()

    // 2. Configure stubs
    mockStyleSheet.computedStyleStub = MockStyleSheet.taskStyle()
    mockEditor.deserializeItemsStub = [testItem1, testItem2]

    // 3. Inject into component under test
    let component = MyComponent(
        styleSheet: mockStyleSheet,
        editor: mockEditor
    )

    // 4. Execute test
    component.performOperation()

    // 5. Verify behavior
    XCTAssertEqual(mockEditor.deserializeItemsCalls.count, 1)
}
```

---

### Pattern 2: Call Verification

**Problem**: Need to verify that component calls dependencies correctly

**Solution**: Use call recording to assert method invocations

```swift
func testCommandExecution() {
    let mockEditor = MockOutlineEditor()
    let component = MyComponent(editor: mockEditor)

    // Execute
    component.indentSelection()

    // Verify the correct command was called
    XCTAssertEqual(mockEditor.performCommandCalls.count, 1)
    XCTAssertEqual(mockEditor.performCommandCalls[0].command, "indent")
}
```

---

### Pattern 3: Error Injection

**Problem**: Need to test error handling without causing real failures

**Solution**: Configure mock to throw errors

```swift
func testErrorHandling() {
    let mockDocument = MockOutlineDocument()

    // Configure error
    struct TestError: Error {}
    mockDocument.errorStub = TestError()

    // Verify error handling
    XCTAssertThrowsError(try mockDocument.read(from: Data(), ofType: "test")) { error in
        XCTAssertTrue(error is TestError)
    }
}
```

---

### Pattern 4: Test Isolation

**Problem**: Test state leaks between tests

**Solution**: Reset mocks in tearDown or between test cases

```swift
class MyComponentTests: XCTestCase {
    var mockEditor: MockOutlineEditor!

    override func setUp() {
        super.setUp()
        mockEditor = MockOutlineEditor()
    }

    override func tearDown() {
        mockEditor.reset() // Clean state for next test
        super.tearDown()
    }

    func testOperation1() {
        mockEditor.performCommand("test1", options: nil)
        XCTAssertEqual(mockEditor.performCommandCalls.count, 1)
    }

    func testOperation2() {
        // Clean state from setUp + reset in tearDown
        mockEditor.performCommand("test2", options: nil)
        XCTAssertEqual(mockEditor.performCommandCalls.count, 1)
    }
}
```

---

## Dependency Injection Patterns

### Pattern 1: Constructor Injection

**Best for**: Required dependencies that don't change

```swift
class MyComponent {
    private let styleSheet: StyleSheetProtocol
    private let editor: OutlineEditorType

    init(styleSheet: StyleSheetProtocol, editor: OutlineEditorType) {
        self.styleSheet = styleSheet
        self.editor = editor
    }

    func performOperation() {
        let style = styleSheet.computedStyle(for: "task")
        // Use style...
    }
}

// Production usage
let component = MyComponent(
    styleSheet: realStyleSheet,
    editor: realEditor
)

// Test usage
let component = MyComponent(
    styleSheet: mockStyleSheet,
    editor: mockEditor
)
```

---

### Pattern 2: Property Injection

**Best for**: Optional dependencies or dependencies that may change

```swift
class MyViewController: NSViewController {
    var styleSheet: StyleSheetProtocol?
    var editor: OutlineEditorType?

    func updateStyling() {
        guard let styleSheet = styleSheet else { return }
        let style = styleSheet.computedStyle(for: "task")
        // Use style...
    }
}

// Production usage
viewController.styleSheet = realStyleSheet
viewController.editor = realEditor

// Test usage
viewController.styleSheet = mockStyleSheet
viewController.editor = mockEditor
```

---

### Pattern 3: Factory Injection

**Best for**: Creating dependencies lazily or with complex initialization

```swift
class MyViewController: NSViewController {
    // Factory closure for dependency creation
    var editorFactory: () -> OutlineEditorType = {
        // Default: create real editor
        return BirchEditor.createOutlineEditor(...)
    }

    // Lazy initialization using factory
    lazy var editor: OutlineEditorType = editorFactory()

    func performOperation() {
        editor.performCommand("test", options: nil)
    }
}

// Production usage
// Uses default factory to create real editor

// Test usage
viewController.editorFactory = { MockOutlineEditor() }
```

---

### Pattern 4: Protocol-Oriented Composition

**Best for**: Components that need multiple protocol capabilities

```swift
// Component accepts multiple protocol types
class DocumentProcessor {
    private let document: OutlineDocumentProtocol
    private let styleSheet: StyleSheetProtocol

    init(document: OutlineDocumentProtocol, styleSheet: StyleSheetProtocol) {
        self.document = document
        self.styleSheet = styleSheet
    }

    func process() throws -> ProcessedDocument {
        let data = try document.data(ofType: "com.taskpaper")
        let style = styleSheet.computedStyle(forKeyPath: "task")
        // Process with both dependencies...
        return ProcessedDocument(data: data, style: style)
    }
}

// Test with both mocks
let processor = DocumentProcessor(
    document: mockDocument,
    styleSheet: mockStyleSheet
)
```

---

## Migration Guide

### Converting Existing Code to Use Protocols

#### Before: Concrete Type Dependency

```swift
class MyComponent {
    private let styleSheet: StyleSheet // ❌ Concrete type

    init(styleSheet: StyleSheet) {
        self.styleSheet = styleSheet
    }
}
```

#### After: Protocol Dependency

```swift
class MyComponent {
    private let styleSheet: StyleSheetProtocol // ✅ Protocol type

    init(styleSheet: StyleSheetProtocol) {
        self.styleSheet = styleSheet
    }
}
```

---

### Converting Tests to Use Mocks

#### Before: Real Objects in Tests

```swift
class MyComponentTests: XCTestCase {
    func testStyling() {
        // ❌ Slow: creates real StyleSheet with JS engine
        let styleSheet = StyleSheet(source: nil, scriptContext: BirchOutline.sharedContext)
        let component = MyComponent(styleSheet: styleSheet)

        component.applyStyling()

        // Can't verify calls to styleSheet
    }
}
```

#### After: Mocks in Tests

```swift
class MyComponentTests: XCTestCase {
    func testStyling() {
        // ✅ Fast: mock with no JS engine
        let mockStyleSheet = MockStyleSheet()
        mockStyleSheet.computedStyleStub = MockStyleSheet.taskStyle()

        let component = MyComponent(styleSheet: mockStyleSheet)

        component.applyStyling()

        // ✅ Can verify calls
        XCTAssertEqual(mockStyleSheet.computedStyleCalls.count, 1)
    }
}
```

---

### Adding Dependency Injection to Existing Classes

#### Step 1: Identify Dependencies

Look for direct instantiation of:
- `StyleSheet`
- `OutlineEditor`
- `OutlineDocument`

#### Step 2: Change Types to Protocols

```swift
// Before
var styleSheet: StyleSheet?

// After
var styleSheet: StyleSheetProtocol?
```

#### Step 3: Inject in Initializer or Property

```swift
// Constructor injection
init(styleSheet: StyleSheetProtocol) {
    self.styleSheet = styleSheet
}

// Or property injection
var styleSheet: StyleSheetProtocol?
```

#### Step 4: Update Call Sites

```swift
// Production code
let component = MyComponent(styleSheet: realStyleSheet)

// Test code
let component = MyComponent(styleSheet: mockStyleSheet)
```

---

## Best Practices

### Do's ✅

1. **Accept protocol types** in public APIs
2. **Configure stubs before** executing test
3. **Verify behavior** using call recording
4. **Reset mocks** between tests
5. **Use constructor injection** for required dependencies
6. **Document stub behavior** in test comments

### Don'ts ❌

1. **Don't test real implementations** with mocks (use real objects for integration tests)
2. **Don't over-mock** - mock only external dependencies
3. **Don't share mocks** between test cases
4. **Don't forget to configure stubs** before use
5. **Don't test mock implementations** themselves

---

## Examples

See `BirchEditorTests/Examples/MockUsageExamplesTests.swift` for comprehensive examples of:

- Basic mock configuration
- Call verification
- Stub responses
- Error injection
- Multiple mock coordination
- Performance comparisons

---

## Further Reading

- [Swift Protocol-Oriented Programming](https://developer.apple.com/videos/play/wwdc2015/408/)
- [Dependency Injection in Swift](https://www.swiftbysundell.com/articles/dependency-injection-in-swift/)
- [Testing with Mocks](https://www.swiftbysundell.com/articles/testing-swift-code-that-uses-system-apis/)

---

**Phase 2 Modernization** | Last Updated: 2025-01
