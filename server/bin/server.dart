import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' as hashes;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:sembast/sembast_io.dart';
import '../../lib/sheet_engine.dart';
import '../../lib/character_data.dart';

final users = stringMapStoreFactory.store('users');
final characters = stringMapStoreFactory.store('characters');
final sessions = stringMapStoreFactory.store('sessions');
final audit = stringMapStoreFactory.store('audit');
String secret([int length = 32]) => base64UrlEncode(
  List<int>.generate(length, (_) => Random.secure().nextInt(256)),
).replaceAll('=', '');
String digest(String s) => hashes.sha256.convert(utf8.encode(s)).toString();
final kdf = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 210000, bits: 256);
Future<String> passwordHash(String password, String salt) async => base64Encode(
  await (await kdf.deriveKey(
    secretKey: SecretKey(utf8.encode(password)),
    nonce: base64Decode(salt),
  )).extractBytes(),
);
bool constantEquals(String a, String b) {
  var d = a.length ^ b.length;
  for (var i = 0; i < a.length && i < b.length; i++) {
    d |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return d == 0;
}

Response jsonResponse(Object? value, [int status = 200]) => Response(
  status,
  body: jsonEncode(value),
  headers: {'content-type': 'application/json', 'cache-control': 'no-store'},
);

class ApiError implements Exception {
  final int status;
  final String message;
  ApiError(this.status, this.message);
}

class CampaignServer {
  final Database db;
  final Map<String, dynamic> reference;
  final Map<String, List<DateTime>> attempts = {};
  CampaignServer(this.db, this.reference);
  Future<void> createUser(String username, String password, String role) async {
    username = username.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9_.-]{2,40}$').hasMatch(username))
      throw ApiError(
        400,
        'Use 2–40 letters, numbers, dots, underscores, or hyphens.',
      );
    if (password.length < 12 || password.length > 256)
      throw ApiError(400, 'Passwords must contain 12–256 characters.');
    final salt = base64Encode(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)),
    );
    final hash = await passwordHash(password, salt);
    await db.transaction((txn) async {
      if (await users.record(username).exists(txn))
        throw ApiError(409, 'Username already exists.');
      await users.record(username).put(txn, {
        'username': username,
        'role': role,
        'salt': salt,
        'hash': hash,
      });
    });
  }

  Future<Map<String, dynamic>> body(Request r) async {
    final bytes = <int>[];
    await for (final part in r.read()) {
      bytes.addAll(part);
      if (bytes.length > 300000) throw ApiError(413, 'Request too large.');
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)));
    } catch (_) {
      throw ApiError(400, 'Invalid JSON object.');
    }
  }

  Future<Map<String, dynamic>> identity(Request r) async {
    final authorization = r.headers['authorization'] ?? '';
    if (!authorization.startsWith('Bearer '))
      throw ApiError(401, 'Sign in to continue.');
    final s = await sessions.record(digest(authorization.substring(7))).get(db);
    if (s == null ||
        DateTime.parse(s['expires'] as String).isBefore(DateTime.now().toUtc()))
      throw ApiError(401, 'Your session expired. Sign in again.');
    final u = await users.record(s['username'] as String).get(db);
    if (u == null) throw ApiError(401, 'Account unavailable.');
    return {'username': u['username'], 'role': u['role']};
  }

  void dm(Map u) {
    if (u['role'] != 'dm')
      throw ApiError(403, 'Only the assigned DM can do that.');
  }

  Future<Map<String, dynamic>> character(String id, Map u) async {
    final c = await characters.record(id).get(db);
    if (c == null) throw ApiError(404, 'Character not found.');
    if (u['role'] != 'dm' && c['owner'] != u['username'])
      throw ApiError(403, 'This character belongs to another player.');
    return c;
  }

  Handler handler({String? webRoot}) {
    final router = Router();
    router.post('/api/login', (Request r) async {
      final remote =
          (r.context['shelf.io.connection_info'] as HttpConnectionInfo?)
              ?.remoteAddress
              .address ??
          'local';
      final now = DateTime.now();
      if (attempts.length > 10000)
        attempts.removeWhere(
          (_, v) => v.isEmpty || now.difference(v.last).inMinutes > 10,
        );
      final recent = attempts.putIfAbsent(remote, () => [])
        ..removeWhere((t) => now.difference(t).inMinutes >= 10);
      if (recent.length >= 15)
        throw ApiError(
          429,
          'Too many sign-in attempts. Try again in 10 minutes.',
        );
      recent.add(now);
      final b = await body(r),
          username = '${b['username'] ?? ''}'.trim().toLowerCase(),
          password = '${b['password'] ?? ''}';
      final u = await users.record(username).get(db);
      final salt = u?['salt'] as String? ?? base64Encode(List.filled(16, 0));
      final hash = await passwordHash(
        password.length > 256 ? 'invalid' : password,
        salt,
      );
      if (u == null || !constantEquals(hash, u['hash'] as String))
        throw ApiError(401, 'Incorrect username or password.');
      recent.clear();
      final token = secret();
      await sessions.record(digest(token)).put(db, {
        'username': username,
        'expires': now.toUtc().add(const Duration(hours: 12)).toIso8601String(),
      });
      return jsonResponse({
        'token': token,
        'user': {'username': username, 'role': u['role']},
      });
    });
    router.post('/api/logout', (Request r) async {
      await identity(r);
      await sessions
          .record(digest(r.headers['authorization']!.substring(7)))
          .delete(db);
      return jsonResponse({'ok': true});
    });
    router.get('/api/characters', (Request r) async {
      final u = await identity(r), all = await characters.find(db);
      return jsonResponse(
        all
            .where(
              (c) => u['role'] == 'dm' || c.value['owner'] == u['username'],
            )
            .map(
              (c) => {
                'id': c.key,
                'name': c.value['name'],
                'owner': c.value['owner'],
                'revision': c.value['revision'],
              },
            )
            .toList(),
      );
    });
    router.post('/api/characters', (Request r) async {
      final u = await identity(r);
      dm(u);
      final b = await body(r);
      final owner = '${b['owner'] ?? u['username']}';
      if (!await users.record(owner).exists(db))
        throw ApiError(400, 'Choose an existing owner.');
      final name = '${b['name'] ?? 'New character'}'.trim();
      if (name.isEmpty || name.length > 100)
        throw ApiError(400, 'Name must be 1–100 characters.');
      final id = secret(12);
      await db.transaction((txn) async {
        await characters.record(id).put(txn, {
          'name': name,
          'owner': owner,
          'revision': 1,
          'overrides': {'Main!B2': name},
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        });
        await audit.record(secret(12)).put(txn, {
          'characterId': id,
          'actor': u['username'],
          'at': DateTime.now().toUtc().toIso8601String(),
          'action': 'created',
          'owner': owner,
          'revision': 1,
        });
      });
      return jsonResponse({'id': id}, 201);
    });
    router.get('/api/users', (Request r) async {
      final u = await identity(r);
      dm(u);
      return jsonResponse(
        (await users.find(
          db,
        )).map((u) => {'username': u.key, 'role': u.value['role']}).toList(),
      );
    });
    router.post('/api/users', (Request r) async {
      final u = await identity(r);
      dm(u);
      final b = await body(r);
      await createUser(
        '${b['username'] ?? ''}',
        '${b['password'] ?? ''}',
        'player',
      );
      return jsonResponse({'ok': true}, 201);
    });
    router.get(
      '/api/characters/<id>',
      (Request r, String id) async =>
          jsonResponse(await character(id, await identity(r))),
    );
    router.post('/api/characters/<id>/owner', (Request r, String id) async {
      final u = await identity(r);
      dm(u);
      final b = await body(r);
      await character(id, u);
      final owner = '${b['owner']}';
      if (!await users.record(owner).exists(db))
        throw ApiError(400, 'Choose an existing account.');
      await db.transaction((txn) async {
        final c = (await characters.record(id).get(txn))!;
        if (c['revision'] != b['revision'])
          throw ApiError(
            409,
            'Character changed. Refresh before assigning it.',
          );
        final revision = (c['revision'] as int) + 1;
        await characters.record(id).put(txn, {
          ...c,
          'owner': owner,
          'revision': revision,
        });
        await audit.record(secret(12)).put(txn, {
          'characterId': id,
          'actor': u['username'],
          'at': DateTime.now().toUtc().toIso8601String(),
          'action': 'assigned to $owner',
          'revision': revision,
        });
      });
      return jsonResponse({'ok': true});
    });
    router.patch('/api/characters/<id>', (Request r, String id) async {
      final u = await identity(r), b = await body(r);
      await character(id, u);
      final changes = Map<String, dynamic>.from(
        b['changes'] is Map ? b['changes'] : {},
      );
      if (changes.isEmpty) throw ApiError(400, 'No changes supplied.');
      if (changes.length > 500) throw ApiError(400, 'Too many changes.');
      for (final e in changes.entries) {
        if (e.key.startsWith('App!')) {
          try {
            validateAppField(e.key, e.value);
          } on FormatException catch (error) {
            throw ApiError(400, error.message);
          }
          continue;
        }
        final parts = e.key.split('!');
        if (parts.length != 2 ||
            !['Main', 'Stats', 'Abilities', 'Misc'].contains(parts[0]) ||
            !RegExp(r'^[A-Z]{1,2}[1-9][0-9]{0,2}$').hasMatch(parts[1]))
          throw ApiError(400, 'Invalid field ${e.key}');
        final original = reference['sheets'][parts[0]]?[parts[1]];
        if (original?['userEnteredValue']?['formulaValue'] != null)
          throw ApiError(400, 'Calculated fields cannot be overwritten.');
        final v = e.value;
        if (v != null && v is! String && v is! num && v is! bool)
          throw ApiError(400, 'Invalid field type.');
        if (v is String && (v.length > 12000 || v.startsWith('=')))
          throw ApiError(400, 'Text is too long or begins with a formula.');
        final entered = original?['userEnteredValue'] ?? {};
        final validation = original?['dataValidation']?['condition'];
        if (entered['boolValue'] != null && v is! bool)
          throw ApiError(400, 'A checkbox must be true or false.');
        if (entered['numberValue'] != null && v != null && v is! num)
          throw ApiError(400, 'A numeric field needs a number.');
        if (validation?['type'] == 'ONE_OF_LIST' &&
            !(validation['values'] as List).any(
              (x) => '${x['userEnteredValue']}' == '$v',
            ))
          throw ApiError(400, 'Choose an allowed value.');
        if (e.key == 'Stats!B4' &&
            (v is! num || v < 1 || v > 20 || v != v.round()))
          throw ApiError(400, 'This rules table supports levels 1–20.');
      }
      final result = await db.transaction((txn) async {
        final current = await characters.record(id).get(txn);
        if (current == null) throw ApiError(404, 'Character not found.');
        if (u['role'] != 'dm' && current['owner'] != u['username'])
          throw ApiError(403, 'Character ownership changed.');
        if (current['revision'] != b['revision'])
          throw ApiError(
            409,
            'Someone saved changes first. Reload the character and reapply your edit.',
          );
        final values = Map<String, dynamic>.from(current['overrides'] as Map)
          ..addAll(changes);
        final engine = SheetEngine(reference['sheets'], values);
        for (final sh in (reference['sheets'] as Map).entries) {
          for (final a in (sh.value as Map).keys) {
            try {
              engine.value(sh.key, a);
            } catch (_) {
              throw ApiError(
                400,
                'This edit creates a rule error at ${sh.key}!$a.',
              );
            }
          }
        }
        final revision = (current['revision'] as int) + 1;
        final updated = {
          ...current,
          'overrides': values,
          'revision': revision,
          'name': engine.display('Main', 'B2'),
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        };
        await characters.record(id).put(txn, updated);
        await audit.record(secret(12)).put(txn, {
          'characterId': id,
          'actor': u['username'],
          'at': DateTime.now().toUtc().toIso8601String(),
          'action': 'edited',
          'revision': revision,
          'changes': changes,
          'before': {
            for (final k in changes.keys) k: engineOriginal(current, k),
          },
        });
        return updated;
      });
      return jsonResponse(result);
    });
    router.get('/api/characters/<id>/history', (Request r, String id) async {
      await character(id, await identity(r));
      final logs = await audit.find(
        db,
        finder: Finder(
          filter: Filter.equals('characterId', id),
          sortOrders: [SortOrder('at', false)],
          limit: 100,
        ),
      );
      return jsonResponse(logs.map((l) => l.value).toList());
    });
    final staticHandler = webRoot == null
        ? null
        : createStaticHandler(webRoot, defaultDocument: 'index.html');
    return (Request r) async {
      Response response;
      try {
        // Same-origin browser API; native Android clients do not send Origin.
        final origin = r.headers['origin'];
        if (origin != null &&
            Uri.tryParse(origin)?.authority != r.headers['host'])
          throw ApiError(403, 'Cross-origin requests are disabled.');
        response = await router(r);
        if (response.statusCode == 404 &&
            !r.url.path.startsWith('api/') &&
            staticHandler != null)
          response = await staticHandler(r);
      } on ApiError catch (e) {
        response = jsonResponse({'error': e.message}, e.status);
      } catch (e) {
        stderr.writeln('Request failed: ${e.runtimeType}');
        response = jsonResponse({
          'error': 'Server could not complete this request.',
        }, 500);
      }
      return response.change(
        headers: {
          'x-content-type-options': 'nosniff',
          'x-frame-options': 'DENY',
          'referrer-policy': 'same-origin',
        },
      );
    };
  }

  dynamic engineOriginal(Map current, String key) {
    // App entry identifiers are case sensitive, unlike sheet addresses.
    if ((current['overrides'] as Map).containsKey(key)) {
      return current['overrides'][key];
    }
    final p = key.split('!');
    return SheetEngine(
      reference['sheets'],
      Map<String, dynamic>.from(current['overrides']),
    ).value(p[0], p[1]);
  }
}

