import 'package:http/http.dart' as http;
import '../../links.dart';

void main(List<String> args) async {
  // var r = await http.get(
  //   Uri.parse('http://localhost:8000/video'),
  //   headers: {
  //     'link': link,
  //     'range': '100-',
  //   },
  // );

  // print(r.statusCode);
  // print('----------------------------');
  // print(r.headers);
  // print('----------------------------');
  // print(r.bodyBytes.length);
  // print('----------------------------');

  for (var link in links) {
    var r = await http.post(
      uri,
      headers: {'link': link},
    );

    print(r.statusCode);
    print('----------------------------');
    print(r.headers);
    print('----------------------------');
    print(r.body);
    print('----------------------------');
  }
}
