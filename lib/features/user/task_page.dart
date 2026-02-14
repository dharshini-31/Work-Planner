// ignore_for_file: use_super_parameters, deprecated_member_use

import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class UserTaskScreen extends StatelessWidget {
  const UserTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not Logged In'));

    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DatabaseService().getTasks(assignedToUid: uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) return const Center(child: Text('No tasks assigned'));

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _TaskCard(task: task);
            },
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  const _TaskCard({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = task['status'];
    Color statusColor = Colors.grey;
    if (status == 'To-Do') statusColor = Colors.red;
    if (status == 'In-Progress') statusColor = Colors.orange;
    if (status == 'Completed') statusColor = Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(task['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(task['description'] ?? 'No description'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Priority: ${task['priority']}', style: TextStyle(color: task['priority'] == 'High' ? Colors.red : Colors.black)),
                // Status Update Buttons
                if (status != 'Completed')
                  DropdownButton<String>(
                    value: status,
                    items: ['To-Do', 'In-Progress', 'Completed'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (newStatus) {
                      if (newStatus != null) {
                        DatabaseService().updateTaskStatus(task['id'], newStatus);
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
