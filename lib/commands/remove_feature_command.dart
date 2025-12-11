import 'dart:io';

import '../utils/logger.dart';
import '../utils/string_utils.dart';

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
        '❌ Please run this command from the project root directory!',
      );
      Logger.error(
        '   (The directory containing melos.yaml and packages/ folder)',
      );
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
    print('   • GoRoute from app_router.dart');
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

    // Remove from app_router.dart
    Logger.step('Removing from app_router.dart...');
    _removeFromAppRouter(snakeName, pascalName, camelName);
    Logger.success('Removed from app_router.dart');

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
   • Route constants from app_routes.dart
   • Navigation helper from app_routes.dart
   • GoRoute registration from app_router.dart

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
    String snakeName,
    String camelName,
    String pascalName,
  ) {
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

      // Remove route name constant
      final featureTitle = snakeName
          .split('_')
          .map((w) => w[0].toUpperCase() + w.substring(1))
          .join(' ');
      final routeNamePattern =
          '\n  // $featureTitle Routes\n  static const String $camelName = \'$snakeName\';\n';
      content = content.replaceAll(routeNamePattern, '');

      // Remove route path constant
      final routePathPattern =
          '  static const String ${camelName}Path = \'/$snakeName\';\n';
      content = content.replaceAll(routePathPattern, '');

      // Remove navigation helper (go_router pattern)
      final navHelperPattern =
          '\n  /// Navigate to $snakeName page\n  static void navigateTo$pascalName(BuildContext context) {\n    context.push(${camelName}Path);\n  }\n';
      content = content.replaceAll(navHelperPattern, '');

      appRoutesFile.writeAsStringSync(content);
    } catch (e) {
      Logger.warning('Error removing routes from app_routes.dart: $e');
    }
  }

  void _removeFromAppRouter(
    String snakeName,
    String pascalName,
    String camelName,
  ) {
    try {
      final currentDir = Directory.current.path;
      final appRouterPath =
          '$currentDir/packages/app/lib/routes/app_router.dart';
      final appRouterFile = File(appRouterPath);

      if (!appRouterFile.existsSync()) {
        Logger.warning('app_router.dart not found');
        return;
      }

      String content = appRouterFile.readAsStringSync();

      // Remove import (exact match)
      final importPattern =
          "import 'package:features_$snakeName/features_$snakeName.dart';\n";
      content = content.replaceAll(importPattern, '');

      // Remove GoRoute registration (exact match of what create command generates)
      final featureTitle = snakeName
          .split('_')
          .map((w) => w[0].toUpperCase() + w.substring(1))
          .join(' ');

      // Try to match the exact pattern with the comment line
      final goRoutePattern =
          '''
        // ==================== $featureTitle Routes ====================
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
''';

      if (content.contains(goRoutePattern)) {
        content = content.replaceAll(goRoutePattern, '');
      } else {
        // Fallback: try without the trailing newline
        final goRoutePatternAlt = goRoutePattern.trimRight();
        content = content.replaceAll(goRoutePatternAlt, '');
      }

      appRouterFile.writeAsStringSync(content);
    } catch (e) {
      Logger.warning('Error removing from app_router.dart: $e');
    }
  }

  static const String _reset = '\x1B[0m';
  static const String _cyan = '\x1B[36m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
}
