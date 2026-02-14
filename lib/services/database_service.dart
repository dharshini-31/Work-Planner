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
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
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
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
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
    Query query = _firestore.collection('tasks').orderBy('createdAt', descending: true);
    if (assignedToUid != null) {
      query = query.where('assignedToUid', isEqualTo: assignedToUid);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await _firestore.collection('tasks').doc(taskId).update({'status': newStatus});
  }

  // --- Bottleneck Management ---

  Future<void> reportBottleneck({
    required String taskId,
    required String taskTitle,
    required String reportedByUid,
    required String description,
  }) async {
    await _firestore.collection('bottlenecks').add({
      'taskId': taskId,
      'taskTitle': taskTitle,
      'reportedByUid': reportedByUid,
      'description': description,
      'status': 'Reported',
      'adminNotes': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getBottlenecks({String? reportedByUid}) {
    Query query = _firestore.collection('bottlenecks').orderBy('createdAt', descending: true);
    if (reportedByUid != null) {
      query = query.where('reportedByUid', isEqualTo: reportedByUid);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> updateBottleneckStatus(String bottleneckId, String newStatus, {String? adminNotes}) async {
    Map<String, dynamic> updates = {'status': newStatus};
    if (adminNotes != null) {
      updates['adminNotes'] = adminNotes;
    }
    await _firestore.collection('bottlenecks').doc(bottleneckId).update(updates);
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
    return _firestore.collection('login_logs')
        .orderBy('timestamp', descending: true)
        .limit(1) // Only interested in the very last one for notification trigger
        .snapshots();
  }
}
