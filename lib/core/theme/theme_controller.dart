import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../services/api_service.dart';
import 'app_colors.dart';

/// Riverpod handle for the theme controller. The controller is
/// instantiated eagerly so the persisted preference is restored on
/// first frame, before any widget reads it.
final themeControllerProvider =
    ChangeNotifierProvider<ThemeController>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeController(prefs)..restore();
});

/// Controls the active light/dark/system theme mode and keeps the
/// global [appBrightness] notifier (used by [AppColors] getters) in
/// sync with whatever the user has chosen.
///
/// The controller is the single source of truth — both
/// `MaterialApp(themeMode:)` and the runtime brightness consulted by
/// the color getters are derived from `mode`. When `mode` is
/// `ThemeMode.system` the controller listens to platform brightness
/// changes via [WidgetsBinding.instance.platformDispatcher] so the UI
/// flips along with the device.
class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  ThemeController(this._prefs);

  final SharedPreferences _prefs;

  ThemeMode _mode = ThemeMode.light;
  bool _observerRegistered = false;
  ThemeMode get mode => _mode;

  /// Resolved brightness — accounts for [ThemeMode.system] by reading
  /// the platform dispatcher. This is what [MaterialApp] ends up
  /// rendering, and what [AppColors] getters return.
  Brightness get effectiveBrightness {
    switch (_mode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return SchedulerBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  bool get isDark => effectiveBrightness == Brightness.dark;

  /// Read the persisted choice from SharedPreferences and apply it.
  /// Called from the provider so the right brightness is active before
  /// `MaterialApp` builds its themes.
  void restore() {
    final raw = _prefs.getString(AppConstants.themeModeKey);
    _mode = _decode(raw) ?? ThemeMode.light;
    _syncGlobalBrightness();
    // Track platform brightness via the observer hook instead of
    // overwriting `platformDispatcher.onPlatformBrightnessChanged`, which
    // would clobber whatever the Flutter framework had set there.
    if (!_observerRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _observerRegistered = true;
    }
  }

  @override
  void didChangePlatformBrightness() {
    if (_mode == ThemeMode.system) {
      _syncGlobalBrightness();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_observerRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _observerRegistered = false;
    }
    super.dispose();
  }

  Future<void> setMode(ThemeMode next) async {
    if (next == _mode) return;
    _mode = next;
    _syncGlobalBrightness();
    notifyListeners();
    await _prefs.setString(AppConstants.themeModeKey, _encode(next));
  }

  /// Convenience for a one-tap toggle in the topbar. Cycles through
  /// dark → light → system → dark.
  Future<void> cycle() async {
    switch (_mode) {
      case ThemeMode.dark:
        return setMode(ThemeMode.light);
      case ThemeMode.light:
        return setMode(ThemeMode.system);
      case ThemeMode.system:
        return setMode(ThemeMode.dark);
    }
  }

  /// Writes the resolved brightness into the global notifier that
  /// `AppColors` getters consult. We assign to `.value` directly so we
  /// don't trigger an extra listener fan-out for code paths that
  /// already react to this controller's own [notifyListeners].
  void _syncGlobalBrightness() {
    final next = effectiveBrightness;
    if (appBrightness.value != next) {
      appBrightness.value = next;
    }
  }

  static String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode? _decode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }
}
