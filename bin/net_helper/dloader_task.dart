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

  // Fast Download Opration
  bool fastDOp = false;
  List<Map<String, dynamic>> progress = [];

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
        'fastDOp': fastDOp,
        'progress': progress
            .map(
              (e) => e.map(
                (key, value) => MapEntry(
                    key,
                    key == 'sub' || key == 'raf' || key == 'file'
                        ? null
                        : value),
              ),
            )
            .toList(),
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
    task.fastDOp = data['fastDOp'];
    task.progress = <Map<String, dynamic>>[...data['progress']];
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
        onError(RemoteError(stopMsg!, ''), 'StackTrace.current');
        return false;
      case 404:
        stopMsg = 'Not Found';
        onError(RemoteError(stopMsg!, ''), 'StackTrace.current');
        return false;
      case 500:
        stopMsg = 'Internal Server Eror';
        onError(RemoteError(stopMsg!, ''), 'StackTrace.current');
        return false;
      case 206:
        print('Partial_Content');
        partialContent = true;
        return true;
      case 200:
        print('OK');
        // partialContent = true;
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
          if (size == downloaded) {
            return onDone();
          }
        } else {
          if (res.headers[HttpHeaders.contentLengthHeader] != null) {
            size = int.tryParse(res.headers['content-length']?[0] ?? '0') ?? 0;
          }
          if (size == downloaded) {
            return onDone();
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

  Future<String> speedit([
    bool resume = false,
    List<String> minions = const [],
  ]) async {
    filename = link.split('/').last;
    var file = File('downloads/$filename');
    var client = HttpClient();

    if (await file.exists()) {
      await file.delete();
      await file.create();
    }
    // raf = await file.open(mode: FileMode.writeOnlyAppend);

    void sumSize(res) {
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
    }

    try {
      // Request for file downlaod to get file size
      var req = await client.getUrl(Uri.parse(link));

      res = await req.close();

      var ok = false;
      if (res.statusCode != 200) {
        ok = true;
      }
      // _continue(res.statusCode);

      while (!ok) {
        for (int i = 0; i < minions.length; i++) {
          var minionUrl = minions[i];
          var req = await client.getUrl(Uri.parse(minionUrl));
          req.headers.add(HttpHeaders.rangeHeader, 'bytes=0-100');
          req.headers.add('link', link);
          var res = await req.close();
          if (res.statusCode != 200) {
            sumSize(res);
            ok = true;
          }
        }
      }

      if (ok || _continue(res.statusCode)) {
        // continue
      } else {
        return 'In Queue, Waiting...';
      }

      started = true;
      running = true;
      waiting = false;

      sumSize(res);

      try {
        res.listen((event) {}).cancel();
      } catch (e) {
        //
      }

      var minionsCount = minions.length;
      var remaining = size % minionsCount;
      var fixedSize = size - remaining;
      var segSize = (fixedSize / minionsCount).round();
      var point = 0;
      var overbytesFixed = false;

      void prepareProgress() {
        for (var i = 0; i < minions.length; i++) {
          progress.add({
            'range': null,
            'size': 0,
            'downloaded': 0,
            'waiting': false,
            'sub': null,
            'raf': null,
            'file': null,
            'started': false,
            'finished': false,
          });

          if (overbytesFixed) {
            var start = point;
            var end = point + segSize;
            point = end;
            progress[i]['size'] = end - start;
            progress[i]['range'] = [start, end];
            print('NODE $i range ${progress[i]['range']}');
          } else {
            // ranges.add((point, point + segSize + remaining));
            var start = point;
            var end = segSize + remaining;
            point = end;
            progress[i]['size'] = end - start;
            progress[i]['range'] = [start, end];
            print('NODE $i range ${progress[i]['range']}');
            overbytesFixed = true;
          }
        }
      }

      if (resume) {
        // continue
      } else {
        prepareProgress();
      }

      // http://localhost:8000/kim.mp4

      print(progress);

      for (int i = 0; i < minions.length; i++) {
        () async {
          var minionUrl = minions[i];
          var file = File('downloads/$filename-$i');
          var range = progress[i]['range'];

          if (resume) {
            if (await file.exists()) {
              var stat = await file.stat();
              if (progress[i]['downloaded'] != stat.size) {
                progress[i]['downloaded'] = stat.size;
              }
            }
          } else {
            if (await file.exists()) {
              await file.delete();
              await file.create();
            }
          }

          var req = await client.getUrl(Uri.parse(minionUrl));
          req.headers.add(
            HttpHeaders.rangeHeader,
            'bytes=${range[0] + progress[i]['downloaded']}-${range[1]}',
          );
          req.headers.add('link', link);

          var res = await req.close();
          while (res.statusCode != 200) {
            print('Waiting until Another Response...');
            await Future.delayed(Duration(minutes: 15));
          }

          print('res.StatusCode\n${res.statusCode}');
          print('res.headers\n' '${res.headers}\nres.headers');

          progress[i]['started'] = true;
          progress[i]['file'] = file;

          RandomAccessFile raf =
              await file.open(mode: FileMode.writeOnlyAppend);

          var sub = res.listen(
            (d) => onMutliPartFileData(d, raf, i),
            onDone: () {
              if (progress[i]['downloaded'] == progress[i]['size']) {
                progress[i]['finished'] = true;
                progress[i]['running'] = false;
              } else if (progress[i]['downloaded'] > progress[i]['size']) {
                progress[i]['finished'] = true;
                progress[i]['started'] = true;
                progress[i]['running'] = false;
                print(
                    'The downloaded is bigger than the segment file num $i \n${progress[i]}\n');
              }
              raf.close();
            },
            onError: onError,
          );
          progress[i]['sub'] = (sub);
          progress[i]['raf'] = (raf);
        }();
      }

      bool allFinished = false;
      while (!allFinished) {
        print('Waiting for All to Finish');
        await Future.delayed(Duration(seconds: 10));
        var sounds = <bool>[];
        for (var i = 0; i < progress.length; i++) {
          if (progress[i]['finished']) {
            sounds.add(true);
          }
        }
        if (sounds.length == progress.length) {
          allFinished = true;
        }
      }
      var sink = file.openWrite(mode: FileMode.append);
      for (var i = 0; i < progress.length; i++) {
        await sink.addStream((progress[i]['file'] as File).openRead());
      }
      await sink.close();
      for (var i = 0; i < progress.length; i++) {
        (progress[i]['file'] as File).delete();
      }

      firstTry = false;
      stoptimer = true;
      running = false;
      waiting = false;
      if (downloaded == size) {
        finished = true;
      }
      return ('Done successfuly');
    } catch (e, s) {
      print(e);
      print(s);
      stoptimer = true;
      running = false;
      waiting = false;
      return e.toString();
    }
  }

  Future<String> stop() async {
    if (fastDOp) {
      for (var prog in progress) {
        try {
          prog['raf'].closeSync();
        } catch (e) {
          //
        }
        try {
          prog['sub'].cancel();
        } catch (e) {
          //
        }
      }
      stoptimer = true;
      running = false;
      waiting = false;
    } else {
      await sub.cancel();
      stoptimer = true;
      running = false;
      waiting = false;
      // started = false;
      raf.closeSync();
    }
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
    List<int> event,
    RandomAccessFile raf,
    int fi,
  ) async {
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
