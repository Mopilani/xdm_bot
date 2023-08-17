import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

var version = '1.8.15 Beta';

void main(List<String> args) async {
  var sport = args.isNotEmpty ? args[0] : '8186';
  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? sport);
  final server = await serve(handler, '0.0.0.0', port);
  print('Server listening on port ${server.port}');
}

final router = Router()..get('/getfile/<filename>', getFile);

Future<Response> getFile(Request req) async {
  var filename = req.params['filename'];
  if (filename == null) {
    return Response.badRequest();
  }
  var file = File(filename);
  var stream = file.openRead();

  return Response.ok(stream);
}
