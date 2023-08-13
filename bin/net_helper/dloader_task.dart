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
  var running = false;
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
    return 'Downloaded: $downloaded from $size\n'
        'Started: ${started ? 'Started' : 'Not Started'}, TryAt: ${tryAfter.month}/${tryAfter.day}'
        ' ${tryAfter.hour}:${tryAfter.minute} - ${finished ? 'Finised' : 'Not Finised'}';
  }

  late RandomAccessFile raf;

  Future<void> start() async {
    var fileName = link.split('/').last;
    var file = File('downloads/$fileName');

    var client = HttpClient();
    var req = await client.getUrl(Uri.parse(link));
    res = await req.close();
    print(
      'StatusCode: ${res.statusCode} :StatusCode\n'
      'Headers: ${res.headers} :Heders',
    );

    if (res.statusCode == 503) {
      tryAfter = tryAt(hours: 1);
      return;
    }

    started = true;
    running = true;

    if (res.headers['content-length'] != null) {
      size = int.tryParse(res.headers['content-length']?[0] ?? '0') ?? 0;
    }

    raf = await file.open(mode: FileMode.writeOnly);

    sub = res.listen(
      onData,
      onDone: onDone,
      onError: onError,
    );
  }

  Future<void> resume() async {
    var fileName = link.split('/').last;
    var file = File('downloads/$fileName');

    var client = HttpClient();
    var req = await client.getUrl(
      Uri.parse(link),
    );
    req.headers.add(HttpHeaders.rangeHeader, '$downloaded-');
    res = await req.close();
    print(
      'StatusCode: ${res.statusCode} :StatusCode\n'
      'Headers: ${res.headers} :Heders',
    );

    if (res.statusCode == 503) {
      tryAfter = tryAt(hours: 1);
      return;
    }

    started = true;
    running = true;

    if (res.headers['content-length'] != null) {
      size = int.tryParse(res.headers['content-length']?[0] ?? '0') ?? 0;
    }

    raf = await file.open(mode: FileMode.writeOnly);

    sub = res.listen(
      onData,
      onDone: onDone,
      onError: onError,
    );
  }

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
