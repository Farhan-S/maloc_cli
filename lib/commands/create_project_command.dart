import 'dart:io';

import 'package:maloc_cli/utils/logger.dart';

class CreateProjectCommand {
  final String? projectName;

  CreateProjectCommand(this.projectName);

  Future<void> execute() async {
    Logger.header('Create New Maloc Project');

    // Get project name
    String name = projectName ?? _promptForInput('Project name');
    name = name.trim().toLowerCase().replaceAll(' ', '_');

    if (name.isEmpty) {
      Logger.error('Project name cannot be empty!');
      exit(1);
    }

    // Validate project name
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
      Logger.error(
          'Invalid project name! Use lowercase letters, numbers, and underscores only.');
      exit(1);
    }

    // Check if directory already exists
    final projectDir = Directory(name);
    if (projectDir.existsSync()) {
      Logger.error('Directory "$name" already exists!');
      exit(1);
    }

    // Get additional info
    final packageName = _promptForInput(
      'Package name (e.g., com.company.appname)',
      defaultValue: 'com.example.$name',
    );
    final description = _promptForInput(
      'Project description',
      defaultValue: 'A new Flutter project with Clean Architecture',
    );

    Logger.header('Creating Project: $name');
    print('');

    try {
      // Step 1: Clone from GitHub template
      Logger.step('Cloning template from GitHub...');
      final cloneResult = await Process.run(
        'git',
        [
          'clone',
          'https://github.com/Farhan-S/flutter-dio-network-config.git',
          name,
        ],
      );

      if (cloneResult.exitCode != 0) {
        Logger.error('Failed to clone template repository');
        print(cloneResult.stderr);
        exit(1);
      }
      Logger.success('Template cloned successfully');

      // Step 2: Remove old git history
      Logger.step('Initializing new git repository...');
      await Process.run('rm', ['-rf', '$name/.git']);
      await Process.run('git', ['-C', name, 'init']);
      Logger.success('Git repository initialized');

      // Step 3: Remove old CLI folder
      Logger.step('Cleaning up template...');
      final oldCliDir = Directory('$name/cli');
      if (oldCliDir.existsSync()) {
        oldCliDir.deleteSync(recursive: true);
      }
      Logger.success('Template cleaned');

      // Step 4: Update pubspec.yaml files
      Logger.step('Updating project configuration...');
      await _updatePubspecFiles(name, packageName, description);
      Logger.success('Configuration updated');

      // Step 5: Run melos bootstrap
      Logger.step('Installing dependencies (this may take a while)...');
      final bootstrapResult = await Process.run(
        'dart',
        ['$name/bootstrap.dart'],
        workingDirectory: name,
      );

      if (bootstrapResult.exitCode == 0) {
        Logger.success('Dependencies installed');
      } else {
        Logger.warning(
            'Some dependencies failed to install. You can run "dart bootstrap.dart" later.');
      }

      // Step 6: Initial git commit
      Logger.step('Creating initial commit...');
      await Process.run('git', ['-C', name, 'add', '.']);
      await Process.run('git', ['-C', name, 'commit', '-m', 'Initial commit']);
      Logger.success('Initial commit created');

      Logger.header('Project Created Successfully! 🎉');
      print('''

${Logger.green}✨ Next steps:${Logger.reset}

1. Navigate to your project:
   ${Logger.cyan}cd $name${Logger.reset}

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
      Logger.error('Failed to create project: $e');
      // Cleanup on failure
      if (projectDir.existsSync()) {
        Logger.step('Cleaning up...');
        projectDir.deleteSync(recursive: true);
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

  Future<void> _updatePubspecFiles(
    String projectName,
    String packageName,
    String description,
  ) async {
    // Update main pubspec.yaml
    final mainPubspec = File('$projectName/pubspec.yaml');
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
    final appPubspec = File('$projectName/packages/app/pubspec.yaml');
    if (appPubspec.existsSync()) {
      var content = appPubspec.readAsStringSync();
      content = content.replaceAll(
        'name: app',
        'name: $projectName',
      );
      content = content.replaceAll(
        'description: Main application package',
        'description: $description',
      );
      appPubspec.writeAsStringSync(content);
    }

    // Update Android package name
    await _updateAndroidPackageName(projectName, packageName);

    // Update iOS bundle identifier
    await _updateIOSBundleId(projectName, packageName);
  }

  Future<void> _updateAndroidPackageName(
    String projectName,
    String packageName,
  ) async {
    final buildGradle =
        File('$projectName/packages/app/android/app/build.gradle');
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
      String projectName, String packageName) async {
    // Update Info.plist if needed
    final infoPlist = File('$projectName/packages/app/ios/Runner/Info.plist');
    if (infoPlist.existsSync()) {
      var content = infoPlist.readAsStringSync();
      content = content.replaceAll(
        'com.example.app',
        packageName,
      );
      infoPlist.writeAsStringSync(content);
    }
  }
}
