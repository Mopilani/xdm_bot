import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Pass the file url');
    return;
  }

  var fileurl = args[0];
  var filename = fileurl.split('/').last;
  var file = File(filename);
  var sink = file.openWrite();

  var client = HttpClient();
  var req = await client.getUrl(Uri.parse(fileurl));
  var res = await req.close();

  res.listen(
    (chunk) {
      sink.add(chunk);
    },
    onDone: () {
      sink.close();
    },
    onError: (e, s) {
      print(e);
      print(s);
    }
  );
}
