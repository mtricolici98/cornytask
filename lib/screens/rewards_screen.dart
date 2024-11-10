import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';

class RewardsScreen extends StatefulWidget {
  @override
  _RewardsScreenState createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final _firestore = FirebaseFirestore.instance;

  // Track if the user is in the process of adding a new reward
  bool _isAdding = false;

  void showFestiveRewardPopup(BuildContext context, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green[100],
          title: const Text('🎉 Reward Redeemed! 🎉'),
          content: Text('Enjoy your $description!'),
          icon: const Icon(Icons.celebration, color: Colors.green),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK', style: TextStyle(color: Colors.green)),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }

  // Text controllers for the new reward's title and cost
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _costController = TextEditingController();


  Future<void> _deleteReward(DocumentSnapshot todo) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('rewards')
        .doc(todo.id)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Todo reset.")));
  }

  void _confirmDelete(DocumentSnapshot todo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Reward"),
          content: Text("Are you sure you want to delete this reward ?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteReward(todo);
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Reference the correct user's todos collection
      return Center(child: Text("Failed to load user"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users') // Access the users collection
          .doc(user.uid) // Get the current user's document by their UID
          .collection('rewards')
          .orderBy("cost", descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        final rewards = snapshot.data!.docs;
        return Scaffold(
          appBar: AppBar(
            title: Text("Rewards"),
          ),
          body: ListView(
            children: [
              // List of rewards from Firestore
              ...rewards.map((reward) {
                int currentCoins =
                    Provider.of<UserProvider>(context, listen: false).coins;
                int cost = reward['cost'] - currentCoins;
                var subtitle;
                if (cost > 0) {
                  subtitle =
                      Text("Cost: ${reward['cost']} unicorns. Need $cost");
                } else {
                  cost = cost * -1;
                  subtitle =
                      Text("Cost: ${reward['cost']} unicorns. $cost remaining");
                }
                return GestureDetector(
                    onLongPress: () => _confirmDelete(reward),
                    child: ListTile(
                      title: Text(reward['title']),
                      subtitle: subtitle,
                      trailing: ElevatedButton(
                        onPressed: () {
                          int currentCoins =
                              Provider.of<UserProvider>(context, listen: false)
                                  .coins;
                          if (currentCoins >= reward['cost']) {
                            Provider.of<UserProvider>(context, listen: false)
                                .spendCoins(reward['cost']);
                            showFestiveRewardPopup(context, reward['title']);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Not enough coins!")));
                          }
                        },
                        child: Text('Redeem'),
                      ),
                    ));
              }).toList(),

              // Add Reward Section
              if (_isAdding)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _costController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Cost (in unicorns)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _addReward,
                        child: Text('Add Reward'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isAdding = false; // Hide the input fields
                          });
                        },
                        child: Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              if (!_isAdding)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isAdding = true; // Show input fields to add a reward
                      });
                    },
                    child: Text('Add New Reward'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Function to add the new reward to Firestore
  Future<void> _addReward() async {
    final title = _titleController.text.trim();
    final cost = int.tryParse(_costController.text.trim());

    if (title.isEmpty || cost == null || cost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter a valid title and cost.")));
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users') // Access the users collection
          .doc(user.uid) // Get the current user's document by their UID
          .collection('rewards')
          .add({
        'title': title,
        'cost': cost,
        'timestamp': FieldValue.serverTimestamp(),
      });
      // Clear input fields after adding the reward
      _titleController.clear();
      _costController.clear();
      setState(() {
        _isAdding = false; // Hide the input fields after adding the reward
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to add reward: $e")));
    }
  }
}
