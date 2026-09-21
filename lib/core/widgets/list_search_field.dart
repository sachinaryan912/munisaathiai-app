import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// A search box for filtering an already-loaded list client-side. Pair with a
/// `String _query = ''` field on the host screen's state and filter the list
/// by `.toLowerCase().contains(_query.toLowerCase())` in the builder.
class ListSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  const ListSearchField({super.key, required this.controller, required this.onChanged, this.hint = 'Search'});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Padding(
          padding: EdgeInsets.all(12),
          child: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, size: 18, color: Colors.grey),
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 16, color: Colors.grey),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}
