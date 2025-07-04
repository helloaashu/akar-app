import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class IssueType {
  final String type;
  int count;
  final Color color;

  IssueType(this.type, this.count, this.color);
}

class IssueTypeCard extends StatelessWidget {
  final double cardWidth;
  final String userId;

  const IssueTypeCard({Key? key, required this.cardWidth, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<IssueType>>(
      future: _fetchIssueTypeData(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        } else if (snapshot.hasError) {
          return _buildErrorCard();
        } else if (snapshot.hasData) {
          final data = snapshot.data!;
          return _buildIssueTypeContent(data);
        } else {
          return _buildErrorCard();
        }
      },
    );
  }

  Widget _buildIssueTypeContent(List<IssueType> data) {
    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Reported Issues',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pie_chart,
                  color: Colors.deepPurple,
                  size: 18,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: cardWidth * 0.08,
                      sections: data.map((issue) {
                        return PieChartSectionData(
                          color: issue.color,
                          value: issue.count.toDouble(),
                          title: '',
                          radius: cardWidth * 0.12,
                          borderSide: BorderSide(color: Colors.white, width: 1),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ListView(
                    children: data.map((issue) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: issue.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${issue.type}: ${issue.count}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<IssueType>> _fetchIssueTypeData(String userId) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot snapshot = await firestore
          .collection('complaints')
          .where('userID', isEqualTo: userId)
          .get();

      Map<String, int> issueCounts = {
        'Potholes': 0,
        'Road Collapse': 0,
        'Landslides': 0,
        'Other': 0,
      };

      for (var doc in snapshot.docs) {
        String complaintType = doc['category'] ?? 'Other';
        if (issueCounts.containsKey(complaintType)) {
          issueCounts[complaintType] = (issueCounts[complaintType] ?? 0) + 1;
        } else {
          issueCounts['Other'] = (issueCounts['Other'] ?? 0) + 1;
        }
      }

      return [
        IssueType('Potholes', issueCounts['Potholes'] ?? 0, Colors.red.shade400),
        IssueType('Traffic Lights', issueCounts['Traffic Lights'] ?? 0, Colors.green.shade400),
        IssueType('Road Signs', issueCounts['Road Signs'] ?? 0, Colors.blue.shade400),
        IssueType('Other', issueCounts['Other'] ?? 0, Colors.orange.shade400),
      ];
    } catch (e) {
      print('Error fetching issue type data: $e');
      throw e;
    }
  }

  Widget _buildLoadingCard() {
    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorCard() {
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
