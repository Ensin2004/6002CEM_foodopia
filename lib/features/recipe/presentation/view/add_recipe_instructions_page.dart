import 'dart:io';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:foodopia/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/progress_bar/app_step_progress_bar.dart';
import '../../domain/entities/add_recipe_basic_info.dart';
import '../../domain/entities/add_recipe_ingredient.dart';
import '../../domain/entities/add_recipe_instruction.dart';
import '../../../meal_plan/domain/entities/add_meal_ai_plan.dart';
import '../../domain/usecases/get_add_recipe_review_usecase.dart';
import '../../domain/usecases/save_add_recipe_instructions_usecase.dart';
import '../viewmodel/add_recipe_instructions_viewmodel.dart';
import '../viewmodel/add_recipe_visibility_viewmodel.dart';
import '../widgets/discard_recipe_changes_dialog.dart';
import '../widgets/instructions/flat_instruction_list.dart';
import '../widgets/label.dart';
import '../widgets/instructions/instruction_mode_button.dart';
import '../widgets/recipe_visibility_action_button.dart';
import '../widgets/instructions/section_instruction_list.dart';

class AddRecipeInstructionDraft {
  final List<AddRecipeInstruction> instructions;
  final bool useSections;

  const AddRecipeInstructionDraft({
    required this.instructions,
    required this.useSections,
  });
}

class AddRecipeInstructionsPage extends StatelessWidget {
  final String recipeId;
  final String initialVisibility;
  final bool returnToReview;
  final AddMealAiRecipe? initialAiRecipe;
  final AddMealAiGenerationRequest? initialAiRequest;
  final String? userId;
  final AddRecipeBasicInfo? aiDraftBasicInfo;
  final List<AddRecipeIngredient> aiDraftIngredients;
  final List<AddRecipeInstruction> initialGeneratedInstructions;
  final bool hideProgressBar;
  final bool hideAppBar;
  final ValueChanged<AddRecipeInstructionDraft>? onAiDraftNext;

  const AddRecipeInstructionsPage({
    super.key,
    required this.recipeId,
    this.initialVisibility = "private",
    this.returnToReview = false,
    this.initialAiRecipe,
    this.initialAiRequest,
    this.userId,
    this.aiDraftBasicInfo,
    this.aiDraftIngredients = const [],
    this.initialGeneratedInstructions = const [],
    this.hideProgressBar = false,
    this.hideAppBar = false,
    this.onAiDraftNext,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AddRecipeInstructionsViewModel(
            saveInstructionsUseCase: sl<SaveAddRecipeInstructionsUseCase>(),
            getReviewUseCase: sl<GetAddRecipeReviewUseCase>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AddRecipeVisibilityViewModel(
            updateVisibilityUseCase: sl(),
            visibility: initialVisibility,
          ),
        ),
      ],
      child: _AddRecipeInstructionsView(
        recipeId: recipeId,
        returnToReview: returnToReview,
        initialAiRecipe: initialAiRecipe,
        initialAiRequest: initialAiRequest,
        userId: userId,
        aiDraftBasicInfo: aiDraftBasicInfo,
        aiDraftIngredients: aiDraftIngredients,
        initialGeneratedInstructions: initialGeneratedInstructions,
        hideProgressBar: hideProgressBar,
        hideAppBar: hideAppBar,
        onAiDraftNext: onAiDraftNext,
      ),
    );
  }
}

class _AddRecipeInstructionsView extends StatefulWidget {
  final String recipeId;
  final bool returnToReview;
  final AddMealAiRecipe? initialAiRecipe;
  final AddMealAiGenerationRequest? initialAiRequest;
  final String? userId;
  final AddRecipeBasicInfo? aiDraftBasicInfo;
  final List<AddRecipeIngredient> aiDraftIngredients;
  final List<AddRecipeInstruction> initialGeneratedInstructions;
  final bool hideProgressBar;
  final bool hideAppBar;
  final ValueChanged<AddRecipeInstructionDraft>? onAiDraftNext;

  const _AddRecipeInstructionsView({
    required this.recipeId,
    required this.returnToReview,
    this.initialAiRecipe,
    this.initialAiRequest,
    this.userId,
    this.aiDraftBasicInfo,
    this.aiDraftIngredients = const [],
    this.initialGeneratedInstructions = const [],
    this.hideProgressBar = false,
    this.hideAppBar = false,
    this.onAiDraftNext,
  });

