import 'package:flutter/material.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Subscription")),
      body: const Center(
        child: Text(
          "Create Screen - Content Coming Soon!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
