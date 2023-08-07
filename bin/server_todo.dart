import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ServerTODO {
  final xport = 8156;

  var running = false;
  Future<void> tick() async {
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

  var tasks = <Task>[];
  // var inNext10Mins = <Task>[];

  final serverDoFilename = 'do.json';

  var doContent = {};

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

  Future<String> editOnce(
      String gid, String id, String? time, String? content) async {
    if (doContent[gid] == null) {
      if (time != null) {
        doContent[gid]['todoList'][int.parse(id)]['time'] =
            DateTime.parse(time);
      }
      if (content != null) {
        doContent[gid]['todoList'][int.parse(id)]['time'] =
            DateTime.parse(content);
      }
    } else {
      return 'No task list with GId $gid found, try add it';
    }
    // else { (doContent[gid]['todoList'] as List).add({ 'content': content, 'time': time, }); }

    var doContentFile = File('todo.json');
    await doContentFile.writeAsString(json.encode(doContent));
    return 'Success Edited';
  }

  Future<void> addToDo(name, gid, [time, content]) async {
    if (doContent[gid] == null) {
      doContent[gid] = {
        // 'name': '',
        'todoList': [
          {
            'content': content,
            'time': time,
          },
        ],
      };
    } else {
      (doContent[gid]['todoList'] as List).add({
        'content': content,
        'time': time,
      });
    }

    var doContentFile = File('todo.json');
    await doContentFile.writeAsString(json.encode(doContent));
  }

  Future<void> loadTasks() async {
    var doContentFile = File('todo.json');
    doContent = json.decode(await doContentFile.readAsString());
    for (var dryTask in doContent['todoList']) {
      tasks.add(dryTask);
    }
  }
}

class Task {
  Task(
    this.time,
    this.content, [
    this.statusCode,
  ]);
  final DateTime time;
  final String content;
  late int? statusCode;

  static Task fromJson(Map data) =>
      Task(DateTime.parse(data['time']), data['content'], data['statusCode']);

  Map<String, dynamic> asMap() => {
        'time': time.toString(),
        'content': content,
      };
}
