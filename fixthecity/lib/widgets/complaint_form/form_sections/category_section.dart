import 'package:flutter/material.dart';
import '../../utils/issue_types_data.dart';


class CategorySection extends StatelessWidget {
  final String? category;
  final String? customCategory;
  final Function(String?) onCategoryChanged;
  final Function(String?) onCustomCategoryChanged;

  const CategorySection({
    Key? key,
    required this.category,
    required this.customCategory,
    required this.onCategoryChanged,
    required this.onCustomCategoryChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Problem Category',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          value: category,
          items: IssueTypesData.categories.toSet().map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onCategoryChanged,
        ),
        if (category == 'Other')
          Padding(
            padding: const EdgeInsets.only(top: 17.0),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Specify Other Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: onCustomCategoryChanged,
            ),
          ),
      ],
    );
  }
}