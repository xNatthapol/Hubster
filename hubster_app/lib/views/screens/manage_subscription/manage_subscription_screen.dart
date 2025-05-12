import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/models/auth/user.dart' as app_user_model;
import 'package:hubster_app/models/subscriptions/hosted_subscription.dart';
import 'package:hubster_app/models/subscriptions/join_request.dart';
import 'package:hubster_app/models/subscriptions/subscription_membership.dart';
import 'package:hubster_app/viewmodels/manage_subscription_notifier.dart';
import 'package:hubster_app/viewmodels/manage_subscription_state.dart';
import 'package:intl/intl.dart';

class ManageSubscriptionScreen extends ConsumerWidget {
  final String hostedSubscriptionId;

  const ManageSubscriptionScreen({
    super.key,
    required this.hostedSubscriptionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      manageSubscriptionNotifierProvider(hostedSubscriptionId),
    );
    final notifier = ref.read(
      manageSubscriptionNotifierProvider(hostedSubscriptionId).notifier,
    );

    // Listen for action statuses to show SnackBars
    ref.listen<ManageSubscriptionState>(
      manageSubscriptionNotifierProvider(hostedSubscriptionId),
      (prev, next) {
        if (prev?.approveRequestStatus !=
                ManageSubscriptionActionStatus.success &&
            next.approveRequestStatus ==
                ManageSubscriptionActionStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Join request approved!"),
              backgroundColor: Colors.green,
            ),
          );
          notifier.resetActionStatuses();
        } else if (prev?.approveRequestStatus !=
                ManageSubscriptionActionStatus.error &&
            next.approveRequestStatus == ManageSubscriptionActionStatus.error &&
            next.approveRequestError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Approval failed: ${next.approveRequestError}"),
              backgroundColor: Colors.red,
            ),
          );
          notifier.resetActionStatuses();
        }

        if (prev?.declineRequestStatus !=
                ManageSubscriptionActionStatus.success &&
            next.declineRequestStatus ==
                ManageSubscriptionActionStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Join request declined."),
              backgroundColor: Colors.blue,
            ),
          );
          notifier.resetActionStatuses();
        } else if (prev?.declineRequestStatus !=
                ManageSubscriptionActionStatus.error &&
            next.declineRequestStatus == ManageSubscriptionActionStatus.error &&
            next.declineRequestError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Decline failed: ${next.declineRequestError}"),
              backgroundColor: Colors.red,
            ),
          );
          notifier.resetActionStatuses();
        }
      },
    );

    Widget buildBody() {
      if (state.screenStatus == ManageSubscriptionScreenStatus.loading &&
          state.subscriptionDetails == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.screenStatus == ManageSubscriptionScreenStatus.error ||
          state.subscriptionDetails == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              state.errorMessage ?? "Failed to load subscription details.",
            ),
          ),
        );
      }

      final subDetails = state.subscriptionDetails!;

      return RefreshIndicator(
        onRefresh: () => notifier.loadInitialData(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSubscriptionOverviewCard(context, subDetails),
            const SizedBox(height: 20),

            Text(
              "Members (${subDetails.host != null ? state.members.length + 1 : state.members.length}/${subDetails.totalSlots})",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (subDetails.host != null)
              _buildMemberListItem(
                context,
                subDetails.host!,
                subDetails.createdAt,
                "Host (You)",
                isHost: true,
              ),

            if (state.members.isEmpty && subDetails.host == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text("No members yet."),
              )
            else if (state.members.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.members.length,
                itemBuilder: (context, index) {
                  final membership = state.members[index];
                  return _buildMemberListItem(
                    context,
                    membership.memberUser,
                    membership.joinedDate,
                    membership.paymentStatus.name,
                  );
                },
              ),
            const SizedBox(height: 20),

            Text(
              "Requests to Join (${state.joinRequests.where((r) => r.status == JoinRequestStatus.Pending).length})",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (state.joinRequests.isEmpty ||
                state.joinRequests.every(
                  (r) => r.status != JoinRequestStatus.Pending,
                ))
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text("No pending join requests."),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.joinRequests.length,
                itemBuilder: (context, index) {
                  final request = state.joinRequests[index];
                  if (request.status != JoinRequestStatus.Pending) {
                    return const SizedBox.shrink();
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            request.requesterUser?.profilePictureUrl != null &&
                                    request
                                        .requesterUser!
                                        .profilePictureUrl!
                                        .isNotEmpty
                                ? NetworkImage(
                                  request.requesterUser!.profilePictureUrl!,
                                )
                                : null,
                        child:
                            (request.requesterUser?.profilePictureUrl == null ||
                                    request
                                        .requesterUser!
                                        .profilePictureUrl!
                                        .isEmpty)
                                ? const Icon(Icons.person)
                                : null,
                      ),
                      title: Text(
                        request.requesterUser?.fullName ??
                            "User ID: ${request.requesterUserId}",
                      ),
                      subtitle: Text(
                        "Requested ${DateFormat.yMMMd().add_jm().format(request.requestDate.toLocal())}",
                      ),
                      trailing:
                          (state.approveRequestStatus ==
                                      ManageSubscriptionActionStatus.loading ||
                                  state.declineRequestStatus ==
                                      ManageSubscriptionActionStatus.loading)
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    child: const Text(
                                      "Decline",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onPressed:
                                        () => notifier.declineRequest(
                                          request.id.toString(),
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    child: const Text("Accept"),
                                    onPressed:
                                        () => notifier.approveRequest(
                                          request.id.toString(),
                                        ),
                                  ),
                                ],
                              ),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.subscriptionDetails?.subscriptionTitle ?? "Manage Subscription",
        ),
      ),
      body: buildBody(),
    );
  }

  Widget _buildSubscriptionOverviewCard(
    BuildContext context,
    HostedSubscriptionResponse subDetails,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child:
                      subDetails.subscriptionServiceLogoUrl != null &&
                              subDetails.subscriptionServiceLogoUrl!.isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              subDetails.subscriptionServiceLogoUrl!,
                            ),
                          )
                          : const Icon(Icons.public, size: 40),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subDetails.subscriptionTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subDetails.planDetails != null &&
                          subDetails.planDetails!.isNotEmpty)
                        Text(
                          subDetails.planDetails!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Monthly Cost (Total):"),
                Text(
                  "\$${subDetails.costPerCycle.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Per Member:"),
                Text(
                  "\$${subDetails.costPerSlot.toStringAsFixed(2)}/mo",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberListItem(
    BuildContext context,
    app_user_model.User? member,
    DateTime relevantDate,
    String statusOrRole, {
    bool isHost = false,
  }) {
    Color statusColor = Colors.grey;
    if (!isHost) {
      if (statusOrRole == PaymentStatus.Paid.name) statusColor = Colors.green;
      if (statusOrRole == PaymentStatus.PaymentDue.name ||
          statusOrRole == PaymentStatus.Unpaid.name) {
        statusColor = Colors.orange;
      }
      if (statusOrRole == PaymentStatus.ProofSubmitted.name) {
        statusColor = Colors.blue;
      }
      if (statusOrRole == PaymentStatus.ProofDeclined.name) {
        statusColor = Colors.red;
      }
    }

    String displayName =
        isHost
            ? (member?.fullName ?? "Host")
            : (member?.fullName ?? "Member ID: ${member?.id}");
    ImageProvider? avatarImage;

    if (member != null) {
      // Check if member object itself is not null
      displayName = member.fullName;
      if (member.profilePictureUrl != null &&
          member.profilePictureUrl!.isNotEmpty) {
        avatarImage = NetworkImage(member.profilePictureUrl!);
      }
    } else if (isHost) {
      displayName = "Host";
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: avatarImage,
          child:
              avatarImage == null
                  ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : "?",
                  )
                  : null,
        ),
        title: Text(displayName),
        subtitle: Text(
          isHost
              ? "Host"
              : "Joined: ${DateFormat.yMMMd().format(relevantDate.toLocal())}",
        ),
        trailing: Text(
          statusOrRole,
          style: TextStyle(
            color:
                isHost
                    ? Theme.of(context).textTheme.bodySmall?.color
                    : statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
