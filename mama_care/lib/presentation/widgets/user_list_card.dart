import 'package:flutter/material.dart';
import 'package:mama_care/domain/entities/user_model.dart';
import 'package:mama_care/presentation/screen/doctor_dashboard_screen.dart';
// ... other imports

class UserListCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEditRole;
  final VoidCallback onEditPermissions;
  final VoidCallback onViewDetails;

  const UserListCard({
    super.key,
    required this.user,
    required this.onEditRole,
    required this.onEditPermissions,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar( // Add avatar
           backgroundImage: (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
             ? NetworkImage(user.profileImageUrl!) : null,
           child: (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
             ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?') : null,
        ),
        title: Text(user.name),
        subtitle: Text('${user.email}\nRole: ${user.role.name.capitalize()}'),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
           onSelected: (value) {
              if (value == 'role') {
                onEditRole();
              } else if (value == 'perms') onEditPermissions();
              else if (value == 'details') onViewDetails();
           },
           itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
             const PopupMenuItem<String>( value: 'details', child: Text('View Details'), ),
             const PopupMenuItem<String>( value: 'role', child: Text('Edit Role'), ),
             const PopupMenuItem<String>( value: 'perms', child: Text('Edit Permissions'), ),
             // Add other actions like 'Disable User', 'Delete User'
           ],
           icon: Icon(Icons.more_vert),
        ),
        onTap: onViewDetails, // Make row tappable for details
      ),
    );
  }
}