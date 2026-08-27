import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_route_names.dart';
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

  Future<void> _openNewScript(BuildContext context) async {
    await Navigator.of(context).pushNamed(AppRouteNames.createScript);
    _loadRecentScripts();
  }

  Future<void> _openSavedScripts(BuildContext context) async {
    await Navigator.of(context).pushNamed(AppRouteNames.savedScripts);
    _loadRecentScripts();
  }

  Future<void> _importScript(BuildContext context) async {
    final result = await ImportExportScriptUseCase.importScriptFromFile();
    if (!context.mounted) return;

    if (result.isSuccess && result.dataOrNull != null) {
      // §12 — Run field-level validation before persisting
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
    final recentList = _savedScripts.take(3).toList();

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
                  const SizedBox(height: AppDimensions.dashboardSectionGap),
                  _ActionGrid(
                    onNewScript: () => _openNewScript(context),
                    onSavedScript: () => _openSavedScripts(context),
                    onImportScript: () => _importScript(context),
                    onExportScript: () => _exportScript(context),
                  ),
                  const SizedBox(height: AppDimensions.dashboardSectionGap),
                  const Text(
                    AppStrings.recentScripts,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primaryBlue),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          if (recentList.isNotEmpty)
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
                                // Use real last-run timestamp instead of hardcoded "Just now"
                                lastUsedLabel: recentList[i].lastRunLabel,
                                onPlayPressed: () => _runScript(context, recentList[i]),
                              ),
                            ]
                          else
                            // Clean empty state — no fake placeholder scripts
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.auto_fix_high_rounded,
                                    size: 48,
                                    color: AppColors.borderGray,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No scripts yet',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => _openNewScript(context),
                                    child: const Text('Create your first script →'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppDimensions.dashboardSectionGap),
                  AppPrimaryButton(
                    label: AppStrings.createNewScript,
                    onPressed: () => _openNewScript(context),
                    trailingIcon: null,
                    expand: true,
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

