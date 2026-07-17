target: file path: ~/programms/flutter/main.jpeg

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
- Styled app icons as circular (`BoxShape.circle`) with a slightly light/white-tinted translucent background (`0.15` alpha in dark theme, `0.65` in light theme) to exactly match the target `main.jpeg` design specifications.
- Aligned the app grid to the bottom right of the screen layout (`Align(alignment: Alignment.bottomCenter)` with `shrinkWrap: true` on the `GridView`) so that pinned apps start filling from the bottom side first.
- Replaced the large card/box panel background around the home app grid with a clean, fully transparent background to match the minimal look of the target design.
- Fixed notification bar wallpaper cropping: configured the Scaffold to extend body elements behind the status and navigation bars (`extendBodyBehindAppBar: true`, `extendBody: true`, `appBar: null`), letting the wallpaper fill the entire screen and eliminating the white header bar.


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
  - Search: "Open App Setting", "Delete App" (or "App Info" for system apps). "Add To Main Grid" was removed based on final requirements.
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
- Added a glassmorphic frosted filter with dynamic contrast to the search bar and search results overlay to render the wallpaper in a smooth, blurry style instead of a solid theme background.


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


Step 9 — Fix Home Screen Grid Overflow

Fix bottom overflow in the home screen grid.

Requirements:

  - Resolve the "BOTTOM OVERFLOWED" layout render error inside each home screen grid cell (as seen in `home-screen3.jpeg`).
  - Maintain correct typography, spacing, and icon sizes.

**Status (2026-07-12): Completed.**
- Cleaned up home screen app layout to completely remove the app name text and its leftover commented code blocks inside the `buildTile` widget.
- Switched the grid cells to a square layout by changing `childAspectRatio` of the home screen `GridView` to `1.0`.
- Reduced `mainAxisSpacing` from `15` to `12` to bring the icon rows closer together vertically, optimizing spacing in accordance with the target design `main.jpeg`.
- Verified that static analysis compiles and passes successfully.


Step 10 — Time and Date Display

Add the current time, date, and day layout on the home screen to match the target design.

Requirements:

  - Show time in a stacked layout on the left side of the home screen (hours on top, minutes on bottom) using a large font size.
  - Below the time, display a pill-shaped container showing the current date formatted as `DaySuffix. Month, Year` (e.g., `4th. Jun, 2023`).
  - Below the date, display `"Today's"` and the current weekday name in large bold text (e.g., `"Today's\nSunday."`).
  - Color scheme should match the target design (soft pastel green accents for the clock digits).
  - The display must update in real-time.

**Status (2026-07-12): Completed.**
- Integrated a stateful `Timer` that ticks every second to maintain a reactive clock state in `_HomeScreenState`.
- Implemented a custom `_formatDate` helper that formats the date suffix (`st`/`nd`/`rd`/`th`) dynamically without external dependencies.
- Replaced the left empty space `SizedBox` with a vertically centered (`Alignment.centerLeft`), left-padded column displaying the formatted hour, minutes, date pill, and weekday string to match `target.jpeg`.
- Styled clock digits as hollow green outlines (pastel green `0xFF8CD8A2` in dark theme, deep green `0xFF2E7D32` in light theme) using a Stroke Paint object with `strokeWidth: 1.8` to match the exact aesthetic of `target.jpeg`.
- Verified that static analysis compiles and passes successfully.

Step 11 — Home Setup, Arrange System, and Grid Settings

Implement the "Set up home" option in the global actions menu with the same functionality as the nkit-launcher project, and add grid configuration under Launcher settings.

Requirements:
  - Add the "Set up home" option (grid icon) and group other custom options under a clean sub-menu called "Launcher settings" (settings icon) in the overflow menu matching `update.jpeg`.
  - Implement a modal bottom sheet displaying two tabs: "Add" and "Arrange".
  - The "Add" tab must list all installed apps with a search filter, showing checkboxes indicating whether they are pinned to the home screen. Checking/unchecking adds/removes the apps from the home screen in real-time.
  - The "Arrange" tab must show the current layout of home grid apps, supporting interactive drag-and-drop reordering (repositioning elements via LongPressDraggable and DragTarget) and allowing custom icon selection or removal directly from the arrange tiles.
  - Save the updated grid positions to SharedPreferences in real-time so that the custom positions persist immediately.
  - Add options under Launcher settings to dynamically change the number of Home grid columns (max 3) and rows (max 9) using the style of `new.jpeg`. Load and persist these configurations in SharedPreferences, dynamically adjusting the screen layouts and flex sizes.

**Status (2026-07-13): Completed.**
- Added the "Set up home" option to the global actions popup menu, and consolidated "Change Theme" and "Choose Wallpaper" settings into a clean "Launcher settings" bottom sheet.
- Created `HomeSetupSheet` with two tabs: "Add" for searching and toggling home apps, and "Arrange" for organizing the apps in the home grid.
- Implemented drag-and-drop reordering in the "Arrange" grid using `LongPressDraggable` and `DragTarget`, which updates the layout in real-time.
- Implemented `updatePinnedAppsOrder` inside `InstalledAppsService` to persist the new order of pinned apps to SharedPreferences immediately.
- Added dropdown selector options for Home grid columns (1 to 3) and rows (1 to 9) in the Launcher Settings modal sheet.
- Integrated dynamic layout flex scaling and grid bounds capping (to columns * rows) based on the settings, saved to SharedPreferences.
- Checked compiling and static analysis (0 errors/warnings).


Things That Must NOT Change

 - Bottom search bar behavior (except removing back icon)
 - Existing launcher speed
 - Existing app launching functionality
 - Existing permissions
 - Existing package structure (unless refactoring is necessary)




----  Bugs and Features ----

- Bugs:
  1. The wallpaper option in launcher setting not work. i select wallpaper but not apply on screen.
  2. when i search an app the list shown here do 2 things --
      - one is give some border or style just shown in image ( ~/programms/flutter/search-design.jpeg)
      - second is , currently i search an app it shows the match result top of the screen like normal launcher shows but i want that the search top result will shown just above the keyboard screen means the end to the search results.
      
  3. in the 3 dots of search bar, the first option is set up home in this option we have a Add apk to screen functionality that work good but only one issue that is it not shown the app icons , so add app icons the actual app icons.

- Features: 

  1. give dark and lite wallpaper option just like the nkit-launcher have(~/programms/flutter/nkit-launcher)
  2. if wallpaper is dark then the clock / time/ day will shown in lite text. and if wallpaper is lite then they shown in dark so easily visible.
