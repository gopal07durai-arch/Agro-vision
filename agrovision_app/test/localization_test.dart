import 'package:flutter_test/flutter_test.dart';
import 'package:agrovision_app/core/l10n/agricultural_localizations.dart';
import 'package:agrovision_app/core/l10n/app_localizations.dart';
import 'package:agrovision_app/models/recommendation_result.dart';

void main() {
  group('AgriculturalLocalizations Tests', () {
    test('All 10 crops translate properly to Tamil, Hindi, Malayalam, and English', () {
      final crops = [
        'Tomato',
        'Paddy',
        'Rice',
        'Wheat',
        'Sugarcane',
        'Groundnut',
        'Sunflower',
        'Cotton',
        'Blackgram',
        'Eggplant',
        'Turmeric',
      ];

      for (final crop in crops) {
        final en = AgriculturalLocalizations.cropName(crop, 'en');
        final ta = AgriculturalLocalizations.cropName(crop, 'ta');
        final hi = AgriculturalLocalizations.cropName(crop, 'hi');
        final ml = AgriculturalLocalizations.cropName(crop, 'ml');

        expect(en, crop);
        expect(ta.isNotEmpty, true);
        expect(hi.isNotEmpty, true);
        expect(ml.isNotEmpty, true);
      }

      expect(AgriculturalLocalizations.cropName('Tomato', 'ta'), 'தக்காளி');
      expect(AgriculturalLocalizations.cropName('Tomato', 'hi'), 'टमाटर');
      expect(AgriculturalLocalizations.cropName('Tomato', 'ml'), 'തക്കാളി');

      expect(AgriculturalLocalizations.cropName('Wheat', 'ta'), 'கோதுமை');
      expect(AgriculturalLocalizations.cropName('Wheat', 'hi'), 'गेहूँ');
      expect(AgriculturalLocalizations.cropName('Wheat', 'ml'), 'ഗോതമ്പ്');
    });

    test('Disease names translate properly to Tamil, Hindi, and Malayalam', () {
      expect(
        AgriculturalLocalizations.diseaseName('Early Blight', 'ta'),
        'ஆரம்பக்கால கருகல் நோய்',
      );
      expect(
        AgriculturalLocalizations.diseaseName('Early Blight', 'hi'),
        contains('अगेती झुलसा'),
      );
      expect(
        AgriculturalLocalizations.diseaseName('Early Blight', 'ml'),
        contains('കരിഞ്ഞുണങ്ങൽ'),
      );

      expect(
        AgriculturalLocalizations.diseaseName('Healthy', 'ta'),
        'ஆரோக்கியமானது',
      );
      expect(
        AgriculturalLocalizations.diseaseName('Healthy', 'hi'),
        'स्वस्थ',
      );
      expect(
        AgriculturalLocalizations.diseaseName('Healthy', 'ml'),
        'ആരോഗ്യമുള്ളത്',
      );
    });

    test('Severity labels translate properly across all 4 languages', () {
      expect(AgriculturalLocalizations.severityLabel('High', 'en'), '⚠ High Severity');
      expect(AgriculturalLocalizations.severityLabel('High', 'ta'), '⚠ அதிக தீவிரம்');
      expect(AgriculturalLocalizations.severityLabel('High', 'hi'), '⚠ उच्च गंभीरता');
      expect(AgriculturalLocalizations.severityLabel('High', 'ml'), '⚠ ഉയർന്ന തീവ്രത');

      expect(AgriculturalLocalizations.severityLabel('None', 'en'), '✓ Healthy');
      expect(AgriculturalLocalizations.severityLabel('None', 'ta'), '✓ ஆரோக்கியமானது');
      expect(AgriculturalLocalizations.severityLabel('None', 'hi'), '✓ स्वस्थ');
      expect(AgriculturalLocalizations.severityLabel('None', 'ml'), '✓ ആരോഗ്യമുള്ളത്');
    });

    test('Dynamic recommendation localization works for Tomato Early Blight', () {
      const original = RecommendationResult(
        problemType: 'Disease',
        productName: 'Trichoderma viride',
        productCategory: 'Biological Control',
        dosage: '2.5 kg/acre',
        dosageUnit: 'kg/acre',
        applicationMethod: 'Dissolve in 200L water; drench soil around base of plant or foliar spray',
        applicationTiming: 'Apply at first symptom appearance or preventively at transplanting',
        frequency: 'Every 21 days during humid weather',
        duration: '3 applications per season',
        precautions: 'Do not mix with chemical fungicides. Apply in cool part of the day.',
        safetyNotes: 'Generally safe — wear gloves and mask. Wash hands after handling.',
        organicAlternative: 'Neem oil 5ml/L foliar spray every 10 days',
        prevention: 'Maintain proper plant spacing. Remove infected leaves. Avoid overhead irrigation. Practice crop rotation.',
      );

      final localizedTa = AgriculturalLocalizations.getLocalizedRecommendation(
        'Tomato',
        'Early Blight',
        original,
        'ta',
      );

      expect(localizedTa, isNotNull);
      expect(localizedTa!.productName, contains('டிரைக்கோடெர்மா விரிடி'));
      expect(localizedTa.productCategory, 'உயிரியல் கட்டுப்பாடு');
      expect(localizedTa.problemType, 'நோய்');
      expect(localizedTa.dosageUnit, 'கிலோ/ஏக்கர்');
      expect(localizedTa.applicationMethod, contains('200 லிட்டர் நீரில் கரைத்து'));
      expect(localizedTa.frequency, contains('21 நாட்களுக்கு ஒருமுறை'));
      expect(localizedTa.precautions, contains('இரசாயன பூஞ்சைக் கொல்லிகளுடன்'));
      expect(localizedTa.organicAlternative, contains('வேப்ப எண்ணெய்'));
      expect(localizedTa.prevention, contains('சரியான செடி இடைவெளியைப்'));
    });

    test('Dynamic fertilizer section is localized', () {
      const original = RecommendationResult(
        problemType: 'Healthy',
        productName: 'Routine Balanced Fertilization',
        productCategory: 'Healthy',
        fertilizerSection: FertilizerRecommendation(
          name: 'Azospirillum biofertilizer',
          productCategory: 'Biofertilizer',
          dosage: '2 kg/acre',
          dosageUnit: 'kg/acre',
          applicationMethod: 'Soil application mixed with FYM at transplanting',
        ),
      );

      final localizedTa = AgriculturalLocalizations.getLocalizedRecommendation(
        'Tomato',
        'Healthy',
        original,
        'ta',
      );

      expect(localizedTa, isNotNull);
      expect(localizedTa!.fertilizerSection, isNotNull);
      expect(localizedTa.fertilizerSection!.name, 'NPK 19:19:19 (கரைசல் உரம்)');
      expect(localizedTa.fertilizerSection!.productCategory, 'உரம்');
      expect(localizedTa.fertilizerSection!.dosageUnit, 'கிராம்/லிட்டர்');
    });
  });

  group('AppLocalizations Tests', () {
    test('AppLocalizations provides translated getters for English, Tamil, Hindi, and Malayalam', () {
      final en = AppLocalizations('en');
      final ta = AppLocalizations('ta');
      final hi = AppLocalizations('hi');
      final ml = AppLocalizations('ml');

      expect(en.appTitle, 'AgroVision AI');
      expect(ta.appTitle, 'அக்ரோவிஷன் AI');
      expect(hi.appTitle, 'एग्रोविजन AI');
      expect(ml.appTitle, 'അഗ്രോവിഷൻ AI');

      expect(en.scanLeaf, 'Scan Leaf');
      expect(ta.scanLeaf, 'இலையை ஸ்கேன் செய்');
      expect(hi.scanLeaf, 'पत्ती स्कैन करें');
      expect(ml.scanLeaf, 'ഇല സ്കാൻ ചെയ്യുക');

      expect(en.recommendedTreatment, 'Recommended Treatment');
      expect(ta.recommendedTreatment, 'பரிந்துரைக்கப்பட்ட சிகிச்சை');
      expect(hi.recommendedTreatment, 'अनुशंसित उपचार');
      expect(ml.recommendedTreatment, 'ശുപാർശ ചെയ്ത ചികിത്സ');

      expect(en.howToApplyStep1Title, 'Prepare');
      expect(ta.howToApplyStep1Title, 'தயார் செய்தல்');
      expect(hi.howToApplyStep1Title, 'तैयारी');
      expect(ml.howToApplyStep1Title, 'തയ്യാറാക്കുക');

      expect(en.preHarvestInterval, 'Pre-Harvest Interval');
      expect(ta.preHarvestInterval, 'அறுவடைக்கு முந்தைய இடைவெளி');
      expect(hi.preHarvestInterval, 'कटाई पूर्व प्रतीक्षा अवधि');
      expect(ml.preHarvestInterval, 'വിളവെടുപ്പിന് മുമ്പുള്ള കാത്തിരിപ്പ് സമയം');

      // Verify no keys return empty
      expect(en.testConnection.isNotEmpty, true);
      expect(ta.testConnection.isNotEmpty, true);
      expect(hi.testConnection.isNotEmpty, true);
      expect(ml.testConnection.isNotEmpty, true);
    });
  });
}
