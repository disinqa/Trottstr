import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:purplebase/purplebase.dart';
import 'package:toastification/toastification.dart';
import 'package:trottstr/router.dart';
import 'package:trottstr/theme.dart';
import 'package:trottstr/providers/auth_providers.dart';
import 'package:trottstr/services/notification_monitoring_service.dart';

void main() {
  runZonedGuarded(() {
    runApp(
      ProviderScope(
        overrides: [
          storageNotifierProvider.overrideWith(
            (ref) => PurplebaseStorageNotifier(ref),
          ),
        ],
        child: const PurplestackApp(),
      ),
    );
  }, errorHandler);

  FlutterError.onError = (details) {
    // Prevents debugger stopping multiple times
    FlutterError.dumpErrorToConsole(details);
    errorHandler(details.exception, details.stack);
  };
}

class PurplestackApp extends ConsumerWidget {
  const PurplestackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = 'Trottstr';
    final theme = ref.watch(themeProvider);

    return switch (ref.watch(appInitializationProvider)) {
      AsyncLoading() => MaterialApp(
        title: title,
        theme: theme,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
        debugShowCheckedModeBanner: false,
      ),
      AsyncError(:final error) => MaterialApp(
        title: title,
        theme: theme,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Initialization Error',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      ),
      _ => ToastificationWrapper(
        child: MaterialApp.router(
          title: title,
          theme: theme,
          routerConfig: ref.watch(routerProvider),
          debugShowCheckedModeBanner: false,
          builder: (_, child) => child!,
        ),
      ),
    };
  }
}

void errorHandler(Object exception, StackTrace? stack) {
  // TODO: Implement proper error handling
  debugPrint('Error: $exception');
  debugPrint('Stack trace: $stack');
}

final appInitializationProvider = FutureProvider<void>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  await ref.read(
    initializationProvider(
      StorageConfiguration(
        databasePath: path.join(dir.path, 'trottstr.db'),
        relayGroups: {
          'default': {
            'wss://relay.damus.io',
            'wss://relay.primal.net',
            'wss://nos.lol',
          },
        },
        defaultRelayGroup: 'default',
      ),
    ).future,
  );

  // Attempt auto sign-in after initialization
  try {
    await ref.read(authServiceProvider).attemptAutoSignIn();
  } catch (e) {
    // Auto sign-in failure is not critical
    debugPrint('Auto sign-in failed: $e');
  }

  // Initialize notification monitoring after auth
  try {
    final monitoringService = ref.read(notificationMonitoringServiceProvider);
    await monitoringService.initialize();
    await monitoringService.scheduleDailyMonitoring();
    debugPrint('Notification monitoring initialized');
  } catch (e) {
    // Notification initialization failure is not critical
    debugPrint('Notification monitoring initialization failed: $e');
  }
});
