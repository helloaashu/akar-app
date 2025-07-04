import 'package:flutter/material.dart';

class NatureComplaintSection extends StatelessWidget {
  final String? natureOfComplaint;
  final Function(String?) onChanged;

  const NatureComplaintSection({
    Key? key,
    required this.natureOfComplaint,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Nature of Complaint',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      value: natureOfComplaint,
      items: <String>[
        'High (Major disruption, safety risk)',
        'Medium (Significant inconvenience)',
        'Low (General maintenance request)',
      ].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}