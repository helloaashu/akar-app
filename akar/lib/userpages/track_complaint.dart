import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'complaint_history.dart';

class TrackComplaintPage extends StatelessWidget {
  final ComplaintData complaintData;

  TrackComplaintPage({required this.complaintData, required String ticketNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Track Complaint', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header Section (Complaint Details)
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complaint Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 15),
                  ComplaintInfoTile(
                    icon: Icons.category,
                    title: 'Category',
                    content: complaintData.category,
                  ),
                  ComplaintInfoTile(
                    icon: Icons.confirmation_number,
                    title: 'Ticket No.',
                    content: complaintData.ticketNo,
                  ),
                  ComplaintInfoTile(
                    icon: Icons.description,
                    title: 'Description',
                    content: complaintData.description,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Improved Timeline Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('complaints')
                    .doc(complaintData.ticketNo)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                    return Text('No timeline data available or an error occurred.');
                  }

                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  String status = data['status'] ?? 'Unknown Status';
                  String complaintDetails = data['complaintDetails'] ?? 'No details available';
                  String adminProgressNotes = data['adminProgressNotes'] ?? 'No progress notes available';

                  bool isAdminReviewCompleted = adminProgressNotes != 'No progress notes available';
                  bool isComplaintResolved = status == 'Complaint Resolved';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complaint Timeline',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      SizedBox(height: 20),
                      TimelineTile(
                        title: 'Complaint Filed',
                        description: complaintDetails,
                        isCompleted: true,
                        icon: Icons.file_present,
                      ),
                      TimelineTile(
                        title: 'Admin Review',
                        description: adminProgressNotes,
                        isCompleted: isAdminReviewCompleted,
                        icon: Icons.admin_panel_settings,
                      ),
                      TimelineTile(
                        title: 'Current Status',
                        description: status,
                        isCompleted: isComplaintResolved,
                        icon: Icons.flag,
                        isLast: true,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComplaintInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  ComplaintInfoTile({required this.icon, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
                Text(
                  content,
                  style: TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TimelineTile extends StatelessWidget {
  final String title;
  final String description;
  final bool isCompleted;
  final bool isLast;
  final IconData icon;

  TimelineTile({
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? Colors.green : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isCompleted ? Colors.green : Colors.deepPurple.shade700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}