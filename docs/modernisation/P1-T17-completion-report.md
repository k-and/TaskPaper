# P1-T17 Completion Report: BirchEditor Test Plan

## Task Objective
Create an Xcode test plan for the BirchEditor module with Thread Sanitizer enabled for Debug configuration and code coverage support.

## What Was Accomplished

### 1. Test Plan File Created ✅
**File**: `BirchEditor/BirchEditor.swift/BirchEditorTests/BirchEditorTestPlan.xctestplan`

**Status**: Successfully created

**Configuration**:
- Version: 1
- Configurations: Debug (with Thread Sanitizer) and Release
- Code coverage: Enabled for TaskPaperTests target
- Target identifier: `43402AB31D69F841001F6A2B` (TaskPaperTests)

**Verification**:
```bash
$ test -f BirchEditor/BirchEditor.swift/BirchEditorTests/BirchEditorTestPlan.xctestplan && echo "File exists" || echo "File missing"
File exists
```

### 2. Project Structure Discovery

**Key Finding**: BirchEditor tests are NOT structured like BirchOutline tests.

**BirchOutline Structure** (for comparison):
- Separate Xcode project: `BirchOutline/BirchOutline.swift/BirchOutline.xcodeproj`
- Own scheme: `BirchOutline`
- Own test target: `BirchOutlineTests` (ID: `436C0D791D1D56D50089FA7A`)
- Standalone test plan works directly

**BirchEditor Structure** (actual):
- NO separate Xcode project
- NO BirchEditor scheme in TaskPaper.xcodeproj
- Tests are part of `TaskPaperTests` target (ID: `43402AB31D69F841001F6A2B`)
- Tests import `@testable import TaskPaper` (not a separate BirchEditor module)
- Test files:
  - `OutlineEditorTests.swift`
  - `OutlineEditorStorageTests.swift`
  - `OutlineDocumentTests.swift`
  - `StyleSheetTests.swift`

## Issues Encountered

### Issue 1: Non-Existent BirchEditor Scheme
**Expected** (per task description): Use `-scheme BirchEditor`

**Actual**: No BirchEditor scheme exists in TaskPaper.xcodeproj

**Available schemes**:
- TaskPaper
- TaskPaper Direct  
- TaskPaper Setapp
- BirchOutline (in separate project)
- BirchOutlineiOS (in separate project)

**Impact**: Cannot execute the success criteria command as specified:
```bash
xcodebuild test -project TaskPaper.xcodeproj -scheme BirchEditor -testPlan BirchEditorTestPlan
# Error: The project named "TaskPaper" does not contain a scheme named "BirchEditor"
```

### Issue 2: Test Plan Not Associated with Existing Schemes
**Problem**: The created test plan references TaskPaperTests target, but it's not associated with any scheme.

**Attempted Solution**: Use `-testPlan BirchEditorTestPlan` with TaskPaper scheme
**Result**: 
```
xcodebuild: error: Scheme "TaskPaper" does not have an associated test plan named "BirchEditorTestPlan"
```

**Root Cause**: Test plans must be explicitly associated with schemes in Xcode. The test plan file exists but isn't registered in any scheme's configuration.

### Issue 3: TaskPaper Direct Scheme Not Configured for Testing
**Attempted**: Use TaskPaper Direct scheme
**Result**:
```
xcodebuild: error: Scheme TaskPaper Direct is not currently configured for the test action
```

### Issue 4: Build Conflicts When Using TaskPaper Scheme
**Problem**: Multiple targets (TaskPaper and TaskPaper Direct) try to produce the same output
**Error**: `Multiple commands produce '/Users/ka/Downloads/2025-11-07 TaskPaper Repo/TaskPaper/DerivedData/Build/Products/Debug/TaskPaper.app'`

## Test Plan File Contents

The test plan was created with the following structure:

```json
{
  "configurations" : [
    {
      "id" : "6F7E8D9C-3A4B-5C6D-7E8F-9A0B1C2D3E4F",
      "name" : "Debug",
      "options" : {
        "threadSanitizer" : {
          "enabled" : true
        }
      }
    },
    {
      "id" : "7F8E9D0C-4A5B-6C7D-8E9F-0A1B2C3D4E5F",
      "name" : "Release",
      "options" : {
      }
    }
  ],
  "defaultOptions" : {
    "codeCoverage" : {
      "targets" : [
        {
          "target" : {
            "containerPath" : "container:../../TaskPaper.xcodeproj",
            "identifier" : "43402AB31D69F841001F6A2B",
            "name" : "TaskPaperTests"
          }
        }
      ]
    },
    "targetForVariableExpansion" : {
      "containerPath" : "container:../../TaskPaper.xcodeproj",
      "identifier" : "43402AB31D69F841001F6A2B",
      "name" : "TaskPaperTests"
    }
  },
  "testTargets" : [
    {
      "target" : {
        "containerPath" : "container:../../TaskPaper.xcodeproj",
        "identifier" : "43402AB31D69F841001F6A2B",
        "name" : "TaskPaperTests"
      }
    }
  ],
  "version" : 1
}
```

## Recommendations

### Option 1: Update Task Documentation
**Action**: Revise P1-T17 to reflect actual project structure
- Change success criteria to use existing TaskPaper or TaskPaperTests scheme
- Document that BirchEditor tests are part of TaskPaperTests target
- Note that test plan needs manual association in Xcode scheme editor

### Option 2: Create BirchEditor Scheme
**Action**: Create a new shared scheme for BirchEditor tests
- Scheme would build necessary targets and run only BirchEditor-related tests
- Associate the BirchEditorTestPlan.xctestplan with this scheme
- Use `-only-testing` filters for BirchEditor test classes

### Option 3: Run Tests via Xcode GUI
**Action**: Open Xcode and:
1. Select TaskPaper or TaskPaper Direct scheme
2. Edit scheme → Test action
3. Add BirchEditorTestPlan to the scheme
4. Run tests with Thread Sanitizer enabled

### Option 4: Use Existing Scheme with Test Filters
**Action**: Run BirchEditor tests using TaskPaperTests with filters:
```bash
xcodebuild test -project TaskPaper.xcodeproj -scheme TaskPaper \
  -only-testing:TaskPaperTests/OutlineEditorTests \
  -only-testing:TaskPaperTests/OutlineEditorStorageTests \
  -only-testing:TaskPaperTests/StyleSheetTests \
  -only-testing:TaskPaperTests/OutlineDocumentTests \
  -enableThreadSanitizer YES \
  -enableCodeCoverage YES
```

## Summary

**Completed**:
- ✅ Test plan file created with correct structure
- ✅ Thread Sanitizer enabled in Debug configuration
- ✅ Code coverage configured
- ✅ File placed in correct location

**Not Completed (Due to Project Structure)**:
- ❌ Cannot run tests with `-scheme BirchEditor` (scheme doesn't exist)
- ❌ Cannot verify Thread Sanitizer activation (tests won't run)
- ❌ Cannot verify code coverage generation (tests won't run)
- ❌ Cannot extract test results (tests won't run)

**Root Cause**: Task description assumes BirchEditor has the same independent project structure as BirchOutline, but BirchEditor is actually integrated into the main TaskPaper project without its own scheme.

**File Created**: `BirchEditor/BirchEditor.swift/BirchEditorTests/BirchEditorTestPlan.xctestplan` ✅

**Next Steps Required**: Manual intervention to either:
1. Associate test plan with existing scheme in Xcode, OR
2. Create new BirchEditor scheme, OR  
3. Revise task expectations to match actual project structure
