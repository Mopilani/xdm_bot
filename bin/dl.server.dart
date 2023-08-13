import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'net_helper/dloader_task.dart';

var tasksFile = File('dl.s.json');
void main(List<String> args) async {
  var sport = args.isNotEmpty ? args[0] : '8186';
  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? sport);
  final server = await serve(handler, '0.0.0.0', port);
  print('Server listening on port ${server.port}');

  var r = await tasksFile.readAsString();
  for (var entry in json.decode(r).entries) {
    clients.addAll({entry.key: DloaderTask.fromMap(entry.value)});
  }
  Future.delayed(Duration(seconds: 5), () {
    tick();
  });
}

var running = false;

Future<void> tick() async {
  running = true;
  while (running) {
    print('TICK-X');
    await Future.delayed(Duration(minutes: 10));
    print("IT'S TIME-X");
    for (var entry in [...clients.entries]) {
      print("POP-X");
      if (!entry.value.started) {
        print("PIP-X");
        await clients[entry.key]!.start();
      }
    }
  }
}

Map<String, DloaderTask> clients = {};

final router = Router()
  ..post('/add', add)
  ..post('/redown', (req) => add(req, true))
  ..get('/cancel', cancel)
  ..get('/remove', (_) {})
  ..get('/stop', (_) {})
  ..post('/resume', resume)
  ..get('/status', status)
  ..get('/tasks', tasks)
  ..get('/shutdown', shutdown)
  ..get('/k/<v>', (_) {});

Future<Response> resume(Request req, [bool b = false]) async {
  var link = req.headers['link'];
  if (link == null) {
    return Response.ok('You must provide a valid link');
  }
  if (clients[link] == null) {
    return Response.ok('Link not exits');
  }
  var task = clients[link]!;
  await task.resume();
  clients.addAll({link: task});
  return Response.ok('OK');
}

Future<Response> cancel(Request req) async {
  var link = req.headers['link'];
  if (clients[link] != null) {
    clients[link]!.cancel();
    return Response.ok('OK');
  } else {
    return Response.ok('Link not found in the queue');
  }
}

Future<Response> shutdown(Request req) async {
  try {
    await tasksFile.writeAsString(json.encode(clients));
    var res = Response.ok('Shutting Down...');
    Future.delayed(Duration(seconds: 3), () {
      exit(0);
    });
    return res;
  } catch (e) {
    return Response.internalServerError(body: "Cant shutdown: $e");
  }
}

Future<Response> status(Request req) async {
  var link = req.headers['link'];
  if (clients[link] != null) {
    return Response.ok(clients[link]!.status());
  } else {
    return Response.ok('Link not found in the queue');
  }
}

Future<Response> tasks(Request req) async {
  var tasksList = 'Tasks: \n';
  for (int i = 0; i < clients.entries.length; i++) {
    var entry = clients.entries.toList()[i];
    tasksList += '$i: ${entry.value.status()}';
  }
  return Response.ok(tasksList);
}

Future<Response> add(Request req, [bool redown = false]) async {
  var link = req.headers['link'];
  if (link == null) {
    return Response.ok('You must provide a valid link');
  }
  if (clients[link] != null && !redown) {
    return Response.ok('Link was exits');
  }
  var task = DloaderTask(link);
  await task.start();
  clients.addAll({link: task});
  return Response.ok('OK');
}

Response t(Request req) {
  return Response.ok('Ok');
}
