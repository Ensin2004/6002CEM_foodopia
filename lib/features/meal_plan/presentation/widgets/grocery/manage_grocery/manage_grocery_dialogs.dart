part of '../../../view/manage_grocery_list_page.dart';

/// Dialog widgets for editing lists and adding grocery items.
///
/// Dialog state remains local to preserve form controller lifecycles.
/// Shows the edit grocery list dialog.
Future<void> _showEditListDialog(
  BuildContext context,
  ManageGroceryListDetail detail,
) async {
  await showDialog<void>(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<ManageGroceryListViewModel>(),
      child: _EditGroceryListDialog(detail: detail),
    ),
  );
}

/// Edit grocery list dialog.
class _EditGroceryListDialog extends StatefulWidget {
  /// The grocery list detail.
  final ManageGroceryListDetail detail;

  /// Creates a new edit grocery list dialog instance.
  const _EditGroceryListDialog({required this.detail});

  @override
  State<_EditGroceryListDialog> createState() => _EditGroceryListDialogState();
}

/// State for the edit grocery list dialog.
class _EditGroceryListDialogState extends State<_EditGroceryListDialog> {
  /// Controller for the list name input.
  late final TextEditingController _nameController;

  /// Start date.
  late DateTime _startDate;

  /// End date.
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.detail.title);
    _startDate = widget.detail.startDate;
    _endDate = widget.detail.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    return AlertDialog(
      title: Text('Edit Grocery List', style: context.text.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List name input.
            Text('List Name', style: context.text.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _nameController,
              maxLength: 50,
              decoration: const InputDecoration(
                hintText: 'e.g. Weekly Groceries',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Date range picker.
            Text('Date Range', style: context.text.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _shortDateRange(_startDate, _endDate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ),
            ),

            // Error message if any.
            if (viewModel.actionErrorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                viewModel.actionErrorMessage!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: viewModel.isSaving
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: viewModel.isSaving ? null : _saveChanges,
          child: Text(viewModel.isSaving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  /// Opens the date range picker.
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    // Update state if picked.
    if (picked == null || !mounted) return;
    setState(() {
      _startDate = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );
      _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
    });
  }

  /// Saves the changes.
  Future<void> _saveChanges() async {
    final saved = await context.read<ManageGroceryListViewModel>().updateList(
      name: _nameController.text,
      startDate: _startDate,
      endDate: _endDate,
    );
    if (saved && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

/// Add grocery item dialog.
class _AddGroceryItemDialog extends StatefulWidget {
  /// Related meal plan IDs.
  final List<String> relatedMealPlanIds;

  /// Creates a new add grocery item dialog instance.
  const _AddGroceryItemDialog({this.relatedMealPlanIds = const []});

  @override
  State<_AddGroceryItemDialog> createState() => _AddGroceryItemDialogState();
}

/// State for the add grocery item dialog.
class _AddGroceryItemDialogState extends State<_AddGroceryItemDialog> {
  /// Controller for ingredient name.
  late final TextEditingController _nameController;

  /// Controller for quantity.
  late final TextEditingController _amountController;

  /// Controller for unit.
  late final TextEditingController _unitController;

  /// Selected configured unit ID.
  String _unitId = '';

  /// Selected custom unit text.
  String _customUnit = '';

  /// Optional ingredient image.
  File? _imageFile;

  /// Available ingredient units.
  List<AddRecipeIngredientUnit> _units = const [];

  /// Whether unit options are loading.
  bool _isLoadingUnits = true;

  /// Unit loading error.
  String? _unitError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _amountController = TextEditingController();
    _unitController = TextEditingController();
    _loadUnits();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    return AlertDialog(
      title: Text('Add Ingredient', style: context.text.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Optional ingredient image.
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: viewModel.isSaving ? null : _pickImage,
                borderRadius: BorderRadius.circular(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 72,
                    height: 72,
                    color: const Color(0xFFF7F7F7),
                    child: _imageFile == null
                        ? const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Color(0xFFC9CBCD),
                            size: 34,
                          )
                        : Image.file(_imageFile!, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Ingredient name.
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Ingredient name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Quantity and unit row.
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: InkWell(
                    onTap: viewModel.isSaving || _isLoadingUnits
                        ? null
                        : _showUnitSheet,
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: const OutlineInputBorder(),
                        suffixIcon: _isLoadingUnits
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const Icon(Icons.keyboard_arrow_down),
                      ),
                      child: Text(
                        _unitController.text.trim().isEmpty
                            ? 'Select'
                            : _unitController.text.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium?.copyWith(
                          color: _unitController.text.trim().isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_unitError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _unitError!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],

            // Error message if any.
            if (viewModel.actionErrorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                viewModel.actionErrorMessage!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: viewModel.isSaving
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: viewModel.isSaving ? null : _saveItem,
          child: Text(viewModel.isSaving ? 'Adding...' : 'Add'),
        ),
      ],
    );
  }

  Future<void> _loadUnits() async {
    final result = await sl<GetAddRecipeIngredientUnitsUseCase>().execute();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _unitError = failure.message;
        _isLoadingUnits = false;
      }),
      (units) => setState(() {
        _units = units;
        _isLoadingUnits = false;
      }),
    );
  }

  Future<void> _pickImage() async {
    final result = await fp.FilePicker.pickFiles(
      allowMultiple: false,
      type: fp.FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
    );
    final path = result?.files.firstOrNull?.path;
    if (path == null || !mounted) return;
    setState(() => _imageFile = File(path));
  }

  Future<void> _showUnitSheet() async {
    final selected = await showModalBottomSheet<UnitPickerSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => IngredientUnitPickerSheet(
        units: _units,
        selectedUnitId: _unitId,
        selectedCustomUnit: _customUnit,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _unitId = selected.isCustom ? '' : selected.unitId;
      _customUnit = selected.isCustom ? selected.unitName : '';
      _unitController.text = selected.unitName;
    });
  }

  /// Saves the new item.
  Future<void> _saveItem() async {
    final saved = await context.read<ManageGroceryListViewModel>().addItem(
      name: _nameController.text,
      amountText: _amountController.text,
      unit: _unitController.text,
      unitId: _unitId,
      customUnit: _customUnit,
      imageFile: _imageFile,
      relatedMealPlanIds: widget.relatedMealPlanIds,
    );
    if (saved && mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Shows the add ingredient dialog.
Future<void> _showAddIngredientDialog(
  BuildContext context, {
  List<String> relatedMealPlanIds = const [],
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<ManageGroceryListViewModel>(),
      child: _AddGroceryItemDialog(relatedMealPlanIds: relatedMealPlanIds),
    ),
  );
}
