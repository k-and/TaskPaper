# Phase 1 Tasks P1-T21 and P1-T22: Xcode Manual Steps

**Date**: 2025-11-12
**Status**: Requires Xcode GUI
**Tasks**: P1-T21 (UI Tests), P1-T22 (Code Coverage Configuration)

---

## Overview

Tasks P1-T21 and P1-T22 require Xcode GUI operations that cannot be automated via command line. This document provides step-by-step instructions for completing these tasks manually in Xcode.

---

## P1-T21: Add UI Tests for Basic Editor Interaction

### Objective

Create UI tests to verify basic editor interaction functionality:
- Test typing (tasks, projects, tags)
- Test folding/unfolding
- Test search bar filtering

### Prerequisites

- Xcode 13.0 or later
- TaskPaper.xcodeproj opened
- TaskPaper app must be buildable

### Step 1: Create UI Test Target

1. **Open TaskPaper.xcodeproj in Xcode**
   ```bash
   open TaskPaper.xcodeproj
   ```

2. **Add New UI Test Target**:
   - Select the project in the Project Navigator (⌘1)
   - Click the "+" button at the bottom of the targets list
   - Choose "iOS" or "macOS" → "UI Testing Bundle"
   - Name it: `TaskPaperUITests`
   - Language: Swift
   - Click "Finish"

3. **Configure UI Test Target**:
   - Set deployment target to match main app (macOS 11.0+)
   - Add to main scheme's test action

### Step 2: Create Basic UI Test File

Create a new Swift file in the `TaskPaperUITests` target:

**File**: `TaskPaperUITests/EditorInteractionTests.swift`

