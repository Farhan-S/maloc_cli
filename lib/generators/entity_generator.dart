class EntityGenerator {
  static String generate(String snakeName, String pascalName) {
    return '''import 'package:equatable/equatable.dart';

/// ${pascalName} entity representing the domain model
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
