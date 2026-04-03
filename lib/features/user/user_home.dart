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
  int _newTaskCount = 0;
  final DatabaseService _db = DatabaseService();
  bool _tasksInitialized = false;

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
      bool isFirstLoad = !_tasksInitialized;
      _tasksInitialized = true;

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final Timestamp? ts = data['createdAt'] as Timestamp?;

          // If this is the initial stream load, only notify for tasks created in the last 2 minutes.
          // This supports single-device testing where an Admin logs out and User logs in.
          if (isFirstLoad) {
            if (ts != null) {
              if (DateTime.now().difference(ts.toDate()).inMinutes > 2) {
                continue;
              }
            } else {
              continue;
            }
          }

          if (_currentIndex != 1 && mounted) {
            setState(() {
              _newTaskCount++;
            });
            
            // Only popup a snackbar for truly live events (not on login dump)
            if (!isFirstLoad) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('You have a new task assigned!'),
                  backgroundColor: Colors.indigo,
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'View',
                    textColor: Colors.white,
                    onPressed: () {
                      setState(() {
                        _currentIndex = 1;
                        _newTaskCount = 0;
                      });
                    },
                  ),
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
                if (index == 1) {
                  _newTaskCount = 0;
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
                  isLabelVisible: _newTaskCount > 0,
                  label: Text('$_newTaskCount', style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.list_alt_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: _newTaskCount > 0,
                  label: Text('$_newTaskCount', style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.red,
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