  @override
  State<_AddRecipeInstructionsView> createState() =>
      _AddRecipeInstructionsViewState();
}

class _AddRecipeInstructionsViewState
    extends State<_AddRecipeInstructionsView> {
  late final List<InstructionStepState> _steps;
  final List<InstructionSectionState> _sections = [InstructionSectionState()];
  bool _useSections = false;
  String? _seededRecipeId;
  String? _requestedRecipeId;
  String? _initialFormSignature;
  bool _didSaveChanges = false;

  @override
  void initState() {
    super.initState();
    final aiInstructions = widget.initialAiRecipe?.instructions ?? const [];
    final generatedInstructions = widget.initialGeneratedInstructions;
    _steps = aiInstructions.isNotEmpty
        ? aiInstructions.map(InstructionStepState.fromDescription).toList()
        : generatedInstructions.isNotEmpty
        ? generatedInstructions
              .map(
                (instruction) =>
                    InstructionStepState.fromDescription(
                      instruction.description,
                    ),
              )
              .toList()
        : [InstructionStepState()];
    for (final step in _steps) {
      step.addListener(_refreshFormState);
    }
    for (final section in _sections) {
      section.addListener(_refreshFormState);
    }
  }

  @override
  void dispose() {
    for (final step in _steps) {
      step.dispose();
    }
    for (final section in _sections) {
      section.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddRecipeInstructionsViewModel>();
    final horizontalPadding = MediaQuery.sizeOf(context).width >= 600
        ? 48.0
        : AppSpacing.lg;

    if (viewModel.isLoading) {
      return const _AddRecipePageLoading();
    }

    if (widget.initialAiRecipe == null &&
        widget.initialGeneratedInstructions.isEmpty &&
        viewModel.existingReview == null &&
        _requestedRecipeId != widget.recipeId) {
      _requestedRecipeId = widget.recipeId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AddRecipeInstructionsViewModel>().loadExistingRecipe(
          widget.recipeId,
        );
      });
      return const _AddRecipePageLoading();
    }

    final existingReview = viewModel.existingReview;
    if (existingReview != null && _seededRecipeId != existingReview.recipeId) {
      _seedFromReview(viewModel);
    }

    _initialFormSignature ??= _formSignature();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        appBar: widget.hideAppBar
            ? null
            : CustomAppBar(
                title: widget.initialAiRecipe == null
                    ? "New Recipe"
                    : "Customize AI Recipe",
                leading: IconButton(
                  onPressed: () => _handleBack(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                actions: [
                  Consumer<AddRecipeVisibilityViewModel>(
                    builder: (context, visibilityViewModel, _) {
                      return RecipeVisibilityActionButton(
                        visibility: visibilityViewModel.visibility,
                        isSaving: visibilityViewModel.isSaving,
                        onChanged: (value) => confirmRecipeVisibilityChange(
                          context: context,
                          currentVisibility: visibilityViewModel.visibility,
                          nextVisibility: value,
                          onConfirmed: (visibility) =>
                              visibilityViewModel.updateVisibility(
                                recipeId: widget.recipeId,
                                value: visibility,
                              ),
                          errorMessage: () => visibilityViewModel.errorMessage,
                        ),
                      );
                    },
                  ),
                ],
              ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.hideProgressBar)
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.md,
                  ),
                  child: AppStepProgressBar(
                    totalSteps: 4,
                    currentStep: 3,
                    labels: [
                      "Basic Info",
                      "Ingredients",
                      "Instructions",
                      "Review",
                    ],
                  ),
                ),

              // Label, Tips, Button
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.sm,
                  horizontalPadding,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Label(text: "Instructions", isRequired: true),
                    const SizedBox(height: 2),
                    Text(
                      "Add step by step instructions for your recipe",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: InstructionModeButton(
                            title: "No Sections",
                            subtitle: "Simple step by step",
                            icon: Icons.format_align_justify_rounded,
                            selected: !_useSections,
                            onTap: () => setState(() => _useSections = false),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: InstructionModeButton(
                            title: "Use Sections",
                            subtitle: "Group steps by section",
                            icon: Icons.format_align_right_rounded,
                            selected: _useSections,
                            onTap: () => setState(() => _useSections = true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),

              // Input Fields
              Expanded(
                child: _useSections
                    ? SectionInstructionList(
                        sections: _sections,
                        horizontalPadding: horizontalPadding,
                        onPickImage: _pickStepImage,
                        onAddStep: _addSectionStep,
                        onRemoveStep: _removeSectionStep,
                        onAddSection: _addSection,
                        onRemoveSection: _removeSection,
                        onReorderStep: _reorderSectionStep,
                        onReorderSection: _reorderSection,
                      )
                    : FlatInstructionList(
                        steps: _steps,
                        horizontalPadding: horizontalPadding,
                        onPickImage: _pickStepImage,
                        onAddStep: _addFlatStep,
                        onRemoveStep: _removeFlatStep,
                        onReorderStep: _reorderFlatStep,
                      ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.lg,
                  horizontalPadding,
                  AppSpacing.lg,
                ),
                child: PrimaryButton(
                  text: widget.initialAiRecipe != null
                      ? "Next"
                      : widget.returnToReview
                      ? "Save & Review"
                      : "Save & Continue",
                  isLoading: viewModel.isSaving,
                  onPressed: viewModel.isSaving || !_canSave
                      ? null
                      : () => _handleNext(context, viewModel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Handle back action
  Future<void> _handleBack(BuildContext context) async {
    if (!_hasUnsavedChanges()) {
      _leaveEditPage(context);
      return;
    }

    final discard = await confirmDiscardRecipeChanges(context);
    if (!context.mounted || !discard) return;
    _leaveEditPage(context);
  }

  void _leaveEditPage(BuildContext context) {
    if (widget.returnToReview) {
      context.pushReplacement(
        AppRouter.addRecipeReview,
        extra: AddRecipeReviewArgs(recipeId: widget.recipeId),
      );
      return;
    }

    if (context.canPop()) {
      context.pop();
    }
  }

  // Image Picker Helper
  Future<void> _pickStepImage(InstructionStepState step) async {
    final image = await _pickImageFile();
    if (image == null) return;
    setState(() => step.imageFile = image);
  }

  Future<File?> _pickImageFile() async {
    final result = await fp.FilePicker.pickFiles(
      allowMultiple: false,
      type: fp.FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
    );
    final path = result?.files.firstOrNull?.path;
    return path == null ? null : File(path);
  }

  // Add, Remove, Reorder Helper
  void _addFlatStep() {
    final step = InstructionStepState();
    step.addListener(_refreshFormState);
    setState(() => _steps.add(step));
  }

  void _removeFlatStep(int index) {
    setState(() {
      if (_steps.length == 1) {
        _steps[index].clear();
        return;
      }
      final step = _steps.removeAt(index);
      step.dispose();
    });
  }

  void _reorderFlatStep(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final step = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, step);
    });
  }

  void _addSection() {
    final section = InstructionSectionState();
    section.addListener(_refreshFormState);
    setState(() => _sections.add(section));
  }

  void _removeSection(int sectionIndex) {
    setState(() {
      if (_sections.length == 1) {
        _sections[sectionIndex].clear();
        return;
      }
      final section = _sections.removeAt(sectionIndex);
      section.dispose();
    });
  }

  void _reorderSection(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final section = _sections.removeAt(oldIndex);
      _sections.insert(newIndex, section);
    });
  }

  void _addSectionStep(InstructionSectionState section) {
    final step = InstructionStepState();
    step.addListener(_refreshFormState);
    setState(() => section.steps.add(step));
  }

  void _removeSectionStep(InstructionSectionState section, int stepIndex) {
    setState(() {
      if (section.steps.length == 1) {
        section.steps[stepIndex].clear();
        return;
      }
      final step = section.steps.removeAt(stepIndex);
      step.dispose();
    });
  }

  void _reorderSectionStep(
    InstructionSectionState section,
    int oldIndex,
    int newIndex,
  ) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final step = section.steps.removeAt(oldIndex);
      section.steps.insert(newIndex, step);
    });
  }

  // Next Button Helper
  Future<void> _handleNext(
    BuildContext context,
    AddRecipeInstructionsViewModel viewModel,
  ) async {
    if (widget.initialAiRecipe != null) {
      final onAiDraftNext = widget.onAiDraftNext;
      if (onAiDraftNext != null) {
        _didSaveChanges = true;
        onAiDraftNext(
          AddRecipeInstructionDraft(
            instructions: _completedInstructions,
            useSections: _useSections,
          ),
        );
        return;
      }
      context.push(
        AppRouter.addRecipeReview,
        extra: AddRecipeReviewArgs(
          recipeId: widget.recipeId,
          aiRecipe: widget.initialAiRecipe,
          aiRequest: widget.initialAiRequest,
          userId: widget.userId,
          aiDraftBasicInfo: widget.aiDraftBasicInfo,
          aiDraftIngredients: widget.aiDraftIngredients,
          aiDraftInstructions: _completedInstructions,
          aiDraftUseSections: _useSections,
        ),
      );
      return;
    }

    final success = await viewModel.saveInstructions(
      recipeId: widget.recipeId,
      useSections: _useSections,
      instructions: _completedInstructions,
    );

    if (!context.mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.errorMessage ?? "Unable to save instructions.",
          ),
        ),
      );
      return;
    }

    _didSaveChanges = true;

    if (widget.returnToReview) {
      context.pushReplacement(
        AppRouter.addRecipeReview,
        extra: AddRecipeReviewArgs(
          recipeId: widget.recipeId,
          aiRecipe: widget.initialAiRecipe,
          aiRequest: widget.initialAiRequest,
          userId: widget.userId,
        ),
      );
      return;
    }

    context.push(
      AppRouter.addRecipeReview,
      extra: AddRecipeReviewArgs(
        recipeId: widget.recipeId,
        aiRecipe: widget.initialAiRecipe,
        aiRequest: widget.initialAiRequest,
        userId: widget.userId,
      ),
    );
  }

  List<AddRecipeInstruction> get _completedInstructions {
    if (!_useSections) {
      return _steps
          .where((step) => step.isComplete)
          .toList()
          .asMap()
          .entries
          .map(
            (entry) => AddRecipeInstruction(
              sectionIndex: null,
              sectionTitle: null,
              stepIndex: entry.key + 1,
              stepImageFile: entry.value.imageFile,
              existingStepImageUrl: entry.value.existingImageUrl,
              description: entry.value.descriptionController.text.trim(),
            ),
          )
          .toList();
    }

    final instructions = <AddRecipeInstruction>[];
    final completeSections = _sections
        .where((section) => section.isComplete)
        .toList();

    for (
      var sectionIndex = 0;
      sectionIndex < completeSections.length;
      sectionIndex++
    ) {
      final section = completeSections[sectionIndex];
      final completeSteps = section.steps
          .where((step) => step.isComplete)
          .toList();
      for (var stepIndex = 0; stepIndex < completeSteps.length; stepIndex++) {
        final step = completeSteps[stepIndex];
        instructions.add(
          AddRecipeInstruction(
            sectionIndex: sectionIndex + 1,
            sectionTitle: section.titleController.text.trim(),
            stepIndex: stepIndex + 1,
            stepImageFile: step.imageFile,
            existingStepImageUrl: step.existingImageUrl,
            description: step.descriptionController.text.trim(),
          ),
        );
      }
    }

    return instructions;
  }

  bool get _canSave {
    if (!_useSections) {
      final hasCompleteStep = _steps.any((step) => step.isComplete);
      final hasPartialStep = _steps.any((step) => step.isPartial);
      return hasCompleteStep && !hasPartialStep;
    }

    final hasCompleteSection = _sections.any((section) => section.isComplete);
    final hasPartialSection = _sections.any((section) => section.isPartial);
    return hasCompleteSection && !hasPartialSection;
  }

  void _refreshFormState() {
    if (!mounted) return;
    setState(() {});
  }

  bool _hasUnsavedChanges() {
    return !_didSaveChanges && _initialFormSignature != _formSignature();
  }

  String _formSignature() {
    final flatSteps = _steps
        .map(
          (step) => [
            step.descriptionController.text.trim(),
            step.imageFile?.path ?? '',
            step.existingImageUrl ?? '',
          ].join('|'),
        )
        .join('::');
    final sections = _sections
        .map(
          (section) => [
            section.titleController.text.trim(),
            section.steps
                .map(
                  (step) => [
                    step.descriptionController.text.trim(),
                    step.imageFile?.path ?? '',
                    step.existingImageUrl ?? '',
                  ].join('|'),
                )
                .join('::'),
          ].join('||'),
        )
        .join('::::');
    return '$_useSections::$flatSteps::$sections';
  }

  // Review Helper
  void _seedFromReview(AddRecipeInstructionsViewModel viewModel) {
    final review = viewModel.existingReview;
    if (review == null) return;

    for (final step in _steps) {
      step.dispose();
    }
    for (final section in _sections) {
      section.dispose();
    }
    _steps.clear();
    _sections.clear();
    _useSections = review.instructionUseSection;

    if (!_useSections) {
      final sourceSteps = review.instructions.isEmpty
          ? [null]
          : review.instructions;
      for (final item in sourceSteps) {
        final step = InstructionStepState();
        if (item != null) {
          step.descriptionController.text = item.description;
          step.existingImageUrl = item.image.trim().isEmpty ? null : item.image;
        }
        step.addListener(_refreshFormState);
        _steps.add(step);
      }
      _sections.add(InstructionSectionState()..addListener(_refreshFormState));
    } else {
      final grouped = <int, List<dynamic>>{};
      for (final instruction in review.instructions) {
        grouped
            .putIfAbsent(instruction.sectionIndex ?? 0, () => [])
            .add(instruction);
      }
      if (grouped.isEmpty) {
        _sections.add(
          InstructionSectionState()..addListener(_refreshFormState),
        );
      } else {
        for (final entry in grouped.entries) {
          final section = InstructionSectionState();
          for (final step in section.steps) {
            step.dispose();
          }
          section.steps.clear();
          section.titleController.text =
              entry.value.first.sectionTitle?.toString() ?? "";
          for (final item in entry.value) {
            final step = InstructionStepState();
            step.descriptionController.text = item.description.toString();
            final image = item.image.toString();
            step.existingImageUrl = image.trim().isEmpty ? null : image;
            section.steps.add(step);
          }
          section.addListener(_refreshFormState);
          _sections.add(section);
        }
      }
      _steps.add(InstructionStepState()..addListener(_refreshFormState));
    }

    _seededRecipeId = review.recipeId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AddRecipeVisibilityViewModel>().seedVisibility(
        review.visibility,
      );
    });
  }
}

