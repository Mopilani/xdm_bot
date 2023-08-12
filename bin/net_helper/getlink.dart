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
  var sink = file.openWrite();

  var count = 0;

  timer() {
    Future.delayed(Duration(seconds: 2), () {
      print(count);
      timer();
    });
  }

  timer();
  
  res.listen((event) {
    count += event.length;
    sink.write(event);
  }, onDone: () {
    timer.cancel();
    print('Done successfuly');
  }, onError: (e, s) {
    print(e);
    print(s);
  });
}
