import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Cross-platform image view that safely handles File on Web and Mobile/Desktop.
class LeafImageView extends StatelessWidget {
  final File file;
  final BoxFit fit;
  final double? width;
  final double? height;

  const LeafImageView({
    super.key,
    required this.file,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        file.path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFF1E293B),
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_outlined,
              size: 40,
              color: Colors.white54,
            ),
          );
        },
      );
    }

    return Image.file(
      file,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFF1E293B),
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: Colors.white54,
          ),
        );
      },
    );
  }
}
