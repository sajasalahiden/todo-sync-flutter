import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/local_db.dart';

class TaskFormScreen extends StatefulWidget {
  final String? taskId;
  const TaskFormScreen({super.key, this.taskId});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  String get _uid => AuthService.instance.currentUser!.uid;
  final _formKey = GlobalKey<FormState>();
  final _titleC = TextEditingController();
  final _descC = TextEditingController();
  DateTime? _due;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.taskId == null) {
      setState(() => _loading = false);
      return;
    }
    final task = await LocalDb.instance.getTaskById(id: widget.taskId!, userId: _uid);
    if (task != null) {
      _titleC.text = task.title;
      _descC.text = task.description;
      _due = task.dueDate;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _due ?? now,
    );
    if (picked != null) {
      setState(() => _due = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final id = widget.taskId ?? const Uuid().v4();

    final task = Task(
      id: id,
      userId: _uid,
      title: _titleC.text.trim(),
      description: _descC.text.trim(),
      dueDate: _due,
      isDone: false,
      updatedAt: now,
      isSynced: false,
    );

    final old = await LocalDb.instance.getTaskById(id: id, userId: _uid);
    final finalTask = old == null ? task : task.copyWith(isDone: old.isDone);

    await LocalDb.instance.upsertTask(finalTask);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.taskId == null ? 'Task added successfully.' : 'Task updated successfully.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dueText = _due == null ? 'No due date selected' : DateFormat('y-MM-dd').format(_due!);
    final isEditing = widget.taskId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Task' : 'Add Task')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.18),
                            Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            child: Icon(Icons.edit_note),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? 'Update your task' : 'Create a new task',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                const Text('Add a title, a clear description, and an optional due date.'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleC,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(Icons.title),
                        hintText: 'Example: Prepare presentation',
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Title is required.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descC,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.notes),
                        alignLabelWithHint: true,
                        hintText: 'Write the task details here...',
                      ),
                      maxLines: 4,
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Description is required.' : null,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event_available),
                                const SizedBox(width: 8),
                                Expanded(child: Text('Due date', style: Theme.of(context).textTheme.titleSmall)),
                                if (_due != null)
                                  TextButton(
                                    onPressed: () => setState(() => _due = null),
                                    child: const Text('Clear'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(dueText),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ActionChip(
                                  avatar: const Icon(Icons.today, size: 18),
                                  label: const Text('Pick Date'),
                                  onPressed: _pickDue,
                                ),
                                ActionChip(
                                  avatar: const Icon(Icons.calendar_view_week, size: 18),
                                  label: const Text('Tomorrow'),
                                  onPressed: () {
                                    final t = DateTime.now().add(const Duration(days: 1));
                                    setState(() => _due = DateTime(t.year, t.month, t.day));
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: Text(isEditing ? 'Save Changes' : 'Save Task'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
