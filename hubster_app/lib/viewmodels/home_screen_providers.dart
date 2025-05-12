import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/core/di/service_locator.dart';
import 'package:hubster_app/models/subscriptions/hosted_subscription.dart';
import 'package:hubster_app/models/subscriptions/subscription_membership.dart';
import 'package:hubster_app/services/subscription_api_service.dart';
import 'package:hubster_app/viewmodels/auth_state_notifier.dart';
import 'package:hubster_app/viewmodels/auth_state.dart';

// Provider to fetch subscriptions hosted by the current user.
final myHostedSubscriptionsProvider =
    FutureProvider.autoDispose<List<HostedSubscriptionResponse>>((ref) async {
      ref.watch(authStateNotifierProvider.select((value) => value.status));

      final authState = ref.read(authStateNotifierProvider);
      if (authState.status != AuthStatus.authenticated) {
        return [];
      }

      final subscriptionService = getIt<SubscriptionApiService>();
      return subscriptionService.getMyHostedSubscriptions();
    });

// Provider to fetch subscriptions the current user is a member of.
final myMemberSubscriptionsProvider =
    FutureProvider.autoDispose<List<SubscriptionMembershipResponse>>((
      ref,
    ) async {
      ref.watch(authStateNotifierProvider.select((value) => value.status));

      final authState = ref.read(authStateNotifierProvider);
      if (authState.status != AuthStatus.authenticated) {
        return [];
      }

      final subscriptionService = getIt<SubscriptionApiService>();
      return subscriptionService.getMyMemberSubscriptions();
    });
