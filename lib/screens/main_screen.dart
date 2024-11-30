import 'package:cornytask/screens/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import 'add_todo.dart';
import 'login_screen.dart';
import 'rewards_screen.dart';
import 'todo_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 2 tabs: Todos and Rewards
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      _showWelcomeDialog();
      await prefs.setBool('isFirstLaunch', false); // Set to false after showing the dialog
    }
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Welcome Tips'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Welcome to Corny Task"),
              Text("• Add todos and define your desired rewards"),
              Text("• Press and hold a todo item to choose additional actions"),
              Text("• Redeem rewards when you have enough unicorns"),
              Text("• Press and hold a reward to delete it"),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Got it!"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddTodo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTodoScreen(),
      ),
    );
  }

  void _navigateToRewards() {
    _tabController.animateTo(1); // Switch to Rewards tab (index 1)
  }

  void navigateToTab(int tabIdx) {
    _tabController.animateTo(tabIdx);
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<UserProvider>(context, listen: false).loadUserData();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Corny Task'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Todos'),
            Tab(icon: Icon(Icons.star), text: 'Rewards'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: _navigateToRewards,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ImageIcon(AssetImage('assets/unicorn_small.png')),
                const SizedBox(width: 8),
                Text(
                  Provider.of<UserProvider>(context, listen: true)
                      .coins
                      .toString(),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TodoScreen(),
          RewardsScreen(),
          HistoryScreen()
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return _tabController.index == 0 // Show button only on Todos tab
              ? FloatingActionButton(
            onPressed: _navigateToAddTodo,
            child: Icon(Icons.add),
            tooltip: 'Add Todo',
          )
              : SizedBox.shrink(); // Hide button on other tabs
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
