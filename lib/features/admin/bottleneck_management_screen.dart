// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBottleneckScreen extends StatelessWidget {
  const AdminBottleneckScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bottleneck Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Reported'),
              Tab(text: 'Pending'),
              Tab(text: 'Solved'),
            ],
          ),
        ),
        body: TabBarView(
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
          return Center(child: Text('No $status bottlenecks'));
        }

        return ListView.builder(
          itemCount: bottlenecks.length,
          itemBuilder: (context, index) {
            final doc = bottlenecks[index];
            final data = doc.data() as Map<String, dynamic>;
            final id = doc.id;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ExpansionTile(
                title: Text(data['taskTitle'] ?? 'Unknown Task'),
                subtitle: Text('Reported by: ${data['reportedByUid']}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(data['description'] ?? 'No description'),
                        const SizedBox(height: 10),
                        if (data['adminNotes'] != null && data['adminNotes'].isNotEmpty) ...[
                          Text('Admin Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(data['adminNotes']),
                          const SizedBox(height: 10),
                        ],
                        if (status != 'Solved')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _updateStatus(context, id, 'Pending'),
                                child: const Text('Mark Pending'),
                              ),
                              ElevatedButton(
                                onPressed: () => _solveContainer(context, id, data['adminNotes']),
                                child: const Text('Resolve'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
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
        title: const Text('Resolve Bottleneck'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: 'Corrective Action / Notes'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('bottlenecks').doc(id).update({
                'status': 'Solved',
                'adminNotes': noteController.text,
              });
              Navigator.pop(context);
            },
            child: const Text('Mark Solved'),
          ),
        ],
      ),
    );
  }
}
