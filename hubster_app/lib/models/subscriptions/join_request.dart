import 'package:equatable/equatable.dart';
import 'package:hubster_app/models/auth/user.dart';

enum JoinRequestStatus {
  Pending,
  Approved,
  Declined,
  Cancelled;

  static JoinRequestStatus fromString(String? value) {
    switch (value) {
      case 'Pending':
        return JoinRequestStatus.Pending;
      case 'Approved':
        return JoinRequestStatus.Approved;
      case 'Declined':
        return JoinRequestStatus.Declined;
      case 'Cancelled':
        return JoinRequestStatus.Cancelled;
      default:
        return JoinRequestStatus.Pending;
    }
  }

  String toJsonString() => name;
}

class JoinRequest extends Equatable {
  final int id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int requesterUserId;
  final User? requesterUser;
  final int hostedSubscriptionId;
  final DateTime requestDate;
  final JoinRequestStatus status;

  const JoinRequest({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.requesterUserId,
    this.requesterUser,
    required this.hostedSubscriptionId,
    required this.requestDate,
    required this.status,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    DateTime safeParseDateTime(dynamic value, String fieldName) {
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print(
            "JoinRequest Error parsing DateTime for $fieldName '$value': $e",
          );
        }
      }
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    return JoinRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      createdAt: safeParseDateTime(json['createdAt'], 'createdAt'),
      updatedAt: safeParseDateTime(json['updatedAt'], 'updatedAt'),
      requesterUserId: (json['requester_user_id'] as num?)?.toInt() ?? 0,
      requesterUser:
          json['requester_user'] != null &&
                  json['requester_user'] is Map<String, dynamic>
              ? User.fromJson(json['requester_user'] as Map<String, dynamic>)
              : null,
      hostedSubscriptionId:
          (json['hosted_subscription_id'] as num?)?.toInt() ?? 0,
      requestDate: safeParseDateTime(json['request_date'], 'requestDate'),
      status: JoinRequestStatus.fromString(json['status'] as String?),
    );
  }

  @override
  List<Object?> get props => [
    id,
    createdAt,
    updatedAt,
    requesterUserId,
    requesterUser,
    hostedSubscriptionId,
    requestDate,
    status,
  ];
}
