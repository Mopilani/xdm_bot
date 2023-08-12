import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:js_interop';

class SSHClientBridge {
  String host;

  SSHClientBridge(this.host);

  late Process sshProcess;

  Future<void> startWith() async {
    sshProcess = await Process.start('ssh', [host]);
    // return sshProcess;
  }

  void sendCommand(command) {
    sshProcess.stdin.write(command);
  }

  void bind(FutureOr<void> Function(String) callBack) {
    sshProcess.stdout.listen((event) async {
      await callBack(utf8.decode(event));
    });
  }

  whatsClientCallBack() {
    return (event) {
      
    };
  }
}
