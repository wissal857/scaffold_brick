import 'package:{{project_name}}/core/caching/persistence/state_stores/state_handler.dart';

class StateHandlerRegistry {
  final Map<String, StateHandler> _handlers;

  StateHandlerRegistry(Iterable<StateHandler> handlers)
    : _handlers = {for (final handler in handlers) handler.entityType: handler};

  StateHandler get(String entityType) {
    final handler = _handlers[entityType];

    if (handler == null) {
      throw StateError('No StateHandler registred for $entityType');
    }
    return handler;
  }
}
