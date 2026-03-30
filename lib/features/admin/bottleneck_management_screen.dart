// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../ui_helpers.dart';

class AdminBottleneckScreen extends StatelessWidget {
  const AdminBottleneckScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('Bottleneck Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Reported'),
              Tab(text: 'Pending'),
              Tab(text: 'Solved'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BottleneckList(status: 'Reported'),
            _BottleneckList(status: 'Pending'),
            _BottleneckList(status: 'Solved'),
          ],
        ),
      ),
    );
  }
}

class _BottleneckList extends StatelessWidget {
  final String status;
  const _BottleneckList({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bottlenecks')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final bottlenecks = snapshot.data!.docs;

        if (bottlenecks.isEmpty) {
          return Center(child: Text('No $status bottlenecks', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 100),
          itemCount: bottlenecks.length,
          itemBuilder: (context, index) {
            final doc = bottlenecks[index];
            final data = doc.data() as Map<String, dynamic>;
            final id = doc.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  collapsedIconColor: AppColors.primary,
                  iconColor: AppColors.primary,
                  title: Text(data['taskTitle'] ?? 'Unknown Task', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  subtitle: Text('Reported by: ${data['reportedByUid']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(data['description'] ?? 'No description', style: const TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          if (data['adminNotes'] != null && data['adminNotes'].isNotEmpty) ...[
                            const Text('Admin Notes:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text(data['adminNotes'], style: const TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                          ],
                          if (status != 'Solved')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _updateStatus(context, id, 'Pending'),
                                  child: const Text('Mark Pending', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  onPressed: () => _solveContainer(context, id, data['adminNotes']),
                                  child: const Text('Resolve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _updateStatus(BuildContext context, String id, String newStatus) {
    FirebaseFirestore.instance.collection('bottlenecks').doc(id).update({'status': newStatus});
  }

  void _solveContainer(BuildContext context, String id, String? currentNotes) {
    final noteController = TextEditingController(text: currentNotes);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Bottleneck', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: 'Corrective Action / Notes'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              FirebaseFirestore.instance.collection('bottlenecks').doc(id).update({
                'status': 'Solved',
                'adminNotes': noteController.text,
              });
              Navigator.pop(context);
            },
            child: const Text('Mark Solved', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
