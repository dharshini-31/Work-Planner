import 'package:flutter/material.dart';
import '../profile/modern_profile_screen.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernProfileScreen(role: 'admin');
  }
}