// Instruction Step State Class
class InstructionStepState {
  final String id = UniqueKey().toString();
  final TextEditingController descriptionController = TextEditingController();
  final List<VoidCallback> _listeners = [];
  File? imageFile;
  String? existingImageUrl;

  InstructionStepState();

  factory InstructionStepState.fromDescription(String description) {
    final step = InstructionStepState();
    step.descriptionController.text = description;
    return step;
  }

  bool get isComplete => descriptionController.text.trim().isNotEmpty;

  bool get isPartial =>
      (imageFile != null || existingImageUrl != null) && !isComplete;

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    descriptionController.addListener(listener);
  }

  void clear() {
    descriptionController.clear();
    imageFile = null;
    existingImageUrl = null;
    for (final listener in _listeners) {
      listener();
    }
  }

  void dispose() {
    for (final listener in _listeners) {
      descriptionController.removeListener(listener);
    }
    descriptionController.dispose();
  }
}

// Instruction Section State Class
class InstructionSectionState {
  final String id = UniqueKey().toString();
  final TextEditingController titleController = TextEditingController();
  final List<InstructionStepState> steps = [InstructionStepState()];
  final List<VoidCallback> _listeners = [];

  bool get isComplete {
    return titleController.text.trim().isNotEmpty &&
        steps.any((step) => step.isComplete) &&
        !steps.any((step) => step.isPartial);
  }

  bool get isPartial {
    final hasContent =
        titleController.text.trim().isNotEmpty ||
        steps.any(
          (step) => step.descriptionController.text.trim().isNotEmpty,
        ) ||
        steps.any((step) => step.imageFile != null);
    return hasContent && !isComplete;
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    titleController.addListener(listener);
    for (final step in steps) {
      step.addListener(listener);
    }
  }

  void clear() {
    titleController.clear();
    for (final step in steps) {
      step.dispose();
    }
    steps
      ..clear()
      ..add(InstructionStepState());
    for (final listener in _listeners) {
      steps.first.addListener(listener);
      listener();
    }
  }

  void dispose() {
    for (final listener in _listeners) {
      titleController.removeListener(listener);
    }
    titleController.dispose();
    for (final step in steps) {
      step.dispose();
    }
  }
}

// Loading Page
class _AddRecipePageLoading extends StatelessWidget {
  const _AddRecipePageLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingDialog(message: "Loading...", inline: true),
    );
  }
}
