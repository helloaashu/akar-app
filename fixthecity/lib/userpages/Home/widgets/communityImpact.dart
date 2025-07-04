import 'package:flutter/material.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityImpactCard extends StatelessWidget {
  final double cardWidth;
  final String? feedbackCollectionPath;

  CommunityImpactCard(this.cardWidth, {this.feedbackCollectionPath = 'feedback'});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: feedbackCollectionPath != null
          ? FirebaseFirestore.instance.collection(feedbackCollectionPath!).snapshots()
          : null,
      builder: (context, snapshot) {
        if (feedbackCollectionPath == null) {
          return _buildErrorCard('Feedback collection path is not set');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard('Error: ${snapshot.error}');
        }

        final feedbacks = snapshot.data?.docs ?? [];
        final citizenCount = feedbacks.length;
        final highRatingCount = feedbacks.where((doc) => doc['rating'] == 5).length;
        final impactStatus = _getImpactStatus(citizenCount, highRatingCount);

        return _buildCard(citizenCount, impactStatus);
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: cardWidth,
      height: 200,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorCard(String errorMessage) {
    return Container(
      width: cardWidth,
      height: 200,
      child: Center(child: Text(errorMessage, textAlign: TextAlign.center)),
    );
  }

  Widget _buildCard(int citizenCount, String impactStatus) {
    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple.shade50, Colors.white],
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Community Impact',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_outline,
                  color: Colors.deepPurple,
                  size: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$citizenCount',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              Text(
                'Citizens',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.deepPurple.shade300,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          StepProgressIndicator(
            totalSteps: 500,
            currentStep: citizenCount,
            size: 8,
            padding: 0,
            selectedColor: Colors.deepPurple,
            unselectedColor: Colors.deepPurple.shade50,
            roundedEdges: Radius.circular(10),
            selectedGradientColor: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Benefited',
            style: TextStyle(
              fontSize: 12,
              color: Colors.deepPurple.shade300,
            ),
          ),
          SizedBox(height: 16),
          _buildImpactLabel(impactStatus),
        ],
      ),
    );
  }

  Widget _buildImpactLabel(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'Hot':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.local_fire_department;
        break;
      case 'Medium':
        backgroundColor = Colors.amber.shade100;
        textColor = Colors.amber.shade800;
        icon = Icons.trending_up;
        break;
      case 'Low':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.trending_flat;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        icon = Icons.info_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: textColor,
            size: 14,
          ),
          SizedBox(width: 8),
          Text(
            '$status Impact',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getImpactStatus(int citizenCount, int highRatingCount) {
    if (citizenCount > 5 && highRatingCount >= 5) {
      return 'Hot';
    } else if (citizenCount > 3 && highRatingCount >= 3) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }
}