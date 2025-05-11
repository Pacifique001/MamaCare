// lib/presentation/screen/edit_profile_screen.dart
import 'dart:io'; // Required for File

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Use for network image
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

// Import ViewModels and Entities
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';
import 'package:mama_care/domain/entities/user_model.dart';
// Import Utils and Widgets
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart'; // Optional AppBar
import 'package:mama_care/injection.dart';
import 'package:sizer/sizer.dart'; // For Logger

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(); // Keep for display, maybe disable editing
  final _phoneController = TextEditingController();
  // Removed password controller - handle separately

  String? _initialProfileImageUrl; // Store the initial URL
  String? _localImageFilePath; // Store path of newly selected image
  bool _imageChanged = false; // Flag to track if image was picked

  final Logger _logger = locator<Logger>();

  @override
  void initState() {
    super.initState();
    // Load initial data from AuthViewModel after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  // Load data from AuthViewModel
  void _loadUserData() {
    // Use read here as it's for initial setup
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.localUser;

    if (currentUser != null) {
      _nameController.text = currentUser.name;
      // Email editing is complex due to verification, often disabled or handled separately
      _emailController.text = currentUser.email;
      _phoneController.text = currentUser.phoneNumber ?? '';
      _initialProfileImageUrl = currentUser.profileImageUrl; // Store initial URL
      if (mounted) {
          setState(() {}); // Update UI if profile image URL exists initially
      }
    } else {
       _logger.e("EditProfileScreen: Cannot load user data, user is null in AuthViewModel.");
       // Show error and potentially pop screen
        if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to load user data. Please try again."), backgroundColor: Colors.red),
            );
            Navigator.maybePop(context); // Try to pop if possible
        }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the AuthViewModel's loading state
    final isLoading = context.watch<AuthViewModel>().isLoading;

    // Determine which image source to use (new local file or initial network URL)
    ImageProvider? displayImage;
    if (_localImageFilePath != null) {
       displayImage = FileImage(File(_localImageFilePath!)); // Display selected local image
    } else if (_initialProfileImageUrl != null) {
       displayImage = CachedNetworkImageProvider(_initialProfileImageUrl!); // Display network image
    }

    return Scaffold(
      appBar: MamaCareAppBar( // Use custom AppBar if available
        title: 'Edit Profile',
        // Optional: Add actions like 'Cancel'
        // actions: [ TextButton(...) ]
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0), // Increased padding
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Center avatar
            children: [
              // --- Profile Picture ---
              InkWell( // Use InkWell for ripple effect
                onTap: isLoading ? null : _pickImage, // Disable tap while loading
                customBorder: const CircleBorder(),
                child: Stack( // Stack to overlay edit icon
                   alignment: Alignment.bottomRight,
                   children: [
                      CircleAvatar(
                        radius: 55, // Slightly larger avatar
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: displayImage, // Use determined image provider
                        child: displayImage == null
                            ? Icon(Icons.person_outline, size: 60, color: Colors.grey.shade600)
                            : null,
                      ),
                      Container(
                         padding: const EdgeInsets.all(4),
                         decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5)
                         ),
                         child: const Icon(Icons.edit, size: 18, color: Colors.white),
                      )
                   ],
                ),
              ),
              if (_imageChanged) // Show remove button only if image was changed
                 TextButton.icon(
                     icon: Icon(Icons.clear, size: 16, color: Colors.red.shade600),
                     label: Text("Revert Image", style: TextStyle(color: Colors.red.shade600, fontSize: 10.sp)),
                     onPressed: isLoading ? null : () {
                         setState(() {
                            _localImageFilePath = null;
                            _imageChanged = false;
                         });
                     },
                 ),
              const SizedBox(height: 30),

              // --- Name ---
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Name', Icons.person_outline),
                textCapitalization: TextCapitalization.words,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),

              // --- Email (Display Only or Handle Carefully) ---
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('Email', Icons.email_outlined).copyWith(
                  // Hint text to discourage editing or indicate process
                  // hintText: "Changing email requires re-verification",
                  // hintStyle: TextStyle(fontSize: 10.sp, color: Colors.orange.shade700)
                ),
                keyboardType: TextInputType.emailAddress,
                // Consider making read-only or adding complex validation/flow for change
                readOnly: true, // ** Recommended to make read-only **
                 style: TextStyle(color: Colors.grey.shade600), // Indicate read-only
                validator: (value) {
                  // Basic validation even if read-only
                  if (value == null || value.isEmpty) return 'Email cannot be empty';
                  if (!_isValidEmail(value)) return 'Invalid email format';
                  return null;
                },
              ),
               if (!context.read<AuthViewModel>().isEmailVerified) // Show verification reminder
                 Padding(
                    padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                    child: Text("Email not verified", style: TextStyle(color: Colors.orange.shade800, fontSize: 10.sp)),
                 ),

              const SizedBox(height: 16),

              // --- Phone Number ---
              TextFormField(
                controller: _phoneController,
                decoration: _inputDecoration('Phone Number (Optional)', Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                // Optional: Add phone number validation
                // validator: (value) { ... }
              ),
              const SizedBox(height: 30), // Increased spacing

              // --- Save Button ---
              ElevatedButton(
                onPressed: isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Use theme color
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: TextStyles.buttonText, // Use defined text style
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(double.infinity, 50) // Make button wider
                ),
                child: isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                  : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for consistent InputDecoration
  InputDecoration _inputDecoration(String label, IconData icon) {
     return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(10),
           borderSide: const BorderSide(color: AppColors.primary, width: 1.5)
        ),
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
        contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0) // Adjust padding
     );
  }

  // Basic Email Validator
   bool _isValidEmail(String email) {
     return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)+$")
         .hasMatch(email);
   }

  /// Handles picking an image from the gallery.
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
       final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70 // Compress image slightly
       );
       if (image != null && mounted) {
         setState(() {
           _localImageFilePath = image.path; // Store local path
           _imageChanged = true; // Set flag
         });
       }
    } catch (e) {
       _logger.e("Error picking image", error: e);
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.redAccent),
          );
       }
    }
  }

  /// Validates the form and calls the ViewModel to update the profile.
  void _updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      _logger.d("Form validated, attempting profile update.");

      // Use context.read for the action
      final authViewModel = context.read<AuthViewModel>();

      // Show loading indicator (managed by ViewModel state now)
      // setState(() => _isLoading = true); // Removed, rely on VM state

      final result = await authViewModel.updateUserProfile(
        name: _nameController.text,
        email: _emailController.text, // Pass email (VM warns about change complexity)
        phoneNumber: _phoneController.text,
        localImageFilePath: _imageChanged ? _localImageFilePath : null, // Pass path only if changed
      );

      // Check result after await
      if (!mounted) return;

      if (result['status'] == 'success') {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Profile updated successfully'), backgroundColor: Colors.green),
         );
         Navigator.pop(context); // Go back on success
      } else {
         // Error message is set within ViewModel and shown via _handleAuthError
         // We can show it again here if desired, or rely on VM state changes
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to update profile.'), backgroundColor: Colors.redAccent),
         );
      }

      // Loading state is managed by the ViewModel based on the update process
      // setState(() => _isLoading = false); // Removed
    } else {
       _logger.w("Form validation failed.");
    }
  }
}