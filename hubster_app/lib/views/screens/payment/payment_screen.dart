import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Overview")),
      body: const Center(
        child: Text(
          "Payment Screen - Content Coming Soon!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
