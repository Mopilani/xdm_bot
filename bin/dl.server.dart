import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'net_helper/dloader_task.dart';

import 'package:http/http.dart' as http;

var tasksFile = File('dl.s.json');
var linksFile = File('.links');

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
      if (!entry.value.started || entry.value.waiting) {
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
  ..get('/ping', ping)
  ..get('/remove', remove)
  ..get('/stop', stop)
  ..get('/resume', resume)
  ..get('/resume/<number>', resume)
  ..get('/refresh/<number>', refresh)
  ..get('/s/<filename>', getFile)
  ..get('/status', status)
  ..get('/recover', recover)
  ..get('/tasks', tasks)
  ..get('/jsapi/tasks', tasksInJson)
  ..get('/shutdown', shutdown);

Future<Response> resume(Request req) async {
  var taskNumber = int.tryParse(req.params['number'] ?? 'NA');
  String? link;

  if (taskNumber != null) {
    link = req.headers['link'] ??
        (taskNumber < clients.keys.length
            ? clients.keys.toList()[taskNumber]
            : null);
  } else {
    link = req.headers['link'];
  }

  if (link == null) {
    return Response.badRequest(body: 'You must provide a valid link');
  }
  if (clients[link] == null) {
    return Response.found('Link not exits');
  }
  var task = clients[link]!;
  await task.resume();
  clients.addAll({link: task});
  return Response.ok('OK');
}

Future<Response> refresh(Request req) async {
  var taskNumber = int.tryParse(req.params['number'] ?? 'NA');
  String? link;
  String? nLink;

  if (taskNumber != null) {
    link = req.headers['link'] ??
        (taskNumber < clients.keys.length
            ? clients.keys.toList()[taskNumber]
            : null);
  } else {
    link = req.headers['link'];
  }
  nLink = req.headers['nLink'];

  if (link == null) {
    return Response.badRequest(body: 'You must provide a valid link');
  }
  if (clients[link] == null) {
    return Response.found('Link not exits');
  }

  List links = json.decode(await linksFile.readAsString());
  links.add(nLink);
  await linksFile.writeAsString(json.encode(links));

  var task = clients[link]!;
  task.link = nLink!;
  clients.addAll({nLink: task});
  clients.remove(nLink);
  return Response.ok('OK');
}

Future<Response> getFile(Request req) async {
  var filename = (req.params['filename']);
  var range = <int>[];

  if (req.headers.containsKey(HttpHeaders.rangeHeader)) {
    var rng = req.headers[HttpHeaders.rangeHeader];
    // bytes=$downloaded-$size
    range = rng!.split('=').last.split('-').map((e) => int.parse(e)).toList();
  }

  var file = File('downloads/$filename');

  if (await file.exists()) {
    Stream<List<int>> bytesStream;
    var fsize = (await file.stat()).size;
    if (range.isNotEmpty) {
      if (range.last > fsize) {
        range.last = fsize;
        bytesStream = file.openRead(range.first, range.last);
      } else {
        bytesStream = file.openRead(range.first, range.last);
      }
    } else {
      bytesStream = file.openRead();
    }

    return Response.ok(bytesStream, headers: {
      HttpHeaders.contentRangeHeader: '${range.first}-${range.last}/$fsize',
      HttpHeaders.contentTypeHeader: ContentType.binary.mimeType,
    });
  } else {
    return Response.notFound('File $filename Not Found');
  }
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

Future<Response> ping(Request req) async {
  return Response.ok('Pong!');
}

Future<Response> shutdown(Request req) async {
  try {
    clients.forEach((key, value) {});
    List<String> links = <String>[];
    for (var client in clients.entries) {
      try {
        await client.value.stop();
      } catch (e) {
        //
      }
      links.add(client.key);
    }
    await linksFile.writeAsString(json.encode(links));

    await tasksFile.writeAsString(
        json.encode(clients.map((key, value) => MapEntry(key, value.asMap()))));
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

Future<Response> recover(Request req) async {
  // var link = req.headers['link'];
  List links = json.decode(await linksFile.readAsString());
  for (var link in links) {
    // if (link == null) {
    //   return Response.badRequest(body: 'Please provide valid link');
    // }
    if (clients[link] == null) {
      var fileName = link.split('/').last;
      var file = File('downloads/$fileName');
      if (await file.exists()) {
        var fstat = await file.stat();
        // fstat.size;
        var task = DloaderTask(link);
        task.downloaded = fstat.size;
        try {
          var res = await http.get(Uri.parse(link));
          var size = int.parse(
            (res.headers[HttpHeaders.contentRangeHeader]![0]).split('/').last,
          );
          task.size = size;
        } catch (e) {
          print(e);
          task.size = 0;
        }
        clients.addAll({link: task});
      }
      // return Response.ok('Recovered Successfuly');
    } else {
      // return Response.found('Link was exits queue');
    }
  }
  return Response.ok('${links.length} Recovered Successfully.');
}

Future<Response> stop(Request req) async {
  var link = req.headers['link'];
  if (clients[link] != null) {
    return Response.ok(clients[link]!.stop());
  } else {
    return Response.ok('Link not found in the queue');
  }
}

Future<Response> remove(Request req) async {
  var link = req.headers['link'];
  if (clients[link] != null) {
    clients.remove(link);
    List links = json.decode(await linksFile.readAsString());
    links.remove(link);
    await linksFile.writeAsString(json.encode(links));
    return Response.ok('Removed Successfully');
  } else {
    return Response.ok('Link not found in the queue');
  }
}

Future<Response> tasks(Request req) async {
  var running = 0;
  var finished = 0;
  var waiting = 0;

  for (int i = 0; i < clients.entries.length; i++) {
    var entry = clients.entries.toList()[i];
    if (entry.value.finished) {
      finished++;
    }
    if (entry.value.running) {
      running++;
    }
    if (entry.value.waiting) {
      waiting++;
    }
  }

  var tasksList =
      'Tasks:    All: ${clients.entries.length}   |   Running: $running   |   Waiting: $waiting   |   Finished: $finished  \n';
  for (int i = 0; i < clients.entries.length; i++) {
    var entry = clients.entries.toList()[i];
    tasksList += '$i: ${entry.value.status()}';
  }
  return Response.ok(tasksList);
}

Future<Response> tasksInJson(Request req) async {
  var running = 0;
  var finished = 0;
  var waiting = 0;

  for (int i = 0; i < clients.entries.length; i++) {
    var entry = clients.entries.toList()[i];
    if (entry.value.finished) {
      finished++;
    }
    if (entry.value.running) {
      running++;
    }
    if (entry.value.waiting) {
      waiting++;
    }
  }
  var body = <String, dynamic>{
    'running': running,
    'finished': finished,
    'waiting': waiting,
    'all': clients.entries.length,
    'tasks': [],
  };
  for (int i = 0; i < clients.entries.length; i++) {
    var entry = clients.entries.toList()[i];
    body['tasks'].add(entry.value.inJson());
  }

  return Response.ok(json.encode(body));
}

Future<Response> add(Request req, [bool redown = false]) async {
  var link = req.headers['link'];
  if (link == null) {
    return Response.badRequest(body: 'You must provide a valid link');
  }
  if (clients[link] != null && !redown) {
    return Response.found('Link was exits');
  }

  List links = json.decode(await linksFile.readAsString());
  links.add(link);
  await linksFile.writeAsString(json.encode(links));

  var task = DloaderTask(link);
  task.start();
  clients.addAll({link: task});
  return Response.ok('OK');
}

Response t(Request req) {
  return Response.ok('Ok');
}
