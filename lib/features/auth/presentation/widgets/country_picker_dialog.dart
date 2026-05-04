// Defines the country picker dialog widget.

import 'package:flutter/material.dart';

/// Defines behavior for country picker dialog.
class CountryPickerDialog extends StatefulWidget {
  final List<Map<String, dynamic>> items;  // Changed to required (not nullable)
  final String? selectedId;

  /// Creates a country picker dialog instance.
  const CountryPickerDialog({
    super.key,
    required this.items,  // Required field
    this.selectedId,
  });

  /// Creates data for the create state operation.
  @override
  State<CountryPickerDialog> createState() => _CountryPickerDialogState();
}

/// Defines behavior for country picker dialog state.
class _CountryPickerDialogState extends State<CountryPickerDialog> {
  late List<Map<String, dynamic>> filtered;
  final TextEditingController _searchController = TextEditingController();

  /// Initializes state before the first widget build.
  @override
  void initState() {
    super.initState();
    filtered = widget.items;  // Direct assignment, no fallback
  }

  /// Handles the filter countries operation.
  void _filterCountries(String query) {
    setState(() {
      // Updates state values displayed by the current screen.
      filtered = widget.items.where((item) {
        final country = (item['country'] as String).toLowerCase();
        final currency = (item['currency'] as String).toLowerCase();
        final searchLower = query.toLowerCase();
        return country.contains(searchLower) || currency.contains(searchLower);
      }).toList();
    });
  }

  /// Releases resources before widget removal.
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Handles the dialog operation.
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 500,
        child: Column(
          children: [
            /// Creates a text field instance.
            TextField(
              controller: _searchController,
              onChanged: _filterCountries,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search country...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            /// Creates a sized box instance.
            const SizedBox(height: 8),
            /// Creates a expanded instance.
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final isSelected = item['id'] == widget.selectedId;

                  /// Handles the list tile operation.
                  return ListTile(
                    title: Text(
                      "${item['country']} (${item['currency']})",
                    ),
                    trailing: isSelected
                        ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                        : null,
                    onTap: () => Navigator.pop(context, item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
