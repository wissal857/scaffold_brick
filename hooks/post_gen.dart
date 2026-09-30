import 'dart:io';

import 'package:mason/mason.dart';

void run(HookContext context) async {
  final progress = context.logger.progress('Installing packages');

  // run flutter pub get after generation
  await Process.run('flutter', ['pub', 'get']);

  progress.complete();
}
