import 'dart:io';

import 'package:maloc_cli/utils/logger.dart';
import 'package:maloc_cli/utils/string_utils.dart';

class RemoveFeatureCommand {
  final String featureName;

  RemoveFeatureCommand(this.featureName);

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

    Logger.header('Removing Feature: $snakeName');

    // Check if feature exists
    final featurePath = '$currentDir/packages/features_$snakeName';
    final featureDir = Directory(featurePath);

    if (!featureDir.existsSync()) {
      Logger.error('Feature "features_$snakeName" does not exist!');
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

    // Ask for confirmation
    print('');
    print('${_red}⚠️  WARNING: This will permanently delete:$_reset');
    print('   • Feature directory: features_$snakeName');
    print('   • Route from app_routes.dart');
    print('   • Route from app_route_generator.dart');
    print('   • Dependency from app/pubspec.yaml');
    print('');
    stdout.write('Are you sure you want to continue? (yes/no): ');
    final confirmation = stdin.readLineSync()?.toLowerCase().trim();

    if (confirmation != 'yes' && confirmation != 'y') {
      Logger.warning('Operation cancelled.');
      exit(0);
    }

    print('');

    // Remove from app/pubspec.yaml
    Logger.step('Removing from app/pubspec.yaml...');
    _removeFromAppPubspec(snakeName);
    Logger.success('Removed from app/pubspec.yaml');

    // Remove routes from app_routes.dart
    Logger.step('Removing routes from app_routes.dart...');
    _removeRoutesFromAppRoutes(snakeName, camelName, pascalName);
    Logger.success('Removed routes from app_routes.dart');

    // Remove from app_route_generator.dart
    Logger.step('Removing from app_route_generator.dart...');
    _removeFromRouteGenerator(snakeName, pascalName, camelName);
    Logger.success('Removed from app_route_generator.dart');

    // Delete feature directory
    Logger.step('Deleting feature directory...');
    try {
      featureDir.deleteSync(recursive: true);
      Logger.success('Feature directory deleted');
    } catch (e) {
      Logger.error('Failed to delete feature directory: $e');
      exit(1);
    }

    Logger.header('Feature Removed Successfully! 🗑️');

    print('''
${_green}✨ What was removed:$_reset
   • Feature directory: packages/features_$snakeName
   • Dependency from app/pubspec.yaml
   • Route constant from app_routes.dart
   • Navigation helper from app_routes.dart
   • Route registration from app_route_generator.dart

${_yellow}⚠️  Don't forget to:$_reset
   1. Remove dependency registrations from app/lib/injection_container.dart
   2. Run: ${_cyan}flutter pub get${_reset} in the app package
''');
  }

  void _removeFromAppPubspec(String snakeName) {
    try {
      final currentDir = Directory.current.path;
      final appPubspecPath = '$currentDir/packages/app/pubspec.yaml';
      final appPubspecFile = File(appPubspecPath);

      if (!appPubspecFile.existsSync()) {
        Logger.warning('app/pubspec.yaml not found');
        return;
      }

      String content = appPubspecFile.readAsStringSync();
      final lines = content.split('\n');
      final newLines = <String>[];
      bool skipNext = false;

      for (int i = 0; i < lines.length; i++) {
        if (skipNext) {
          skipNext = false;
          continue;
        }

        if (lines[i].trim() == 'features_$snakeName:') {
          // Skip this line and the next line (path:)
          skipNext = true;
          continue;
        }

        newLines.add(lines[i]);
      }

      appPubspecFile.writeAsStringSync(newLines.join('\n'));
    } catch (e) {
      Logger.warning('Error removing from app/pubspec.yaml: $e');
    }
  }

  void _removeRoutesFromAppRoutes(
      String snakeName, String camelName, String pascalName) {
    try {
      final currentDir = Directory.current.path;
      final appRoutesPath =
          '$currentDir/packages/core/lib/src/routes/app_routes.dart';
      final appRoutesFile = File(appRoutesPath);

      if (!appRoutesFile.existsSync()) {
        Logger.warning('app_routes.dart not found');
        return;
      }

      String content = appRoutesFile.readAsStringSync();

      // Remove route constant (exact match of what create command generates)
      final featureTitle = snakeName
          .split('_')
          .map((w) => w[0].toUpperCase() + w.substring(1))
          .join(' ');
      final routeConstantPattern =
          '\n  // $featureTitle Routes\n  static const String $camelName = \'/$snakeName\';\n';
      content = content.replaceAll(routeConstantPattern, '');

      // Remove navigation helper (exact match of what create command generates)
      final navHelperPattern =
          '\n  /// Navigate to $snakeName page\n  static Future<void> navigateTo$pascalName(BuildContext context) {\n    return Navigator.pushNamed(context, $camelName);\n  }\n\n';
      content = content.replaceAll(navHelperPattern, '');

      appRoutesFile.writeAsStringSync(content);
    } catch (e) {
      Logger.warning('Error removing routes from app_routes.dart: $e');
    }
  }

  void _removeFromRouteGenerator(
      String snakeName, String pascalName, String camelName) {
    try {
      final currentDir = Directory.current.path;
      final routeGeneratorPath =
          '$currentDir/packages/app/lib/routes/app_route_generator.dart';
      final routeGeneratorFile = File(routeGeneratorPath);

      if (!routeGeneratorFile.existsSync()) {
        Logger.warning('app_route_generator.dart not found');
        return;
      }

      String content = routeGeneratorFile.readAsStringSync();

      // Remove import (exact match)
      final importPattern =
          "import 'package:features_$snakeName/features_$snakeName.dart';\n";
      content = content.replaceAll(importPattern, '');

      // Remove switch case (exact match)
      final switchCasePattern =
          '\n      case AppRoutes.$camelName:\n        return _createRoute(\n          BlocProvider(\n            create: (_) => getIt<${pascalName}Bloc>(),\n            child: const ${pascalName}Page(),\n          ),\n          settings,\n        );\n';
      content = content.replaceAll(switchCasePattern, '');

      // Remove route registration (exact match of what create command generates)
      final registrationPattern = '''
    
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
      content = content.replaceAll(registrationPattern, '');

      routeGeneratorFile.writeAsStringSync(content);
    } catch (e) {
      Logger.warning('Error removing from app_route_generator.dart: $e');
    }
  }

  static const String _reset = '\x1B[0m';
  static const String _cyan = '\x1B[36m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
}
