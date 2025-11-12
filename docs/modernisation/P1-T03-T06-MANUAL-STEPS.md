# P1-T03 through P1-T06: Manual Xcode Steps Required

**Date**: 2025-11-12
**Status**: Requires Xcode GUI
**Automated**: ❌ No - Must be performed manually

---

## Overview

Tasks P1-T03 through P1-T06 require Xcode GUI operations that cannot be automated via command-line tools. These tasks update the Xcode project configuration to use Swift Package Manager instead of Carthage.

---

## P1-T03: Update Xcode Project for SPM Integration

### Prerequisites
- ✅ P1-T01 Complete (Carthage audit)
- ✅ P1-T02 Complete (Package.swift created)

### Manual Steps

#### 1. Open Project in Xcode
```bash
open TaskPaper.xcodeproj
```

#### 2. Remove Carthage Framework Search Paths
1. Select the TaskPaper project in Project Navigator
2. For each target (TaskPaper-Direct, TaskPaper-AppStore, TaskPaper-Setapp):
   - Select the target
   - Go to Build Settings tab
   - Search for "Framework Search Paths"
   - Remove `$(PROJECT_DIR)/Carthage/Build/Mac` entry
   - Save

#### 3. Remove Carthage Copy-Frameworks Build Phase
1. Select each target (TaskPaper-Direct, TaskPaper-AppStore, TaskPaper-Setapp)
2. Go to Build Phases tab
3. Look for "Run Script" phase with Carthage copy-frameworks command:
   ```bash
   /usr/local/bin/carthage copy-frameworks
   ```
4. Delete this build phase
5. Save

#### 4. Add Swift Package Dependency
1. In Xcode, select File → Add Packages...
2. Enter repository URL: `https://github.com/sparkle-project/Sparkle`
3. Select "Up to Next Major Version" with 2.6.0
4. Click "Add Package"
5. When prompted, select all targets that need Sparkle:
   - TaskPaper-Direct
   - TaskPaper-AppStore
   - (Sparkle may not be needed for Setapp - verify)
6. Click "Add Package"

#### 5. Link Sparkle Framework to Targets
1. For each target, verify Sparkle is linked:
   - Select target
   - Go to "General" tab
   - Under "Frameworks, Libraries, and Embedded Content"
   - Verify "Sparkle" appears with "Do Not Embed" option
2. If missing, click + and add Sparkle

#### 6. Update Build Schemes
1. Product → Scheme → Edit Scheme...
2. For each scheme, remove any Carthage-specific pre/post actions
3. Save

#### 7. Configure SPM Package Resolution
1. File → Project Settings (or Xcode → Settings → Accounts)
2. Under "Derived Data", note location
3. SPM packages will be downloaded automatically on first build

### Success Criteria

```bash
# Verify project builds successfully with SPM
xcodebuild -project TaskPaper.xcodeproj -scheme "TaskPaper Direct" -configuration Debug clean build | grep -q "BUILD SUCCEEDED"

# Verify Carthage references removed from project file
! grep -q "Carthage" TaskPaper.xcodeproj/project.pbxproj
```

### Expected Outcome
- ✅ Project builds successfully with SPM
- ✅ No Carthage references in project.pbxproj
- ✅ Sparkle framework linked via SPM
- ✅ All three targets compile (Direct, AppStore, Setapp)

---

## P1-T04: Handle Paddle Framework Integration

### Prerequisites
- ✅ P1-T02 Complete (Package.swift created)
- ✅ P1-T03 Complete (SPM integration)

### Background
PaddleHQ Mac-Framework-V4 v4.4.3 does NOT support Swift Package Manager. Manual integration is required.

### Option 1: Keep Carthage-Built Paddle Framework (Recommended)

#### Steps:
1. Copy Paddle framework to project:
   ```bash
   mkdir -p Frameworks
   cp -R Carthage/Build/Mac/Paddle.framework Frameworks/
   ```

2. Add framework to Xcode project:
   - Right-click project in Project Navigator
   - Add Files to "TaskPaper"...
   - Select `Frameworks/Paddle.framework`
   - Ensure "Copy items if needed" is UNCHECKED (already copied)
   - Add to targets: TaskPaper-Direct, TaskPaper-AppStore
   - Click "Add"

