import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;

    if (uid == null) return const Center(child: Text('Please log in'));

    return Scaffold(
      appBar: AppBar(title: const Text('My Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Task Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tasks')
                  .where('assignedToUid', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final tasks = snapshot.data!.docs;
                final total = tasks.length;
                final completed = tasks.where((doc) => doc['status'] == 'Completed').length;
                final progress = total == 0 ? 0.0 : completed / total;

                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 20,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 8),
                    Text('${(progress * 100).toInt()}% Completed'),
                    const SizedBox(height: 24),
                    _buildStatusSummary(tasks),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSummary(List<QueryDocumentSnapshot> tasks) {
    final todo = tasks.where((d) => d['status'] == 'To-Do').length;
    final inProgress = tasks.where((d) => d['status'] == 'In-Progress').length;
    final completed = tasks.where((d) => d['status'] == 'Completed').length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _summaryCard('To-Do', todo, Colors.red),
        _summaryCard('In-Progress', inProgress, Colors.orange),
        _summaryCard('Completed', completed, Colors.green),
      ],
    );
  }

  Widget _summaryCard(String title, int count, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
