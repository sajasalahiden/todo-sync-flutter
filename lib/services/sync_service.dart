import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/task.dart';
import 'auth_service.dart';
import 'cloud_service.dart';
import 'local_db.dart';

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  final Connectivity _conn = Connectivity();

  Future<SyncResult> syncNow() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      return const SyncResult(
          ok: false, message: 'Please log in first to sync your tasks.');
    }

    final connectivity = await _conn.checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      return const SyncResult(
          ok: false,
          message:
              'No internet connection. Your tasks are saved locally and will sync later.');
    }

    final uid = user.uid;
    int pushed = 0;
    int pulled = 0;

    final unsynced = await LocalDb.instance.getUnsyncedTasks(uid);
    for (final t in unsynced) {
      await CloudService.instance.upsertTask(uid: uid, task: t);
      await LocalDb.instance.markSynced(id: t.id, userId: uid);
      pushed++;
    }

    final cloudTasks = await CloudService.instance.fetchAllTasks(uid: uid);
    for (final c in cloudTasks) {
      final local = await LocalDb.instance.getTaskById(id: c.id, userId: uid);
      if (local == null || c.updatedAt.isAfter(local.updatedAt)) {
        await LocalDb.instance
            .upsertTask(c.copyWith(userId: uid, isSynced: true));
        pulled++;
      }
    }

    return SyncResult(
        ok: true,
        message: 'Synchronization completed successfully.',
        pushed: pushed,
        pulled: pulled);
  }
}

class SyncResult {
  final bool ok;
  final String message;
  final int pushed;
  final int pulled;

  const SyncResult({
    required this.ok,
    required this.message,
    this.pushed = 0,
    this.pulled = 0,
  });
}
