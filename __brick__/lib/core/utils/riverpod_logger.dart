import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final class RiverpodLogger extends ProviderObserver {
  final log = Logger('RiverpodLogger');

  @override
  void didUnmountProvider(ProviderObserverContext context) {
    super.didUnmountProvider(context);
    log.info('Provider unmounted -> Provider : ${context.provider}');
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    super.didUpdateProvider(context, previousValue, newValue);
    log.info(
      'Provider updated -> Provider: ${context.provider}, NewValue $newValue, Mutation: ${context.mutation}',
    );
  }
}
