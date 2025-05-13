import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/models/payment/payment_record.dart';
import 'package:hubster_app/services/payment_api_service.dart';
import 'package:hubster_app/core/di/service_locator.dart';
import 'payment_approval_state.dart';
import 'package:hubster_app/viewmodels/host_payments_notifier.dart';

class PaymentApprovalNotifier extends StateNotifier<PaymentApprovalState> {
  final PaymentApiService _paymentApiService;
  final String _paymentRecordId;
  final Ref _ref;

  PaymentApprovalNotifier(
    this._paymentApiService,
    this._paymentRecordId,
    this._ref,
  ) : super(const PaymentApprovalState()) {
    fetchPaymentRecordDetails();
  }

  Future<void> fetchPaymentRecordDetails() async {
    state = state.copyWith(
      screenStatus: PaymentApprovalScreenStatus.loadingDetails,
      clearErrorMessage: true,
    );
    try {
      final recordDetails = await _paymentApiService.getPaymentRecordDetails(
        _paymentRecordId,
      );
      state = state.copyWith(
        screenStatus: PaymentApprovalScreenStatus.detailsLoaded,
        paymentRecord: recordDetails,
      );
    } catch (e) {
      print(
        "PaymentApprovalNotifier: Error fetching payment record details: $e",
      );
      state = state.copyWith(
        screenStatus: PaymentApprovalScreenStatus.errorDetails,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> approvePayment({String? notes}) async {
    state = state.copyWith(
      approveStatus: PaymentActionStatus.loading,
      clearApproveMessage: true,
    );
    try {
      final updatedRecord = await _paymentApiService.approvePaymentProof(
        _paymentRecordId,
        notes: notes,
      );
      state = state.copyWith(
        approveStatus: PaymentActionStatus.success,
        approveMessage: "Payment approved!",
        paymentRecord: updatedRecord,
        screenStatus: PaymentApprovalScreenStatus.detailsLoaded,
      );
      _ref.invalidate(hostPaymentsNotifierProvider);
      return true;
    } catch (e) {
      print("PaymentApprovalNotifier: Error approving payment: $e");
      state = state.copyWith(
        approveStatus: PaymentActionStatus.error,
        approveMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> declinePayment({String? notes}) async {
    state = state.copyWith(
      declineStatus: PaymentActionStatus.loading,
      clearDeclineMessage: true,
    );
    try {
      final updatedRecord = await _paymentApiService.declinePaymentProof(
        _paymentRecordId,
        notes: notes,
      );
      state = state.copyWith(
        declineStatus: PaymentActionStatus.success,
        declineMessage: "Payment declined.",
        paymentRecord: updatedRecord,
        screenStatus: PaymentApprovalScreenStatus.detailsLoaded,
      );
      _ref.invalidate(hostPaymentsNotifierProvider);
      return true;
    } catch (e) {
      print("PaymentApprovalNotifier: Error declining payment: $e");
      state = state.copyWith(
        declineStatus: PaymentActionStatus.error,
        declineMessage: e.toString(),
      );
      return false;
    }
  }

  void resetActionStatuses() {
    state = state.copyWith(
      approveStatus: PaymentActionStatus.idle,
      clearApproveMessage: true,
      declineStatus: PaymentActionStatus.idle,
      clearDeclineMessage: true,
    );
  }
}

final paymentApprovalNotifierProvider = StateNotifierProvider.autoDispose
    .family<PaymentApprovalNotifier, PaymentApprovalState, String>((
      ref,
      paymentRecordId,
    ) {
      final apiService = getIt<PaymentApiService>();
      return PaymentApprovalNotifier(apiService, paymentRecordId, ref);
    });
