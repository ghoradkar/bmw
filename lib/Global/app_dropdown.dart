import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'constant.dart';
Widget _boxedDropdown({required Widget child})
{ return Container(
  decoration: BoxDecoration( border: Border.all(color: Colors.grey),
    borderRadius: BorderRadius.circular(14), ), child: child, ); }



Widget validatedApiDropdown({
  required String hint,
  required Map<String, dynamic>? value,
  required List<Map<String, dynamic>> items,
  required String displayKey,
  required IconData icon,
  required String errorText,
  required ValueChanged<Map<String, dynamic>?> onChanged,
  Color? color
}) {
  return FormField<Map<String, dynamic>>(
    validator: (val) {
      if (value != null) return null; // ✅ API value present
      if (items.isEmpty) return "No data available";
      if (val == null) return errorText;
      return null;
    },
    builder: (state) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _boxedDropdown(
            child: DropdownButtonFormField<Map<String, dynamic>>(
              isExpanded: true,
              value: value,
              decoration: InputDecoration(
                fillColor: color,
                hintText: hint,
                prefixIcon: Icon(icon, color: kPrimaryDarkColor),
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: items.map((item) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: item,
                  child: Text(
                    (item[displayKey] ?? '').toString().trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                state.didChange(val);
                onChanged(val);
              },
            ),
          ),
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 6),
              child: Text(
                state.errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 11),
              ),
            ),
        ],
      );
    },
  );
}
