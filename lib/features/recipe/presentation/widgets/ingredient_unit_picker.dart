import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';

class UnitPickerSheet extends StatefulWidget {
  final List<String> units;
  final String selectedUnit;

  const UnitPickerSheet({
    super.key,
    required this.units,
    required this.selectedUnit,
  });

  @override
  State<UnitPickerSheet> createState() => _UnitPickerSheetState();
}

class _UnitPickerSheetState extends State<UnitPickerSheet> {
  final TextEditingController _customUnitController = TextEditingController();

  @override
  void dispose() {
    _customUnitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + bottomInset,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                "Select Unit",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _customUnitController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: "Custom Unit",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                onSubmitted: _submitCustomUnit,
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      _submitCustomUnit(_customUnitController.text),
                  child: const Text("Use Custom Unit"),
                ),
              ),
              const Divider(height: AppSpacing.lg),
              Expanded(
                child: widget.units.isEmpty
                    ? Center(
                  child: Image.asset(
                    "assets/images/empty_page.png",
                    height: 120,
                  ),
                )
                    : ListView.separated(
                  itemCount: widget.units.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final unit = widget.units[index];
                    final isSelected = widget.selectedUnit == unit;
                    return ListTile(
                      title: Text(
                        unit,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isSelected
                          ? const Icon(
                        Icons.check,
                        color: AppColors.primary,
                      )
                          : null,
                      onTap: () => Navigator.of(context).pop(unit),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitCustomUnit(String value) {
    final unit = value.trim();
    if (unit.isEmpty) return;
    Navigator.of(context).pop(unit);
  }
}