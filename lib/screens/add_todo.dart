import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTodoScreen extends StatefulWidget {
  @override
  _AddTodoScreenState createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _rewardController = TextEditingController();

  List _suggestedTodos = [];

  // Firestore reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to fetch titles from Firestore
  void _fetchSuggestedTitles(String query) async {
    // Query Firestore for existing to-do titles matching the input
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Reference the correct user's todos collection
      var snapshot = await FirebaseFirestore.instance
          .collection('users') // Access the users collection
          .doc(user.uid) // Get the current user's document by their UID
          .collection('todos') // Access the todos subcollection
          .where('keywords', arrayContains: query.toLowerCase()) // Case insensitive matching
          .limit(5) // Limit suggestions to 5
          .get();

      setState(() {
        _suggestedTodos =
            snapshot.docs.map((doc) => doc).toList();
      });
    }
  }

  // Function to save new to-do
  Future<void> _addTodo() async {
    if (_titleController.text.isEmpty || _rewardController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please provide a title and reward amount')));
      return;
    }
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Reference the correct user's todos collection
      CollectionReference todosCollection = FirebaseFirestore.instance
          .collection('users') // Access the users collection
          .doc(user.uid) // Get the current user's document by their UID
          .collection('todos'); // Access the todos subcollection
      await todosCollection.add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'isCompleted': false,
        'keywords': _titleController.text.split(' '),
        'rewardCoins': int.parse(_rewardController.text),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add To-do")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Title input with suggestions
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _fetchSuggestedTitles(value);
                } else {
                  setState(() {
                    _suggestedTodos = [];
                  });
                }
              },
            ),
            if (_suggestedTodos.isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                height: 100,
                child: ListView.builder(
                  itemCount: _suggestedTodos.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_suggestedTodos[index]["title"]),
                      onTap: () {
                        // Use suggested title
                        setState(() {
                          _titleController.text = _suggestedTodos[index]["title"];
                          _rewardController.text = _suggestedTodos[index]["rewardCoins"].toString();
                          _descriptionController.text = _suggestedTodos[index]["description"];
                          _suggestedTodos = [];
                        });
                      },
                    );
                  },
                ),
              ),
            ],
            SizedBox(height: 16),
            // Description input
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            // Reward input
            TextField(
              controller: _rewardController,
              decoration: InputDecoration(labelText: 'Reward in Unicorns'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 32),
            // Save button
            ElevatedButton(
              onPressed: _addTodo,
              child: Text('Add To-do'),
            ),
          ],
        ),
      ),
    );
  }
}
