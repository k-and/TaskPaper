# Phase 4: Deep Architecture Evolution (6-12 months)

## Phase Overview

Phase 4 represents the most ambitious and transformative phase, addressing fundamental architectural decisions that have defined TaskPaper since its inception. This long-term phase focuses on evaluating and potentially replacing the JavaScript bridge architecture, further deepening SwiftUI adoption where appropriate, implementing Combine for reactive data flow, and establishing cloud synchronization capabilities. The objectives are to assess the viability of replacing the JavaScript model layer with pure Swift implementation, integrate Combine framework for reactive bindings and state management, expand SwiftUI usage based on Phase 3 learnings, and implement optional iCloud sync for document synchronization. Expected outcomes include significantly simplified architecture through potential JavaScript elimination, improved performance and debuggability from native Swift implementation, modern reactive patterns throughout the codebase, and enhanced user experience through cloud synchronization. This phase requires careful planning and may span multiple major releases.

---

## P4-T01: Comprehensive JavaScript Bridge Audit

**Component**: Architecture Analysis  
**Files**:
- `BirchOutline/BirchOutline.swift/Common/Sources/BirchOutline.swift`
- `BirchOutline/birch-outline.js/` (entire JavaScript codebase)
- All files using JavaScriptCore

**Technical Changes**:
1. Document complete JavaScript bridge architecture:
   - All JSContext usage and initialization
   - Swift → JavaScript method invocations
   - JavaScript → Swift callbacks
   - Data type conversions and bridging
   - Memory management patterns
2. Analyze JavaScript functionality in birch-outline.js:
   - Outline data structure implementation
   - Item path query language and parser
   - Undo/redo management
   - Serialization/deserialization
   - Attributed string handling
3. Measure JavaScript bridge overhead:
   - Performance impact of JS ↔ Swift calls
   - Memory footprint of JSContext
   - Debugging complexity
4. Assess migration feasibility:
   - Complexity of porting query language parser to Swift
   - Difficulty of replicating undo management
   - Risk level (very high due to core functionality)
5. Create detailed report: `docs/modernisation/javascript-bridge-analysis.md`
6. Recommend: migrate, keep, or hybrid approach

**Prerequisites**: None

**Success Criteria**:
```bash
test -f docs/modernisation/javascript-bridge-analysis.md
grep -q "JSContext" docs/modernisation/javascript-bridge-analysis.md
grep -q "Performance" docs/modernisation/javascript-bridge-analysis.md
grep -q "Migration Feasibility" docs/modernisation/javascript-bridge-analysis.md
grep -qE "(RECOMMEND|DECISION)" docs/modernisation/javascript-bridge-analysis.md
```

---

## P4-T02: Design Pure Swift Outline Model Architecture

**Component**: Architecture Design  
**Files**:
- `docs/modernisation/swift-outline-model-design.md` (new)

**Technical Changes**:
1. Design Swift-native outline model to replace JavaScript:
   ```swift
   // Proposed architecture
   @Observable
   final class OutlineModel {
       private(set) var items: [OutlineItem] = []
       private var undoManager: UndoManager
       
       func addItem(_ item: OutlineItem, parent: OutlineItem?, index: Int?)
       func removeItem(_ item: OutlineItem)
       func moveItem(_ item: OutlineItem, to parent: OutlineItem?, at index: Int)
       func setAttribute(_ attribute: String, value: Any?, for item: OutlineItem)
   }
   
   struct OutlineItem: Identifiable, Hashable {
       let id: UUID
       var text: String
       var attributes: [String: Any]
       var children: [OutlineItem]
       var type: ItemType
       
       enum ItemType {
           case project, task, note
       }
   }
   ```
2. Design query language interpreter in Swift:
   - Port PEG.js parser to Swift parsing library (e.g., swift-parsing)
   - Define query AST (abstract syntax tree)
   - Implement query execution engine
3. Design undo/redo system:
   - Use NSUndoManager or custom command pattern
   - Ensure performance for large documents
4. Design serialization:
   - Implement TaskPaper format parser/serializer in Swift
   - Ensure 100% compatibility with existing format
5. Estimate effort: likely 8-12 weeks of focused development
6. Document migration strategy (parallel implementation, then switch)

**Prerequisites**: P4-T01

**Success Criteria**:
```bash
test -f docs/modernisation/swift-outline-model-design.md
grep -q "OutlineModel" docs/modernisation/swift-outline-model-design.md
grep -q "query language" docs/modernisation/swift-outline-model-design.md
grep -q "undo" docs/modernisation/swift-outline-model-design.md
grep -q "serialization" docs/modernisation/swift-outline-model-design.md
```

---

## P4-T03: Implement Swift Query Language Parser

**Component**: Query Engine  
**Files**:
- `BirchOutline/BirchOutline.swift/QueryEngine/QueryParser.swift` (new)
- `BirchOutline/BirchOutline.swift/QueryEngine/QueryAST.swift` (new)
- `Package.swift` (add swift-parsing dependency)

**Technical Changes**:
1. Add swift-parsing package dependency:
   ```swift
   .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.13.0")
   ```
2. Define query AST nodes:
   ```swift
   enum QueryNode {
       case all
       case type(ItemType)
       case attribute(String, value: String?)
       case tag(String, value: String?)
       case union([QueryNode])
       case intersection([QueryNode])
       case except(QueryNode, excluding: QueryNode)
       case descendants(QueryNode)
       case ancestors(QueryNode)
   }
   ```
3. Implement parser using swift-parsing:
   ```swift
   import Parsing
   
   struct QueryParser: Parser {
       var body: some Parser<Substring, QueryNode> {
           OneOf {
               typeParser
               tagParser
               attributeParser
               unionParser
               intersectionParser
           }
       }
       
       var typeParser: some Parser<Substring, QueryNode> {
           Parse {
               OneOf {
                   "project".map { ItemType.project }
                   "task".map { ItemType.task }
                   "note".map { ItemType.note }
               }
           }
           .map { QueryNode.type($0) }
       }
       
       // Additional parsers...
   }
   ```
4. Implement comprehensive parser tests
5. Ensure 100% compatibility with JavaScript query language
6. Performance target: parsing < 1ms for typical queries

**Prerequisites**: P4-T02

**Success Criteria**:
```bash
test -f BirchOutline/BirchOutline.swift/QueryEngine/QueryParser.swift
test -f BirchOutline/BirchOutline.swift/QueryEngine/QueryAST.swift
grep -q "swift-parsing" Package.swift
grep -q "struct QueryParser: Parser" BirchOutline/BirchOutline.swift/QueryEngine/QueryParser.swift
xcodebuild -project TaskPaper.xcodeproj -scheme BirchOutline build | grep -q "BUILD SUCCEEDED"
# Verify tests pass
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchOutline -only-testing:BirchOutlineTests/QueryParserTests | grep -q "Test Succeeded"
```

