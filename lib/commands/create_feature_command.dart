import 'dart:io';

import 'package:maloc_cli/generators/barrel_export_generator.dart';
import 'package:maloc_cli/generators/bloc_generator.dart';
import 'package:maloc_cli/generators/datasource_generator.dart';
import 'package:maloc_cli/generators/entity_generator.dart';
import 'package:maloc_cli/generators/model_generator.dart';
import 'package:maloc_cli/generators/page_generator.dart';
import 'package:maloc_cli/generators/pubspec_generator.dart';
import 'package:maloc_cli/generators/repository_generator.dart';
import 'package:maloc_cli/generators/repository_impl_generator.dart';
import 'package:maloc_cli/generators/usecase_generator.dart';
import 'package:maloc_cli/utils/logger.dart';
import 'package:maloc_cli/utils/string_utils.dart';

class CreateFeatureCommand {
  final String featureName;

  CreateFeatureCommand(this.featureName);

  Future<void> execute() async {
    final snakeName = StringUtils.toSnakeCase(featureName);
    final pascalName = StringUtils.toPascalCase(featureName);
    final camelName = StringUtils.toCamelCase(featureName);

    // Check if running from project root
    final currentDir = Directory.current.path;
    final melosFile = File('$currentDir/melos.yaml');
    final packagesDir = Directory('$currentDir/packages');

    if (!melosFile.existsSync() || !packagesDir.existsSync()) {
      Logger.error(
          '❌ Please run this command from the project root directory!');
      Logger.error(
          '   (The directory containing melos.yaml and packages/ folder)');
      print('');
      print('Current directory: ${_cyan}$currentDir$_reset');
      print('Expected files: ${_cyan}melos.yaml, packages/$_reset');
      exit(1);
    }

    Logger.header('Creating Feature: $snakeName');

    // Determine packages path
    final packagesPath =
        currentDir.endsWith('packages') ? currentDir : '$currentDir/packages';

    final featurePath = '$packagesPath/features_$snakeName';

    // Check if feature already exists
    if (Directory(featurePath).existsSync()) {
      Logger.error('Feature "features_$snakeName" already exists!');
      exit(1);
    }

    // Create directory structure
    Logger.step('Creating directory structure...');
    _createDirectoryStructure(featurePath);
    Logger.success('Directory structure created');

    // Generate files
    Logger.step('Generating files...');

    // pubspec.yaml
    final pubspecContent = PubspecGenerator.generate(snakeName);
    _writeFile('$featurePath/pubspec.yaml', pubspecContent);
    Logger.success('Generated pubspec.yaml');

    // Barrel export
    final barrelContent = BarrelExportGenerator.generate(snakeName);
    _writeFile('$featurePath/lib/features_$snakeName.dart', barrelContent);
    Logger.success('Generated barrel export file');

    // Domain layer
    final entityContent = EntityGenerator.generate(snakeName, pascalName);
    _writeFile('$featurePath/lib/domain/entities/${snakeName}_entity.dart',
        entityContent);
    Logger.success('Generated entity');

    final repositoryContent =
        RepositoryGenerator.generate(snakeName, pascalName);
    _writeFile(
        '$featurePath/lib/domain/repositories/${snakeName}_repository.dart',
        repositoryContent);
    Logger.success('Generated repository interface');

    final usecaseContent =
        UseCaseGenerator.generate(snakeName, pascalName, camelName);
    _writeFile('$featurePath/lib/domain/usecases/get_${snakeName}_usecase.dart',
        usecaseContent);
    Logger.success('Generated use cases');

    // Data layer
    final modelContent = ModelGenerator.generate(snakeName, pascalName);
    _writeFile(
        '$featurePath/lib/data/models/${snakeName}_model.dart', modelContent);
    Logger.success('Generated model');

    final datasourceContent =
        DataSourceGenerator.generate(snakeName, pascalName);
    _writeFile(
        '$featurePath/lib/data/datasources/${snakeName}_remote_datasource.dart',
        datasourceContent);
    Logger.success('Generated remote datasource');

    final repoImplContent =
        RepositoryImplGenerator.generate(snakeName, pascalName, camelName);
    _writeFile(
        '$featurePath/lib/data/repositories/${snakeName}_repository_impl.dart',
        repoImplContent);
    Logger.success('Generated repository implementation');

    // Presentation layer
    final blocFiles = BlocGenerator.generate(snakeName, pascalName, camelName);
    _writeFile('$featurePath/lib/presentation/bloc/${snakeName}_bloc.dart',
        blocFiles['bloc']!);
    _writeFile('$featurePath/lib/presentation/bloc/${snakeName}_event.dart',
        blocFiles['event']!);
    _writeFile('$featurePath/lib/presentation/bloc/${snakeName}_state.dart',
        blocFiles['state']!);
    Logger.success('Generated BLoC files');

    final pageContent = PageGenerator.generate(snakeName, pascalName);
    _writeFile('$featurePath/lib/presentation/pages/${snakeName}_page.dart',
        pageContent);
    Logger.success('Generated page');

    // Create empty widgets folder with .gitkeep
    _writeFile('$featurePath/lib/presentation/widgets/.gitkeep', '');

    // Add route to app_routes.dart
    Logger.step('Adding route to app_routes.dart...');
    _addRouteToAppRoutes(snakeName, camelName);
    Logger.success('Route added to app_routes.dart');

    // Register route in app_route_generator.dart
    Logger.step('Registering route in app_route_generator.dart...');
    _registerRouteInGenerator(snakeName, pascalName, camelName);
    Logger.success('Route registered in app_route_generator.dart');

    // Add to app/pubspec.yaml
    Logger.step('Adding dependency to app/pubspec.yaml...');
    _addToAppPubspec(snakeName);
    Logger.success('Dependency added to app/pubspec.yaml');

    // Install dependencies
    Logger.step('Installing dependencies...');
    _installDependencies(featurePath);
    Logger.success('Dependencies installed');

    Logger.header('Feature Created Successfully! 🎉');

    print('''
Next steps:

1. Register in app/lib/injection_container.dart:
   ${_cyan}// Data Sources
   getIt.registerLazySingleton<${pascalName}RemoteDataSource>(
     () => ${pascalName}RemoteDataSource(getIt<DioClient>()),
   );

   // Repositories
   getIt.registerLazySingleton<${pascalName}Repository>(
     () => ${pascalName}RepositoryImpl(getIt<${pascalName}RemoteDataSource>()),
   );

   // Use Cases
   getIt.registerLazySingleton<Get${pascalName}UseCase>(
     () => Get${pascalName}UseCase(getIt<${pascalName}Repository>()),
   );

   // BLoC
   getIt.registerFactory<${pascalName}Bloc>(
     () => ${pascalName}Bloc(getIt<Get${pascalName}UseCase>()),
   );$_reset

${_green}✨ What was done automatically:$_reset
   • Created complete Clean Architecture structure
   • Added dependency to app/pubspec.yaml
   • Installed all feature dependencies
   • Registered routes in app_routes.dart
   • Registered routes in app_route_generator.dart

Feature location: ${_green}$featurePath$_reset
''');
  }

