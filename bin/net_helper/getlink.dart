import 'dart:async';
import 'dart:io';

// import 'package:http/http.dart' as http;
// https://dl3.downloadly.ir/Files/Elearning/Coursera_Foundations_of_Cybersecurity_2023_5_Downloadly.ir.rar
void main(List<String> args) async {
  var link = args[0];
  var fileName = link.split('/').last;

  var file = File(fileName);

  var client = HttpClient();
  var req = await client.getUrl(Uri.parse(link));

  var res = await req.close();
  var sink = await file.open(
    mode: FileMode.writeOnly,
    // encoding: latin1,
  );

  var count = 0;
  var stoptimer = false;

  timer() {
    Future.delayed(Duration(seconds: 2), () {
      print(count);
      if (!stoptimer) {
        timer();
      }
    });
  }

  timer();

  res.listen((event) async {
    count += event.length;
    sink.writeFromSync(event);
    // sink.write(event);
  }, onDone: () {
    stoptimer = true;
    print('Done successfuly');
  }, onError: (e, s) {
    print(e);
    print(s);
  });
}
