class PageGenerator {
  static String generate(
      String snakeName, String pascalName, String camelName) {
    return '''import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/${snakeName}_bloc.dart';
import '../bloc/${snakeName}_event.dart';
import '../bloc/${snakeName}_state.dart';

/// ${pascalName} page
class ${pascalName}Page extends StatelessWidget {
  const ${pascalName}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('${pascalName}'),
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
                    'ID: \${state.${camelName}.id}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Name: \${state.${camelName}.name}',
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
                const Text('Welcome to ${pascalName} Page'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<${pascalName}Bloc>().add(
                      const Get${pascalName}Event('1'),
                    );
                  },
                  child: const Text('Load ${pascalName}'),
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
