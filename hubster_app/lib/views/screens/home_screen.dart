import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/core/theme/app_colors.dart';
import 'package:hubster_app/models/subscriptions/hosted_subscription.dart';
import 'package:hubster_app/models/subscriptions/subscription_membership.dart';
import 'package:hubster_app/viewmodels/auth_state_notifier.dart';
import 'package:hubster_app/viewmodels/home_screen_providers.dart';
import 'package:hubster_app/viewmodels/main_screen_tab_notifier.dart';
import 'package:hubster_app/views/screens/manage_subscription/manage_subscription_screen.dart';
import 'package:hubster_app/views/screens/member/member_subscription_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);
    final hostedSubsAsyncValue = ref.watch(myHostedSubscriptionsProvider);
    final memberSubsAsyncValue = ref.watch(myMemberSubscriptionsProvider);

    print("HomeScreen BUILD started. User: ${authState.currentUser?.email}");

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hubster',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          if (authState.currentUser != null)
            Padding(
              padding: const EdgeInsets.only(
                right: 12.0,
                top: 6.0,
                bottom: 6.0,
              ),
              child: InkWell(
                onTap: () {
                  ref.read(mainScreenTabNotifierProvider.notifier).changeTab(4);
                },
                customBorder: const CircleBorder(),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      authState.currentUser!.profilePictureUrl != null &&
                              authState
                                  .currentUser!
                                  .profilePictureUrl!
                                  .isNotEmpty
                          ? NetworkImage(
                            authState.currentUser!.profilePictureUrl!,
                          )
                          : null,
                  child:
                      (authState.currentUser!.profilePictureUrl == null ||
                              authState.currentUser!.profilePictureUrl!.isEmpty)
                          ? Icon(
                            Icons.person,
                            size: 22,
                            color: AppColors.primary,
                          )
                          : null,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myHostedSubscriptionsProvider);
          ref.invalidate(myMemberSubscriptionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          children: [
            // Hosted Subscriptions Section
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Text(
                "Hosted Subscriptions",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            hostedSubsAsyncValue.when(
              data: (subs) {
                if (subs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 30.0),
                      child: Text("You are not hosting any subscriptions yet."),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subs.length,
                  itemBuilder: (context, index) {
                    final sub = subs[index];
                    return InkWell(
                      onTap: () {
                        print(
                          "Navigating to ManageSubscriptionScreen for ID: ${sub.id}, Title: ${sub.subscriptionTitle}",
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ManageSubscriptionScreen(
                                  hostedSubscriptionId: sub.id.toString(),
                                ),
                          ),
                        );
                      },
                      child: HostedSubscriptionCard(
                        subscription: sub,
                        isHostView: true,
                      ),
                    );
                  },
                );
              },
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error:
                  (err, stack) => Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("Error fetching hosted subs: $err"),
                    ),
                  ),
            ),
            const SizedBox(height: 24),

            // Member Subscriptions Section
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Text(
                "Member Subscriptions",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            memberSubsAsyncValue.when(
              data: (subs) {
                if (subs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("You haven't joined any subscriptions yet."),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subs.length,
                  itemBuilder: (context, index) {
                    final membership = subs[index];
                    return InkWell(
                      onTap: () {
                        print(
                          "Navigating to MemberSubscriptionDetailScreen for Membership ID: ${membership.id}",
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => MemberSubscriptionDetailScreen(
                                  membership: membership,
                                ),
                          ),
                        );
                      },
                      child: MemberSubscriptionCard(membership: membership),
                    );
                  },
                );
              },
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error:
                  (err, stack) => Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("Error fetching member subs: $err"),
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

// Card widget for "Hosted Subscriptions"
class HostedSubscriptionCard extends StatelessWidget {
  final HostedSubscriptionResponse subscription;
  final bool isHostView;

  const HostedSubscriptionCard({
    super.key,
    required this.subscription,
    this.isHostView = false,
  });

  @override
  Widget build(BuildContext context) {
    final int displayCurrentOccupants =
        subscription.membersCount + 1; // host + other members
    final int displayTotalCapacity = subscription.totalSlots;
    final ThemeData theme = Theme.of(context);

    Widget actionWidget;
    if (isHostView) {
      actionWidget = Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          "Manage",
          style: TextStyle(
            color: AppColors.primary.withOpacity(0.9),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      );
    } else {
      // Explore view
      actionWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:
              subscription.availableSlots > 0
                  ? Colors.green[100]
                  : Colors.orange[100],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          subscription.availableSlots > 0
              ? "${subscription.availableSlots} spots left"
              : "Full",
          style: TextStyle(
            color:
                subscription.availableSlots > 0
                    ? Colors.green[800]
                    : Colors.orange[800],
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );
    }

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child:
                      subscription.subscriptionServiceLogoUrl != null &&
                              subscription
                                  .subscriptionServiceLogoUrl!
                                  .isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(6.0),
                            child: Image.network(
                              subscription.subscriptionServiceLogoUrl!,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (c, e, s) =>
                                      const Icon(Icons.public, size: 24),
                            ),
                          )
                          : Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Icon(
                              Icons.public,
                              size: 24,
                              color: Colors.grey[600],
                            ),
                          ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.subscriptionTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "$displayCurrentOccupants/$displayTotalCapacity members",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subscription.subscriptionServiceName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    "\$${subscription.costPerSlot.toStringAsFixed(2)}/mo",
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              // Bottom row for Avatars and Action Widget (Manage or Spots Left)
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Member Avatars
                if (subscription.memberAvatars != null &&
                    subscription.memberAvatars!.isNotEmpty)
                  SizedBox(
                    height: 28,
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          subscription.memberAvatars!.length > 4
                              ? 4
                              : subscription.memberAvatars!.length,
                      itemBuilder:
                          (context, index) => Align(
                            widthFactor: 0.6,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: theme.cardColor,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundImage: NetworkImage(
                                  subscription.memberAvatars![index],
                                ),
                                onBackgroundImageError: (e, s) {},
                                backgroundColor: Colors.grey[300],
                              ),
                            ),
                          ),
                    ),
                  )
                else
                  const Expanded(child: SizedBox(height: 28)),
                actionWidget,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Card widget for "Member Subscriptions"
