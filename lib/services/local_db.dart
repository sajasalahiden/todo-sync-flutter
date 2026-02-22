import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/task.dart';

class LocalDb {
  LocalDb._();

  static final LocalDb instance = LocalDb._();

  Database? _db;

  Future<Database> get db async {
    final existing = _db;
    if (existing != null) return existing;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final base = await getDatabasesPath();
    final path = p.join(base, 'todo_sync_v2.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks(
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            dueDate INTEGER,
            isDone INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            isSynced INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_tasks_user_updated ON tasks(userId, updatedAt DESC)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE tasks ADD COLUMN userId TEXT NOT NULL DEFAULT ''");
          await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_user_updated ON tasks(userId, updatedAt DESC)');
        }
      },
    );
  }

  Future<List<Task>> getAllTasks(String userId) async {
    final database = await db;
    final rows = await database.query(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'updatedAt DESC',
    );
    return rows.map(Task.fromDbMap).toList();
  }

  Future<Task?> getTaskById({required String id, required String userId}) async {
    final database = await db;
    final rows = await database.query(
      'tasks',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Task.fromDbMap(rows.first);
  }

  Future<void> upsertTask(Task task) async {
    final database = await db;
    await database.insert(
      'tasks',
      task.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTask({required String id, required String userId}) async {
    final database = await db;
    await database.delete('tasks', where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }

  Future<List<Task>> getUnsyncedTasks(String userId) async {
    final database = await db;
    final rows = await database.query(
      'tasks',
      where: 'isSynced = 0 AND userId = ?',
      whereArgs: [userId],
      orderBy: 'updatedAt ASC',
    );
    return rows.map(Task.fromDbMap).toList();
  }

  Future<void> markSynced({required String id, required String userId}) async {
    final database = await db;
    await database.update(
      'tasks',
      {'isSynced': 1},
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> close() async {
    final database = _db;
    _db = null;
    await database?.close();
  }
}