---

## P4-T04: Implement Swift Query Execution Engine

**Component**: Query Engine  
**Files**:
- `BirchOutline/BirchOutline.swift/QueryEngine/QueryExecutor.swift` (new)

**Technical Changes**:
1. Implement query execution against OutlineModel:
   ```swift
   final class QueryExecutor {
       func execute(_ query: QueryNode, on items: [OutlineItem]) -> [OutlineItem] {
           switch query {
           case .all:
               return items
           case .type(let itemType):
               return items.filter { $0.type == itemType }
           case .tag(let name, let value):
               return items.filter { item in
                   if let tagValue = item.attributes["@\(name)"] as? String {
                       return value == nil || tagValue == value
                   }
                   return false
               }
           case .union(let queries):
               return Set(queries.flatMap { execute($0, on: items) }).sorted()
           case .intersection(let queries):
               guard !queries.isEmpty else { return [] }
               var result = Set(execute(queries[0], on: items))
               for query in queries.dropFirst() {
                   result.formIntersection(execute(query, on: items))
               }
               return Array(result).sorted()
           case .descendants(let parentQuery):
               let parents = execute(parentQuery, on: items)
               return parents.flatMap { getAllDescendants(of: $0) }
           // Additional cases...
           }
       }
       
       private func getAllDescendants(of item: OutlineItem) -> [OutlineItem] {
           var descendants: [OutlineItem] = []
           for child in item.children {
               descendants.append(child)
               descendants.append(contentsOf: getAllDescendants(of: child))
           }
           return descendants
       }
   }
   ```
2. Optimize for common query patterns
3. Add caching for repeated queries
4. Implement comprehensive execution tests
5. Performance target: execute typical queries in < 10ms for 1000-item documents

**Prerequisites**: P4-T03

**Success Criteria**:
```bash
test -f BirchOutline/BirchOutline.swift/QueryEngine/QueryExecutor.swift
grep -q "class QueryExecutor" BirchOutline/BirchOutline.swift/QueryEngine/QueryExecutor.swift
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchOutline -only-testing:BirchOutlineTests/QueryExecutorTests | grep -q "Test Succeeded"
```

---

## P4-T05: Implement Swift Outline Model with Observation

**Component**: Model Layer  
**Files**:
- `BirchOutline/BirchOutline.swift/Model/SwiftOutlineModel.swift` (new)
- `BirchOutline/BirchOutline.swift/Model/OutlineItem.swift` (new)

**Technical Changes**:
1. Implement Observable outline model using Swift 5.9+ Observation:
   ```swift
   import Observation
   
   @Observable
   @MainActor
   final class SwiftOutlineModel {
       private(set) var rootItem: OutlineItem
       private var undoManager: UndoManager?
       
       init(undoManager: UndoManager? = nil) {
           self.rootItem = OutlineItem(text: "", type: .note, children: [])
           self.undoManager = undoManager
       }
       
       func addItem(_ item: OutlineItem, to parent: OutlineItem, at index: Int) {
           let oldChildren = parent.children
           var newChildren = parent.children
           newChildren.insert(item, at: index)
           parent.children = newChildren
           
           // Register undo
           undoManager?.registerUndo(withTarget: self) { target in
               target.removeItem(item, from: parent)
           }
           undoManager?.setActionName("Add Item")
       }
       
       func removeItem(_ item: OutlineItem, from parent: OutlineItem) {
           guard let index = parent.children.firstIndex(where: { $0.id == item.id }) else { return }
           
           let removed = parent.children.remove(at: index)
           
           // Register undo
           undoManager?.registerUndo(withTarget: self) { target in
               target.addItem(removed, to: parent, at: index)
           }
           undoManager?.setActionName("Delete Item")
       }
       
       func moveItem(_ item: OutlineItem, from source: OutlineItem, to destination: OutlineItem, at index: Int) {
           // Implement move with undo support
       }
       
       func setAttribute(_ key: String, value: Any?, for item: OutlineItem) {
           let oldValue = item.attributes[key]
           item.attributes[key] = value
           
           // Register undo
           undoManager?.registerUndo(withTarget: self) { target in
               target.setAttribute(key, value: oldValue, for: item)
           }
       }
       
       func executeQuery(_ queryString: String) throws -> [OutlineItem] {
           let parser = QueryParser()
           let query = try parser.parse(queryString)
           let executor = QueryExecutor()
           return executor.execute(query, on: allItems())
       }
       
       private func allItems() -> [OutlineItem] {
           // Flatten tree to array
       }
   }
   
   final class OutlineItem: Identifiable {
       let id: UUID
       var text: String
       var attributes: [String: Any]
       var children: [OutlineItem]
       var type: ItemType
       
       enum ItemType: Codable {
           case project, task, note
       }
       
       init(text: String, type: ItemType, children: [OutlineItem] = []) {
           self.id = UUID()
           self.text = text
           self.type = type
           self.children = children
           self.attributes = [:]
       }
   }
   ```
2. Ensure all mutations trigger observation updates
3. Implement efficient change tracking
4. Support large documents (10,000+ items)
5. Add comprehensive unit tests

**Prerequisites**: P4-T03, P4-T04

**Success Criteria**:
```bash
test -f BirchOutline/BirchOutline.swift/Model/SwiftOutlineModel.swift
grep -q "@Observable" BirchOutline/BirchOutline.swift/Model/SwiftOutlineModel.swift
grep -q "class SwiftOutlineModel" BirchOutline/BirchOutline.swift/Model/SwiftOutlineModel.swift
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchOutline -only-testing:BirchOutlineTests/SwiftOutlineModelTests | grep -q "Test Succeeded"
```

---

## P4-T06: Implement TaskPaper Format Parser in Swift

**Component**: Serialization  
**Files**:
- `BirchOutline/BirchOutline.swift/Serialization/TaskPaperParser.swift` (new)

