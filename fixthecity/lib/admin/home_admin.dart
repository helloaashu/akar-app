import 'package:fixthecity/admin/solve_complaint.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomeAdmin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Manage Complaints',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ComplaintsHomePage(),
    );
  }
}

class ComplaintsHomePage extends StatefulWidget {
  @override
  _ComplaintsHomePageState createState() => _ComplaintsHomePageState();
}

class _ComplaintsHomePageState extends State<ComplaintsHomePage> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterChips(),
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('complaints')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
                  ),
                );
              }

              var allComplaints = snapshot.data!.docs;

              // Filter complaints based on the selected filter
              var complaints = _filterComplaints(allComplaints);

              // Apply search filter
              if (_searchQuery.isNotEmpty) {
                complaints = complaints.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var title = data['title']?.toString().toLowerCase() ?? '';
                  var description = data['description']?.toString().toLowerCase() ?? '';
                  var ticketNumber = data['ticketNumber']?.toString().toLowerCase() ?? '';
                  var department = data['department']?.toString().toLowerCase() ?? '';

                  return title.contains(_searchQuery.toLowerCase()) ||
                      description.contains(_searchQuery.toLowerCase()) ||
                      ticketNumber.contains(_searchQuery.toLowerCase()) ||
                      department.contains(_searchQuery.toLowerCase());
                }).toList();
              }

              // Get high priority complaints for the compact section
              var highSeverityComplaints = allComplaints.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                var severity = data['severity']?.toString().toLowerCase() ?? '';
                var status = data['status']?.toString().toLowerCase() ?? '';

                return severity == 'high' && !status.contains('resolved');
              }).toList();

              if (complaints.isEmpty) {
                return _buildEmptyState();
              }

              return CustomScrollView(
                slivers: [
                  // Show compact high priority section for "All" filter only
                  if (_selectedFilter == 'All' && highSeverityComplaints.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildCompactHighPrioritySection(highSeverityComplaints),
                    ),

                  // Section header for current filter
                  if (_selectedFilter != 'All')
                    SliverToBoxAdapter(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        child: Text(
                          '${_selectedFilter} Complaints (${complaints.length})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ),

                  // Main complaints list
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          var complaint = complaints[index].data() as Map<String, dynamic>;
                          return ComplaintCard(
                            documentId: complaints[index].id,
                            userID: complaint['userID']?.toString() ?? 'Unknown User',
                            timestamp: complaint['timestamp'],
                            ticketNumber: complaint['ticketNumber']?.toString() ?? 'Unknown',
                            title: complaint['title']?.toString() ?? 'No Title',
                            description: complaint['description']?.toString() ?? 'No description provided',
                            department: complaint['department']?.toString() ?? 'Unknown Department',
                            formType: complaint['formType']?.toString() ?? 'Unknown Type',
                            severity: complaint['severity']?.toString() ?? 'Unknown',
                            status: complaint['status']?.toString() ?? 'Unknown Status',
                          );
                        },
                        childCount: complaints.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }



  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search complaints...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.deepPurple.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.deepPurple, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.deepPurple.shade200),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        style: TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All'),
            SizedBox(width: 8),
            _buildFilterChip('High Priority'),
            SizedBox(width: 8),
            _buildFilterChip('Pending'),
            SizedBox(width: 8),
            _buildFilterChip('In Progress'),
            SizedBox(width: 8),
            _buildFilterChip('Resolved'),
            SizedBox(width: 16), // Extra space at the end
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    Color selectedColor = label == 'High Priority' ? Colors.red : Colors.deepPurple;
    Color backgroundColor = label == 'High Priority'
        ? Colors.red.shade50
        : Colors.deepPurple.shade50;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label == 'High Priority')
            Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Icons.priority_high,
                size: 14,
                color: isSelected ? Colors.white : Colors.red,
              ),
            ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : selectedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (bool value) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: selectedColor,
      backgroundColor: backgroundColor,
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildCompactHighPrioritySection(List<QueryDocumentSnapshot> highPriorityComplaints) {
    // Filter to ensure only non-resolved high priority complaints
    var activeHighPriorityComplaints = highPriorityComplaints.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      var status = data['status']?.toString().toLowerCase() ?? '';
      return !status.contains('resolved');
    }).toList();

    if (activeHighPriorityComplaints.isEmpty) {
      return Container();
    }

    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.red.shade100],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        children: [
          // Compact header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade600, Colors.red.shade700],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.priority_high, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'High Priority: ${activeHighPriorityComplaints.length} urgent complaints',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = 'High Priority';
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Show first 2 high priority complaints in a compact format
          Container(
            padding: EdgeInsets.all(6),
            child: Column(
              children: activeHighPriorityComplaints.take(2).map((doc) {
                var complaint = doc.data() as Map<String, dynamic>;
                return Container(
                  margin: EdgeInsets.only(bottom: 6),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(Icons.priority_high, color: Colors.red, size: 14),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaint['title']?.toString() ?? 'No Title',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Ticket: ${complaint['ticketNumber']?.toString() ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ComplaintDetailPage(
                                complaintId: complaint['ticketNumber']?.toString() ?? '',
                              ),
                            ),
                          );
                        },
                        child: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;
    IconData icon;
    Color iconColor;

    switch (_selectedFilter) {
      case 'High Priority':
        message = 'No urgent high priority complaints';
        subtitle = 'All high severity issues have been resolved or are being handled';
        icon = Icons.check_circle_outline;
        iconColor = Colors.green.shade400;
        break;
      case 'Pending':
        message = 'No pending complaints';
        subtitle = 'All complaints are being processed or resolved';
        icon = Icons.inbox_outlined;
        iconColor = Colors.blue.shade400;
        break;
      case 'In Progress':
        message = 'No complaints in progress';
        subtitle = 'No active work is currently being done';
        icon = Icons.hourglass_empty;
        iconColor = Colors.orange.shade400;
        break;
      case 'Resolved':
        message = 'No resolved complaints';
        subtitle = 'No complaints have been resolved yet';
        icon = Icons.task_alt;
        iconColor = Colors.green.shade400;
        break;
      default:
        message = 'No complaints found';
        subtitle = 'All complaints matching your criteria will appear here';
        icon = Icons.inbox_outlined;
        iconColor = Colors.grey.shade400;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: iconColor,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterComplaints(List<QueryDocumentSnapshot> complaints) {
    if (_selectedFilter == 'All') return complaints;

    return complaints.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      var status = data['status']?.toString().toLowerCase() ?? '';
      var severity = data['severity']?.toString().toLowerCase() ?? '';

      switch (_selectedFilter) {
        case 'High Priority':
        // Only high severity complaints that are NOT resolved
          return severity == 'high' && !status.contains('resolved');

        case 'Pending':
        // Pending complaints that are NOT resolved and NOT in progress
          return !status.contains('resolved') &&
              !status.contains('progress') &&
              (status.isEmpty || status.contains('pending'));

        case 'In Progress':
        // Only complaints in progress (not resolved)
          return status.contains('progress') && !status.contains('resolved');

        case 'Resolved':
        // Only resolved complaints (regardless of priority)
          return status.contains('resolved');

        default:
          return true;
      }
    }).toList();
  }
}

class ComplaintCard extends StatelessWidget {
  final String documentId;
  final String userID;
  final dynamic timestamp;
  final String ticketNumber;
  final String title;
  final String description;
  final String department;
  final String formType;
  final String severity;
  final String status;

  ComplaintCard({
    required this.documentId,
    required this.userID,
    required this.timestamp,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.department,
    required this.formType,
    required this.severity,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and ticket number
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ticket #$ticketNumber',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                            fontFamily: 'Courier',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),

              SizedBox(height: 12),

              // Description
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 16),

              // Details row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDetailChip(Icons.business, department, Colors.blue),
                  _buildDetailChip(Icons.category, formType, Colors.green),
                  _buildSeverityChip(),
                ],
              ),

              SizedBox(height: 12),

              // Footer with user and time
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple.shade100,
                    radius: 16,
                    child: Icon(
                      Icons.person,
                      color: Colors.deepPurple,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userID,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          _formatTimestamp(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.visibility,
                        color: Colors.deepPurple,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ComplaintDetailPage(complaintId: ticketNumber),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String displayStatus;

    switch (status.toLowerCase()) {
      case 'in progress':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.timelapse;
        displayStatus = 'In Progress';
        break;
      case 'resolved':
      case 'complaint resolved':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        displayStatus = 'Resolved';
        break;
      case 'withdrawn':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        displayStatus = 'Withdrawn';
        break;
      default:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.hourglass_empty;
        displayStatus = 'Pending';
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
            displayStatus,
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

  Widget _buildDetailChip(IconData icon, String text, Color color) {
    // Truncate long text to prevent overflow
    String displayText = text.length > 12 ? text.substring(0, 12) + '...' : text;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChip() {
    Color color;
    IconData icon;

    switch (severity.toLowerCase()) {
      case 'high':
        color = Colors.red;
        icon = Icons.priority_high;
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.remove;
        break;
      case 'low':
        color = Colors.green;
        icon = Icons.expand_more;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            severity,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp() {
    if (timestamp == null) return 'Unknown time';

    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'Unknown time';
      }

      return DateFormat('MMM dd, yyyy • HH:mm').format(dateTime);
    } catch (e) {
      return 'Unknown time';
    }
  }
}