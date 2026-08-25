import 'dart:math' as math;
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
  final double nonPlantColorRatio;
  final double totalPlantRatio;
  final double hueEntropyBits;

  const LeafValidationResult({
    required this.isValid,
    this.errorType = LeafValidationError.none,
    this.errorMessage = '',
    this.greenRatio = 0.0,
    this.skinRatio = 0.0,
    this.lowSatRatio = 0.0,
    this.nonPlantColorRatio = 0.0,
    this.totalPlantRatio = 0.0,
    this.hueEntropyBits = 0.0,
  });

  static const LeafValidationResult valid = LeafValidationResult(isValid: true);
}

/// Pure Dart Leaf Validator
/// Performs robust image quality assessment and non-leaf (OOD) filtering
/// to prevent random crop/disease predictions on cars, persons, buildings,
/// roads, posters, documents, screenshots, etc.
class LeafValidatorService {
  LeafValidatorService._();

  /// Validate an image before running ML inference.
  /// Returns a [LeafValidationResult] describing whether the image is a
  /// supported crop leaf or should be rejected.
  static LeafValidationResult validateImage(img.Image image) {
    // ── 1. Minimum Resolution Check ─────────────────────────────────────────
    if (image.width < 60 || image.height < 60) {
      return const LeafValidationResult(
        isValid: false,
        errorType: LeafValidationError.lowImageQuality,
        errorMessage: 'Image resolution is too low. Please upload a clearer photo.',
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
    int diseasedCount = 0;
    int lowSatCount = 0;
    int nonPlantColorCount = 0;
    int pitchDarkCount = 0;
    int overexposedCount = 0;
    double totalBrightness = 0.0;

    // Hue histogram with 36 bins (each bin = 10° of hue in 0–360 range)
    final hueBins = List<int>.filled(36, 0);
    int saturatedPixelCount = 0;

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

        // 1. Strictly Green-Dominant Plant Foliage (G > 1.04*R and G > 1.04*B with G >= 28.0)
        final isGreen = (g > r * 1.04 && g > b * 1.04 && g >= 28.0);
        if (isGreen) {
          greenCount++;
        }

        // 2. Human Skin Detection in YCbCr color space
        // Y  =  0.299*R + 0.587*G + 0.114*B
        // Cb = -0.168736*R - 0.331264*G + 0.5*B + 128
        // Cr =  0.5*R - 0.418688*G - 0.081312*B + 128
        final cb = -0.168736 * r - 0.331264 * g + 0.5 * b + 128.0;
        final cr = 0.5 * r - 0.418688 * g - 0.081312 * b + 128.0;
        final isSkin = (cr >= 133.0 && cr <= 173.0 && cb >= 77.0 && cb <= 127.0);
        if (isSkin) {
          skinCount++;
        }

        // 3. HSV calculations for hue, saturation, value
        final maxC = [r, g, b].reduce((a, b) => a > b ? a : b);
        final minC = [r, g, b].reduce((a, b) => a < b ? a : b);
        final sat = maxC > 0 ? (maxC - minC) / maxC : 0.0;
        final val = maxC; // 0..255

        double hue = 0.0;
        if (maxC != minC) {
          final delta = maxC - minC;
          if (maxC == r) {
            hue = 60.0 * (((g - b) / delta) % 6.0);
          } else if (maxC == g) {
            hue = 60.0 * ((b - r) / delta + 2.0);
          } else {
            hue = 60.0 * ((r - g) / delta + 4.0);
          }
          if (hue < 0) hue += 360.0;
        }

        // 4. Low-Saturation Neutral (Asphalt, metal, concrete, wall, white paper)
        if (sat < 0.12 && brightness > 25.0 && brightness < 225.0) {
          lowSatCount++;
        }

        // 5. Diseased Yellow/Brown plant tissue (Hue in [20, 52] deg, Sat in [0.14, 1.0], Val in [30, 245], not skin)
        if (!isSkin && hue >= 20.0 && hue <= 52.0 && sat >= 0.14 && val >= 30.0 && val <= 245.0) {
          diseasedCount++;
        }

        // 6. Artificial Non-Botanical Colors (Blue, Cyan, Magenta, Purple: Hue in [160, 340] deg with Sat > 0.16)
        if (hue >= 160.0 && hue <= 340.0 && sat > 0.16 && val > 30.0) {
          nonPlantColorCount++;
        }

        // 7. Hue histogram for color diversity (Shannon entropy)
        if (sat >= 0.12 && brightness > 25.0 && maxC != minC) {
          final binIndex = (hue / 10.0).floor().clamp(0, 35);
          hueBins[binIndex]++;
          saturatedPixelCount++;
        }
      }
    }

    final sampledTotal = sampledPixels.toDouble();
    final greenRatio = greenCount / sampledTotal;
    final skinRatio = skinCount / sampledTotal;
    final diseasedRatio = diseasedCount / sampledTotal;
    final lowSatRatio = lowSatCount / sampledTotal;
    final nonPlantColorRatio = nonPlantColorCount / sampledTotal;
    final darkRatio = pitchDarkCount / sampledTotal;
    final overexposedRatio = overexposedCount / sampledTotal;
    final avgBrightness = totalBrightness / sampledTotal;

    // Total plant tissue: Diseased yellow/brown is only credited if accompanied by baseline green foliage (>= 4%)
    final totalPlantRatio = (greenRatio >= 0.04)
        ? (greenRatio + diseasedRatio).clamp(0.0, 1.0)
        : greenRatio;

    // Compute Shannon entropy of hue bins
    double hueEntropyBits = 0.0;
    if (saturatedPixelCount > 50) {
      for (final count in hueBins) {
        if (count > 0) {
          final p = count / saturatedPixelCount;
          hueEntropyBits -= p * (math.log(p) / math.ln2);
        }
      }
    }

    // ── 2. Brightness Assessment ─────────────────────────────────────────────
    if (avgBrightness < 20.0 || darkRatio > 0.85) {
      return LeafValidationResult(
        isValid: false,
        errorType: LeafValidationError.lowImageQuality,
        errorMessage: 'Image is too dark. Please take a photo in bright natural lighting.',
        greenRatio: greenRatio,
        skinRatio: skinRatio,
        lowSatRatio: lowSatRatio,
        nonPlantColorRatio: nonPlantColorRatio,
        totalPlantRatio: totalPlantRatio,
        hueEntropyBits: hueEntropyBits,
      );
    }

    if (avgBrightness > 240.0 || overexposedRatio > 0.85) {
      return LeafValidationResult(
        isValid: false,
        errorType: LeafValidationError.lowImageQuality,
        errorMessage: 'Image is overexposed or washed out. Please capture a clear leaf photo.',
        greenRatio: greenRatio,
        skinRatio: skinRatio,
        lowSatRatio: lowSatRatio,
        nonPlantColorRatio: nonPlantColorRatio,
        totalPlantRatio: totalPlantRatio,
        hueEntropyBits: hueEntropyBits,
      );
    }

    // ── 3. Multi-Layer Non-Leaf / OOD Rejection Rules ────────────────────────

    // Rule 3a: Artificial non-botanical colors (Blue, Cyan, Magenta, Purple posters/vehicles/screens)
    if (nonPlantColorRatio > 0.05 && greenRatio < 0.35) {
      return LeafValidationResult(
        isValid: false,
        errorType: LeafValidationError.notLeaf,
        errorMessage:
            'Please upload a clear image of a supported crop leaf, not a poster, vehicle, or artificial object.',
        greenRatio: greenRatio,
        skinRatio: skinRatio,
        lowSatRatio: lowSatRatio,
        nonPlantColorRatio: nonPlantColorRatio,
        totalPlantRatio: totalPlantRatio,
        hueEntropyBits: hueEntropyBits,
      );
    }

    // Rule 3b: Human skin / hand / person dominance
    if (skinRatio > 0.10 && greenRatio < 0.15) {
      return LeafValidationResult(
        isValid: false,
        errorType: LeafValidationError.notLeaf,
        errorMessage: 'Please upload a clear image of a supported crop leaf, not a person or hand.',
        greenRatio: greenRatio,
        skinRatio: skinRatio,
        lowSatRatio: lowSatRatio,
        nonPlantColorRatio: nonPlantColorRatio,
        totalPlantRatio: totalPlantRatio,
        hueEntropyBits: hueEntropyBits,
      );
    }

    // Rule 3c: Asphalt / Road / Concrete / Neutral Grey / Paper Document dominance
    if (lowSatRatio > 0.55 && greenRatio < 0.10) {
      return LeafValidationResult(
        isValid: false,
        errorType: LeafValidationError.notLeaf,
        errorMessage: 'Please upload a clear image of a supported crop leaf, not a road, wall, or document.',
        greenRatio: greenRatio,
        skinRatio: skinRatio,
        lowSatRatio: lowSatRatio,
        nonPlantColorRatio: nonPlantColorRatio,
        totalPlantRatio: totalPlantRatio,
        hueEntropyBits: hueEntropyBits,
      );
    }

    // Rule 3d: Minimum green plant tissue requirement
    if (greenRatio < 0.04) {
      return LeafValidationResult(
        isValid: false,
        errorType: LeafValidationError.notLeaf,
        errorMessage:
            'This image does not appear to be a supported crop leaf. Please upload a clear leaf image.',
        greenRatio: greenRatio,
        skinRatio: skinRatio,
        lowSatRatio: lowSatRatio,
        nonPlantColorRatio: nonPlantColorRatio,
        totalPlantRatio: totalPlantRatio,
        hueEntropyBits: hueEntropyBits,
      );
    }

    // Rule 3e: Minimum total plant tissue area requirement (at least 12% total plant coverage)
    if (totalPlantRatio < 0.12) {
      return LeafValidationResult(
        isValid: false,
        errorType: LeafValidationError.notLeaf,
        errorMessage: 'Please upload a clear image of a supported crop leaf.',
        greenRatio: greenRatio,
        skinRatio: skinRatio,
        lowSatRatio: lowSatRatio,
        nonPlantColorRatio: nonPlantColorRatio,
        totalPlantRatio: totalPlantRatio,
        hueEntropyBits: hueEntropyBits,
      );
    }

    // Rule 3f: Color Diversity / Shannon Entropy Guard
    if (hueEntropyBits > 2.8 && greenRatio < 0.25) {
      return LeafValidationResult(
        isValid: false,
        errorType: LeafValidationError.notLeaf,
        errorMessage:
            'This image appears to be a poster, document, or unrelated photo. '
            'Please upload a clear image of a supported crop leaf.',
        greenRatio: greenRatio,
        skinRatio: skinRatio,
        lowSatRatio: lowSatRatio,
        nonPlantColorRatio: nonPlantColorRatio,
        totalPlantRatio: totalPlantRatio,
        hueEntropyBits: hueEntropyBits,
      );
    }

    return LeafValidationResult(
      isValid: true,
      errorType: LeafValidationError.none,
      greenRatio: greenRatio,
      skinRatio: skinRatio,
      lowSatRatio: lowSatRatio,
      nonPlantColorRatio: nonPlantColorRatio,
      totalPlantRatio: totalPlantRatio,
      hueEntropyBits: hueEntropyBits,
    );
  }
}
