//
//  MockOutlineDocument.swift
//  BirchEditorTests
//
//  Created for Protocol-Oriented Design (Phase 2)
//  Mock document for testing without NSDocument infrastructure
//

import BirchEditor
import BirchOutline
import Cocoa
import Foundation

/// Mock OutlineDocumentProtocol implementation for testing.
///
/// This mock enables testing document-dependent code without:
/// - Initializing full NSDocument infrastructure
/// - File system I/O operations
/// - Complex document lifecycle management
///
/// ## Benefits
///
/// - **Fast**: No file system overhead or document state management
/// - **Predictable**: Stub responses ensure deterministic tests
/// - **Inspectable**: Records all method calls for verification
///
/// ## Usage
///
/// ```swift
/// class DocumentTests: XCTestCase {
///     func testDocumentSave() {
///         let mockDocument = MockOutlineDocument()
///
///         // Configure document
///         mockDocument.outlineStub = mockOutline
///         mockDocument.dataStub = Data("task1\ntask2".utf8)
///
///         // Use in test
///         let data = try mockDocument.data(ofType: "com.taskpaper")
///
///         // Verify behavior
///         XCTAssertEqual(mockDocument.dataCallCount, 1)
///         XCTAssertEqual(String(data: data, encoding: .utf8), "task1\ntask2")
///     }
/// }
/// ```
///
/// ## Recording
///
/// All method calls are recorded in call counters and call arrays:
/// - `readFromDataCalls`: Records `read(from:ofType:)` calls
/// - `readFromURLCalls`: Records `read(from:ofType:)` calls for URLs
/// - `dataCallCount`: Counts `data(ofType:)` calls
/// - `writeToURLCalls`: Records `write(to:ofType:)` calls
/// - `saveCalls`: Records `save(to:ofType:for:completionHandler:)` calls
/// - `updateChangeCountCalls`: Records `updateChangeCount(_:)` calls
///
/// ## Stubbing
///
/// Set stub properties to control return values:
/// - `outlineStub`: The outline instance to return
/// - `fileURLStub`: The file URL to return
/// - `displayNameStub`: The display name to return
/// - `dataStub`: The data to return from serialization
/// - `hasUnautosavedChangesStub`: Whether document has unsaved changes
///
@MainActor
public final class MockOutlineDocument: OutlineDocumentProtocol {

    // MARK: - Stubs

    /// Stub outline instance
    public var outlineStub: OutlineType!

    /// Stub file URL
    public var fileURLStub: URL?

    /// Stub display name
    public var displayNameStub: String = "Untitled"

    /// Stub file type
    public var fileTypeStub: String? = "com.taskpaper"

    /// Stub for hasUnautosavedChanges
    public var hasUnautosavedChangesStub: Bool = false

    /// Stub data to return from data(ofType:)
    public var dataStub: Data = Data()

    /// Error to throw from read/write operations (nil = no error)
    public var errorStub: Error?

    // MARK: - Call Recording

    /// Records all calls to read(from:ofType:) with Data
    public private(set) var readFromDataCalls: [(data: Data, typeName: String)] = []

    /// Records all calls to read(from:ofType:) with URL
    public private(set) var readFromURLCalls: [(url: URL, typeName: String)] = []

    /// Counts calls to data(ofType:)
    public private(set) var dataCallCount: Int = 0

    /// Records all calls to write(to:ofType:)
    public private(set) var writeToURLCalls: [(url: URL, typeName: String)] = []

    /// Records all calls to save(to:ofType:for:completionHandler:)
    public private(set) var saveCalls: [(url: URL, typeName: String, saveOperation: NSDocument.SaveOperationType)] = []

    /// Records all calls to updateChangeCount(_:)
    public private(set) var updateChangeCountCalls: [NSDocument.ChangeType] = []

    // MARK: - Properties

    public var outline: OutlineType {
        return outlineStub
    }

    public var fileURL: URL? {
        return fileURLStub
    }

    public var displayName: String {
        return displayNameStub
    }

    public var fileType: String? {
        return fileTypeStub
    }

    public var hasUnautosavedChanges: Bool {
        return hasUnautosavedChangesStub
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Reading

    public func read(from data: Data, ofType typeName: String) throws {
        readFromDataCalls.append((data: data, typeName: typeName))
        if let error = errorStub {
            throw error
        }
    }

    public func read(from url: URL, ofType typeName: String) throws {
        readFromURLCalls.append((url: url, typeName: typeName))
        if let error = errorStub {
            throw error
        }
    }

    // MARK: - Writing

    public func data(ofType typeName: String) throws -> Data {
        dataCallCount += 1
        if let error = errorStub {
            throw error
        }
        return dataStub
    }

    public func write(to url: URL, ofType typeName: String) throws {
        writeToURLCalls.append((url: url, typeName: typeName))
        if let error = errorStub {
            throw error
        }
    }

    public func save(
        to url: URL,
        ofType typeName: String,
        for saveOperation: NSDocument.SaveOperationType,
        completionHandler: @escaping (Error?) -> Void
    ) {
        saveCalls.append((url: url, typeName: typeName, saveOperation: saveOperation))
        completionHandler(errorStub)
    }

    // MARK: - Change Tracking

    public func updateChangeCount(_ changeType: NSDocument.ChangeType) {
        updateChangeCountCalls.append(changeType)

        switch changeType {
        case .changeDone, .changeAutosaved, .changeRedone:
            hasUnautosavedChangesStub = true
        case .changeCleared, .changeDiscardable:
            hasUnautosavedChangesStub = false
        @unknown default:
            break
        }
    }

    // MARK: - Reset

    /// Resets all recorded calls and stubs to initial state.
    ///
    /// Call this in test `tearDown()` or between test cases.
    public func reset() {
        readFromDataCalls.removeAll()
        readFromURLCalls.removeAll()
        dataCallCount = 0
        writeToURLCalls.removeAll()
        saveCalls.removeAll()
        updateChangeCountCalls.removeAll()

        fileURLStub = nil
        displayNameStub = "Untitled"
        fileTypeStub = "com.taskpaper"
        hasUnautosavedChangesStub = false
        dataStub = Data()
        errorStub = nil
    }
}
