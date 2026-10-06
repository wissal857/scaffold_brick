import 'dart:convert';
import 'package:crypto/crypto.dart';

class IdempotencyKey {
  const IdempotencyKey._();

  static String generate(Map<String, dynamic> data) {
    final canonical = _canonicalize(data);
    final json = jsonEncode(canonical);
    final bytes = utf8.encode(json);

    return sha256.convert(bytes).toString();
  }

  static dynamic _canonicalize(dynamic value) {
    if (value is Map) {
      final entries = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return {
        for (final entry in entries)
          {entry.key.toString(): _canonicalize(entry.value)},
      };
    }

    if (value is List) {
      return value.map(_canonicalize).toList();
    }

    return value;
  }
}
