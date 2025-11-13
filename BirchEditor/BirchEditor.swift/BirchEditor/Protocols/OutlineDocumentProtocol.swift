//
//  OutlineDocumentProtocol.swift
//  BirchEditor
//
//  Created for Protocol-Oriented Design (Phase 2)
//  Protocol abstraction for document operations
//

import BirchOutline
import Cocoa
import Foundation

/// Protocol defining essential document operations for outline-based documents.
///
/// This protocol abstracts the core document lifecycle methods from `OutlineDocument`,
/// enabling dependency injection and testability.
///
/// ## Purpose
///
/// - **Dependency Injection**: Accept any document implementation in code that needs document access
/// - **Testing**: Create mock documents for fast, deterministic tests
/// - **Decoupling**: Separate document interface from NSDocument implementation details
///
/// ## Key Operations
///
/// - **Outline Access**: Read/write access to the underlying outline data structure
/// - **File I/O**: Reading from and writing to data formats
/// - **Persistence**: Saving documents to URLs
/// - **Metadata**: Document display name and file location
///
/// ## Usage
///
/// ```swift
/// func processDocument(_ document: OutlineDocumentProtocol) {
///     let outline = document.outline
///     let data = try document.data(ofType: "com.taskpaper")
///     // Process outline data
/// }
/// ```
///
/// ## Implementation Notes
///
/// - All methods must be called on the main actor
/// - Implementations should be thread-safe when accessed from main actor
/// - File operations may throw errors for I/O failures
///
@MainActor
public protocol OutlineDocumentProtocol: AnyObject {

    /// The underlying outline data structure.
    ///
    /// This is the core model object representing the hierarchical document structure.
    var outline: OutlineType { get }

    /// The file URL where this document is stored, if any.
    ///
    /// Returns `nil` for unsaved documents.
    var fileURL: URL? { get }

    /// The display name for this document.
    ///
    /// Used in UI elements like window titles and tabs.
    var displayName: String { get }

    /// The file type identifier for this document.
    ///
    /// Typically a UTI like "com.taskpaper" or "public.plain-text".
    var fileType: String? { get }

    /// Whether this document has unsaved changes.
    var hasUnautosavedChanges: Bool { get }

    // MARK: - Reading

    /// Reads document content from data.
    ///
    /// - Parameters:
    ///   - data: The serialized document data
    ///   - typeName: The file type identifier (UTI)
    /// - Throws: Errors if the data cannot be parsed
    func read(from data: Data, ofType typeName: String) throws

    /// Reads document content from a file URL.
    ///
    /// - Parameters:
    ///   - url: The file URL to read from
    ///   - typeName: The file type identifier (UTI)
    /// - Throws: Errors if the file cannot be read or parsed
    func read(from url: URL, ofType typeName: String) throws

    // MARK: - Writing

    /// Serializes document content to data.
    ///
    /// - Parameter typeName: The file type identifier (UTI)
    /// - Returns: The serialized document data
    /// - Throws: Errors if the document cannot be serialized
    func data(ofType typeName: String) throws -> Data

    /// Writes document content to a file URL.
    ///
    /// - Parameters:
    ///   - url: The destination file URL
    ///   - typeName: The file type identifier (UTI)
    /// - Throws: Errors if the file cannot be written
    func write(to url: URL, ofType typeName: String) throws

    /// Saves document content asynchronously.
    ///
    /// This is the primary save method that handles all save operations including
    /// autosave, explicit save, and save-as.
    ///
    /// - Parameters:
    ///   - url: The destination file URL
    ///   - typeName: The file type identifier (UTI)
    ///   - saveOperation: The type of save operation being performed
    ///   - completionHandler: Called when save completes or fails
    func save(
        to url: URL,
        ofType typeName: String,
        for saveOperation: NSDocument.SaveOperationType,
        completionHandler: @escaping (Error?) -> Void
    )

    // MARK: - Change Tracking

    /// Updates the document's change count.
    ///
    /// Used to track whether the document has unsaved changes.
    ///
    /// - Parameter changeType: The type of change (changed, cleared, etc.)
    func updateChangeCount(_ changeType: NSDocument.ChangeType)
}
