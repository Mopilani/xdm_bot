import 'dart:async';
import 'dart:io';

class DloaderTask {
  String link;

  DloaderTask(this.link);

  late HttpClientResponse res;
  late StreamSubscription sub;

  var downloaded = 0;
  var size = 0;

  var stoptimer = false;

  void timer() {
    Future.delayed(Duration(seconds: 2), () {
      print(status());
      if (!stoptimer) {
        timer();
      }
    });
  }

  String status() {
    return 'Downloaded: $downloaded - $size';
  }

  Future<void> start() async {
    var fileName = link.split('/').last;

    var file = File('downloads/$fileName');

    var client = HttpClient();
    var req = await client.getUrl(Uri.parse(link));

    res = await req.close();
    var raf = await file.open(mode: FileMode.writeOnly);

    timer();

    void onDone() {
      stoptimer = true;
      print('Done successfuly');
    }

    void onError(e, s) {
      print(e);
      print(s);
    }

    void onData(List<int> event) async {
      downloaded += event.length;
      raf.writeFromSync(event);
    }

    sub = res.listen(
      onData,
      onDone: onDone,
      onError: onError,
    );
  }

  void cancel() async => await sub.cancel();
}
