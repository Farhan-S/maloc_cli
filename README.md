# Maloc CLI

A powerful CLI tool for scaffolding Flutter projects with Clean Architecture, Melos monorepo setup, and BLoC state management.

## Features

- 🚀 **Project Scaffolding**: Create new Flutter projects with a complete modular architecture
- 📦 **Feature Generation**: Generate feature modules with Clean Architecture layers
- 🗑️ **Feature Removal**: Clean removal of feature modules including routes and dependencies
- 🏗️ **Clean Architecture**: Pre-configured with presentation, domain, and data layers
- 🔄 **BLoC Pattern**: State management with flutter_bloc
- 🌐 **Network Layer**: Pre-configured Dio client with interceptors
- �� **Monorepo**: Melos workspace management for multiple packages

## Installation

Install globally using pub:

\`\`\`bash
dart pub global activate maloc_cli
\`\`\`

Make sure \`~/.pub-cache/bin\` is in your PATH.

## Usage

### Create a New Project

\`\`\`bash
maloc create my_awesome_app
\`\`\`

### Generate a Feature

\`\`\`bash
maloc feature products
\`\`\`

### Remove a Feature

\`\`\`bash
maloc remove products
\`\`\`

## Author

Farhan-S - [GitHub](https://github.com/Farhan-S)
