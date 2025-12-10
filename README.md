# Maloc CLI

A powerful CLI tool for scaffolding Flutter projects with Clean Architecture, Melos monorepo setup, and BLoC state management.

## Features

- 🚀 **Project Scaffolding**: Create new Flutter projects with a complete modular architecture
- 🎯 **Project Initialization**: Initialize template in current or any directory
- 📦 **Feature Generation**: Generate feature modules with Clean Architecture layers
- 🗑️ **Feature Removal**: Clean removal of feature modules including routes and dependencies
- 🏗️ **Clean Architecture**: Pre-configured with presentation, domain, and data layers
- 🔄 **BLoC Pattern**: State management with flutter_bloc
- 🌐 **Network Layer**: Pre-configured Dio client with interceptors
- 📂 **Monorepo**: Melos workspace management for multiple packages

## Installation

### Option 1: Install from pub.dev (Recommended)

Once published on pub.dev, install globally:

```bash
dart pub global activate maloc_cli
```

### Option 2: Install from GitHub

Install directly from the GitHub repository:

```bash
dart pub global activate --source git https://github.com/Farhan-S/maloc_cli.git
```

### Option 3: Install from Local Clone

Clone the repository and install from source:

```bash
# Clone the repository
git clone https://github.com/Farhan-S/maloc_cli.git
cd maloc_cli

# Install dependencies
dart pub get

# Activate globally from local source
dart pub global activate --source path .
```

### Verify Installation

Make sure `~/.pub-cache/bin` is in your PATH, then verify:

```bash
maloc --version
maloc --help
```

## Usage

### Create a New Project

Creates a new directory with the project name and initializes the template:

```bash
maloc create my_awesome_app
```

This will:

- Clone the template from GitHub
- Set up the project structure
- Configure package names
- Install dependencies
- Initialize git repository

### Initialize in Current/Specific Directory

Initialize the template in the current directory or a specific path:

```bash
# Initialize in current directory
maloc init

# Initialize in a specific directory
maloc init ./my_project
maloc init /path/to/my_project
```

This is useful when:

- You want to set up the template in an existing directory
- You've already created a directory and want to initialize it
- You want to specify a custom path

### Generate a Feature

Generate a new feature module with all Clean Architecture layers:

```bash
maloc feature products
```

This creates:

- Presentation layer (BLoC, Pages, Widgets)
- Domain layer (Entities, Use Cases, Repository Interface)
- Data layer (Models, Data Sources, Repository Implementation)

### Remove a Feature

Remove an existing feature module:

```bash
maloc remove products
```

This removes all feature files and cleans up dependencies.

### Install Dependencies

Install dependencies for all packages in your monorepo:

```bash
maloc pub get
```

This will run `dart pub get` for all packages in the project.

## Updating Maloc CLI

### If installed from pub.dev:

```bash
dart pub global activate maloc_cli
```

### If installed from GitHub:

```bash
dart pub global activate --source git https://github.com/Farhan-S/maloc_cli.git
```

### If installed from local source:

```bash
cd /path/to/maloc_cli
git pull
dart pub global activate --source path .
```

## Project Structure

The generated project follows Clean Architecture principles:

```
my_project/
├── packages/
│   ├── app/                 # Main application
│   ├── core/                # Shared utilities
│   └── features/            # Feature modules
│       └── feature_name/
│           ├── data/
│           ├── domain/
│           └── presentation/
├── melos.yaml
└── pubspec.yaml
```

## Publishing to pub.dev

To publish this CLI to pub.dev:

1. Make sure your package is ready:

```bash
dart pub publish --dry-run
```

2. Publish to pub.dev:

```bash
dart pub publish
```

## Development

To work on this CLI locally:

1. Clone the repository
2. Install dependencies:

```bash
dart pub get
```

3. Run locally:

```bash
dart run bin/maloc.dart <command>
```

4. Test the global installation:

```bash
dart pub global activate --source path .
```

## Requirements

- Dart SDK: ^3.6.0
- Flutter SDK (for generated projects)
- Git (for cloning templates)

## Author

Farhan-S - [GitHub](https://github.com/Farhan-S)

## License

This project is open source and available under the MIT License.
