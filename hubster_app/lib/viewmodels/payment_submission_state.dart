import 'dart:io';
import 'package:equatable/equatable.dart';

enum PaymentSubmissionStatus {
  initial,
  imagePicking,
  imageUploading,
  imageUploadError,
  imageUploaded,
  submittingRecord,
  submissionSuccess,
  submissionError,
}

class PaymentSubmissionState extends Equatable {
  final PaymentSubmissionStatus status;
  final File? pickedProofImageFile;
  final String? uploadedProofImageUrl;
  final String? operationMessage;

  const PaymentSubmissionState({
    this.status = PaymentSubmissionStatus.initial,
    this.pickedProofImageFile,
    this.uploadedProofImageUrl,
    this.operationMessage,
  });

  PaymentSubmissionState copyWith({
    PaymentSubmissionStatus? status,
    File? pickedProofImageFile,
    bool clearPickedImage = false,
    String? uploadedProofImageUrl,
    bool clearUploadedImageUrl = false,
    String? operationMessage,
    bool clearOperationMessage = false,
  }) {
    return PaymentSubmissionState(
      status: status ?? this.status,
      pickedProofImageFile:
          clearPickedImage
              ? null
              : pickedProofImageFile ?? this.pickedProofImageFile,
      uploadedProofImageUrl:
          clearUploadedImageUrl
              ? null
              : uploadedProofImageUrl ?? this.uploadedProofImageUrl,
      operationMessage:
          clearOperationMessage
              ? null
              : operationMessage ?? this.operationMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    pickedProofImageFile,
    uploadedProofImageUrl,
    operationMessage,
  ];
}
