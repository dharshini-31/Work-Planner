import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class UserBottleneckPage extends StatefulWidget {
  const UserBottleneckPage({super.key});

  @override
  State<UserBottleneckPage> createState() => _UserBottleneckPageState();
}

class _UserBottleneckPageState extends State<UserBottleneckPage> {
  final uid = AuthService().currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const Center(child: Text('Not logged in'));

    return Scaffold(
      appBar: AppBar(title: const Text('My Bottlenecks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReportDialog(),
        label: const Text('Report Issue'),
        icon: const Icon(Icons.report_problem),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DatabaseService().getBottlenecks(reportedByUid: uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final bottlenecks = snapshot.data!;
          if (bottlenecks.isEmpty) return const Center(child: Text('No bottlenecks reported'));

          return ListView.builder(
            itemCount: bottlenecks.length,
            itemBuilder: (context, index) {
              final b = bottlenecks[index];
              return Card(
                child: ListTile(
                  title: Text(b['taskTitle'] ?? 'Unknown Task'),
                  subtitle: Text('Status: ${b['status']}\n${b['description']}'),
                  isThreeLine: true,
                  trailing: b['status'] == 'Solved' 
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.hourglass_empty, color: Colors.orange),
                ),
              );
            },
          );
        },
      ),
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
  const _ReportDialog({super.key, required this.uid});

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
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
