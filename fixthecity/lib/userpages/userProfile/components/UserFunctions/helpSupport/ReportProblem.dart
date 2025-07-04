import 'package:flutter/material.dart';

class ReportProblemPage extends StatelessWidget {
  const ReportProblemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text('Report a Problem', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
      ),

      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Describe the problem',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('Submit'),
              onPressed: () {
                // Implement problem submission logic
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Problem report submitted. Thank you!')),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
