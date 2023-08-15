import 'dart:io';
import 'dart:math';

void main(List<String> args) {
  var filename = args[0];
  int? start = () {
    try {
      return int.tryParse(args[1]);
    } catch (e) {
      return null;
    }
  }();
  int? end = () {
    try {
      return int.tryParse(args[2]);
    } catch (e) {
      return null;
    }
  }();

  var file = File(filename);
  var r = file.openRead(start, end);
  var sfile = File('${Random().nextInt(1000000)}.gen');
  var sink = sfile.openWrite();
  r.listen((chunk) {
    sink.add(chunk);
  }, onDone: () async {
    await sink.close();
  });
}
