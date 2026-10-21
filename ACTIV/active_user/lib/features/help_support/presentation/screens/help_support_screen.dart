import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_header.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:activ_user_app/shared/widgets/inputs/app_input_field.dart';
import 'package:activ_user_app/shared/widgets/custom_button.dart';
import 'package:activ_user_app/core/network/activ_api_client.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _toController = TextEditingController(
    text: 'support@activ.live',
  );
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  bool _messageSent = false;

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_messageSent) {
      return _buildSuccessScreen(context);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Help & Support'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.medium(
                "We're Here To Help!",
                color: AppColors.textPrimary,
                fontSize: 22,
              ),
              const SizedBox(height: 2),
              AppText.small(
                "Send us an email and we'll get back to you\nas soon as possible",
                color: AppColors.grey99,
                fontSize: 16,
              ),
              const SizedBox(height: 24),

              // "To" Field
              AppInpuField(
                controller: _toController,
                labelText: 'To*',
                hintText: '',
                readOnly: true, // makes it uneditable
                enabled: false, // dims the text color
              ),
              const SizedBox(height: 6),
              AppText.medium(
                'This is our official support email address.',
                color: AppColors.grey99,
                fontSize: 10,
              ),
              const SizedBox(height: 16),

              // "Subject" Field
              AppInpuField(
                controller: _subjectController,
                labelText: 'Subject*',
                hintText: 'Enter subject here',
              ),
              const SizedBox(height: 16),

              // "Message" Field
              AppInpuField(
                controller: _messageController,
                labelText: 'Message*',
                hintText: 'Type your message here...',
                maxLines: 6,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 40),

              // Send Button
              CustomButton(
                text: 'Send',
                iconRight: true,
                backgroundColor: AppColors.lightGrey,
                foregroundColor: AppColors.primary,
                icon: AppSvg(
                  AppAssets.thickArrowRight,
                  color: AppColors.primary,
                  height: 24,
                  width: 24,
                ),
                onPressed: _isSending ? null : _submitSupportMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitSupportMessage() async {
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject')),
      );
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _isSending = true);
    try {
      await ActivApiClient.instance.createSupportTicket(
        subject: _subjectController.text,
        message: _messageController.text,
      );
      if (!mounted) return;
      _subjectController.clear();
      _messageController.clear();
      setState(() => _messageSent = true);
    } on ActivApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _buildSuccessScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 64),
              const AppSvg(AppAssets.success, width: 132, height: 132),
              const SizedBox(height: 32),
              AppText.bold(
                'Message Sent!',
                color: AppColors.textPrimary,
                fontSize: 24,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              AppText.small(
                'Thanks for reaching out. Our support\nteam will get back to you as soon as\npossible.',
                color: AppColors.grey99,
                fontSize: 16,
                height: 1.35,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              CustomButton(
                text: 'Done',
                backgroundColor: AppColors.lightGrey,
                foregroundColor: AppColors.primary,
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                    return;
                  }

                  setState(() => _messageSent = false);
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
