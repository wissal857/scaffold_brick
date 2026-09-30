import 'package:{{project_name}}/core/constants/app_constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FeatureFlags {
  FeatureFlags._();

  static bool get isRemoteApiEnabled =>
      dotenv.env[AppConstants.kEnableRemoteApiTag] == 'true';
  static bool get isSentryEnabled =>
      dotenv.env[AppConstants.kEnableSentryTag] == 'true';
}
