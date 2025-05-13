import 'package:equatable/equatable.dart';
import 'package:hubster_app/models/payment/payment_record.dart';

enum HostPaymentsStatus { initial, loading, loaded, error }

class HostPaymentsState extends Equatable {
  final HostPaymentsStatus status;
  final List<PaymentRecordResponse> pendingPaymentRecords;
  final String? errorMessage;

  const HostPaymentsState({
    this.status = HostPaymentsStatus.initial,
    this.pendingPaymentRecords = const [],
    this.errorMessage,
  });

  HostPaymentsState copyWith({
    HostPaymentsStatus? status,
    List<PaymentRecordResponse>? pendingPaymentRecords,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return HostPaymentsState(
      status: status ?? this.status,
      pendingPaymentRecords:
          pendingPaymentRecords ?? this.pendingPaymentRecords,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, pendingPaymentRecords, errorMessage];
}
