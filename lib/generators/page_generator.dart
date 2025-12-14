/// Generator for creating Flutter page widgets.
///
/// Generates page widgets with optional BLoC integration and data layer support.
class PageGenerator {
  /// Generates a Flutter page widget for the given feature.
  ///
  /// Parameters:
  /// - [snakeName]: Feature name in snake_case
  /// - [pascalName]: Feature name in PascalCase
  /// - [camelName]: Feature name in camelCase
  /// - [withData]: If true, generates page with full data layer integration
  ///
  /// Returns a string containing the complete page widget code.
  static String generate(String snakeName, String pascalName, String camelName,
      {bool withData = false}) {
    if (withData) {
      return _generateWithDataLayer(snakeName, pascalName, camelName);
    } else {
      return _generateSimple(snakeName, pascalName, camelName);
    }
  }

  static String _generateWithDataLayer(
      String snakeName, String pascalName, String camelName) {
    return '''import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/${snakeName}_bloc.dart';
import '../bloc/${snakeName}_event.dart';
import '../bloc/${snakeName}_state.dart';

/// $pascalName page
class ${pascalName}Page extends StatelessWidget {
  const ${pascalName}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$pascalName'),
      ),
      body: BlocBuilder<${pascalName}Bloc, ${pascalName}State>(
        builder: (context, state) {
          if (state is ${pascalName}Loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ${pascalName}Error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry logic
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ${pascalName}Loaded) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ID: \${state.$camelName.id}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Name: \${state.$camelName.name}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Welcome to $pascalName Page'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<${pascalName}Bloc>().add(
                      const Get${pascalName}Event('1'),
                    );
                  },
                  child: const Text('Load $pascalName'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
''';
  }

  static String _generateSimple(
      String snakeName, String pascalName, String camelName) {
    return '''import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/${snakeName}_bloc.dart';
import '../bloc/${snakeName}_event.dart';
import '../bloc/${snakeName}_state.dart';

/// $pascalName page
class ${pascalName}Page extends StatelessWidget {
  const ${pascalName}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$pascalName'),
      ),
      body: BlocBuilder<${pascalName}Bloc, ${pascalName}State>(
        builder: (context, state) {
          if (state is ${pascalName}Loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ${pascalName}Error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<${pascalName}Bloc>().add(
                        const Get${pascalName}Event('1'),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ${pascalName}Loaded) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Data: \${state.data}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Welcome to $pascalName Page'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<${pascalName}Bloc>().add(
                      const Get${pascalName}Event('1'),
                    );
                  },
                  child: const Text('Load $pascalName'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
''';
  }
}
