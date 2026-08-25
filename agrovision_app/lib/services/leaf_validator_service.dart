import 'package:image/image.dart' as img;

/// Validation error types matching backend error specifications
enum LeafValidationError {
  none,
  lowImageQuality,
  notLeaf,
}

class LeafValidationResult {
  final bool isValid;
  final LeafValidationError errorType;
  final String errorMessage;
  final double greenRatio;
  final double skinRatio;
  final double lowSatRatio;

  const LeafValidationResult({
    required this.isValid,
    this.errorType = LeafValidationError.none,
    this.errorMessage = '',
    this.greenRatio = 0.0,
    this.skinRatio = 0.0,
    this.lowSatRatio = 0.0,
  });

  static const LeafValidationResult valid = LeafValidationResult(isValid: true);
}

/// Pure Dart Leaf Validator
/// Performs robust image quality assessment and non-leaf (OOD) filtering
/// to prevent random crop/disease predictions on cars, persons, buildings, roads, etc.
class LeafValidatorService {
  LeafValidatorService._();

  /// Validate an image before running ML inference.
  static LeafValidationResult validateImage(img.Image image) {
    // ── 1. Minimum Resolution Check ──────────────────────────────────────────
    if (image.width < 60 || image.height < 60) {
      return const LeafValidationResult(
        isValid: false,
        errorType: LeafValidationError.lowImageQuality,
        errorMessage: 'Image resolution is too low. Please upload a clear leaf image.',
      );
    }

    final totalPixels = (image.width * image.height).toDouble();
    if (totalPixels <= 0) {
      return const LeafValidationResult(
        isValid: false,
        errorType: LeafValidationError.lowImageQuality,
        errorMessage: 'Invalid image data.',
      );
    }

    int greenCount = 0;
    int skinCount = 0;
    int lowSatCount = 0;
    int pitchDarkCount = 0;
    int overexposedCount = 0;
    double totalBrightness = 0.0;

    // Sample pixels for speed (step = 2 for images > 400px)
    final step = (image.width > 400 && image.height > 400) ? 2 : 1;
    int sampledPixels = 0;

    for (int y = 0; y < image.height; y += step) {
      for (int x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        sampledPixels++;

        final brightness = (0.299 * r + 0.587 * g + 0.114 * b);
        totalBrightness += brightness;

        if (brightness < 15.0) pitchDarkCount++;
        if (brightness > 245.0) overexposedCount++;

        // 1. Strictly Green-Dominant Plant Foliage (G > 1.03*R and G > 1.03*B with minimal brightness)
        if (g > r * 1.03 && g > b * 1.03 && g >= 25.0) {
          greenCount++;
        }

        // 2. Human Skin Detection in YCbCr color space
        // Y  =  0.299*R + 0.587*G + 0.114*B
        // Cb = -0.168736*R - 0.331264*G + 0.5*B + 128
        // Cr =  0.5*R - 0.418688*G - 0.081312*B + 128
        final cb = -0.168736 * r - 0.331264 * g + 0.5 * b + 128.0;
        final cr = 0.5 * r - 0.418688 * g - 0.081312 * b + 128.0;
        if (cr >= 133.0 && cr <= 173.0 && cb >= 77.0 && cb <= 127.0) {
          skinCount++;
        }

        // 3. Low-Saturation Neutral (Asphalt, metal, concrete, wall)
        final maxC = [r, g, b].reduce((a, b) => a > b ? a : b);
        final minC = [r, g, b].reduce((a, b) => a < b ? a : b);
        final sat = maxC > 0 ? (maxC - minC) / maxC : 0.0;
        if (sat < 0.12 && brightness > 25.0 && brightness < 225.0) {
          lowSatCount++;
        }
      }
    }

    final sampledTotal = sampledPixels.toDouble();
    final greenRatio = greenCount / sampledTotal;
    final skinRatio = skinCount / sampledTotal;
    final lowSatRatio = lowSatCount / sampledTotal;
    final darkRatio = pitchDarkCount / sampledTotal;
    final overexposedRatio = overexposedCount / sampledTotal;
    final avgBrightness = totalBrightness / sampledTotal;

    // ── 2. Brightness Assessment ─────────────────────────────────────────────
    if (avgBrightness < 20.0 || darkRatio > 0.85) {
      return LeafValidationResult(
        isValid: false,
        errorType: LeafValidationError.lowImageQuality,
        errorMessage: 'Image is too dark. Please take a photo in good lighting.',
        greenRatio: greenRatio,
        skinRatio: skinRatio,
        lowSatRatio: lowSatRatio,
      );
    }

    if (avgBrightness > 240.0 || overexposedRatio > 0.85) {
      return LeafValidationResult(
        isValid: false,
        errorType: LeafValidationError.lowImageQuality,
        errorMessage: 'Image is overexposed or washed out. Please take a clearer photo.',
        greenRatio: greenRatio,
        skinRatio: skinRatio,
        lowSatRatio: lowSatRatio,
      );
    }

    // ── 3. Human Skin / Person Rejection ─────────────────────────────────────
    if (skinRatio > 0.28 && greenRatio < 0.15) {
      return LeafValidationResult(
        isValid: false,
        errorType: LeafValidationError.notLeaf,
        errorMessage: 'Please upload a clear image of a crop leaf, not a person or hand.',
        greenRatio: greenRatio,
        skinRatio: skinRatio,
        lowSatRatio: lowSatRatio,
      );
    }

    // ── 4. Low-Saturation / Concrete / Road / Metal Rejection ────────────────
    if (lowSatRatio > 0.65 && greenRatio < 0.08) {
      return LeafValidationResult(
        isValid: false,
        errorType: LeafValidationError.notLeaf,
        errorMessage: 'Please upload a clear crop leaf photo, not a road, wall, or object.',
        greenRatio: greenRatio,
        skinRatio: skinRatio,
        lowSatRatio: lowSatRatio,
      );
    }

    // ── 5. Zero Foliage / Non-Plant Object Rejection ─────────────────────────
    if (greenRatio < 0.02 && (skinRatio > 0.20 || lowSatRatio > 0.50)) {
      return LeafValidationResult(
        isValid: false,
        errorType: LeafValidationError.notLeaf,
        errorMessage: 'This image does not appear to be a supported crop leaf. Please upload a clear leaf image.',
        greenRatio: greenRatio,
        skinRatio: skinRatio,
        lowSatRatio: lowSatRatio,
      );
    }

    return LeafValidationResult(
      isValid: true,
      errorType: LeafValidationError.none,
      greenRatio: greenRatio,
      skinRatio: skinRatio,
      lowSatRatio: lowSatRatio,
    );
  }
}
