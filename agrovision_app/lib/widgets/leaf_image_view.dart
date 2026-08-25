import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Cross-platform image view that safely handles File, Network URL, and null placeholders.
class LeafImageView extends StatelessWidget {
  final File? file;
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const LeafImageView({
    super.key,
    this.file,
    this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (file != null) {
      if (kIsWeb) {
        return Image.network(
          file!.path,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => _buildFallback(),
        );
      }

      return Image.file(
        file!,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF064E3B),
            Color(0xFF0F172A),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.eco_rounded,
        size: 56,
        color: Color(0xFF10B981),
      ),
    );
  }
}

