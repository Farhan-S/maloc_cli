# Maloc CLI Examples

This directory contains examples of how to use the Maloc CLI tool.

## Basic Usage

### 1. Create a New Project

```bash
# Create a new Flutter project with Clean Architecture
maloc create my_awesome_app
cd my_awesome_app
```

This will:
- Clone the template from GitHub
- Set up the project structure with Clean Architecture
- Configure package names
- Install dependencies
- Initialize git repository

### 2. Initialize in Existing Directory

```bash
# Create a directory first
mkdir my_project
cd my_project

# Initialize the template here
maloc init

# Or initialize from another location
maloc init ./specific/path
```

### 3. Generate a Feature Module

```bash
# Generate a complete feature with all layers
maloc feature products

# This creates:
# - packages/features_products/
#   ├── data/
#   │   ├── datasources/products_remote_datasource.dart
#   │   ├── models/products_model.dart
#   │   └── repositories/products_repository_impl.dart
#   ├── domain/
#   │   ├── entities/products_entity.dart
#   │   ├── repositories/products_repository.dart
#   │   └── usecases/get_products_usecase.dart
#   └── presentation/
#       ├── bloc/
#       │   ├── products_bloc.dart
#       │   ├── products_event.dart
#       │   └── products_state.dart
#       └── pages/products_page.dart
```

### 4. Add Pages to Features

```bash
# Add a simple page without data/domain layers
maloc page home settings

# Add a page with BLoC but no data layers
maloc page home profile --no-bloc

# Add a page with full data and domain layer integration
maloc page products details --with-data
```

### 5. Remove Features or Pages

```bash
# Remove an entire feature
maloc remove products

# Remove a specific page from a feature
maloc remove-page home settings
```

### 6. Install Dependencies

```bash
# Install dependencies for all packages in the monorepo
maloc pub get
```

### 7. Clean Build Artifacts

```bash
# Clean all packages (like flutter clean for entire project)
maloc clean

# Shows output like:
#   ▸ app... ✓ (45.2 MB)
#   ▸ core... ✓ (12.1 MB)
#   ▸ features_products... ✓ (8.5 MB)
# All packages cleaned successfully! (3 packages, 65.8 MB freed)
```

## Complete Workflow Example

```bash
# 1. Create a new project
maloc create shopping_app
cd shopping_app

# 2. Generate feature modules
maloc feature auth
maloc feature products
maloc feature cart
maloc feature orders

# 3. Add additional pages to features
maloc page auth login --with-data
maloc page auth register --with-data
maloc page products product_details --with-data

# 4. Install all dependencies
maloc pub get

# 5. Run the app (in the app package)
cd packages/app
flutter run

# 6. After development, clean if needed
cd ../..
maloc clean
```

## Project Structure

After running the commands above, your project will look like:

```
shopping_app/
├── packages/
│   ├── app/                    # Main application
│   │   └── lib/
│   │       └── routes/
│   │           └── app_router.dart
│   ├── core/                   # Shared utilities
│   │   └── lib/
│   │       └── routes/
│   │           └── app_routes.dart
│   └── features/               # Feature modules
│       ├── features_auth/
│       ├── features_products/
│       ├── features_cart/
│       └── features_orders/
├── melos.yaml
└── pubspec.yaml
```

## Tips

1. **Always run from project root**: Feature generation commands should be run from the project root (where `melos.yaml` is located).

2. **Feature naming**: Use snake_case or camelCase for feature names. The CLI will automatically convert them to the appropriate case for different contexts.

3. **Routing**: After generating features, routes are automatically added to `app_routes.dart` and `app_router.dart`. Use them like:
   ```dart
   AppRoutes.navigateToProducts(context);
   // or
   context.push(AppRoutes.productsPath);
   ```

4. **Clean regularly**: Use `maloc clean` to free up disk space and resolve build issues, especially after major dependency updates.

5. **Monorepo management**: This CLI uses Melos for monorepo management. You can also use standard Melos commands:
   ```bash
   melos bootstrap
   melos run test
   ```

## Advanced Usage

### Custom Feature with Multiple Pages

```bash
# Create the feature
maloc feature social

# Add multiple pages
maloc page social feed --with-data
maloc page social profile --with-data
maloc page social friends
maloc page social messages --with-data
```

### Cleaning Specific Directory

```bash
# Clean a specific project
maloc clean /path/to/project
```

## Troubleshooting

**Problem**: "Please run this command from the project root directory!"

**Solution**: Navigate to the directory containing `melos.yaml` and `packages/` folder.

---

**Problem**: Feature generation fails

**Solution**: Ensure you've initialized a project first with `maloc create` or `maloc init`.

---

**Problem**: Routes not working

**Solution**: The routes are auto-generated. Make sure to import and use `AppRoutes` from the core package in your app.

## Further Reading

- [Main README](../README.md)
- [Clean Architecture Principles](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [BLoC Pattern](https://bloclibrary.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Melos Documentation](https://melos.invertase.dev/)
