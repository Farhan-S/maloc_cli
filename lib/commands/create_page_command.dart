import 'dart:io';

import 'package:maloc_cli/generators/bloc_generator.dart';
import 'package:maloc_cli/generators/datasource_generator.dart';
import 'package:maloc_cli/generators/entity_generator.dart';
import 'package:maloc_cli/generators/model_generator.dart';
import 'package:maloc_cli/generators/page_generator.dart';
import 'package:maloc_cli/generators/repository_generator.dart';
import 'package:maloc_cli/generators/repository_impl_generator.dart';
import 'package:maloc_cli/generators/usecase_generator.dart';
import 'package:maloc_cli/utils/logger.dart';
import 'package:maloc_cli/utils/string_utils.dart';

class CreatePageCommand {
  final String featureName;
  final String pageName;
  final bool withBloc;
  final bool withData;

  CreatePageCommand(
    this.featureName,
    this.pageName, {
    this.withBloc = true,
    this.withData = false,
  });

  Future<void> execute() async {
    final snakeFeatureName = StringUtils.toSnakeCase(featureName);
    final snakePageName = StringUtils.toSnakeCase(pageName);
    final pascalPageName = StringUtils.toPascalCase(pageName);
    final camelPageName = StringUtils.toCamelCase(pageName);

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

    Logger.header(
        'Creating Page: $snakePageName in feature: $snakeFeatureName');

    // Determine packages path
    final packagesPath =
        currentDir.endsWith('packages') ? currentDir : '$currentDir/packages';

    final featurePath = '$packagesPath/features_$snakeFeatureName';

    // Check if feature exists
    if (!Directory(featurePath).existsSync()) {
      Logger.error('❌ Feature "features_$snakeFeatureName" does not exist!');
      print('');
      print('${_yellow}Available features:$_reset');
      final features = packagesDir
          .listSync()
          .whereType<Directory>()
          .where((d) => d.path.split('/').last.startsWith('features_'))
          .toList();

      if (features.isEmpty) {
        print('${_yellow}  No features found. Create one with:$_reset');
        print('  ${_cyan}maloc feature <feature-name>$_reset');
      } else {
        for (var feature in features) {
          print('${_yellow}  • ${feature.path.split('/').last}$_reset');
        }
      }
      exit(1);
    }

    final pagesPath = '$featurePath/lib/presentation/pages';
    final pageFile = '$pagesPath/${snakePageName}_page.dart';

    // Check if page already exists
    if (File(pageFile).existsSync()) {
      Logger.error('❌ Page "${snakePageName}_page.dart" already exists!');
      exit(1);
    }

    try {
      // Create pages directory if it doesn't exist
      Directory(pagesPath).createSync(recursive: true);

      // Generate BLoC files if requested
      if (withBloc) {
        Logger.step('Generating BLoC files...');
        _generateBlocFiles(
            featurePath, snakePageName, pascalPageName, camelPageName);
        Logger.success('Generated BLoC files');
      }

      // Generate data and domain layers if requested
      if (withData) {
        Logger.step('Generating domain layer...');
        _generateDomainLayer(
            featurePath, snakePageName, pascalPageName, camelPageName);
        Logger.success('Generated domain layer');

        Logger.step('Generating data layer...');
        _generateDataLayer(
            featurePath, snakePageName, pascalPageName, camelPageName);
        Logger.success('Generated data layer');
      }

      // Generate page content
      Logger.step('Generating page...');
      final pageContent = withBloc
          ? PageGenerator.generate(snakePageName, pascalPageName, camelPageName,
              withData: withData)
          : _generatePageContent(snakePageName, pascalPageName, camelPageName);
      _writeFile(pageFile, pageContent);
      Logger.success('Generated ${snakePageName}_page.dart');

      // Update barrel export file
      Logger.step('Updating barrel export...');
      _updateBarrelExports(featurePath, snakePageName, snakeFeatureName);
      Logger.success('Updated features_$snakeFeatureName.dart');

      // Add route to app_routes.dart
      Logger.step('Adding route to app_routes.dart...');
      _addRouteToAppRoutes(snakePageName, pascalPageName, camelPageName);
      Logger.success('Route added to app_routes.dart');

      // Register route in app_router.dart
      Logger.step('Registering route in app_router.dart...');
      _registerRouteInAppRouter(
          snakePageName, pascalPageName, camelPageName, snakeFeatureName);
      Logger.success('Route registered in app_router.dart');

      // Register in dependency injection
      if (withBloc) {
        Logger.step('Registering in dependency injection...');
        _registerInDI(snakePageName, pascalPageName, withData);
        Logger.success('Registered in injection_container.dart');
      }

      Logger.header('Page Created Successfully! 🎉');
      print('');
      print('${_green}✨ What was generated:$_reset');
      print('   • Page: ${snakePageName}_page.dart');
      if (withBloc) {
        print('   • BLoC: ${snakePageName}_bloc.dart');
        print('   • Events: ${snakePageName}_event.dart');
        print('   • States: ${snakePageName}_state.dart');
      }
      if (withData) {
        print('   • Entity: ${snakePageName}_entity.dart');
        print('   • Repository: ${snakePageName}_repository.dart');
        print('   • Use Case: get_${snakePageName}_usecase.dart');
        print('   • Model: ${snakePageName}_model.dart');
        print('   • DataSource: ${snakePageName}_remote_datasource.dart');
        print(
            '   • Repository Implementation: ${snakePageName}_repository_impl.dart');
      }
      print('   • Route: AppRoutes.${camelPageName}Path = \'/$snakePageName\'');
      if (withBloc) {
        print('   • Dependency Injection: ${pascalPageName}Bloc registered');
      }
      print('');
      print('${_green}✨ What was done automatically:$_reset');
      print('   • Added route to app_routes.dart');
      print('   • Registered GoRoute in app_router.dart');
      if (withBloc) {
        print('   • Registered dependencies in injection_container.dart');
      }
      print('');
      print('${_yellow}🚀 Ready to use!$_reset');
      print(
          '   Navigate with: ${_cyan}AppRoutes.navigateTo${pascalPageName}(context)$_reset');
      print('');
    } catch (e) {
      Logger.error('Error creating page: $e');
      exit(1);
    }
  }

