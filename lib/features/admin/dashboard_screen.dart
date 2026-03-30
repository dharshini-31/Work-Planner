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
                  const Text('Burn-Down Chart (Demo)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
                  final int userCount = userSnapshot.hasData ? userSnapshot.data!.docs.length : 0;
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
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('D${value.toInt()}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
                reservedSize: 30,
                interval: 2,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                reservedSize: 30,
                interval: 2,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 7,
          minY: 0,
          maxY: 6,
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 4), FlSpot(2, 2), FlSpot(4, 5), FlSpot(6, 3.1), FlSpot(7, 4),
              ],
              isCurved: true,
              color: AppColors.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: AppColors.primary)),
              belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }
}
