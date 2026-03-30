import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- User Management ---

  Future<void> saveUser({
    required String uid,
    required String email,
    required String name,
    required String role,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving user: $e');
      rethrow;
    }
  }

  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>)['role'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // --- Task Management ---

  Future<void> createTask({
    required String title,
    required String description,
    required String assignedToUid,
    required String assignedToName,
    required String priority,
    required DateTime deadline,
  }) async {
    try {
      await _firestore.collection('tasks').add({
        'title': title,
        'description': description,
        'assignedToUid': assignedToUid,
        'assignedToName': assignedToName,
        'priority': priority,
        'deadline': Timestamp.fromDate(deadline),
        'status': 'To-Do',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating task: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getTasks({String? assignedToUid}) {
    Query query = _firestore
        .collection('tasks')
        .orderBy('createdAt', descending: true);
    if (assignedToUid != null) {
      query = query.where('assignedToUid', isEqualTo: assignedToUid);
    }
    return query.snapshots().map((snapshot) {
      try {
        // Debug logging to help diagnose disappearing tasks
        // ignore: avoid_print
        print(
          'getTasks snapshot: docs=${snapshot.docs.length}, isFromCache=${snapshot.metadata.isFromCache}',
        );
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      } catch (e) {
        // ignore: avoid_print
        print('Error mapping tasks snapshot: $e');
        return <Map<String, dynamic>>[];
      }
    });
  }

  /// Fetch server data first once, then continue with realtime snapshots.
  Stream<List<Map<String, dynamic>>> getTasksServerFirst({
    String? assignedToUid,
  }) async* {
    Query query = _firestore
        .collection('tasks')
        .orderBy('createdAt', descending: true);
    if (assignedToUid != null) {
      query = query.where('assignedToUid', isEqualTo: assignedToUid);
    }
    try {
      // Try server fetch first to ensure we don't show a stale cache-only snapshot
      final serverSnapshot = await query.get(
        const GetOptions(source: Source.server),
      );
      // ignore: avoid_print
      print('getTasksServerFirst: server docs=${serverSnapshot.docs.length}');
      yield serverSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('getTasksServerFirst server fetch error: $e');
      // fallthrough to realtime snapshots — they may still work
    }

    // then yield realtime updates
    yield* getTasks(assignedToUid: assignedToUid);
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': newStatus,
    });
  }

  // --- Bottleneck Management ---

  Future<void> reportBottleneck({
    required String taskId,
    required String taskTitle,
    required String reportedByUid,
    required String description,
  }) async {
    try {
      await _firestore.collection('bottlenecks').add({
        'taskId': taskId,
        'taskTitle': taskTitle,
        'reportedByUid': reportedByUid,
        'description': description,
        'status': 'Reported',
        'adminNotes': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error reporting bottleneck: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getBottlenecks({String? reportedByUid}) {
    Query query;
    if (reportedByUid != null) {
      // Use single-field query to avoid needing a composite index
      query = _firestore
          .collection('bottlenecks')
          .where('reportedByUid', isEqualTo: reportedByUid);
    } else {
      query = _firestore
          .collection('bottlenecks')
          .orderBy('createdAt', descending: true);
    }
    return query.snapshots().map((snapshot) {
      final list =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
      // Sort client-side when filtering by reportedByUid (no composite index needed)
      if (reportedByUid != null) {
        list.sort((a, b) {
          final aTime = a['createdAt'];
          final bTime = b['createdAt'];
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // descending
        });
      }
      return list;
    });
  }

  Future<void> updateBottleneckStatus(
    String bottleneckId,
    String newStatus, {
    String? adminNotes,
  }) async {
    Map<String, dynamic> updates = {'status': newStatus};
    if (adminNotes != null) {
      updates['adminNotes'] = adminNotes;
    }
    await _firestore
        .collection('bottlenecks')
        .doc(bottleneckId)
        .update(updates);
  }

  // --- Real-time Notifications (Login Logs) ---

  Future<void> logUserLogin(String uid, String email) async {
    await _firestore.collection('login_logs').add({
      'uid': uid,
      'email': email,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getLoginLogsStream() {
    // Return stream of logs ordered by timestamp
    // Limit to recent ones could be good, but for now simple stream
    return _firestore
        .collection('login_logs')
        .orderBy('timestamp', descending: true)
        .limit(
          1,
        ) // Only interested in the very last one for notification trigger
        .snapshots();
  }

  Stream<QuerySnapshot> getNewUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots();
  }

  Stream<QuerySnapshot> getNewTasksStream(String assignedToUid) {
    return _firestore
        .collection('tasks')
        .where('assignedToUid', isEqualTo: assignedToUid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots();
  }
}
