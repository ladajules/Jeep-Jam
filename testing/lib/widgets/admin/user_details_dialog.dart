import 'package:flutter/material.dart';
import '../../utils/date_formatter.dart';

class UserDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onDelete;
  final VoidCallback onToggleAdmin;

  const UserDetailsDialog({
    Key? key,
    required this.user,
    required this.onDelete,
    required this.onToggleAdmin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAdmin = user['isAdmin'] == true;
    final isVerified = user['isVerified'] == true;

    return AlertDialog(
      title: const Text(
        'User Details',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', user['email'] ?? 'N/A'),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Email Verified',
              isVerified ? 'Yes' : 'No',
              textColor: isVerified ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Admin Status',
              isAdmin ? 'Admin' : 'Regular User',
              textColor: isAdmin ? Colors.purple : Colors.grey,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Joined',
              DateFormatter.formatDate(user['createdAt'], format: 'MMM dd, yyyy h:mm a'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Colors.black)),
        ),
        TextButton(
          onPressed: () => _showToggleAdminDialog(context, isAdmin),
          child: Text(
            isAdmin ? 'Remove Admin' : 'Make Admin',
            style: TextStyle(color: isAdmin ? Colors.orange : Colors.purple),
          ),
        ),
        TextButton(
          onPressed: () => _showDeleteDialog(context),
          child: const Text('Delete User', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  void _showToggleAdminDialog(BuildContext context, bool isAdmin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isAdmin ? 'Remove Admin Rights?' : 'Grant Admin Rights?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isAdmin
              ? 'This will remove admin privileges from ${user['email']}.'
              : 'This will grant admin privileges to ${user['email']}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onToggleAdmin();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdmin ? Colors.orange : Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: Text(isAdmin ? 'Remove' : 'Grant'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete User?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently delete ${user['email']} and all their data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? textColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}