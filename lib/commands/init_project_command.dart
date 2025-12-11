import 'dart:io';

import '../utils/logger.dart';

class InitProjectCommand {
  final String? targetPath;

  InitProjectCommand(this.targetPath);

  Future<void> execute() async {
    Logger.header('Initialize Maloc Project');

    // Determine target directory
    final target = targetPath ?? Directory.current.path;
    final targetDir = Directory(target);

    // Get project name from directory name
    final projectName = targetDir.absolute.path
        .split(Platform.pathSeparator)
        .last;

    // Check if directory exists, create if not
    if (!targetDir.existsSync()) {
      Logger.step('Creating directory: $target');
      targetDir.createSync(recursive: true);
    }

    // Check if directory is empty
    final contents = targetDir.listSync();
    if (contents.isNotEmpty) {
      Logger.warning('Directory is not empty!');
      stdout.write('Continue anyway? (y/n): ');
      final response = stdin.readLineSync()?.toLowerCase().trim();
      if (response != 'y' && response != 'yes') {
        Logger.info('Operation cancelled.');
        exit(0);
      }
    }

    // Get additional info
    final packageName = _promptForInput(
      'Package name (e.g., com.company.appname)',
      defaultValue: 'com.example.$projectName',
    );
    final description = _promptForInput(
      'Project description',
      defaultValue: 'A new Flutter project with Clean Architecture',
    );

    Logger.header('Initializing Project: $projectName');
    print('');

    try {
      // Step 1: Download template from GitHub
      Logger.step('Downloading template from GitHub...');
      final tempDir = Directory('${targetDir.path}/.maloc_temp');

      final cloneResult = await Process.run('git', [
        'clone',
        '--depth=1',
        'https://github.com/Farhan-S/flutter_monorepo_clean_architecture.git',
        tempDir.path,
      ]);

      if (cloneResult.exitCode != 0) {
        Logger.error('Failed to download template repository');
        print(cloneResult.stderr);
        exit(1);
      }
      Logger.success('Template downloaded successfully');

      // Step 2: Copy template files to target directory
      Logger.step('Extracting template files...');
      await _copyDirectory(tempDir, targetDir, exclude: ['.git', 'cli']);
      Logger.success('Template files extracted');

      // Step 3: Clean up temporary directory
      Logger.step('Cleaning up...');
      tempDir.deleteSync(recursive: true);
      Logger.success('Cleanup complete');

      // Step 4: Initialize git repository if not exists
      final gitDir = Directory('${targetDir.path}/.git');
      if (!gitDir.existsSync()) {
        Logger.step('Initializing git repository...');
        await Process.run('git', ['init'], workingDirectory: targetDir.path);
        Logger.success('Git repository initialized');
      }

      // Step 5: Update pubspec.yaml files
      Logger.step('Updating project configuration...');
      await _updatePubspecFiles(
        targetDir.path,
        projectName,
        packageName,
        description,
      );
      Logger.success('Configuration updated');

      // Step 6: Run melos bootstrap
      Logger.step('Installing dependencies (this may take a while)...');
      final bootstrapFile = File('${targetDir.path}/bootstrap.dart');
      if (bootstrapFile.existsSync()) {
        final bootstrapResult = await Process.run('dart', [
          'bootstrap.dart',
        ], workingDirectory: targetDir.path);

        if (bootstrapResult.exitCode == 0) {
          Logger.success('Dependencies installed');
        } else {
          Logger.warning(
            'Some dependencies failed to install. You can run "dart bootstrap.dart" later.',
          );
        }
      } else {
        Logger.warning(
          'bootstrap.dart not found. Skipping dependency installation.',
        );
      }

      // Step 7: Initial git commit (if new repo)
      if (!gitDir.existsSync() || (await _isGitRepoEmpty(targetDir.path))) {
        Logger.step('Creating initial commit...');
        await Process.run('git', [
          'add',
          '.',
        ], workingDirectory: targetDir.path);
        await Process.run('git', [
          'commit',
          '-m',
          'Initial commit',
        ], workingDirectory: targetDir.path);
        Logger.success('Initial commit created');
      }

      Logger.header('Project Initialized Successfully! 🎉');
      print('''

${Logger.green}✨ Next steps:${Logger.reset}

1. Navigate to your project (if not already there):
   ${Logger.cyan}cd $target${Logger.reset}

2. Open in your IDE:
   ${Logger.cyan}code .${Logger.reset}  or  ${Logger.cyan}open -a "Android Studio" .${Logger.reset}

3. Run the app:
   ${Logger.cyan}flutter run${Logger.reset}

4. Create a new feature:
   ${Logger.cyan}maloc feature feature_name${Logger.reset}

${Logger.yellow}📚 Documentation:${Logger.reset}
   • README.md - Project overview and setup
   • Check packages/ folder for modular structure

${Logger.green}Happy coding! 🚀${Logger.reset}
''');
    } catch (e) {
      Logger.error('Failed to initialize project: $e');
      // Cleanup temp directory on failure
      final tempDir = Directory('${targetDir.path}/.maloc_temp');
      if (tempDir.existsSync()) {
        Logger.step('Cleaning up...');
        tempDir.deleteSync(recursive: true);
      }
      exit(1);
    }
  }

