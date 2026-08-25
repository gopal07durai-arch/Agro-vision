import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import '../core/constants/app_config.dart';
import '../models/api_error.dart';

/// Handles image selection (camera/gallery), EXIF orientation correction,
/// validation, and JPEG compression before upload.
class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final _picker = ImagePicker();
  static final Map<String, Uint8List> _bytesCache = {};

  /// Safely reads the binary bytes of an image file across Native and Web platforms.
  static Future<Uint8List> readFileBytes(File file) async {
    if (kIsWeb) {
      final cached = _bytesCache[file.path];
      if (cached != null && cached.isNotEmpty) return cached;
      try {
        if (file.path.startsWith('blob:') || file.path.startsWith('http')) {
          final res = await http.get(Uri.parse(file.path));
          if (res.statusCode == 200) {
            _bytesCache[file.path] = res.bodyBytes;
            return res.bodyBytes;
          }
        }
      } catch (_) {}
    }
    return await file.readAsBytes();
  }

  /// Pick image from the device photo gallery.
  /// Returns null if the user cancels.
  Future<File?> pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // We compress ourselves below
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (picked == null) return null;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        _bytesCache[picked.path] = bytes;
      }
      return File(picked.path);
    } catch (_) {
      return null;
    }
  }

  /// Capture image from the rear camera.
  /// Returns null if the user cancels.
  Future<File?> captureFromCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        maxWidth: 2048,
        maxHeight: 2048,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) return null;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        _bytesCache[picked.path] = bytes;
      }
      return File(picked.path);
    } catch (_) {
      return null;
    }
  }

  /// Validate file size + format, then compress to JPEG.
  ///
  /// Throws [ApiError] if:
  ///   - File is too large (> 10MB before compression)
  ///   - Extension is not JPG, PNG, or WebP
  ///
  /// Returns the compressed [File] (or original if compression fails).
  Future<File> validateAndCompress(File originalFile) async {
    if (kIsWeb) {
      return originalFile;
    }

    // 1. Check raw file size
    final sizeBytes = await originalFile.length();
    if (sizeBytes > AppConfig.maxImageSizeBytes) {
      throw ApiError(
        type: ApiErrorType.invalidImage,
        message:
            'Image is too large (${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB). '
            'Maximum allowed size is 10 MB.',
      );
    }

    // 2. Check extension
    final ext = p.extension(originalFile.path).toLowerCase();
    if (!{'.jpg', '.jpeg', '.png', '.webp'}.contains(ext)) {
      throw const ApiError(
        type: ApiErrorType.invalidImage,
        message: 'Unsupported image format. Please use JPG, PNG, or WebP.',
      );
    }

    // 3. Compress + fix EXIF orientation
    final compressed = await _compress(originalFile);
    return compressed ?? originalFile;
  }

  Future<File?> _compress(File file) async {
    if (kIsWeb) return null;
    try {
      final tempDir = await getTemporaryDirectory();
      final outPath = p.join(
          tempDir.path,
          'agrovision_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        minWidth: 100,
        minHeight: 100,
        quality: AppConfig.imageQuality,
        format: CompressFormat.jpeg,
        // keepExif=false ensures orientation is baked into pixels,
        // fixing the "rotated leaf" issue on mobile camera captures.
        keepExif: false,
      );

      if (result == null) return null;
      return File(result.path);
    } catch (_) {
      // Compression failure is non-fatal — use original file
      return null;
    }
  }

  /// Read an image file as bytes (for API upload).
  Future<Uint8List> readAsBytes(File file) => file.readAsBytes();

  /// Get image file size in human-readable format.
  Future<String> getFileSizeString(File file) async {
    try {
      final bytes = kIsWeb ? (await file.readAsBytes()).length : await file.length();
      if (bytes < 1024) return '${bytes}B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '';
    }
  }
}
