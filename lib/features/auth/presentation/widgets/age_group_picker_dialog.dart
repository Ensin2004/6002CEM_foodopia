import 'package:flutter/material.dart';

/// Dialog for selecting an age group from the configured list.
/// Provides search functionality and displays available age groups.
class AgeGroupPickerDialog extends StatefulWidget {
  /// List of age group items to display.
  final List<Map<String, dynamic>> items;

  /// ID of the currently selected age group.
  final String? selectedId;

  /// Creates a new age group picker dialog instance.
  const AgeGroupPickerDialog({
    super.key,
    required this.items,
    this.selectedId,
  });

  @override
  State<AgeGroupPickerDialog> createState() => _AgeGroupPickerDialogState();
}

/// State for the age group picker dialog.
class _AgeGroupPickerDialogState extends State<AgeGroupPickerDialog> {
  /// Filtered list of age groups based on search.
  late List<Map<String, dynamic>> filtered;

  /// Controller for the search input field.
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize filtered list with all items.
    filtered = widget.items;
  }

  /// Filters age groups based on search query.
  void _filterAgeGroups(String query) {
    setState(() {
      // Convert query to lowercase for case-insensitive search.
      final searchLower = query.toLowerCase();

      // Filter items by name or description.
      filtered = widget.items.where((item) {
        final name = (item['name'] as String? ?? '').toLowerCase();
        final description = (item['description'] as String? ?? '').toLowerCase();
        return name.contains(searchLower) || description.contains(searchLower);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 500,
        child: Column(
          children: [
            // Search field.
            TextField(
              controller: _searchController,
              onChanged: _filterAgeGroups,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search age group...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // List of age groups.
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No age groups found'))
                  : ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  // Get the item at the current index.
                  final item = filtered[index];

                  // Check if this item is selected.
                  final isSelected = item['id'] == widget.selectedId;

                  // Get the description.
                  final description = item['description'] as String? ?? '';

                  return ListTile(
                    title: Text(item['name'] as String? ?? ''),
                    subtitle: description.isNotEmpty ? Text(description) : null,
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