**Technical Changes**:
1. Implement TaskPaper format parser:
   ```swift
   struct TaskPaperParser {
       func parse(_ text: String) throws -> OutlineItem {
           let lines = text.components(separatedBy: .newlines)
           var rootItem = OutlineItem(text: "", type: .note, children: [])
           var stack: [(item: OutlineItem, level: Int)] = [(rootItem, -1)]
           
           for line in lines {
               let (level, content) = parseIndentation(line)
               let item = parseItem(content)
               
               // Find correct parent based on indentation
               while stack.last!.level >= level {
                   stack.removeLast()
               }
               
               stack.last!.item.children.append(item)
               stack.append((item, level))
           }
           
           return rootItem
       }
       
       private func parseIndentation(_ line: String) -> (level: Int, content: String) {
           var level = 0
           var startIndex = line.startIndex
           
           for char in line {
               if char == "\t" {
                   level += 1
                   startIndex = line.index(after: startIndex)
               } else {
                   break
               }
           }
           
           return (level, String(line[startIndex...]))
       }
       
       private func parseItem(_ content: String) -> OutlineItem {
           if content.hasSuffix(":") {
               // Project
               let text = String(content.dropLast())
               return OutlineItem(text: text, type: .project)
           } else if content.hasPrefix("- ") {
               // Task
               let text = String(content.dropFirst(2))
               let (plainText, tags) = extractTags(from: text)
               var item = OutlineItem(text: plainText, type: .task)
               item.attributes = tags
               return item
           } else {
               // Note
               let (plainText, tags) = extractTags(from: content)
               var item = OutlineItem(text: plainText, type: .note)
               item.attributes = tags
               return item
           }
       }
       
       private func extractTags(from text: String) -> (text: String, tags: [String: Any]) {
           var tags: [String: Any] = [:]
           var plainText = text
           
           // Regex to find @tag or @tag(value)
           let pattern = #"@(\w+)(?:\(([^)]+)\))?"#
           let regex = try! NSRegularExpression(pattern: pattern)
           let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
           
           for match in matches {
               let tagName = String(text[Range(match.range(at: 1), in: text)!])
               if match.range(at: 2).location != NSNotFound {
                   let tagValue = String(text[Range(match.range(at: 2), in: text)!])
                   tags["@\(tagName)"] = tagValue
               } else {
                   tags["@\(tagName)"] = true
               }
           }
           
           return (plainText, tags)
       }
   }
   ```
2. Implement serializer (OutlineItem → TaskPaper text)
3. Ensure 100% format compatibility with JavaScript version
4. Add extensive parser tests with edge cases
5. Test round-trip: parse → modify → serialize → parse

**Prerequisites**: P4-T05

**Success Criteria**:
```bash
test -f BirchOutline/BirchOutline.swift/Serialization/TaskPaperParser.swift
grep -q "struct TaskPaperParser" BirchOutline/BirchOutline.swift/Serialization/TaskPaperParser.swift
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchOutline -only-testing:BirchOutlineTests/TaskPaperParserTests | grep -q "Test Succeeded"
```

---

## P4-T07: Create Parallel Swift Outline Implementation

**Component**: Architecture Migration  
**Files**:
- `BirchOutline/BirchOutline.swift/Common/Sources/SwiftBirchOutline.swift` (new)

**Technical Changes**:
1. Create new Swift-only BirchOutline class parallel to existing JavaScript-based one:
   ```swift
   @MainActor
   final class SwiftBirchOutline {
       private let model: SwiftOutlineModel
       private let parser: TaskPaperParser
       
       init(undoManager: UndoManager? = nil) {
           self.model = SwiftOutlineModel(undoManager: undoManager)
           self.parser = TaskPaperParser()
       }
       
       func loadFromSerialization(_ text: String) throws {
           let rootItem = try parser.parse(text)
           model.rootItem = rootItem
       }
       
       func serialization() -> String {
           return TaskPaperSerializer().serialize(model.rootItem)
       }
       
       func executeQuery(_ query: String) throws -> [OutlineItem] {
           return try model.executeQuery(query)
       }
       
       // Bridge existing BirchOutline API
   }
   ```
2. Implement feature parity with JavaScript BirchOutline
3. Add runtime flag to choose implementation:
   ```swift
   enum BirchOutlineImplementation {
       case javascript
       case swift
       
       static var preferred: BirchOutlineImplementation {
           #if DEBUG
           return UserDefaults.standard.bool(forKey: "UseSwiftOutline") ? .swift : .javascript
           #else
           return .javascript // Stable release uses JavaScript until Swift version proven
           #endif
       }
   }
   ```
4. Keep both implementations functional during transition
5. Allow A/B testing and gradual rollout

**Prerequisites**: P4-T05, P4-T06

**Success Criteria**:
```bash
test -f BirchOutline/BirchOutline.swift/Common/Sources/SwiftBirchOutline.swift
grep -q "class SwiftBirchOutline" BirchOutline/BirchOutline.swift/Common/Sources/SwiftBirchOutline.swift
xcodebuild -project TaskPaper.xcodeproj -scheme BirchOutline build | grep -q "BUILD SUCCEEDED"
```

---

## P4-T08: Add Feature Flag System for Implementation Switching

**Component**: Configuration  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/FeatureFlags.swift` (new)
- `TaskPaper/Settings.bundle/Root.plist` (update)

**Technical Changes**:
1. Create feature flag system:
   ```swift
   @Observable
   final class FeatureFlags {
       static let shared = FeatureFlags()
       
       @AppStorage("useSwiftOutlineModel")
       var useSwiftOutlineModel: Bool = false
       
       @AppStorage("useCombineBindings")
       var useCombineBindings: Bool = false
       
       @AppStorage("enableiCloudSync")
       var enableiCloudSync: Bool = false
       
       // Debug-only flags
       #if DEBUG
       var forceTextKit1: Bool = false
       var logPerformanceMetrics: Bool = true
       #endif
   }
   ```
2. Add UI in preferences to toggle Swift outline (Debug builds only)
3. Update document loading to respect feature flag:
   ```swift
   func createOutline() -> BirchOutline {
       if FeatureFlags.shared.useSwiftOutlineModel {
           return SwiftBirchOutline()
       } else {
           return BirchOutline() // JavaScript-based
       }
   }
   ```
4. Add telemetry to track which implementation users prefer
5. Document feature flags in README

**Prerequisites**: P4-T07

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditor/FeatureFlags.swift
grep -q "useSwiftOutlineModel" BirchEditor/BirchEditor.swift/BirchEditor/FeatureFlags.swift
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct build | grep -q "BUILD SUCCEEDED"
```

---

## P4-T09: Extensive Testing of Swift Outline Implementation

**Component**: Testing  
**Files**:
- `BirchOutline/BirchOutline.swift/BirchOutlineTests/SwiftImplementationTests.swift` (new)

