import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:shimmer/shimmer.dart';
import 'IssueTypewidget.dart';
import 'package:fixthecity/userpages/complaint_history.dart';

import 'communityImpact.dart';
import 'modeltest.dart';

class RoadIssuesDashboard extends StatefulWidget {
  final String userID;

  const RoadIssuesDashboard({Key? key, required this.userID}) : super(key: key);

  @override
  State<RoadIssuesDashboard> createState() => _RoadIssuesDashboardState();
}

class _RoadIssuesDashboardState extends State<RoadIssuesDashboard> {
  late Future<Map<String, int>> _complaintDataFuture;
  String selectedCategory = 'Insights & Stats';




  @override
  void initState() {
    super.initState();
    _complaintDataFuture = _fetchComplaintData();
  }


  Future<Map<String, int>> _fetchComplaintData() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Get total complaints for the user
      QuerySnapshot totalSnapshot = await firestore
          .collection('complaints')
          .where('userID', isEqualTo: widget.userID)
          .get();

      // Get resolved complaints for the user
      QuerySnapshot resolvedSnapshot = await firestore
          .collection('complaints')
          .where('userID', isEqualTo: widget.userID)
          .where('status', isEqualTo: 'Complaint Resolved')
          .get();

      QuerySnapshot inProgressSnapshot = await firestore
          .collection('complaints')
          .where('userID', isEqualTo: widget.userID)
          .where('status', isEqualTo: 'In Progress')
          .get();

      return {
        'total': totalSnapshot.size,
        'resolved': resolvedSnapshot.size,
        'inProgress': inProgressSnapshot.size,
      };
    } catch (e) {
      print('Error fetching complaint data: $e');
      // In case of error, return default values or rethrow the error
      // Returning default values here, but you might want to handle this differently
      return {
        'total': 0,
        'resolved': 0,
        'inProgress': 0,
      };
    }
  }
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _buildCategorySelector(),
              SizedBox(height: 16),
              _buildIssuesGrid(constraints),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategorySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _categoryButton('Insights & Stats'),
          SizedBox(width:10),
          _categoryButton('Complaint History'),
          SizedBox(width:10),
          _categoryButton('Trending',),
          SizedBox(width:10),
          //_categoryButton('News',),
        ],
      ),
    );
  }

  Widget _categoryButton(String category) {
    bool isSelected = selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
        _handleCategorySelection(category);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _handleCategorySelection(String category) {
    // Trigger different actions based on the selected category
    switch (category) {
      case 'Insights & Stats':
      // Fetch or display insights and stats
        break;
      case 'Complaint History':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ComplaintHistory(
              onPageChanged: (int pageIndex) {
                // Handle page change actions if needed
              }, userID: '',
            ),
          ),
        );
        break;
      case 'Trending':
      // Fetch or display trending issues
        break;
      case 'News':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewsPage()),
        );

      // Fetch or display news
        break;
    }
  }


  Widget _buildIssuesGrid(BoxConstraints constraints) {
    double cardWidth = constraints.maxWidth * 0.6; // Adjust the width as needed

    return SizedBox(
      height: cardWidth * 1.1, // Maintain a reasonable height for the cards
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildResolvedIssuesCard(cardWidth),
          _buildIssueStatusCard(cardWidth),
          IssueTypeCard(cardWidth: cardWidth, userId: widget.userID),

          CommunityImpactCard(cardWidth,feedbackCollectionPath: 'feedback'),
          // Add more cards if needed...
        ],
      ),
    );
  }

  Widget _buildResolvedIssuesCard(double cardWidth) {
    return FutureBuilder<Map<String, int>>(
      future: _complaintDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(cardWidth);
        } else if (snapshot.hasError) {
          return _buildErrorCard(cardWidth);
        } else if (snapshot.hasData) {
          final data = snapshot.data!;
          final total = data['total'] ?? 0;
          final resolved = data['resolved'] ?? 0;
          final successRate = total > 0 ? (resolved / total * 100).round() : 0;

          return Container(
            width: cardWidth,
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Resolved Issues',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: CircularStepProgressIndicator(
                      totalSteps: total > 0 ? total : 1,
                      currentStep: resolved,
                      stepSize: 10,
                      selectedColor: Colors.white,
                      unselectedColor: Colors.white.withOpacity(0.2),
                      padding: 0,
                      width: 100,
                      height: 100,
                      selectedStepSize: 14,
                      roundedCap: (_, __) => true,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$resolved',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Solved',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$successRate% Success',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else {
          return _buildErrorCard(cardWidth);
        }
      },
    );
  }

  Widget _buildLoadingCard(double cardWidth) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: cardWidth,
        margin: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }


  Widget _buildIssueStatusCard(double cardWidth) {
    return FutureBuilder<Map<String, int>>(
      future: _complaintDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerCard(cardWidth);
        } else if (snapshot.hasError) {
          return _buildErrorCard(cardWidth);
        } else if (snapshot.hasData) {
          final data = snapshot.data!;
          final totalIssues = data['total'] ?? 0;
          final inProgressIssues = data['inProgress'] ?? 0;

          return Container(
            width: cardWidth,
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'In Progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.timelapse,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: CircularStepProgressIndicator(
                      totalSteps: totalIssues > 0 ? totalIssues : 1,
                      currentStep: inProgressIssues,
                      stepSize: 10,
                      selectedColor: Colors.white,
                      unselectedColor: Colors.white.withOpacity(0.2),
                      padding: 0,
                      width: 100,
                      height: 100,
                      selectedStepSize: 14,
                      roundedCap: (_, __) => true,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$inProgressIssues',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'of $totalIssues',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$totalIssues Total Issues',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else {
          return _buildErrorCard(cardWidth);
        }
      },
    );
  }

  Widget _buildShimmerCard(double cardWidth) {
    return Shimmer.fromColors(
      baseColor: Colors.purple[300]!,
      highlightColor: Colors.purple[100]!,
      child: Container(
        width: cardWidth,
        margin: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(double cardWidth) {
    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(child: Text('Error loading data')),
    );
  }




}


