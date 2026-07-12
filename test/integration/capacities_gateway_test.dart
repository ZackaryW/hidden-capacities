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

  Map<String, dynamic> objectWith(String blockId, String text) => {
        'id': 'obj-1',
        'structureId': 'ss',
        'properties': <String, dynamic>{},
        'blocks': {
          'notes': [
            {
              'id': blockId,
              'type': 'TextBlock',
              'tokens': [
                {'type': 'TextToken', 'text': text},
              ],
            }
          ],
        },
      };

  CapacitiesLink link(String? blockId) =>
      CapacitiesLink(spaceId: 'sp', objectId: 'obj-1', blockId: blockId);

  test('loads a plain block as not-encrypted', () async {
    adapter.onGet(
      '/object',
      (s) => s.reply(200, objectWith('b1', 'hello world')),
      queryParameters: {'id': 'obj-1'},
    );

    final loaded = await gateway.loadBlock(link('b1'));

    expect(loaded.blockId, 'b1');
    expect(loaded.plainText, 'hello world');
    expect(loaded.isEncrypted, isFalse);
  });

  test('loads a HIDDEN-CAP block as encrypted', () async {
    adapter.onGet(
      '/object',
      (s) => s.reply(200, objectWith('b1', 'HIDDEN-CAP:abc123')),
      queryParameters: {'id': 'obj-1'},
    );

    final loaded = await gateway.loadBlock(link('b1'));

    expect(loaded.isEncrypted, isTrue);
    expect(loaded.plainText, 'HIDDEN-CAP:abc123');
  });

  test('requires a specific block id (no bid) -> ArgumentError', () async {
    await expectLater(gateway.loadBlock(link(null)), throwsArgumentError);
  });

  test('block id not present in object -> BlockNotFoundException', () async {
    adapter.onGet(
      '/object',
      (s) => s.reply(200, objectWith('other-block', 'x')),
      queryParameters: {'id': 'obj-1'},
    );

    await expectLater(
      gateway.loadBlock(link('missing')),
      throwsA(isA<BlockNotFoundException>()),
    );
  });

  test('API error propagates as CapacitiesApiException', () async {
    adapter.onGet(
      '/object',
      (s) => s.reply(401, {'code': 'cap_unauthorized', 'message': 'no token'}),
      queryParameters: {'id': 'obj-1'},
    );

    await expectLater(
      gateway.loadBlock(link('b1')),
      throwsA(isA<CapacitiesApiException>()),
    );
  });
}
