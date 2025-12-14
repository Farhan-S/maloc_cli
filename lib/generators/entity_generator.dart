/// Generator for creating domain entity classes.
///
/// Generates entity classes that represent the core domain models
/// using Equatable for value equality.
class EntityGenerator {
  /// Generates a domain entity class for the given feature.
  ///
  /// Parameters:
  /// - [snakeName]: Feature name in snake_case
  /// - [pascalName]: Feature name in PascalCase
  ///
  /// Returns a string containing the complete entity class code.
  static String generate(String snakeName, String pascalName) {
    return '''import 'package:equatable/equatable.dart';

/// $pascalName entity representing the domain model
class ${pascalName}Entity extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;

  const ${pascalName}Entity({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, createdAt];
}
''';
  }
}