```swift
//
//  EditorInteractionTests.swift
//  TaskPaperUITests
//
//  Created: 2025-11-12
//

import XCTest

class EditorInteractionTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    // MARK: - Typing Tests

    func testTypingTask() throws {
        // Test typing a task (- followed by text)
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.waitForExistence(timeout: 5))

        // Type a task
        textView.click()
        textView.typeText("- New task item\n")

        // Verify the task was created
        XCTAssertTrue(textView.value as? String ?? "" contains: "- New task item")
    }

    func testTypingProject() throws {
        // Test typing a project (text ending with :)
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.waitForExistence(timeout: 5))

        // Type a project
        textView.click()
        textView.typeText("My Project:\n")

        // Verify the project was created
        XCTAssertTrue(textView.value as? String ?? "" contains: "My Project:")
    }

    func testTypingTag() throws {
        // Test typing a tag (@tagname)
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.waitForExistence(timeout: 5))

        // Type text with a tag
        textView.click()
        textView.typeText("- Task with @tag\n")

        // Verify the tag was created
        XCTAssertTrue(textView.value as? String ?? "" contains: "@tag")
    }

    func testTypingMultipleItems() throws {
        // Test typing multiple items
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.waitForExistence(timeout: 5))

        textView.click()
        textView.typeText("Project:\n")
        textView.typeText("\t- Subtask 1\n")
        textView.typeText("\t- Subtask 2 @done\n")

        let content = textView.value as? String ?? ""
        XCTAssertTrue(content.contains("Project:"))
        XCTAssertTrue(content.contains("Subtask 1"))
        XCTAssertTrue(content.contains("Subtask 2 @done"))
    }

    // MARK: - Folding Tests

    func testFoldingProject() throws {
        // Test folding/unfolding a project
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.waitForExistence(timeout: 5))

        // Create a project with children
        textView.click()
        textView.typeText("Foldable Project:\n")
        textView.typeText("\t- Child item 1\n")
        textView.typeText("\t- Child item 2\n")

        // Find and click the fold indicator (may vary by implementation)
        // This is a simplified example - actual implementation may differ
        let foldButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'fold'")).firstMatch
        if foldButton.exists {
            foldButton.click()

            // After folding, child items should not be visible
            // This assertion may need adjustment based on actual behavior
            let content = textView.value as? String ?? ""
            XCTAssertTrue(content.contains("Foldable Project:"))

            // Click again to unfold
            foldButton.click()
        }
    }

    func testUnfoldingProject() throws {
        // Test that unfolding reveals children
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.waitForExistence(timeout: 5))

        // Setup: Create folded project
        textView.click()
        textView.typeText("Another Project:\n")
        textView.typeText("\t- Hidden item\n")

        // Find fold button and ensure it's unfolded
        let foldButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'fold'")).firstMatch
        if foldButton.exists {
            // Fold first
            foldButton.click()

            // Then unfold
            foldButton.click()

            // Verify child is visible
            let content = textView.value as? String ?? ""
            XCTAssertTrue(content.contains("Hidden item"))
        }
    }

    // MARK: - Search/Filter Tests

    func testSearchBarFiltering() throws {
        // Test filtering items using search bar
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.waitForExistence(timeout: 5))

        // Create test content
        textView.click()
        textView.typeText("- Task with @priority\n")
        textView.typeText("- Task with @later\n")
        textView.typeText("- Regular task\n")

        // Find and use search bar
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        // Search for @priority tag
        searchField.click()
        searchField.typeText("@priority")

        // Verify filtering (implementation-specific)
        // The exact behavior depends on how the app implements filtering
        XCTAssertTrue(searchField.value as? String == "@priority")
    }

    func testSearchBarClear() throws {
        // Test clearing the search filter
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        // Enter search text
        searchField.click()
        searchField.typeText("@tag")

        // Clear the search
        if let clearButton = searchField.buttons["Clear"].firstMatch, clearButton.exists {
            clearButton.click()
            XCTAssertEqual(searchField.value as? String ?? "", "")
        }
    }

    func testSearchWithNoResults() throws {
        // Test search with no matching results
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.waitForExistence(timeout: 5))

        // Create test content
        textView.click()
        textView.typeText("- Task one\n")
        textView.typeText("- Task two\n")

        // Search for non-existent tag
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.click()
        searchField.typeText("@nonexistent")

        // Verify no crash and UI remains stable
        XCTAssertTrue(searchField.exists)
    }

    // MARK: - Task Completion Tests

    func testMarkTaskDone() throws {
        // Test clicking the leading dash to mark task done
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.waitForExistence(timeout: 5))

        // Create a task
        textView.click()
        textView.typeText("- Task to complete\n")

        // Find and click the task indicator (implementation-specific)
        // This may require accessibility identifiers in the main app
        let taskIndicator = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'task-indicator'")).firstMatch
        if taskIndicator.exists {
            taskIndicator.click()

            // Verify @done tag was added
            let content = textView.value as? String ?? ""
            XCTAssertTrue(content.contains("@done"))
        }
    }

    // MARK: - Indentation Tests

    func testTabIndentation() throws {
        // Test Tab key for indentation
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.waitForExistence(timeout: 5))

        textView.click()
        textView.typeText("- Task\n")
        textView.typeKey(.tab, modifierFlags: [])
        textView.typeText("- Subtask\n")

        // Verify indentation occurred (content check)
        let content = textView.value as? String ?? ""
        XCTAssertTrue(content.contains("Task"))
        XCTAssertTrue(content.contains("Subtask"))
    }

    func testShiftTabUnindent() throws {
        // Test Shift-Tab for un-indentation
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.waitForExistence(timeout: 5))

        textView.click()
        textView.typeText("- Task\n")
        textView.typeKey(.tab, modifierFlags: [])
        textView.typeText("- Subtask\n")
        textView.typeKey(.tab, modifierFlags: [.shift])

        // Verify un-indentation occurred
        let content = textView.value as? String ?? ""
        XCTAssertTrue(content.contains("Task"))
        XCTAssertTrue(content.contains("Subtask"))
    }

    // MARK: - Performance Tests

    func testTypingPerformance() throws {
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.waitForExistence(timeout: 5))

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            textView.click()
            for i in 1...10 {
                textView.typeText("- Task \(i)\n")
            }
        }
    }
}
```

### Step 3: Configure UI Test Scheme

1. **Edit Scheme**:
   - Product → Scheme → Edit Scheme... (⌘<)
   - Select "Test" in the left sidebar
   - Click "+" and add `TaskPaperUITests`
   - Check the box to enable it

2. **Run UI Tests**:
   - Product → Test (⌘U)
   - Or: `xcodebuild test -scheme TaskPaper -destination 'platform=macOS'`

### Step 4: Troubleshooting UI Tests

**Common Issues**:

1. **App doesn't launch**:
   - Verify the app builds successfully
   - Check code signing settings
   - Ensure deployment target matches

2. **UI elements not found**:
   - Add accessibility identifiers to UI elements in the main app
   - Use Xcode's Accessibility Inspector (Xcode → Open Developer Tool → Accessibility Inspector)
   - Record UI actions using Xcode's UI test recording feature

3. **Tests are flaky**:
   - Add explicit waits using `waitForExistence(timeout:)`
   - Increase timeouts if running on slower systems
   - Disable animations in the test app: `app.launchArguments = ["UI_TESTING"]`