class MemberSubscriptionCard extends StatelessWidget {
  final SubscriptionMembershipResponse membership;
  const MemberSubscriptionCard({super.key, required this.membership});

  @override
  Widget build(BuildContext context) {
    String paymentStatusText = membership.paymentStatus.name;
    Color statusColor = Colors.orangeAccent;
    Color statusTextColor = Colors.orange[800]!;

    switch (membership.paymentStatus) {
      case PaymentStatus.Paid:
        paymentStatusText = "Paid";
        statusColor = Colors.greenAccent[100]!;
        statusTextColor = Colors.green[700]!;
        break;
      case PaymentStatus.PaymentDue:
        paymentStatusText = "Payment Due";
        statusColor = Colors.orangeAccent[100]!;
        statusTextColor = Colors.orange[800]!;
        break;
      case PaymentStatus.ProofSubmitted:
        paymentStatusText = "Proof Submitted";
        statusColor = Colors.blueAccent[100]!;
        statusTextColor = Colors.blue[700]!;
        break;
      case PaymentStatus.ProofDeclined:
        paymentStatusText = "Proof Declined";
        statusColor = Colors.redAccent[100]!;
        statusTextColor = Colors.red[700]!;
        break;
      case PaymentStatus.Unpaid:
        paymentStatusText = "Unpaid";
        statusColor = Colors.redAccent[100]!;
        statusTextColor = Colors.red[700]!;
        break;
      default:
        paymentStatusText = membership.paymentStatus.name;
    }

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Service Logo
            SizedBox(
              width: 50,
              height: 50,
              child:
                  membership.serviceProviderLogoUrl != null &&
                          membership.serviceProviderLogoUrl!.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          membership.serviceProviderLogoUrl!,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (c, e, s) => const Icon(Icons.public, size: 30),
                        ),
                      )
                      : Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Icon(
                          Icons.public,
                          size: 30,
                          color: Colors.grey,
                        ),
                      ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    membership.hostedSubscriptionTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Hosted by ${membership.hostName}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    membership.serviceProviderName,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "\$${membership.costPerSlot.toStringAsFixed(2)}/month",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Payment Status and View Button
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    paymentStatusText,
                    style: TextStyle(
                      color: statusTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    "View",
                    style: TextStyle(
                      color: AppColors.primary.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
