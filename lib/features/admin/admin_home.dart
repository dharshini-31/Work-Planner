import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database_service.dart';
import 'dashboard_screen.dart';
import 'task_management_screen.dart';
import 'bottleneck_management_screen.dart';
import 'profile_screen.dart';

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

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminTaskManagementScreen(),
    const AdminBottleneckScreen(),
    const AdminProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _listenForNewLogins();
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

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber),
            label: 'Bottlenecks',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