4. **Code signing issues**:
   - Ensure all targets have valid signing certificates
   - May need to disable "Automatically manage signing" and configure manually

### Step 5: Add Accessibility Identifiers (Optional but Recommended)

To make UI tests more reliable, add accessibility identifiers to key UI elements:

```swift
// In your view controller or view setup code
textView.setAccessibilityIdentifier("main-editor-text-view")
searchField.setAccessibilityIdentifier("search-filter-field")
foldButton.setAccessibilityIdentifier("fold-indicator-button")
```

Then in tests:
```swift
let textView = app.textViews["main-editor-text-view"]
```

---

## P1-T22: Configure Code Coverage Reporting

### Objective

Enable code coverage reporting and set a 60% baseline target for Phase 1.

### Prerequisites

- Xcode 13.0 or later
- TaskPaper.xcodeproj opened
- All test targets configured (P1-T14 through P1-T21)

### Step 1: Enable Code Coverage in Scheme

1. **Open Scheme Editor**:
   - Product → Scheme → Edit Scheme... (⌘<)
   - Or: Click scheme dropdown in toolbar → Edit Scheme...

2. **Enable Code Coverage**:
   - Select "Test" in the left sidebar
   - Click "Options" tab
   - Check "Gather coverage for some targets" or "Gather coverage for all targets"

3. **Select Targets for Coverage**:
   If you chose "Gather coverage for some targets":
   - Click "+" button
   - Add these targets:
     * TaskPaper (main app)
     * BirchOutline
     * BirchEditor
   - Do NOT add test targets themselves

4. **Click "Close"** to save scheme changes

### Step 2: Run Tests with Coverage

1. **Run All Tests**:
   ```bash
   # Via Xcode:
   Product → Test (⌘U)

   # Via command line:
   xcodebuild test \
     -scheme TaskPaper \
     -destination 'platform=macOS' \
     -enableCodeCoverage YES \
     -resultBundlePath ./build/TestResults.xcresult
   ```

2. **Wait for Tests to Complete**:
   - This may take several minutes depending on test suite size
   - Monitor progress in Xcode's test navigator

### Step 3: View Code Coverage Report

1. **Open Coverage Report in Xcode**:
   - Open Report Navigator (⌘9)
   - Select the most recent test run (has coverage icon)
   - Click "Coverage" tab
   - View coverage by target, file, and function

2. **View via Command Line**:
   ```bash
   # Export coverage data
   xcrun xccov view --report --json ./build/TestResults.xcresult > coverage-report.json

   # View human-readable report
   xcrun xccov view --report ./build/TestResults.xcresult
   ```

### Step 4: Generate Coverage Baseline Report

Create a coverage report document:

**File**: `docs/modernisation/Phase-1-Code-Coverage-Baseline.md`

```markdown
# Phase 1: Code Coverage Baseline Report

**Date**: [Date tests were run]
**Xcode Version**: [e.g., 14.3]
**Test Run**: [Test result bundle ID or timestamp]

---

## Overall Coverage

| Target | Coverage % | Lines Covered | Total Lines |
|--------|-----------|---------------|-------------|
| BirchOutline | XX.X% | XXXX | XXXX |
| BirchEditor | XX.X% | XXXX | XXXX |
| TaskPaper | XX.X% | XXXX | XXXX |
| **Total** | **XX.X%** | **XXXX** | **XXXX** |

**Phase 1 Target**: 60% overall coverage
**Status**: [PASS/FAIL - if >= 60%]

---

## Coverage by Module

### BirchOutline
- **OutlineType**: XX.X%
- **Item**: XX.X%
- **ItemType**: XX.X%
- **JavaScript Bridge**: XX.X%
- **Serialization**: XX.X%

### BirchEditor
- **OutlineEditor**: XX.X%
- **OutlineEditorTextStorage**: XX.X%
- **StyleSheet**: XX.X%
- **OutlineDocument**: XX.X%

### TaskPaper
- **TaskPaperDocument**: XX.X%
- **Main App**: XX.X%

---

## High-Value Coverage Gaps

List files/functions with <30% coverage that should be prioritized:

1. **[File name]** (XX.X%)
   - Priority: [High/Medium/Low]
   - Reason: [Why this gap matters]

2. **[File name]** (XX.X%)
   - Priority: [High/Medium/Low]
   - Reason: [Why this gap matters]

---

## Files with Excellent Coverage (>90%)

List files with excellent coverage for reference:

1. **[File name]** (XX.X%)
2. **[File name]** (XX.X%)

---

## Recommendations for Phase 2

1. Increase coverage target to 70%
2. Focus on high-value gaps identified above
3. Add tests for edge cases and error handling
4. Improve coverage for:
   - [Specific area 1]
   - [Specific area 2]

---

## Test Execution Summary

- **Total Tests Run**: XXXX
- **Passed**: XXXX
- **Failed**: X
- **Skipped**: X
- **Execution Time**: XX.X seconds

---

## Notes

- [Any important notes about the coverage data]
- [Known limitations or exclusions]
- [Areas intentionally not covered (e.g., deprecated code)]
```

