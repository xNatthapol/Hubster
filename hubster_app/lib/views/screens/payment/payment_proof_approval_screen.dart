import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/models/payment/payment_record.dart';
import 'package:hubster_app/viewmodels/payment_approval_notifier.dart';
import 'package:hubster_app/viewmodels/payment_approval_state.dart';
import 'package:intl/intl.dart';

// Screen for hosts to review and approve/decline a submitted payment proof.
class PaymentProofApprovalScreen extends ConsumerWidget {
  final String paymentRecordId;

  const PaymentProofApprovalScreen({super.key, required this.paymentRecordId});

  // Helper for consistent detail row display.
  Widget _buildDetailRow(
    BuildContext context,
    String label,
    Widget valueWidget,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 15)),
          const SizedBox(width: 10),
          Expanded(
            child: DefaultTextStyle(
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: Colors.black87,
              ),
              textAlign: TextAlign.end,
              child: valueWidget,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentApprovalNotifierProvider(paymentRecordId));
    final notifier = ref.read(
      paymentApprovalNotifierProvider(paymentRecordId).notifier,
    );
    final ThemeData theme = Theme.of(context);

    // SnackBar listener for actions.
    ref.listen<PaymentApprovalState>(
      paymentApprovalNotifierProvider(paymentRecordId),
      (prev, next) {
        // Check Approve Status
        if (prev?.approveStatus != PaymentActionStatus.success &&
            next.approveStatus == PaymentActionStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.approveMessage ?? "Payment Approved!"),
              backgroundColor: Colors.green,
            ),
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ModalRoute.of(context)?.isCurrent == true)
              Navigator.of(context).pop();
          });
          notifier.resetActionStatuses();
        } else if (prev?.approveStatus != PaymentActionStatus.error &&
            next.approveStatus == PaymentActionStatus.error &&
            next.approveMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Approval Failed: ${next.approveMessage}"),
              backgroundColor: Colors.red,
            ),
          );
          notifier.resetActionStatuses();
        }

        // Check Decline Status
        if (prev?.declineStatus != PaymentActionStatus.success &&
            next.declineStatus == PaymentActionStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.declineMessage ?? "Payment Declined."),
              backgroundColor: Colors.orange,
            ),
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ModalRoute.of(context)?.isCurrent == true)
              Navigator.of(context).pop();
          });
          notifier.resetActionStatuses();
        } else if (prev?.declineStatus != PaymentActionStatus.error &&
            next.declineStatus == PaymentActionStatus.error &&
            next.declineMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Decline Failed: ${next.declineMessage}"),
              backgroundColor: Colors.red,
            ),
          );
          notifier.resetActionStatuses();
        }
      },
    );

    // Main content builder.
    Widget buildContent() {
      if (state.screenStatus == PaymentApprovalScreenStatus.loadingDetails ||
          (state.screenStatus == PaymentApprovalScreenStatus.initial &&
              state.paymentRecord == null)) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.screenStatus == PaymentApprovalScreenStatus.errorDetails ||
          state.paymentRecord == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(state.errorMessage ?? "Error loading payment details."),
          ),
        );
      }

      final record = state.paymentRecord!;

      String statusBannerText = "Review Payment Proof";
      Color statusBannerBgColor = Colors.blue[100]!;
      Color statusBannerFgColor = Colors.blue[800]!;
      IconData statusBannerIcon = Icons.hourglass_top_rounded;

      if (record.status == PaymentRecordStatus.Approved) {
        statusBannerText = "Payment Approved";
        statusBannerBgColor = Colors.green[100]!;
        statusBannerFgColor = Colors.green[800]!;
        statusBannerIcon = Icons.check_circle_outline_rounded;
      } else if (record.status == PaymentRecordStatus.Declined) {
        statusBannerText = "Payment Declined";
        statusBannerBgColor = Colors.red[100]!;
        statusBannerFgColor = Colors.red[800]!;
        statusBannerIcon = Icons.cancel_outlined;
      } else if (record.status == PaymentRecordStatus.ProofSubmitted) {
        statusBannerText = "Payment Pending Review";
        statusBannerBgColor = Colors.orange[100]!;
        statusBannerFgColor = Colors.orange[800]!;
        statusBannerIcon = Icons.hourglass_top_rounded;
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: statusBannerBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(statusBannerIcon, color: statusBannerFgColor, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    statusBannerText,
                    style: TextStyle(
                      color: statusBannerFgColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              "Payment Details",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              "Amount Paid:",
              Text(
                "\$${record.amountPaid.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            _buildDetailRow(
              context,
              "For Cycle:",
              Text(
                record.paymentCycleIdentifier,
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            _buildDetailRow(
              context,
              "Subscription:",
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    record.subscriptionTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            _buildDetailRow(
              context,
              "Submitted by:",
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (record.memberProfilePictureUrl != null &&
                      record.memberProfilePictureUrl!.isNotEmpty)
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                        record.memberProfilePictureUrl!,
                      ),
                      radius: 10,
                    )
                  else
                    CircleAvatar(
                      child: Icon(Icons.person, size: 12),
                      radius: 10,
                      backgroundColor: Colors.grey[300],
                    ),
                  const SizedBox(width: 8),
                  Text(
                    record.memberName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            _buildDetailRow(
              context,
              "Submitted At:",
              Text(
                DateFormat(
                  'MMM d, yyyy hh:mm a',
                ).format(record.submittedAt.toLocal()),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              "Submitted Receipt",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (record.proofImageUrl.isNotEmpty)
              Center(
                child: GestureDetector(
                  onTap: () {
                    print("Tapped on proof image: ${record.proofImageUrl}");
                  },
                  child: Container(
                    constraints: const BoxConstraints(
                      maxHeight: 300,
                      maxWidth: double.infinity,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7.5),
                      child: Image.network(
                        record.proofImageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder:
                            (context, child, loadingProgress) =>
                                loadingProgress == null
                                    ? child
                                    : const SizedBox(
                                      height: 150,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                        errorBuilder:
                            (context, error, stackTrace) => const SizedBox(
                              height: 150,
                              child: Center(
                                child: Icon(Icons.broken_image, size: 50),
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("No proof image submitted."),
                ),
              ),
            const SizedBox(height: 30),

            if (record.status == PaymentRecordStatus.ProofSubmitted)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Approve Button
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text("Received"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed:
                          (state.approveStatus == PaymentActionStatus.loading ||
                                  state.declineStatus ==
                                      PaymentActionStatus.loading)
                              ? null
                              : () {
                                notifier.approvePayment();
                              },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Decline Button
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close_rounded),
                      label: const Text("Not Received"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed:
                          (state.declineStatus == PaymentActionStatus.loading ||
                                  state.approveStatus ==
                                      PaymentActionStatus.loading)
                              ? null
                              : () {
                                notifier.declinePayment();
                              },
                    ),
                  ),
                ],
              )
            else
              Center(
                child: Text(
                  "This payment has already been reviewed. Status: ${record.status.name}",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
              ),

            if (state.approveStatus == PaymentActionStatus.loading ||
                state.declineStatus == PaymentActionStatus.loading)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(state.paymentRecord?.subscriptionTitle ?? "Review Payment"),
      ),
      body: buildContent(),
    );
  }
}