  void _generateBlocFiles(String featurePath, String snakeName,
      String pascalName, String camelName) {
    final blocPath = '$featurePath/lib/presentation/bloc';
    Directory(blocPath).createSync(recursive: true);

    final blocFiles = BlocGenerator.generate(snakeName, pascalName, camelName,
        withData: withData);
    _writeFile('$blocPath/${snakeName}_bloc.dart', blocFiles['bloc']!);
    _writeFile('$blocPath/${snakeName}_event.dart', blocFiles['event']!);
    _writeFile('$blocPath/${snakeName}_state.dart', blocFiles['state']!);
  }

  void _generateDomainLayer(String featurePath, String snakeName,
      String pascalName, String camelName) {
    // Entity
    final entityPath = '$featurePath/lib/domain/entities';
    Directory(entityPath).createSync(recursive: true);
    final entityContent = EntityGenerator.generate(snakeName, pascalName);
    _writeFile('$entityPath/${snakeName}_entity.dart', entityContent);

    // Repository interface
    final repoPath = '$featurePath/lib/domain/repositories';
    Directory(repoPath).createSync(recursive: true);
    final repoContent = RepositoryGenerator.generate(snakeName, pascalName);
    _writeFile('$repoPath/${snakeName}_repository.dart', repoContent);

    // Use case
    final usecasePath = '$featurePath/lib/domain/usecases';
    Directory(usecasePath).createSync(recursive: true);
    final usecaseContent =
        UseCaseGenerator.generate(snakeName, pascalName, camelName);
    _writeFile('$usecasePath/get_${snakeName}_usecase.dart', usecaseContent);
  }

