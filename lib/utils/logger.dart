/// Utility class for formatted console logging with colors and icons.
///
/// Provides methods for different log levels with appropriate colors and symbols.
class Logger {
  static const String _reset = '\x1B[0m';
  static const String _green = '\x1B[32m';
  static const String _red = '\x1B[31m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _cyan = '\x1B[36m';

  /// ANSI reset code to clear formatting.
  static const String reset = _reset;

  /// ANSI green color code.
  static const String green = _green;

  /// ANSI red color code.
  static const String red = _red;

  /// ANSI yellow color code.
  static const String yellow = _yellow;

  /// ANSI blue color code.
  static const String blue = _blue;

  /// ANSI cyan color code.
  static const String cyan = _cyan;

  /// Prints a success [message] in green with a checkmark.
  static void success(String message) {
    print('$_green✓$_reset $message');
  }

  /// Prints an error [message] in red with an X mark.
  static void error(String message) {
    print('$_red✗$_reset $message');
  }

  /// Prints a warning [message] in yellow with a warning symbol.
  static void warning(String message) {
    print('$_yellow⚠$_reset $message');
  }

  /// Prints an info [message] in blue with an info symbol.
  static void info(String message) {
    print('$_blue ℹ$_reset $message');
  }

  /// Prints a step [message] in cyan with an arrow symbol.
  static void step(String message) {
    print('$_cyan▸$_reset $message');
  }

  /// Prints a formatted header [message] with borders.
  static void header(String message) {
    print(
        '\n$_cyan═══════════════════════════════════════════════════════$_reset');
    print('$_cyan  $message$_reset');
    print(
        '$_cyan═══════════════════════════════════════════════════════$_reset\n');
  }
}
