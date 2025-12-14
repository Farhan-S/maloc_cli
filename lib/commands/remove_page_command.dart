import 'dart:io';

import '../utils/logger.dart';
import '../utils/string_utils.dart';

class RemovePageCommand {
  final String featureName;
  final String pageName;

  RemovePageCommand(this.featureName, this.pageName);

  Future<void> execute() async {
    final snakeFeatureName = StringUtils.toSnakeCase(featureName);
    final snakePageName = StringUtils.toSnakeCase(pageName);
    final pascalPageName = StringUtils.toPascalCase(pageName);

    // Check if running from project root
    final currentDir = Directory.current.path;
    final melosFile = File('$currentDir/melos.yaml');
    final packagesDir = Directory('$currentDir/packages');

    if (!melosFile.existsSync() || !packagesDir.existsSync()) {
      Logger.error(
        '❌ Please run this command from the project root directory!',
      );
      Logger.error(
        '   (The directory containing melos.yaml and packages/ folder)',
      );
      print('');
      print('Current directory: $_cyan$currentDir$_reset');
      print('Expected files: ${_cyan}melos.yaml, packages/$_reset');
      exit(1);
    }

    Logger.header(
        'Removing Page: $snakePageName from feature: $snakeFeatureName');

    // Check if feature exists
    final featurePath = '$currentDir/packages/features_$snakeFeatureName';
    final featureDir = Directory(featurePath);

    if (!featureDir.existsSync()) {
      Logger.error('Feature "features_$snakeFeatureName" does not exist!');
      Logger.warning('Available features:');
      final packagesDirectory = Directory('$currentDir/packages');
      await for (var entity in packagesDirectory.list()) {
        if (entity is Directory && entity.path.contains('features_')) {
          final name = entity.path.split('/').last;
          Logger.warning('  • $name');
        }
      }
      exit(1);
    }

    // Check if page exists
    final pageFile =
        File('$featurePath/lib/presentation/pages/${snakePageName}_page.dart');
    if (!pageFile.existsSync()) {
      Logger.error(
          'Page "${snakePageName}_page.dart" does not exist in features_$snakeFeatureName!');
      Logger.warning('Available pages:');
      final pagesDir = Directory('$featurePath/lib/presentation/pages');
      if (pagesDir.existsSync()) {
        await for (var entity in pagesDir.list()) {
          if (entity is File && entity.path.endsWith('_page.dart')) {
            final name = entity.path.split('/').last;
            Logger.warning('  • $name');
          }
        }
      }
      exit(1);
    }

    // Detect what was generated with the page
    final blocFile =
        File('$featurePath/lib/presentation/bloc/${snakePageName}_bloc.dart');
    final entityFile =
        File('$featurePath/lib/domain/entities/${snakePageName}_entity.dart');

    final hasBloc = blocFile.existsSync();
    final hasData = entityFile.existsSync();

    // Ask for confirmation
    print('');
    print('$_red⚠️  WARNING: This will permanently delete:$_reset');
    print('   • Page: ${snakePageName}_page.dart');
    if (hasBloc) {
      print(
          '   • BLoC files: ${snakePageName}_bloc.dart, ${snakePageName}_event.dart, ${snakePageName}_state.dart');
    }
    if (hasData) {
      print('   • Domain layer: entity, repository, use case');
      print('   • Data layer: model, datasource, repository implementation');
    }
    print('   • Exports from barrel file');
    print('');
    stdout.write('Are you sure you want to continue? (yes/no): ');
    final confirmation = stdin.readLineSync()?.toLowerCase().trim();

    if (confirmation != 'yes' && confirmation != 'y') {
      Logger.warning('Operation cancelled.');
      exit(0);
    }

    print('');

    try {
      // Remove page file
      Logger.step('Removing page file...');
      pageFile.deleteSync();
      Logger.success('Removed ${snakePageName}_page.dart');

      // Remove BLoC files if they exist
      if (hasBloc) {
        Logger.step('Removing BLoC files...');
        _removeBlocFiles(featurePath, snakePageName);
        Logger.success('Removed BLoC files');
      }

      // Remove data and domain layers if they exist
      if (hasData) {
        Logger.step('Removing domain layer...');
        _removeDomainLayer(featurePath, snakePageName);
        Logger.success('Removed domain layer');

        Logger.step('Removing data layer...');
        _removeDataLayer(featurePath, snakePageName);
        Logger.success('Removed data layer');
      }

      // Update barrel exports
      Logger.step('Updating barrel exports...');
      _removeFromBarrelExports(
          featurePath, snakePageName, snakeFeatureName, hasBloc, hasData);
      Logger.success('Updated barrel exports');

      // Remove route from app_routes.dart
      Logger.step('Removing route from app_routes.dart...');
      _removeRouteFromAppRoutes(currentDir, snakePageName, pascalPageName);
      Logger.success('Removed route from app_routes.dart');

      // Remove route from app_router.dart
      Logger.step('Removing route from app_router.dart...');
      _removeRouteFromAppRouter(currentDir, snakePageName, pascalPageName);
      Logger.success('Removed route from app_router.dart');

      // Remove from dependency injection
      if (hasBloc) {
        Logger.step('Removing from dependency injection...');
        _removeFromDI(currentDir, snakePageName, pascalPageName, hasData);
        Logger.success('Removed from dependency injection');
      }

      Logger.header('Page Removed Successfully! 🗑️');

      print('');
      print('$_green✨ What was removed:$_reset');
      print('   • Page: ${snakePageName}_page.dart');
      if (hasBloc) {
        print('   • BLoC: ${snakePageName}_bloc.dart');
        print('   • Events: ${snakePageName}_event.dart');
        print('   • States: ${snakePageName}_state.dart');
      }
      if (hasData) {
        print('   • Entity: ${snakePageName}_entity.dart');
        print('   • Repository: ${snakePageName}_repository.dart');
        print('   • Use Case: get_${snakePageName}_usecase.dart');
        print('   • Model: ${snakePageName}_model.dart');
        print('   • DataSource: ${snakePageName}_remote_datasource.dart');
        print(
            '   • Repository Implementation: ${snakePageName}_repository_impl.dart');
      }
      print('');
      print('$_green✨ What was cleaned up automatically:$_reset');
      print('   • Route removed from app_routes.dart');
      print('   • Route removed from app_router.dart');
      if (hasBloc) {
        print('   • Dependencies removed from injection_container.dart');
      }
      print('');
    } catch (e) {
      Logger.error('Error removing page: $e');
      exit(1);
    }
  }

