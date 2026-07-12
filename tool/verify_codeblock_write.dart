// ignore_for_file: avoid_print
// One-off live verification (task 2.1, write side): can PATCH /blocks/block
// turn a block into a CodeBlock in place, or does it only accept TextBlock?
// Uses raw Dio (the typed client's Block can't express code-block text/lang),
// so this probes the API directly. Creates a throwaway object, tries the
// CodeBlock update, reports the outcome, then hard-deletes.
//
// Usage: CAPACITIES_API_TOKEN=cap-api-... dart run tool/verify_codeblock_write.dart

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:unofficial_capacities/unofficial_capacities.dart';

const _encoder = JsonEncoder.withIndent('  ');

Dio _rawDio() => Dio(BaseOptions(
      baseUrl: 'https://api.capacities.io',
      headers: {
        'Authorization': 'Bearer ${Platform.environment['CAPACITIES_API_TOKEN']}',
        'X-Capacities-Api-Version': '0.1.0',
      },
    ));

void main() async {
  final client = CapacitiesClient();
  final dio = _rawDio();

  final structures = await client.getSpaceStructures();
  final structure = structures.firstWhere(
    (s) => s.propertyDefinitions.any((p) => p.id == 'title' && p.writable),
  );

  // Create an object with a plain paragraph (TextBlock) to target.
  final created = await client.createObjectMarkdown(
    structureId: structure.id,
    markdown: '# write probe\n\nplaceholder paragraph to transform\n',
  );
  print('created id: ${created.id}');

  try {
    final object = await client.getObject(id: created.id);
    // Find the first block and its property id from the raw JSON.
    final blocks = object.toJson()['blocks'] as Map<String, dynamic>;
    final propertyId = blocks.keys.first;
    final list = blocks[propertyId] as List<dynamic>;
    final targetBlock = list.firstWhere(
      (b) => (b as Map)['type'] == 'TextBlock',
      orElse: () => list.first,
    ) as Map<String, dynamic>;
    final blockId = targetBlock['id'] as String;
    print('target propertyId=$propertyId blockId=$blockId type=${targetBlock['type']}');

    print('\n--- PATCH /blocks/block with a CodeBlock (raw) ---');
    try {
      final resp = await dio.patch<Map<String, dynamic>>('/blocks/block', data: {
        'id': created.id,
        'blockId': blockId,
        'block': {
          'type': 'CodeBlock',
          'lang': 'Text',
          'text': 'HIDDEN-CAP:WRITE_TEST',
        },
      });
      print('SUCCESS — response block shape:');
      final resultBlocks = resp.data!['blocks'] as Map<String, dynamic>;
      print(_encoder.convert(resultBlocks));
    } on DioException catch (e) {
      print('REJECTED — status ${e.response?.statusCode}');
      print(_encoder.convert(e.response?.data ?? {'error': e.message}));
    }
  } finally {
    print('\n--- cleanup ---');
    await client.deleteObject(id: created.id, hardDelete: true);
    print('deleted ${created.id}');
  }
}
