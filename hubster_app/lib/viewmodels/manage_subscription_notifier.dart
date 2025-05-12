import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/services/subscription_api_service.dart';
import 'package:hubster_app/core/di/service_locator.dart';
import 'manage_subscription_state.dart';

// Notifier for the ManageSubscription screen.
class ManageSubscriptionNotifier
    extends StateNotifier<ManageSubscriptionState> {
  final SubscriptionApiService _subscriptionApiService;
  final String _subscriptionId;

  ManageSubscriptionNotifier(this._subscriptionApiService, this._subscriptionId)
    : super(const ManageSubscriptionState()) {
    loadInitialData();
  }

  Future<void> loadInitialData({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(
        screenStatus: ManageSubscriptionScreenStatus.loading,
        clearErrorMessage: true,
      );
    }
    try {
      final details = await _subscriptionApiService
          .getHostedSubscriptionDetails(_subscriptionId);
      final members = await _subscriptionApiService.getSubscriptionMembers(
        _subscriptionId,
      );
      final requests = await _subscriptionApiService
          .getJoinRequestsForSubscription(_subscriptionId, status: "Pending");

      state = state.copyWith(
        screenStatus: ManageSubscriptionScreenStatus.loaded,
        subscriptionDetails: details,
        members: members,
        joinRequests: requests,
      );
    } catch (e) {
      print("ManageSubscriptionNotifier: Error loading initial data: $e");
      state = state.copyWith(
        screenStatus: ManageSubscriptionScreenStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Approves a join request.
  Future<void> approveRequest(String requestId) async {
    state = state.copyWith(
      approveRequestStatus: ManageSubscriptionActionStatus.loading,
      clearApproveRequestError: true,
    );
    try {
      final newMembership = await _subscriptionApiService.approveJoinRequest(
        requestId,
      );
      await loadInitialData(showLoading: false);
      state = state.copyWith(
        approveRequestStatus: ManageSubscriptionActionStatus.success,
      );
    } catch (e) {
      print(
        "ManageSubscriptionNotifier: Error approving request $requestId: $e",
      );
      state = state.copyWith(
        approveRequestStatus: ManageSubscriptionActionStatus.error,
        approveRequestError: e.toString(),
      );
    }
  }

  // Declines a join request.
  Future<void> declineRequest(String requestId) async {
    state = state.copyWith(
      declineRequestStatus: ManageSubscriptionActionStatus.loading,
      clearDeclineRequestError: true,
    );
    try {
      await _subscriptionApiService.declineJoinRequest(requestId);
      await loadInitialData(showLoading: false);
      state = state.copyWith(
        declineRequestStatus: ManageSubscriptionActionStatus.success,
      );
    } catch (e) {
      print(
        "ManageSubscriptionNotifier: Error declining request $requestId: $e",
      );
      state = state.copyWith(
        declineRequestStatus: ManageSubscriptionActionStatus.error,
        declineRequestError: e.toString(),
      );
    }
  }

  // Call this to reset action statuses
  void resetActionStatuses() {
    state = state.copyWith(
      approveRequestStatus: ManageSubscriptionActionStatus.idle,
      clearApproveRequestError: true,
      declineRequestStatus: ManageSubscriptionActionStatus.idle,
      clearDeclineRequestError: true,
    );
  }
}

// Riverpod provider using .family to pass the subscriptionId.
final manageSubscriptionNotifierProvider = StateNotifierProvider.autoDispose
    .family<ManageSubscriptionNotifier, ManageSubscriptionState, String>((
      ref,
      subscriptionId,
    ) {
      final apiService = getIt<SubscriptionApiService>();
      return ManageSubscriptionNotifier(apiService, subscriptionId);
    });
