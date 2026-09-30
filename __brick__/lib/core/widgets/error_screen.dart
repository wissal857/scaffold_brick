import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'package:{{project_name}}/core/errors/failure.dart';

class ErrorScreen extends StatelessWidget {
  ErrorScreen({super.key, required this.error});

  final Failure error;
  final _log = Logger('ErrorScreen');

  @override
  Widget build(BuildContext context) {
    _log.severe(error.message, error, error.stackTrace ?? StackTrace.current);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(error.message),
        ],
      ),
    );
  }
}