Future<void> main() async {
  final env = Platform.environment;
  final path = env['FIVE_DATA'] ?? 'data/campaign.db';
  await Directory(File(path).parent.path).create(recursive: true);
  final db = await databaseFactoryIo.openDatabase(path);
  final reference =
      jsonDecode(await File('../assets/reference.json').readAsString())
          as Map<String, dynamic>;
  final app = CampaignServer(db, reference);
  if (await users.count(db) == 0) {
    final name = env['FIVE_DM_USER'] ?? 'dm',
        password = env['FIVE_DM_PASSWORD'];
    if (password == null || password.length < 12) {
      stderr.writeln(
        'First launch requires FIVE_DM_PASSWORD (at least 12 characters).',
      );
      await db.close();
      exitCode = 1;
      return;
    }
    await app.createUser(name, password, 'dm');
    await characters.record('rags').put(db, {
      'name': 'Ragnar "Rags"',
      'owner': name,
      'revision': 1,
      'overrides': <String, dynamic>{},
    });
  }
  final host = env['FIVE_HOST'] ?? '127.0.0.1',
      port = int.parse(env['FIVE_PORT'] ?? '8080');
  final server = await io.serve(
    app.handler(webRoot: '../build/web'),
    host,
    port,
  );
  stdout.writeln(
    '5.0 Character Ledger: http://${server.address.host}:${server.port}',
  );
  stdout.writeln(
    'Database: ${File(path).absolute.path}. Keep this file private and backed up.',
  );
  ProcessSignal.sigint.watch().listen((_) async {
    await server.close(force: true);
    await db.close();
    exit(0);
  });
}
