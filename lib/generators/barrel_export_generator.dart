class BarrelExportGenerator {
  static String generate(String featureName) {
    return '''library features_$featureName;

// Domain Layer
export 'domain/entities/${featureName}_entity.dart';
export 'domain/repositories/${featureName}_repository.dart';
export 'domain/usecases/get_${featureName}_usecase.dart';

// Data Layer
export 'data/models/${featureName}_model.dart';
export 'data/datasources/${featureName}_remote_datasource.dart';
export 'data/repositories/${featureName}_repository_impl.dart';

// Presentation Layer
export 'presentation/bloc/${featureName}_bloc.dart';
export 'presentation/bloc/${featureName}_event.dart';
export 'presentation/bloc/${featureName}_state.dart';
export 'presentation/pages/${featureName}_page.dart';
''';
  }
}
