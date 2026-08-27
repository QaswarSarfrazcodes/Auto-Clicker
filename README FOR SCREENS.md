# Auto Clicker — First 4 Screens (Splash + Onboarding)

## How to add this to your existing project

1. Copy the `lib/` folder contents into your existing project's `lib/` folder
   (merge — don't overwrite if you already have files there).
2. Copy the `assets/images/` folder in too.
3. In your project's `main.dart`, either replace it with the one here, or
   copy just the `MaterialApp` setup (`initialRoute`, `onGenerateRoute`)
   into your existing `main.dart`.
4. Add this to your `pubspec.yaml` (create the `flutter:` block if you
   don't have one, or add the `assets:` line under your existing one):

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
```

5. Drop your exported Figma images into `assets/images/` using these exact
   filenames (declared in `lib/core/constants/app_assets.dart`):
   - `splash_app_icon.png`
   - `onboarding_automate_illustration.png`
   - `onboarding_no_root_illustration.png`
   - `onboarding_custom_scripts_illustration.png`
   - `overlay_permission_illustration.png`

   And into `assets/icons/` (declared separately, matching the project's
   folder convention):
   - `recent_script_instagram.png`
   - `recent_script_camera.png`
   - `recent_script_gaming.png`

   Until you add them, each screen shows a light placeholder box instead
   of crashing — so the app runs fine right now, and swapping in the real
   PNGs is a drop-in, no-code-change operation.
6. Run `flutter pub get`, then `flutter run`.

## What's here and why it's built this way

| File | Purpose |
|---|---|
| `core/constants/app_colors.dart` | Every color used, as named constants — includes the exact `#0655FF → #043399` splash gradient and `#2380FD` button blue from your Figma export |
| `core/constants/app_dimensions.dart` | Every size/position from the Figma frame (390×844), plus a `DesignScaleContext` extension so those exact numbers scale proportionally on any real device instead of only looking right at 390px wide |
| `core/constants/app_text_styles.dart` / `app_strings.dart` / `app_assets.dart` | Typography, copy, and asset paths centralized — no screen file has a hardcoded string, hex color, or pixel value inside its `build()` |
| `core/routing/spring_curve.dart` + `spring_page_route.dart` | Reproduces the exact Figma "Smart Animate → Spring" interaction (mass 1, stiffness 44.44, damping 10) as the page-transition animation between screens |
| `presentation/widgets/onboarding/onboarding_scaffold.dart` | The one shared layout template behind screens 2–4, composed from small reusable pieces (progress bar, illustration, footer) — this is what keeps the three onboarding screens from drifting apart visually over time |
| `presentation/screens/splash/splash_screen.dart` | Screen 1 |
| `presentation/screens/onboarding/onboarding_automate_screen.dart` | Screen 2 |
| `presentation/screens/onboarding/onboarding_no_root_required_screen.dart` | Screen 3 |
| `presentation/screens/onboarding/onboarding_custom_scripts_screen.dart` | Screen 4 |

## How to customize position/size (the "zoom in/out" ask)

Every number that controls where something sits or how big it is lives in
**one file**: `lib/core/constants/app_dimensions.dart`. To move the splash
icon down, change `splashIconTop`. To make the onboarding illustration
bigger, change `onboardingIllustrationSize`. No screen file needs to be
touched — this is the whole point of pulling these values out of the
widget tree.

## Next screen (not included yet)

Screens 11–13 (Running, Saved Scripts, Settings) are still only specified in the
project skill (`/auto-clicker-project`), not yet coded.

## Screens 5–10 (added in this update)

| Screen | File |
|---|---|
| 5 — Enable Accessibility Services | `presentation/screens/permission/accessibility_permission_screen.dart` |
| 6 — Allow Display Over Other Apps | `presentation/screens/permission/overlay_permission_screen.dart` |
| 7 — Dashboard | `presentation/screens/dashboard/dashboard_screen.dart` |
| 8 — Create Script | `presentation/screens/create_script/create_script_screen.dart` |
| 9 — Place Click Points | `presentation/screens/click_points/place_click_points_screen.dart` |
| 10 — Swipe Parameters | `presentation/screens/swipe_parameters/swipe_parameters_screen.dart` |

Screens 5 and 6 share `presentation/widgets/permission/permission_scaffold.dart`
the same way screens 2–4 share `onboarding_scaffold.dart`. Screens 8 and 10 share
a small library of form widgets under `presentation/widgets/forms/` (labeled text
field, segmented control, toggle row, slider row, section label, outlined button)
so neither screen re-implements input styling. Screen 7's header is built to the
exact Figma "Rectangle 5703" gradient spec (`#13112C → #2380FD`). Screen 9 is a
real interactive overlay — tap anywhere to drop a numbered marker, tap a marker to
edit/delete it — built with local widget state, ready to wire into the real
`ClickPoint` domain entity once the data layer exists.

Full navigation is wired end-to-end: Splash → Onboarding (1–3) → Get Started →
Accessibility permission → Overlay permission → Dashboard → New Script → Add
Click Point (branches to screen 9 for Click scripts, screen 10 for Swipe
scripts). Every `TODO(qaswar)` left in the code marks a spot that needs the real
platform channel, use case, or repository call once those layers are built.
