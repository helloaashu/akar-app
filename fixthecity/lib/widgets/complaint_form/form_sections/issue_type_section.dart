import 'package:flutter/material.dart';
import '../../utils/issue_types_data.dart';
import '../../utils/form_validators.dart';

class IssueTypeSection extends StatelessWidget {
  final String? category;
  final String? complaintType;
  final String? customIssueType;
  final Function(String?) onComplaintTypeChanged;
  final Function(String?) onCustomIssueTypeChanged;

  const IssueTypeSection({
    Key? key,
    required this.category,
    required this.complaintType,
    required this.customIssueType,
    required this.onComplaintTypeChanged,
    required this.onCustomIssueTypeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (category == 'Other') {
      return TextFormField(
        decoration: InputDecoration(
          labelText: 'Specify Issue Type',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onChanged: onCustomIssueTypeChanged,
      );
    }

    List<String> issueTypes =
    IssueTypesData.getIssueTypesForCategory(category).toSet().toList();

    return Column(
      children: [
        DropdownButtonFormField<String>(
          validator: FormValidators.validateComplaintType,
          decoration: InputDecoration(
            labelText: 'Issue Type',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          value: complaintType,
          items: issueTypes.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onComplaintTypeChanged,
        ),
        if (category != 'Other' && complaintType == 'Other')
          Padding(
            padding: const EdgeInsets.only(top: 17.0),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Specify Other Issue Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: onCustomIssueTypeChanged,
            ),
          ),
      ],
    );
  }
}