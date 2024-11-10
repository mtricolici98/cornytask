import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _todos = [];

  static const successEmojis = ["🎉", "🥂", "🤩"];
  static const sadEmojis = ["😬", "🥲", "🥺"];

  String getRandomEmoji(List<String> from){
    var random = Random();
    String randomItem = from[random.nextInt(from.length)];
    return randomItem;
  }

  @override
  void initState() {
    super.initState();
    _listenToTodos();
  }

  void _listenToTodos() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('todos')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      // Only update the list if there is a meaningful change
      setState(() {
        _todos = snapshot.docs;
      });
    });
  }

  Future<void> _updateTodoStatus(DocumentSnapshot todo, bool? isCompleted) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('todos')
        .doc(todo.id)
        .update({'isCompleted': isCompleted});

    int coins = todo['rewardCoins'];
    if (isCompleted == true) {
      Provider.of<UserProvider>(context, listen: false).addCoins(coins);
      var emoji = getRandomEmoji(successEmojis);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$emoji Task Complete! Rewarded $coins")));
    } else {
      Provider.of<UserProvider>(context, listen: false).spendCoins(coins);
      var emoji = getRandomEmoji(sadEmojis);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$emoji Task Undone! $coins taken back.")));
    }
  }

  Future<void> _deleteTodo(DocumentSnapshot todo) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('todos')
        .doc(todo.id)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Todo deleted.")));
  }

  Future<void> _resetTodo(DocumentSnapshot todo) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('todos')
        .doc(todo.id)
        .update({"isCompleted": false, 'createdAt': FieldValue.serverTimestamp(),});

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Todo reset.")));
  }

  void _confirmDelete(DocumentSnapshot todo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("What do you want to do?"),
          content: Text("You can choose to reset the TODO, marking it as unfinished but keeping your coins or delete it."),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Reset"),
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetTodo(todo);
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteTodo(todo);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _todos.isEmpty
        ? Center(child: Text("You have not created any TODOs yet."))
        : ListView.builder(
      itemCount: _todos.length,
      itemBuilder: (context, index) {
        var todo = _todos[index];
        return GestureDetector(
          onLongPress: () => _confirmDelete(todo), // Hold to delete
          child: ListTile(
            key: ValueKey(todo.id), // Unique key for each item
            trailing: Wrap(
              children: [
                Text(todo['rewardCoins'].toString()),
                Image.asset(
                  'assets/unicorn_small.png',
                  width: 24,
                  height: 24,
                ),
              ],
            ),
            title: Text(todo['title']),
            subtitle: Text(todo['description']),
            leading: Checkbox(
              value: todo['isCompleted'],
              onChanged: (value) async {
                await _updateTodoStatus(todo, value);
              },
            ),
          ),
        );
      },
    );
  }
}