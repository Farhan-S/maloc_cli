import 'dart:io';

import 'package:maloc_cli/utils/logger.dart';

class PubGetCommand {
  final String? targetPath;

  PubGetCommand(this.targetPath);

  Future<void> execute() async {
    Logger.header('Get Dependencies for Maloc Project');

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

    Logger.step('Getting dependencies for all packages...');
    print('');

    try {
      var successCount = 0;
      var failCount = 0;

      // Get dependencies for packages
      await for (var entity in packagesDir.list()) {
        if (entity is Directory) {
          final pubspecFile = File('${entity.path}/pubspec.yaml');
          if (await pubspecFile.exists()) {
            final packageName = entity.path.split(Platform.pathSeparator).last;
            stdout.write('  ▸ $packageName... ');

            final result = await Process.run(
              'dart',
              ['pub', 'get'],
              workingDirectory: entity.path,
              runInShell: true,
            );

            if (result.exitCode == 0) {
              print('${Logger.green}✓${Logger.reset}');
              successCount++;
            } else {
              print('${Logger.red}✗${Logger.reset}');
              if (result.stderr.toString().isNotEmpty) {
                print('    ${result.stderr}');
              }
              failCount++;
            }
          }
        }
      }

      // Get dependencies for CLI if exists
      final cliDir = Directory('${targetDir.path}/cli');
      final cliPubspec = File('${targetDir.path}/cli/pubspec.yaml');
      if (await cliDir.exists() && await cliPubspec.exists()) {
        stdout.write('  ▸ cli... ');

        final result = await Process.run(
          'dart',
          ['pub', 'get'],
          workingDirectory: cliDir.path,
          runInShell: true,
        );

        if (result.exitCode == 0) {
          print('${Logger.green}✓${Logger.reset}');
          successCount++;
        } else {
          print('${Logger.red}✗${Logger.reset}');
          if (result.stderr.toString().isNotEmpty) {
            print('    ${result.stderr}');
          }
          failCount++;
        }
      }

      print('');
      if (failCount == 0) {
        Logger.success(
            'All packages bootstrapped successfully! ($successCount packages)');
      } else {
        Logger.warning(
            'Bootstrapped with errors: $successCount succeeded, $failCount failed');
        exit(1);
      }
    } catch (e) {
      Logger.error('Failed to bootstrap project: $e');
      exit(1);
    }
  }
}
