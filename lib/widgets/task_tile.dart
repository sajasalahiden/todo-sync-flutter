import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;

  const TaskTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggleDone,
  });

  @override
  Widget build(BuildContext context) {
    final dueText = task.dueDate == null
        ? 'No due date'
        : DateFormat('y-MM-dd').format(task.dueDate!);

    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$dueText • Updated ${DateFormat('y-MM-dd HH:mm').format(task.updatedAt)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          onPressed: onToggleDone,
          icon: Icon(task.isDone ? Icons.check_circle : Icons.radio_button_unchecked),
        ),
        trailing: Icon(
          task.isSynced ? Icons.cloud_done : Icons.cloud_off,
        ),
      ),
    );
  }
}
