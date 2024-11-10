import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'main_screen.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/unicorn_logo.png'),
            Spacer(),
            Text(
              "Welcome to Corny Tasks",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 32,
                  fontWeight: FontWeight.bold),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () async {
                // Attempt Google sign-in
                User? user;
                try {
                  user = await Provider.of<AuthService>(context, listen: false)
                      .signInWithGoogle();
                } catch (exception) {
                  user = null;
                }
                if (user != null) {
                  // User signed in successfully, navigate to main screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MyHomePage()),
                  );
                } else {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Log in failed!")));
                }
              },
              child: Text('Sign in with Google'),
            ),
            Spacer()
          ],
        ),
      ),
    );
  }
}
