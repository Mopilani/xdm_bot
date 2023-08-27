import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'net_helper/dloader_task.dart';

var version = '1.9.4 Beta';

var tasksFile = File('dl.s.json');
var linksFile = File('.links');
var minionsFile = File('dl.minions.json');

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

  if (!(await tasksFile.exists())) tasksFile.writeAsString('{}');
  if (!(await linksFile.exists())) linksFile.writeAsString('[]');
  if (!(await minionsFile.exists())) minionsFile.writeAsString('[]');

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
      print("Client ${entry.key}");
      if (!entry.value.started || entry.value.waiting) {
        print("Starting Waiting Task");
        try {
          if (clients[entry.key]!.fastDOp) {
            var minions = json.decode(await minionsFile.readAsString());
            clients[entry.key]!.speedit(false, [...minions]);
          } else {
            clients[entry.key]!.start();
          }
        } catch (e) {
          print(e);
        }
      }
      if (entry.value.started && entry.value.waiting) {
        print("Resuming Waiting Task");
        try {
          if (clients[entry.key]!.fastDOp) {
            var minions = json.decode(await minionsFile.readAsString());
            clients[entry.key]!.speedit(true, [...minions]);
          } else {
            clients[entry.key]!.resume();
          }
        } catch (e) {
          print(e);
        }
      }
    }
  }
}

Map<String, DloaderTask> clients = {};

final router = Router()
  ..post('/fdl', fastdownload) // Add task
  ..get('/ft', forwaredTraffic) // Add task
  //
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

Future<Response> fastdownload(Request req, [bool redown = false]) async {
  var link = req.headers['link'];
  if (link == null) {
    return Response.badRequest(body: 'You must provide a valid link');
  }
  if (clients[link] != null && !redown) {
    return Response.found('Link was exits');
  }

  // try {
  List links = json.decode(await linksFile.readAsString());
  links.add(link);
  await linksFile.writeAsString(json.encode(links));
  var task = DloaderTask(link);
  task.fastDOp = true;
  var minions = json.decode(await minionsFile.readAsString());
  task.speedit(false, [...minions]);
  clients.addAll({link: task});
  // } catch (e, s) {
  //   print(e);
  //   print(s);
  // }
  return Response.ok('OK');
}

Future<Response> forwaredTraffic(Request req) async {
  var link = req.headers['link'];
  if (link == null) {
    return Response.badRequest(body: 'You must provide a valid link');
  }
  var client = HttpClient();

  var creq = await client.getUrl(Uri.parse(link));
  creq.headers
      .add(HttpHeaders.rangeHeader, req.headers[HttpHeaders.rangeHeader]!);
  var res = await creq.close();
  var stream = res;

  var headers = <String, String>{};
  res.headers.forEach((name, values) => headers.addAll({name: values[0]}));

  return Response(res.statusCode, headers: headers, body: stream);
}

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
  if (task.fastDOp) {
    var minions = json.decode(await minionsFile.readAsString());
    task.speedit(true, [...minions]);
  } else {
    task.resume();
  }
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
    return Response.notFound('Link not exits');
  }

  List links = json.decode(await linksFile.readAsString());
  links.add(nLink);
  links.remove(link);
  await linksFile.writeAsString(json.encode(links));

  var task = clients[link]!;
  task.link = nLink!;
  clients.addAll({nLink: task});
  clients.remove(link);
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
  return Response.ok('$version!');
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
      print('Links not found, Adding it..');
      var fileName = link.split('/').last;
      var file = File('downloads/$fileName');
      if (await file.exists()) {
        print('File $fileName exists');
        var fstat = await file.stat();
        var task = DloaderTask(link);
        task.downloaded = fstat.size;
        // try {
        //   var res = await http.get(Uri.parse(link));
        //   res.body;
        //   var size = int.parse(
        //     (res.headers[HttpHeaders.contentRangeHeader]![0]).split('/').last,
        //   );
        //   task.size = size;
        // } catch (e) {
        //   print(e);
        //   task.size = 0;
        // }
        task.size = 0;
        clients.addAll({link: task});
      } else {
        print('File $fileName Not exists');
        var task = DloaderTask(link);
        task.downloaded = 0;
        // try {
        //   // var res = await http.get(
        //   //   Uri.parse(link),
        //   //   headers: {
        //   //     // HttpHeaders.rangeHeader: 'bytes=0-100',
        //   //   },
        //   // );
        //   // res.request.;
        //   // var client = HttpClient();
        //   // var req = await client.getUrl(Uri.parse(link));
        //   // var res1 = await req.close();
        //   // res1.first;
        //   // await res1.listen((event) {}).cancel();
        //   // var size = int.parse(
        //   //   (res.headers[HttpHeaders.contentRangeHeader]![0]).split('/').last,
        //   // );
        //   // task.size = size;
        // } catch (e) {
        //   print(e);
        //   task.size = 0;
        // }
        task.size = 0;
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
    return Response.ok(await clients[link]!.stop());
  } else {
    return Response.ok('Link not found in the queue');
  }
}

Future<Response> remove(Request req) async {
  var link = req.headers['link'];
  var deleteFiles = req.headers['deleteFiles'];
  if (clients[link] != null) {
    if (deleteFiles == 'true') {
      var client = clients[link];
      var file = File('downloads/${client!.filename}');
      if (await file.exists()) {
        await file.delete();
      }
    }
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