**Technical Changes**:
1. Create comprehensive test suite comparing JavaScript vs Swift implementations:
   ```swift
   final class SwiftImplementationTests: XCTestCase {
       func testFeatureParity_BasicOperations() throws {
           let jsOutline = BirchOutline()
           let swiftOutline = SwiftBirchOutline()
           
           // Load same document in both
           let testDoc = "Project:\n\t- Task @done\n\tNote"
           jsOutline.loadFromSerialization(testDoc)
           try swiftOutline.loadFromSerialization(testDoc)
           
           // Verify identical serialization
           XCTAssertEqual(jsOutline.serialization(), swiftOutline.serialization())
       }
       
       func testFeatureParity_QueryExecution() throws {
           let jsOutline = BirchOutline()
           let swiftOutline = SwiftBirchOutline()
           
           // Load sample document
           let testDoc = loadSampleDocument()
           jsOutline.loadFromSerialization(testDoc)
           try swiftOutline.loadFromSerialization(testDoc)
           
           // Execute same queries on both
           let queries = ["@done", "project", "//task", "@due < 2025-12-01"]
           for query in queries {
               let jsResults = jsOutline.executeQuery(query)
               let swiftResults = try swiftOutline.executeQuery(query)
               XCTAssertEqual(jsResults.count, swiftResults.count, "Query: \(query)")
           }
       }
       
       func testFeatureParity_UndoRedo() throws {
           // Test undo/redo behavior matches
       }
       
       func testPerformance_SwiftVsJavaScript() throws {
           // Benchmark both implementations
       }
   }
   ```
2. Test all query language features
3. Test undo/redo in both implementations
4. Verify serialization compatibility
5. Load test with 10,000+ item documents
6. Ensure 100% feature parity before considering switch

**Prerequisites**: P4-T08

**Success Criteria**:
```bash
test -f BirchOutline/BirchOutline.swift/BirchOutlineTests/SwiftImplementationTests.swift
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchOutline -only-testing:BirchOutlineTests/SwiftImplementationTests | grep -q "Test Succeeded"
```

---

## P4-T10: Performance Benchmark Swift vs JavaScript Implementation

**Component**: Performance Analysis  
**Files**:
- `docs/modernisation/swift-vs-javascript-performance.md` (new)

**Technical Changes**:
1. Benchmark key operations:
   - Document loading (various sizes)
   - Query execution (simple and complex queries)
   - Item manipulation (add, remove, move)
   - Undo/redo performance
   - Memory footprint
   - Serialization speed
2. Create performance comparison document
3. Target: Swift should be 2-5x faster than JavaScript bridge
4. Document any performance regressions
5. If Swift is slower, investigate and optimize
6. Decision point: proceed with Swift if performance is better or equal

**Prerequisites**: P4-T09

**Success Criteria**:
```bash
test -f docs/modernisation/swift-vs-javascript-performance.md
grep -q "JavaScript" docs/modernisation/swift-vs-javascript-performance.md
grep -q "Swift" docs/modernisation/swift-vs-javascript-performance.md
grep -qE "(faster|slower|equal)" docs/modernisation/swift-vs-javascript-performance.md
```

---

## P4-T11: Audit Combine Adoption Opportunities

**Component**: Reactive Programming  
**Files**:
- All files with KVO, NotificationCenter, custom observers
- `docs/modernisation/combine-adoption-plan.md` (new)

**Technical Changes**:
1. Find all reactive patterns in codebase:
   - KVO usage: `grep -r "observe" --include="*.swift"`
   - NotificationCenter: `grep -r "NotificationCenter" --include="*.swift"`
   - Custom observer patterns: delegate callbacks, closures
2. Categorize by complexity:
   - **Simple**: Single property observations
   - **Medium**: Multiple property coordination
   - **Complex**: Async data streams, error handling
3. Identify candidates for Combine:
   - Document property changes
   - User input streams (search, filtering)
   - Async operations (file loading, network)
4. Design Combine architecture:
   - Publishers for model changes
   - Subscribers in view controllers
   - Operators for transformations
5. Document migration strategy: `combine-adoption-plan.md`

**Prerequisites**: None

**Success Criteria**:
```bash
test -f docs/modernisation/combine-adoption-plan.md
grep -q "Combine" docs/modernisation/combine-adoption-plan.md
grep -q "Publisher" docs/modernisation/combine-adoption-plan.md
grep -q "KVO" docs/modernisation/combine-adoption-plan.md
```

---

## P4-T12: Add Combine Publishers to SwiftOutlineModel

**Component**: Reactive Model  
**Files**:
- `BirchOutline/BirchOutline.swift/Model/SwiftOutlineModel.swift`

**Technical Changes**:
1. Add Combine publishers to model:
   ```swift
   import Combine
   
   @Observable
   @MainActor
   final class SwiftOutlineModel {
       // Existing properties...
       
       // Combine publishers
       let itemsDidChange = PassthroughSubject<Void, Never>()
       let itemAdded = PassthroughSubject<OutlineItem, Never>()
       let itemRemoved = PassthroughSubject<OutlineItem, Never>()
       let itemModified = PassthroughSubject<OutlineItem, Never>()
       
       @Published private(set) var itemCount: Int = 0
       @Published private(set) var hasUnsavedChanges: Bool = false
       
       func addItem(_ item: OutlineItem, to parent: OutlineItem, at index: Int) {
           // Existing logic...
           
           // Publish change
           itemAdded.send(item)
           itemsDidChange.send()
           updateItemCount()
           hasUnsavedChanges = true
       }
       
       // Additional methods publish changes...
   }
   ```
2. Ensure all mutations publish appropriate events
3. Add @Published properties for derived state
4. Document publisher contracts
5. Add tests verifying publishers fire correctly

**Prerequisites**: P4-T05, P4-T11

**Success Criteria**:
```bash
grep -q "import Combine" BirchOutline/BirchOutline.swift/Model/SwiftOutlineModel.swift
grep -q "PassthroughSubject" BirchOutline/BirchOutline.swift/Model/SwiftOutlineModel.swift
grep -q "@Published" BirchOutline/BirchOutline.swift/Model/SwiftOutlineModel.swift
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchOutline | grep -q "Test Succeeded"
```

---

## P4-T13: Convert Search Bar to Use Combine

