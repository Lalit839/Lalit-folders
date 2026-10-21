import 'package:flutter/material.dart';

class VenueImageItem extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onTap;

  const VenueImageItem({
    super.key,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          image: DecorationImage(
            image: imageUrl.startsWith('http')
                ? NetworkImage(imageUrl) as ImageProvider
                : AssetImage(imageUrl),
            fit: BoxFit.cover))));
  }
}
