import 'package:flutter/material.dart';

class CountryPickerDialog extends StatefulWidget {
  final List<Map<String, dynamic>> items;  // ✅ Changed to required (not nullable)
  final String? selectedId;

  const CountryPickerDialog({
    super.key,
    required this.items,  // ✅ Now required
    this.selectedId,
  });

  @override
  State<CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<CountryPickerDialog> {
  late List<Map<String, dynamic>> filtered;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filtered = widget.items;  // ✅ Direct assignment, no fallback
  }

  void _filterCountries(String query) {
    setState(() {
      filtered = widget.items.where((item) {
        final country = (item['country'] as String).toLowerCase();
        final currency = (item['currency'] as String).toLowerCase();
        final searchLower = query.toLowerCase();
        return country.contains(searchLower) || currency.contains(searchLower);
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
              onChanged: _filterCountries,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search country...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final isSelected = item['id'] == widget.selectedId;

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