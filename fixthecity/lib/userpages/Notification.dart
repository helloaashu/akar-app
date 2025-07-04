import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Message extends StatefulWidget {
  const Message({super.key});

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
  Map<String, dynamic> payload = {};

  @override
  Widget build(BuildContext context) {
    final data = ModalRoute.of(context)?.settings.arguments;

    // Handling the foreground and background/terminated state
    if (data is RemoteMessage) {
      payload = data.data;
    } else if (data is NotificationResponse) {
      payload = jsonDecode(data.payload!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Details'),
      ),
      body: payload.isEmpty
          ? _buildNoNotificationMessage()
          : _buildNotificationDetails(payload),
    );
  }

  // Widget to display when there are no notifications
  Widget _buildNoNotificationMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No notifications at the moment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Widget to display notification details
  Widget _buildNotificationDetails(Map<String, dynamic> messageData) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationSection('Title', messageData['title']),
          SizedBox(height: 16),
          _buildNotificationSection('Body', messageData['body']),
          SizedBox(height: 16),
          _buildNotificationSection('Data', messageData.toString()),
        ],
      ),
    );
  }

  // Helper widget to format each notification section
  Widget _buildNotificationSection(String label, String? content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content ?? 'N/A',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
