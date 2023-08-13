import 'package:http/http.dart' as http;
import '../../links.dart';

void main(List<String> args) async {
  var r = await http.post(
    Uri.parse('http://167.172.167.245:8186/add'),
    headers: {'link': link},
  );

  print(r.statusCode);
  print('----------------------------');
  print(r.headers);
  print('----------------------------');
  print(r.body);
  print('----------------------------');
}
