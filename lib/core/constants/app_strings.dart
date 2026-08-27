/// Centralized user-facing copy for the first four screens.
library;

abstract final class AppStrings {
  // Splash
  static const String splashWordmarkRegular = 'Auto';
  static const String splashWordmarkBold = 'Clicker';
  static const String splashTagline = 'Automates Taps & Swipes';

  // Onboarding — screen 2
  static const String onboardingAutomateHeadline = 'Automate\nRepetitive Tasks';
  static const String onboardingAutomateSubtext =
      'Create automatic taps and swipes anywhere on your screen.';

  // Onboarding — screen 3
  static const String onboardingNoRootHeadline = 'No Root Required';
  static const String onboardingNoRootSubtext =
      'Work safely using Android Accessibility Services.';

  // Onboarding — screen 4
  static const String onboardingCustomScriptsHeadline = 'Create Custom\nScripts';
  static const String onboardingCustomScriptsSubtext =
      'Save, edit and reuse automation scripts anytime';

  // Shared actions
  static const String skip = 'Skip';
  static const String next = 'Next';
  static const String getStarted = 'Get Started';

  // Screen 5 — Enable Accessibility Services
  static const String accessibilityHeadline = 'Enable Accessibility\nServices';
  static const String accessibilitySubtext =
      'This permission allows Auto Clicker to simulate taps and swipes';
  static const String enable = 'Enable';
  static const String howItWorks = 'How it works?';

  // Screen 6 — Allow Display Over Other Apps
  static const String overlayHeadline = 'Allow Display all Over\nOther Apps';
  static const String overlaySubtext =
      'Required to show the floating control panel.';
  static const String grantPermission = 'GRANT PERMISSION';
  static const String whyIsThisNeeded = 'Why is this needed?';

  // Screen 7 — Dashboard
  static const String appTitle = 'Auto Clicker';
  static const String newScript = 'New Script';
  static const String newScriptCaption = 'Create Automation';
  static const String savedScript = 'Saved Script';
  static const String savedScriptCaption = 'View Scripts';
  static const String importScript = 'Import Script';
  static const String importScriptCaption = 'Import it';
  static const String exportScript = 'Export Script';
  static const String exportScriptCaption = 'Export it';
  static const String recentScripts = 'Recent Scripts';
  static const String createNewScript = 'Create New Script';
  static const String instagramAutoScroll = 'Auto Scroll (Generic)';
  static const String lastUsedJustNow = 'Last used: Just now';
  static const String cameraIntervalTap = 'Interval Tap (Generic)';
  static const String lastUsed2hAgo = 'Last used: 2h ago';
  static const String gamingFarming = 'Auto Farm (Generic)';

  // Screen 8 — Create Script
  static const String createScript = 'Create Script';
  static const String scriptName = 'Script name';
  static const String scriptNameHint = 'Auto Scroll';
  static const String actionType = 'Action Type';
  static const String click = 'Click';
  static const String swipe = 'Swipe';
  static const String timingSettings = 'Timing Settings';
  static const String interval = 'Interval';
  static const String seconds = 'Seconds';
  static const String repeat = 'Repeat';
  static const String infinite = 'Infinite';
  static const String customCount = 'Custom Count';
  static const String randomDelay = 'Random Delay';
  static const String min = 'Min';
  static const String max = 'Max';
  static const String addClickPoint = 'Add Click Point';
  static const String saveScript = 'Save Script';

  // Screen 9 — Place Click Points
  static const String tapAnywhereToPlaceClickPoints =
      'Tap Anywhere to place\nClick Points';
  static const String pointLabel = 'Point';
  static const String xCoordinate = 'X-Cordinate';
  static const String yCoordinate = 'Y-Cordinate';
  static const String delayMs = 'Delay (ms)';
  static const String delete = 'Delete';
  static const String save = 'Save';

  // Screen 10 — Swipe Parameters
  static const String swipeParameters = 'Swipe Parameters';
  static const String startingPosition = 'STARTING POSITION';
  static const String endPosition = 'END POSITION';
  static const String xPx = 'X (px)';
  static const String yPx = 'Y (px)';
  static const String timingAndBehavior = 'TIMING & BEHAVIOR';
  static const String durationMs = 'Duration (ms)';
  static const String loopSequence = 'Loop Sequence';
  static const String saveChanges = 'Save Changes';
  static const String resetToDefault = 'Reset to Default';

  // Screen 11 — Running
  static const String runningStatus = 'Running';
  static const String scriptNameLabel = 'Script Name';
  static const String clicksLabel = 'Clicks';
  static const String runtimeLabel = 'Runtime';
  static const String speedLabel = 'Speed';
  static const String pauseButton = 'Pause';
  static const String stopButton = 'Stop';
  static const String resumeButton = 'RESUME';
  static const String minimizeLabel = 'Minimize';

