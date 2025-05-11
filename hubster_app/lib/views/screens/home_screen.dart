import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/core/theme/app_colors.dart';
import 'package:hubster_app/viewmodels/auth_state_notifier.dart';
import 'package:hubster_app/views/screens/profile/profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);
    final user = authState.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: const Text(
          'Hubster',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            // fontSize: 20,
          ),
        ),
        centerTitle: false,

        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(
                right: 12.0,
                top: 6.0,
                bottom: 6.0,
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                customBorder: const CircleBorder(),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      user.profilePictureUrl != null &&
                              user.profilePictureUrl!.isNotEmpty
                          ? NetworkImage(user.profilePictureUrl!)
                          : null,
                  child:
                      (user.profilePictureUrl == null ||
                              user.profilePictureUrl!.isEmpty)
                          ? const Icon(
                            Icons.person,
                            size: 22,
                            color: AppColors.primary,
                          )
                          : null,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.account_circle, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hubster Home Screen - Main Content Area',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
