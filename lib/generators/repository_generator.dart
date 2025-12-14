/// Generator for creating repository interface classes.
///
/// Generates abstract repository classes that define the contract
/// for data operations following Clean Architecture principles.
class RepositoryGenerator {
  /// Generates a repository interface for the given feature.
  ///
  /// Parameters:
  /// - [snakeName]: Feature name in snake_case
  /// - [pascalName]: Feature name in PascalCase
  ///
  /// Returns a string containing the complete repository interface code.
  static String generate(String snakeName, String pascalName) {
    return '''import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/${snakeName}_entity.dart';

/// Repository interface for $pascalName
/// Defines the contract for $snakeName data operations
abstract class ${pascalName}Repository {
  /// Get $snakeName by ID
  Future<Either<ApiException, ${pascalName}Entity>> get$pascalName(String id);

  /// Get all ${snakeName}s
  Future<Either<ApiException, List<${pascalName}Entity>>> getAll();

  /// Create new $snakeName
  Future<Either<ApiException, ${pascalName}Entity>> create$pascalName(${pascalName}Entity $snakeName);

  /// Update existing $snakeName
  Future<Either<ApiException, ${pascalName}Entity>> update$pascalName(${pascalName}Entity $snakeName);

  /// Delete $snakeName
  Future<Either<ApiException, void>> delete$pascalName(String id);
}
''';
  }
}
