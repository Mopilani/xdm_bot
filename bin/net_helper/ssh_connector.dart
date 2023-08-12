import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../author.dart';

class SSHClientBridge {
  String host;

  SSHClientBridge(this.host);

  late Process sshProcess;

  Future<void> start() async {
    sshProcess = await Process.start('ssh', [host]);
  }
  
  void stop() async {
    sshProcess.stdin.writeln('exit');
    sshProcess.kill();
  }

  void sendCommand(command) {
    sshProcess.stdin.write(command);
  }

  void bind(FutureOr<void> Function(String) callBack) {
    sshProcess.stdout.listen((event) async {
      await callBack(utf8.decode(event));
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
