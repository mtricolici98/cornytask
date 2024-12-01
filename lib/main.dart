import 'package:cornytask/plugins/flutter_notification_plugin.dart';
import 'package:cornytask/providers/notificaitons_provider.dart';
import 'package:cornytask/providers/user_provider.dart';
import 'package:cornytask/screens/login_screen.dart';
import 'package:cornytask/screens/main_screen.dart';
import 'package:cornytask/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'package:timezone/data/latest.dart' as tz;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final InitializationSettings initializationSettings =
  InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );

  tz.initializeTimeZones();

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  scheduleDailyNotification();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        Provider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'CornyTask',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Consumer<AuthService>(
          builder: (context, authService, _) {
            return authService.currentUser != null ? MyHomePage() : LoginScreen();
          },
        ),
      ),
    );
  }
}
