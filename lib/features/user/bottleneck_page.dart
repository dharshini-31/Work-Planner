import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../ui_helpers.dart';

class UserBottleneckPage extends StatefulWidget {
  const UserBottleneckPage({super.key});

  @override
  State<UserBottleneckPage> createState() => _UserBottleneckPageState();
}

class _UserBottleneckPageState extends State<UserBottleneckPage> {
  final uid = AuthService().currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const DashboardHeader(
            title: 'My Issues',
            subtitle: 'Report and review,',
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: DatabaseService().getBottlenecks(reportedByUid: uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final bottlenecks = snapshot.data!;
                if (bottlenecks.isEmpty) {
                  return const Center(child: Text('No bottlenecks reported', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 100),
                  itemCount: bottlenecks.length,
                  itemBuilder: (context, index) {
                    final b = bottlenecks[index];
                    final isSolved = b['status'] == 'Solved';
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (isSolved ? Colors.green : Colors.orangeAccent).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isSolved ? Icons.check_circle : Icons.hourglass_empty,
                                color: isSolved ? Colors.green : Colors.orangeAccent,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b['taskTitle'] ?? 'Unknown Task',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    b['description'] ?? '',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (isSolved ? Colors.green : Colors.orangeAccent).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      b['status'] ?? 'Pending',
                                      style: TextStyle(
                                        color: isSolved ? Colors.green : Colors.orangeAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (isSolved && b['adminNotes'] != null && b['adminNotes'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green.withOpacity(0.2)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Resolution Note:',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            b['adminNotes'],
                                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
            ),
          ),
        ],
      ),
      floatingActionButton: GradientButton(
        text: 'Report Issue',
        icon: Icons.report_problem,
        onPressed: () => _showReportDialog(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => _ReportDialog(uid: uid!),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  final String uid;
  const _ReportDialog({required this.uid});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String? _selectedTaskId;
  String? _selectedTaskTitle;
  final _descController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Bottleneck'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: DatabaseService().getTasks(assignedToUid: widget.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final tasks = snapshot.data!;
              if (tasks.isEmpty) return const Text('No tasks assigned to report on');

              return DropdownButtonFormField<String>(
                value: _selectedTaskId,
                hint: const Text('Select Task'),
                items: tasks.map((t) {
                  return DropdownMenuItem<String>(
                    value: t['id'],
                    child: Text(t['title'], overflow: TextOverflow.ellipsis),
                    onTap: () {
                      _selectedTaskTitle = t['title'];
                    },
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedTaskId = val;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Description of Issue'),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading || _selectedTaskId == null ? null : _submitReport,
          child: const Text('Report'),
        ),
      ],
    );
  }

  Future<void> _submitReport() async {
    setState(() => _isLoading = true);
    try {
      await DatabaseService().reportBottleneck(
        taskId: _selectedTaskId!,
        taskTitle: _selectedTaskTitle ?? 'Unknown',
        reportedByUid: widget.uid,
        description: _descController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bottleneck reported successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reporting bottleneck: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
