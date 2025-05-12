import 'package:equatable/equatable.dart';
import 'package:hubster_app/models/catalog/subscription_service.dart';

// Enum for the status of the create subscription process.
enum CreateSubscriptionStatus {
  initial,
  loadingServices,
  servicesLoaded,
  uploadingQR,
  qrUploaded,
  submitting,
  success,
  error,
}

// Immutable state for the CreateSubscription screen.
class CreateSubscriptionState extends Equatable {
  final CreateSubscriptionStatus status;
  final List<SubscriptionService> availableServices;
  final String? selectedServiceId;
  final String? uploadedQrCodeUrl;
  final String? operationMessage;

  const CreateSubscriptionState({
    this.status = CreateSubscriptionStatus.initial,
    this.availableServices = const [],
    this.selectedServiceId,
    this.uploadedQrCodeUrl,
    this.operationMessage,
  });

  CreateSubscriptionState copyWith({
    CreateSubscriptionStatus? status,
    List<SubscriptionService>? availableServices,
    String? selectedServiceId,
    bool clearSelectedService = false,
    String? uploadedQrCodeUrl,
    bool clearUploadedQrCodeUrl = false,
    String? operationMessage,
    bool clearOperationMessage = false,
  }) {
    return CreateSubscriptionState(
      status: status ?? this.status,
      availableServices: availableServices ?? this.availableServices,
      selectedServiceId:
          clearSelectedService
              ? null
              : (selectedServiceId ?? this.selectedServiceId),
      uploadedQrCodeUrl:
          clearUploadedQrCodeUrl
              ? null
              : (uploadedQrCodeUrl ?? this.uploadedQrCodeUrl),
      operationMessage:
          clearOperationMessage
              ? null
              : (operationMessage ?? this.operationMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    availableServices,
    selectedServiceId,
    uploadedQrCodeUrl,
    operationMessage,
  ];
}
