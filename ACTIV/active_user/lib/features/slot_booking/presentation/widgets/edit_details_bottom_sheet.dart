import 'package:activ_user_app/shared/widgets/app_divider.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/buttons/app_button.dart';
import 'package:activ_user_app/shared/widgets/inputs/app_input_field.dart';
import 'package:activ_user_app/shared/widgets/app_bottom_sheet.dart';

class EditDetailsBottomSheet extends StatefulWidget {
  final String initialFirstName;
  final String initialLastName;
  final String initialPhone;

  const EditDetailsBottomSheet({
    super.key,
    required this.initialFirstName,
    required this.initialLastName,
    required this.initialPhone,
  });

  static Future<({String firstName, String lastName, String phone})?> show(
    BuildContext context, {
    required String firstName,
    required String lastName,
    required String phone,
  }) {
    return showAppBottomSheet(
      context: context,
      title: 'Edit your details',
      child: EditDetailsBottomSheet(initialFirstName: firstName, initialLastName: lastName, initialPhone: phone),
    );
  }

  @override
  State<EditDetailsBottomSheet> createState() => _EditDetailsBottomSheetState();
}

class _EditDetailsBottomSheetState extends State<EditDetailsBottomSheet> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.initialFirstName);
    _lastNameController = TextEditingController(text: widget.initialLastName);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInpuField(
            controller: _firstNameController,
            hintText: 'Sumit',
            labelText: 'First Name*',
          ),
          const SizedBox(height: 12),
          AppInpuField(
            controller: _lastNameController,
            hintText: 'Patel',
            labelText: 'Last Name*',
          ),
          const SizedBox(height: 12),
          AppInpuField(
            controller: _phoneController,
            hintText: '+91 12345-67890',
            labelText: 'Phone Number*',
          ),

          AppDivider(verticalPadding: 24),
          AppText(
            'Information mentioned above will be used for generating the invoice and sending out the tickets.',
            color: AppColors.greyBorder,
            height: 1.4,
          ),
          const SizedBox(height: 40),
          AppButton(
            title: 'Save',
            textColor: AppColors.yellowColor,
            backgroundColor: AppColors.blackColor2,
            onTap: () {
              final firstName = _firstNameController.text.trim();
              final lastName = _lastNameController.text.trim();
              if (firstName.isEmpty && lastName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your name.')),
                );
                return;
              }
              Navigator.pop(
                context,
                (
                  firstName: firstName,
                  lastName: lastName,
                  phone: widget.initialPhone,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
