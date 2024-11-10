import 'package:cornytask/providers/user_provider.dart';
import 'package:cornytask/screens/login_screen.dart';
import 'package:cornytask/screens/main_screen.dart';
import 'package:cornytask/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
