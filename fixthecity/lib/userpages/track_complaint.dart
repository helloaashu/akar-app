import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'complaint_history.dart';

class TrackComplaintPage extends StatefulWidget {
  final ComplaintData complaintData;
  final String ticketNumber;

  TrackComplaintPage({required this.complaintData, required this.ticketNumber});

  @override
  _TrackComplaintPageState createState() => _TrackComplaintPageState();
}

class _TrackComplaintPageState extends State<TrackComplaintPage>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _timelineAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _timelineAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _timelineAnimationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutQuart,
    );
    _timelineAnimation = CurvedAnimation(
      parent: _timelineAnimationController,
      curve: Curves.elasticOut,
    );

    _headerAnimationController.forward();
    Future.delayed(Duration(milliseconds: 300), () {
      _timelineAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _timelineAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade600,
              Colors.indigo.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAnimatedHeader(),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - _headerAnimation.value)),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Track Complaint',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.refresh, color: Colors.white),
                          onPressed: () => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  _buildStatusCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.indigo],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.confirmation_number,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ticket Number - Always show full number in smaller font
                    Text(
                      'Ticket #${widget.complaintData.ticketNo}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade800,
                        fontFamily: 'Courier', // Monospace font for ticket number
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    // Category
                    Text(
                      widget.complaintData.category,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 8),
                    // Status Badge on its own line
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildStatusBadge(widget.complaintData.status),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.deepPurple, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Filed on ${DateFormat('MMM dd, yyyy').format(widget.complaintData.createdAt)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // You can uncomment this if you want to show ETA
                // if (widget.complaintData.estimatedResolutionTime.isNotEmpty)
                //   Container(
                //     padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                //     decoration: BoxDecoration(
                //       color: Colors.orange[100],
                //       borderRadius: BorderRadius.circular(10),
                //     ),
                //     child: Text(
                //       'ETA: ${widget.complaintData.estimatedResolutionTime}',
                //       style: TextStyle(
                //         fontSize: 12,
                //         color: Colors.orange[800],
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),
          _buildComplaintDetails(),
          SizedBox(height: 30),
          _buildTimelineSection(),
          SizedBox(height: 30),
          if (widget.complaintData.aiAnalysis.isNotEmpty)
            _buildAIInsights(),
        ],
      ),
    );
  }

  Widget _buildComplaintDetails() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.info_outline, color: Colors.blue[700]),
              ),
              SizedBox(width: 15),
              Text(
                'Complaint Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildDetailItem(
            Icons.category_outlined,
            'Category',
            widget.complaintData.category,
            Colors.purple,
          ),
          _buildDetailItem(
            Icons.description_outlined,
            'Description',
            widget.complaintData.description,
            Colors.blue,
          ),
          _buildDetailItem(
            Icons.location_on_outlined,
            'Location',
            widget.complaintData.address,
            Colors.red,
          ),
          _buildDetailItem(
            Icons.business_outlined,
            'Department',
            widget.complaintData.department,
            Colors.green,
          ),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.priority_high_outlined,
                  'Priority',
                  widget.complaintData.priority,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: _buildDetailItem(
                  Icons.warning_outlined,
                  'Severity',
                  widget.complaintData.severity,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTimelineSection() {
    return AnimatedBuilder(
      animation: _timelineAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.5 + (0.5 * _timelineAnimation.value),
          child: Opacity(
            opacity: (_timelineAnimation.value).clamp(0.0, 1.0), // Fixed: Clamp the value
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.deepPurple, Colors.indigo],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(Icons.timeline, color: Colors.white),
                      ),
                      SizedBox(width: 15),
                      Text(
                        'Progress Timeline',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 25),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('complaints')
                        .doc(widget.complaintData.id)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingTimeline();
                      }
                      if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                        return _buildErrorTimeline();
                      }

                      var data = snapshot.data!.data() as Map<String, dynamic>;
                      return _buildTimeline(data);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeline(Map<String, dynamic> data) {
    String status = data['status'] ?? 'Unknown Status';
    String adminNotes = data['adminProgressNotes'] ?? '';
    DateTime createdAt = widget.complaintData.createdAt;

    List<TimelineStep> steps = [
      TimelineStep(
        title: 'Complaint Submitted',
        description: 'Your complaint has been successfully submitted and assigned a ticket number.',
        icon: Icons.file_present,
        isCompleted: true,
        completedAt: createdAt,
        color: Colors.green,
      ),
      TimelineStep(
        title: 'Under Review',
        description: adminNotes.isNotEmpty
            ? adminNotes
            : 'Your complaint is being reviewed by our team.',
        icon: Icons.rate_review,
        isCompleted: adminNotes.isNotEmpty || status != 'In Progress',
        completedAt: adminNotes.isNotEmpty ? createdAt.add(Duration(hours: 2)) : null,
        color: Colors.blue,
      ),
      TimelineStep(
        title: 'In Progress',
        description: 'Action is being taken to resolve your complaint.',
        icon: Icons.engineering,
        isCompleted: status != 'In Progress' && status != 'Under Review',
        completedAt: status != 'In Progress' ? createdAt.add(Duration(days: 1)) : null,
        color: Colors.orange,
      ),
      TimelineStep(
        title: 'Resolution',
        description: status.toLowerCase().contains('resolved')
            ? 'Your complaint has been successfully resolved.'
            : status == 'Withdrawn'
            ? 'Complaint has been withdrawn.'
            : 'Awaiting resolution.',
        icon: status.toLowerCase().contains('resolved')
            ? Icons.check_circle
            : status == 'Withdrawn'
            ? Icons.cancel
            : Icons.pending,
        isCompleted: status.toLowerCase().contains('resolved') || status == 'Withdrawn',
        completedAt: status.toLowerCase().contains('resolved') || status == 'Withdrawn'
            ? createdAt.add(Duration(days: 3))
            : null,
        color: status.toLowerCase().contains('resolved')
            ? Colors.green
            : status == 'Withdrawn'
            ? Colors.red
            : Colors.grey,
        isLast: true,
      ),
    ];

    return Column(
      children: steps.map((step) => _buildTimelineItem(step)).toList(),
    );
  }

  Widget _buildTimelineItem(TimelineStep step) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: step.isCompleted
                      ? LinearGradient(colors: [step.color, step.color.withOpacity(0.7)])
                      : LinearGradient(colors: [Colors.grey[300]!, Colors.grey[400]!]),
                  shape: BoxShape.circle,
                  boxShadow: step.isCompleted
                      ? [
                    BoxShadow(
                      color: step.color.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                      : [],
                ),
                child: Icon(
                  step.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              if (!step.isLast)
                Container(
                  width: 3,
                  height: 60,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: step.isCompleted
                        ? LinearGradient(
                      colors: [step.color, Colors.grey[300]!],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                        : LinearGradient(colors: [Colors.grey[300]!, Colors.grey[300]!]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
          SizedBox(width: 20),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(15),
              margin: EdgeInsets.only(bottom: step.isLast ? 0 : 20),
              decoration: BoxDecoration(
                color: step.isCompleted
                    ? step.color.withOpacity(0.05)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: step.isCompleted
                      ? step.color.withOpacity(0.2)
                      : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: step.isCompleted
                                ? step.color
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                      if (step.isCompleted && step.completedAt != null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: step.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            DateFormat('MMM dd, HH:mm').format(step.completedAt!),
                            style: TextStyle(
                              fontSize: 10,
                              color: step.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    step.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingTimeline() {
    return Column(
      children: List.generate(4, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildErrorTimeline() {
    return Container(
      padding: EdgeInsets.all(30),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red[300],
          ),
          SizedBox(height: 15),
          Text(
            'Unable to load timeline',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsights() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyan[50]!,
            Colors.blue[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyan[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.cyan, Colors.blue],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.psychology, color: Colors.white),
              ),
              SizedBox(width: 15),
              Text(
                'AI Insights',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Text(
            widget.complaintData.aiAnalysis,
            style: TextStyle(
              fontSize: 14,
              color: Colors.cyan[700],
              height: 1.5,
            ),
          ),
          if (widget.complaintData.aiSuggestions.isNotEmpty) ...[
            SizedBox(height: 15),
            Text(
              'Suggestions:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.cyan[800],
              ),
            ),
            SizedBox(height: 10),
            ...widget.complaintData.aiSuggestions.map((suggestion) {
              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.cyan[600],
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.cyan[700],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class TimelineStep {
  final String title;
  final String description;
  final IconData icon;
  final bool isCompleted;
  final DateTime? completedAt;
  final Color color;
  final bool isLast;

  TimelineStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.isCompleted,
    this.completedAt,
    required this.color,
    this.isLast = false,
  });
}