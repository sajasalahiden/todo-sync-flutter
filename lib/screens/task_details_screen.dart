import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/local_db.dart';
import 'task_form_screen.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  Future<Task?>? _future;

  String get _uid => AuthService.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = LocalDb.instance.getTaskById(id: widget.taskId, userId: _uid);
  }

  Future<void> _delete(Task task) async {
    await LocalDb.instance.deleteTask(id: task.id, userId: _uid);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _toggleDone(Task task) async {
    final updated = task.copyWith(
      isDone: !task.isDone,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await LocalDb.instance.upsertTask(updated);
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TaskFormScreen(taskId: widget.taskId)),
              );
              setState(_reload);
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: FutureBuilder<Task?>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final task = snap.data;
          if (task == null) {
            return const Center(child: Text('Task not found.'));
          }

          final dueText = task.dueDate == null
              ? 'No due date'
              : DateFormat('y-MM-dd').format(task.dueDate!);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(task.isDone ? Icons.check_circle : Icons.radio_button_unchecked),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(task.description),
                const SizedBox(height: 12),
                Text('Due: $dueText'),
                const SizedBox(height: 8),
                Text('Last updated: ${DateFormat('y-MM-dd HH:mm').format(task.updatedAt)}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Sync status: '),
                    Icon(task.isSynced ? Icons.cloud_done : Icons.cloud_off),
                    const SizedBox(width: 8),
                    Text(task.isSynced ? 'Synced' : 'Pending'),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleDone(task),
                        icon: const Icon(Icons.check),
                        label: Text(task.isDone ? 'Mark as not done' : 'Mark as done'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _delete(task),
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
