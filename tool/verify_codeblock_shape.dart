// ignore_for_file: avoid_print
// One-off live verification (task 2.1): discover how Capacities represents a
// single-line code block on the wire, so the HIDDEN-CAP write path builds the
// right shape instead of guessing. Creates a throwaway object from markdown
// with a fenced code block, fetches it, prints the block JSON, then hard-deletes.
//
// Usage: CAPACITIES_API_TOKEN=cap-api-... dart run tool/verify_codeblock_shape.dart

import 'dart:convert';

import 'package:unofficial_capacities/unofficial_capacities.dart';

const _encoder = JsonEncoder.withIndent('  ');

void main() async {
  final client = CapacitiesClient();

  final structures = await client.getSpaceStructures();
  final structure = structures.firstWhere(
    (s) => s.propertyDefinitions.any((p) => p.id == 'title' && p.writable),
    orElse: () => throw StateError('no writable-title structure found'),
  );
  print('Using structure: ${structure.id} (${structure.title})');

  print('\n--- POST /object/markdown (fenced code block) ---');
  final created = await client.createObjectMarkdown(
    structureId: structure.id,
    markdown: '# codeblock shape probe\n\n```\nHIDDEN-CAP:PROBE123\n```\n',
  );
  print('created id: ${created.id}');

  try {
    print('\n--- GET /object (inspect block wire shape) ---');
    final object = await client.getObject(id: created.id);
    print(_encoder.convert(object.toJson()));
  } finally {
    print('\n--- DELETE /object (cleanup) ---');
    await client.deleteObject(id: created.id, hardDelete: true);
    print('deleted ${created.id}');
  }
}
