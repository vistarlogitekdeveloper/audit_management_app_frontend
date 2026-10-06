import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/services/api_service.dart';
import 'core/telemetry/telemetry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Usage analytics: off unless the build carries ET_APP_ID + ET_WRITE_KEY
  // (lib/core/telemetry/telemetry.dart). Waits at most 2 s, never throws.
  await Telemetry.init();

  try {
    await Firebase.initializeApp();
  } catch (_) {
    // The app still runs when Firebase config is added later.
  }

  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const VistarAuditApp(),
    ),
  );
}
