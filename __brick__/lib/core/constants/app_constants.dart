import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:{{project_name}}/core/errors/app_exception.dart';

class AppConstants {
  const AppConstants._();

  static const kEnableSentryTag = 'ENABLE_SENTRY';
  static const kEnableRemoteApiTag = 'ENABLE_REMOTE_API';
  static const kInitialDataPath = 'assets/data/initial_data.json';
  static const kMutationQueueCapacity = 100;

  static String get kApiUrl {
    String? apiKey = dotenv.env['API_URL'];
    if (apiKey == null) {
      throw MissingAPIKeyException();
    } else {
      return apiKey;
    }
  }

  static String get kSentryDsn {
    String? kSentryDsn = dotenv.env['SENTRY_DSN'];
    if (kSentryDsn == null) {
      throw MissingAPIKeyException();
    } else {
      return kSentryDsn;
    }
  }
}
