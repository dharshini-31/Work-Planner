import 'package:flutter/material.dart';
import '../profile/modern_profile_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernProfileScreen(role: 'user');
  }
}
