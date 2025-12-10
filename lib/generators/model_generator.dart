class ModelGenerator {
  static String generate(String snakeName, String pascalName) {
    return '''import '../../domain/entities/${snakeName}_entity.dart';

/// Data model for ${pascalName}
/// Extends ${pascalName}Entity and adds JSON serialization
class ${pascalName}Model extends ${pascalName}Entity {
  const ${pascalName}Model({
    required super.id,
    required super.name,
    required super.createdAt,
  });

  /// Create ${pascalName}Model from JSON
  factory ${pascalName}Model.fromJson(Map<String, dynamic> json) {
    return ${pascalName}Model(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert ${pascalName}Model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create ${pascalName}Model from entity
  factory ${pascalName}Model.fromEntity(${pascalName}Entity entity) {
    return ${pascalName}Model(
      id: entity.id,
      name: entity.name,
      createdAt: entity.createdAt,
    );
  }
}
''';
  }
}
