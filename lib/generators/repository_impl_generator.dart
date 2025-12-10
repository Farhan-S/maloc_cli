class RepositoryImplGenerator {
  static String generate(
      String snakeName, String pascalName, String camelName) {
    return '''import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/${snakeName}_entity.dart';
import '../../domain/repositories/${snakeName}_repository.dart';
import '../datasources/${snakeName}_remote_datasource.dart';
import '../models/${snakeName}_model.dart';

/// Implementation of ${pascalName}Repository
/// Handles data operations and error handling
class ${pascalName}RepositoryImpl implements ${pascalName}Repository {
  final ${pascalName}RemoteDataSource remoteDataSource;

  ${pascalName}RepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<ApiException, ${pascalName}Entity>> get${pascalName}(String id) async {
    try {
      final ${camelName} = await remoteDataSource.get${pascalName}(id);
      return Right(${camelName});
    } on ApiException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(e.toString()));
    }
  }

  @override
  Future<Either<ApiException, List<${pascalName}Entity>>> getAll() async {
    try {
      final items = await remoteDataSource.getAll();
      return Right(items);
    } on ApiException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(e.toString()));
    }
  }

  @override
  Future<Either<ApiException, ${pascalName}Entity>> create${pascalName}(${pascalName}Entity ${snakeName}) async {
    try {
      final model = ${pascalName}Model.fromEntity(${snakeName});
      final created${pascalName} = await remoteDataSource.create${pascalName}(model);
      return Right(created${pascalName});
    } on ApiException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(e.toString()));
    }
  }

  @override
  Future<Either<ApiException, ${pascalName}Entity>> update${pascalName}(${pascalName}Entity ${snakeName}) async {
    try {
      final model = ${pascalName}Model.fromEntity(${snakeName});
      final updated${pascalName} = await remoteDataSource.update${pascalName}(model);
      return Right(updated${pascalName});
    } on ApiException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(e.toString()));
    }
  }

  @override
  Future<Either<ApiException, void>> delete${pascalName}(String id) async {
    try {
      await remoteDataSource.delete${pascalName}(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownException(e.toString()));
    }
  }
}
''';
  }
}
