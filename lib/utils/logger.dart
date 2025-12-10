class Logger {
  static const String _reset = '\x1B[0m';
  static const String _green = '\x1B[32m';
  static const String _red = '\x1B[31m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _cyan = '\x1B[36m';

  // Public color constants for use in other classes
  static const String reset = _reset;
  static const String green = _green;
  static const String red = _red;
  static const String yellow = _yellow;
  static const String blue = _blue;
  static const String cyan = _cyan;

  static void success(String message) {
    print('$_green✓$_reset $message');
  }

  static void error(String message) {
    print('$_red✗$_reset $message');
  }

  static void warning(String message) {
    print('$_yellow⚠$_reset $message');
  }

  static void info(String message) {
    print('$_blue ℹ$_reset $message');
  }

  static void step(String message) {
    print('$_cyan▸$_reset $message');
  }

  static void header(String message) {
    print(
        '\n$_cyan═══════════════════════════════════════════════════════$_reset');
    print('$_cyan  $message$_reset');
    print(
        '$_cyan═══════════════════════════════════════════════════════$_reset\n');
  }
}
