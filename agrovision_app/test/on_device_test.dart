import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:agrovision_app/core/l10n/agricultural_localizations.dart';
import 'package:agrovision_app/services/leaf_validator_service.dart';

void main() {
  group('LeafValidatorService Tests', () {
    test('Rejects low resolution images', () {
      final small = img.Image(width: 40, height: 40);
      final res = LeafValidatorService.validateImage(small);
      expect(res.isValid, false);
      expect(res.errorType, LeafValidationError.lowImageQuality);
    });

    test('Rejects pitch dark image', () {
      final dark = img.Image(width: 224, height: 224);
      img.fill(dark, color: img.ColorRgb8(5, 5, 5));
      final res = LeafValidatorService.validateImage(dark);
      expect(res.isValid, false);
      expect(res.errorType, LeafValidationError.lowImageQuality);
    });

    test('Rejects human skin tones (non-leaf)', () {
      final skin = img.Image(width: 224, height: 224);
      // Skin tone: R=210, G=160, B=140
      img.fill(skin, color: img.ColorRgb8(210, 160, 140));
      final res = LeafValidatorService.validateImage(skin);
      expect(res.isValid, false);
      expect(res.errorType, LeafValidationError.notLeaf);
    });

    test('Rejects neutral grey concrete / asphalt (non-leaf)', () {
      final concrete = img.Image(width: 224, height: 224);
      // Neutral grey: R=120, G=120, B=120
      img.fill(concrete, color: img.ColorRgb8(120, 120, 120));
      final res = LeafValidatorService.validateImage(concrete);
      expect(res.isValid, false);
      expect(res.errorType, LeafValidationError.notLeaf);
    });

    test('Rejects multi-color poster or banner (non-leaf)', () {
      final poster = img.Image(width: 224, height: 224);
      // Red top, blue mid, yellow bottom, purple base
      for (int y = 0; y < 56; y++) {
        for (int x = 0; x < 224; x++) {
          poster.setPixel(x, y, img.ColorRgb8(220, 40, 40));
        }
      }
      for (int y = 56; y < 112; y++) {
        for (int x = 0; x < 224; x++) {
          poster.setPixel(x, y, img.ColorRgb8(40, 120, 220));
        }
      }
      for (int y = 112; y < 168; y++) {
        for (int x = 0; x < 224; x++) {
          poster.setPixel(x, y, img.ColorRgb8(230, 200, 40));
        }
      }
      for (int y = 168; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          poster.setPixel(x, y, img.ColorRgb8(180, 50, 180));
        }
      }
      final res = LeafValidatorService.validateImage(poster);
      expect(res.isValid, false);
      expect(res.errorType, LeafValidationError.notLeaf);
    });

    test('Rejects artificial blue/purple object or vehicle (non-leaf)', () {
      final vehicle = img.Image(width: 224, height: 224);
      // Bright blue: R=20, G=80, B=230
      img.fill(vehicle, color: img.ColorRgb8(20, 80, 230));
      final res = LeafValidatorService.validateImage(vehicle);
      expect(res.isValid, false);
      expect(res.errorType, LeafValidationError.notLeaf);
    });

    test('Accepts green plant foliage', () {
      final leaf = img.Image(width: 224, height: 224);
      // Green foliage: R=50, G=160, B=40
      img.fill(leaf, color: img.ColorRgb8(50, 160, 40));
      final res = LeafValidatorService.validateImage(leaf);
      expect(res.isValid, true);
      expect(res.errorType, LeafValidationError.none);
    });
  });

  group('Offline Localized Recommendation Tests (null original)', () {
    test('Generates English recommendation for Tomato Early Blight offline', () {
      final rec = AgriculturalLocalizations.getLocalizedRecommendation(
        'Tomato',
        'Early Blight',
        null,
        'en',
      );
      expect(rec, isNotNull);
      expect(rec!.productName, 'Trichoderma viride');
      expect(rec.dosage, '2.5 kg/acre');
      expect(rec.problemType, 'Disease');
    });

    test('Generates Tamil recommendation for Tomato Early Blight offline', () {
      final rec = AgriculturalLocalizations.getLocalizedRecommendation(
        'Tomato',
        'Early Blight',
        null,
        'ta',
      );
      expect(rec, isNotNull);
      expect(rec!.productName?.contains('டிரைக்கோடெர்மா விரிடி'), true);
      expect(rec.region, 'தமிழ்நாடு & தென்னிந்தியா');
    });

    test('Generates complete recommendations for all 10 supported crops offline', () {
      final pairs = [
        ['Tomato', 'Late Blight'],
        ['Paddy', 'Brown Spot'],
        ['Wheat', 'Leaf Rust'],
        ['Cotton', 'Bacterial Blight'],
        ['Eggplant', 'Mosaic Virus'],
        ['Groundnut', 'Late Leaf Spot'],
        ['Sugarcane', 'Red Rot'],
        ['Sunflower', 'Downy Mildew'],
        ['Turmeric', 'Leaf Blotch'],
        ['Blackgram', 'Yellow Mosaic'],
      ];

      for (final pair in pairs) {
        final crop = pair[0];
        final disease = pair[1];

        final recEn = AgriculturalLocalizations.getLocalizedRecommendation(
          crop,
          disease,
          null,
          'en',
        );
        expect(recEn, isNotNull, reason: 'Failed for $crop $disease (en)');
        expect(recEn!.productName?.isNotEmpty, true);

        final recTa = AgriculturalLocalizations.getLocalizedRecommendation(
          crop,
          disease,
          null,
          'ta',
        );
        expect(recTa, isNotNull, reason: 'Failed for $crop $disease (ta)');
        expect(recTa!.productName?.isNotEmpty, true);
      }
    });
  });
}
