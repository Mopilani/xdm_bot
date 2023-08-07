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
}

class Task {
  Task(this.time, this.content);
  final DateTime time;
  final String content;
  late int statusCode;
}
