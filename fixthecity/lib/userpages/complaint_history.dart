import 'package:fixthecity/userpages/track_complaint.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ComplaintHistory extends StatefulWidget {
  final Function(int) onPageChanged;
  final String userID;

  const ComplaintHistory({
    Key? key,
    required this.onPageChanged,
    required this.userID,
  }) : super(key: key);

  @override
  State<ComplaintHistory> createState() => _ComplaintHistoryState();
}

class _ComplaintHistoryState extends State<ComplaintHistory> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.deepPurple,
        title: const Text(
          'Complaint History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(value: 'In Progress', child: Text('In Progress')),
              const PopupMenuItem(value: 'Resolved', child: Text('Resolved')),
              const PopupMenuItem(value: 'Withdrawn', child: Text('Withdrawn')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('In Progress'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Resolved'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Withdrawn'),
                ],
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder(
              future: _getComplaintHistory(),
              builder: (context, AsyncSnapshot<List<ComplaintData>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error fetching complaints',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Retry
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No complaints found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  var filteredComplaints = _filterComplaints(snapshot.data!);
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredComplaints.length,
                    itemBuilder: (context, index) {
                      var complaint = filteredComplaints[index];
                      return ComplaintCard(
                        complaint: complaint,
                        onWithdraw: () => _showWithdrawConfirmation(context, complaint),
                        onDelete: () => _showDeleteConfirmation(context, complaint),
                        onTrack: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrackComplaintPage(
                              complaintData: complaint,
                              ticketNumber: complaint.ticketNo,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: Colors.deepPurple.withOpacity(0.2),
      checkmarkColor: Colors.deepPurple,
      labelStyle: TextStyle(
        color: isSelected ? Colors.deepPurple : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  List<ComplaintData> _filterComplaints(List<ComplaintData> complaints) {
    if (_selectedFilter == 'All') {
      return complaints;
    }
    return complaints.where((complaint) {
      if (_selectedFilter == 'Resolved') {
        return complaint.status.toLowerCase().contains('resolved');
      }
      return complaint.status == _selectedFilter;
    }).toList();
  }

  // DEBUGGING VERSION OF _getComplaintHistory()
  Future<List<ComplaintData>> _getComplaintHistory() async {
    try {
      print("\n🔍 === STARTING _getComplaintHistory() ===");

      User? user = _auth.currentUser;
      if (user == null) {
        print("❌ User not authenticated");
        return [];
      }

      print("✅ User authenticated: ${user.uid}");
      print("📧 User email: ${user.email}");

      print("🔍 Querying Firestore...");
      print("📄 Collection: complaints");
      print("🔍 Where: userID == ${user.uid}");
      print("📅 OrderBy: createdAt descending");

      QuerySnapshot snapshot = await _firestore
          .collection('complaints')
          .where('userID', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      print("📄 Query executed successfully");
      print("📊 Found ${snapshot.docs.length} documents");

      if (snapshot.docs.isEmpty) {
        print("⚠️ No documents found for this user");
        print("🔍 Checking if any documents exist in complaints collection...");

        // Check if collection exists and has any documents
        QuerySnapshot allDocs = await _firestore
            .collection('complaints')
            .limit(1)
            .get();

        if (allDocs.docs.isEmpty) {
          print("❌ No documents found in complaints collection at all");
        } else {
          print("✅ Collection exists with documents, but none for this user");
          Map<String, dynamic>? firstDocData = allDocs.docs.first.data() as Map<String, dynamic>?;
          print("🔍 First document userID: ${firstDocData?['userID'] ?? 'MISSING'}");
        }

        return [];
      }

      List<ComplaintData> complaints = [];

      for (int i = 0; i < snapshot.docs.length; i++) {
        try {
          print("\n📋 === Processing document ${i + 1}/${snapshot.docs.length} ===");
          DocumentSnapshot doc = snapshot.docs[i];

          print("📄 Document ID: ${doc.id}");
          print("📄 Document exists: ${doc.exists}");

          if (!doc.exists) {
            print("❌ Document does not exist, skipping...");
            continue;
          }

          Map<String, dynamic>? rawData = doc.data() as Map<String, dynamic>?;
          print("📄 Raw data keys: ${rawData?.keys.toList() ?? 'NULL'}");

          ComplaintData complaint = ComplaintData.fromFirestore(doc);
          complaints.add(complaint);
          print("✅ Successfully parsed document ${i + 1}");

        } catch (e, stackTrace) {
          print("❌ Error parsing document ${i + 1}: $e");
          print("📄 Document ID: ${snapshot.docs[i].id}");
          print("📄 Document data: ${snapshot.docs[i].data()}");
          print("🔍 Stack trace: $stackTrace");
          // Continue with other documents
          continue;
        }
      }

      print("\n✅ === COMPLETED _getComplaintHistory() ===");
      print("📊 Total documents processed: ${snapshot.docs.length}");
      print("✅ Successfully parsed: ${complaints.length}");
      print("❌ Failed to parse: ${snapshot.docs.length - complaints.length}");

      return complaints;

    } catch (e, stackTrace) {
      print("\n❌ === ERROR in _getComplaintHistory() ===");
      print("❌ Error type: ${e.runtimeType}");
      print("❌ Error message: $e");
      print("🔍 Stack trace: $stackTrace");

      if (e is FirebaseException) {
        print("🔥 Firebase error code: ${e.code}");
        print("🔥 Firebase error message: ${e.message}");
        print("🔥 Firebase error details: ${e.toString()}");
      }

      rethrow;
    }
  }

  Future<void> _showWithdrawConfirmation(
      BuildContext context, ComplaintData complaint) async {
    if (complaint.status != 'In Progress') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Withdrawal is not possible for resolved complaints.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Withdraw Complaint'),
          content: const Text('Are you sure you want to withdraw this complaint? This action will automatically delete the complaint from your records.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Withdraw & Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed) {
      _deleteComplaint(complaint);
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, ComplaintData complaint) async {
    // Only allow deletion for withdrawn or resolved complaints
    if (complaint.status != 'Withdrawn' &&
        !complaint.status.toLowerCase().contains('resolved')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Only withdrawn or resolved complaints can be deleted.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Delete Complaint'),
          content: const Text('Are you sure you want to permanently delete this complaint? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed) {
      _deleteComplaint(complaint);
    }
  }

  Future<void> _withdrawComplaint(ComplaintData complaint) async {
    try {
      await _firestore.collection('complaints').doc(complaint.id).update({
        'status': 'Withdrawn',
        'withdrawnAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Complaint successfully withdrawn.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      setState(() {});
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to withdraw the complaint. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _deleteComplaint(ComplaintData complaint) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
          );
        },
      );

      // Delete the complaint document from Firestore
      await _firestore.collection('complaints').doc(complaint.id).delete();

      // Hide loading indicator
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Complaint successfully deleted.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Refresh the list
      setState(() {});
    } catch (error) {
      // Hide loading indicator
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to delete the complaint. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

// DEBUGGING VERSION OF ComplaintData
class ComplaintData {
  final String id;
  final String status;
  final String ticketNo;
  final String category;
  final String description;
  final String imageUrl;
  final String address;
  final String priority;
  final String severity;
  final String department;
  final DateTime createdAt;
  final String aiAnalysis;
  final List<String> aiSuggestions;
  final String estimatedResolutionTime;

  ComplaintData({
    required this.id,
    required this.status,
    required this.ticketNo,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.address,
    required this.priority,
    required this.severity,
    required this.department,
    required this.createdAt,
    required this.aiAnalysis,
    required this.aiSuggestions,
    required this.estimatedResolutionTime,
  });

  factory ComplaintData.fromFirestore(DocumentSnapshot doc) {
    try {
      if (!doc.exists) {
        throw Exception("Document does not exist");
      }

      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

      if (data == null) {
        throw Exception("Document data is null");
      }

      // Status
      String status = data['status']?.toString() ?? 'Unknown Status';

      // Ticket number (try multiple field names)
      String ticketNo = data['ticketNumber']?.toString() ??
          data['ticketNo']?.toString() ??
          data['ticket_number']?.toString() ??
          'Unknown Ticket No';

      // Category
      String category = data['category']?.toString() ?? 'Unknown Category';

      // Description
      String description = data['description']?.toString() ?? 'No description available';

      // Handle images more safely
      String imageUrl = 'https://via.placeholder.com/150';
      try {
        if (data['images'] != null) {
          if (data['images'] is List) {
            List imagesList = data['images'] as List;
            if (imagesList.isNotEmpty && imagesList[0] != null) {
              imageUrl = imagesList[0].toString();
            }
          } else if (data['images'] is String) {
            imageUrl = data['images'].toString();
          }
        }
      } catch (e) {
        // Use placeholder if images parsing fails
      }

      // Address
      String address = data['address']?.toString() ?? 'Address not provided';

      // Priority
      String priority = data['priority']?.toString() ?? 'Medium';

      // Severity
      String severity = data['severity']?.toString() ?? 'Medium';

      // Department
      String department = data['department']?.toString() ?? 'Unknown Department';

      // Handle createdAt more safely
      DateTime createdAt = DateTime.now();
      try {
        if (data['createdAt'] != null) {
          if (data['createdAt'] is Timestamp) {
            createdAt = (data['createdAt'] as Timestamp).toDate();
          } else if (data['createdAt'] is String) {
            createdAt = DateTime.parse(data['createdAt']);
          }
        }
      } catch (e) {
        // Use current time if createdAt parsing fails
      }

      // AI Analysis
      String aiAnalysis = data['aiAnalysis']?.toString() ?? '';

      // Handle aiSuggestions more safely
      List<String> aiSuggestions = [];
      try {
        if (data['aiSuggestions'] != null) {
          if (data['aiSuggestions'] is List) {
            List rawSuggestions = data['aiSuggestions'] as List;
            aiSuggestions = rawSuggestions
                .map((item) => item?.toString() ?? '')
                .where((item) => item.isNotEmpty)
                .toList();
          } else if (data['aiSuggestions'] is String) {
            // Handle case where aiSuggestions is a string (split by comma or period)
            String suggestionsString = data['aiSuggestions'].toString();
            aiSuggestions = suggestionsString
                .split(RegExp(r'[.,]'))
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
          }
        }
      } catch (e) {
        // Use empty list if aiSuggestions parsing fails
      }

      // Estimated Resolution Time
      String estimatedResolutionTime = data['estimatedResolutionTime']?.toString() ?? 'Not specified';

      return ComplaintData(
        id: doc.id,
        status: status,
        ticketNo: ticketNo,
        category: category,
        description: description,
        imageUrl: imageUrl,
        address: address,
        priority: priority,
        severity: severity,
        department: department,
        createdAt: createdAt,
        aiAnalysis: aiAnalysis,
        aiSuggestions: aiSuggestions,
        estimatedResolutionTime: estimatedResolutionTime,
      );

    } catch (e) {
      rethrow;
    }
  }
}

class ComplaintCard extends StatelessWidget {
  final ComplaintData complaint;
  final VoidCallback onWithdraw;
  final VoidCallback onDelete;
  final VoidCallback onTrack;

  const ComplaintCard({
    Key? key,
    required this.complaint,
    required this.onWithdraw,
    required this.onDelete,
    required this.onTrack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status and ticket number
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadge(),
                    Text(
                      '#${complaint.ticketNo.length > 8 ? complaint.ticketNo.substring(0, 8) : complaint.ticketNo}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Priority and Category
                Row(
                  children: [
                    _buildPriorityChip(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        complaint.category,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Department
                Text(
                  complaint.department,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Image and Description
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        complaint.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.broken_image,
                              size: 40,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  complaint.address,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date and Resolution Time
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(complaint.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    if (complaint.estimatedResolutionTime.isNotEmpty)
                      Text(
                        'ETA: ${complaint.estimatedResolutionTime}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.deepPurple[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    List<Widget> buttons = [];

    // For In Progress complaints: Withdraw and Track
    if (complaint.status == 'In Progress') {
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onWithdraw,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Withdraw'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      );
      buttons.add(const SizedBox(width: 8));
    }

    // For Withdrawn or Resolved complaints: Delete button
    if (complaint.status == 'Withdrawn' ||
        complaint.status.toLowerCase().contains('resolved')) {
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      );
      buttons.add(const SizedBox(width: 8));
    }

    // Track button for all complaints
    buttons.add(
      Expanded(
        child: ElevatedButton.icon(
          onPressed: onTrack,
          icon: const Icon(Icons.track_changes, size: 16),
          label: const Text('Track'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );

    return Row(children: buttons);
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (complaint.status.toLowerCase()) {
      case 'in progress':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        icon = Icons.timelapse;
        break;
      case 'resolved':
      case 'complaint resolved':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
        break;
      case 'withdrawn':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            complaint.status,
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

  Widget _buildPriorityChip() {
    Color backgroundColor;
    Color textColor;

    switch (complaint.priority.toLowerCase()) {
      case 'high':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        break;
      case 'medium':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        break;
      case 'low':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        complaint.priority,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}