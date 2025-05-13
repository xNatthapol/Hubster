import 'package:equatable/equatable.dart';
import 'package:hubster_app/models/payment/payment_record.dart';

enum PaymentApprovalScreenStatus {
  initial,
  loadingDetails,
  detailsLoaded,
  errorDetails,
}

enum PaymentActionStatus { idle, loading, success, error }

class PaymentApprovalState extends Equatable {
  final PaymentApprovalScreenStatus screenStatus;
  final PaymentRecordResponse? paymentRecord;
  final String? errorMessage;

  final PaymentActionStatus approveStatus;
  final String? approveMessage;
  final PaymentActionStatus declineStatus;
  final String? declineMessage;

  const PaymentApprovalState({
    this.screenStatus = PaymentApprovalScreenStatus.initial,
    this.paymentRecord,
    this.errorMessage,
    this.approveStatus = PaymentActionStatus.idle,
    this.approveMessage,
    this.declineStatus = PaymentActionStatus.idle,
    this.declineMessage,
  });

  PaymentApprovalState copyWith({
    PaymentApprovalScreenStatus? screenStatus,
    PaymentRecordResponse? paymentRecord,
    String? errorMessage,
    bool clearErrorMessage = false,
    PaymentActionStatus? approveStatus,
    String? approveMessage,
    bool clearApproveMessage = false,
    PaymentActionStatus? declineStatus,
    String? declineMessage,
    bool clearDeclineMessage = false,
  }) {
    return PaymentApprovalState(
      screenStatus: screenStatus ?? this.screenStatus,
      paymentRecord: paymentRecord ?? this.paymentRecord,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      approveStatus: approveStatus ?? this.approveStatus,
      approveMessage:
          clearApproveMessage ? null : approveMessage ?? this.approveMessage,
      declineStatus: declineStatus ?? this.declineStatus,
      declineMessage:
          clearDeclineMessage ? null : declineMessage ?? this.declineMessage,
    );
  }

  @override
  List<Object?> get props => [
    screenStatus,
    paymentRecord,
    errorMessage,
    approveStatus,
    approveMessage,
    declineStatus,
    declineMessage,
  ];
}
