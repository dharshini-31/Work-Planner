// ignore_for_file: use_super_parameters, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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

    String deadlineStr = 'No Deadline';
    if (task['deadline'] != null) {
      if (task['deadline'] is Timestamp) {
        deadlineStr = DateFormat.yMMMd().format((task['deadline'] as Timestamp).toDate());
      }
    }

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
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0, right: 8.0, top: 4.0, bottom: 4.0),
                    child: Text(
                      task['title'] ?? 'No Title',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.4),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
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
            FutureBuilder<DocumentSnapshot?>(
              future: (task['assignedByUid'] != null)
                  ? FirebaseFirestore.instance.collection('users').doc(task['assignedByUid']).get()
                  : null,
              builder: (context, snapshot) {
                String adminName = 'Loading...';
                String adminEmail = 'Loading...';
                
                if (snapshot.connectionState == ConnectionState.done) {
                  adminName = 'Admin'; // Fallback if no user is found
                  adminEmail = task['assignedByEmail'] ?? 'Unknown Email'; // Fallback to task payload
                  
                  if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data != null) {
                      String fullName = data['name'] ?? '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
                      if (fullName.isNotEmpty) {
                        adminName = fullName.split(' ').first; // Force First Name only
                      }
                      
                      // Prioritize the live Email pulled from the Admin's Database Profile
                      if (data['email'] != null && data['email'].toString().isNotEmpty) {
                        adminEmail = data['email'];
                      }
                    }
                  }
                }
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.support_agent_rounded, size: 16, color: Colors.blueAccent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assigned by : $adminName', 
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent)
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Email ID : $adminEmail', 
                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500)
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.mail_outline, size: 18, color: AppColors.textSecondary),
                    ],
                  ),
                );
              }
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.black12),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.flag, size: 16, color: task['priority'] == 'High' ? Colors.redAccent : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${task['priority'] ?? 'Normal'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: task['priority'] == 'High' ? Colors.redAccent : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.event, size: 16, color: Colors.blueAccent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          deadlineStr,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (status != 'Completed')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: status,
                        isDense: true,
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