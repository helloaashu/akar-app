import 'package:flutter/material.dart';

import '../../services/preference_service.dart';

Future<void> showAIModeDialog(BuildContext context) async {
  bool dontAskAgain = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Choose Your AI Mode'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔹 Basic AI:\n• Offline\n• Detects potholes, cracks, etc.\n• Fast, lightweight'),
                  SizedBox(height: 12),
                  Text('🔸 Gemini AI:\n• Online\n• Smart auto-fill & suggestions\n• Needs internet'),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: dontAskAgain,
                        onChanged: (val) => setState(() => dontAskAgain = val!),
                      ),
                      Expanded(child: Text("Don't ask me again")),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (dontAskAgain) {
                    PreferenceService.setShowAIModePrompt(false);
                  }
                  Navigator.of(context).pop();
                },
                child: Text('Continue'),
              ),
            ],
          );
        },
      );
    },
  );
}
