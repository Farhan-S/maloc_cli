import 'package:recase/recase.dart';

/// Utility class for string case conversions.
///
/// Provides methods to convert strings between different naming conventions
/// commonly used in code generation.
class StringUtils {
  /// Converts [input] to snake_case.
  ///
  /// Example: "myFeature" -> "my_feature"
  static String toSnakeCase(String input) {
    return ReCase(input).snakeCase;
  }

  /// Converts [input] to PascalCase.
  ///
  /// Example: "my_feature" -> "MyFeature"
  static String toPascalCase(String input) {
    return ReCase(input).pascalCase;
  }

  /// Converts [input] to camelCase.
  ///
  /// Example: "my_feature" -> "myFeature"
  static String toCamelCase(String input) {
    return ReCase(input).camelCase;
  }

  /// Converts [input] to Title Case.
  ///
  /// Example: "my_feature" -> "My Feature"
  static String toTitleCase(String input) {
    return ReCase(input).titleCase;
  }
}
