import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/models/subscriptions/hosted_subscription.dart';
import 'package:hubster_app/services/subscription_api_service.dart';
import 'package:hubster_app/core/di/service_locator.dart';
import 'package:equatable/equatable.dart';

// Enum for detail screen status
enum DetailScreenStatus {
  initial,
  loading,
  loaded,
  error,
  submittingRequest,
  requestSent,
  requestError,
}

// State for SubscriptionDetailScreen
class SubscriptionDetailState extends Equatable {
  final DetailScreenStatus status;
  final HostedSubscriptionResponse? subscription;
  final String? errorMessage;
  final String? joinRequestMessage;

  const SubscriptionDetailState({
    this.status = DetailScreenStatus.initial,
    this.subscription,
    this.errorMessage,
    this.joinRequestMessage,
  });

  SubscriptionDetailState copyWith({
    DetailScreenStatus? status,
    HostedSubscriptionResponse? subscription,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? joinRequestMessage,
    bool clearJoinRequestMessage = false,
  }) {
    return SubscriptionDetailState(
      status: status ?? this.status,
      subscription: subscription ?? this.subscription,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      joinRequestMessage:
          clearJoinRequestMessage
              ? null
              : joinRequestMessage ?? this.joinRequestMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    subscription,
    errorMessage,
    joinRequestMessage,
  ];
}

// Notifier
class SubscriptionDetailNotifier
    extends StateNotifier<SubscriptionDetailState> {
  final SubscriptionApiService _subscriptionApiService;
  final String subscriptionId;

  SubscriptionDetailNotifier(this._subscriptionApiService, this.subscriptionId)
    : super(const SubscriptionDetailState()) {
    fetchSubscriptionDetails();
  }

  Future<void> fetchSubscriptionDetails() async {
    state = state.copyWith(
      status: DetailScreenStatus.loading,
      clearErrorMessage: true,
      clearJoinRequestMessage: true,
    );
    try {
      final subDetails = await _subscriptionApiService
          .getHostedSubscriptionDetails(subscriptionId);
      state = state.copyWith(
        status: DetailScreenStatus.loaded,
        subscription: subDetails,
      );
    } catch (e) {
      state = state.copyWith(
        status: DetailScreenStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> requestToJoin() async {
    state = state.copyWith(
      status: DetailScreenStatus.submittingRequest,
      clearJoinRequestMessage: true,
    );
    try {
      await _subscriptionApiService.requestToJoin(subscriptionId);
      state = state.copyWith(
        status: DetailScreenStatus.requestSent,
        joinRequestMessage: "Join request sent successfully!",
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: DetailScreenStatus.requestError,
        joinRequestMessage: e.toString(),
      );
      return false;
    }
  }

  void clearJoinRequestMessage() {
    if (state.joinRequestMessage != null) {
      DetailScreenStatus newStatus = state.status;
      if (state.status == DetailScreenStatus.requestSent ||
          state.status == DetailScreenStatus.requestError) {
        newStatus =
            state.subscription != null
                ? DetailScreenStatus.loaded
                : DetailScreenStatus.initial;
      }
      state = state.copyWith(clearJoinRequestMessage: true, status: newStatus);
    }
  }
}

// Provider that takes a subscriptionId argument
final subscriptionDetailNotifierProvider = StateNotifierProvider.autoDispose
    .family<SubscriptionDetailNotifier, SubscriptionDetailState, String>((
      ref,
      subscriptionId,
    ) {
      final apiService = getIt<SubscriptionApiService>();
      return SubscriptionDetailNotifier(apiService, subscriptionId);
    });
