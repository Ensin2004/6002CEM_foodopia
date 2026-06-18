part of '../../view/planning/generate_ai_meal_page.dart';

/// Shared form widgets used across AI meal generation steps.
///
/// Small inputs, chips, badges, and reusable cards are kept outside the page shell.
class _MiniInfoTile extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Label text.
  final String label;

  /// Value text.
  final String value;

  /// Creates a new mini info tile instance.
  const _MiniInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.bodySmall),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Expandable factor card widget.
class _ExpandableFactorCard extends StatefulWidget {
  /// Icon to display.
  final IconData icon;

  /// Title text.
  final String title;

  /// Subtitle text.
  final String subtitle;

  /// Selected labels to display.
  final List<String> selectedLabels;

  /// Children widgets.
  final List<Widget> children;

  /// Creates a new expandable factor card instance.
  const _ExpandableFactorCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selectedLabels,
    required this.children,
  });

  @override
  State<_ExpandableFactorCard> createState() => _ExpandableFactorCardState();
}

/// State for the expandable factor card.
class _ExpandableFactorCardState extends State<_ExpandableFactorCard> {
  /// Whether the card is expanded.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Filter out empty labels.
    final labels = widget.selectedLabels
        .where((label) => label.trim().isNotEmpty)
        .toSet()
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header with expand/collapse toggle.
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(widget.icon, color: AppColors.textSecondary, size: 22),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: context.text.titleMedium),
                        const SizedBox(height: 2),
                        Text(widget.subtitle, style: context.text.bodySmall),
                        if (labels.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _ChipWrap(values: labels, selectedValues: labels),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down, size: 18),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content.
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.children,
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}

/// Word limited text input widget.
class _WordLimitedTextInput extends StatefulWidget {
  /// Hint text.
  final String hintText;

  /// Callback when text changes.
  final ValueChanged<String> onChanged;

  /// Creates a new word limited text input instance.
  const _WordLimitedTextInput({
    required this.hintText,
    required this.onChanged,
  });

  @override
  State<_WordLimitedTextInput> createState() => _WordLimitedTextInputState();
}

/// State for the word limited text input.
class _WordLimitedTextInputState extends State<_WordLimitedTextInput> {
  /// Maximum number of words allowed.
  static const _maxWords = 30;

  /// Text controller.
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Count words in the current text.
    final count = _wordCount(_controller.text);

    return TextField(
      controller: _controller,
      onChanged: (value) {
        // Limit the number of words.
        final limited = _limitWords(value);

        // Update controller if limited.
        if (limited != value) {
          _controller.value = TextEditingValue(
            text: limited,
            selection: TextSelection.collapsed(offset: limited.length),
          );
        }

        // Call the onChanged callback.
        widget.onChanged(limited);

        // Update the state.
        setState(() {});
      },
      minLines: 1,
      maxLines: 3,
      style: context.text.bodySmall?.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hintText,
        helperText: '$count/$_maxWords words',
        hintStyle: context.text.bodySmall?.copyWith(
          color: AppColors.textSecondary.withValues(alpha: 0.65),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  /// Counts the number of words in a string.
  int _wordCount(String value) {
    return value.trim().isEmpty ? 0 : value.trim().split(RegExp(r'\s+')).length;
  }

  /// Limits a string to the maximum number of words.
  String _limitWords(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    if (value.trim().isEmpty || words.length <= _maxWords) return value;
    return words.take(_maxWords).join(' ');
  }
}

/// Difficulty level picker widget.
class _DifficultyLevelPicker extends StatelessWidget {
  /// Selected difficulty level.
  final int selectedLevel;

  /// Callback when a level is selected.
  final ValueChanged<int> onSelected;

  /// Creates a new difficulty level picker instance.
  const _DifficultyLevelPicker({
    required this.selectedLevel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Define difficulty levels.
    const levels = ['Novice', 'Beginner', 'Intermediate', 'Advanced', 'Master'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Difficulty Level'),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: levels.asMap().entries.map((entry) {
              final levelValue = entry.key + 1;
              final selected = levelValue <= selectedLevel;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelected(levelValue),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.restaurant_menu_rounded,
                        size: 24,
                        color: selected
                            ? AppColors.secondary
                            : AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          entry.value,
                          maxLines: 1,
                          style: context.text.bodySmall?.copyWith(
                            fontSize: 9,
                            color: selected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary.withValues(
                                    alpha: 0.5,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Cooking minutes input widget.
class _CookingMinutesInput extends StatelessWidget {
  /// Current minutes value.
  final int minutes;

  /// Callback when minutes change.
  final ValueChanged<String> onChanged;

  /// Creates a new cooking minutes input instance.
  const _CookingMinutesInput({required this.minutes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Cooking Time'),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          initialValue: minutes.toString(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          style: context.text.bodySmall?.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. 30',
            suffixText: 'minutes',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

/// Serving size input widget.
class _ServingSizeInput extends StatelessWidget {
  /// Current servings value.
  final int servings;

  /// Callback when servings change.
  final ValueChanged<String> onChanged;

  /// Creates a new serving size input instance.
  const _ServingSizeInput({required this.servings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Servings'),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          initialValue: servings.toString(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          style: context.text.bodySmall?.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. 1',
            suffixText: 'servings',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

/// Chip wrap widget.
class _ChipWrap extends StatelessWidget {
  /// List of values to display as chips.
  final List<String> values;

  /// List of selected values.
  final List<String> selectedValues;

  /// Callback when a chip is selected.
  final ValueChanged<String>? onSelected;

  /// Whether to use danger styling.
  final bool danger;

  /// Creates a new chip wrap instance.
  const _ChipWrap({
    required this.values,
    required this.selectedValues,
    this.onSelected,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    // Create a set of selected values for quick lookup.
    final selectedSet = selectedValues.toSet();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: values.map((value) {
        final selected = selectedSet.contains(value);
        return InkWell(
          onTap: onSelected == null ? null : () => onSelected!(value),
          borderRadius: BorderRadius.circular(12),
          child: _SmallChip(label: value, selected: selected, danger: danger),
        );
      }).toList(),
    );
  }
}

/// Section label widget.
class _SectionLabel extends StatelessWidget {
  /// Label text.
  final String label;

  /// Creates a new section label instance.
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.text.bodySmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

/// Selected summary text widget.
class _SelectedSummaryText extends StatelessWidget {
  /// Text to display.
  final String text;

  /// Creates a new selected summary text instance.
  const _SelectedSummaryText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.text.bodySmall?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

/// Factor card widget.
class _FactorCard extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Title text.
  final String title;

  /// Subtitle text.
  final String subtitle;

  /// Whether to highlight the card.
  final bool highlighted;

  /// Creates a new factor card instance.
  const _FactorCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.secondary.withValues(alpha: 0.18)
            : Colors.white,
        border: Border.all(
          color: highlighted
              ? AppColors.secondary.withValues(alpha: 0.75)
              : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: highlighted
                ? const Color(0xFF8A6400)
                : AppColors.textSecondary,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Recipe result card widget.
