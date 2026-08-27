# Screens 11–13 Integration Guide — Auto Clicker

Yeh README un 17 files ko **existing codebase (screens 1–10)** mein integrate
karne ka step-by-step tareeqa batati hai.

---

## 1. Files ko copy karo

`lib/` folder ka structure bilkul wahi hai jo pehle se project mein hai —
bas files ko apne project ke `lib/` ke andar same relative paths par copy
kar do (overwrite nahi karna, sab naye paths hain):

```
lib/core/constants/app_colors_screens_11_13.dart
lib/core/constants/app_strings_screens_11_13.dart
lib/core/constants/app_dimensions_screens_11_13.dart
lib/core/routing/app_route_names_screens_11_13.dart

lib/presentation/widgets/common/app_screen_header.dart

lib/presentation/widgets/running/running_status_indicator.dart
lib/presentation/widgets/running/running_stat_card.dart
lib/presentation/screens/running/running_screen.dart

lib/presentation/widgets/saved_scripts/script_filter_tabs.dart
lib/presentation/widgets/saved_scripts/saved_script_tile.dart
lib/presentation/screens/saved_scripts/saved_scripts_screen.dart

lib/presentation/widgets/settings/settings_section_header.dart
lib/presentation/widgets/settings/settings_toggle_row.dart
lib/presentation/widgets/settings/settings_nav_row.dart
lib/presentation/widgets/settings/power_user_card.dart
lib/presentation/widgets/settings/need_help_card.dart
lib/presentation/screens/settings/settings_screen.dart
```

---

## 2. Pehle in 3 cheezon ko verify karo (compile se pehle)

Yeh screens 8–10 ke shared widgets ko reuse karti hain — maine unka exact
signature nahi dekha, sirf skill doc se assume kiya hai. Apne existing
`lib/presentation/widgets/common/` aur `lib/presentation/widgets/forms/`
files khol kar match karo:

| Widget maine use kiya | Jo maine assume kiya |
|---|---|
| `AppPrimaryButton` | params: `label`, `onPressed` (nullable), `icon` (optional), `color` (optional) |
| `AppTextButton` | params: `label`, `onPressed`, `trailingIcon` (optional) |
| `AppLabeledTextField` | params: `label`, `controller`, `readOnly`, `trailing` (optional widget) |

Agar in mein se koi signature match nahi karta, to sirf us widget ke call
site (running_screen.dart mein) ko apne actual param names ke hisaab se
adjust kar dena — logic tabdeel nahi karna padega.

**`AppScreenHeader`** bilkul naya widget hai (maine bana ke diya hai) kyunke
mujhe pata nahi tha ke `AppBackHeader` trailing icons (screen 12 ka search
icon) support karta hai ya nahi. Agar `AppBackHeader` already `actions`
param leta hai, to `AppScreenHeader` delete kar do aur seedha `AppBackHeader`
use kar lo dono screens (12, 13) mein.

---

## 3. Constants ko merge karo

Naye tokens (`AppColorsX`, `AppStringsX`, `AppDimensionsX`) alag files mein
isliye rakhe hain kyunke mujhe aapki asal `app_colors.dart` /
`app_strings.dart` / `app_dimensions.dart` ka content nahi dikh raha tha —
overwrite karne ka risk nahi lena tha.

Jab bhi convenient ho:

1. `AppColorsX` ke saare static consts copy karke `AppColors` class ke
   andar paste kar do.
2. `AppStringsX` ke consts `AppStrings` class mein paste kar do.
3. `AppDimensionsX` ke consts `AppDimensions` class mein paste kar do.
4. Phir teeno naye screens/widgets files mein import + prefix
   (`AppColorsX.` → `AppColors.`, `AppStringsX.` → `AppStrings.`,
   `AppDimensionsX.` → `AppDimensions.`) update kar do — find & replace se
   2 minute ka kaam hai.
5. `app_colors_screens_11_13.dart`, `app_strings_screens_11_13.dart`,
   `app_dimensions_screens_11_13.dart` delete kar do.

Agar abhi merge nahi karna, koi masla nahi — jaisa hain waisa bhi compile
ho jayega, bas 3 extra files codebase mein reh jayengi.

---

## 4. Routing wire karo

`app_route_names_screens_11_13.dart` ke consts apne asal
`app_route_names.dart` mein daal do:

```dart
static const String running = '/running';
static const String savedScripts = '/saved-scripts';
static const String settings = '/settings';
```

Phir `app_router.dart` ke `onGenerateRoute` mein teen naye `case` add karo
(screens 1–10 wale pattern follow karte hue):

```dart
case AppRouteNames.running:
  return SpringPageRoute(builder: (_) => const RunningScreen());
case AppRouteNames.savedScripts:
  return SpringPageRoute(builder: (_) => const SavedScriptsScreen());
case AppRouteNames.settings:
  return SpringPageRoute(builder: (_) => const SettingsScreen());
```

Dashboard (screen 7) ke settings gear icon ko `AppRouteNames.settings` par,
aur "Saved Script" card ko `AppRouteNames.savedScripts` par navigate karwa
do.

---

## 5. Jo abhi tak sirf placeholder hai (TODO markers dekho)

Har file mein `TODO(qaswar)` comments hain jahan real logic connect hogi:

- **Running screen**: `Clicks`/`Runtime` abhi local `Timer` se badh rahe
  hain — real `RunScriptUseCase` stream se replace karna hai.
- **Saved Scripts**: list abhi hardcoded 4 entries hain — real
  `ScriptRepository.watchAll()` se replace karna hai.
- **Settings**: toggles abhi sirf local `setState` hain — real
  `SettingsRepository` se persist karna hai.
- **Global Hotkeys row** (Settings) Android/desktop-only concept hai —
  iOS build mein `Platform.isAndroid` check laga ke hide karna hai (jaisa
  skill doc §2/§13 mein likha hai).

---

## 6. Quick sanity check

```
flutter analyze
```

chala kar dekho — zyada tar warnings (agar aayen) unhi 3 assumed-widget
signatures ki wajah se hongi (Step 2 dekho).
