import 'package:fixthecity/admin/set_status.dart';
import 'package:fixthecity/admin/view_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fixthecity/admin/review/map_page.dart';


class ComplaintDetailPage extends StatelessWidget {
  final String complaintId;

  ComplaintDetailPage({required this.complaintId});

  String formatTimestamp(Timestamp timestamp) {
    var dateTime = timestamp.toDate();
    return DateFormat('MMMM d, y \'at\' h:mm:ss a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Complaint Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .where('ticketNumber', isEqualTo: complaintId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Complaint not found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ticket: $complaintId',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          var complaintData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          var documentId = snapshot.data!.docs.first.id;

          // Safely get data with null checks
          var name = complaintData['userID'] ?? 'Unknown User';
          var ticketNumber = complaintData['ticketNumber'] ?? 'Unknown';
          var complaintDetails = complaintData['description'] ?? 'No description provided';
          var complaintType = complaintData['complaintType'] ?? complaintData['formType'] ?? 'Unknown Type';
          var category = complaintData['category'] ?? complaintData['department'] ?? 'Unknown Category';
          var status = complaintData['status'] ?? 'Unknown Status';
          var severity = complaintData['severity'] ?? 'Unknown';
          var title = complaintData['title'] ?? 'No Title';

          // Handle timestamp
          var timestamp = complaintData['timestamp'];
          var formattedDate = 'Unknown Date';
          if (timestamp != null) {
            try {
              if (timestamp is Timestamp) {
                formattedDate = formatTimestamp(timestamp);
              } else if (timestamp is String) {
                var dateTime = DateTime.parse(timestamp);
                formattedDate = DateFormat('MMMM d, y \'at\' h:mm:ss a').format(dateTime);
              }
            } catch (e) {
              formattedDate = 'Invalid Date';
            }
          }

          // Handle location
          var location = complaintData['location'];
          var latitude = 'Unknown';
          var longitude = 'Unknown';
          var landmark = complaintData['landmark'] ?? 'Not specified';
          var streetName = complaintData['streetName'] ?? complaintData['address'] ?? 'Not specified';

          if (location != null && location is GeoPoint) {
            latitude = location.latitude.toStringAsFixed(6);
            longitude = location.longitude.toStringAsFixed(6);
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Icon(Icons.person, color: Colors.deepPurple, size: 30),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Ticket: $ticketNumber',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                                SizedBox(height: 4),
                                _buildStatusBadge(status),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Complaint Details Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description, color: Colors.deepPurple),
                              SizedBox(width: 8),
                              Text(
                                'Complaint Details',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          _buildDetailRow('Title', title),
                          SizedBox(height: 16),
                          _buildDetailRow('Description', complaintDetails),
                          SizedBox(height: 16),
                          _buildDetailRow('Type', complaintType),
                          SizedBox(height: 16),
                          _buildDetailRow('Category', category),
                          SizedBox(height: 16),
                          _buildDetailRow('Severity', severity, _getSeverityColor(severity)),
                          SizedBox(height: 16),
                          _buildDetailRow('Date Submitted', formattedDate),

                          SizedBox(height: 24),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ImageCarousel(complaintId: documentId),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              icon: Icon(Icons.image),
                              label: Text('View Images'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Location Details Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.deepPurple),
                              SizedBox(width: 8),
                              Text(
                                'Location Details',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          // _buildDetailRow('Landmark', landmark),
                          SizedBox(height: 16),
                          _buildDetailRow('Street/Address', streetName),
                          SizedBox(height: 16),
                          _buildDetailRow('Coordinates', 'Lat: $latitude, Lng: $longitude'),

                          SizedBox(height: 24),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Updated onPressed function for in-app map
                                if (location != null && location is GeoPoint) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MapPage(
                                        latitude: location.latitude,
                                        longitude: location.longitude,
                                        title: 'Complaint Location - $ticketNumber',
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Location coordinates not available'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              icon: Icon(Icons.map),
                              label: Text('View on Map'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return SetStatusPage(complaintId: complaintId);
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.symmetric(vertical: 16),
            elevation: 2,
          ),
          child: Text(
            'Update Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: valueColor ?? Colors.grey[800],
            fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'resolved':
      case 'complaint resolved':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case 'in progress':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.hourglass_empty;
        break;
      case 'withdrawn':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.pending;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}