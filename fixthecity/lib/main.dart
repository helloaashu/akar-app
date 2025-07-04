
import 'dart:async';
import 'dart:convert';
import 'package:fixthecity/Screens/splash.dart';
import 'package:fixthecity/admin/admin_login.dart';
import 'package:fixthecity/userpages/controllerpage.dart';
import 'package:fixthecity/userpages/notificationmsg.dart';
import 'package:fixthecity/userpages/notification_service.dart';
import 'package:fixthecity/userpages/userProfile/Identification.dart';
import 'package:fixthecity/userpages/userProfile/profileDetails.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'Screens/home.dart';
import 'Screens/login.dart';
import 'Screens/register.dart';
import 'Screens/recover.dart';



 final navigatorKey = GlobalKey<NavigatorState>();


 //function to listen to bg chnages
Future bgMessage(RemoteMessage message)async{
  await Firebase.initializeApp();

  if(message.notification!=null) {
    print("Received in background..");
  }


}




Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: dotenv.env['API_KEY']!,
        appId: dotenv.env['APP_ID']!,
        messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
        projectId: dotenv.env['PROJECT_ID']!,
        storageBucket: dotenv.env['STORAGE_BUCKET']!),
  );



  // await PushNotifications.init();
  await PushNotifications.localNotiInit();

  FirebaseMessaging.onBackgroundMessage(bgMessage);

//on bg notification tapped
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message){
    if(message.notification!=null){
      print("bg tapped...");
      navigatorKey.currentState!.pushNamed("/message",arguments: message);

    }
  });

  //to handle foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    String payloadData = jsonEncode(message.data);
    print("Got a message in foreground");
    if (message.notification != null) {
        PushNotifications.showSimpleNotification(
            title: message.notification!.title!,
            body: message.notification!.body!,
            payload: payloadData);
      }

  });

  //
  // for handling in terminated state
  @pragma("vm:entry-point")
  final RemoteMessage? message =
  await FirebaseMessaging.instance.getInitialMessage();

  if (message != null) {
    print("Launched from terminated state");
    Future.delayed(Duration(seconds: 1), () {
      navigatorKey.currentState!.pushNamed("/message", arguments: message);
    });
  }


  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      routes: {
        "/": (context) => MySplash(),
        "/message":(context)=> Message2(),
        "/register": (context) => const RegistrationPage(),
        "/login": (context) => const SignInPage(),
        "/recover": (context) => const RecoverPage(),
        "/UserPages": (context) => const MyCont(),
        '/profile-details': (context) => const ProfileDetailsPage(),
        '/upload-gov-id': (context) => const UploadId(),

        "/home": (context) => const MyHome(),

        "/admin": (context) => const AdminLogin(),

      },
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',

      //home: MyHome(),
    );
  }
}

