import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/local_db.dart';
import '../services/sync_service.dart';
import '../widgets/task_tile.dart';
import 'task_details_screen.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late Future<List<Task>> _future;
  bool _syncing = false;

  String get _uid => AuthService.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _future = LocalDb.instance.getAllTasks(_uid);
  }

  Future<void> _toggleDone(Task task) async {
    final updated = task.copyWith(
      isDone: !task.isDone,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await LocalDb.instance.upsertTask(updated);
    setState(_refresh);
  }

  Future<void> _delete(Task task) async {
    await LocalDb.instance.deleteTask(id: task.id, userId: _uid);
    setState(_refresh);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task deleted successfully.')),
    );
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    final res = await SyncService.instance.syncNow();
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (res.ok) {
      final details = <String>[];
      if (res.pushed > 0) details.add('${res.pushed} task(s) uploaded');
      if (res.pulled > 0) details.add('${res.pulled} task(s) downloaded');
      final suffix = details.isEmpty ? ' No changes were needed.' : ' ' + details.join(' and ') + '.';
      messenger.showSnackBar(
        SnackBar(content: Text('Synchronization completed successfully.' + suffix)),
      );
    } else {
      messenger.showSnackBar(SnackBar(content: Text(res.message)));
    }

    setState(() {
      _syncing = false;
      _refresh();
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to sign out now?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).clearSnackBars();
      await AuthService.instance.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            tooltip: 'Sync now',
            onPressed: _syncing ? null : _syncNow,
            icon: _syncing
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snap.data!;
          if (tasks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: const Icon(Icons.task_alt, size: 34),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No tasks yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap the + button to create your first task.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_refresh);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tasks.length,
              itemBuilder: (context, i) {
                final t = tasks[i];
                return Dismissible(
                  key: ValueKey(t.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: const Icon(Icons.delete),
                  ),
                  onDismissed: (_) => _delete(t),
                  child: TaskTile(
                    task: t,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TaskDetailsScreen(taskId: t.id)),
                      );
                      setState(_refresh);
                    },
                    onToggleDone: () => _toggleDone(t),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskFormScreen()));
          setState(_refresh);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}