**Component**: Search UI  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/SearchBarViewController.swift`

**Technical Changes**:
1. Replace manual search handling with Combine:
   ```swift
   import Combine
   
   @MainActor
   final class SearchBarViewController: NSViewController {
       @IBOutlet weak var searchField: NSSearchField!
       private var cancellables = Set<AnyCancellable>()
       var outlineEditor: OutlineEditorProtocol?
       
       override func viewDidLoad() {
           super.viewDidLoad()
           setupSearchPublisher()
       }
       
       private func setupSearchPublisher() {
           NotificationCenter.default
               .publisher(for: NSControl.textDidChangeNotification, object: searchField)
               .map { ($0.object as? NSSearchField)?.stringValue ?? "" }
               .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
               .removeDuplicates()
               .sink { [weak self] query in
                   self?.performSearch(query)
               }
               .store(in: &cancellables)
       }
       
       private func performSearch(_ query: String) {
           guard let editor = outlineEditor else { return }
           do {
               let results = try editor.executeQuery(query)
               updateResults(results)
           } catch {
               showError(error)
           }
       }
   }
   ```
2. Add debouncing for search input (300ms)
3. Handle errors gracefully in Combine pipeline
4. Remove manual NotificationCenter observation
5. Test search responsiveness and accuracy

**Prerequisites**: P4-T11

**Success Criteria**:
```bash
grep -q "import Combine" BirchEditor/BirchEditor.swift/BirchEditor/SearchBarViewController.swift
grep -q "debounce" BirchEditor/BirchEditor.swift/BirchEditor/SearchBarViewController.swift
grep -q "sink" BirchEditor/BirchEditor.swift/BirchEditor/SearchBarViewController.swift
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct build | grep -q "BUILD SUCCEEDED"
```

---

## P4-T14: Convert Sidebar to Use Combine

**Component**: Sidebar UI  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineSidebarViewController.swift`

**Technical Changes**:
1. Use Combine to react to outline changes:
   ```swift
   @MainActor
   final class OutlineSidebarViewController: NSViewController {
       var outlineModel: SwiftOutlineModel?
       private var cancellables = Set<AnyCancellable>()
       
       override func viewDidLoad() {
           super.viewDidLoad()
           setupBindings()
       }
       
       private func setupBindings() {
           // React to outline changes
           outlineModel?.itemsDidChange
               .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
               .sink { [weak self] _ in
                   self?.reloadSidebar()
               }
               .store(in: &cancellables)
           
           // Update tag list when items change
           outlineModel?.itemsDidChange
               .map { [weak self] _ in
                   self?.extractAllTags() ?? []
               }
               .assign(to: \.availableTags, on: self)
               .store(in: &cancellables)
       }
       
       @Published private(set) var availableTags: [String] = []
       
       private func extractAllTags() -> [String] {
           // Extract unique tags from all items
       }
   }
   ```
2. Bind sidebar UI to model publishers
3. Remove manual refresh calls where possible
4. Optimize updates with debouncing
5. Test sidebar updates correctly with model changes

**Prerequisites**: P4-T12

**Success Criteria**:
```bash
grep -q "import Combine" BirchEditor/BirchEditor.swift/BirchEditor/OutlineSidebarViewController.swift
grep -q "sink" BirchEditor/BirchEditor.swift/BirchEditor/OutlineSidebarViewController.swift
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-Direct build | grep -q "BUILD SUCCEEDED"
```

---

## P4-T15: Replace Custom Observers with Combine

**Component**: Reactive Patterns  
**Files**:
- All files with custom observer implementations

**Technical Changes**:
1. Find custom observer patterns: `grep -r "Observer" --include="*.swift"`
2. Replace with Combine where appropriate:
   ```swift
   // Before: Custom observer pattern
   protocol OutlineObserver: AnyObject {
       func outlineDidChange()
   }
   
   class OutlineManager {
       private var observers: [Weak<OutlineObserver>] = []
       
       func addObserver(_ observer: OutlineObserver) { ... }
       func notifyObservers() {
           observers.forEach { $0.value?.outlineDidChange() }
       }
   }
   
   // After: Combine
   class OutlineManager {
       let outlineDidChange = PassthroughSubject<Void, Never>()
       
       func makeChange() {
           // ... do work
           outlineDidChange.send()
       }
   }
   ```
3. Remove weak reference management (Combine handles it)
4. Simplify notification code
5. Test all observer conversions

**Prerequisites**: P4-T11

**Success Criteria**:
```bash
# Verify reduction in custom observer code
echo "Manual verification: Check diff showing custom observer removal"
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchEditor | grep -q "Test Succeeded"
```

---

## P4-T16: Design iCloud Sync Architecture

**Component**: Cloud Sync  
**Files**:
- `docs/modernisation/icloud-sync-design.md` (new)

**Technical Changes**:
1. Research iCloud document sync options:
   - **UIDocument + iCloud Drive**: Automatic sync, simplest
   - **NSUbiquitousKeyValueStore**: For small data only
   - **CloudKit**: Full control, most complex
   - **NSFileCoordinator**: Required for iCloud Drive
2. Design sync architecture:
   ```swift
   // Proposed: Use NSDocument + iCloud Drive
   class TaskPaperDocument: NSDocument {
       override class var autosavesInPlace: Bool { true }
       
       override func save(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) async throws {
           // Use NSFileCoordinator for iCloud
           let coordinator = NSFileCoordinator(filePresenter: self)
           try await coordinator.coordinate(writingItemAt: url, options: .forReplacing) { url in
               try await super.save(to: url, ofType: typeName, for: saveOperation)
           }
       }
   }
   ```
3. Handle sync conflicts:
   - Present conflict resolution UI
   - Allow user to choose version
   - Option to merge changes (complex)
4. Design user experience:
   - Opt-in iCloud sync in preferences
   - Indicator for sync status
   - Graceful offline handling
5. Document privacy and security considerations
6. Estimate effort: 4-6 weeks

**Prerequisites**: None

**Success Criteria**:
```bash
test -f docs/modernisation/icloud-sync-design.md
grep -q "iCloud" docs/modernisation/icloud-sync-design.md
grep -q "NSFileCoordinator" docs/modernisation/icloud-sync-design.md
grep -q "conflict" docs/modernisation/icloud-sync-design.md
```

---

## P4-T17: Add iCloud Entitlements and Configuration

**Component**: Cloud Sync Setup  
**Files**:
- `TaskPaper/TaskPaper.entitlements`
- `TaskPaper.xcodeproj/project.pbxproj`
- `TaskPaper/Info.plist`

**Technical Changes**:
1. Add iCloud entitlements:
   ```xml
   <key>com.apple.developer.icloud-container-identifiers</key>
   <array>
       <string>iCloud.com.hogbaysoftware.TaskPaper</string>
   </array>
   <key>com.apple.developer.icloud-services</key>
   <array>
       <string>CloudDocuments</string>
   </array>
   <key>com.apple.developer.ubiquity-container-identifiers</key>
   <array>
       <string>iCloud.com.hogbaysoftware.TaskPaper</string>
   </array>
   ```
