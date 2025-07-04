import 'package:flutter/material.dart';
import '../../utils/form_validators.dart';

class ComplaintDetailsSection extends StatelessWidget {
  final TextEditingController controller;

  const ComplaintDetailsSection({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Complaint Details',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      maxLines: 3,
      validator: FormValidators.validateComplaintDetails,
    );
  }
}