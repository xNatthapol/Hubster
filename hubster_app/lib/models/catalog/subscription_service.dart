import 'package:equatable/equatable.dart';

// Represents a predefined subscription service
class SubscriptionService extends Equatable {
  final int id;
  final String name;
  final String? logoUrl;

  const SubscriptionService({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  factory SubscriptionService.fromJson(Map<String, dynamic> json) {
    return SubscriptionService(
      id: json['id'] as int,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'logo_url': logoUrl};
  }

  @override
  List<Object?> get props => [id, name, logoUrl];
}
