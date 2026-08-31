import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_urls.dart';
import '../../widgets/common/app_screen_header.dart';
import '../../widgets/settings/language_picker_dialog.dart';
import '../../widgets/settings/need_help_card.dart';
import '../../widgets/settings/power_user_card.dart';
import '../../widgets/settings/settings_nav_row.dart';
import '../../widgets/settings/settings_section_header.dart';
import '../../widgets/settings/settings_toggle_row.dart';
import '../../../data/datasources/platform/subscription_service.dart';
import '../../../data/datasources/platform/support_service.dart';
import '../../../data/datasources/platform/update_service.dart';
import '../../../data/datasources/preferences_local_datasource.dart';

/// Screen 13 — Settings.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _launchOnStartup = true;
  bool _darkModeOptimization = false;
  bool _collisionDetection = true;
  String _currentLanguageLabel = AppStrings.languageEnglish;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = PreferencesLocalDataSource.instance;
    final launch = await prefs.getLaunchOnStartup();
    final dark = await prefs.getDarkMode();
    final collision = await prefs.getCollisionDetection();
    final lang = await prefs.getAppLanguage();
    if (mounted) {
      setState(() {
        _launchOnStartup = launch;
        _darkModeOptimization = dark;
        _collisionDetection = collision;
        _currentLanguageLabel =
            lang == 'ur' ? AppStrings.languageUrdu : AppStrings.languageEnglish;
        _isLoading = false;
      });
    }
  }

  // Language picker
  Future<void> _openLanguagePicker() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const LanguagePickerDialog(),
    );
    final lang = await PreferencesLocalDataSource.instance.getAppLanguage();
    if (mounted) {
      setState(() {
        _currentLanguageLabel =
            lang == 'ur' ? AppStrings.languageUrdu : AppStrings.languageEnglish;
      });
    }
  }

  // Update check
  Future<void> _checkForUpdates() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.checkingForUpdates)),
    );
    final message = await UpdateService.instance.checkForUpdates();
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Terms of Service
  Future<void> _openTermsOfService() async {
    final uri = Uri.parse(AppUrls.termsOfService);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Manage subscription
  Future<void> _openManageSubscription() async {
    await SubscriptionService.instance.openManageSubscription();
  }

  // Contact support
  Future<void> _contactSupport() async {
    final launched = await SupportService.instance.contactSupport();
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email us at: ${AppUrls.supportEmail}'),
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: AppUrls.supportEmail));
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.scaleW(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppScreenHeader(title: AppStrings.settingsTitle),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.only(bottom: context.scaleH(24)),
                        children: [
                          SizedBox(height: context.scaleH(8)),
                          const SettingsSectionHeader(
                            iconAssetPath: AppIconAssets.generalSettings,
                            icon: Icons.grid_view_rounded,
                            title: AppStrings.generalSectionTitle,
                          ),
                          SettingsToggleRow(
                            title: AppStrings.launchOnStartupTitle,
                            subtitle: AppStrings.launchOnStartupSubtitle,
                            value: _launchOnStartup,
                            onChanged: (v) async {
                              setState(() => _launchOnStartup = v);
                              await PreferencesLocalDataSource.instance
                                  .setLaunchOnStartup(v);
                            },
                          ),
                          SettingsNavRow(
                            title: AppStrings.appLanguageTitle,
                            value: _currentLanguageLabel,
                            onTap: _openLanguagePicker,
                          ),
                          SettingsToggleRow(
                            title: AppStrings.darkModeTitle,
                            subtitle: AppStrings.darkModeSubtitle,
                            value: _darkModeOptimization,
                            onChanged: (v) async {
                              setState(() => _darkModeOptimization = v);
                              await PreferencesLocalDataSource.instance
                                  .setDarkMode(v);
                            },
                          ),
                          SizedBox(height: context.scaleH(20)),
                          const SettingsSectionHeader(
                            iconAssetPath: AppIconAssets.automationSettings,
                            icon: Icons.auto_awesome_motion_outlined,
                            title: AppStrings.automationSectionTitle,
                          ),
                          SettingsToggleRow(
                            title: AppStrings.collisionDetectionTitle,
                            subtitle: AppStrings.collisionDetectionSubtitle,
                            value: _collisionDetection,
                            onChanged: (v) async {
                              setState(() => _collisionDetection = v);
                              await PreferencesLocalDataSource.instance
                                  .setCollisionDetection(v);
                            },
                          ),
                          SizedBox(height: context.scaleH(20)),
                          PowerUserCard(
                            onManageSubscription: _openManageSubscription,
                          ),
                          SizedBox(height: context.scaleH(20)),
                          Text(
                            AppStrings.aboutSectionTitle,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SettingsNavRow(
                            title: AppStrings.versionLabel,
                            value: AppStrings.versionValue,
                          ),
                          const SettingsNavRow(
                            title: AppStrings.releaseDateLabel,
                            value: AppStrings.releaseDateValue,
                          ),
                          SettingsNavRow(
                            title: AppStrings.checkForUpdatesLabel,
                            trailingIcon: Icons.refresh,
                            onTap: _checkForUpdates,
                          ),
                          SettingsNavRow(
                            title: AppStrings.termsOfServiceLabel,
                            trailingIcon: Icons.open_in_new,
                            onTap: _openTermsOfService,
                          ),
                          SizedBox(height: context.scaleH(20)),
                          NeedHelpCard(
                            onContactSupport: _contactSupport,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
