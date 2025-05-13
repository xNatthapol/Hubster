import 'package:equatable/equatable.dart';

enum PaymentRecordStatus {
  ProofSubmitted,
  Approved,
  Declined,
  RequiresAttention;

  static PaymentRecordStatus fromString(String? value) {
    switch (value) {
      case 'ProofSubmitted':
        return PaymentRecordStatus.ProofSubmitted;
      case 'Approved':
        return PaymentRecordStatus.Approved;
      case 'Declined':
        return PaymentRecordStatus.Declined;
      case 'RequiresAttention':
        return PaymentRecordStatus.RequiresAttention;
      default:
        print(
          "Warning: Unknown PaymentRecordStatus string '$value'. Defaulting to ProofSubmitted.",
        );
        return PaymentRecordStatus.ProofSubmitted;
    }
  }

  String toJsonString() => name;
}

// Represents a payment record/submission
class PaymentRecordResponse extends Equatable {
  final int id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int subscriptionMembershipId;
  final String paymentCycleIdentifier;
  final double amountExpected;
  final double amountPaid;
  final String? paymentMethod;
  final String? transactionReference;
  final String proofImageUrl;
  final DateTime submittedAt;
  final PaymentRecordStatus status;
  final int? reviewedByUserId;
  final DateTime? reviewedAt;
  final String memberName;
  final String? memberProfilePictureUrl;
  final String subscriptionTitle;

  const PaymentRecordResponse({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.subscriptionMembershipId,
    required this.paymentCycleIdentifier,
    required this.amountExpected,
    required this.amountPaid,
    this.paymentMethod,
    this.transactionReference,
    required this.proofImageUrl,
    required this.submittedAt,
    required this.status,
    this.reviewedByUserId,
    this.reviewedAt,
    required this.memberName,
    this.memberProfilePictureUrl,
    required this.subscriptionTitle,
  });

  factory PaymentRecordResponse.fromJson(Map<String, dynamic> json) {
    DateTime safeParseDateTime(
      dynamic value,
      String fieldName, {
      bool isOptional = false,
    }) {
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print(
            "PaymentRecord.fromJson: Error parsing DateTime for $fieldName '$value': $e",
          );
        }
      }
      if (isOptional)
        return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      print(
        "Warning: DateTime field $fieldName is null, empty, or not a string: '$value'. Using epoch default.",
      );
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    String safeGetString(
      dynamic value,
      String fieldName, {
      String defaultValueIfNull = "",
    }) {
      if (value is String) return value;
      if (value == null) {
        print(
          "Warning: String field $fieldName is null. Using default '$defaultValueIfNull'.",
        );
        return defaultValueIfNull;
      }
      print(
        "Warning: String field $fieldName is not a String (type: ${value.runtimeType}): '$value'. Using default '$defaultValueIfNull'.",
      );
      return defaultValueIfNull;
    }

    return PaymentRecordResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      createdAt: safeParseDateTime(json['createdAt'], 'createdAt'),
      updatedAt: safeParseDateTime(json['updatedAt'], 'updatedAt'),
      subscriptionMembershipId:
          (json['subscription_membership_id'] as num?)?.toInt() ?? 0,
      paymentCycleIdentifier: safeGetString(
        json['payment_cycle_identifier'],
        'payment_cycle_identifier',
      ),
      amountExpected: (json['amount_expected'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String?,
      transactionReference: json['transaction_reference'] as String?,
      proofImageUrl: safeGetString(
        json['proof_image_url'],
        'proof_image_url',
        defaultValueIfNull: "error_no_proof_url",
      ),
      submittedAt: safeParseDateTime(json['submitted_at'], 'submittedAt'),
      status: PaymentRecordStatus.fromString(json['status'] as String?),
      reviewedByUserId: (json['reviewed_by_user_id'] as num?)?.toInt(),
      reviewedAt:
          json['reviewed_at'] != null
              ? safeParseDateTime(
                json['reviewed_at'],
                'reviewedAt',
                isOptional: true,
              )
              : null,
      memberName: safeGetString(
        json['member_name'],
        'member_name',
        defaultValueIfNull: "Unknown Member",
      ),
      memberProfilePictureUrl: json['member_profile_picture_url'] as String?,
      subscriptionTitle: safeGetString(
        json['subscription_title'],
        'subscription_title',
        defaultValueIfNull: "N/A Subscription",
      ),
    );
  }

  @override
  List<Object?> get props => [
    id,
    createdAt,
    updatedAt,
    subscriptionMembershipId,
    paymentCycleIdentifier,
    amountExpected,
    amountPaid,
    paymentMethod,
    transactionReference,
    proofImageUrl,
    submittedAt,
    status,
    reviewedByUserId,
    reviewedAt,
    memberName,
    memberProfilePictureUrl,
    subscriptionTitle,
  ];
}

// Request DTO for creating a payment record
class CreatePaymentRecordRequest {
  final String paymentCycleIdentifier;
  final double amountPaid;
  final String proofImageUrl;
  final String? paymentMethod;
  final String? transactionReference;

  CreatePaymentRecordRequest({
    required this.paymentCycleIdentifier,
    required this.amountPaid,
    required this.proofImageUrl,
    this.paymentMethod,
    this.transactionReference,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'payment_cycle_identifier': paymentCycleIdentifier,
      'amount_paid': amountPaid,
      'proof_image_url': proofImageUrl,
    };
    if (paymentMethod != null && paymentMethod!.isNotEmpty) {
      data['payment_method'] = paymentMethod;
    }
    if (transactionReference != null && transactionReference!.isNotEmpty) {
      data['transaction_reference'] = transactionReference;
    }
    return data;
  }
}
