import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(),
            const SizedBox(height: 24),
            const Text(
              'Task Status Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTaskStatusPieChart(),
            const SizedBox(height: 24),
            const Text(
              'Burn-Down Chart (Demo)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBurnDownChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
      builder: (context, taskSnapshot) {
        if (!taskSnapshot.hasData) return const LinearProgressIndicator();

        final tasks = taskSnapshot.data!.docs;
        final totalTasks = tasks.length;
        final int tasksCompleted = tasks.where((doc) => doc['status'] == 'Completed').length;
        final int inProgress = tasks.where((doc) => doc['status'] == 'In-Progress').length;
        final int pending = tasks.where((doc) => doc['status'] == 'To-Do').length;

        return LayoutBuilder(builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final bool isSmall = width < 600;
          
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard('Total Tasks', totalTasks.toString(), Colors.blue, width: isSmall ? width : width / 2 - 24),
              _buildStatCard('Completed', tasksCompleted.toString(), Colors.green, width: isSmall ? width : width / 2 - 24),
              _buildStatCard('In-Progress', inProgress.toString(), Colors.orange, width: isSmall ? width : width / 2 - 24),
              _buildStatCard('Pending', pending.toString(), Colors.red, width: isSmall ? width : width / 2 - 24),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, userSnapshot) {
                  final int userCount = userSnapshot.hasData ? userSnapshot.data!.docs.length : 0;
                  return _buildStatCard('Active Users', userCount.toString(), Colors.purple, width: isSmall ? width : width / 2 - 24);
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('bottlenecks').snapshots(),
                builder: (context, bottleSnapshot) {
                  final int bottleCount = bottleSnapshot.hasData ? bottleSnapshot.data!.docs.length : 0;
                  return _buildStatCard('Bottlenecks', bottleCount.toString(), Colors.deepOrange, width: isSmall ? width : width / 2 - 24);
                },
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color, {double? width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTaskStatusPieChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));

        final tasks = snapshot.data!.docs;
        final completed = tasks.where((doc) => doc['status'] == 'Completed').length;
        final inProgress = tasks.where((doc) => doc['status'] == 'In-Progress').length;
        final todo = tasks.where((doc) => doc['status'] == 'To-Do').length;

        if (tasks.isEmpty) return const Text('No tasks created yet.');

        return SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  color: Colors.green,
                  value: completed.toDouble(),
                  title: '$completed',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: Colors.orange,
                  value: inProgress.toDouble(),
                  title: '$inProgress',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: Colors.red,
                  value: todo.toDouble(),
                  title: '$todo',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBurnDownChart() {
    // Implementing a true burn-down chart requires historical data which we don't store in this simple schema.
    // Instead, I'll show a placeholder chart with some dummy data to represent the UI.
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
          minX: 0,
          maxX: 7,
          minY: 0,
          maxY: 6,
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 4),
                FlSpot(2.6, 2),
                FlSpot(4.9, 5),
                FlSpot(6.8, 3.1),
                FlSpot(8, 4),
                FlSpot(9.5, 3),
                FlSpot(11, 4),
              ],
              isCurved: true,
              color: Colors.blue,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
