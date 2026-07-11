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

**Status (2026-07-11): Completed.**
- Upgraded dependencies to latest stable versions.
- Resolved all deprecated APIs and warnings (including replacing `withOpacity` with `withValues`).
- Verified static analysis runs with 0 errors and debug build successfully compiles APK.


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

**Status (2026-07-11): Completed.**
- Home screen redesigned using `Row` containing left-aligned empty flex space (flex: 6) and right-aligned two-column app grid (flex: 5).
- Custom rounded icon layout with padded text labels matching target design.


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

**Status (2026-07-11): Completed.**
- Time-only second screen and its toggle button removed.
- Apps on home grid and list are launched directly on tap.


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

**Status (2026-07-11): Completed.**
- Integrated long press dialogs for both home screen and search results drawer.
- Implemented option mapping:
  - Home: "Remove From Home", "Select Icon", "Delete App" (or "App Info" for system apps).
  - Search: "Add To Main Grid", "Open App Setting", "Delete App" (or "App Info" for system apps).
- Triggers standard Android uninstall channel or system settings info screen.


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

**Status (2026-07-11): Completed.**
- Implemented options menu using `showModalBottomSheet` triggered by three-dot overflow button.
- Replicated bottom sheet sliding transition, background dim, layout style, list tiles, and clean action routing from `nkit-launcher`.


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

**Status (2026-07-11): Completed.**
- Implemented `WallpaperService` and a visual `WallpaperEditor` widget.
- Supports image selection via file picker, manual crop repositioning (drag to reposition, crop zoom slider), frosted glass blur/tint overlay options, and instant background updates.
- Selection and crop attributes persisted in `SharedPreferences` and restored immediately on reboot/app startup.


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

**Status (2026-07-11): Completed.**
- Redundant themes removed from `ThemeService`.
- Strictly limits options to "Light", "Dark", and "System Default".
- Follows system brightness dynamically when "System Default" is active.


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

**Status (2026-07-11): Completed.**
- Unused code, deprecated libraries, and async warnings refactored.
- Removed unused imports, corrected invalid `MainAxisAlignment` reference, and eliminated unsafe context usage across async boundaries.
- Preserved search bar, performance, launches, permissions, and layout configuration.


Things That Must NOT Change

 - Bottom search bar behavior (except removing back icon)
 - Existing launcher speed
 - Existing app launching functionality
 - Existing permissions
 - Existing package structure (unless refactoring is necessary)
