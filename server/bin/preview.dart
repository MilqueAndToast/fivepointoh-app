import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

Future<void> main(List<String> args) async {
  final directory = args.isEmpty ? '../build/web' : args[0];
  final port = args.length < 2 ? 8765 : int.parse(args[1]);
  await io.serve(
    createStaticHandler(directory, defaultDocument: 'index.html'),
    '127.0.0.1',
    port,
  );
  print('Local reference preview: http://127.0.0.1:$port');
}
