import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/models/subscriptions/subscription_membership.dart';
import 'package:equatable/equatable.dart';

// Enum for screen status
enum MemberDetailDisplayStatus { initial, loaded }

// State for MemberSubscriptionDetailScreen
class MemberSubscriptionDetailDisplayState extends Equatable {
  final MemberDetailDisplayStatus status;
  final SubscriptionMembershipResponse? membershipDetails;

  const MemberSubscriptionDetailDisplayState({
    this.status = MemberDetailDisplayStatus.initial,
    this.membershipDetails,
  });

  MemberSubscriptionDetailDisplayState copyWith({
    MemberDetailDisplayStatus? status,
    SubscriptionMembershipResponse? membershipDetails,
  }) {
    return MemberSubscriptionDetailDisplayState(
      status: status ?? this.status,
      membershipDetails: membershipDetails ?? this.membershipDetails,
    );
  }

  @override
  List<Object?> get props => [status, membershipDetails];
}

// Notifier
class MemberSubscriptionDetailNotifier
    extends StateNotifier<MemberSubscriptionDetailDisplayState> {
  MemberSubscriptionDetailNotifier(
    SubscriptionMembershipResponse initialDetails,
  ) : super(
        MemberSubscriptionDetailDisplayState(
          membershipDetails: initialDetails,
          status: MemberDetailDisplayStatus.loaded,
        ),
      );
}

// Provider that takes the initial SubscriptionMembershipResponse
final memberSubscriptionDetailNotifierProvider = StateNotifierProvider
    .autoDispose
    .family<
      MemberSubscriptionDetailNotifier,
      MemberSubscriptionDetailDisplayState,
      SubscriptionMembershipResponse
    >((ref, initialMembershipDetails) {
      return MemberSubscriptionDetailNotifier(initialMembershipDetails);
    });
