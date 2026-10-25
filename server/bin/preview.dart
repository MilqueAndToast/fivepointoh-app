import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

Future<void> main() async {
  await io.serve(
    createStaticHandler('../build/web', defaultDocument: 'index.html'),
    '127.0.0.1',
    8765,
  );
  print('Local reference preview: http://127.0.0.1:8765');
}
