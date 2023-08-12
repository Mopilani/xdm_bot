import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'net_helper/dloader_task.dart';

// https://dl3.downloadly.ir/Files/Elearning/Coursera_Foundations_of_Cybersecurity_2023_5_Downloadly.ir.rar
void main(List<String> args) async {
  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8186');
  final server = await serve(handler, '0.0.0.0', port);
  print('Server listening on port ${server.port}');
}

Map<String, DloaderTask> clients = {};

final router = Router()
  ..post('/add', add)
  ..get('/cancel', cancel)
  ..get('/remove', (_) {})
  ..get('/stop', (_) {})
  ..get('/resume', (_) {})
  ..get('/status', status)
  ..get('/tasks', tasks)
  ..get('/k/<v>', (_) {});

Future<Response> cancel(Request req) async {
  var link = req.headers['link'];
  if (clients[link] == null) {
    clients[link]!.cancel();
    return Response.ok('OK');
  } else {
    return Response.ok('Link not found in the queue');
  }
}

Future<Response> status(Request req) async {
  var link = req.headers['link'];
  if (clients[link] == null) {
    return Response.ok(clients[link]!.status());
  } else {
    return Response.ok('Link not found in the queue');
  }
}

Future<Response> tasks(Request req) async {
  var tasksList = 'Tasks: \n';
  for (int i = 0; i < clients.entries.length; i++) {
    var entry = clients.entries.toList()[i];
    tasksList += '$i: ${entry.key},';
  }
  return Response.ok(tasksList);
}

Future<Response> add(Request req) async {
  var body = utf8.decode(await req.read().first);
  var link = json.decode(body)['link'];
  var task = DloaderTask(link);
  await task.start();
  clients.addAll({link: task});
  return Response.ok('OK');
}

Response t(Request req) {
  return Response.ok('Ok');
}
