import 'package:flutter/material.dart';
import '../../ui_helpers.dart';
import '../../services/database_service.dart';

class AdminUsersListScreen extends StatefulWidget {
  const AdminUsersListScreen({super.key});

  @override
  State<AdminUsersListScreen> createState() => _AdminUsersListScreenState();
}

class _AdminUsersListScreenState extends State<AdminUsersListScreen> {
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const DashboardHeader(
            title: 'Users Directory',
            subtitle: 'Overview of registered delegates',
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _db.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!;
          final regularUsers = users.where((u) => u['role']?.toString().toLowerCase() != 'admin').toList();

          if (regularUsers.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: regularUsers.length,
            itemBuilder: (context, index) {
              final user = regularUsers[index];
              return Padding(
                 padding: const EdgeInsets.only(bottom: 12.0),
                 child: GlassCard(
                   padding: EdgeInsets.zero,
                   child: Theme(
                     data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                     child: ExpansionTile(
                       leading: CircleAvatar(
                         backgroundColor: AppColors.primary.withOpacity(0.1),
                         child: const Icon(Icons.person, color: AppColors.primary),
                       ),
                       title: Text(
                         user['name'] ?? 'Unknown User',
                         style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                       ),
                       subtitle: Text(
                         user['role'] ?? 'User',
                         style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                       ),
                       children: [
                         Padding(
                           padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 20.0),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               const Divider(color: Colors.black12),
                               const SizedBox(height: 12),
                               _buildInfoRow('Email ID', user['email'] ?? 'Not provided'),
                               _buildInfoRow('First Name', user['firstName'] ?? 'Not provided'),
                               _buildInfoRow('Last Name', user['lastName'] ?? 'Not provided'),
                               _buildInfoRow('Username', user['username'] ?? 'Not provided'),
                               _buildInfoRow('Phone', '${user['countryCode'] ?? ''} ${user['phone'] ?? 'Not provided'}'),
                               _buildInfoRow('Birth Date', user['birthDate'] ?? 'Not provided'),
                               _buildInfoRow('Gender', user['gender'] ?? 'Not provided'),
                             ],
                           ),
                         )
                       ],
                     ),
                   ),
                 ),
              );
            },
            );
          },
        ),
      ),
    ],
  ),
);
}

  Widget _buildInfoRow(String label, String value) {
    if (value.trim().isEmpty || value == ' ') value = 'Not provided';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
