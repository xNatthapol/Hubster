import 'package:equatable/equatable.dart';
import 'package:hubster_app/models/auth/user.dart';

// Enum for BillingCycleType
enum BillingCycleType {
  Monthly,
  Annually;

  static BillingCycleType fromString(String? value) {
    if (value == 'Monthly') return BillingCycleType.Monthly;
    if (value == 'Annually') return BillingCycleType.Annually;
    print(
      "Warning: Unknown BillingCycleType string '$value'. Defaulting to Monthly.",
    );
    return BillingCycleType.Monthly;
  }

  String toJsonString() {
    return name;
  }
}

class HostedSubscriptionResponse extends Equatable {
  final int id;
  final User? host;
  final String subscriptionTitle;
  final String? planDetails;
  final int totalSlots;
  final double costPerCycle;
  final BillingCycleType billingCycle;
  final String? paymentQRCodeUrl;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String subscriptionServiceName;
  final String? subscriptionServiceLogoUrl;
  final int membersCount;
  final int availableSlots;
  final double costPerSlot;
  final List<String>? memberAvatars;

  const HostedSubscriptionResponse({
    required this.id,
    this.host,
    required this.subscriptionTitle,
    this.planDetails,
    required this.totalSlots,
    required this.costPerCycle,
    required this.billingCycle,
    this.paymentQRCodeUrl,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.subscriptionServiceName,
    this.subscriptionServiceLogoUrl,
    required this.membersCount,
    required this.availableSlots,
    required this.costPerSlot,
    this.memberAvatars,
  });

  factory HostedSubscriptionResponse.fromJson(Map<String, dynamic> json) {
    print(
      "Attempting HostedSubscriptionResponse.fromJson with keys: ${json.keys.toList()}",
    );

    // Explicitly check and default non-nullable strings
    String title = "Default Title";
    if (json.containsKey('subscription_title') &&
        json['subscription_title'] is String) {
      title = json['subscription_title'];
    } else {
      print(
        "Warning: 'subscription_title' is missing or not a String. Value: ${json['subscription_title']}",
      );
    }

    String serviceName = "Default Service";
    if (json.containsKey('subscription_service_name') &&
        json['subscription_service_name'] is String) {
      serviceName = json['subscription_service_name'];
    } else {
      print(
        "Warning: 'subscription_service_name' is missing or not a String. Value: ${json['subscription_service_name']}",
      );
    }

    DateTime cAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    if (json.containsKey('createdAt') && json['createdAt'] is String) {
      try {
        cAt = DateTime.parse(json['createdAt']);
      } catch (e) {
        print("Error parsing createdAt: ${json['createdAt']}");
      }
    } else {
      print(
        "Warning: 'createdAt' is missing or not a String. Value: ${json['createdAt']}",
      );
    }

    DateTime uAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    if (json.containsKey('updatedAt') && json['updatedAt'] is String) {
      try {
        uAt = DateTime.parse(json['updatedAt']);
      } catch (e) {
        print("Error parsing updatedAt: ${json['updatedAt']}");
      }
    } else {
      print(
        "Warning: 'updatedAt' is missing or not a String. Value: ${json['updatedAt']}",
      );
    }

    BillingCycleType cycle = BillingCycleType.Monthly;
    if (json.containsKey('billing_cycle') && json['billing_cycle'] is String) {
      cycle = BillingCycleType.fromString(json['billing_cycle']);
    } else if (json['billing_cycle'] == null) {
      print("Warning: 'billing_cycle' is null. Defaulting.");
    } else {
      print(
        "Warning: 'billing_cycle' is missing or not a String. Value: ${json['billing_cycle']}",
      );
    }

    return HostedSubscriptionResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      host:
          json.containsKey('host') &&
                  json['host'] != null &&
                  json['host'] is Map<String, dynamic>
              ? User.fromJson(json['host'] as Map<String, dynamic>)
              : null,
      subscriptionTitle: title,
      planDetails: json['plan_details'] as String?,
      totalSlots: (json['total_slots'] as num?)?.toInt() ?? 0,
      costPerCycle: (json['cost_per_cycle'] as num?)?.toDouble() ?? 0.0,
      billingCycle: cycle,
      paymentQRCodeUrl:
          json['payment_qr_code_url'] as String?, 
      description: json['description'] as String?, 
      createdAt: cAt,
      updatedAt: uAt,
      subscriptionServiceName: serviceName,
      subscriptionServiceLogoUrl:
          json['subscription_service_logo_url'] as String?, 
      membersCount: (json['members_count'] as num?)?.toInt() ?? 0,
      availableSlots: (json['available_slots'] as num?)?.toInt() ?? 0,
      costPerSlot: (json['cost_per_slot'] as num?)?.toDouble() ?? 0.0,
      memberAvatars:
          (json['member_avatars'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    host,
    subscriptionTitle,
    planDetails,
    totalSlots,
    costPerCycle,
    billingCycle,
    paymentQRCodeUrl,
    description,
    createdAt,
    updatedAt,
    subscriptionServiceName,
    subscriptionServiceLogoUrl,
    membersCount,
    availableSlots,
    costPerSlot,
    memberAvatars,
  ];
}

// DTO for creating a new hosted subscription
class CreateHostedSubscriptionRequest {
  final int subscriptionServiceId;
  final String subscriptionTitle;
  final String? planDetails;
  final int totalSlots;
  final double costPerCycle;
  final BillingCycleType billingCycle;
  final String? paymentQRCodeUrl;
  final String? description;

  CreateHostedSubscriptionRequest({
    required this.subscriptionServiceId,
    required this.subscriptionTitle,
    this.planDetails,
    required this.totalSlots,
    required this.costPerCycle,
    required this.billingCycle,
    this.paymentQRCodeUrl,
    this.description,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['subscription_service_id'] = subscriptionServiceId;
    data['subscription_title'] = subscriptionTitle;
    if (planDetails != null) data['plan_details'] = planDetails;
    data['total_slots'] = totalSlots;
    data['cost_per_cycle'] = costPerCycle;
    data['billing_cycle'] = billingCycle.toJsonString();
    if (paymentQRCodeUrl != null) {
      data['payment_qr_code_url'] = paymentQRCodeUrl;
    }
    if (description != null) data['description'] = description;
    return data;
  }
}
