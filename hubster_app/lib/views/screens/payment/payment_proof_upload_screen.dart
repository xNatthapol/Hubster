import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/models/payment/payment_record.dart';
import 'package:hubster_app/viewmodels/auth_state_notifier.dart';
import 'package:hubster_app/viewmodels/payment_submission_notifier.dart';
import 'package:hubster_app/viewmodels/payment_submission_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:hubster_app/core/theme/app_colors.dart';

class PaymentProofUploadScreen extends ConsumerStatefulWidget {
  final String membershipId;
  final String hostedSubscriptionTitle;
  final String serviceProviderName;
  final String? serviceProviderLogoUrl;
  final double amountExpected;
  final String? hostPaymentQRCodeUrl;
  final DateTime? nextDueDate;

  const PaymentProofUploadScreen({
    super.key,
    required this.membershipId,
    required this.hostedSubscriptionTitle,
    required this.serviceProviderName,
    this.serviceProviderLogoUrl,
    required this.amountExpected,
    this.hostPaymentQRCodeUrl,
    this.nextDueDate,
  });

  @override
  ConsumerState<PaymentProofUploadScreen> createState() =>
      _PaymentProofUploadScreenState();
}

class _PaymentProofUploadScreenState
    extends ConsumerState<PaymentProofUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentMethodController = TextEditingController();
  final _transactionRefController = TextEditingController();

  File? _pickedProofImageFileLocalPreview;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _paymentMethodController.dispose();
    _transactionRefController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imageXFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (imageXFile != null) {
      setState(() {
        _pickedProofImageFileLocalPreview = File(imageXFile.path);
      });
      ref
          .read(paymentSubmissionNotifierProvider.notifier)
          .pickAndUploadProofImage(File(imageXFile.path));
    }
  }

  void _submitProof() {
    final notifier = ref.read(paymentSubmissionNotifierProvider.notifier);
    final currentState = ref.read(paymentSubmissionNotifierProvider);

    if (currentState.uploadedProofImageUrl == null ||
        currentState.uploadedProofImageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please choose and upload a payment receipt."),
        ),
      );
      return;
    }

    // Determine paymentCycleIdentifier from nextDueDate or current date
    String paymentCycleIdentifier;
    if (widget.nextDueDate != null) {
      paymentCycleIdentifier = DateFormat(
        'MMMM yyyy',
      ).format(widget.nextDueDate!);
    } else {
      paymentCycleIdentifier = DateFormat('MMMM yyyy').format(DateTime.now());
    }

    final request = CreatePaymentRecordRequest(
      paymentCycleIdentifier: paymentCycleIdentifier,
      amountPaid: widget.amountExpected,
      proofImageUrl: currentState.uploadedProofImageUrl!,
      paymentMethod:
          _paymentMethodController.text.trim().isNotEmpty
              ? _paymentMethodController.text.trim()
              : null,
      transactionReference:
          _transactionRefController.text.trim().isNotEmpty
              ? _transactionRefController.text.trim()
              : null,
    );

    notifier.submitPaymentRecord(widget.membershipId, request);
  }

  Widget _buildDetailRow(String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 15)),
          valueWidget,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentSubmissionNotifierProvider);
    final notifier = ref.read(paymentSubmissionNotifierProvider.notifier);
    final currentUser = ref.watch(authStateNotifierProvider).currentUser;

    final theme = Theme.of(context);

    ref.listen<PaymentSubmissionState>(paymentSubmissionNotifierProvider, (
      prev,
      next,
    ) {
      if (next.status == PaymentSubmissionStatus.submissionSuccess &&
          next.operationMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.operationMessage!),
            backgroundColor: Colors.green,
          ),
        );
        notifier.resetAll();
        Navigator.of(context).pop();
      } else if ((next.status == PaymentSubmissionStatus.submissionError ||
              next.status == PaymentSubmissionStatus.imageUploadError) &&
          next.operationMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.operationMessage!),
            backgroundColor: Colors.red,
          ),
        );
        notifier.clearMessage();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Payment Request")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Pending Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Payment Pending",
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment Details Section
            Text(
              "Payment Details",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              "Amount",
              Text(
                "\$${widget.amountExpected.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            _buildDetailRow(
              "Due Date",
              Text(
                widget.nextDueDate != null
                    ? DateFormat('MMM d, yyyy').format(widget.nextDueDate!)
                    : "N/A",
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            _buildDetailRow(
              "Subscription",
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.serviceProviderLogoUrl != null &&
                      widget.serviceProviderLogoUrl!.isNotEmpty)
                    Image.network(
                      widget.serviceProviderLogoUrl!,
                      width: 20,
                      height: 20,
                      errorBuilder: (c, e, s) => const SizedBox.shrink(),
                    ),
                  if (widget.serviceProviderLogoUrl != null &&
                      widget.serviceProviderLogoUrl!.isNotEmpty)
                    const SizedBox(width: 4),
                  Text(
                    widget.hostedSubscriptionTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            _buildDetailRow(
              "Payer",
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currentUser?.profilePictureUrl != null &&
                      currentUser!.profilePictureUrl!.isNotEmpty)
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                        currentUser.profilePictureUrl!,
                      ),
                      radius: 10,
                    )
                  else
                    CircleAvatar(
                      child: Icon(Icons.person, size: 12),
                      radius: 10,
                      backgroundColor: Colors.grey[300],
                    ),
                  const SizedBox(width: 8),
                  Text(
                    currentUser?.fullName ?? "You",
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Scan to Pay Section
            if (widget.hostPaymentQRCodeUrl != null &&
                widget.hostPaymentQRCodeUrl!.isNotEmpty) ...[
              Text(
                "Scan to Pay",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Image.network(
                    widget.hostPaymentQRCodeUrl!,
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (c, e, s) => const Text("Could not load QR code"),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Upload Payment Receipt Section
            Text(
              "Upload Payment receipt",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap:
                  (state.status == PaymentSubmissionStatus.imageUploading)
                      ? null
                      : _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(
                    color: Colors.grey[400]!,
                    width:
                        1.5 /*, style: BorderStyle.dashed - not directly supported*/,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Builder(
                  builder: (context) {
                    if (state.status == PaymentSubmissionStatus.imageUploading)
                      return const Center(child: CircularProgressIndicator());
                    // Show uploaded network image if available (after successful upload)
                    if (state.uploadedProofImageUrl != null &&
                        state.uploadedProofImageUrl!.isNotEmpty) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.network(
                          state.uploadedProofImageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (c, e, s) => const Center(
                                child: Text("Error loading preview"),
                              ),
                        ),
                      );
                    }
                    // Show locally picked file before upload for preview
                    if (_pickedProofImageFileLocalPreview != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(
                          _pickedProofImageFileLocalPreview!,
                          fit: BoxFit.contain,
                        ),
                      );
                    }
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 50,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Upload payment receipt",
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Support JPG, PNG or PDF, max 5MB",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _pickImage,
                          child: const Text("Choose File"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (state.status == PaymentSubmissionStatus.imageUploadError &&
                state.operationMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  state.operationMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed:
                    (state.status == PaymentSubmissionStatus.submittingRecord ||
                            state.status ==
                                PaymentSubmissionStatus.imageUploading)
                        ? null
                        : _submitProof,
                child:
                    (state.status == PaymentSubmissionStatus.submittingRecord)
                        ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : const Text(
                          "Submit Payment receipt",
                          style: TextStyle(fontSize: 18),
                        ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
