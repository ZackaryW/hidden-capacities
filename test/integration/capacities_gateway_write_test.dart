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

  // Object as returned by append: original TextBlock + the new HIDDEN-CAP CodeBlock.
  Map<String, dynamic> afterAppendJson(String blob) => {
        'id': 'obj-1',
        'structureId': 'ss',
        'properties': <String, dynamic>{},
        'blocks': {
          'notes': [
            {
              'id': 'orig',
              'type': 'TextBlock',
              'tokens': [
                {'type': 'TextToken', 'text': 'plain', 'style': <String, dynamic>{}}
              ],
              'blocks': <dynamic>[],
            },
            {'id': 'new-code', 'type': 'CodeBlock', 'lang': 'Text', 'text': blob},
          ],
        },
      };

  test('encryptBlock appends a CodeBlock, deletes the original, returns the new deeplink',
      () async {
    const blob = 'HIDDEN-CAP:xyz';

    adapter.onPost(
      '/blocks/append',
      (s) => s.reply(200, afterAppendJson(blob)),
      data: {
        'id': 'obj-1',
        'blocks': [
          {'type': 'CodeBlock', 'lang': 'Text', 'text': blob}
        ],
      },
    );
    adapter.onDelete(
      '/block',
      (s) => s.reply(200, afterAppendJson(blob)),
      queryParameters: {'objectId': 'obj-1', 'blockId': 'orig'},
    );

    final link = await gateway.encryptBlock(
      spaceId: 'sp',
      objectId: 'obj-1',
      originalBlockId: 'orig',
      blob: blob,
    );

    expect(link.spaceId, 'sp');
    expect(link.objectId, 'obj-1');
    expect(link.blockId, 'new-code');
    expect(link.build(),
        'capacities://sp/obj-1?bid=new-code');
  });

  test('throws if the appended CodeBlock cannot be located in the response', () async {
    const blob = 'HIDDEN-CAP:xyz';
    // Response missing the new code block (append returned only the original).
    adapter.onPost(
      '/blocks/append',
      (s) => s.reply(200, {
        'id': 'obj-1',
        'structureId': 'ss',
        'properties': <String, dynamic>{},
        'blocks': {
          'notes': [
            {'id': 'orig', 'type': 'TextBlock', 'tokens': <dynamic>[], 'blocks': <dynamic>[]}
          ],
        },
      }),
      data: {
        'id': 'obj-1',
        'blocks': [
          {'type': 'CodeBlock', 'lang': 'Text', 'text': blob}
        ],
      },
    );

    await expectLater(
      gateway.encryptBlock(
        spaceId: 'sp',
        objectId: 'obj-1',
        originalBlockId: 'orig',
        blob: blob,
      ),
      throwsA(isA<StateError>()),
    );
  });
}
