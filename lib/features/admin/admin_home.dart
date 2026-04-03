import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database_service.dart';
import '../../ui_helpers.dart';
import 'dashboard_screen.dart';
import 'task_management_screen.dart';
import 'bottleneck_management_screen.dart';
import 'profile_screen.dart';
import 'users_list_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;
  final DatabaseService _db = DatabaseService();
  bool _initialized = false;
  Timestamp? _lastLoginTimestamp;
  bool _hasNewUserNotification = false;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminTaskManagementScreen(),
    const AdminBottleneckScreen(),
    const AdminUsersListScreen(),
    const AdminProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _listenForNewLogins();
    _listenForNewUsers();
  }

  void _listenForNewLogins() {
    _db.getLoginLogsStream().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        final timestamp = data['timestamp'] as Timestamp?;
        
        if (timestamp == null) return;

        // On first load, just set the timestamp so we don't notify for old logins
        if (!_initialized) {
          _lastLoginTimestamp = timestamp;
          _initialized = true;
          return;
        }

        // If new timestamp is after the last known one, show notification
        if (_lastLoginTimestamp != null && timestamp.compareTo(_lastLoginTimestamp!) > 0) {
          _lastLoginTimestamp = timestamp;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('New user login: ${data['email']}'),
                backgroundColor: Colors.indigo,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    });
  }

  bool _usersInitialized = false;

  void _listenForNewUsers() {
    _db.getNewUsersStream().listen((snapshot) {
      bool isFirstLoad = !_usersInitialized;
      _usersInitialized = true;

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final Timestamp? ts = data['createdAt'] as Timestamp?;

          if (isFirstLoad) {
            if (ts != null) {
              if (DateTime.now().difference(ts.toDate()).inMinutes > 2) {
                continue;
              }
            } else {
              continue; // skip if no timestamp
            }
          }

          if (mounted) {
            setState(() {
              _hasNewUserNotification = true;
            });
            // Only popup snackbar for truly live events (not login triggers)
            if (!isFirstLoad) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('A new user has registered!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                if (index == 3) {
                  _hasNewUserNotification = false;
                }
              });
            },
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey[400],
            showSelectedLabels: true,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.task_outlined),
                activeIcon: Icon(Icons.task),
                label: 'Tasks',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.warning_amber_outlined),
                activeIcon: Icon(Icons.warning_amber),
                label: 'Issues',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: _hasNewUserNotification,
                  child: const Icon(Icons.group_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: _hasNewUserNotification,
                  child: const Icon(Icons.group),
                ),
                label: 'Users',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
