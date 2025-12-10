class UseCaseGenerator {
  static String generate(
      String snakeName, String pascalName, String camelName) {
    return '''import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../entities/${snakeName}_entity.dart';
import '../repositories/${snakeName}_repository.dart';

/// Use case for getting ${snakeName} by ID
/// Encapsulates the business logic for retrieving a single ${snakeName}
class Get${pascalName}UseCase {
  final ${pascalName}Repository repository;

  Get${pascalName}UseCase(this.repository);

  /// Execute the use case
  /// 
  /// Returns [Right] with [${pascalName}Entity] on success
  /// Returns [Left] with [ApiException] on failure
  Future<Either<ApiException, ${pascalName}Entity>> call(String id) async {
    return await repository.get${pascalName}(id);
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
