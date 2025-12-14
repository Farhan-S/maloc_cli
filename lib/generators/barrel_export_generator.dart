/// Generator for creating barrel export files for feature modules.
///
/// A barrel export file simplifies importing by re-exporting all public APIs
/// from a feature module in a single file.
class BarrelExportGenerator {
  /// Generates a barrel export file content for the given [featureName].
  ///
  /// Returns a string containing export statements for all domain, data,
  /// and presentation layer components.
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
