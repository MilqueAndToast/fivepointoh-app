import 'dart:convert';
import 'dart:io';
import 'package:sembast/sembast_io.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import '../bin/server.dart';
import '../../lib/sheet_engine.dart';

void main() {
  test(
    'server enforces ownership, audit identity, formula locks, revisions, and persistence',
    () async {
      final dir = await Directory.systemTemp.createTemp('five-zero-test-');
      final db = await databaseFactoryIo.openDatabase(
        '${dir.path}/campaign.db',
      );
      final ref =
          jsonDecode(File('../assets/reference.json').readAsStringSync())
              as Map<String, dynamic>;
      final app = CampaignServer(db, ref),
          handler = CampaignServer(db, ref).handler();
      await app.createUser('dm', 'a-secure-dm-password', 'dm');
      await app.createUser('alice', 'a-secure-alice-password', 'player');
      await app.createUser('bob', 'a-secure-bob-password', 'player');
      Future<Response> call(
        String method,
        String path, {
        String? token,
        Map<String, dynamic>? body,
      }) async => await handler(
        Request(
          method,
          Uri.parse('http://localhost/api/$path'),
          headers: {
            'host': 'localhost',
            if (token != null) 'authorization': 'Bearer $token',
          },
          body: body == null ? null : jsonEncode(body),
        ),
      );
      Future<dynamic> decoded(Response r) async =>
          jsonDecode(await r.readAsString());
      Future<String> login(String username, String password) async =>
          (await decoded(
            await call(
              'POST',
              'login',
              body: {'username': username, 'password': password},
            ),
          ))['token'];
      final dmToken = await login('dm', 'a-secure-dm-password'),
          aliceToken = await login('alice', 'a-secure-alice-password'),
          bobToken = await login('bob', 'a-secure-bob-password');
      expect((await call('GET', 'characters')).statusCode, 401);
      expect(
        (await call(
          'POST',
          'users',
          token: aliceToken,
          body: {'username': 'fake', 'password': 'long-enough-password'},
        )).statusCode,
        403,
      );
      final created = await decoded(
        await call(
          'POST',
          'characters',
          token: dmToken,
          body: {'name': 'Alice hero', 'owner': 'alice'},
        ),
      );
      final id = created['id'];
      expect(
        (await call('GET', 'characters/$id', token: bobToken)).statusCode,
        403,
      );
      expect(
        await decoded(await call('GET', 'characters', token: bobToken)),
        isEmpty,
      );
      expect(
        (await call(
          'PATCH',
          'characters/$id',
          token: aliceToken,
          body: {
            'revision': 1,
            'changes': {'Main!AN4': 999},
          },
        )).statusCode,
        400,
      );
      expect(
        (await call(
          'PATCH',
          'characters/$id',
          token: aliceToken,
          body: {
            'revision': 1,
            'changes': {'Stats!B4': 21},
          },
        )).statusCode,
        400,
      );
      for (final changes in [
        {
          'App!slots_1': [true, 'invalid'],
        },
        {'App!slots_1': List.filled(31, false)},
        {
          'App!entry_bad': {
            'kind': 'spell',
            'name': 'Broken',
            'description': '',
            'level': 20,
          },
        },
        {'App!unknown': 'unrecognized'},
        {'App!pack_quantity_18': -1},
        {'App!pack_quantity_18': 1.5},
        {'App!pack_quantity_17': 2},
      ]) {
        expect(
          (await call(
            'PATCH',
            'characters/$id',
            token: aliceToken,
            body: {'revision': 1, 'changes': changes},
          )).statusCode,
          400,
        );
      }
      expect(
        (await call(
          'PATCH',
          'characters/$id',
          token: aliceToken,
          body: {
            'revision': 1,
            'changes': {
              'Main!BF5': true,
              'App!pack_quantity_18': 2,
              'Main!BX18': 5,
              'Main!AW25': 2,
              'Main!BJ25': 1,
              'Misc!BZ30': 'Claw',
              'Main!BD30': 'Pierce',
              'Main!B25': 'One continuous journal.\nMeet at dawn.',
              'App!entry_test': {
                'kind': 'spell',
                'name': 'Test Ward',
                'description': 'Protects an ally.',
                'level': 1,
              },
              'App!slots_1': [true, false, false, true, false],
              for (var row = 26; row <= 36; row++) 'Main!B$row': null,
            },
            'actor': 'dm',
          },
        )).statusCode,
        200,
      );
      expect(
        (await call(
          'PATCH',
          'characters/$id',
          token: dmToken,
          body: {
            'revision': 1,
            'changes': {'Main!AU4': 4},
          },
        )).statusCode,
        409,
      );
      final logs = await decoded(
        await call('GET', 'characters/$id/history', token: dmToken),
      );
      expect(logs.first['actor'], 'alice');
      expect(
        (await call(
          'POST',
          'characters/$id/owner',
          token: dmToken,
          body: {'revision': 2, 'owner': 'bob'},
        )).statusCode,
        200,
      );
      expect(
        (await call('GET', 'characters/$id', token: aliceToken)).statusCode,
        403,
      );
      final snapshot = await decoded(
        await call('GET', 'characters/$id', token: bobToken),
      );
      expect(snapshot['overrides']['Main!BF5'], true);
      expect(snapshot['overrides']['App!pack_quantity_18'], 2);
      expect(snapshot['overrides']['Main!BX18'], 5);
      expect(
        SheetEngine(
          ref['sheets'],
          Map<String, dynamic>.from(snapshot['overrides']),
        ).value('Main', 'BX36'),
        205,
      );
      expect(snapshot['overrides']['Misc!BZ30'], 'Claw');
      expect(snapshot['overrides']['Main!BD30'], 'Pierce');
      expect(snapshot['overrides']['App!entry_test']['name'], 'Test Ward');
      expect(snapshot['overrides']['App!slots_1'], [
        true,
        false,
        false,
        true,
        false,
      ]);
      expect(
        snapshot['overrides']['Main!B25'],
        'One continuous journal.\nMeet at dawn.',
      );
      final updatedEntry = {
        ...snapshot['overrides']['App!entry_test'] as Map,
        'description': 'Updated by the new owner.',
      };
      expect(
        (await call(
          'PATCH',
          'characters/$id',
          token: bobToken,
          body: {
            'revision': 3,
            'changes': {'App!entry_test': updatedEntry},
          },
        )).statusCode,
        200,
      );
      final updatedLogs = await decoded(
        await call('GET', 'characters/$id/history', token: dmToken),
      );
      expect(updatedLogs.first['actor'], 'bob');
      expect(
        updatedLogs.first['before']['App!entry_test']['description'],
        'Protects an ally.',
      );
      await db.close();
      final reopened = await databaseFactoryIo.openDatabase(
        '${dir.path}/campaign.db',
      );
      expect((await characters.record(id).get(reopened))!['revision'], 4);
      final restored = (await characters.record(id).get(reopened))!;
      expect(
        ((restored['overrides'] as Map)['App!entry_test']
            as Map)['description'],
        'Updated by the new owner.',
      );
      await reopened.close();
      await dir.delete(recursive: true);
    },
  );
}