3. Verify framework linking:
   - Select each target
   - Go to "General" tab
   - Under "Frameworks, Libraries, and Embedded Content"
   - Verify Paddle.framework appears with "Embed & Sign" option

4. Update .gitignore:
   ```bash
   # Add to .gitignore (don't ignore manually managed frameworks)
   echo "# Manually managed frameworks (keep in version control)" >> .gitignore
   echo "# Frameworks/" >> .gitignore
   ```

### Option 2: Download Latest Paddle Framework

#### Steps:
1. Download latest Paddle v4 from GitHub:
   ```bash
   curl -L https://github.com/PaddleHQ/Mac-Framework-V4/releases/download/v4.4.3/Paddle.framework.zip -o /tmp/Paddle.framework.zip
   unzip /tmp/Paddle.framework.zip -d Frameworks/
   ```

2. Follow steps 2-4 from Option 1 above

### Verify Licensing Code

⚠️ **CRITICAL**: Per repository guidelines, do NOT modify licensing code.

#### Test Steps:
1. Build and run TaskPaper-Direct
2. Verify license validation dialog appears (or valid license recognized)
3. Test license activation flow (if applicable)
4. Verify no crashes related to Paddle framework

### Create Documentation

Create `docs/modernisation/paddle-integration.md` documenting:
- Why manual integration is required
- Steps taken for integration
- Paddle framework version used
- How to update Paddle framework in future
- Testing procedure for license validation

### Success Criteria

```bash
# Verify Paddle framework is accessible in build settings
xcodebuild -project TaskPaper.xcodeproj -scheme "TaskPaper Direct" -configuration Debug -showBuildSettings | grep -q "Paddle"

# Verify licensing code still functions (manual testing required)
echo "Manual verification: Launch app and verify license validation works"
```

### Expected Outcome
- ✅ Paddle.framework integrated manually
- ✅ Framework copied to Frameworks/ directory
- ✅ All targets link Paddle correctly
- ✅ License validation works (manual test)
- ✅ Documentation created

---

## P1-T05: Remove Carthage Files and Configuration

### Prerequisites
- ✅ P1-T03 Complete (SPM integration working)
- ✅ P1-T04 Complete (Paddle integrated manually)

### Steps

#### 1. Verify All Dependencies Working
Before removing Carthage, ensure:
- Project builds successfully
- Sparkle framework linked via SPM
- Paddle framework integrated manually
- All tests pass

#### 2. Delete Carthage Files
```bash
cd /path/to/TaskPaper

# Delete Cartfile and Cartfile.resolved
rm Cartfile Cartfile.resolved

# Delete entire Carthage directory
rm -rf Carthage/

# Verify deletion
! test -f Cartfile
! test -f Cartfile.resolved
! test -d Carthage
```

#### 3. Update .gitignore

Remove Carthage-specific entries and add SPM entries:

```bash
# Open .gitignore in editor
# Remove these lines:
#   Carthage/Build/iOS
#   Carthage/Build/tvOS
#   Carthage/Build/watchOS
#   Carthage/Checkouts
#
# Add these lines:
#   # Swift Package Manager
#   .swiftpm/
#   .build/

# Automated approach:
sed -i.bak '/Carthage/d' .gitignore
echo "" >> .gitignore
echo "# Swift Package Manager" >> .gitignore
echo ".swiftpm/" >> .gitignore
echo ".build/" >> .gitignore
```

#### 4. Final Build Verification

```bash
# Clean build to ensure no Carthage artifacts remain
xcodebuild -project TaskPaper.xcodeproj -scheme "TaskPaper Direct" -configuration Debug clean build
```

### Success Criteria

```bash
# Verify Carthage files removed
! test -f Cartfile
! test -f Cartfile.resolved
! test -d Carthage

# Verify gitignore updated
grep -q ".swiftpm" .gitignore

# Verify project still builds
xcodebuild -project TaskPaper.xcodeproj -scheme "TaskPaper Direct" -configuration Debug build | grep -q "BUILD SUCCEEDED"
```

### Expected Outcome
- ✅ All Carthage files deleted
- ✅ .gitignore updated for SPM
- ✅ Project builds successfully
- ✅ No Carthage references remain

---

## P1-T06: Update README.md for SPM Instructions

### Prerequisites
- ✅ P1-T05 Complete (Carthage removed)

### Steps

#### 1. Locate Carthage Instructions in README.md

