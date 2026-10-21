import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static const String razorpayKeyIdKey = 'RAZORPAY_KEY_ID';
  static const String apiBaseUrlKey = 'API_BASE_URL';
  static const String mockAppDataKey = 'MOCK_APP_DATA';
  static const String mockAppDataScenarioKey = 'MOCK_APP_DATA_SCENARIO';

  static bool get useMockAppData => false;

  static String get mockAppDataScenario {
    if (kReleaseMode) return 'success';
    return (dotenv.env[mockAppDataScenarioKey] ?? 'success').toLowerCase();
  }

  static String get razorpayKeyId {
    return dotenv.env[razorpayKeyIdKey] ?? '';
  }

  static Future<void> init() async {
    // Optionally load different files based on environment if needed
    // Defaults to .env if not specified, but we can load .env.development
    if (kReleaseMode) {
      await dotenv.load(fileName: '.env.production');
    } else {
      await dotenv.load(fileName: '.env.development');
    }
  }
}
