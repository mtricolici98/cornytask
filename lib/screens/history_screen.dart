import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _history = [];
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _listen_to_history();
  }

  void _listen_to_history() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _history = snapshot.docs;
      });
    });
  }

  List<Map<String, dynamic>> _getFilteredHistory() {
    // Filter by selected month
    return _history
        .map((doc) => doc.data() as Map<String, dynamic>)
        .where((item) {
      final createdAt = (item['createdAt'] as Timestamp).toDate();
      return createdAt.year == _selectedMonth.year &&
          createdAt.month == _selectedMonth.month;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> _groupHistoryByDate(
      List<Map<String, dynamic>> history) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (var item in history) {
      final createdAt = (item['createdAt'] as Timestamp).toDate();
      final dateKey = DateFormat('EEE, dd/MM/yyyy').format(createdAt);

      if (grouped[dateKey] == null) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(item);
    }

    return grouped;
  }

  List<BarChartGroupData> _generateGraphData(
      List<Map<String, dynamic>> history) {
    // Aggregate data for the graph
    final dailyTotals = <DateTime, int>{};

    for (var item in history) {
      final createdAt = (item['createdAt'] as Timestamp).toDate();
      final dateKey = DateTime(createdAt.year, createdAt.month, createdAt.day);
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) +
          int.parse(item['rewardCoins'].toString());
    }

    return dailyTotals.entries
        .map((entry) => BarChartGroupData(
              x: entry.key.day,
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: Colors.blue,
                ),
              ],
            ))
        .toList();
  }

  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + increment,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = _getFilteredHistory();
    final groupedHistory = _groupHistoryByDate(filteredHistory);
    final graphData = _generateGraphData(filteredHistory);

    return Scaffold(
      body: Column(
        children: [
          // Grouped List
          Expanded(
            child: ListView(
              children: groupedHistory.entries.map((entry) {
                final date = entry.key;
                final items = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        date,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...items.map((item) {
                      return ListTile(
                        leading: Checkbox(
                          value: true,
                          onChanged: (b) => {},
                        ),
                        title: Text(item['title']),
                        trailing: Wrap(
                          children: [
                            Text(item['rewardCoins'].toString()),
                            Image.asset(
                              'assets/unicorn_small.png',
                              width: 24,
                              height: 24,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    Divider(),
                  ],
                );
              }).toList(),
            ),
          ),
          Divider(),
          // Month Selector and Graph
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth),
                  style: const TextStyle(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: graphData,
                titlesData: FlTitlesData(
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        return Text('${value.toInt()}');
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