  // Screen 12 — Saved Scripts
  static const String savedScriptsTitle = 'Saved Scripts';
  static const String filterAll = 'All';
  static const String filterClick = 'Click';
  static const String filterSwipe = 'Swipe';
  static const String createdPrefix = 'Created: ';

  // Screen 13 — Settings
  static const String settingsTitle = 'Settings';
  static const String generalSectionTitle = 'General';
  static const String launchOnStartupTitle = 'Launch on System Startup';
  static const String launchOnStartupSubtitle =
      'Start Auto Clicker automatically when\nyou log in.';
  static const String appLanguageTitle = 'Application Language';
  static const String appLanguageValue = 'English (United States)';
  static const String darkModeTitle = 'Dark Mode Optimization';
  static const String darkModeSubtitle =
      'Adapt interface for high-performance\ndisplays.';

  static const String automationSectionTitle = 'Automation';
  static const String globalHotkeysTitle = 'Global Hotkeys';
  static const String globalHotkeysSubtitle =
      'Default: Ctrl + Alt + S to\nstart/stop.';
  static const String globalHotkeysValue = 'CTRL +\nALT + S';
  static const String collisionDetectionTitle = 'Collision Detection';
  static const String collisionDetectionSubtitle =
      'Pause if unexpected windows appear.';

  static const String powerUserTitle = 'Power User';
  static const String powerUserStatus = 'Pro Version Active';
  static const String powerUserDescription =
      'Access all premium automation scripts and\npriority cloud synchronization.';
  static const String manageSubscriptionButton = 'Manage Subscription';

  static const String aboutSectionTitle = 'About';
  static const String versionLabel = 'Version';
  static const String versionValue = 'v2.4.0';
  static const String releaseDateLabel = 'Release Date';
  static const String releaseDateValue = 'Oct 24, 2023';
  static const String checkForUpdatesLabel = 'Check for Updates';
  static const String termsOfServiceLabel = 'Terms of Service';

  static const String needHelpTitle = 'Need Help?';
  static const String needHelpDescription =
      'Our technical team is available 24/7 for\npremium users.';
  static const String contactSupportButton = 'Contact Support';

  // §3 — Edit Script
  static const String editScript = 'Edit Script';
  static const String saveChangesButton = 'Save Changes';

  // §4 — Language Picker
  static const String appLanguage = 'Application Language';
  static const String languageEnglish = 'English';
  static const String languageUrdu = 'اردو (Urdu)';
  static const String cancel = 'Cancel';

  // §5 — Hotkeys
  static const String globalHotkeysDialog = 'Set Global Hotkey';
  static const String pressAnyKey = 'Press any key…';
  static const String notSet = 'Not Set';

  // §6 — Update Check
  static const String updateDownloading = 'Update downloading…';
  static const String alreadyUpToDate = "You're on the latest version.";
  static const String openedAppStore = 'Opened App Store for updates.';
  static const String checkingForUpdates = 'Checking for updates…';

  // §9 — Support
  static const String supportSubject = 'Auto Clicker Support';

  // §12 — Import validation
  static const String importFailed = 'Import Failed';
  static const String ok = 'OK';

  // §13 — Drawer
  static const String rateApp = 'Rate the App';
  static const String contactSupport = 'Contact Support';

  // §15 — Delete confirmation
  static const String deleteScriptTitle = 'Delete Script';
  static const String deleteScriptConfirm =
      'This cannot be undone. Are you sure?';
  static const String deleteConfirm = 'Delete';

  // §20 — Previously hardcoded strings
  static const String noScriptsCreatedYet = 'No scripts created yet';
  static const String noMatchingScripts = 'No matching scripts found';
  static const String noSavedScripts = 'No saved scripts found';
  static const String selectScriptToExport = 'Select Script to Export';
  static const String scriptJsonCopied = 'Script JSON copied to clipboard!';
  static const String tapToGetStarted =
      'Tap "New Script" or "Create New Script" below to get started.';

  // §21 — Error state
  static const String somethingWentWrong = 'Something went wrong';
  static const String retry = 'Retry';

  // §2 — iOS
  static const String iosSwitchControlExplainer =
      'iOS runs automation through Apple\'s own Switch Control. '
      'We\'ll help you configure a custom gesture — this app cannot '
      'tap other apps directly (Apple platform restriction).';
  static const String openSwitchControl = 'Open Switch Control Settings';

  // §16 — Notifications
  static const String notificationPermissionRequired =
      'Notification permission is required to keep the script running in the background. '
      'Please allow it and try again.';

  // §11 — Foreground service notification
  static const String scriptRunningNotifTitle = 'Auto Clicker is running';
  static const String scriptRunningNotifBody =
      'Use the floating bar to pause or stop.';
  static const String scriptStopAction = 'Stop';

  const AppStrings._();
}
