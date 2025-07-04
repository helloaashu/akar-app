import 'package:flutter/material.dart';
import 'package:flutter_emoji_feedback/flutter_emoji_feedback.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For user ID (if using Firebase Authentication)
import 'package:share/share.dart';

class FeedbackPage extends StatefulWidget {
  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  bool _isSubmitting = false;
  int _selectedFeedback = -1;
  TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Give Feedback', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width,
                child: Image.asset(
                  'assets/review12.png',
                  fit: BoxFit.cover,
                ),
              ),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How satisfied are you with the overall experience of using the app?',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      EmojiFeedback(
                        onChanged: (value) {
                          setState(() {
                            _selectedFeedback = value;
                          });
                        },
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          labelText: 'What are the main reasons for your rating?',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitFeedback,
                            child: _isSubmitting
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : Text('Submit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitFeedback() async {
    if (_selectedFeedback == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a rating before submitting.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('feedback').add({
          'userId': user.uid,
          'rating': _selectedFeedback,
          'comments': _commentController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _showShareOptionsDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in. Please log in to submit feedback.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit feedback. Please try again later.')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showShareOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Thank you for your feedback!'),
          content: Text('Would you like to share your experience?'),
          actions: <Widget>[
            TextButton(
              child: Text('No, thanks'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Share'),
              onPressed: () {
                Navigator.of(context).pop();
                _shareExperience();
              },
            ),
          ],
        );
      },
    );
  }

  void _shareExperience() {
    String feedbackText = 'Rating: $_selectedFeedback\nComments: ${_commentController.text}';
    Share.share(feedbackText);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