  void _createDirectoryStructure(String basePath) {
    final dirs = [
      '$basePath/lib/domain/entities',
      '$basePath/lib/domain/repositories',
      '$basePath/lib/domain/usecases',
      '$basePath/lib/data/models',
      '$basePath/lib/data/datasources',
      '$basePath/lib/data/repositories',
      '$basePath/lib/presentation/bloc',
      '$basePath/lib/presentation/pages',
      '$basePath/lib/presentation/widgets',
    ];

    for (var dir in dirs) {
      Directory(dir).createSync(recursive: true);
    }
  }

  void _writeFile(String path, String content) {
    File(path).writeAsStringSync(content);
  }

  void _addRouteToAppRoutes(String snakeName, String camelName) {
    final currentDir = Directory.current.path;
    final appRoutesPath = currentDir.endsWith('packages')
        ? '$currentDir/core/lib/src/routes/app_routes.dart'
        : '$currentDir/packages/core/lib/src/routes/app_routes.dart';

    final appRoutesFile = File(appRoutesPath);
    if (!appRoutesFile.existsSync()) {
      Logger.warning('app_routes.dart not found at $appRoutesPath');
      return;
    }

    String content = appRoutesFile.readAsStringSync();
    final pascalName = snakeName
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join('');
    bool routeExists = content.contains("static const String $camelName =");
    bool navHelperExists = content.contains("navigateTo$pascalName(");

    // Add route constant if not exists
    if (!routeExists) {
      final insertPattern = "static const String settings = '/settings';";
      final insertIndex = content.indexOf(insertPattern);

      if (insertIndex != -1) {
        final lineEnd = content.indexOf('\n', insertIndex);
        final insertPosition = lineEnd + 1;

        final featureTitle = snakeName
            .split('_')
            .map((w) => w[0].toUpperCase() + w.substring(1))
            .join(' ');
        final newRoute =
            "\n  // $featureTitle Routes\n  static const String $camelName = '/$snakeName';\n";

        content = content.substring(0, insertPosition) +
            newRoute +
            content.substring(insertPosition);
      } else {
        Logger.warning(
            'Could not find insertion point for route constant in app_routes.dart');
        return;
      }
    }

    // Add navigation helper if not exists
    if (!navHelperExists) {
      final navigationHelperPattern =
          "/// Navigate back\n  static void navigateBack(BuildContext context) {";
      final navHelperIndex = content.indexOf(navigationHelperPattern);

      if (navHelperIndex != -1) {
        final navigationHelper =
            "\n  /// Navigate to $snakeName page\n  static Future<void> navigateTo$pascalName(BuildContext context) {\n    return Navigator.pushNamed(context, $camelName);\n  }\n\n";

        content = content.substring(0, navHelperIndex) +
            navigationHelper +
            content.substring(navHelperIndex);
      } else {
        Logger.warning(
            'Could not find insertion point for navigation helper in app_routes.dart');
      }
    }

    // Write updated content
    if (!routeExists || !navHelperExists) {
      appRoutesFile.writeAsStringSync(content);
    } else {
      Logger.warning(
          'Route $camelName and navigation helper already exist in app_routes.dart');
    }
  }

