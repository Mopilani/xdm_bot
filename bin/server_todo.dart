import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ServerTODO {
  static final xport = 8156;

  static var running = false;
  static Future<void> tick() async {
    running = true;
    while (running) {
      await Future.delayed(Duration(seconds: 30));
      for (var task in tasks) {
        if (task.time.millisecondsSinceEpoch <
            DateTime.now().millisecondsSinceEpoch) {
          var res = await http.post(
            Uri.parse('http://localhost:$xport/post'),
            body: task.content,
          );
          task.statusCode = res.statusCode;
        }
      }
    }
  }

  static var tasks = <Task>[];
  // var inNext10Mins = <Task>[];

  static final serverDoFilename = 'do.json';

  static var doContent = {};

  /// Do Content Arch:
  /// { gid :
  ///      {
  ///          name : string,
  ///          todoList :
  ///                [
  ///                  {
  ///                     content : Content,
  ///                     time: time,
  ///                   }
  ///                ]
  ///           }
  ///      }
  /// }
  ///

  static Future<String> editOnce(
    String gid,
    String id,
    DateTime? time,
    String? content,
    bool? periodicly,
  ) async {
    if (doContent[gid] == null) {
      if (time != null) {
        doContent[gid]['todoList'][int.parse(id)]['time'] = time;
      }
      if (content != null) {
        doContent[gid]['todoList'][int.parse(id)]['content'] = content;
      }
      if (periodicly != null) {
        doContent[gid]['todoList'][int.parse(id)]['periodicly'] = periodicly;
      }
    } else {
      return 'No task list with GId $gid found, try add it';
    }
    // else { (doContent[gid]['todoList'] as List).add({ 'content': content, 'time': time, }); }

    var doContentFile = File('todo.json');
    await doContentFile.writeAsString(json.encode(doContent));
    return 'Success Edited';
  }

  Future<String> addToDo(name, gid, [time, content]) async {
    var id = doContent.entries.length + 1;
    if (doContent[gid] == null) {
      doContent[gid] = {
        // 'name': '',
        'todoList': [
          {
            'content': content,
            'time': time,
            'periodicly': false,
          },
        ],
      };
    } else {
      (doContent[gid]['todoList'] as List).add({
        'content': content,
        'time': time,
        'periodicly': false,
      });
    }

    var doContentFile = File('todo.json');
    await doContentFile.writeAsString(json.encode(doContent));
    return 'Added Successfuly Id $id';
  }

  static Future<void> loadTasks() async {
    var doContentFile = File('todo.json');
    doContent = json.decode(await doContentFile.readAsString());
    for (var group in doContent.entries) {
      for (var dryTask in doContent[group.key]['todoList']) {
        tasks.add(Task.fromMap(dryTask));
      }
    }
    ServerTODO.tick();
  }
}

class Task {
  Task(
    this.time,
    this.content, [
    this.statusCode,
    this.periodicly,
  ]);
  final DateTime time;
  final String content;
  late int? statusCode;
  late bool? periodicly;

  static Task fromMap(Map data) => Task(
        DateTime.parse(data['time']),
        data['content'],
        data['statusCode'],
        data['periodicly'],
      );

  Map<String, dynamic> asMap() => {
        'time': time.toString(),
        'content': content,
        'periodicly': periodicly,
      };
}
