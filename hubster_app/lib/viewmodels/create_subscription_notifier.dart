import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/core/di/service_locator.dart';
import 'package:hubster_app/models/subscriptions/hosted_subscription.dart';
import 'package:hubster_app/services/subscription_api_service.dart';
import 'package:hubster_app/services/upload_service.dart';
import 'create_subscription_state.dart';
import 'package:hubster_app/viewmodels/home_screen_providers.dart';

// Manages state and logic for creating a new hosted subscription.
class CreateSubscriptionNotifier
    extends StateNotifier<CreateSubscriptionState> {
  final SubscriptionApiService _subscriptionApiService;
  final UploadService _uploadService;
  final Ref _ref;

  CreateSubscriptionNotifier(
    this._subscriptionApiService,
    this._uploadService,
    this._ref,
  ) : super(const CreateSubscriptionState()) {
    fetchSubscriptionServices();
  }

  Future<void> fetchSubscriptionServices() async {
    state = state.copyWith(
      status: CreateSubscriptionStatus.loadingServices,
      clearOperationMessage: true,
    );
    try {
      final services = await _subscriptionApiService.getSubscriptionServices();
      state = state.copyWith(
        status: CreateSubscriptionStatus.servicesLoaded,
        availableServices: services,
      );
    } catch (e) {
      state = state.copyWith(
        status: CreateSubscriptionStatus.error,
        operationMessage: e.toString(),
      );
    }
  }

  Future<void> uploadQrCode(File imageFile) async {
    state = state.copyWith(
      status: CreateSubscriptionStatus.uploadingQR,
      clearOperationMessage: true,
      clearUploadedQrCodeUrl: true,
    );
    try {
      final imageUrl = await _uploadService.uploadImage(imageFile);
      if (imageUrl != null) {
        state = state.copyWith(
          status: CreateSubscriptionStatus.qrUploaded,
          uploadedQrCodeUrl: imageUrl,
        );
      } else {
        throw Exception("QR code upload returned null URL.");
      }
    } catch (e) {
      state = state.copyWith(
        status: CreateSubscriptionStatus.error,
        operationMessage: "QR Upload Failed: ${e.toString()}",
      );
    }
  }

  Future<bool> submitHostedSubscription(
    CreateHostedSubscriptionRequest request,
  ) async {
    state = state.copyWith(
      status: CreateSubscriptionStatus.submitting,
      clearOperationMessage: true,
    );
    try {
      await _subscriptionApiService.createHostedSubscription(request);
      state = state.copyWith(
        status: CreateSubscriptionStatus.success,
        operationMessage: "Subscription hosted successfully!",
      );

      _ref.invalidate(myHostedSubscriptionsProvider);
      print(
        "CreateSubscriptionNotifier: Subscription created. HomeScreen should refresh. (Call invalidate on its provider here)",
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        status: CreateSubscriptionStatus.error,
        operationMessage: e.toString(),
      );
      return false;
    }
  }

  void selectService(String serviceId) {
    state = state.copyWith(
      selectedServiceId: serviceId,
      status: CreateSubscriptionStatus.servicesLoaded,
    );
  }

  void resetFormState() {
    final currentServices = state.availableServices;
    state = CreateSubscriptionState(
      availableServices: currentServices,
      status:
          currentServices.isNotEmpty
              ? CreateSubscriptionStatus.servicesLoaded
              : CreateSubscriptionStatus.initial,
    );
    if (currentServices.isEmpty &&
        state.status == CreateSubscriptionStatus.initial) {
      fetchSubscriptionServices();
    }
    print("CreateSubscriptionNotifier: Form state reset.");
  }

  void clearOperationMessage() {
    if (state.operationMessage != null) {
      CreateSubscriptionStatus newStatus = state.status;
      if (state.status == CreateSubscriptionStatus.error ||
          state.status == CreateSubscriptionStatus.success) {
        newStatus =
            state.availableServices.isNotEmpty
                ? CreateSubscriptionStatus.servicesLoaded
                : CreateSubscriptionStatus.initial;
      }
      state = state.copyWith(clearOperationMessage: true, status: newStatus);
    }
  }
}

// Update the provider definition to pass 'ref' to the notifier's constructor.
final createSubscriptionNotifierProvider =
    StateNotifierProvider<CreateSubscriptionNotifier, CreateSubscriptionState>((
      ref,
    ) {
      final subApiService = getIt<SubscriptionApiService>();
      final uploadService = getIt<UploadService>();
      return CreateSubscriptionNotifier(subApiService, uploadService, ref);
    });
