import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_showcase/app.dart';
import 'package:flutter_showcase/di/providers.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  // Web: /meal/52772 instead of /#/meal/52772 (no-op on mobile). Pages serves
  // 404.html (a copy of index.html) for such paths.
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      // Show the retry UI at once instead of Riverpod 3 retrying silently.
      retry: (_, _) => null,
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const App(),
    ),
  );
}