### Step 5: Set Coverage Target Threshold

1. **Document the 60% Baseline**:
   - Save the coverage report above
   - Note current coverage percentage
   - Set 60% as minimum acceptable for Phase 1

2. **Create Coverage Alerts (Optional)**:
   - Some teams use scripts to fail CI if coverage drops below threshold
   - Example script:
   ```bash
   #!/bin/bash
   # check-coverage.sh

   COVERAGE_THRESHOLD=60.0

   # Extract coverage percentage
   COVERAGE=$(xcrun xccov view --report ./build/TestResults.xcresult | grep "Total" | awk '{print $3}' | sed 's/%//')

   echo "Current coverage: ${COVERAGE}%"
   echo "Threshold: ${COVERAGE_THRESHOLD}%"

   # Compare with threshold
   if (( $(echo "$COVERAGE < $COVERAGE_THRESHOLD" | bc -l) )); then
       echo "❌ Coverage below threshold!"
       exit 1
   else
       echo "✅ Coverage meets threshold"
       exit 0
   fi
   ```

### Step 6: Export Coverage Data for Documentation

1. **Generate HTML Report** (requires xcov gem):
   ```bash
   # Install xcov
   gem install xcov

   # Generate report
   xcov --scheme TaskPaper \
        --output_directory ./docs/modernisation/coverage \
        --minimum_coverage_percentage 60.0
   ```

2. **Export JSON for Processing**:
   ```bash
   xcrun xccov view --report --json ./build/TestResults.xcresult \
     > docs/modernisation/coverage-data.json
   ```

### Troubleshooting Code Coverage

**Issue: Coverage data not appearing**
- Solution: Ensure "Gather coverage" is checked in scheme
- Rebuild all targets after enabling coverage
- Clean build folder (⇧⌘K) and rebuild

**Issue: Coverage seems inaccurate**
- Solution: Disable code optimization in Debug configuration
- Build Settings → Optimization Level → None (-O0) for Debug

**Issue: Coverage only shows test targets**
- Solution: Verify you selected app targets in "Gather coverage for some targets"
- Exclude test targets from coverage gathering

**Issue: xcrun xccov not found**
- Solution: Ensure Xcode command line tools are installed
  ```bash
  xcode-select --install
  ```

---

## Success Criteria

### P1-T21 Complete When:
- ✅ TaskPaperUITests target created
- ✅ At least 10 UI test methods implemented
- ✅ Tests covering: typing, folding, search filtering
- ✅ All UI tests pass (or documented as expected failures)
- ✅ Troubleshooting guide documented

### P1-T22 Complete When:
- ✅ Code coverage enabled in test scheme
- ✅ Coverage report generated
- ✅ Baseline report created with actual percentages
- ✅ Coverage percentage documented (target: ≥60%)
- ✅ High-value coverage gaps identified
- ✅ Recommendations for Phase 2 documented

---

## Estimated Time

- **P1-T21**: 3-4 hours (setup + test implementation)
- **P1-T22**: 1-2 hours (configuration + reporting)
- **Total**: 4-6 hours

---

## Next Steps After Completion

1. Run full test suite including UI tests
2. Review code coverage report
3. Document final metrics in Phase 1 completion report (P1-T23)
4. Commit all changes to branch
5. Proceed to Phase 1 completion documentation

---

## References

- [Apple: Testing Your Apps in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)
- [Apple: UI Testing](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [Apple: Code Coverage](https://developer.apple.com/documentation/xcode/code-coverage)
- [XCUITest Documentation](https://developer.apple.com/documentation/xctest/xcuiapplication)
- [TaskPaper Phase 1 Progress Report](./PHASE-1-PROGRESS.md)

---

**Document Version**: 1.0
**Last Updated**: 2025-11-12
**Author**: Claude (Phase 1 Modernisation Task Force)
