import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/progress_bar/app_step_progress_bar.dart';
import '../../domain/entities/add_recipe_instruction.dart';
import '../../domain/usecases/save_add_recipe_instructions_usecase.dart';
import '../viewmodel/add_recipe_instructions_viewmodel.dart';
import '../widgets/flat_instruction_list.dart';
import '../widgets/input_label.dart';
import '../widgets/instruction_mode_button.dart';
import '../widgets/section_instruction_list.dart';

class AddRecipeInstructionsPage extends StatelessWidget {
  final String recipeId;

  const AddRecipeInstructionsPage({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddRecipeInstructionsViewModel(
        saveInstructionsUseCase: sl<SaveAddRecipeInstructionsUseCase>(),
      ),
      child: _AddRecipeInstructionsView(recipeId: recipeId),
    );
  }
}

class _AddRecipeInstructionsView extends StatefulWidget {
  final String recipeId;

  const _AddRecipeInstructionsView({required this.recipeId});

  @override
  State<_AddRecipeInstructionsView> createState() =>
      _AddRecipeInstructionsViewState();
}

class _AddRecipeInstructionsViewState extends State<_AddRecipeInstructionsView> {
  final ImagePicker _imagePicker = ImagePicker();
  final List<InstructionStepState> _steps = [InstructionStepState()];
  final List<InstructionSectionState> _sections = [InstructionSectionState()];
  bool _useSections = false;

  @override
  void initState() {
    super.initState();
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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: "New Recipe"),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar
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
                labels: ["Basic Info", "Ingredients", "Instructions", "Review"],
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
                  InputLabel(text: "Instructions", isRequired: true),
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
                text: "Next",
                isLoading: viewModel.isSaving,
                onPressed: viewModel.isSaving || !_canSave
                    ? null
                    : () => _handleNext(context, viewModel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Image Picker Helper
  Future<void> _pickStepImage(InstructionStepState step) async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => step.imageFile = File(image.path));
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
    final success = await viewModel.saveInstructions(
      recipeId: widget.recipeId,
      useSections: _useSections,
      instructions: _completedInstructions,
    );

    if (!context.mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? "Unable to save instructions."),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Recipe instructions saved.")),
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
              description: entry.value.descriptionController.text.trim(),
            ),
          )
          .toList();
    }

    final instructions = <AddRecipeInstruction>[];
    final completeSections = _sections
        .where((section) => section.isComplete)
        .toList();

    for (var sectionIndex = 0; sectionIndex < completeSections.length; sectionIndex++) {
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
}

// Instruction Step State Class
class InstructionStepState {
  final String id = UniqueKey().toString();
  final TextEditingController descriptionController = TextEditingController();
  final List<VoidCallback> _listeners = [];
  File? imageFile;

  bool get isComplete => descriptionController.text.trim().isNotEmpty;

  bool get isPartial => imageFile != null && !isComplete;

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    descriptionController.addListener(listener);
  }

  void clear() {
    descriptionController.clear();
    imageFile = null;
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
        steps.any((step) => step.descriptionController.text.trim().isNotEmpty) ||
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
