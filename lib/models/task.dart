class Task {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime? dueDate;
  final bool isDone;
  final DateTime updatedAt;
  final bool isSynced;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.isDone,
    required this.updatedAt,
    required this.isSynced,
  });

  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isDone,
    DateTime? updatedAt,
    bool? isSynced,
    bool clearDueDate = false,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isDone: isDone ?? this.isDone,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'isDone': isDone ? 1 : 0,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  static Task fromDbMap(Map<String, dynamic> map) {
    final due = map['dueDate'] as int?;
    return Task(
      id: map['id'] as String,
      userId: (map['userId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      dueDate: due == null ? null : DateTime.fromMillisecondsSinceEpoch(due),
      isDone: (map['isDone'] as int? ?? 0) == 1,
      updatedAt: DateTime.fromMillisecondsSinceEpoch((map['updatedAt'] as int?) ?? 0),
      isSynced: (map['isSynced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toCloudMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'isDone': isDone,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  static Task fromCloudMap(Map<String, dynamic> map) {
    final due = map['dueDate'] as int?;
    final updated = map['updatedAt'] as int?;
    return Task(
      id: (map['id'] as String?) ?? '',
      userId: (map['userId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      dueDate: due == null ? null : DateTime.fromMillisecondsSinceEpoch(due),
      isDone: (map['isDone'] as bool?) ?? false,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updated ?? 0),
      isSynced: true,
    );
  }
}