2. Enable iCloud capability in Xcode project
3. Update Info.plist with document types supporting iCloud
4. Configure iCloud container in Apple Developer portal
5. Update provisioning profiles for all targets (Direct, AppStore, Setapp)
6. Note: Setapp target may not support iCloud (verify)

**Prerequisites**: P4-T16

**Success Criteria**:
```bash
grep -q "com.apple.developer.icloud" TaskPaper/TaskPaper.entitlements
grep -q "CloudDocuments" TaskPaper/TaskPaper.entitlements
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-AppStore -configuration Debug build | grep -q "BUILD SUCCEEDED"
```

---

## P4-T18: Implement iCloud Document Sync

**Component**: Cloud Sync  
**Files**:
- `TaskPaper/TaskPaperDocument.swift`
- `TaskPaper/CloudSync/iCloudDocumentSync.swift` (new)

**Technical Changes**:
1. Update TaskPaperDocument for iCloud:
   ```swift
   class TaskPaperDocument: OutlineDocument {
       private var fileCoordinator: NSFileCoordinator?
       
       override func save(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) async throws {
           if url.pathExtension == "taskpaper" && isICloudURL(url) {
               // Use file coordinator for iCloud
               let coordinator = NSFileCoordinator(filePresenter: self)
               var coordinationError: NSError?
               var saveError: Error?
               
               coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: &coordinationError) { coordinated in
                   do {
                       try super.save(to: coordinated, ofType: typeName, for: saveOperation)
                   } catch {
                       saveError = error
                   }
               }
               
               if let error = coordinationError ?? saveError {
                   throw error
               }
           } else {
               try await super.save(to: url, ofType: typeName, for: saveOperation)
           }
       }
       
       override func presentedItemDidChange() {
           // Handle external changes (from iCloud sync)
           Task { @MainActor in
               await reloadFromFile()
           }
       }
       
       private func isICloudURL(_ url: URL) -> Bool {
           return FileManager.default.isUbiquitousItem(at: url)
       }
   }
   ```
2. Implement conflict resolution UI
3. Handle metadata updates
4. Add sync status indicator in UI
5. Test with multiple devices syncing same document

**Prerequisites**: P4-T17

**Success Criteria**:
```bash
test -f TaskPaper/CloudSync/iCloudDocumentSync.swift
grep -q "NSFileCoordinator" TaskPaper/TaskPaperDocument.swift
grep -q "presentedItemDidChange" TaskPaper/TaskPaperDocument.swift
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-AppStore build | grep -q "BUILD SUCCEEDED"
echo "Manual test: Enable iCloud, create document, verify sync to another device"
```

---

## P4-T19: Implement Conflict Resolution UI

**Component**: Cloud Sync  
**Files**:
- `TaskPaper/CloudSync/ConflictResolutionView.swift` (new, SwiftUI)

**Technical Changes**:
1. Create SwiftUI conflict resolution interface:
   ```swift
   struct ConflictResolutionView: View {
       let localVersion: TaskPaperDocument
       let cloudVersion: TaskPaperDocument
       let onResolve: (ConflictResolution) -> Void
       
       enum ConflictResolution {
           case keepLocal
           case keepCloud
           case merge
       }
       
       var body: some View {
           VStack {
               Text("Sync Conflict Detected")
                   .font(.headline)
               
               Text("This document has been modified on another device.")
                   .foregroundColor(.secondary)
               
               HStack(spacing: 20) {
                   VStack {
                       Text("Local Version")
                           .font(.subheadline)
                       Text(localVersion.modificationDate?.formatted() ?? "Unknown")
                       Button("Use This Version") {
                           onResolve(.keepLocal)
                       }
                   }
                   
                   VStack {
                       Text("iCloud Version")
                           .font(.subheadline)
                       Text(cloudVersion.modificationDate?.formatted() ?? "Unknown")
                       Button("Use This Version") {
                           onResolve(.keepCloud)
                       }
                   }
               }
               
               Button("Compare Versions") {
                   // Show diff view
               }
               .disabled(true) // Phase 5 feature
           }
           .padding()
           .frame(width: 500, height: 300)
       }
   }
   ```
2. Present conflict UI when detected
3. Implement "Keep Local" and "Keep Cloud" options
4. Document merge strategy (manual for now)
5. Test conflict detection and resolution

**Prerequisites**: P4-T18

**Success Criteria**:
```bash
test -f TaskPaper/CloudSync/ConflictResolutionView.swift
grep -q "ConflictResolutionView: View" TaskPaper/CloudSync/ConflictResolutionView.swift
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-AppStore build | grep -q "BUILD SUCCEEDED"
```

---

## P4-T20: Add Sync Status Indicator to UI

**Component**: Cloud Sync UI  
**Files**:
- `BirchEditor/BirchEditor.swift/BirchEditor/SyncStatusView.swift` (new, SwiftUI)
- `BirchEditor/BirchEditor.swift/BirchEditor/OutlineEditorWindowController.swift`

**Technical Changes**:
1. Create sync status indicator:
   ```swift
   struct SyncStatusView: View {
       @ObservedObject var syncManager: SyncStatusManager
       
       var body: some View {
           HStack(spacing: 4) {
               Image(systemName: syncManager.iconName)
                   .foregroundColor(syncManager.iconColor)
               
               if syncManager.isSyncing {
                   ProgressView()
                       .scaleEffect(0.7)
               }
               
               Text(syncManager.statusText)
                   .font(.caption)
                   .foregroundColor(.secondary)
           }
           .padding(.horizontal, 8)
           .padding(.vertical, 4)
           .background(Color.gray.opacity(0.1))
           .cornerRadius(4)
       }
   }
   
   @MainActor
   final class SyncStatusManager: ObservableObject {
       @Published var isSyncing: Bool = false
       @Published var lastSyncDate: Date?
       @Published var syncError: Error?
       
       var iconName: String {
           if let _ = syncError {
               return "exclamationmark.icloud"
           } else if isSyncing {
               return "icloud.and.arrow.up"
           } else {
               return "icloud"
           }
       }
       
       var statusText: String {
           if let error = syncError {
               return "Sync Error"
           } else if isSyncing {
               return "Syncing..."
           } else if let date = lastSyncDate {
               return "Synced \(date.formatted(.relative(presentation: .named)))"
           } else {
               return "Not synced"
           }
       }
   }
   ```
2. Embed in window title bar or toolbar
3. Update status based on iCloud sync events
4. Show error state when sync fails
5. Make status clickable to show details

**Prerequisites**: P4-T18

