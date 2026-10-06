import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'http_client.dart';
import 'i_http_client.dart';

final httpClientProvider = Provider.autoDispose<IHttpClient>((ref) {
  return HttpClient();
});
