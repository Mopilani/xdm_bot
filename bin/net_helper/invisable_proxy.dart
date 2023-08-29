import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stdout.writeln('You must provide the server address to connect to.');
    exit(1);
  }

  var hostAndPort = args.first;

  var client = HttpClient();
  var req = await client.getUrl(Uri.parse('http://$hostAndPort/hiamip'));
  var res = await req.close();
  var link = res.headers.value('link');
  if (link == null) {
    stdout.writeln('Bad Response');
    exit(400);
  }
  // var range = res.headers.value(HttpHeaders.rangeHeader);

  var creq = await client.getUrl(Uri.parse(link));
  creq.headers
      .add(HttpHeaders.rangeHeader, req.headers[HttpHeaders.rangeHeader]!);
  res = await creq.close();

  var headers = <String, String>{};
  res.headers.forEach((name, values) => headers.addAll({name: values[0]}));
  var stream = res;
  req = await client.getUrl(Uri.parse('http://$hostAndPort/part'));
  req.addStream(stream);
  res = await req.close();
  // res.;

  // res.listen((event) {});
}
