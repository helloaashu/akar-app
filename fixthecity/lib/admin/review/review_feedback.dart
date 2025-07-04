import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detailed_review.dart';

class ReviewsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            FutureBuilder(
              future: _getStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final stats = snapshot.data as Map<String, int>;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildStatCard('Reviews', stats['total'].toString(), Icons.rate_review),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard('Answered', stats['answered'].toString(), Icons.check_circle, countColor: Colors.green),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard('Due', (stats['total']! - stats['answered']!).toString(), Icons.schedule, countColor: Colors.red),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 10),
            Row(
              children: [
                _buildFilterChip('All Projects', isSelected: true),
                SizedBox(width: 10),
                _buildFilterChip('Filter 5'),
                SizedBox(width: 10),
                _buildFilterChip('Sorting'),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('feedback').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final reviews = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(review['userId']).get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return SizedBox();
                          }
                          final user = userSnapshot.data!;
                          final name = user.data().toString().contains('name') ? user['name'] : 'Unknown';
                          final homeAddress = user.data().toString().contains('homeAddress') ? user['homeAddress'] : 'No address';
                          final profileImageURL = user.data().toString().contains('profileImageURL') ? user['profileImageURL'] : '';
                          return _buildReviewCard(
                            context,
                            review['comments'],
                            review['rating'],
                            review['timestamp'],
                            name,
                            homeAddress,
                            profileImageURL,
                            review.id,
                            review['userId'],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _getStats() async {
    final feedbackSnapshot = await FirebaseFirestore.instance.collection('feedback').get();
    final answeredSnapshot = await FirebaseFirestore.instance.collection('feedback').where('answered', isEqualTo: true).get();

    final totalReviews = feedbackSnapshot.docs.length;
    final answeredReviews = answeredSnapshot.docs.length;

    return {
      'total': totalReviews,
      'answered': answeredReviews,
    };
  }

  Widget _buildStatCard(String title, String count, IconData icon, {Color countColor = Colors.black}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            SizedBox(height: 10),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: countColor,
              ),
            ),
            SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return FilterChip(
      label: Text(label),
      onSelected: (bool value) {},
      selected: isSelected,
      selectedColor: Colors.blue,
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildReviewCard(
      BuildContext context,
      String comment,
      int rating,
      Timestamp timestamp,
      String name,
      String homeAddress,
      String profileImageURL,
      String reviewId,
      String userId,
      ) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getRatingText(rating),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmationDialog(context, reviewId),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.orange,
                  size: 20,
                );
              }),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.access_time, size: 16),
                SizedBox(width: 5),
                Text(timestamp.toDate().toString()),
              ],
            ),
            SizedBox(height: 10),
            Text(
              comment,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: profileImageURL.isNotEmpty
                      ? NetworkImage(profileImageURL)
                      : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                  radius: 20,
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name),
                    Text(homeAddress, style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: ReviewDetailsModal(
                          userId: userId,            // ✅ already present
                          reviewId: reviewId,        // ✅ add this
                        ),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                child: Text(
                  'View Submissions',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, String reviewId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Review'),
          content: Text('Are you sure you want to delete this review?'),
          actions: <Widget>[
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Yes', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('feedback').doc(reviewId).delete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor experience';
      case 2:
        return 'Mediocre experience';
      case 3:
        return 'Neutral experience';
      case 4:
        return 'Excellent experience';
      case 5:
        return 'Outstanding experience';
      default:
        return '';
    }
  }
}
