import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_route_names.dart';
import '../../../data/datasources/preferences_local_datasource.dart';
import '../../../data/datasources/script_local_datasource.dart';
import '../../../domain/entities/script_entity.dart';
import '../../../domain/usecases/import_export_script_usecase.dart';
import '../../../domain/usecases/script_validator.dart';
import '../../widgets/common/app_primary_button.dart';
import '../../widgets/dashboard/app_drawer.dart';
import '../../widgets/dashboard/dashboard_action_card.dart';
import '../../widgets/dashboard/dashboard_header.dart';
import '../../widgets/dashboard/import_validation_dialog.dart';
import '../../widgets/dashboard/recent_script_tile.dart';

/// Screen 7 — Home / Dashboard.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<ScriptEntity> _savedScripts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentScripts();
  }

  Future<void> _loadRecentScripts() async {
    final scripts = await ScriptLocalDataSource.instance.getSavedScripts();
    if (mounted) {
      setState(() {
        _savedScripts = scripts;
        _isLoading = false;
      });
    }
  }

  void _openDrawer(BuildContext context) {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).pushNamed(AppRouteNames.settings);
  }

  Future<void> _openFatigueGuardSheet(BuildContext context) async {
    final prefs = PreferencesLocalDataSource.instance;
    int breakMinutes = await prefs.getFatigueBreakMinutes();
    bool jitterEnabled = await prefs.getAntiDetectionJitter();
    int sleepMinutes = await prefs.getAutoSleepMinutes();
    bool batterySaver = await prefs.getBatterySaverStop();

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle grip
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF10B981)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fatigue Guard & Anti-Ban',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Mimics human behavior & prevents bot detection',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 1. Auto-Breaks
                    const Text(
                      'Session Fatigue Auto-Breaks',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Takes a 45s natural human rest break after continuous running to avoid account flags.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [0, 15, 30, 45, 60].map((mins) {
                        final isSelected = breakMinutes == mins;
                        return ChoiceChip(
                          label: Text(mins == 0 ? 'Disabled' : '$mins min'),
                          selected: isSelected,
                          selectedColor: const Color(0xFF10B981),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => breakMinutes = mins);
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(height: 28),

                    // 2. Anti-Detection Jitter
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Human Micro-Jitter (Anti-Detection)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      subtitle: const Text(
                        'Randomizes click timing (±15%) & adds subtle ±1.5px micro-offset so bots cannot detect the pattern without drifting off target.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                      value: jitterEnabled,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) => setModalState(() => jitterEnabled = val),
                    ),
                    const Divider(height: 24),

                    // 3. Auto-Sleep Timer
                    const Text(
                      'Auto-Sleep Stop Timer',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Stops automation automatically to save battery and prevent screen burn-in.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [0, 30, 60, 120].map((mins) {
                        final isSelected = sleepMinutes == mins;
                        return ChoiceChip(
                          label: Text(mins == 0 ? 'Never' : (mins >= 60 ? '${mins ~/ 60} Hour' : '$mins min')),
                          selected: isSelected,
                          selectedColor: const Color(0xFF10B981),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => sleepMinutes = mins);
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(height: 24),

                    // 4. Battery Saver Stop
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Battery Saver Guard (Auto-Stop at 20%)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      subtitle: const Text(
                        'Safely turns off auto-scrolling when device battery drops below 20%.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                      value: batterySaver,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) => setModalState(() => batterySaver = val),
                    ),
                    const SizedBox(height: 18),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await prefs.setFatigueBreakMinutes(breakMinutes);
                          await prefs.setAntiDetectionJitter(jitterEnabled);
                          await prefs.setAutoSleepMinutes(sleepMinutes);
                          await prefs.setBatterySaverStop(batterySaver);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🛡️ Fatigue Guard settings saved & active!'),
                                backgroundColor: Color(0xFF059669),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Save & Apply Fatigue Guard',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openNewScript(BuildContext context) async {
    await Navigator.of(context).pushNamed(AppRouteNames.createScript);
    _loadRecentScripts();
  }

  Future<void> _openSavedScripts(BuildContext context) async {
    await Navigator.of(context).pushNamed(AppRouteNames.savedScripts);
    _loadRecentScripts();
  }

  /// 1-Tap Quick Launcher for Social Feeds / Reels Auto-Scroll
  void _launchQuickReelScroll(BuildContext context) {
    final script = ScriptEntity(
      id: 'quick_reel_scroll',
      name: 'Quick Social Auto-Scroll',
      actionType: 'swipe',
      intervalValue: 2,
      intervalUnit: 'Sec',
      repeatType: 'infinite',
      repeatCount: 1,
      randomDelayEnabled: true,
      randomDelayMin: 1,
      randomDelayMax: 3,
      holdOnVideoEnabled: true,
      maxVideoWaitSeconds: 180,
      swipeConfig: const SwipeConfigEntity(
        startX: 540,
        startY: 1500,
        endX: 540,
        endY: 500,
        durationMs: 250,
      ),
      createdAt: DateTime.now(),
    );
    Navigator.of(context).pushNamed(
      AppRouteNames.running,
      arguments: script,
    );
  }

  /// 1-Tap Quick Launcher for Instant Auto-Clicker
  void _launchQuickClicker(BuildContext context) {
    final script = ScriptEntity(
      id: 'quick_auto_clicker',
      name: 'Quick Auto-Clicker',
      actionType: 'click',
      intervalValue: 500,
      intervalUnit: 'ms',
      repeatType: 'infinite',
      repeatCount: 1,
      randomDelayEnabled: false,
      randomDelayMin: 1,
      randomDelayMax: 3,
      createdAt: DateTime.now(),
    );
    Navigator.of(context).pushNamed(
      AppRouteNames.running,
      arguments: script,
    );
  }

  Future<void> _importScript(BuildContext context) async {
    final result = await ImportExportScriptUseCase.importScriptFromFile();
    if (!context.mounted) return;

    if (result.isSuccess && result.dataOrNull != null) {
      final json = result.dataOrNull!.toJson();
      final errors = ScriptValidator.validateImportedJson(json);
      if (errors.isNotEmpty) {
        showDialog(
          context: context,
          builder: (_) => ImportValidationDialog(errors: errors),
        );
        return;
      }
      final ds = ScriptLocalDataSource.instance;
      await ds.saveScript(result.dataOrNull!);
      _loadRecentScripts();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported "${result.dataOrNull!.name}"'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } else if (result.isFailure && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: ${result.failureOrNull?.message}'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  void _exportScript(BuildContext context) {
    if (_savedScripts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No saved scripts available to export.'),
          backgroundColor: AppColors.textSecondary,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.selectScriptToExport,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ..._savedScripts.take(5).map((script) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.code, color: AppColors.primaryBlue),
                    title: Text(script.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${script.actionType.toUpperCase()} • ${script.intervalValue} ${script.intervalUnit}'),
                    trailing: const Icon(Icons.copy, size: 20, color: AppColors.textSecondary),
                    onTap: () {
                      final json = ImportExportScriptUseCase.exportScriptToJson(script);
                      Clipboard.setData(ClipboardData(text: json));
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Script JSON for "${script.name}" copied to clipboard!'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _runScript(BuildContext context, ScriptEntity script) {
    Navigator.of(context).pushNamed(
      AppRouteNames.running,
      arguments: script,
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentList = _savedScripts.take(4).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surfaceWhite,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          DashboardHeader(
            onMenuPressed: () => _openDrawer(context),
            onSettingsPressed: () => _openSettings(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.dashboardContentHorizontalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // ── Service Status Pill ─────────────────────────────────
                  _ServiceStatusBanner(),

                  const SizedBox(height: 16),

                  // ── User Intent Hub ("What do you want to automate?") ──
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Automation Modes',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      Text(
                        'Select an intent',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 2x2 Primary Intent Grid
                  Row(
                    children: [
                      // 1. Social Auto-Scroll
                      Expanded(
                        child: _IntentCard(
                          title: 'Social Auto-Scroll',
                          subtitle: 'Facebook, TikTok, Reels',
                          badge: '🎬 Smart Video Hold',
                          icon: Icons.swipe_vertical_rounded,
                          gradientColors: const [Color(0xFF4338CA), Color(0xFF6366F1)],
                          buttonLabel: '1-Tap Start',
                          onTap: () => _launchQuickReelScroll(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 2. Quick Clicker
                      Expanded(
                        child: _IntentCard(
                          title: 'Quick Clicker',
                          subtitle: 'Games, Roblox, Shopping',
                          badge: '🎯 Drops Tap Pin [1]',
                          icon: Icons.touch_app_rounded,
                          gradientColors: const [Color(0xFF0284C7), Color(0xFF06B6D4)],
                          buttonLabel: '1-Tap Start',
                          onTap: () => _launchQuickClicker(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // 3. Unified Script Studio
                      Expanded(
                        child: _IntentCard(
                          title: 'Script Studio',
                          subtitle: 'Multi-Clicks & Swipes',
                          badge: '🛠️ Tab 1 & Tab 2',
                          icon: Icons.auto_fix_high_rounded,
                          gradientColors: const [Color(0xFF7C3AED), Color(0xFF9333EA)],
                          buttonLabel: 'Open Studio',
                          onTap: () => _openNewScript(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 4. Fatigue Guard & Anti-Detection
                      Expanded(
                        child: _IntentCard(
                          title: 'Fatigue Guard',
                          subtitle: '15m/30m Breaks & ±1.5px Jitter',
                          badge: '🛡️ Anti-Ban Active',
                          icon: Icons.shield_outlined,
                          gradientColors: const [Color(0xFF059669), Color(0xFF10B981)],
                          buttonLabel: 'Configure',
                          onTap: () => _openFatigueGuardSheet(context),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.dashboardSectionGap),

                  // ── Recent Scripts / Automation Queue ───────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        AppStrings.recentScripts,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_savedScripts.isNotEmpty)
                        TextButton(
                          onPressed: () => _openSavedScripts(context),
                          child: Text('View All (${_savedScripts.length})'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primaryBlue),
                      ),
                    )
                  else if (_savedScripts.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (int i = 0; i < recentList.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: AppColors.borderGray,
                              ),
                            RecentScriptTile(
                              iconAssetPath: '',
                              iconFallback: recentList[i].actionType == 'swipe'
                                  ? Icons.swipe_rounded
                                  : (i % 2 == 0
                                      ? Icons.touch_app_rounded
                                      : Icons.mouse_rounded),
                              iconColor: recentList[i].actionType == 'swipe'
                                  ? const Color(0xFF6366F1)
                                  : (i % 2 == 0
                                      ? AppColors.accentPink
                                      : AppColors.textPrimary),
                              name: recentList[i].name,
                              lastUsedLabel: recentList[i].lastRunLabel,
                              onPlayPressed: () => _runScript(context, recentList[i]),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    // Quick Start Template Presets when empty
                    _QuickStartPresets(
                      onSelectPreset: (preset) {
                        _runScript(context, preset);
                      },
                    ),

                  const SizedBox(height: AppDimensions.dashboardSectionGap),

                  // ── Management Grid (Bottom Utilities) ──────────────────
                  const Text(
                    'Script Management',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ActionGrid(
                    onNewScript: () => _openNewScript(context),
                    onSavedScript: () => _openSavedScripts(context),
                    onImportScript: () => _importScript(context),
                    onExportScript: () => _exportScript(context),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Service Status Banner showing live readiness
class _ServiceStatusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Automation Service Ready • No Root Required',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF15803D),
              ),
            ),
          ),
          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF15803D)),
        ],
      ),
    );
  }
}

/// Quick Start Presets shown when user has not saved any scripts yet
class _QuickStartPresets extends StatelessWidget {
  const _QuickStartPresets({required this.onSelectPreset});

  final ValueChanged<ScriptEntity> onSelectPreset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, size: 18, color: AppColors.accentOrange),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Quick-Start Automation Presets',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PresetChip(
            title: '15m Reels Scroller',
            desc: 'Auto-swipes every 2.5s with video hold',
            icon: Icons.play_circle_filled_rounded,
            color: const Color(0xFF4F46E5),
            onTap: () {
              onSelectPreset(
                ScriptEntity(
                  id: 'preset_reels',
                  name: '15m Reels Scroller',
                  actionType: 'swipe',
                  intervalValue: 2,
                  intervalUnit: 'Sec',
                  repeatType: 'infinite',
                  repeatCount: 1,
                  randomDelayEnabled: true,
                  randomDelayMin: 1,
                  randomDelayMax: 3,
                  holdOnVideoEnabled: true,
                  maxVideoWaitSeconds: 180,
                  createdAt: DateTime.now(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _PresetChip(
            title: 'Rapid 500ms Clicker',
            desc: 'Fast repetitive click on active point',
            icon: Icons.touch_app_rounded,
            color: const Color(0xFF0284C7),
            onTap: () {
              onSelectPreset(
                ScriptEntity(
                  id: 'preset_clicker',
                  name: 'Rapid 500ms Clicker',
                  actionType: 'click',
                  intervalValue: 500,
                  intervalUnit: 'ms',
                  repeatType: 'infinite',
                  repeatCount: 1,
                  createdAt: DateTime.now(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Compact Intent Card for 2x2 Grid with high visual aesthetics
class _IntentCard extends StatelessWidget {
  const _IntentCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.gradientColors,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final List<Color> gradientColors;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: gradientColors.first,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The 2x2 grid of dashboard action cards.
class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.onNewScript,
    required this.onSavedScript,
    required this.onImportScript,
    required this.onExportScript,
  });

  final VoidCallback onNewScript;
  final VoidCallback onSavedScript;
  final VoidCallback onImportScript;
  final VoidCallback onExportScript;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DashboardActionCard(
                icon: Icons.add_rounded,
                iconColor: AppColors.primaryBlue,
                filledIconBackground: true,
                hasActiveBorder: true,
                title: AppStrings.newScript,
                caption: AppStrings.newScriptCaption,
                onTap: onNewScript,
              ),
            ),
            const SizedBox(width: AppDimensions.dashboardGridGap),
            Expanded(
              child: DashboardActionCard(
                icon: Icons.folder_rounded,
                iconColor: AppColors.accentOrange,
                title: AppStrings.savedScript,
                caption: AppStrings.savedScriptCaption,
                onTap: onSavedScript,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.dashboardGridGap),
        Row(
          children: [
            Expanded(
              child: DashboardActionCard(
                icon: Icons.file_download_rounded,
                iconColor: AppColors.primaryBlue,
                title: AppStrings.importScript,
                caption: AppStrings.importScriptCaption,
                onTap: onImportScript,
              ),
            ),
            const SizedBox(width: AppDimensions.dashboardGridGap),
            Expanded(
              child: DashboardActionCard(
                icon: Icons.file_upload_rounded,
                iconColor: AppColors.accentOrange,
                title: AppStrings.exportScript,
                caption: AppStrings.exportScriptCaption,
                onTap: onExportScript,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
