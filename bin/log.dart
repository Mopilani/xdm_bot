import 'dart:convert';
import 'dart:io';

class Log {
  Log._();

  static Log? _ins;

  factory Log() {
    if (_ins == null) {
      _ins = Log._();
      return _ins!;
    }
    return _ins!;
  }

  String readAsJson() => json.encode(logLines);

  List<String> logLines = [];

  void log(Object obj) {
    logLines.add('${DateTime.now().millisecondsSinceEpoch}: $obj');
  }

  Future<List<String>> readFile() async {
    var logFile = File('${DateTime.now().millisecondsSinceEpoch}.log');
    var contents = await logFile.readAsString();
    return json.decode(contents);
  }

  Future<void> saveToFile() async {
    var logFile = File('${DateTime.now().millisecondsSinceEpoch}.log');
    await logFile.writeAsString(
      json.encode(log),
    );
    logLines.clear();
  }
}
