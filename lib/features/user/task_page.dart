// ignore_for_file: use_super_parameters, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../ui_helpers.dart';

class UserTaskScreen extends StatelessWidget {
  const UserTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = AuthService().currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not Logged In')),
      );
    }

    final String uid = user.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const DashboardHeader(
            title: 'My Tasks',
            subtitle: 'Manage your workload,',
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: DatabaseService().getTasksServerFirst(assignedToUid: uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = snapshot.data ?? [];

                if (tasks.isEmpty) {
                  return const Center(child: Text('No tasks assigned', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 16, bottom: 100, left: 16, right: 16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return _TaskCard(task: tasks[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  const _TaskCard({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String status = task['status'] ?? 'To-Do';

    Color statusColor = Colors.grey;
    if (status == 'To-Do') statusColor = Colors.redAccent;
    if (status == 'In-Progress') statusColor = Colors.orangeAccent;
    if (status == 'Completed') statusColor = Colors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task['title'] ?? 'No Title',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task['description'] ?? 'No description',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.black12),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.flag, size: 16, color: task['priority'] == 'High' ? Colors.redAccent : Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${task['priority'] ?? 'Normal'}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: task['priority'] == 'High' ? Colors.redAccent : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (status != 'Completed')
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: status,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 13),
                        items: const [
                          DropdownMenuItem(value: 'To-Do', child: Text('To-Do')),
                          DropdownMenuItem(value: 'In-Progress', child: Text('In-Progress')),
                          DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                        ],
                        onChanged: (newStatus) async {
                          if (newStatus != null) {
                            await DatabaseService().updateTaskStatus(task['id'], newStatus);
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}