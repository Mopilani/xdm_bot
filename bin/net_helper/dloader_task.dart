import 'dart:async';
import 'dart:io';
import 'dart:isolate';

class DloaderTask {
  late String link;

  DloaderTask(this.link);

  late HttpClientResponse res;
  late StreamSubscription sub;

  int downloaded = 0;
  int size = 0;
  bool finished = false;
  bool started = false;
  bool running = false;

  String? stopMsg = '';

  DateTime tryAfter = DateTime.now();

  bool stoptimer = false;

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
    return '$link\n'
        'Downloaded: $downloaded from $size\n'
        'Started: ${started ? 'Started' : 'Not Started'}, TryAt: ${tryAfter.month}/${tryAfter.day}'
        ' ${tryAfter.hour}:${tryAfter.minute} - ${finished ? 'Finised' : 'Not Finised'}\n';
  }

  late RandomAccessFile raf;
  bool partialContent = false;
  bool firstTry = true;

  bool _continue(int statusCode) {
    switch (statusCode) {
      case 503:
        tryAfter = tryAt(hours: 1);
        return false;
      case 400:
        stopMsg = 'Bad Request';
        onError(RemoteError(stopMsg!, ''), StackTrace.current);
        return false;
      case 404:
        stopMsg = 'Not Found';
        onError(RemoteError(stopMsg!, ''), StackTrace.current);
        return false;
      case 500:
        stopMsg = 'Internal Server Eror';
        onError(RemoteError(stopMsg!, ''), StackTrace.current);
        return false;
      case 206:
        print('Partial_Content');
        partialContent = true;
        return true;
      default:
        return true;
    }
  }

  Future<void> start() async {
    var fileName = link.split('/').last;
    var file = File('downloads/$fileName');
    var client = HttpClient();

    raf = await file.open(mode: FileMode.writeOnlyAppend);

    try {
      while (partialContent || firstTry) {
        // await Future.delayed(Duration(seconds: 1));
        var req = await client.getUrl(Uri.parse(link));

        if (partialContent) {
          req.headers.add(HttpHeaders.rangeHeader, '$downloaded-');
        }

        res = await req.close();

        print(
          'StatusCode: ${res.statusCode} :StatusCode\n'
          'Headers: ${res.headers} :Heders',
        );

        if (_continue(res.statusCode)) {
          // continue
        } else {
          return;
        }

        started = true;
        running = true;

        if (res.headers[HttpHeaders.contentRangeHeader] != null) {
          size = int.parse(
            (res.headers[HttpHeaders.contentRangeHeader]![0]).split('/').last,
          );
          int expectedSize = downloaded +
              int.parse(
                (res.headers[HttpHeaders.contentLengthHeader]![0]),
              );
          print('size: $size == expectedSize: $expectedSize');
          if (size == expectedSize) {
            partialContent = false;
          }
        } else {
          if (res.headers[HttpHeaders.contentLengthHeader] != null) {
            size = int.tryParse(res.headers['content-length']?[0] ?? '0') ?? 0;
          }
        }

        sub = res.listen(
          onData,
          // onDone: onDone,
          onError: onError,
        );
        await sub.asFuture();
        firstTry = false;
      }
      onDone();
    } catch (e, s) {
      onError(e, s);
    }
  }

  Future<void> resume() async {
    partialContent = true; 
    firstTry = false;
    await start();
  }

  // Future<void> resume() async {
  //   var fileName = link.split('/').last;
  //   var exits = true;
  //   var partNumber = 0;
  //   File file = File('downloads/$fileName');

  //   while (exits) {
  //     if (file.existsSync()) {
  //       partNumber++;
  //       file = File('downloads/$fileName-($partNumber).xdl.part');
  //     } else {
  //       exits = false;
  //     }
  //   }

  //   var client = HttpClient();
  //   var req = await client.getUrl(
  //     Uri.parse(link),
  //   );

  //   var length = file.statSync().size;
  //   if (length != downloaded) {
  //     downloaded = length;
  //     req.headers.add(HttpHeaders.rangeHeader, '$length-');
  //   } else {
  //     req.headers.add(HttpHeaders.rangeHeader, '$downloaded-');
  //   }

  //   res = await req.close();
  //   print(
  //     'StatusCode: ${res.statusCode} :StatusCode\n'
  //     'Headers: ${res.headers} :Heders',
  //   );

  //   if (_continue(res.statusCode)) {
  //     // continue
  //   } else {
  //     return;
  //   }

  //   started = true;
  //   running = true;

  //   if (res.headers['content-length'] != null) {
  //     size = int.tryParse(res.headers['content-length']?[0] ?? '0') ?? 0;
  //   }

  //   raf = await file.open(mode: FileMode.writeOnly);

  //   sub = res.listen(
  //     onData,
  //     onDone: onDone,
  //     onError: onError,
  //   );
  // }

  void onDone() {
    stoptimer = true;
    running = false;
    if (downloaded == size) {
      finished = true;
    }
    raf.closeSync();
    print('Done successfuly');
  }

  void onError(e, s) {
    print(e);
    print(s);
    running = false;
    raf.closeSync();
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
