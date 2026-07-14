import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_capacities/src/integration/capacities_gateway.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:unofficial_capacities/unofficial_capacities.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late CapacitiesGateway gateway;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.capacities.io'));
    adapter = DioAdapter(dio: dio);
    gateway = CapacitiesGateway(CapacitiesClient(apiToken: 't', dio: dio));
  });

  Map<String, dynamic> objectJson() => {
        'id': 'obj-1',
        'structureId': 'ss',
        'properties': <String, dynamic>{},
        'blocks': {
          'notes': [
            {'id': 'orig', 'type': 'TextBlock', 'tokens': <dynamic>[], 'blocks': <dynamic>[]}
          ],
        },
      };

  test('encryptBlock updates a plain TextBlock in place, keeping type and id',
      () async {
    const blob = 'HIDDEN-CAP:xyz';

    // Same-type replacement (TextBlock -> TextBlock) via PATCH /blocks/block,
    // targeting the SAME block id so position and deeplink are preserved.
    adapter.onPatch(
      '/blocks/block',
      (s) => s.reply(200, objectJson()),
      data: {
        'id': 'obj-1',
        'blockId': 'orig',
        'block': {
          'type': 'TextBlock',
          'tokens': [
            {'type': 'TextToken', 'text': blob, 'style': <String, dynamic>{}}
          ],
        },
      },
    );

    final link = await gateway.encryptBlock(
      spaceId: 'sp',
      objectId: 'obj-1',
      original: TextBlock(id: 'orig', tokens: [const TextToken('plain')]),
      blob: blob,
    );

    // The deeplink points at the SAME block id — stable across encryption.
    expect(link.blockId, 'orig');
    expect(link.build(), 'capacities://sp/obj-1?bid=orig');
  });

  test('encryptBlock keeps a CodeBlock a CodeBlock in place', () async {
    const blob = 'HIDDEN-CAP:xyz';

    adapter.onPatch(
      '/blocks/block',
      (s) => s.reply(200, objectJson()),
      data: {
        'id': 'obj-1',
        'blockId': 'code-1',
        'block': {'type': 'CodeBlock', 'lang': 'Text', 'text': blob},
      },
    );

    final link = await gateway.encryptBlock(
      spaceId: 'sp',
      objectId: 'obj-1',
      original: CodeBlock(id: 'code-1', lang: 'Text', text: 'print(1)'),
      blob: blob,
    );

    expect(link.blockId, 'code-1');
  });

  test('throws if the block has no id', () async {
    await expectLater(
      gateway.encryptBlock(
        spaceId: 'sp',
        objectId: 'obj-1',
        original: TextBlock(tokens: [const TextToken('plain')]),
        blob: 'HIDDEN-CAP:xyz',
      ),
      throwsA(isA<StateError>()),
    );
  });
}
