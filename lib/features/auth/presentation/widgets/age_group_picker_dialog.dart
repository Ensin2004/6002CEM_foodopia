import 'package:flutter/material.dart';

/// Dialog for selecting an age group from the configured list.
class AgeGroupPickerDialog extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String? selectedId;

  const AgeGroupPickerDialog({
    super.key,
    required this.items,
    this.selectedId,
  });

  @override
  State<AgeGroupPickerDialog> createState() => _AgeGroupPickerDialogState();
}

class _AgeGroupPickerDialogState extends State<AgeGroupPickerDialog> {
  late List<Map<String, dynamic>> filtered;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filtered = widget.items;
  }

  void _filterAgeGroups(String query) {
    setState(() {
      final searchLower = query.toLowerCase();
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
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No age groups found'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isSelected = item['id'] == widget.selectedId;
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
