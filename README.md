# TaskPaper

This project is "shared source" for TaskPaper license owners:

1. Do modify as you see fit for your own use.
2. Do not change or disable any of the licensing code.
3. Do not redistribute binaries without permission from jesse@hogbayoftware.com
4. Do submit pull requests if you would like your changes potentially included in the official TaskPaper release.

I want TaskPaper to continue on. Contact me if you want to do something with the code that does not fit under the above conditions and we can probably work something out.

## Background

I worked adding features to TaskPaper from around 2007-2018.

Around 2018 I decided that I wanted a [new foundation](https://support.hogbaysoftware.com/t/how-does-bike-relate-to-taskpaper/4689) for outlining that wasn't compatible with TaskPaper's approach. Since then most of my time has been spent developing [Bike Outliner](https://www.hogbaysoftware.com/bike/). I fix TaskPaper bugs and update for macOS releases, but other then that I have not actively worked on TaskPaper.

This has been a bit sad for me as TaskPaper is a nice well polished app. But I only have so much work time, and I'm dedicating that time to Bike Outliner's development. 

I hope by making TaskPaper's source available to license holders TaskPaper can continue to grow for those who enjoy it.

## Design

TaskPaper's code is spread across a few different projects:

- `birch-outline.js` The model layer consisting of outline, attributed string, serialization, query language, and undo.
- `BirchOutline.swift` Swift wrapper around model layer.
- `birch-editor.js` The view model layer consisting of editor state, selection, visible lines, and style calculations.
- `BirchEditor.swift` Swift wrapper around birch editor view model layer + most of Swift application code. NSTextView based editor, document, window, picker views, etc.
- `TaskPaper` TaskPaper specific customization to `BirchEditor.swift`. The intention was that there might be other apps that build off `BirchEditor.swift`.

## Building

These instructions work for me, but there could very well be system dependencies that I've not accounting for. Let me know if they don't work for you and I'll add extra notes.

### Update Dependencies

carthage update

### Javascript

This is a bit of a mess. Goal was to make `birch-outline.js` and `BirchOutline.swift` reusable so that other apps could read TaskPaper's file format. Would simplify things to just have a single JavaScript layer and single Swift layer... but getting code to that point would take some time, so that's why it's the way that it is.

**Node.js Requirement: v20.x LTS**

Both `birch-outline.js` and `birch-editor.js` require Node.js v20 or higher. The easiest way to manage Node.js versions is with [nvm (Node Version Manager)](https://github.com/nvm-sh/nvm).

**Building JavaScript Layers:**

1. Install Node.js v20:
   ```bash
   nvm install 20
   nvm use 20  # Or just run: nvm use (reads from .nvmrc files)
   ```

2. Build birch-outline.js:
   ```bash
   cd BirchOutline/birch-outline.js
   npm install
   npm run start
   ```

3. Build birch-editor.js:
   ```bash
   cd BirchEditor/birch-editor.js
   npm install
   npm run start
   ```

4. Now this Xcode project should pickup any changes

**Development Workflow:**

- **npm link**: Use from within `birch-outline.js` so that `birch-editor.js` can reference the local version
- **npm start**: Run in both packages to watch for changes and rebuild automatically
- **Webpack output**: Goes to each package's "min" folder
- **Xcode integration**: BirchOutline and BirchEditor Swift projects automatically copy updated JavaScript bundles during build

**.nvmrc files**: Both JavaScript packages now include `.nvmrc` files specifying Node.js 20, so you can simply run `nvm use` in each directory.

## Releasing

Update TaskPaper-Direct-Notes.md
./build.sh # update build number in script, because me dumb!

That should build all versions, direct, direct preview, setapp, and app store

- Direct and setapp version are bundled into a new folder in TaskPaper/build and can be copied from there.
- App store version is found in Xcode organizer and can be submitted from there.
