class BlocGenerator {
  static Map<String, String> generate(
      String snakeName, String pascalName, String camelName) {
    return {
      'bloc': _generateBloc(snakeName, pascalName, camelName),
      'event': _generateEvent(snakeName, pascalName),
      'state': _generateState(snakeName, pascalName, camelName),
    };
  }

  static String _generateBloc(
      String snakeName, String pascalName, String camelName) {
    return '''import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_${snakeName}_usecase.dart';
import '${snakeName}_event.dart';
import '${snakeName}_state.dart';

/// BLoC for managing ${pascalName} state
class ${pascalName}Bloc extends Bloc<${pascalName}Event, ${pascalName}State> {
  final Get${pascalName}UseCase get${pascalName}UseCase;

  ${pascalName}Bloc(this.get${pascalName}UseCase) : super(${pascalName}Initial()) {
    on<Get${pascalName}Event>(_onGet${pascalName});
  }

  Future<void> _onGet${pascalName}(
    Get${pascalName}Event event,
    Emitter<${pascalName}State> emit,
  ) async {
    emit(${pascalName}Loading());

    final result = await get${pascalName}UseCase(event.id);

    result.fold(
      (failure) => emit(${pascalName}Error(message: failure.message)),
      (${camelName}) => emit(${pascalName}Loaded(${camelName}: ${camelName})),
    );
  }
}
''';
  }

  static String _generateEvent(String snakeName, String pascalName) {
    return '''import 'package:equatable/equatable.dart';

/// Base class for ${pascalName} events
abstract class ${pascalName}Event extends Equatable {
  const ${pascalName}Event();

  @override
  List<Object?> get props => [];
}

/// Event to get ${snakeName} by ID
class Get${pascalName}Event extends ${pascalName}Event {
  final String id;

  const Get${pascalName}Event(this.id);

  @override
  List<Object?> get props => [id];
}
''';
  }

  static String _generateState(
      String snakeName, String pascalName, String camelName) {
    return '''import 'package:equatable/equatable.dart';
import '../../domain/entities/${snakeName}_entity.dart';

/// Base class for ${pascalName} states
abstract class ${pascalName}State extends Equatable {
  const ${pascalName}State();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ${pascalName}Initial extends ${pascalName}State {}

/// Loading state
class ${pascalName}Loading extends ${pascalName}State {}

/// Loaded state with ${snakeName} data
class ${pascalName}Loaded extends ${pascalName}State {
  final ${pascalName}Entity ${camelName};

  const ${pascalName}Loaded({required this.${camelName}});

  @override
  List<Object?> get props => [${camelName}];
}

/// Error state
class ${pascalName}Error extends ${pascalName}State {
  final String message;

  const ${pascalName}Error({required this.message});

  @override
  List<Object?> get props => [message];
}
''';
  }
}
