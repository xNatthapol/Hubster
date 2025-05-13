import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/models/payment/payment_record.dart';
import 'package:hubster_app/services/upload_service.dart';
import 'package:hubster_app/services/payment_api_service.dart';
import 'package:hubster_app/core/di/service_locator.dart';
import 'payment_submission_state.dart';

class PaymentSubmissionNotifier extends StateNotifier<PaymentSubmissionState> {
  final UploadService _uploadService;
  final PaymentApiService _paymentApiService;

  PaymentSubmissionNotifier(this._uploadService, this._paymentApiService)
    : super(const PaymentSubmissionState());

  // Uploads the selected proof image.
  Future<void> pickAndUploadProofImage(File imageFile) async {
    state = state.copyWith(
      pickedProofImageFile: imageFile,
      clearUploadedImageUrl: true,
      status: PaymentSubmissionStatus.imageUploading,
      clearOperationMessage: true,
    );
    try {
      final imageUrl = await _uploadService.uploadImage(imageFile);
      if (imageUrl != null) {
        state = state.copyWith(
          status: PaymentSubmissionStatus.imageUploaded,
          uploadedProofImageUrl: imageUrl,
          clearPickedImage: true,
        );
      } else {
        throw Exception("Image upload returned a null URL.");
      }
    } catch (e) {
      print("PaymentSubmissionNotifier: Image upload error - $e");
      state = state.copyWith(
        status: PaymentSubmissionStatus.imageUploadError,
        operationMessage: "Image upload failed: ${e.toString()}",
        clearPickedImage: true,
      );
    }
  }

  // Submits the payment record with proof to the backend.
  Future<bool> submitPaymentRecord(
    String membershipId,
    CreatePaymentRecordRequest request,
  ) async {
    if (state.uploadedProofImageUrl == null ||
        state.uploadedProofImageUrl!.isEmpty) {
      state = state.copyWith(
        status: PaymentSubmissionStatus.submissionError,
        operationMessage: "Please upload a payment proof image first.",
      );
      return false;
    }

    final finalRequest = CreatePaymentRecordRequest(
      paymentCycleIdentifier: request.paymentCycleIdentifier,
      amountPaid: request.amountPaid,
      proofImageUrl: state.uploadedProofImageUrl!,
      paymentMethod: request.paymentMethod,
      transactionReference: request.transactionReference,
    );

    state = state.copyWith(
      status: PaymentSubmissionStatus.submittingRecord,
      clearOperationMessage: true,
    );
    try {
      await _paymentApiService.submitPaymentProof(membershipId, finalRequest);
      state = state.copyWith(
        status: PaymentSubmissionStatus.submissionSuccess,
        operationMessage: "Payment proof submitted successfully!",
        clearUploadedImageUrl: true,
      );
      return true;
    } catch (e) {
      print("PaymentSubmissionNotifier: Payment record submission error - $e");
      state = state.copyWith(
        status: PaymentSubmissionStatus.submissionError,
        operationMessage: e.toString(),
      );
      return false;
    }
  }

  void clearMessage() {
    if (state.operationMessage != null) {
      PaymentSubmissionStatus newStatus = state.status;
      if (state.status == PaymentSubmissionStatus.submissionError ||
          state.status == PaymentSubmissionStatus.imageUploadError) {
        newStatus =
            state.uploadedProofImageUrl != null
                ? PaymentSubmissionStatus.imageUploaded
                : PaymentSubmissionStatus.initial;
      } else if (state.status == PaymentSubmissionStatus.submissionSuccess) {
        newStatus = PaymentSubmissionStatus.initial;
      }
      state = state.copyWith(clearOperationMessage: true, status: newStatus);
    }
  }

  void resetAll() {
    state = const PaymentSubmissionState();
  }
}

// Riverpod provider
final paymentSubmissionNotifierProvider = StateNotifierProvider.autoDispose<
  PaymentSubmissionNotifier,
  PaymentSubmissionState
>((ref) {
  return PaymentSubmissionNotifier(
    getIt<UploadService>(),
    getIt<PaymentApiService>(),
  );
});
