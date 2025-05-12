import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/models/subscriptions/subscription_membership.dart';
import 'package:hubster_app/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class MemberSubscriptionDetailScreen extends ConsumerWidget {
  final SubscriptionMembershipResponse membership;

  const MemberSubscriptionDetailScreen({super.key, required this.membership});

  // Helper for consistent detail row display.
  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  // Helper for styling the payment status chip.
  Widget _buildPaymentStatusChip(BuildContext context, PaymentStatus status) {
    String paymentStatusText = status.name;
    Color bgColor = Colors.grey[200]!;
    Color textColor = Colors.grey[800]!;

    switch (status) {
      case PaymentStatus.Paid:
        paymentStatusText = "Paid";
        bgColor = Colors.greenAccent[100]!;
        textColor = Colors.green[700]!;
        break;
      case PaymentStatus.PaymentDue:
        paymentStatusText = "Payment Due";
        bgColor = Colors.orangeAccent[100]!;
        textColor = Colors.orange[800]!;
        break;
      case PaymentStatus.ProofSubmitted:
        paymentStatusText = "Proof Submitted";
        bgColor = Colors.blueAccent[100]!;
        textColor = Colors.blue[700]!;
        break;
      case PaymentStatus.ProofDeclined:
        paymentStatusText = "Proof Declined";
        bgColor = Colors.redAccent[100]!;
        textColor = Colors.red[700]!;
        break;
      case PaymentStatus.Unpaid:
        paymentStatusText = "Unpaid";
        bgColor = Colors.redAccent[100]!;
        textColor = Colors.red[700]!;
        break;
      default:
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Text(
        paymentStatusText,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subMembership = membership;

    return Scaffold(
      appBar: AppBar(title: Text(subMembership.hostedSubscriptionTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Card with Service Info & Host
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child:
                          subMembership.serviceProviderLogoUrl != null &&
                                  subMembership
                                      .serviceProviderLogoUrl!
                                      .isNotEmpty
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  subMembership.serviceProviderLogoUrl!,
                                ),
                              )
                              : Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.public, size: 30),
                              ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subMembership.hostedSubscriptionTitle,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Hosted by ${subMembership.hostName}",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Your Payment Section
            Text(
              "Your Payment",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Amount:",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          "\$${subMembership.costPerSlot.toStringAsFixed(2)}/month",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Status:"),
                        _buildPaymentStatusChip(
                          context,
                          subMembership.paymentStatus,
                        ),
                      ],
                    ),
                    if (subMembership.nextPaymentDate != null) ...[
                      const Divider(height: 24, thickness: 0.5),
                      _buildDetailRow(
                        context,
                        "Next Due Date:",
                        DateFormat.yMMMd().format(
                          subMembership.nextPaymentDate!.toLocal(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Make Payment Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // TODO: Navigate to PaymentProofUploadScreen, passing necessary info like
                  print(
                    "Make Payment button tapped for membership ID: ${subMembership.id}",
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Navigate to Payment Proof Upload screen (coming soon!)",
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Make Payment",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Payment History Section (Placeholder)
            Text(
              "Payment History",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  heightFactor: 2,
                  child: Text("Payment history feature coming soon."),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
