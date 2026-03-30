import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../ui_helpers.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'task_page.dart';
import 'bottleneck_page.dart';
import 'profile_screen.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int _currentIndex = 0;
  bool _hasNewTask = false;
  final DatabaseService _db = DatabaseService();
  bool _tasksInitialized = false;
  Timestamp? _lastTaskTimestamp;

  final List<Widget> _screens = [
    const UserDashboardScreen(),
    const UserTaskScreen(),
    const UserBottleneckPage(),
    const UserProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _listenForNewTasks();
  }

  void _listenForNewTasks() {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;

    _db.getNewTasksStream(uid).listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        final timestamp = data['createdAt'] as Timestamp?;

        if (timestamp == null) return;

        if (!_tasksInitialized) {
          _lastTaskTimestamp = timestamp;
          _tasksInitialized = true;
          return;
        }

        if (_lastTaskTimestamp != null && timestamp.compareTo(_lastTaskTimestamp!) > 0) {
          _lastTaskTimestamp = timestamp;
          if (_currentIndex != 1 && mounted) {
            setState(() {
              _hasNewTask = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You have a new task assigned!'),
                backgroundColor: Colors.indigo,
                duration: Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
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
                if (index == 1) {
                  _hasNewTask = false;
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
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: _hasNewTask,
                  child: const Icon(Icons.list_alt_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: _hasNewTask,
                  child: const Icon(Icons.list_alt),
                ),
                label: 'Tasks',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.warning_amber_outlined),
                activeIcon: Icon(Icons.warning_amber),
                label: 'Issues',
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
