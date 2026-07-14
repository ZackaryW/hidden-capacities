import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Live wire inspection for task 2.1: prints the raw Capacities response JSON
/// for every request, exactly as the API returned it (before model parsing),
/// so each block type's true wire shape can be confirmed on a running app.
///
/// Debug-only — silent in release builds.

const _encoder = JsonEncoder.withIndent('  ');

/// Formats one response into a console-ready block: an endpoint header line
/// followed by the untouched response body pretty-printed as JSON.
String formatWireLog(String endpoint, Object? data) {
  final body = data == null ? '(no body)' : _encoder.convert(data);
  return '── capacities wire ── $endpoint\n$body';
}

/// A [Dio] with raw-response logging attached in debug builds (a plain [Dio]
/// otherwise). Pass it to `CapacitiesClient(dio: ...)`; the client sets the
/// base URL and auth headers on it.
Dio wireLoggingDio() {
  final dio = Dio();
  if (kDebugMode) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          final options = response.requestOptions;
          debugPrint(formatWireLog('${options.method} ${options.uri}', response.data));
          handler.next(response);
        },
      ),
    );
  }
  return dio;
}
