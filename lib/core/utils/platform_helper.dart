import 'dart:io';
import 'package:flutter/foundation.dart';

/// Platform detection helpers for adaptive UI
class PlatformHelper {
  PlatformHelper._();

  /// True on macOS, Windows, Linux
  static bool get isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  /// True on iOS, Android
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// True on macOS specifically
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// True on Android specifically
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Minimum window width to show wide (2-column) desktop layout
  static const double wideBreakpoint = 900.0;

  /// Minimum window width for 3-column layout
  static const double extraWideBreakpoint = 1200.0;

  /// Check if current width qualifies as wide layout
  static bool isWideLayout(double width) => width >= wideBreakpoint;

  /// Check if current width qualifies as extra-wide layout
  static bool isExtraWideLayout(double width) => width >= extraWideBreakpoint;
}