**Success Criteria**:
```bash
test -f BirchEditor/BirchEditor.swift/BirchEditor/SyncStatusView.swift
grep -q "SyncStatusView: View" BirchEditor/BirchEditor.swift/BirchEditor/SyncStatusView.swift
xcodebuild -project TaskPaper.xcodeproj -scheme TaskPaper-AppStore build | grep -q "BUILD SUCCEEDED"
```

---

## P4-T21: Explore Full SwiftUI Editor (Research Phase)

**Component**: SwiftUI Architecture  
**Files**:
- `docs/modernisation/swiftui-editor-feasibility.md` (new)

**Technical Changes**:
1. Research TextEditor capabilities in SwiftUI:
   - Attribute support (limited in SwiftUI)
   - Custom layout capabilities
   - Performance with large documents
   - Disclosure triangle/handle integration
2. Evaluate SwiftUI alternatives:
   - Use NSViewRepresentable to wrap AppKit editor (hybrid)
   - Build custom text editor using Text and Layout APIs
   - Wait for future SwiftUI text improvements
3. Create proof-of-concept simple SwiftUI editor:
   ```swift
   struct OutlineEditorSwiftUI: View {
       @Bindable var model: SwiftOutlineModel
       
       var body: some View {
           List(model.rootItem.children, children: \.children) { item in
               OutlineItemRow(item: item)
           }
       }
   }
   
   struct OutlineItemRow: View {
       let item: OutlineItem
       
       var body: some View {
           HStack {
               if !item.children.isEmpty {
                   Image(systemName: "chevron.right")
               }
               
               Text(item.text)
               
               ForEach(item.tags, id: \.self) { tag in
                   Text(tag)
                       .font(.caption)
                       .foregroundColor(.secondary)
               }
           }
       }
   }
   ```
4. Test performance and feature parity
5. Document limitations and challenges
6. Decision: likely **not feasible** for full editor in SwiftUI yet
7. Recommendation: Keep AppKit/TextKit 2 editor, use SwiftUI for auxiliary UI

**Prerequisites**: P3 tasks complete (SwiftUI experience gained)

**Success Criteria**:
```bash
test -f docs/modernisation/swiftui-editor-feasibility.md
grep -q "SwiftUI" docs/modernisation/swiftui-editor-feasibility.md
grep -q "TextEditor" docs/modernisation/swiftui-editor-feasibility.md
grep -qE "(FEASIBLE|NOT FEASIBLE|RECOMMEND)" docs/modernisation/swiftui-editor-feasibility.md
```

---

## P4-T22: Comprehensive Testing of Phase 4 Features

**Component**: Testing  
**Files**:
- `TaskPaperTests/Phase4IntegrationTests.swift` (new)

**Technical Changes**:
1. Create end-to-end tests for Phase 4:
   ```swift
   final class Phase4IntegrationTests: XCTestCase {
       func testSwiftOutlineFullWorkflow() async throws {
           // Test complete Swift outline implementation
           let document = TaskPaperDocument()
           document.useSwiftImplementation = true
           
           // Load document
           let url = Bundle(for: type(of: self)).url(forResource: "sample", withExtension: "taskpaper")!
           try await document.read(from: url, ofType: "com.taskpaper.text")
           
           // Modify
           try document.outline.addItem(...)
           
           // Query
           let results = try document.outline.executeQuery("@done")
           XCTAssertGreaterThan(results.count, 0)
           
           // Save
           let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.taskpaper")
           try await document.save(to: tempURL, ofType: "com.taskpaper.text", for: .saveOperation)
           
           // Reload
           let reloaded = TaskPaperDocument()
           try await reloaded.read(from: tempURL, ofType: "com.taskpaper.text")
           
           XCTAssertEqual(document.outline.serialization(), reloaded.outline.serialization())
       }
       
       func testCombineReactivity() throws {
           // Test Combine bindings work correctly
       }
       
       func testiCloudSync() async throws {
           // Test iCloud document sync (requires entitlements and signed build)
       }
   }
   ```
2. Test Swift outline implementation thoroughly
3. Test Combine integrations
4. Test iCloud sync (may require manual testing)
5. Verify performance targets met
6. Test on multiple macOS versions

**Prerequisites**: All P4 implementation tasks (P4-T07 through P4-T20)

**Success Criteria**:
```bash
test -f TaskPaperTests/Phase4IntegrationTests.swift
xcodebuild test -project TaskPaper.xcodeproj -scheme TaskPaper-Direct -only-testing:TaskPaperTests/Phase4IntegrationTests | grep -q "Test Succeeded"
```

---

## P4-T23: Performance Validation of Phase 4 Changes

**Component**: Performance Testing  
**Files**:
- `docs/modernisation/phase4-performance-report.md` (new)

**Technical Changes**:
1. Benchmark all Phase 4 changes:
   - Swift outline vs JavaScript: load, query, modify times
   - Combine overhead: measure publisher impact
   - iCloud sync: measure sync latency and conflict resolution
   - Memory usage: compare JavaScript vs Swift implementations
2. Compare against Phase 3 baseline
3. Target improvements:
   - Swift outline: 2-5x faster than JavaScript
   - Combine: negligible overhead (< 5%)
   - iCloud sync: < 2s initial sync for typical documents
4. Document any regressions and mitigations
5. Create performance dashboard for ongoing monitoring

**Prerequisites**: P4-T22

**Success Criteria**:
```bash
test -f docs/modernisation/phase4-performance-report.md
grep -q "Swift outline" docs/modernisation/phase4-performance-report.md
grep -q "Combine" docs/modernisation/phase4-performance-report.md
grep -q "iCloud" docs/modernisation/phase4-performance-report.md
grep -qE "[0-9]+x faster" docs/modernisation/phase4-performance-report.md
```

---

## P4-T24: Update Code Coverage Metrics

**Component**: Testing Infrastructure  
**Files**:
- `docs/modernisation/phase4-coverage-report.txt` (new)

**Technical Changes**:
1. Run full test suite with coverage:
   ```bash
   xcodebuild test -project TaskPaper.xcodeproj -scheme TaskPaper-Direct -enableCodeCoverage YES
   xcrun xccov view --report $(find ~/Library/Developer/Xcode/DerivedData -name '*.xcresult' | head -1) > docs/modernisation/phase4-coverage-report.txt
   ```
2. Target: 80%+ code coverage (up from 75% in Phase 3)
3. Analyze coverage of new Swift outline model
4. Check Combine integration coverage
5. Verify iCloud sync code paths tested
6. Compare with Phase 3 baseline

**Prerequisites**: P4-T22

