import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name}}/core/errors/error_config.dart';
import 'package:{{project_name}}/core/notifications/app_notifications_listener.dart';
import 'package:{{project_name}}/core/routing/app_router_provider.dart';
import 'package:{{project_name}}/core/utils/feature_flags.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/constants/app_constants.dart';

void main() async {
  try {
    // 2. Load Environment Variables FIRST
    // FeatureFlags needs this to determine if Sentry is enabled
    await dotenv.load(fileName: ".env");

    // 3. Conditional Sentry Initialization
    // Only initialize the SDK if the flag is enabled.
    // This saves resources and prevents unnecessary SDK overhead.
    if (!kDebugMode && FeatureFlags.isSentryEnabled) {
      await SentryFlutter.init(
        (options) {
          options.dsn = AppConstants.kSentryDsn; // Assuming DSN is also in .env
          options.tracesSampleRate = 1.0;
        },
        appRunner: () async {
          // We wrap the app start here as per Sentry's recommended pattern
          await _startApp();
        },
      );
    } else {
      // If Sentry is disabled, just start the app normally
      await _startApp();
    }
  } catch (e, stackTrace) {
    // Fallback: If .env or Sentry fails to init, we still want the app to run
    debugPrint('Critical initialization error: $e, stackTrace: $stackTrace');
    await _startApp();
  }
}

// Separate the app startup to avoid nesting the logic too deeply in main()
Future<void> _startApp() async {
  // 4. Configure Global Error Fallbacks
  // This sets up ErrorWidget.builder and platformDispatcher.instance.onError
  // This should happen AFTER Sentry init but BEFORE runApp.
  ErrorConfig.initErrorHandling();

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Clean Architecture App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      builder: (context, child) => AppNotificationsListener(child: child!),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
