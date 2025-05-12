import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/models/catalog/subscription_service.dart';
import 'package:hubster_app/models/subscriptions/hosted_subscription.dart';
import 'package:hubster_app/viewmodels/create_subscription_state.dart';
import 'package:hubster_app/viewmodels/create_subscription_notifier.dart';
import 'package:hubster_app/viewmodels/main_screen_tab_notifier.dart';
import 'package:hubster_app/viewmodels/home_screen_providers.dart';
import 'package:image_picker/image_picker.dart';

// Screen for hosts to create a new subscription offering.
class CreateSubscriptionScreen extends ConsumerStatefulWidget {
  const CreateSubscriptionScreen({super.key});

  @override
  ConsumerState<CreateSubscriptionScreen> createState() =>
      _CreateSubscriptionScreenState();
}

class _CreateSubscriptionScreenState
    extends ConsumerState<CreateSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _costPerCycleController = TextEditingController();

  SubscriptionService? _selectedSubscriptionService;
  BillingCycleType _selectedBillingCycle = BillingCycleType.Monthly;
  File? _pickedQrImageFile;
  int _numberOfMembers = 2;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _costPerCycleController.dispose();
    super.dispose();
  }

  // Handles image selection for QR code and triggers upload via notifier.
  Future<void> _pickAndUploadQrCode() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imageXFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (imageXFile != null) {
      setState(() {
        _pickedQrImageFile = File(imageXFile.path);
      });
      // Call notifier to handle the upload and update state with URL
      await ref
          .read(createSubscriptionNotifierProvider.notifier)
          .uploadQrCode(File(imageXFile.path));
    }
  }

  void _resetLocalFormFields() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _costPerCycleController.clear();
    setState(() {
      _selectedSubscriptionService = null;
      _pickedQrImageFile = null;
      _numberOfMembers = 2;
      _selectedBillingCycle = BillingCycleType.Monthly;
    });
  }

  // Validates form and submits data to create the subscription.
  void _submitForm() {
    final createNotifier = ref.read(
      createSubscriptionNotifierProvider.notifier,
    );
    createNotifier.clearOperationMessage();

    if (_formKey.currentState!.validate()) {
      if (_selectedSubscriptionService == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a service provider."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final currentCreateState = ref.read(createSubscriptionNotifierProvider);
      if (currentCreateState.uploadedQrCodeUrl == null ||
          currentCreateState.uploadedQrCodeUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please upload a payment QR code."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final request = CreateHostedSubscriptionRequest(
        subscriptionServiceId: _selectedSubscriptionService!.id,
        subscriptionTitle: _titleController.text.trim(),
        totalSlots: _numberOfMembers,
        costPerCycle:
            double.tryParse(_costPerCycleController.text.trim()) ?? 0.0,
        billingCycle: _selectedBillingCycle,
        paymentQRCodeUrl: currentCreateState.uploadedQrCodeUrl,
      );

      createNotifier.submitHostedSubscription(request).then((success) {
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Subscription created successfully!"),
              backgroundColor: Colors.green,
            ),
          );

          createNotifier.resetFormState();
          _resetLocalFormFields();

          // Change tab in MainScreen to Home (index 0)
          ref.read(mainScreenTabNotifierProvider.notifier).changeTab(0);

          // Invalidate HomeScreen's data provider to trigger a refresh
          ref.invalidate(myHostedSubscriptionsProvider);
          print(
            "CREATE_SUBSCRIPTION_SCREEN: Switched to Home tab and invalidated hosted subscriptions provider.",
          );
        }
      });
    }
  }

  // Helper to build consistent section titles.
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createSubscriptionNotifierProvider);
    final pageNotifier = ref.read(createSubscriptionNotifierProvider.notifier);

    // Listen for error messages to show in a SnackBar.
    ref.listen<int>(mainScreenTabNotifierProvider, (prevIndex, nextIndex) {
      if (prevIndex == 2 &&
          nextIndex != 2 &&
          state.status != CreateSubscriptionStatus.success) {}
      if (nextIndex == 2 && prevIndex != 2 && prevIndex != null) {
        print(
          "CreateSubscriptionScreen: Tab switched to Create. Resetting form.",
        );
        pageNotifier.resetFormState();
        _resetLocalFormFields();
      }
    });

    // Error SnackBar listener
    ref.listen<CreateSubscriptionState>(createSubscriptionNotifierProvider, (
      previous,
      next,
    ) {
      if (next.status == CreateSubscriptionStatus.error &&
          next.operationMessage != null &&
          !next.operationMessage!.contains("QR")) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.operationMessage!)));
        pageNotifier.clearOperationMessage();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Create Subscription")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildSectionTitle(context, "Subscription Title"),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: "Enter subscription Title",
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required.';
                  }
                  if (value.trim().length < 3) return 'Title is too short.';
                  return null;
                },
              ),

              _buildSectionTitle(context, "Service Provider"),
              if (state.status == CreateSubscriptionStatus.loadingServices)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (state.availableServices.isEmpty &&
                  state.status != CreateSubscriptionStatus.initial &&
                  state.status != CreateSubscriptionStatus.loadingServices)
                const Center(
                  child: Text("Could not load services. Please try again."),
                )
              else
                DropdownButtonFormField<SubscriptionService>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Select service",
                  ),
                  value: _selectedSubscriptionService,
                  isExpanded: true,
                  items:
                      state.availableServices.map((
                        SubscriptionService service,
                      ) {
                        return DropdownMenuItem<SubscriptionService>(
                          value: service,
                          child: Row(
                            children: [
                              if (service.logoUrl != null &&
                                  service.logoUrl!.isNotEmpty) ...[
                                Image.network(
                                  service.logoUrl!,
                                  width: 24,
                                  height: 24,
                                  errorBuilder:
                                      (c, e, s) => const Icon(
                                        Icons.broken_image,
                                        size: 24,
                                      ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: Text(
                                  service.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (SubscriptionService? newValue) {
                    setState(() {
                      _selectedSubscriptionService = newValue;
                    });
                  },
                  validator:
                      (value) =>
                          value == null ? 'Please select a service.' : null,
                ),

              _buildSectionTitle(context, "Number of Members"),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.6),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.remove_rounded,
                        color:
                            _numberOfMembers >
                                    2 // Minimum 2 members (host + 1)
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[400],
                      ),
                      onPressed:
                          _numberOfMembers > 2
                              ? () => setState(() => _numberOfMembers--)
                              : null,
                      iconSize: 28,
                      splashRadius: 24,
                      padding: const EdgeInsets.all(12),
                    ),
                    // Display for the current number of members
                    Text(
                      '$_numberOfMembers',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_rounded,
                        color:
                            _numberOfMembers < 20
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[400],
                      ),
                      onPressed:
                          _numberOfMembers < 20
                              ? () => setState(() => _numberOfMembers++)
                              : null,
                      iconSize: 28,
                      splashRadius: 24,
                      padding: const EdgeInsets.all(12),
                    ),
                  ],
                ),
              ),

              // Section title for Billing Cycle
              _buildSectionTitle(context, "Billing Cycle"),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<BillingCycleType>(
                  segments: <ButtonSegment<BillingCycleType>>[
                    // Monthly Button Segment
                    ButtonSegment<BillingCycleType>(
                      value: BillingCycleType.Monthly,
                      label: Text(
                        'Monthly',
                        style: TextStyle(
                          color:
                              _selectedBillingCycle == BillingCycleType.Monthly
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).textTheme.bodyLarge?.color
                                      ?.withOpacity(0.7),
                          fontWeight:
                              _selectedBillingCycle == BillingCycleType.Monthly
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ),
                    // Annually Button Segment
                    ButtonSegment<BillingCycleType>(
                      value: BillingCycleType.Annually,
                      label: Text(
                        'Annually',
                        style: TextStyle(
                          color:
                              _selectedBillingCycle == BillingCycleType.Annually
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).textTheme.bodyLarge?.color
                                      ?.withOpacity(0.7),
                          fontWeight:
                              _selectedBillingCycle == BillingCycleType.Annually
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                  selected: <BillingCycleType>{_selectedBillingCycle},
                  onSelectionChanged: (Set<BillingCycleType> newSelection) {
                    setState(() {
                      _selectedBillingCycle = newSelection.first;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color?>((
                      Set<MaterialState> states,
                    ) {
                      if (states.contains(MaterialState.selected)) {
                        return Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.12);
                      }
                      return Colors.transparent;
                    }),
                    side: MaterialStateProperty.resolveWith<BorderSide?>((
                      Set<MaterialState> states,
                    ) {
                      if (states.contains(MaterialState.selected)) {
                        return BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                          width: 1.0,
                        );
                      }
                      return BorderSide(color: Colors.grey[400]!, width: 1.0);
                    }),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                  showSelectedIcon: false,
                ),
              ),
              _buildSectionTitle(context, "Cost per Cycle"),
              TextFormField(
                controller: _costPerCycleController,
                decoration: const InputDecoration(
                  hintText: "0.00",
                  prefixText: "\$ ",
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Cost is required.';
                  final c = double.tryParse(value);
                  if (c == null) return 'Invalid amount.';
                  if (c <= 0) return 'Cost must be positive.';
                  return null;
                },
              ),

              _buildSectionTitle(context, "Payment QR Code"),
              GestureDetector(
                onTap:
                    (state.status == CreateSubscriptionStatus.uploadingQR)
                        ? null
                        : _pickAndUploadQrCode,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey[400]!,
                      width: 1.0,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                  ),
                  child:
                      state.status == CreateSubscriptionStatus.uploadingQR
                          ? const Center(child: CircularProgressIndicator())
                          : state.uploadedQrCodeUrl != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(7.0),
                            child: Image.network(
                              state.uploadedQrCodeUrl!,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (c, e, s) => const Center(
                                    child: Text("Error loading QR"),
                                  ),
                            ),
                          )
                          : _pickedQrImageFile != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(7.0),
                            child: Image.file(
                              _pickedQrImageFile!,
                              fit: BoxFit.contain,
                            ),
                          )
                          : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Upload QR Code",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
              if (state.status == CreateSubscriptionStatus.error &&
                  state.operationMessage != null &&
                  state.operationMessage!.contains("QR Upload Failed"))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    state.operationMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      (state.status == CreateSubscriptionStatus.submitting ||
                              state.status ==
                                  CreateSubscriptionStatus.uploadingQR)
                          ? null
                          : _submitForm,
                  child:
                      (state.status == CreateSubscriptionStatus.submitting ||
                              state.status ==
                                  CreateSubscriptionStatus.uploadingQR)
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            "Create Subscription",
                            style: TextStyle(fontSize: 18),
                          ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
