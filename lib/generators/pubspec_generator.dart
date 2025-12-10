class PubspecGenerator {
  static String generate(String featureName) {
    return '''name: features_$featureName
description: $featureName feature module with Clean Architecture
version: 1.0.0
publish_to: none

environment:
  sdk: '>=3.9.2 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # Core dependencies
  core:
    path: ../core
  
  # Functional programming
  dartz: ^0.10.1
  
  # State management
  flutter_bloc: ^8.1.6
  
  # Value equality
  equatable: ^2.0.7

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
''';
  }
}
