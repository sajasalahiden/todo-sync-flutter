import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task.dart';

class CloudService {
  CloudService._();

  static final CloudService instance = CloudService._();
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userTasks(String uid) {
    return _fs.collection('users').doc(uid).collection('tasks');
  }

  Future<void> upsertTask({required String uid, required Task task}) async {
    await _userTasks(uid).doc(task.id).set(task.toCloudMap(), SetOptions(merge: true));
  }

  Future<void> deleteTask({required String uid, required String id}) async {
    await _userTasks(uid).doc(id).delete();
  }

  Future<List<Task>> fetchAllTasks({required String uid}) async {
    final snap = await _userTasks(uid).get();
    return snap.docs
        .map((d) => Task.fromCloudMap(d.data()))
        .where((t) => t.id.isNotEmpty)
        .toList();
  }

  Stream<List<Task>> watchTasks({required String uid}) {
    return _userTasks(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Task.fromCloudMap(d.data())).toList());
  }
}
