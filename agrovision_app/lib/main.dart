import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/providers/app_provider.dart';
import 'services/on_device_ml_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('[Main] Supabase initialization skipped: $e');
    }
  }

  // Initialize on-device ML model in background
  OnDeviceMLService.instance.initialize().catchError((e) {
    debugPrint('[Main] On-device ML initialization deferred: $e');
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const AgroVisionApp(),
    ),
  );
}
