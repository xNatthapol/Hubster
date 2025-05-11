import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/core/di/service_locator.dart';
import 'package:hubster_app/models/auth/user.dart';
import 'package:hubster_app/models/user/update_user_request.dart';
import 'package:hubster_app/services/upload_service.dart';
import 'package:hubster_app/viewmodels/auth_state_notifier.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phone_form_field/phone_form_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final User currentUser;
  const EditProfileScreen({super.key, required this.currentUser});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;

  // This will be the initial value for PhoneFormField.
  PhoneNumber? _fieldInitialPhoneNumber;
  // This holds the actual current PhoneNumber object from user input.
  PhoneNumber? _currentPhoneNumber;

  String? _currentProfileImageUrl;
  File? _pickedImageFile;
  bool _isUploadingImage = false;
  bool _isUpdatingProfile = false;

  // Define default country code
  static const IsoCode defaultIsoCode = IsoCode.TH;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.currentUser.fullName,
    );
    _currentProfileImageUrl = widget.currentUser.profilePictureUrl;

    if (widget.currentUser.phoneNumber != null &&
        widget.currentUser.phoneNumber!.isNotEmpty) {
      try {
        _fieldInitialPhoneNumber = PhoneNumber.parse(
          widget.currentUser.phoneNumber!,
        );
        _currentPhoneNumber = _fieldInitialPhoneNumber;
      } catch (e) {
        print(
          "EditProfileScreen: Error parsing initial phone number '${widget.currentUser.phoneNumber}': $e",
        );
        _fieldInitialPhoneNumber = const PhoneNumber(
          isoCode: defaultIsoCode,
          nsn: '',
        );
        _currentPhoneNumber = null;
      }
    } else {
      // No existing phone number, so initialize PhoneFormField with the default country and empty number.
      _fieldInitialPhoneNumber = const PhoneNumber(
        isoCode: defaultIsoCode,
        nsn: '',
      );
      _currentPhoneNumber = null;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imageXFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (imageXFile == null) return;
    setState(() {
      _pickedImageFile = File(imageXFile.path);
      _currentProfileImageUrl = null;
      _isUploadingImage = true;
    });
    try {
      final uploadService = getIt<UploadService>();
      final newImageUrl = await uploadService.uploadImage(_pickedImageFile!);
      setState(() {
        _currentProfileImageUrl = newImageUrl;
        _pickedImageFile = null;
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image ready."),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _pickedImageFile = null;
          _currentProfileImageUrl = widget.currentUser.profilePictureUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Image upload failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitUpdateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isUploadingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please wait for image upload.")),
      );
      return;
    }
    setState(() {
      _isUpdatingProfile = true;
    });

    final String? phoneNumberE164 = _currentPhoneNumber?.international;

    final request = UpdateUserRequest(
      fullName: _fullNameController.text.trim(),
      phoneNumber:
          (phoneNumberE164 != null && phoneNumberE164.isNotEmpty)
              ? phoneNumberE164
              : null, // Send null if effectively empty
      profilePictureUrl: _currentProfileImageUrl,
    );

    final success = await ref
        .read(authStateNotifierProvider.notifier)
        .updateUserProfile(request);

    if (!mounted) return;
    setState(() {
      _isUpdatingProfile = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authStateNotifierProvider).operationMessage ??
                "Failed to update profile.",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProfileImage() {
    ImageProvider? imageProvider;
    if (_pickedImageFile != null) {
      imageProvider = FileImage(_pickedImageFile!);
    } else if (_currentProfileImageUrl != null &&
        _currentProfileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_currentProfileImageUrl!);
    }
    return CircleAvatar(
      radius: 60,
      backgroundImage: imageProvider,
      child: imageProvider == null ? const Icon(Icons.person, size: 60) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _buildProfileImage(),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withOpacity(0.8),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).primaryColor,
                      child:
                          _isUploadingImage
                              ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: _pickAndUploadImage,
                                tooltip: "Change profile picture",
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full name cannot be empty';
                  }
                  if (value.trim().length < 2) return 'Full name too short';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: widget.currentUser.email,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                readOnly: true,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),

              // Phone Number using PhoneFormField
              PhoneFormField(
                initialValue: _fieldInitialPhoneNumber,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                countrySelectorNavigator:
                    const CountrySelectorNavigator.bottomSheet(),
                countryButtonStyle: const CountryButtonStyle(
                  showFlag: true,
                  flagSize: 16,
                  showDialCode: true,
                ),
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (PhoneNumber? phoneNumber) {
                  setState(() {
                    // Only update if it's a valid number or if it's being cleared
                    if (phoneNumber == null ||
                        phoneNumber.nsn.isEmpty ||
                        phoneNumber.isValid()) {
                      _currentPhoneNumber = phoneNumber;
                    }
                    // } else {
                    //   _currentPhoneNumber = null;
                    // }
                  });
                  // print(
                  //   'EditProfileScreen: Phone changed to: ${phoneNumber?.international}, IsValid: ${phoneNumber?.isValid()}',
                  // );
                },
                validator: (PhoneNumber? phoneNumber) {
                  if (phoneNumber == null || phoneNumber.nsn.isEmpty) {
                    return null;
                  }
                  if (!phoneNumber.isValid()) {
                    return 'Invalid phone number format';
                  }
                  return null;
                },
                autofillHints: const [AutofillHints.telephoneNumber],
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed:
                    (_isUpdatingProfile || _isUploadingImage)
                        ? null
                        : _submitUpdateProfile,
                child:
                    (_isUpdatingProfile || _isUploadingImage)
                        ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                        : const Text("Confirm", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
