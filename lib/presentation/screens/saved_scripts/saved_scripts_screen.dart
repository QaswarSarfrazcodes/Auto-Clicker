import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_route_names.dart';
import '../../widgets/common/app_screen_header.dart';
import '../../widgets/common/confirm_delete_dialog.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/saved_scripts/saved_script_tile.dart';
import '../../widgets/saved_scripts/script_filter_tabs.dart';
import '../../../data/datasources/script_local_datasource.dart';
import '../../../domain/entities/script_entity.dart';
import '../../../domain/usecases/import_export_script_usecase.dart';
import '../create_script/create_script_screen.dart';
import '../../../core/routing/spring_page_route.dart';

/// Screen 12 — Saved Scripts.
class SavedScriptsScreen extends StatefulWidget {
  const SavedScriptsScreen({super.key});

  @override
  State<SavedScriptsScreen> createState() => _SavedScriptsScreenState();
}

class _SavedScriptsScreenState extends State<SavedScriptsScreen> {
  ScriptFilter _filter = ScriptFilter.all;
  List<ScriptEntity> _savedScripts = [];
  bool _isLoading = true;
  String? _loadError; // §21 — error state
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadScripts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadScripts() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final scripts = await ScriptLocalDataSource.instance.getSavedScripts();
      if (mounted) {
        setState(() {
          _savedScripts = scripts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = AppStrings.somethingWentWrong;
          _isLoading = false;
        });
      }
    }
  }

  List<ScriptEntity> get _visibleScripts {
    List<ScriptEntity> list = _savedScripts;
    if (_filter != ScriptFilter.all) {
      final String typeStr = _filter == ScriptFilter.click ? 'click' : 'swipe';
      list = list.where((s) => s.actionType == typeStr).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((s) => s.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showScriptOptions(BuildContext context, ScriptEntity script) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              // §3 — Edit option
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue),
                title: const Text(
                  AppStrings.editScript,
                  style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await Navigator.of(context).push(
                    SpringPageRoute(
                      settings: const RouteSettings(name: AppRouteNames.createScript),
                      builder: (_) => CreateScriptScreen(editScript: script),
                    ),
                  );
                  _loadScripts(); // Refresh after edit
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: AppColors.primaryBlue),
                title: const Text(
                  AppStrings.selectScriptToExport,
                  style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  final json = ImportExportScriptUseCase.exportScriptToJson(script);
                  Clipboard.setData(ClipboardData(text: json));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.scriptJsonCopied),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                },
              ),
              // §15 — Delete with confirmation
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.dangerRed),
                title: const Text(
                  AppStrings.deleteScriptTitle,
                  style: TextStyle(color: AppColors.dangerRed, fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final confirmed = await showConfirmDeleteDialog(context, script.name);
                  if (!confirmed) return;
                  final success = await ScriptLocalDataSource.instance.deleteScript(script.id);
                  if (success) {
                    _loadScripts();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Deleted "${script.name}"'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleList = _visibleScripts;

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.scaleW(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppScreenHeader(
                    title: AppStrings.savedScriptsTitle,
                    actions: [
                      IconButton(
                        splashRadius: 20,
                        icon: Icon(_isSearching ? Icons.close : Icons.search, size: 22),
                        color: AppColors.textPrimary,
                        onPressed: () {
                          setState(() {
                            _isSearching = !_isSearching;
                            if (!_isSearching) {
                              _searchQuery = '';
                              _searchController.clear();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (_isSearching) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search script by name...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          filled: true,
                          fillColor: AppColors.surfaceMuted,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                  ],
                  SizedBox(height: context.scaleH(12)),
                  ScriptFilterTabs(
                    selected: _filter,
                    onChanged: (f) => setState(() => _filter = f),
                  ),
                  SizedBox(height: context.scaleH(16)),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryBlue,
                            ),
                          )
                        : _loadError != null
                            // §21 — Error state with retry button
                            ? ErrorStateWidget(
                                message: _loadError!,
                                onRetry: _loadScripts,
                              )
                        : visibleList.isEmpty
                            ? Center(
                                child: Text(
                                  _searchQuery.isNotEmpty
                                      ? AppStrings.noMatchingScripts
                                      : AppStrings.noSavedScripts,
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.only(
                                  bottom: context.scaleH(AppDimensions.fabSize + 24),
                                ),
                                itemCount: visibleList.length,
                                separatorBuilder: (context, index) => SizedBox(
                                  height: context.scaleH(AppDimensions.scriptTileGap),
                                ),
                                itemBuilder: (context, index) {
                                  final script = visibleList[index];
                                  return SavedScriptTile(
                                    name: script.name,
                                    createdDate: _formatDate(script.createdAt),
                                    onPlay: () {
                                      Navigator.of(context).pushNamed(
                                        AppRouteNames.running,
                                        arguments: script,
                                      );
                                    },
                                    onMenu: () => _showScriptOptions(context, script),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: context.scaleW(20),
              bottom: context.scaleH(24),
              child: FloatingActionButton(
                backgroundColor: AppColors.primaryBlue,
                onPressed: () async {
                  await Navigator.of(context).pushNamed(AppRouteNames.createScript);
                  _loadScripts(); // Refresh list on return
                },
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
