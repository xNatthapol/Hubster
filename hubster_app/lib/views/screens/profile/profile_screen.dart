import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/models/auth/user.dart';
import 'package:hubster_app/viewmodels/auth_state_notifier.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // Helper for section headers
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 24.0,
        bottom: 8.0,
        left: 16.0,
        right: 16.0,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  // Helper for profile options
  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing:
          onTap != null
              ? const Icon(Icons.chevron_right, color: Colors.grey)
              : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);
    final User? user = authState.currentUser;

    if (user == null) {
      // This should ideally be handled by app.dart navigating away if user becomes null
      // while this screen is active. If reached, show loading or error.
      print(
        "ProfileScreen: User is null, showing loading. AuthStatus: ${authState.status}",
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        automaticallyImplyLeading:
            true, // Allow back navigation if pushed onto stack
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          user.profilePictureUrl != null &&
                                  user.profilePictureUrl!.isNotEmpty
                              ? NetworkImage(user.profilePictureUrl!)
                              : null,
                      child:
                          user.profilePictureUrl == null ||
                                  user.profilePictureUrl!.isEmpty
                              ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey[600],
                              )
                              : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
          ),

          _buildSectionHeader(context, "Account Details"),
          _buildProfileOption(
            context,
            icon: Icons.person_outline,
            title: "Personal Information",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(currentUser: user),
                ),
              );
            },
          ),

          const Divider(height: 1, indent: 16, endIndent: 16, thickness: 0.5),

          _buildProfileOption(
            context,
            icon: Icons.logout,
            title: "Log Out",
            onTap: () {
              ref.read(authStateNotifierProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
