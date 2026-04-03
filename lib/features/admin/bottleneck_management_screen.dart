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
        body: Column(
          children: [
            const DashboardHeader(
              title: 'Bottleneck Management',
              subtitle: 'Track and resolve ongoing issues',
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                ),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                tabs: const [
                  Tab(text: 'Reported'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Solved'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: TabBarView(
                children: [
                  _BottleneckList(status: 'Reported'),
                  _BottleneckList(status: 'Pending'),
                  _BottleneckList(status: 'Solved'),
                ],
              ),
            ),
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

            final String reportedByUid = data['reportedByUid'] ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: FutureBuilder<DocumentSnapshot>(
                  future: reportedByUid.isNotEmpty 
                      ? FirebaseFirestore.instance.collection('users').doc(reportedByUid).get() 
                      : null,
                  builder: (context, userSnap) {
                    String reporterName = 'Loading...';
                    if (reportedByUid.isEmpty) {
                      reporterName = 'Unknown';
                    } else if (userSnap.connectionState == ConnectionState.done) {
                      if (userSnap.hasData && userSnap.data != null && userSnap.data!.exists) {
                        final uData = userSnap.data!.data() as Map<String, dynamic>?;
                        if (uData != null) {
                          reporterName = uData['name']?.toString().trim() ?? '';
                          if (reporterName.isEmpty) {
                            reporterName = '${uData['firstName'] ?? ''} ${uData['lastName'] ?? ''}'.trim();
                          }
                          if (reporterName.isEmpty) reporterName = 'Unknown User';
                        } else {
                          reporterName = 'Unknown User';
                        }
                      } else {
                        reporterName = 'Unknown User';
                      }
                    } else if (userSnap.hasError) {
                      reporterName = 'Error';
                    }

                    return ExpansionTile(
                      collapsedIconColor: AppColors.primary,
                      iconColor: AppColors.primary,
                      title: Text(data['taskTitle'] ?? 'Unknown Task', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      subtitle: Text('Reported by: $reporterName', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                );
              }
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