**Success Criteria**:
```bash
test -f docs/modernisation/phase4-coverage-report.txt
grep -q "%" docs/modernisation/phase4-coverage-report.txt
echo "Verify coverage >= 80%"
```

---

## P4-T25: Document Architecture Evolution

**Component**: Documentation  
**Files**:
- `docs/modernisation/Architecture-Evolution.md` (new)

**Technical Changes**:
1. Create comprehensive architecture documentation:
   - Original architecture (JavaScript bridge, AppKit)
   - Phase-by-phase evolution
   - Current architecture (Swift outline, Combine, SwiftUI hybrid)
   - Rationale for major decisions
2. Document JavaScript → Swift migration:
   - Why the change was made
   - What was gained (performance, debuggability)
   - What was lost (if anything)
   - Lessons learned
3. Document Combine adoption:
   - Patterns used
   - Benefits realized
   - Where Combine is used vs not used
4. Document iCloud sync implementation:
   - Architecture decisions
   - Conflict resolution strategy
   - Privacy and security considerations
5. Create architecture diagrams showing evolution
6. Provide guidance for future architectural changes

**Prerequisites**: All P4 tasks

**Success Criteria**:
```bash
test -f docs/modernisation/Architecture-Evolution.md
grep -q "JavaScript" docs/modernisation/Architecture-Evolution.md
grep -q "Swift outline" docs/modernisation/Architecture-Evolution.md
grep -q "Combine" docs/modernisation/Architecture-Evolution.md
grep -q "iCloud" docs/modernisation/Architecture-Evolution.md
```

---

## P4-T26: Plan JavaScript Bridge Deprecation Timeline

**Component**: Migration Planning  
**Files**:
- `docs/modernisation/JavaScript-Deprecation-Plan.md` (new)

**Technical Changes**:
1. Create deprecation timeline:
   - **Release N**: Swift outline available as opt-in beta
   - **Release N+1**: Swift outline becomes default, JavaScript available as fallback
   - **Release N+2**: JavaScript bridge deprecated (warnings)
   - **Release N+3**: JavaScript bridge removed entirely
2. Document migration path for users:
   - Automatic migration of documents (already compatible)
   - No user-facing changes required
   - Fallback option if issues arise
3. Plan for JavaScript removal:
   - Remove birch-outline.js dependencies
   - Remove birch-editor.js dependencies
   - Remove Node.js build requirement
   - Remove JavaScriptCore bridge code
   - Update documentation
4. Estimate code reduction: ~5,000-10,000 lines removed
5. Document risks and mitigation strategies
6. Timeline: 12-18 months from Swift outline release

**Prerequisites**: P4-T10 (performance validation showing Swift is better)

**Success Criteria**:
```bash
test -f docs/modernisation/JavaScript-Deprecation-Plan.md
grep -q "Release N" docs/modernisation/JavaScript-Deprecation-Plan.md
grep -q "timeline" docs/modernisation/JavaScript-Deprecation-Plan.md
grep -q "deprecation" docs/modernisation/JavaScript-Deprecation-Plan.md
```

---

## P4-T27: Document Phase 4 Completion and Metrics

**Component**: Documentation  
**Files**:
- `docs/modernisation/Phase-4-Completion-Report.md` (new)
- `docs/modernisation/Modernisation-Complete.md` (new)

**Technical Changes**:
1. Create Phase 4 completion report:
   - All 27 tasks completed
   - Swift outline implementation summary
   - Combine adoption metrics
   - iCloud sync implementation summary
   - SwiftUI editor feasibility findings
   - Code coverage improvement (75% → 80%+)
   - Performance improvements documented
2. Include metrics:
   - Lines of Swift code added
   - Lines of JavaScript code (to be deprecated)
   - Performance improvements (Swift vs JS)
   - Number of Combine publishers/subscribers
   - iCloud sync adoption rate (if telemetry available)
3. Document user-facing changes
4. List remaining technical debt
5. Create overall modernization summary document:
   - All four phases completed
   - Total time invested
   - Major achievements
   - Before/after comparisons
   - Future recommendations
6. Update README.md with completion status

**Prerequisites**: All P4 tasks (P4-T01 through P4-T26)

**Success Criteria**:
```bash
test -f docs/modernisation/Phase-4-Completion-Report.md
test -f docs/modernisation/Modernisation-Complete.md
grep -q "Phase 4 Complete" docs/modernisation/Phase-4-Completion-Report.md
grep -q "All Phases Complete" docs/modernisation/Modernisation-Complete.md
grep -q "Swift outline" docs/modernisation/Phase-4-Completion-Report.md
grep -q "Combine" docs/modernisation/Phase-4-Completion-Report.md
grep -q "iCloud" docs/modernisation/Phase-4-Completion-Report.md
```

---

## Phase 4 Summary

**Total Tasks**: 27  
**Estimated Duration**: 6-12 months  
**Key Deliverables**:
- ✅ Swift outline model implementation (JavaScript bridge replacement)
- ✅ Query language parser and executor in Swift
- ✅ Combine framework adoption for reactive patterns
- ✅ iCloud document sync with conflict resolution
- ✅ Feature flag system for gradual rollout
- ✅ Performance improvements from native Swift
- ✅ Code coverage improved to 80%+
- ✅ Architecture evolution documented
- ✅ JavaScript deprecation plan established

**Phase 4 Success Metrics**:
- All 27 tasks completed and verified
- Swift outline feature parity with JavaScript version achieved
- Performance improvement: 2-5x faster than JavaScript bridge
- Combine successfully integrated in search, sidebar, and model observation
- iCloud sync functional with conflict resolution
- Code coverage ≥ 80%
- All tests passing (unit, integration, performance)
- Documentation complete for architectural changes
- JavaScript deprecation timeline defined

**Major Achievements Across All Phases**:
- **Phase 1**: Modern tooling, Swift 6, comprehensive tests (60% coverage)
- **Phase 2**: Async/await, protocol architecture, concurrency safety (70% coverage)
- **Phase 3**: SwiftUI hybrid, TextKit 2, Touch Bar, accessibility (75% coverage)
- **Phase 4**: Swift outline, Combine, iCloud sync (80% coverage)

**Total Modernization Impact**:
- ~10,000+ lines of legacy code removed or replaced
- 2-5x performance improvement in core operations
- Modern Swift concurrency throughout
- Hybrid SwiftUI/AppKit architecture
- Native Swift implementation replacing JavaScript
- Comprehensive test coverage (60% → 80%)
- Enhanced platform integration (Touch Bar, iCloud, accessibility)
- Simplified architecture and improved maintainability
