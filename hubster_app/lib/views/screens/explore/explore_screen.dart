import 'package:flutter/material.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Explore Subscriptions")),
      body: const Center(
        child: Text(
          "Explore Screen - Content Coming Soon!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
