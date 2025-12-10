#!/usr/bin/env dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:maloc_cli/commands/create_feature_command.dart';
import 'package:maloc_cli/commands/create_project_command.dart';
import 'package:maloc_cli/commands/init_project_command.dart';
import 'package:maloc_cli/commands/remove_feature_command.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Show usage information')
    ..addFlag('version', abbr: 'v', negatable: false, help: 'Show version');

  // Add create project command
  parser.addCommand('create');

  // Add init project command
  parser.addCommand('init');

  // Add feature command with options
  final featureParser = ArgParser()
    ..addOption('name', abbr: 'n', help: 'Name of the feature to create');
  parser.addCommand('feature', featureParser);

  // Add remove command with options
  final removeParser = ArgParser()
    ..addOption('name', abbr: 'n', help: 'Name of the feature to remove');
  parser.addCommand('remove', removeParser);

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool || arguments.isEmpty) {
      _printHelp();
      return;
    }

    if (results['version'] as bool) {
      print('Maloc CLI version 1.1.0');
      return;
    }

    final command = results.command;
    if (command == null) {
      _printHelp();
      return;
    }

    switch (command.name) {
      case 'create':
        final projectName = command.rest.isNotEmpty ? command.rest.first : null;
        await CreateProjectCommand(projectName).execute();
        break;
      case 'init':
        final targetPath = command.rest.isNotEmpty ? command.rest.first : null;
        await InitProjectCommand(targetPath).execute();
        break;
      case 'feature':
        final featureName = command['name'] ??
            (command.rest.isNotEmpty ? command.rest.first : null);
        if (featureName == null) {
          print('❌ Error: Please provide a feature name');
          print('Usage: maloc feature <feature-name>');
          print('   or: maloc feature --name <feature-name>');
          exit(1);
        }
        await CreateFeatureCommand(featureName).execute();
        break;
      case 'remove':
        final featureName = command['name'] ??
            (command.rest.isNotEmpty ? command.rest.first : null);
        if (featureName == null) {
          print('❌ Error: Please provide a feature name');
          print('Usage: maloc remove <feature-name>');
          print('   or: maloc remove --name <feature-name>');
          exit(1);
        }
        await RemoveFeatureCommand(featureName).execute();
        break;
      default:
        print('Unknown command: ${command.name}');
        _printHelp();
        exit(1);
    }
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

void _printHelp() {
  print('''
╔═══════════════════════════════════════════════════════════╗
║              Maloc CLI - Flutter Generator                ║
║           Melos + BLoC Project Scaffolding                ║
╚═══════════════════════════════════════════════════════════╝

Usage: maloc <command> [arguments]

Commands:
  create <project-name>      Create a new Flutter project with Clean Architecture
  init [path]                Initialize template in current or specified directory
  feature <feature-name>     Generate a new feature module in existing project
  remove <feature-name>      Remove an existing feature module

Options:
  -h, --help                 Show this usage information
  -v, --version              Display version information

Examples:
  # Create a new project
  maloc create my_awesome_app

  # Add a feature to existing project
  maloc feature products
  maloc feature --name user_profile

  # Remove a feature
  maloc remove products
  maloc remove --name old_feature

For more information, visit:
  https://github.com/Farhan-S/flutter-dio-network-config
''');
}
