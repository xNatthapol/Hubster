import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/viewmodels/auth_state_notifier.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Add WidgetRef ref
    // Watch the state for UI updates
    final authState = ref.watch(authStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${authState.currentUser?.email ?? "User"}!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              print("HomeScreen: Logout button pressed.");
              // Read the notifier to call methods
              ref.read(authStateNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You are logged in! This is the Hubster Home Screen.'),
            const SizedBox(height: 20),
            Text('User ID: ${authState.currentUser?.id ?? "N/A"}'),
            Text('User Email: ${authState.currentUser?.email ?? "N/A"}'),
          ],
        ),
      ),
    );
  }
}
