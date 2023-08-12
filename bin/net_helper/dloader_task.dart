import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../author.dart';

class DloaderTask {
  String link;

  DloaderTask(this.link);

  late Process sshProcess;

  Future<void> start() async {
    sshProcess = await Process.start(
      'curl',
      [link],
      runInShell: false,
    );
  }

  void stop() async {
    // http.get();

    sshProcess.stdin.writeln('exit');
    sshProcess.kill();
  }

  void sendCommand(command) {
    sshProcess.stdin.writeln(command);
  }

  void bind(FutureOr<void> Function(String) callBack) {
    sshProcess.stdout.listen((event) async {
      var data = utf8.decode(event);
      print(data);
      await callBack(data);
    }, onError: (e, s) async {
      await callBack(e.toString());
      print('stderr: $e');
      print(s);
    });

    sshProcess.stderr.listen((event) async {
      var data = utf8.decode(event);
      print(data);
      await callBack(data);
    }, onError: (e, s) async {
      await callBack(e.toString());
      print('err: $e');
      print(s);
    });
  }

  Future Function(String) whatsClientCallBack(String receiver) {
    return (event) async {
      await http.post(
        Uri.parse('http://localhost:$xport/ssh'),
        headers: {
          'receiver': receiver,
          HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
        },
        body: json.encode(event),
      );
    };
  }
}