  void _generateDataLayer(String featurePath, String snakeName,
      String pascalName, String camelName) {
    // Model
    final modelPath = '$featurePath/lib/data/models';
    Directory(modelPath).createSync(recursive: true);
    final modelContent = ModelGenerator.generate(snakeName, pascalName);
    _writeFile('$modelPath/${snakeName}_model.dart', modelContent);

    // Remote DataSource
    final datasourcePath = '$featurePath/lib/data/datasources';
    Directory(datasourcePath).createSync(recursive: true);
    final datasourceContent =
        DataSourceGenerator.generate(snakeName, pascalName);
    _writeFile('$datasourcePath/${snakeName}_remote_datasource.dart',
        datasourceContent);

    // Repository Implementation
    final repoImplPath = '$featurePath/lib/data/repositories';
    Directory(repoImplPath).createSync(recursive: true);
    final repoImplContent =
        RepositoryImplGenerator.generate(snakeName, pascalName, camelName);
    _writeFile(
        '$repoImplPath/${snakeName}_repository_impl.dart', repoImplContent);
  }

  String _generatePageContent(
    String snakeName,
    String pascalName,
    String camelName,
  ) {
    return '''import 'package:flutter/material.dart';

/// $pascalName page
class ${pascalName}Page extends StatelessWidget {
  const ${pascalName}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$pascalName'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.note_add,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              '$pascalName Page',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'This page was generated with Maloc CLI',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
''';
  }

  void _updateBarrelExports(
      String featurePath, String snakePageName, String snakeFeatureName) {
    final barrelFile = File('$featurePath/lib/features_$snakeFeatureName.dart');

    if (!barrelFile.existsSync()) {
      Logger.warning('Barrel export file not found, skipping update');
      return;
    }

    String content = barrelFile.readAsStringSync();
    final exports = <String>[];

    // Domain exports
    if (withData) {
      exports.add("export 'domain/entities/${snakePageName}_entity.dart';");
      exports.add(
          "export 'domain/repositories/${snakePageName}_repository.dart';");
      exports
          .add("export 'domain/usecases/get_${snakePageName}_usecase.dart';");
    }

    // Data exports
    if (withData) {
      exports.add("export 'data/models/${snakePageName}_model.dart';");
      exports.add(
          "export 'data/datasources/${snakePageName}_remote_datasource.dart';");
      exports.add(
          "export 'data/repositories/${snakePageName}_repository_impl.dart';");
    }

    // Presentation exports
    if (withBloc) {
      exports.add("export 'presentation/bloc/${snakePageName}_bloc.dart';");
      exports.add("export 'presentation/bloc/${snakePageName}_event.dart';");
      exports.add("export 'presentation/bloc/${snakePageName}_state.dart';");
    }
    exports.add("export 'presentation/pages/${snakePageName}_page.dart';");

    // Add exports to the barrel file
    for (var export in exports) {
      if (content.contains(export)) {
        continue; // Skip if already exists
      }

      // Determine where to insert based on the layer
      String? section;
      if (export.contains('domain/entities')) {
        section = '// Domain Layer';
      } else if (export.contains('domain/repositories')) {
        section = '// Domain Layer';
      } else if (export.contains('domain/usecases')) {
        section = '// Domain Layer';
      } else if (export.contains('data/models')) {
        section = '// Data Layer';
      } else if (export.contains('data/')) {
        section = '// Data Layer';
      } else if (export.contains('presentation/bloc')) {
        section = '// Presentation Layer';
      } else if (export.contains('presentation/pages')) {
        section = '// Presentation Layer';
      }

      int? insertPosition;
      if (section != null && content.contains(section)) {
        // Find the last export in this section
        final sectionIndex = content.indexOf(section);
        final nextSectionIndex =
            content.indexOf('//', sectionIndex + section.length);

        if (nextSectionIndex != -1) {
          // Find the last export before the next section
          final sectionContent =
              content.substring(sectionIndex, nextSectionIndex);
          final lastExportIndex = sectionContent.lastIndexOf("export '");
          if (lastExportIndex != -1) {
            final lineEnd =
                content.indexOf('\n', sectionIndex + lastExportIndex);
            insertPosition = lineEnd + 1;
          } else {
            // No exports in this section yet, add after the comment
            insertPosition = sectionIndex + section.length + 1;
          }
        } else {
          // This is the last section
          final lastExportIndex =
              content.lastIndexOf("export '", content.length);
          if (lastExportIndex > sectionIndex) {
            final lineEnd = content.indexOf('\n', lastExportIndex);
            insertPosition = lineEnd + 1;
          } else {
            insertPosition = sectionIndex + section.length + 1;
          }
        }
      }

      if (insertPosition != null) {
        content = content.substring(0, insertPosition) +
            '$export\n' +
            content.substring(insertPosition);
      } else {
        // Fallback: add at the end
        if (!content.endsWith('\n')) {
          content += '\n';
        }
        content += '$export\n';
      }
    }

    barrelFile.writeAsStringSync(content);
  }