  String _promptForInput(String prompt, {String? defaultValue}) {
    if (defaultValue != null) {
      stdout.write('$prompt [$defaultValue]: ');
    } else {
      stdout.write('$prompt: ');
    }

    final input = stdin.readLineSync()?.trim() ?? '';
    return input.isEmpty && defaultValue != null ? defaultValue : input;
  }

  Future<void> _copyDirectory(
    Directory source,
    Directory destination, {
    List<String> exclude = const [],
  }) async {
    await for (final entity in source.list(recursive: false)) {
      final name = entity.path.split(Platform.pathSeparator).last;

      // Skip excluded files/folders
      if (exclude.contains(name)) {
        continue;
      }

      if (entity is Directory) {
        final newDirectory = Directory('${destination.path}/$name');
        if (!newDirectory.existsSync()) {
          newDirectory.createSync(recursive: true);
        }
        await _copyDirectory(entity, newDirectory, exclude: exclude);
      } else if (entity is File) {
        final newFile = File('${destination.path}/$name');
        await entity.copy(newFile.path);
      }
    }
  }

  Future<void> _updatePubspecFiles(
    String projectPath,
    String projectName,
    String packageName,
    String description,
  ) async {
    // Update main pubspec.yaml
    final mainPubspec = File('$projectPath/pubspec.yaml');
    if (mainPubspec.existsSync()) {
      var content = mainPubspec.readAsStringSync();
      content = content.replaceAll(
        'name: dio_network_config',
        'name: $projectName',
      );
      content = content.replaceAll(
        'description: A Flutter project demonstrating Clean Architecture with Dio network configuration.',
        'description: $description',
      );
      mainPubspec.writeAsStringSync(content);
    }

    // Update app pubspec.yaml
    final appPubspec = File('$projectPath/packages/app/pubspec.yaml');
    if (appPubspec.existsSync()) {
      var content = appPubspec.readAsStringSync();
      content = content.replaceAll('name: app', 'name: $projectName');
      content = content.replaceAll(
        'description: Main application package',
        'description: $description',
      );
      appPubspec.writeAsStringSync(content);
    }

    // Update Android package name
    await _updateAndroidPackageName(projectPath, packageName);

    // Update iOS bundle identifier
    await _updateIOSBundleId(projectPath, packageName);
  }

  Future<void> _updateAndroidPackageName(
    String projectPath,
    String packageName,
  ) async {
    final buildGradle = File(
      '$projectPath/packages/app/android/app/build.gradle',
    );
    if (buildGradle.existsSync()) {
      var content = buildGradle.readAsStringSync();
      content = content.replaceAll(
        RegExp(r'applicationId\s+"[^"]+"'),
        'applicationId "$packageName"',
      );
      buildGradle.writeAsStringSync(content);
    }
  }

  Future<void> _updateIOSBundleId(
    String projectPath,
    String packageName,
  ) async {
    // Update Info.plist if needed
    final infoPlist = File('$projectPath/packages/app/ios/Runner/Info.plist');
    if (infoPlist.existsSync()) {
      var content = infoPlist.readAsStringSync();
      content = content.replaceAll('com.example.app', packageName);
      infoPlist.writeAsStringSync(content);
    }
  }

  Future<bool> _isGitRepoEmpty(String path) async {
    final result = await Process.run('git', [
      'rev-list',
      '--all',
      '--count',
    ], workingDirectory: path);
    return result.stdout.toString().trim() == '0';
  }
}
