import 'package:equatable/equatable.dart';
import 'package:hubster_app/models/subscriptions/hosted_subscription.dart';
import 'package:hubster_app/models/subscriptions/join_request.dart';
import 'package:hubster_app/models/subscriptions/subscription_membership.dart';

// Enum for the overall status of the ManageSubscription screen.
enum ManageSubscriptionScreenStatus { initial, loading, loaded, error }

// Enum for the status of specific actions like approving/declining.
enum ManageSubscriptionActionStatus { idle, loading, success, error }

// Immutable state for the ManageSubscription screen.
class ManageSubscriptionState extends Equatable {
  final ManageSubscriptionScreenStatus screenStatus;
  final HostedSubscriptionResponse? subscriptionDetails;
  final List<SubscriptionMembershipResponse> members;
  final List<JoinRequest> joinRequests;
  final String? errorMessage;

  // Status for specific actions on join requests
  final ManageSubscriptionActionStatus approveRequestStatus;
  final String? approveRequestError;
  final ManageSubscriptionActionStatus declineRequestStatus;
  final String? declineRequestError;

  const ManageSubscriptionState({
    this.screenStatus = ManageSubscriptionScreenStatus.initial,
    this.subscriptionDetails,
    this.members = const [],
    this.joinRequests = const [],
    this.errorMessage,
    this.approveRequestStatus = ManageSubscriptionActionStatus.idle,
    this.approveRequestError,
    this.declineRequestStatus = ManageSubscriptionActionStatus.idle,
    this.declineRequestError,
  });

  ManageSubscriptionState copyWith({
    ManageSubscriptionScreenStatus? screenStatus,
    HostedSubscriptionResponse? subscriptionDetails,
    List<SubscriptionMembershipResponse>? members,
    List<JoinRequest>? joinRequests,
    String? errorMessage,
    bool clearErrorMessage = false,
    ManageSubscriptionActionStatus? approveRequestStatus,
    String? approveRequestError,
    bool clearApproveRequestError = false,
    ManageSubscriptionActionStatus? declineRequestStatus,
    String? declineRequestError,
    bool clearDeclineRequestError = false,
  }) {
    return ManageSubscriptionState(
      screenStatus: screenStatus ?? this.screenStatus,
      subscriptionDetails: subscriptionDetails ?? this.subscriptionDetails,
      members: members ?? this.members,
      joinRequests: joinRequests ?? this.joinRequests,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      approveRequestStatus: approveRequestStatus ?? this.approveRequestStatus,
      approveRequestError:
          clearApproveRequestError
              ? null
              : approveRequestError ?? this.approveRequestError,
      declineRequestStatus: declineRequestStatus ?? this.declineRequestStatus,
      declineRequestError:
          clearDeclineRequestError
              ? null
              : declineRequestError ?? this.declineRequestError,
    );
  }

  @override
  List<Object?> get props => [
    screenStatus,
    subscriptionDetails,
    members,
    joinRequests,
    errorMessage,
    approveRequestStatus,
    approveRequestError,
    declineRequestStatus,
    declineRequestError,
  ];
}
