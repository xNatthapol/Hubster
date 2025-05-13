import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/models/payment/payment_record.dart';
import 'package:hubster_app/viewmodels/host_payments_notifier.dart';
import 'package:hubster_app/viewmodels/host_payments_state.dart';
import 'package:hubster_app/views/screens/payment/payment_proof_approval_screen.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hostPaymentsNotifierProvider);
    final notifier = ref.read(hostPaymentsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment Actions"),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.fetchPendingPaymentRecords(),
        child: _buildBody(context, state, notifier),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    HostPaymentsState state,
    HostPaymentsNotifier notifier,
  ) {
    if (state.status == HostPaymentsStatus.loading &&
        state.pendingPaymentRecords.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == HostPaymentsStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(state.errorMessage ?? "Failed to load payment actions."),
        ),
      );
    }
    if (state.pendingPaymentRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "No pending payment proofs to review.",
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Text(
            "Awaiting Your Approval",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.pendingPaymentRecords.length,
          itemBuilder: (context, index) {
            final record = state.pendingPaymentRecords[index];

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 6.0,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      record.memberProfilePictureUrl != null &&
                              record.memberProfilePictureUrl!.isNotEmpty
                          ? NetworkImage(record.memberProfilePictureUrl!)
                          : null,
                  child:
                      (record.memberProfilePictureUrl == null ||
                              record.memberProfilePictureUrl!.isEmpty)
                          ? Text(
                            record.memberName.isNotEmpty
                                ? record.memberName[0].toUpperCase()
                                : "?",
                          )
                          : null,
                ),
                title: Text(
                  record.memberName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  "Proof for: ${record.subscriptionTitle}\nSubmitted: ${DateFormat.yMMMd().add_jm().format(record.submittedAt.toLocal())}",
                ),
                trailing: const Icon(Icons.chevron_right),
                isThreeLine: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => PaymentProofApprovalScreen(
                            paymentRecordId: record.id.toString(),
                          ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
