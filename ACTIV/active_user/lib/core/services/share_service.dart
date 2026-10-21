import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareService {
  String buildVenueShareMessage({
    required String name,
    required String sports,
    required String venueUrl,
  }) {
    return 'Check out $name on ACTIV.\n\n$sports\n\nBook now:\n$venueUrl';
  }

  Future<void> copyVenueLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
  }

  Future<void> shareVenue(String content) async {
    await SharePlus.instance.share(ShareParams(text: content));
  }

  Future<void> shareVenueOnWhatsApp(String content, {VoidCallback? onWhatsAppNotInstalled}) async {
    final Uri whatsappUrl = Uri.parse("whatsapp://send?text=${Uri.encodeComponent(content)}");
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      debugPrint('Could not launch WhatsApp');
      onWhatsAppNotInstalled?.call();
    }
  }
}