  void _addRouteToAppRoutes(
      String snakeName, String pascalName, String camelName) {
    try {
      final currentDir = Directory.current.path;
      final appRoutesPath =
          '$currentDir/packages/core/lib/src/routes/app_routes.dart';
      final appRoutesFile = File(appRoutesPath);

      if (!appRoutesFile.existsSync()) {
        Logger.warning(
            'app_routes.dart not found, skipping route registration');
        return;
      }

      String content = appRoutesFile.readAsStringSync();

      // Check if route already exists
      if (content.contains("static const String $camelName = ")) {
        Logger.warning('Route $camelName already exists in app_routes.dart');
        return;
      }

      // Add route name constant
      final routeNamesSection = '// User Routes';
      final routeNamesIndex = content.indexOf(routeNamesSection);

      if (routeNamesIndex != -1) {
        final lineEnd = content.indexOf('\n', routeNamesIndex);
        final insertPosition = content.indexOf('\n', lineEnd + 1) + 1;

        final routeNameConstant =
            "  static const String $camelName = '$snakeName';\n";
        content = content.substring(0, insertPosition) +
            routeNameConstant +
            content.substring(insertPosition);
      }

      // Add route path constant
      final routePathsSection = '// Root paths';
      final routePathsIndex = content.indexOf(routePathsSection);

      if (routePathsIndex != -1) {
        // Find the last path constant
        final lastPathIndex = content.lastIndexOf('Path = ',
            content.indexOf('// ==================== Route Parameters'));
        if (lastPathIndex != -1) {
          final lineEnd = content.indexOf('\n', lastPathIndex);
          final insertPosition = lineEnd + 1;

          final routePathConstant =
              "  static const String ${camelName}Path = '/$snakeName';\n";
          content = content.substring(0, insertPosition) +
              routePathConstant +
              content.substring(insertPosition);
        }
      }

      // Add navigation helper
      final helpersIndex = content.lastIndexOf('/// Navigate to settings page');

      if (helpersIndex != -1) {
        final methodEnd = content.indexOf('}', helpersIndex);
        final insertPosition = content.indexOf('\n', methodEnd) + 1;

        final navigationHelper = '''
  /// Navigate to $snakeName page
  static void navigateTo$pascalName(BuildContext context) {
    context.push(${camelName}Path);
  }
''';

        content = content.substring(0, insertPosition) +
            navigationHelper +
            content.substring(insertPosition);
      }

      appRoutesFile.writeAsStringSync(content);
    } catch (e) {
      Logger.warning('Error adding route to app_routes.dart: $e');
    }
  }

