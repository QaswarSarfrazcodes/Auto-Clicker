import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_route_names.dart';
import '../../../core/routing/spring_page_route.dart';
import '../../widgets/common/app_back_header.dart';
import '../../widgets/common/app_primary_button.dart';
import '../../widgets/forms/app_labeled_text_field.dart';
import '../../widgets/forms/app_outlined_button.dart';
import '../../widgets/forms/app_segmented_control.dart';
import '../../widgets/forms/app_toggle_row.dart';
import '../click_points/place_click_points_screen.dart';
import '../swipe_parameters/swipe_parameters_screen.dart';
import '../../../data/datasources/script_local_datasource.dart';
import '../../../domain/entities/script_entity.dart';
import '../../../domain/usecases/script_validator.dart';

/// Screen 8 — Create / Edit Script.
///
/// Pass [editScript] to pre-fill all fields for editing an existing script (§3).
class CreateScriptScreen extends StatefulWidget {
  const CreateScriptScreen({super.key, this.editScript});

  /// When non-null, the screen operates in "Edit" mode.
  final ScriptEntity? editScript;

  @override
  State<CreateScriptScreen> createState() => _CreateScriptScreenState();
}

enum _ActionType { click, swipe }

enum _RepeatMode { infinite, custom }

class _CreateScriptScreenState extends State<CreateScriptScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _intervalController = TextEditingController(
    text: '2',
  );
  final TextEditingController _customCountController = TextEditingController();
  final TextEditingController _minDelayController = TextEditingController(
    text: '1',
  );
  final TextEditingController _maxDelayController = TextEditingController(
    text: '3',
  );

  _ActionType _actionType = _ActionType.click;
  _RepeatMode _repeatMode = _RepeatMode.infinite;
  String _intervalUnit = 'Sec';
  bool _randomDelayEnabled = true;

  // Track the configuration states across screens to prevent dropping parameters
  List<ClickPointEntity> _clickPoints = [];
  SwipeConfigEntity? _swipeConfig;

  bool get _isEditing => widget.editScript != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields when in edit mode (§3).
    final e = widget.editScript;
    if (e != null) {
      _nameController.text = e.name;
      _intervalController.text = e.intervalValue.toString();
      _intervalUnit = e.intervalUnit;
      _actionType = e.actionType == 'swipe'
          ? _ActionType.swipe
          : _ActionType.click;
      _repeatMode = e.repeatType == 'infinite'
          ? _RepeatMode.infinite
          : _RepeatMode.custom;
      _customCountController.text = e.repeatCount.toString();
      _randomDelayEnabled = e.randomDelayEnabled;
      _minDelayController.text = e.randomDelayMin.toString();
      _maxDelayController.text = e.randomDelayMax.toString();
      _clickPoints = List.from(e.clickPoints);
      _swipeConfig = e.swipeConfig;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _intervalController.dispose();
    _customCountController.dispose();
    _minDelayController.dispose();
    _maxDelayController.dispose();
    super.dispose();
  }

  Future<void> _handleAddClickPoint(BuildContext context) async {
    final bool isClick = _actionType == _ActionType.click;
    final result = await Navigator.of(context).push(
      SpringPageRoute(
        settings: RouteSettings(
          name: isClick
              ? AppRouteNames.placeClickPoints
              : AppRouteNames.swipeParameters,
        ),
        builder: (_) => isClick
            ? PlaceClickPointsScreen(initialPoints: _clickPoints)
            : SwipeParametersScreen(initialConfig: _swipeConfig),
      ),
    );

    if (result != null) {
      setState(() {
        if (isClick) {
          _clickPoints = result as List<ClickPointEntity>;
        } else {
          _swipeConfig = result as SwipeConfigEntity;
        }
      });
    }
  }

  Future<void> _handleSaveScript(BuildContext context) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a script name'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    final intervalValue = int.tryParse(_intervalController.text) ?? 2;
    final repeatCount = int.tryParse(_customCountController.text) ?? 10;
    final minDelay = int.tryParse(_minDelayController.text) ?? 1;
    final maxDelay = int.tryParse(_maxDelayController.text) ?? 3;

    // Edit mode: preserve the original ID; create mode: generate a new one.
    final script = ScriptEntity(
      id: _isEditing
          ? widget.editScript!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      actionType: _actionType == _ActionType.click ? 'click' : 'swipe',
      intervalValue: intervalValue,
      intervalUnit: _intervalUnit,
      repeatType: _repeatMode == _RepeatMode.infinite ? 'infinite' : 'custom',
      repeatCount: repeatCount,
      randomDelayEnabled: _randomDelayEnabled,
      randomDelayMin: minDelay,
      randomDelayMax: maxDelay,
      clickPoints: _clickPoints,
      swipeConfig: _swipeConfig,
      createdAt: _isEditing ? widget.editScript!.createdAt : DateTime.now(),
    );

    final validation = ScriptValidator.validateEntity(script);
    if (validation.isFailure) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              validation.failureOrNull?.message ?? 'Invalid script',
            ),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
      return;
    }

    final bool success;
    if (_isEditing) {
      // §3 — update existing script in-place.
      success = await ScriptLocalDataSource.instance.updateScript(script);
    } else {
      success = await ScriptLocalDataSource.instance.saveScript(script);
    }

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Script "$name" updated!'
                  : 'Script "$name" saved successfully!',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Failed to update script.'
                  : 'Failed to save script.',
            ),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.formHorizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.headerTop),
              AppBackHeader(
                title: _isEditing
                    ? AppStrings.editScript
                    : AppStrings.createScript,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      AppLabeledTextField(
                        label: AppStrings.scriptName,
                        controller: _nameController,
                        hintText: AppStrings.scriptNameHint,
                      ),
                      const SizedBox(height: AppDimensions.formFieldGap),
                      const Text(
                        AppStrings.actionType,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppSegmentedControl(
                        leftLabel: AppStrings.click,
                        rightLabel: AppStrings.swipe,
                        isLeftSelected: _actionType == _ActionType.click,
                        onChanged: (isClick) => setState(() {
                          _actionType = isClick
                              ? _ActionType.click
                              : _ActionType.swipe;
                        }),
                      ),
                      const SizedBox(height: AppDimensions.formSectionGap),
                      const Text(
                        AppStrings.timingSettings,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: AppLabeledTextField(
                              label: AppStrings.interval,
                              controller: _intervalController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 130,
                            height: AppDimensions.formFieldHeight,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _intervalUnit == 'ms'
                                  ? 'ms'
                                  : AppStrings.seconds,
                              items: const [AppStrings.seconds, 'ms']
                                  .map(
                                    (unit) => DropdownMenuItem(
                                      value: unit,
                                      child: Text(unit),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (unit) {
                                if (unit != null) {
                                  setState(() {
                                    _intervalUnit = unit == AppStrings.seconds
                                        ? 'Sec'
                                        : 'ms';
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.formFieldRadius,
                                  ),
                                  borderSide: const BorderSide(
                                    color: AppColors.borderGray,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.formFieldRadius,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.formSectionGap),
                      const Text(
                        AppStrings.repeat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppSegmentedControl(
                        leftLabel: AppStrings.infinite,
                        rightLabel: AppStrings.customCount,
                        isLeftSelected: _repeatMode == _RepeatMode.infinite,
                        onChanged: (isInfinite) => setState(() {
                          _repeatMode = isInfinite
                              ? _RepeatMode.infinite
                              : _RepeatMode.custom;
                        }),
                      ),
                      if (_repeatMode == _RepeatMode.custom) ...[
                        const SizedBox(height: 12),
                        AppLabeledTextField(
                          label: AppStrings.customCount,
                          controller: _customCountController,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      const SizedBox(height: AppDimensions.formSectionGap),
                      AppToggleRow(
                        label: AppStrings.randomDelay,
                        value: _randomDelayEnabled,
                        onChanged: (value) =>
                            setState(() => _randomDelayEnabled = value),
                      ),
                      if (_randomDelayEnabled) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AppLabeledTextField(
                                label: '${AppStrings.min} 1s',
                                controller: _minDelayController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppLabeledTextField(
                                label: '${AppStrings.max} 3s',
                                controller: _maxDelayController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppDimensions.formSectionGap),
                      AppOutlinedButton(
                        label: _actionType == _ActionType.click
                            ? AppStrings.addClickPoint
                            : 'Configure Swipe Parameters',
                        onPressed: () => _handleAddClickPoint(context),
                      ),
                      if (_actionType == _ActionType.click &&
                          _clickPoints.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.successGreen.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: AppColors.successGreen,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_clickPoints.length} Click Point(s) Configured',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.successGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_actionType == _ActionType.swipe &&
                          _swipeConfig != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: AppColors.primaryBlue,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Swipe: (${_swipeConfig!.startX.round()}, ${_swipeConfig!.startY.round()}) → (${_swipeConfig!.endX.round()}, ${_swipeConfig!.endY.round()})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      AppPrimaryButton(
                        label: _isEditing
                            ? AppStrings.saveChangesButton
                            : AppStrings.saveScript,
                        onPressed: () => _handleSaveScript(context),
                        expand: true,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
