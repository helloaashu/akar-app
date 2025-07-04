import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewDetailsModal extends StatelessWidget {
  final String userId;
  final String reviewId;
  final TextEditingController _replyController = TextEditingController();

  ReviewDetailsModal({required this.userId, required this.reviewId});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('feedback').doc(reviewId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(child: Text('Error: ${snapshot.error}')),
            );
          }

          if (!snapshot.data!.exists) {
            return Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(child: Text('Review not found.')),
            );
          }

          final reviewData = snapshot.data!.data() as Map<String, dynamic>?;
          if (reviewData == null) {
            return Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(child: Text('Review data is null.')),
            );
          }

          final comment = reviewData['comments'] ?? 'No comment provided';
          final rating = reviewData['rating'] ?? 0;
          final timestamp = reviewData['timestamp'] as Timestamp? ?? Timestamp.now();

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
              final name = userData['name'] ?? 'No name provided';
              final homeAddress = userData['homeAddress'] ?? 'No address provided';
              final profileImageURL = userData['profileImageURL'] ?? 'https://via.placeholder.com/150';

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Review Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(comment),
                      SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.orange,
                            size: 20,
                          );
                        }),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16),
                          SizedBox(width: 5),
                          Text(timestamp.toDate().toString()),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(profileImageURL),
                          ),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(homeAddress),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _replyController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Reply for this message',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () async {
                            final replyText = _replyController.text.trim();
                            if (replyText.isEmpty) return;

                            await FirebaseFirestore.instance.collection('feedback').doc(reviewId).update({
                              'adminReply': replyText,
                            });

                            await FirebaseFirestore.instance.collection('feedback').doc(reviewId).delete();

                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                          child: Text(
                            'Submit',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
