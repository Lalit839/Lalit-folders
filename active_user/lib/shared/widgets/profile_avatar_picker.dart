import 'dart:io';
import 'dart:convert';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/storage/shared_pref_service.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';

class ProfileAvatarPicker extends StatefulWidget {
  final double size;
  final ValueChanged<File?>? onImageChanged;

  const ProfileAvatarPicker({super.key, this.size = 86, this.onImageChanged});

  @override
  State<ProfileAvatarPicker> createState() => _ProfileAvatarPickerState();
}

class _ProfileAvatarPickerState extends State<ProfileAvatarPicker> {
  File? _selectedImage;
  String? _savedBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _savedBase64 = SharedPrefService.profilePhotoBase64;
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);

    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (image == null) return;

    final CroppedFile? croppedImage = await ImageCropper().cropImage(
      sourcePath: image.path,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: const Color(0xFF1A1A1A),
          toolbarWidgetColor: Colors.white,
          backgroundColor: const Color(0xFF1A1A1A),
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: true,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          cropStyle: CropStyle.circle,
          aspectRatioLockEnabled: true,
          resetButtonHidden: true,
        ),
      ],
    );

    if (croppedImage == null) return;

    final bytes = await File(croppedImage.path).readAsBytes();
    final base64 = base64Encode(bytes);
    await SharedPrefService.setProfilePhotoBase64(base64);

    if (!mounted) return;
    setState(() {
      _selectedImage = File(croppedImage.path);
      _savedBase64 = base64;
    });

    widget.onImageChanged?.call(_selectedImage);
  }

  void _removeImage() {
    Navigator.pop(context);

    SharedPrefService.setProfilePhotoBase64(null);

    setState(() {
      _selectedImage = null;
      _savedBase64 = null;
    });

    widget.onImageChanged?.call(null);
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetItem(
                  icon: Icons.camera_alt_outlined,
                  title: 'Take Photo',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _sheetItem(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                if (_selectedImage != null)
                  _sheetItem(
                    icon: Icons.delete_outline,
                    title: 'Remove Photo',
                    color: Colors.redAccent,
                    onTap: _removeImage,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontSize: 15)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showImagePickerSheet,
      child: Column(
        children: [
          CircleAvatar(
            radius: widget.size / 2,
            backgroundColor: AppColors.lightGrey,
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : (_savedBase64 != null && _savedBase64!.isNotEmpty)
                ? MemoryImage(base64Decode(_savedBase64!))
                : null,
            child: _selectedImage == null && (_savedBase64 == null || _savedBase64!.isEmpty)
                ? AppSvg(
                    AppAssets.navProfile,
                    width: 70,
                    height: 70,
                    color: Colors.grey,
                  )
                : null,
          ),
          const SizedBox(height: 12),

          AppText.medium(
            'Change Profile Photo',
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}
