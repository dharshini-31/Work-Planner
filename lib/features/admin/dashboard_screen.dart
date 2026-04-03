import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../ui_helpers.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const DashboardHeader(
            title: 'Admin Dashboard',
            subtitle: 'Overview,',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Platform Statistics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  _buildOverviewCards(),
                  const SizedBox(height: 32),
                  const Text('Task Status Distribution', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: _buildTaskStatusPieChart(),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Burn-Down Chart', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Row(
                        children: [
                          Container(width: 12, height: 2, color: Colors.grey),
                          const SizedBox(width: 4),
                          const Text('Ideal', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(width: 12),
                          Container(width: 12, height: 4, color: AppColors.primary),
                          const SizedBox(width: 4),
                          const Text('Actual', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: _buildBurnDownChart(),
                  ),
                  const SizedBox(height: 100), // spacing for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
      builder: (context, taskSnapshot) {
        if (!taskSnapshot.hasData) return const Center(child: CircularProgressIndicator());

        final tasks = taskSnapshot.data!.docs;
        final totalTasks = tasks.length;
        final int tasksCompleted = tasks.where((doc) => doc['status'] == 'Completed').length;
        final int inProgress = tasks.where((doc) => doc['status'] == 'In-Progress').length;
        final int pending = tasks.where((doc) => doc['status'] == 'To-Do').length;

        return LayoutBuilder(builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final bool isSmall = width < 600;
          final cardWidth = isSmall ? width : width / 2 - 8;
          
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard('Total Tasks', totalTasks.toString(), Colors.blue, Icons.assignment, width: cardWidth),
              _buildStatCard('Completed', tasksCompleted.toString(), Colors.green, Icons.check_circle, width: cardWidth),
              _buildStatCard('In-Progress', inProgress.toString(), Colors.orange, Icons.hourglass_bottom, width: cardWidth),
              _buildStatCard('Pending', pending.toString(), Colors.red, Icons.assignment_late, width: cardWidth),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, userSnapshot) {
                  int userCount = 0;
                  if (userSnapshot.hasData) {
                    final docs = userSnapshot.data!.docs;
                    userCount = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['role']?.toString().toLowerCase() != 'admin';
                    }).length;
                  }
                  return _buildStatCard('Active Users', userCount.toString(), Colors.purple, Icons.people, width: cardWidth);
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('bottlenecks').snapshots(),
                builder: (context, bottleSnapshot) {
                  final int bottleCount = bottleSnapshot.hasData ? bottleSnapshot.data!.docs.length : 0;
                  return _buildStatCard('Bottlenecks', bottleCount.toString(), Colors.deepOrange, Icons.warning_amber, width: cardWidth);
                },
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon, {double? width}) {
    return SizedBox(
      width: width,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
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

        if (tasks.isEmpty) return const Center(child: Text('No tasks created yet.', style: TextStyle(color: AppColors.textSecondary)));

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
                  color: Colors.redAccent,
                  value: todo.toDouble(),
                  title: '$todo',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
              sectionsSpace: 4,
              centerSpaceRadius: 40,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBurnDownChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }

        final tasks = snapshot.data!.docs;
        if (tasks.isEmpty) {
          return const SizedBox(height: 200, child: Center(child: Text('No tasks to map.', style: TextStyle(color: AppColors.textSecondary))));
        }

        int totalTasks = tasks.length;
        int completedTasks = tasks.where((t) => t['status'] == 'Completed').length;
        int openTasks = totalTasks - completedTasks;

        DateTime earliest = DateTime.now();
        for (var t in tasks) {
          final data = t.data() as Map<String, dynamic>;
          if (data['createdAt'] != null) {
            final dt = (data['createdAt'] as Timestamp).toDate();
            if (dt.isBefore(earliest)) earliest = dt;
          }
        }
        
        earliest = DateTime(earliest.year, earliest.month, earliest.day);

        List<String> xLabels = [];
        for (int i = 0; i < 7; i++) {
          final d = earliest.add(Duration(days: i));
          xLabels.add("${d.month}/${d.day}");
        }

        final daysPassed = DateTime.now().difference(earliest).inDays;
        double currentDayIndex = (daysPassed + 1).toDouble();
        if (currentDayIndex > 7) currentDayIndex = 7;
        if (currentDayIndex < 1) currentDayIndex = 1;

        double maxY = totalTasks.toDouble();
        if (maxY < 5) maxY = 5;

        return SizedBox(
          height: 220,
          width: double.infinity,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY / 5).ceilToDouble() == 0 ? 1 : (maxY / 5).ceilToDouble(),
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int idx = value.toInt() - 1;
                      if (idx >= 0 && idx < 7) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(xLabels[idx], style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                        );
                      }
                      return const SizedBox();
                    },
                    reservedSize: 30,
                    interval: 1,
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: const Padding(padding: EdgeInsets.only(bottom: 2.0), child: Text('Tasks', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value % 1 == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Text(value.toInt().toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                        );
                      }
                      return const SizedBox();
                    },
                    reservedSize: 32,
                    interval: (maxY / 5).ceilToDouble() == 0 ? 1 : (maxY / 5).ceilToDouble(),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 1,
              maxX: 7,
              minY: 0,
              maxY: maxY + 1,
              lineBarsData: [
                // Ideal Line
                LineChartBarData(
                  spots: [
                    FlSpot(1, totalTasks.toDouble()),
                    FlSpot(7, 0),
                  ],
                  isCurved: false,
                  color: Colors.grey.withOpacity(0.5),
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dashArray: [5, 5],
                  dotData: const FlDotData(show: false),
                ),
                // Actual Progress Line
                LineChartBarData(
                  spots: [
                    FlSpot(1, totalTasks.toDouble()),
                    if (currentDayIndex > 1) FlSpot(currentDayIndex, openTasks.toDouble()) else FlSpot(1, openTasks.toDouble()),
                  ],
                  isCurved: false,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: AppColors.primary,
                    ),
                  ),
                  belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.1)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