  void _removeBlocFiles(String featurePath, String snakePageName) {
    final blocDir = Directory('$featurePath/lib/presentation/bloc');
    if (!blocDir.existsSync()) return;

    final files = [
      '${snakePageName}_bloc.dart',
      '${snakePageName}_event.dart',
      '${snakePageName}_state.dart',
    ];

    for (var fileName in files) {
      final file = File('${blocDir.path}/$fileName');
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }

  void _removeDomainLayer(String featurePath, String snakePageName) {
    final files = [
      '$featurePath/lib/domain/entities/${snakePageName}_entity.dart',
      '$featurePath/lib/domain/repositories/${snakePageName}_repository.dart',
      '$featurePath/lib/domain/usecases/get_${snakePageName}_usecase.dart',
    ];

    for (var filePath in files) {
      final file = File(filePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }

  void _removeDataLayer(String featurePath, String snakePageName) {
    final files = [
      '$featurePath/lib/data/models/${snakePageName}_model.dart',
      '$featurePath/lib/data/datasources/${snakePageName}_remote_datasource.dart',
      '$featurePath/lib/data/repositories/${snakePageName}_repository_impl.dart',
    ];

    for (var filePath in files) {
      final file = File(filePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }

  void _removeFromBarrelExports(String featurePath, String snakePageName,
      String snakeFeatureName, bool hasBloc, bool hasData) {
    final barrelFile = File('$featurePath/lib/features_$snakeFeatureName.dart');

    if (!barrelFile.existsSync()) {
      Logger.warning('Barrel export file not found, skipping update');
      return;
    }

    String content = barrelFile.readAsStringSync();
    final exportsToRemove = <String>[];

    // Domain exports
    if (hasData) {
      exportsToRemove
          .add("export 'domain/entities/${snakePageName}_entity.dart';");
      exportsToRemove.add(
          "export 'domain/repositories/${snakePageName}_repository.dart';");
      exportsToRemove
          .add("export 'domain/usecases/get_${snakePageName}_usecase.dart';");
    }

    // Data exports
    if (hasData) {
      exportsToRemove.add("export 'data/models/${snakePageName}_model.dart';");
      exportsToRemove.add(
          "export 'data/datasources/${snakePageName}_remote_datasource.dart';");
      exportsToRemove.add(
          "export 'data/repositories/${snakePageName}_repository_impl.dart';");
    }

    // Presentation exports
    if (hasBloc) {
      exportsToRemove
          .add("export 'presentation/bloc/${snakePageName}_bloc.dart';");
      exportsToRemove
          .add("export 'presentation/bloc/${snakePageName}_event.dart';");
      exportsToRemove
          .add("export 'presentation/bloc/${snakePageName}_state.dart';");
    }
    exportsToRemove
        .add("export 'presentation/pages/${snakePageName}_page.dart';");

    // Remove each export
    for (var export in exportsToRemove) {
      // Remove the export line (with or without newline)
      content = content.replaceAll('$export\n', '');
      content = content.replaceAll(export, '');
    }

    barrelFile.writeAsStringSync(content);
  }

  void _removeRouteFromAppRoutes(
      String projectRoot, String snakeName, String pascalName) {
    try {
      final appRoutesFile =
          File('$projectRoot/packages/core/lib/src/routes/app_routes.dart');
      if (!appRoutesFile.existsSync()) {
        Logger.warning('app_routes.dart not found, skipping route removal');
        return;
      }

      String content = appRoutesFile.readAsStringSync();
      final camelName = StringUtils.toCamelCase(snakeName);

      // Remove route name constant
      final routeNamePattern = RegExp(
        r"  static const String " + camelName + r" = '[^']+';?\n?",
        multiLine: true,
      );
      content = content.replaceAll(routeNamePattern, '');

      // Remove route path constant
      final routePathPattern = RegExp(
        r"  static const String " + camelName + r"Path = '[^']+';?\n?",
        multiLine: true,
      );
      content = content.replaceAll(routePathPattern, '');

      // Remove navigation helper method
      final helperPattern = RegExp(
        r'  /// Navigate to ' +
            snakeName +
            r' page\n' +
            r'  static void navigateTo' +
            pascalName +
            r'\(BuildContext context\) \{\n' +
            r'    context\.push\(' +
            camelName +
            r'Path\);\n' +
            r'  \}\n',
        multiLine: true,
      );
      content = content.replaceAll(helperPattern, '');

      appRoutesFile.writeAsStringSync(content);
    } catch (e) {
      Logger.warning('Error removing route from app_routes.dart: $e');
    }
  }

  void _removeRouteFromAppRouter(
      String projectRoot, String snakeName, String pascalName) {
    try {
      final appRouterFile =
          File('$projectRoot/packages/app/lib/routes/app_router.dart');
      if (!appRouterFile.existsSync()) {
        Logger.warning('app_router.dart not found, skipping route removal');
        return;
      }

      String content = appRouterFile.readAsStringSync();

      // Remove the entire GoRoute block with comment
      final routePattern = RegExp(
        r'\n        // ={20} ' +
            pascalName +
            r' Route ={20}\n' +
            r'        GoRoute\(\n' +
            r'(?:.*\n)*?' + // Match any lines in between (non-greedy)
            r'        \),\n',
        multiLine: true,
      );
      content = content.replaceAll(routePattern, '\n');

      appRouterFile.writeAsStringSync(content);
    } catch (e) {
      Logger.warning('Error removing route from app_router.dart: $e');
    }
  }

  void _removeFromDI(
      String projectRoot, String snakeName, String pascalName, bool hasData) {
    try {
      final diFile =
          File('$projectRoot/packages/app/lib/injection_container.dart');
      if (!diFile.existsSync()) {
        Logger.warning(
            'injection_container.dart not found, skipping DI removal');
        return;
      }

      String content = diFile.readAsStringSync();

      if (hasData) {
        // Remove DataSource registration
        final dataSourcePattern = RegExp(
          r'\n  // ' +
              pascalName +
              r' Data Sources\n' +
              r'  getIt\.registerLazySingleton<' +
              pascalName +
              r'RemoteDataSource>\(\n' +
              r'    \(\) => ' +
              pascalName +
              r'RemoteDataSource\(getIt<DioClient>\(\)\),\n' +
              r'  \);\n',
          multiLine: true,
        );
        content = content.replaceAll(dataSourcePattern, '');

        // Remove Repository registration
        final repoPattern = RegExp(
          r'\n  // ' +
              pascalName +
              r' Repositories\n' +
              r'  getIt\.registerLazySingleton<' +
              pascalName +
              r'Repository>\(\n' +
              r'    \(\) => ' +
              pascalName +
              r'RepositoryImpl\(getIt<' +
              pascalName +
              r'RemoteDataSource>\(\)\),\n' +
              r'  \);\n',
          multiLine: true,
        );
        content = content.replaceAll(repoPattern, '');

        // Remove UseCase registration
        final useCasePattern = RegExp(
          r'\n  // ' +
              pascalName +
              r' Use Cases\n' +
              r'  getIt\.registerLazySingleton<Get' +
              pascalName +
              r'UseCase>\(\n' +
              r'    \(\) => Get' +
              pascalName +
              r'UseCase\(getIt<' +
              pascalName +
              r'Repository>\(\)\),\n' +
              r'  \);\n',
          multiLine: true,
        );
        content = content.replaceAll(useCasePattern, '');

        // Remove BLoC registration (with UseCase)
        final blocWithDataPattern = RegExp(
          r'\n  // ' +
              pascalName +
              r' BLoC\n' +
              r'  getIt\.registerFactory<' +
              pascalName +
              r'Bloc>\(\n' +
              r'    \(\) => ' +
              pascalName +
              r'Bloc\(getIt<Get' +
              pascalName +
              r'UseCase>\(\)\),\n' +
              r'  \);\n',
          multiLine: true,
        );
        content = content.replaceAll(blocWithDataPattern, '');
      } else {
        // Remove BLoC registration (without UseCase)
        final blocPattern = RegExp(
          r'\n  // ' +
              pascalName +
              r' BLoC\n' +
              r'  getIt\.registerFactory<' +
              pascalName +
              r'Bloc>\(\n' +
              r'    \(\) => ' +
              pascalName +
              r'Bloc\(\),\n' +
              r'  \);\n',
          multiLine: true,
        );
        content = content.replaceAll(blocPattern, '');
      }

      diFile.writeAsStringSync(content);
    } catch (e) {
      Logger.warning('Error removing from injection_container.dart: $e');
    }
  }

  static const String _reset = '\x1B[0m';
  static const String _cyan = '\x1B[36m';
  static const String _green = '\x1B[32m';
  static const String _red = '\x1B[31m';
}
