import 'dart:io';

import 'package:maloc_cli/utils/logger.dart';

/// Command to clean build artifacts and caches from all packages in a Maloc project.
///
/// This command removes:
/// - `build/` directories
/// - `.dart_tool/` directories
/// - Platform-specific build artifacts (Android, iOS, macOS, Linux, Windows, Web)
/// - Generated plugin files
/// - Lock files
///
/// Similar to running `flutter clean` but for the entire monorepo structure.
class CleanCommand {
  /// The target directory path. If null, uses current directory.
  final String? targetPath;

  /// Creates a new [CleanCommand] with optional [targetPath].
  CleanCommand(this.targetPath);

  /// Executes the clean command, removing build artifacts from all packages.
  ///
  /// Returns a [Future] that completes when the cleaning is done.
  /// Exits with code 1 if the target directory doesn't exist or isn't a valid project.
  Future<void> execute() async {
    Logger.header('Clean Maloc Project');

    // Determine target directory
    final target = targetPath ?? Directory.current.path;
    final targetDir = Directory(target);

    if (!targetDir.existsSync()) {
      Logger.error('Directory does not exist: $target');
      exit(1);
    }

    // Check if it's a valid project
    final packagesDir = Directory('${targetDir.path}/packages');
    if (!packagesDir.existsSync()) {
      Logger.error(
          'Not a valid Maloc project. "packages" directory not found.');
      Logger.info('Make sure you are in the project root directory.');
      exit(1);
    }

    Logger.step('Cleaning all packages...');
    print('');

    try {
      var successCount = 0;
      var failCount = 0;
      var totalSize = 0;

      // Clean packages directory
      await for (var entity in packagesDir.list()) {
        if (entity is Directory) {
          final pubspecFile = File('${entity.path}/pubspec.yaml');
          if (await pubspecFile.exists()) {
            final packageName = entity.path.split(Platform.pathSeparator).last;
            stdout.write('  ▸ $packageName... ');

            final size = await _cleanPackage(entity.path);

            if (size >= 0) {
              print('${Logger.green}✓${Logger.reset} (${_formatSize(size)})');
              successCount++;
              totalSize += size;
            } else {
              print('${Logger.red}✗${Logger.reset}');
              failCount++;
            }
          }
        }
      }

      // Clean CLI directory if exists
      final cliDir = Directory('${targetDir.path}/cli');
      final cliPubspec = File('${targetDir.path}/cli/pubspec.yaml');
      if (await cliDir.exists() && await cliPubspec.exists()) {
        stdout.write('  ▸ cli... ');

        final size = await _cleanPackage(cliDir.path);

        if (size >= 0) {
          print('${Logger.green}✓${Logger.reset} (${_formatSize(size)})');
          successCount++;
          totalSize += size;
        } else {
          print('${Logger.red}✗${Logger.reset}');
          failCount++;
        }
      }

      // Clean root level cache
      await _cleanRootCache(targetDir.path);

      print('');
      if (failCount == 0) {
        Logger.success(
            'All packages cleaned successfully! ($successCount packages, ${_formatSize(totalSize)} freed)');
      } else {
        Logger.warning(
            'Cleaned with errors: $successCount succeeded, $failCount failed');
        exit(1);
      }
    } catch (e) {
      Logger.error('Error during clean: $e');
      exit(1);
    }
  }

  /// Clean a single package directory
  /// Returns the total size freed in bytes, or -1 on error
  Future<int> _cleanPackage(String packagePath) async {
    var totalSize = 0;

    try {
      // Directories to clean
      final dirsToClean = [
        'build',
        '.dart_tool',
        'android/.gradle',
        'android/build',
        'android/app/build',
        'ios/.symlinks',
        'ios/Pods',
        'ios/.generated',
        'macos/.symlinks',
        'macos/Pods',
        'linux/flutter/ephemeral',
        'windows/flutter/ephemeral',
        'web/.dart_tool',
      ];

      for (final dirName in dirsToClean) {
        final dir = Directory('$packagePath/$dirName');
        if (await dir.exists()) {
          final size = await _getDirectorySize(dir);
          await dir.delete(recursive: true);
          totalSize += size;
        }
      }

      // Files to clean
      final filesToClean = [
        '.flutter-plugins',
        '.flutter-plugins-dependencies',
        '.packages',
        'pubspec.lock',
        'ios/Podfile.lock',
        'macos/Podfile.lock',
      ];

      for (final fileName in filesToClean) {
        final file = File('$packagePath/$fileName');
        if (await file.exists()) {
          final size = await file.length();
          await file.delete();
          totalSize += size;
        }
      }

      return totalSize;
    } catch (e) {
      return -1;
    }
  }

  /// Clean root-level cache directories
  Future<void> _cleanRootCache(String rootPath) async {
    try {
      final rootCacheDirs = [
        '.dart_tool',
        'build',
      ];

      for (final dirName in rootCacheDirs) {
        final dir = Directory('$rootPath/$dirName');
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      }
    } catch (e) {
      // Silently fail for root cache
    }
  }

  /// Calculate directory size recursively
  Future<int> _getDirectorySize(Directory directory) async {
    var size = 0;
    try {
      await for (var entity
          in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            size += await entity.length();
          } catch (e) {
            // Skip files we can't read
          }
        }
      }
    } catch (e) {
      // If we can't read the directory, return 0
    }
    return size;
  }

  /// Format bytes to human-readable size
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