Find section about dependencies and building:
```bash
grep -n "carthage" README.md
```

Current instructions (around line 38):
```markdown
### Update Dependencies

carthage update
```

#### 2. Replace with SPM Instructions

Update the dependencies section to:

```markdown
## Dependencies

TaskPaper uses Swift Package Manager for dependency management.
Dependencies are automatically resolved when opening the Xcode project.

### Main Dependencies

- **Sparkle** (automatic updates) - Managed via Swift Package Manager
- **Paddle** (licensing framework) - Manual integration (see docs/modernisation/paddle-integration.md)

### Building from Source

1. Open `TaskPaper.xcodeproj` in Xcode 15+
2. Select your desired scheme:
   - TaskPaper Direct (for direct distribution)
   - TaskPaper (for App Store)
   - TaskPaper Setapp (for Setapp distribution)
3. Build (⌘B)

Dependencies will be automatically resolved by Swift Package Manager on first build.
```

#### 3. Update Contribution Guidelines (if needed)

If README mentions Carthage in contribution guidelines, update to mention SPM instead.

#### 4. Remove Carthage Update Command

Delete or comment out the `carthage update` command from build instructions.

### Success Criteria

```bash
# Verify README updated
! grep -q "carthage update" README.md
grep -q "Swift Package Manager" README.md
```

### Expected Outcome
- ✅ README.md updated with SPM instructions
- ✅ Carthage references removed
- ✅ Clear build instructions for contributors
- ✅ Paddle manual integration documented

---

## Summary Checklist

After completing P1-T03 through P1-T06 manually in Xcode:

- [ ] P1-T03: Xcode project updated for SPM
  - [ ] Framework search paths removed
  - [ ] Copy-frameworks build phase removed
  - [ ] Sparkle added via SPM
  - [ ] All targets link Sparkle
  - [ ] Project builds successfully

- [ ] P1-T04: Paddle framework handled
  - [ ] Paddle.framework copied to Frameworks/
  - [ ] Framework added to Xcode project
  - [ ] All targets link Paddle
  - [ ] License validation tested
  - [ ] Documentation created

- [ ] P1-T05: Carthage removed
  - [ ] Cartfile deleted
  - [ ] Cartfile.resolved deleted
  - [ ] Carthage/ directory deleted
  - [ ] .gitignore updated
  - [ ] Project still builds

- [ ] P1-T06: README.md updated
  - [ ] SPM instructions added
  - [ ] Carthage references removed
  - [ ] Build instructions clarified
  - [ ] Paddle integration documented

---

## Next Steps

After completing these manual Xcode steps:

1. Commit changes:
   ```bash
   git add -A
   git commit -m "Phase 1: Complete P1-T03 through P1-T06 (SPM migration)"
   ```

2. Verify with success criteria scripts provided above

3. Continue to P1-T07: Audit Node.js Dependencies (automated)

---

## Troubleshooting

### Issue: Sparkle 2.x API Changes

If you encounter errors after upgrading Sparkle 1.x → 2.x:

1. Review Sparkle 2.x migration guide: https://sparkle-project.org/documentation/api-reference/
2. Update initialization code in AppDelegate
3. Update update check method calls

Common changes:
```swift
// Sparkle 1.x
SUUpdater.shared().checkForUpdatesInBackground()

// Sparkle 2.x
SPUStandardUpdaterController.shared().checkForUpdates()
```

### Issue: Paddle Framework Not Found

If Paddle.framework is not found during build:

1. Verify framework is in Frameworks/ directory
2. Check framework is added to target's "Frameworks, Libraries, and Embedded Content"
3. Verify "Embed & Sign" is selected
4. Clean build folder (⇧⌘K) and rebuild

### Issue: Project Won't Build After Carthage Removal

If build fails after removing Carthage:

1. Clean derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
2. Clean build folder in Xcode (⇧⌘K)
3. Verify SPM packages resolved: File → Packages → Resolve Package Versions
4. Check for any remaining Carthage references: `grep -r "Carthage" TaskPaper.xcodeproj/`

---

## Notes for Future Phases

- **Phase 2**: Swift 6 migration will require Xcode 15+
- **Phase 3**: SwiftUI work will benefit from Xcode 15+
- **Phase 4**: No additional Xcode-specific requirements beyond standard development

Keep Xcode updated to latest stable version for best compatibility with modern Swift features.
