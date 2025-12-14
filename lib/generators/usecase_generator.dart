/// Generator for creating use case classes.
///
/// Generates use case classes that encapsulate business logic
/// following the Single Responsibility Principle.
class UseCaseGenerator {
  /// Generates use case classes for the given feature.
  ///
  /// Parameters:
  /// - [snakeName]: Feature name in snake_case
  /// - [pascalName]: Feature name in PascalCase
  /// - [camelName]: Feature name in camelCase
  ///
  /// Returns a string containing the complete use case classes code.
  static String generate(
      String snakeName, String pascalName, String camelName) {
    return '''import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/${snakeName}_entity.dart';
import '../repositories/${snakeName}_repository.dart';

/// Use case for getting $snakeName by ID
/// Encapsulates the business logic for retrieving a single $snakeName
class Get${pascalName}UseCase {
  final ${pascalName}Repository repository;

  Get${pascalName}UseCase(this.repository);

  /// Execute the use case
  /// 
  /// Returns [Right] with [${pascalName}Entity] on success
  /// Returns [Left] with [ApiException] on failure
  Future<Either<ApiException, ${pascalName}Entity>> call(String id) async {
    return await repository.get$pascalName(id);
  }
}

/// Use case for getting all ${snakeName}s
class GetAll${pascalName}sUseCase {
  final ${pascalName}Repository repository;

  GetAll${pascalName}sUseCase(this.repository);

  /// Execute the use case to get all ${snakeName}s
  Future<Either<ApiException, List<${pascalName}Entity>>> call() async {
    return await repository.getAll();
  }
}
''';
  }
}