  void _registerRouteInAppRouter(String snakeName, String pascalName,
      String camelName, String snakeFeatureName) {
    try {
      final currentDir = Directory.current.path;
      final appRouterPath =
          '$currentDir/packages/app/lib/routes/app_router.dart';
      final appRouterFile = File(appRouterPath);

      if (!appRouterFile.existsSync()) {
        Logger.warning(
            'app_router.dart not found, skipping route registration');
        return;
      }

      String content = appRouterFile.readAsStringSync();

      // Check if route already registered
      if (content.contains("path: AppRoutes.${camelName}Path")) {
        Logger.warning(
            'Route $camelName already registered in app_router.dart');
        return;
      }

      // Add import if not exists
      final featureImport =
          "import 'package:features_$snakeFeatureName/features_$snakeFeatureName.dart';";
      if (!content.contains(featureImport)) {
        final lastImportIndex =
            content.lastIndexOf("import '../injection_container.dart';");
        if (lastImportIndex != -1) {
          final lineEnd = content.indexOf('\n', lastImportIndex);
          content = content.substring(0, lineEnd + 1) +
              '$featureImport\n' +
              content.substring(lineEnd + 1);
        }
      }

      // Add GoRoute before the closing ],
      final routesEndPattern = '      ],';
      final routesEndIndex = content.lastIndexOf(routesEndPattern);

      if (routesEndIndex != -1) {
        final newRoute = withBloc
            ? '''
        // ==================== $pascalName Route ====================
        GoRoute(
          path: AppRoutes.${camelName}Path,
          name: AppRoutes.$camelName,
          pageBuilder: (context, state) => _buildPageWithTransition(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) => getIt<${pascalName}Bloc>(),
              child: const ${pascalName}Page(),
            ),
          ),
        ),

'''
            : '''
        // ==================== $pascalName Route ====================
        GoRoute(
          path: AppRoutes.${camelName}Path,
          name: AppRoutes.$camelName,
          pageBuilder: (context, state) => _buildPageWithTransition(
            key: state.pageKey,
            child: const ${pascalName}Page(),
          ),
        ),

''';

        content = content.substring(0, routesEndIndex) +
            newRoute +
            content.substring(routesEndIndex);

        appRouterFile.writeAsStringSync(content);
      }
    } catch (e) {
      Logger.warning('Error registering route in app_router.dart: $e');
    }
  }

  void _registerInDI(String snakeName, String pascalName, bool withData) {
    try {
      final currentDir = Directory.current.path;
      final diPath = '$currentDir/packages/app/lib/injection_container.dart';
      final diFile = File(diPath);

      if (!diFile.existsSync()) {
        Logger.warning(
            'injection_container.dart not found, skipping DI registration');
        return;
      }

      String content = diFile.readAsStringSync();

      // Check if BLoC already registered
      if (content.contains("getIt.registerFactory<${pascalName}Bloc>")) {
        Logger.warning(
            '${pascalName}Bloc already registered in injection_container.dart');
        return;
      }

      String registrations = '';

      if (withData) {
        // Register DataSource
        registrations += '''
  // ${pascalName} Data Sources
  getIt.registerLazySingleton<${pascalName}RemoteDataSource>(
    () => ${pascalName}RemoteDataSource(getIt<DioClient>()),
  );

''';

        // Register Repository
        registrations += '''
  // ${pascalName} Repositories
  getIt.registerLazySingleton<${pascalName}Repository>(
    () => ${pascalName}RepositoryImpl(getIt<${pascalName}RemoteDataSource>()),
  );

''';

        // Register Use Case
        registrations += '''
  // ${pascalName} Use Cases
  getIt.registerLazySingleton<Get${pascalName}UseCase>(
    () => Get${pascalName}UseCase(getIt<${pascalName}Repository>()),
  );

''';

        // Register BLoC
        registrations += '''
  // ${pascalName} BLoC
  getIt.registerFactory<${pascalName}Bloc>(
    () => ${pascalName}Bloc(getIt<Get${pascalName}UseCase>()),
  );

''';
      } else {
        // Register BLoC only
        registrations += '''
  // ${pascalName} BLoC
  getIt.registerFactory<${pascalName}Bloc>(
    () => ${pascalName}Bloc(),
  );

''';
      }

      // Find where to insert (before the closing })
      final closingBraceIndex = content.lastIndexOf('}');
      if (closingBraceIndex != -1) {
        content = content.substring(0, closingBraceIndex) +
            registrations +
            content.substring(closingBraceIndex);

        diFile.writeAsStringSync(content);
      }
    } catch (e) {
      Logger.warning('Error registering in injection_container.dart: $e');
    }
  }

  void _writeFile(String path, String content) {
    final file = File(path);
    file.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  static const String _reset = '\x1B[0m';
  static const String _cyan = '\x1B[36m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
}