  void _registerRouteInGenerator(
      String snakeName, String pascalName, String camelName) {
    try {
      final currentDir = Directory.current.path;
      final routeGeneratorPath = currentDir.endsWith('packages')
          ? '$currentDir/app/lib/routes/app_route_generator.dart'
          : '$currentDir/packages/app/lib/routes/app_route_generator.dart';

      final routeGeneratorFile = File(routeGeneratorPath);
      if (!routeGeneratorFile.existsSync()) {
        Logger.warning(
            'app_route_generator.dart not found at $routeGeneratorPath');
        return;
      }

      String content = routeGeneratorFile.readAsStringSync();
      bool wasModified = false;

      // Check if route already registered
      if (content.contains("case AppRoutes.$camelName:")) {
        Logger.warning(
            'Route $camelName already registered in switch statement');
        return;
      }

      // 1. Add import for the feature
      final importsEndPattern = "import '../injection_container.dart';";
      final importIndex = content.indexOf(importsEndPattern);

      if (importIndex != -1) {
        final lineEnd = content.indexOf('\n', importIndex);
        final importInsertPosition = lineEnd + 1;
        final featureImport =
            "import 'package:features_$snakeName/features_$snakeName.dart';\n";

        // Only add if import doesn't exist
        if (!content.contains(featureImport.trim())) {
          content = content.substring(0, importInsertPosition) +
              featureImport +
              content.substring(importInsertPosition);
          wasModified = true;
        }
      } else {
        Logger.warning(
            'Could not find import section in app_route_generator.dart');
      }

      // 2. Add case to switch statement
      final switchInsertPattern = "case AppRoutes.login:";
      final switchIndex = content.indexOf(switchInsertPattern);

      if (switchIndex != -1) {
        // Find the end of the login case
        final loginCaseEnd = content.indexOf("default:", switchIndex);

        if (loginCaseEnd != -1) {
          final newCase = '''

      case AppRoutes.$camelName:
        return _createRoute(
          BlocProvider(
            create: (_) => getIt<${pascalName}Bloc>(),
            child: const ${pascalName}Page(),
          ),
          settings,
        );
''';

          content = content.substring(0, loginCaseEnd) +
              newCase +
              '\n      ' +
              content.substring(loginCaseEnd);
          wasModified = true;
        } else {
          Logger.warning('Could not find default case in switch statement');
        }
      } else {
        Logger.warning('Could not find login case in switch statement');
      }

      // 3. Add route registration in registerAllRoutes method
      final registerRoutesPattern =
          "// Auth routes can be registered similarly\n    AppRouteRegistry.registerRoute(";
      final registerIndex = content.indexOf(registerRoutesPattern);

      if (registerIndex != -1) {
        // Find the end of login route registration
        final loginRegisterEnd = content.indexOf(");", registerIndex);
        if (loginRegisterEnd != -1) {
          final semicolonEnd = content.indexOf(";", loginRegisterEnd);
          final insertPosition = semicolonEnd + 1;

          final newRegistration = '''
    
    // ${pascalName} route
    AppRouteRegistry.registerRoute(
      AppRoutes.$camelName,
      (settings) => MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<${pascalName}Bloc>(),
          child: const ${pascalName}Page(),
        ),
        settings: settings,
      ),
    );''';

          content = content.substring(0, insertPosition) +
              newRegistration +
              content.substring(insertPosition);
          wasModified = true;
        } else {
          Logger.warning('Could not find login route registration end');
        }
      } else {
        Logger.warning('Could not find route registration section');
      }

      if (wasModified) {
        routeGeneratorFile.writeAsStringSync(content);
      }
    } catch (e) {
      Logger.error('Error registering route in app_route_generator.dart: $e');
    }
  }

