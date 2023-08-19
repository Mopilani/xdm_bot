import 'dart:async';
import 'dart:io';
import 'dart:isolate';

class DloaderTask {
  late String link;
  late String filename;

  DloaderTask(this.link);

  late HttpClientResponse res;
  late StreamSubscription sub;

  int downloaded = 0;
  int size = 0;
  bool finished = false;
  bool started = false;
  bool running = false;
  bool waiting = false;

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
        ' ${tryAfter.hour}:${tryAfter.minute} - ${finished ? 'Finised' : 'Not Finished'}\n';
  }

  Map<String, dynamic> inJson() {
    return {
      'link': link,
      'downloaded': downloaded,
      'size': size,
      'started': started,
      'tryAfter': tryAfter.toString(),
      'stoptimer': stoptimer,
      'running': running,
      'finished': finished,
      'waiting': waiting,
    };
  }

  late RandomAccessFile raf;
  bool partialContent = false;
  bool firstTry = true;

  bool _continue(int statusCode) {
    switch (statusCode) {
      case 503:
        tryAfter = tryAt(hours: 1);
        waiting = true;
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
      case 200:
        print('OK');
        partialContent = true;
        return true;
      default:
        return false;
    }
  }

  Future<String> start([bool resume = false]) async {
    filename = link.split('/').last;
    var file = File('downloads/$filename');
    var client = HttpClient();

    if (resume) {
      if (await file.exists()) {
        var stat = await file.stat();
        if (downloaded != stat.size) {
          downloaded = stat.size;
        }
      }
    } else {
      if (await file.exists()) {
        await file.delete();
        await file.create();
      }
    }

    raf = await file.open(mode: FileMode.writeOnlyAppend);

    try {
      while (partialContent || firstTry) {
        await Future.delayed(Duration(milliseconds: 100));
        var req = await client.getUrl(Uri.parse(link));

        if (partialContent || resume) {
          // req.headers.add(HttpHeaders.rangeHeader, '$downloaded-');
          if (downloaded > size) {
          } else {
            req.headers.add(HttpHeaders.rangeHeader, 'bytes=$downloaded-$size');
          }
        }

        res = await req.close();

        print(
          '---------------------------------------'
          'ReqHeaders: ${req.headers} :ReqHeaders'
          '---------------------------------------',
        );

        print(
          'StatusCode: ${res.statusCode} :StatusCode\n'
          'Headers: ${res.headers} :Headers',
        );

        if (_continue(res.statusCode)) {
          // continue
        } else {
          return 'In Queue, Waiting...';
        }

        started = true;
        running = true;
        waiting = false;

        if (res.headers[HttpHeaders.contentRangeHeader] != null) {
          size = int.parse(
            (res.headers[HttpHeaders.contentRangeHeader]![0]).split('/').last,
          );
          int expectedSize = downloaded +
              int.parse(
                (res.headers[HttpHeaders.contentLengthHeader]![0]),
              );
          print('size: $size == expectedSize: $expectedSize');
          if (size == expectedSize || expectedSize > size) {
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
      return onDone();
    } catch (e, s) {
      return onError(e, s);
    }
  }

  // var minionsSubs = <StreamSubscription>[];
  // var minionsRafs = <RandomAccessFile>[];
  // List<(int start, int end)> ranges = <(int start, int end)>[];
  List<Map<String, dynamic>> progress = [];

  Future<String> speedit(
      [bool resume = false, List<String> minions = const []]) async {
    filename = link.split('/').last;
    var file = File('downloads/$filename');
    var client = HttpClient();

    raf = await file.open(mode: FileMode.writeOnlyAppend);

    if (resume) {
      if (await file.exists()) {
        var stat = await file.stat();
        if (downloaded != stat.size) {
          downloaded = stat.size;
        }
      }
    } else {
      if (await file.exists()) {
        await file.delete();
        await file.create();
      }
    }

    // clients <String>[]
    // for client
    // range segmenter
    // get range

    try {
      // Request for file downlaod to get file size
      var req = await client.getUrl(Uri.parse(link));

      var rres = await req.close();

      if (_continue(rres.statusCode)) {
        // continue
      } else {
        return 'In Queue, Waiting...';
      }

      started = true;
      running = true;
      waiting = false;

      progress.add({
        'range': null,
        'size': 0,
        'downloaded': 0,
        'waiting': false,
        'sub': null,
        'raf': null,
        'started': false,
        'finished': false,
      });

      if (res.headers[HttpHeaders.contentRangeHeader] != null) {
        size = int.parse(
          (res.headers[HttpHeaders.contentRangeHeader]![0]).split('/').last,
        );
        int expectedSize = downloaded +
            int.parse(
              (res.headers[HttpHeaders.contentLengthHeader]![0]),
            );
        print('size: $size == expectedSize: $expectedSize');
        if (size == expectedSize || expectedSize > size) {
          partialContent = false;
        }
      } else {
        if (res.headers[HttpHeaders.contentLengthHeader] != null) {
          size = int.tryParse(res.headers['content-length']?[0] ?? '0') ?? 0;
        }
      }

      var minionsCount = minions.length;
      var remaining = size % minionsCount;
      var fixedSize = size - remaining;
      var segSize = (fixedSize / minionsCount).round();
      var point = 0;
      var overbytesFixed = false;

      for (var _ in minions) {
        progress.add({
          'range': null,
          'size': 0,
          'downloaded': 0,
          'waiting': false,
          'sub': null,
          'raf': null,
          'started': false,
          'finished': false,
        });

        if (overbytesFixed) {
          point = point + segSize;
          progress[0]['range'] = [point, point];
        } else {
          // ranges.add((point, point + segSize + remaining));
          point = point + segSize + remaining;
          progress[0]['range'] = [point, point];
          overbytesFixed = true;
        }
      }

      sub = res.listen(
        (d) => onMutliPartFileData(d, raf, 0),
        // onDone: onDone,
        onError: onError,
      );

      progress[0]['sub'] = sub;
      progress[0]['raf'] = raf;
      progress[0]['size'] = size;

      for (int i = 0; i < minions.length; i++) {
        progress.add({
          'done': false,
          'range': [int, int],
          'size': 0,
          'downloaded': 0,
          'waiting': false,
          'started': false,
          'finished': false,
        });

        var minionUrl = minions[i];
        var req = await client.getUrl(Uri.parse(minionUrl));
        if (partialContent || resume) {
          // req.headers.add(HttpHeaders.rangeHeader, '$downloaded-');
          var range = progress[0]['range'];
          req.headers
              .add(HttpHeaders.rangeHeader, 'bytes=${range.$1}-${range.$2}');
        }
        var file = File('downloads/$filename');

        if (resume) {
          if (await file.exists()) {
            var stat = await file.stat();
            if (downloaded != stat.size) {
              downloaded = stat.size;
            }
          }
        } else {
          if (await file.exists()) {
            await file.delete();
            await file.create();
          }
        }

        progress[i]['started'] = true;

        RandomAccessFile raf = await file.open(mode: FileMode.writeOnlyAppend);

        var sub = res.listen(
          (d) => onMutliPartFileData(d, raf, i + 1),
          onDone: () {
            if (progress[i]['downloaded'] == progress[i]['size']) {
              progress[i]['finished'] = true;
            } else if (progress[i]['downloaded'] >= progress[i]['size']) {
              progress[i]['finished'] = true;
              progress[i]['started'] = true;
              throw 'The downloaded is bigger than the segment file';
            }
          },
          onError: onError,
        );
        progress[0]['sub'] = (sub);
        progress[0]['raf'] = (raf);
      }

      await sub.asFuture();

      firstTry = false;
      return onDone();
    } catch (e, s) {
      return onError(e, s);
    }
  }

  Future<String> stop() async {
    await sub.cancel();
    stoptimer = true;
    running = false;
    waiting = false;
    // started = false;
    raf.closeSync();
    return ('Stopped successfuly');
  }

  Future<String> resume() async {
    partialContent = true;
    firstTry = false;
    await start(true);
    return ('Resuming Download');
  }

  //   while (exits) { if (file.existsSync()) { partNumber++;
  //       file = File('downloads/$fileName-($partNumber).xdl.part'); } else { exits = false; } }

  String onDone() {
    stoptimer = true;
    running = false;
    waiting = false;
    // started = false;
    if (downloaded == size) {
      finished = true;
    }
    raf.closeSync();
    return ('Done successfuly');
  }

  String onError(e, s) {
    print(e);
    print(s);
    stoptimer = true;
    running = false;
    waiting = false;
    // started = false;
    raf.closeSync();
    return e.toString();
  }

  void onData(List<int> event) async {
    downloaded += event.length;
    raf.writeFromSync(event);
  }

  void onMutliPartFileData(
      List<int> event, RandomAccessFile raf, int fi) async {
    downloaded += event.length;
    // (int, int) r = ranges[fi];
    // ranges[fi] = (r.$1, r.$2 + event.length);
    progress[fi]['downloaded'] += event.length;
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
