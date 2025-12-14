/// Generator for creating remote data source classes.
///
/// Generates data source classes that handle API communication
/// using DioClient from the core package.
class DataSourceGenerator {
  /// Generates a remote data source class for the given feature.
  ///
  /// Parameters:
  /// - [snakeName]: Feature name in snake_case
  /// - [pascalName]: Feature name in PascalCase
  ///
  /// Returns a string containing the complete data source class code.
  static String generate(String snakeName, String pascalName) {
    return '''import 'package:core/core.dart';
import '../models/${snakeName}_model.dart';

/// Remote data source for $pascalName
/// Handles API communication for $snakeName operations
class ${pascalName}RemoteDataSource {
  final DioClient dioClient;

  ${pascalName}RemoteDataSource(this.dioClient);

  /// Fetch $snakeName by ID from API
  Future<${pascalName}Model> get$pascalName(String id) async {
    try {
      final response = await dioClient.get('/${snakeName}s/\$id');
      return ${pascalName}Model.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch all ${snakeName}s from API
  Future<List<${pascalName}Model>> getAll() async {
    try {
      final response = await dioClient.get('/${snakeName}s');
      final List<dynamic> data = response.data as List;
      return data.map((json) => ${pascalName}Model.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Create new $snakeName via API
  Future<${pascalName}Model> create$pascalName(${pascalName}Model $snakeName) async {
    try {
      final response = await dioClient.post(
        '/${snakeName}s',
        data: $snakeName.toJson(),
      );
      return ${pascalName}Model.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update existing $snakeName via API
  Future<${pascalName}Model> update$pascalName(${pascalName}Model $snakeName) async {
    try {
      final response = await dioClient.put(
        '/${snakeName}s/\${$snakeName.id}',
        data: $snakeName.toJson(),
      );
      return ${pascalName}Model.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete $snakeName via API
  Future<void> delete$pascalName(String id) async {
    try {
      await dioClient.delete('/${snakeName}s/\$id');
    } catch (e) {
      rethrow;
    }
  }
}
''';
  }
}
