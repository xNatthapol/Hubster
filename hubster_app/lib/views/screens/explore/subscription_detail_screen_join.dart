import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/core/theme/app_colors.dart';
import 'package:hubster_app/viewmodels/subscription_detail_notifier.dart';

class SubscriptionDetailScreenJoin extends ConsumerWidget {
  final String subscriptionId;

  const SubscriptionDetailScreenJoin({super.key, required this.subscriptionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider for this specific subscriptionId
    final state = ref.watch(subscriptionDetailNotifierProvider(subscriptionId));
    final notifier = ref.read(
      subscriptionDetailNotifierProvider(subscriptionId).notifier,
    );

    // Listen for join request messages (success/error) to show SnackBars
    ref.listen<SubscriptionDetailState>(
      subscriptionDetailNotifierProvider(subscriptionId),
      (previous, next) {
        if ((next.status == DetailScreenStatus.requestSent ||
                next.status == DetailScreenStatus.requestError) &&
            next.joinRequestMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.joinRequestMessage!),
              backgroundColor:
                  next.status == DetailScreenStatus.requestSent
                      ? Colors.green
                      : Colors.red,
            ),
          );
          notifier.clearJoinRequestMessage();
          if (next.status == DetailScreenStatus.requestSent) {}
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.subscription?.subscriptionTitle ?? "Subscription Details",
        ),
      ),
      body: Builder(
        builder: (context) {
          if (state.status == DetailScreenStatus.loading ||
              state.status == DetailScreenStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == DetailScreenStatus.error ||
              state.subscription == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  state.errorMessage ?? "Failed to load subscription details.",
                ),
              ),
            );
          }

          final sub = state.subscription!;

          return SingleChildScrollView(
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
                        // Service Logo
                        SizedBox(
                          width: 60,
                          height: 60,
                          child:
                              sub.subscriptionServiceLogoUrl != null &&
                                      sub.subscriptionServiceLogoUrl!.isNotEmpty
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      sub.subscriptionServiceLogoUrl!,
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                  : Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.public, size: 40),
                                  ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sub.subscriptionTitle,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (sub.planDetails != null &&
                                  sub.planDetails!.isNotEmpty)
                                Text(
                                  sub.planDetails!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundImage:
                                        sub.host?.profilePictureUrl != null &&
                                                sub
                                                    .host!
                                                    .profilePictureUrl!
                                                    .isNotEmpty
                                            ? NetworkImage(
                                              sub.host!.profilePictureUrl!,
                                            )
                                            : null,
                                    child:
                                        (sub.host?.profilePictureUrl == null ||
                                                sub
                                                    .host!
                                                    .profilePictureUrl!
                                                    .isEmpty)
                                            ? const Icon(Icons.person, size: 12)
                                            : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    // To prevent overflow if host name is long
                                    child: Text(
                                      "Hosted by ${sub.host?.fullName ?? 'Unknown Host'}",
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Subscription Details Section
                Text(
                  "Subscription Details",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                        _buildDetailRow(
                          "Monthly Cost (Total):",
                          "\$${sub.costPerCycle.toStringAsFixed(2)}",
                        ),
                        _buildDetailRow(
                          "Your Share:",
                          "\$${sub.costPerSlot.toStringAsFixed(2)}/month",
                        ),
                        _buildDetailRow(
                          "Available Spots:",
                          "${sub.availableSlots} of ${sub.totalSlots}",
                        ),
                        _buildDetailRow(
                          "Billing Cycle:",
                          sub.billingCycle.name,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Current Members
                Text(
                  "Current Members (${sub.membersCount + 1}/${sub.totalSlots})",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (sub.memberAvatars != null && sub.memberAvatars!.isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: sub.memberAvatars!.length,
                      itemBuilder:
                          (ctx, index) => Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundImage: NetworkImage(
                                sub.memberAvatars![index],
                              ),
                            ),
                          ),
                    ),
                  )
                else
                  const Text(
                    "Be the first to join after the host!",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),

                const SizedBox(height: 30),

                // Request to Join Button
                if (state.status == DetailScreenStatus.submittingRequest)
                  const Center(child: CircularProgressIndicator())
                else if (state.status == DetailScreenStatus.requestSent)
                  Center(
                    child: Text(
                      state.joinRequestMessage ?? "Request Sent!",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        notifier.requestToJoin();
                      },
                      child: const Text(
                        "Request to Join",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                if (state.status == DetailScreenStatus.requestError &&
                    state.joinRequestMessage != null &&
                    state.joinRequestMessage!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      state.joinRequestMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
