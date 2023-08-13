import 'dart:async';
import 'dart:io';

class DloaderTask {
  late String link;

  DloaderTask(this.link);

  late HttpClientResponse res;
  late StreamSubscription sub;

  var downloaded = 0;
  var size = 0;
  var finished = false;
  var started = false;
  DateTime tryAfter = DateTime.now();

  var stoptimer = false;

  Map<String, dynamic> asMap() => {
        'link': link,
        'downloaded': downloaded,
        'size': size,
        'started': started,
        'tryAfter': tryAfter.toString(),
        'stoptimer': stoptimer,
        'finished': finished,
      };

  DloaderTask.from();

  static DloaderTask fromMap(Map data) {
    var task = DloaderTask.from();
    task.link = data['link'];
    task.downloaded = data['downloaded'];
    task.size = data['size'];
    task.started = data['started'];
    task.tryAfter = DateTime.parse(data['tryAfter']);
    task.stoptimer = data['stoptimer'];
    task.finished = data['finished'];
    return task;
  }

  // void timer() {
  //   Future.delayed(Duration(seconds: 10), () {
  //     // print(status());
  //     if (!stoptimer) {
  //       timer();
  //     }
  //   });
  // }

  String status() {
    return 'Downloaded: $downloaded - $size\n'
        'Started: $started, TryAt: ${tryAfter.month}/${tryAfter.day}'
        ' ${tryAfter.hour}:${tryAfter.minute} - $finished';
  }

  Future<void> start() async {
    var fileName = link.split('/').last;

    var file = File('downloads/$fileName');

    var client = HttpClient();
    var req = await client.getUrl(Uri.parse(link));

    res = await req.close();
    print('Headers: ${res.headers} :Heders');

    if (res.statusCode == 503) {
      // put in the queue
      tryAfter = tryAt(hours: 1);
      return;
    }

    started = true;

    if (res.headers['content-length'] != null) {
      size = int.tryParse(res.headers['content-length']?[0] ?? '0') ?? 0;
    }

    var raf = await file.open(mode: FileMode.writeOnly);

    // timer();

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

  DateTime tryAt({
    int? hours,
    int? minutes,
    int? seconds,
  }) {
    return DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      hours ?? DateTime.now().hour,
      minutes ?? DateTime.now().minute,
      seconds ?? DateTime.now().second,
    );
  }

  void cancel() async => await sub.cancel();
}
