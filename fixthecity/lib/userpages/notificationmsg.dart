import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Message2 extends StatefulWidget {
  const Message2({super.key});

  @override
  State<Message2> createState() => _Message2State();
}

class _Message2State extends State<Message2> {
  Map payload = {};
  @override
  Widget build(BuildContext context) {
    final data = ModalRoute.of(context)!.settings.arguments;
    // for background and terminated state
    if (data is RemoteMessage) {
      payload = data.data;
    }
    // for foreground state
    if (data is NotificationResponse) {
      payload = jsonDecode(data.payload!);
    }
    return Scaffold(
      appBar: AppBar(title: Text("Notification Details")),
      body: Center(
        child: Text(payload.toString()),
      ),
    );
  }
}