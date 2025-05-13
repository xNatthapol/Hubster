import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/core/di/service_locator.dart';
import 'package:hubster_app/models/payment/payment_record.dart';
import 'package:hubster_app/models/subscriptions/hosted_subscription.dart';
import 'package:hubster_app/services/payment_api_service.dart';
import 'package:hubster_app/services/subscription_api_service.dart';
import 'host_payments_state.dart';
import 'package:hubster_app/viewmodels/auth_state_notifier.dart';
import 'package:hubster_app/viewmodels/auth_state.dart';

class HostPaymentsNotifier extends StateNotifier<HostPaymentsState> {
  final SubscriptionApiService _subscriptionApiService;
  final PaymentApiService _paymentApiService;

  HostPaymentsNotifier(this._subscriptionApiService, this._paymentApiService)
    : super(const HostPaymentsState()) {
    fetchPendingPaymentRecords();
  }

  Future<void> fetchPendingPaymentRecords() async {
    state = state.copyWith(
      status: HostPaymentsStatus.loading,
      clearErrorMessage: true,
    );
    try {
      final List<HostedSubscriptionResponse> hostedSubs =
          await _subscriptionApiService.getMyHostedSubscriptions();

      if (hostedSubs.isEmpty) {
        state = state.copyWith(
          status: HostPaymentsStatus.loaded,
          pendingPaymentRecords: [],
        );
        return;
      }

      List<PaymentRecordResponse> allPendingRecords = [];
      for (var sub in hostedSubs) {
        try {
          final pendingRecordsForSub = await _paymentApiService
              .getPaymentRecordsForHostedSubscription(
                sub.id.toString(),
                status: PaymentRecordStatus.ProofSubmitted.name,
              );
          allPendingRecords.addAll(pendingRecordsForSub);
        } catch (e) {
          print(
            "HostPaymentsNotifier: Error fetching pending payments for sub ID ${sub.id}: $e",
          );
        }
      }

      allPendingRecords.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));

      state = state.copyWith(
        status: HostPaymentsStatus.loaded,
        pendingPaymentRecords: allPendingRecords,
      );
    } catch (e) {
      print("HostPaymentsNotifier: Error fetching pending payment records: $e");
      state = state.copyWith(
        status: HostPaymentsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Method to call when a proof is approved/declined elsewhere, to refresh this list
  void refreshData() {
    fetchPendingPaymentRecords();
  }
}

// Riverpod provider
final hostPaymentsNotifierProvider =
    StateNotifierProvider.autoDispose<HostPaymentsNotifier, HostPaymentsState>((
      ref,
    ) {
      ref.watch(authStateNotifierProvider.select((value) => value.status));
      final authState = ref.read(authStateNotifierProvider);
      if (authState.status != AuthStatus.authenticated) {
        return HostPaymentsNotifier(
            getIt<SubscriptionApiService>(),
            getIt<PaymentApiService>(),
          )
          ..state = const HostPaymentsState(
            status: HostPaymentsStatus.loaded,
            pendingPaymentRecords: [],
          );
      }
      return HostPaymentsNotifier(
        getIt<SubscriptionApiService>(),
        getIt<PaymentApiService>(),
      );
    });
