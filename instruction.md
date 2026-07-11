
agy --conversation=c8daeec0-723b-4276-a5ae-3c800be9439c
Objective

  - Redesign my Flutter launcher to match the target design as closely as possible while preserving existing functionality.

Reference Images

Target Design: ~/programms/flutter/target.jpeg
Current Launcher Screenshot: ~/programms/flutter/current.jpeg

The launcher should visually resemble the target image while remaining lightweight and responsive.

Step 1 — Update Project

Before making any code changes:

 - Update all project dependencies to their latest stable versions.
 - Fix any deprecated APIs.
 - Ensure the project builds successfully with no errors or warnings.
 - Do not remove existing functionality unless explicitly instructed.


Step 2 — Home Screen UI Redesign

Redesign the home screen to closely match the target launcher.

Requirements:

 - Use the same overall layout.
 - Keep the launcher clean and minimal.
 - Match spacing, alignment, padding, icon sizing and typography.
 - Keep animations smooth.
 - Maintain current performance.
 - Home Screen

The home screen should contain:

 - Large empty space on the left.
 - Two-column vertical app layout on the right.
 - Rounded icons.
 - Minimal text.
 - Elegant spacing.

Do NOT copy the image exactly.

Use it only as a design reference.

Step 3 — Remove Unwanted Screen

Currently:

  Home
        ↓
  Click Wink icon
        ↓
  Second screen (shows only time)

  Remove this screen completely.

Expected flow:

  Home
        ↓
  Tap app
        ↓
  Launch app directly

No intermediate screen should exist.

Step 4 — Delete App Feature

Add a Delete / Uninstall App option.

This option must be available from:

Home Screen Apps:

  Long press an app.

  Show menu:

  Remove from Home
  Select Icon
  Delete App



App List:

Long press an app.

Show the same menu:

  Add To Main Grid
  Open App Setting
  Delete App

Use Android's uninstall intent.

If the app is a system app, show App Info instead.

Step 5 — Search Bar Three-Dot Menu

Use the implementation from this project as the reference:

  ~/programms/flutter/nkit-launcher/

  Study how that launcher opens the overflow menu.

  Replicate:

  same animation
  same style
  same UX
  same interaction
  same functionality

  Do not copy unnecessary code.

  Reuse architecture only where appropriate.

Step 6 — Wallpaper Support

Add wallpaper functionality.

Requirements:

Users should be able to:

  Open wallpaper picker
  Select image from Gallery
  Crop if necessary
  Apply wallpaper
  Save wallpaper selection
  Restore after reboot

Wallpaper should update immediately.

Step 7 — Theme Settings

Currently multiple themes exist.

  Remove all extra themes.

  Only keep:

  Dark
  Light
  System Default

Behavior:

  Dark

  Always dark

  Light

  Always light

  System Default

  Follow Android system theme

No other themes should exist anywhere in the launcher.

Step 8 — Code Quality

While implementing:

  Refactor duplicated code.
  Remove dead code.
  Follow Flutter best practices.
  Use clean architecture.
  Keep widgets reusable.
  Keep files organized.
  Avoid unnecessary rebuilds.
  Maintain null safety.


Things That Must NOT Change

 - Bottom search bar behavior (except removing back icon)
 - Existing launcher speed
 - Existing app launching functionality
 - Existing permissions
 - Existing package structure (unless refactoring is necessary)
