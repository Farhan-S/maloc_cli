import 'package:recase/recase.dart';

class StringUtils {
  static String toSnakeCase(String input) {
    return ReCase(input).snakeCase;
  }

  static String toPascalCase(String input) {
    return ReCase(input).pascalCase;
  }

  static String toCamelCase(String input) {
    return ReCase(input).camelCase;
  }

  static String toTitleCase(String input) {
    return ReCase(input).titleCase;
  }
}