  void _addToAppPubspec(String snakeName) {
    try {
      final currentDir = Directory.current.path;
      final appPubspecPath = currentDir.endsWith('packages')
          ? '$currentDir/app/pubspec.yaml'
          : '$currentDir/packages/app/pubspec.yaml';

      final appPubspecFile = File(appPubspecPath);
      if (!appPubspecFile.existsSync()) {
        Logger.warning('app/pubspec.yaml not found at $appPubspecPath');
        return;
      }

      String content = appPubspecFile.readAsStringSync();

      // Check if already added
      if (content.contains('features_$snakeName:')) {
        Logger.warning(
            'features_$snakeName already exists in app/pubspec.yaml');
        return;
      }

      // Find the insertion point - after the last features_ dependency or after core
      final lines = content.split('\n');
      int insertIndex = -1;
      int lastFeatureIndex = -1;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();

        // Find the last features_ package
        if (line.startsWith('features_') && line.endsWith(':')) {
          lastFeatureIndex = i;
        }

        // Also track core package as fallback
        if (line == 'core:' && insertIndex == -1) {
          insertIndex = i;
        }
      }

      // Use last feature index if found, otherwise use core
      if (lastFeatureIndex != -1) {
        insertIndex = lastFeatureIndex;
      }

      if (insertIndex == -1) {
        Logger.warning('Could not find insertion point in app/pubspec.yaml');
        return;
      }

      // Find the end of that dependency block (next line with path:)
      for (int i = insertIndex + 1;
          i < lines.length && i < insertIndex + 3;
          i++) {
        if (lines[i].trim().startsWith('path:')) {
          insertIndex = i;
          break;
        }
      }

      // Insert the new dependency after the found index
      final newDependency = '''  features_$snakeName:
    path: ../features_$snakeName''';

      lines.insert(insertIndex + 1, newDependency);

      final newContent = lines.join('\n');
      appPubspecFile.writeAsStringSync(newContent);
    } catch (e) {
      Logger.warning('Error adding to app/pubspec.yaml: $e');
      Logger.warning('Please add manually:');
      Logger.warning('  features_$snakeName:');
      Logger.warning('    path: ../features_$snakeName');
    }
  }

  void _installDependencies(String featurePath) {
    try {
      final result = Process.runSync(
        'dart',
        ['pub', 'get'],
        workingDirectory: featurePath,
        runInShell: true,
      );

      if (result.exitCode != 0) {
        Logger.warning('Failed to install dependencies automatically');
        Logger.warning('Please run: cd $featurePath && dart pub get');
      }
    } catch (e) {
      Logger.warning('Could not install dependencies: $e');
      Logger.warning('Please run: cd $featurePath && dart pub get');
    }
  }

  static const String _reset = '\x1B[0m';
  static const String _green = '\x1B[32m';
  static const String _cyan = '\x1B[36m';
}
