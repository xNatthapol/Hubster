import 'package:equatable/equatable.dart';
import 'package:hubster_app/models/auth/user.dart';

enum PaymentStatus {
  PaymentDue,
  Paid,
  Unpaid,
  ProofSubmitted,
  ProofDeclined;

  static PaymentStatus fromString(String? value) {
    switch (value) {
      case 'PaymentDue':
        return PaymentStatus.PaymentDue;
      case 'Paid':
        return PaymentStatus.Paid;
      case 'Unpaid':
        return PaymentStatus.Unpaid;
      case 'ProofSubmitted':
        return PaymentStatus.ProofSubmitted;
      case 'ProofDeclined':
        return PaymentStatus.ProofDeclined;
      default:
        print(
          "Warning: Unknown PaymentStatus string '$value'. Defaulting to PaymentDue.",
        );
        return PaymentStatus.PaymentDue;
    }
  }

  String toJsonString() => name;
}

// DTO for displaying user's membership details.
class SubscriptionMembershipResponse extends Equatable {
  final int id;
  final int memberUserId;
  final User? memberUser;
  final int hostedSubscriptionId;
  final DateTime joinedDate;
  final PaymentStatus paymentStatus;
  final DateTime? nextPaymentDate;

  // Details from the HostedSubscription
  final String hostedSubscriptionTitle;
  final String serviceProviderName;
  final String? serviceProviderLogoUrl;
  final String hostName;
  final double costPerSlot;
  final String? paymentQRCodeUrl;

  const SubscriptionMembershipResponse({
    required this.id,
    required this.memberUserId,
    this.memberUser,
    required this.hostedSubscriptionId,
    required this.joinedDate,
    required this.paymentStatus,
    this.nextPaymentDate,
    required this.hostedSubscriptionTitle,
    required this.serviceProviderName,
    this.serviceProviderLogoUrl,
    required this.hostName,
    required this.costPerSlot,
    this.paymentQRCodeUrl,
  });

  factory SubscriptionMembershipResponse.fromJson(Map<String, dynamic> json) {
    DateTime? parseOptionalDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print("Error parsing optional date: $value");
        }
      }
      return null;
    }

    String safeGetString(
      dynamic value,
      String fieldName, {
      String defaultValueIfNull = "",
    }) {
      if (value is String) return value;
      return defaultValueIfNull;
    }

    return SubscriptionMembershipResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      memberUserId: (json['member_user_id'] as num?)?.toInt() ?? 0,
      memberUser:
          json['member_user'] != null &&
                  json['member_user'] is Map<String, dynamic>
              ? User.fromJson(json['member_user'] as Map<String, dynamic>)
              : null,
      hostedSubscriptionId:
          (json['hosted_subscription_id'] as num?)?.toInt() ?? 0,
      joinedDate: DateTime.parse(json['joined_date'] as String),
      paymentStatus: PaymentStatus.fromString(
        json['payment_status'] as String?,
      ),
      nextPaymentDate: parseOptionalDate(json['next_payment_date']),
      hostedSubscriptionTitle: safeGetString(
        json['hosted_subscription_title'],
        'hosted_subscription_title',
      ),
      serviceProviderName: safeGetString(
        json['service_provider_name'],
        'service_provider_name',
      ),
      serviceProviderLogoUrl: json['service_provider_logo_url'] as String?,
      hostName: safeGetString(json['host_name'], 'host_name'),
      costPerSlot: (json['cost_per_slot'] as num?)?.toDouble() ?? 0.0,
      paymentQRCodeUrl: json['payment_qr_code_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    memberUserId,
    hostedSubscriptionId,
    joinedDate,
    paymentStatus,
    nextPaymentDate,
    hostedSubscriptionTitle,
    serviceProviderName,
    serviceProviderLogoUrl,
    hostName,
    costPerSlot,
    paymentQRCodeUrl,
  ];
}
