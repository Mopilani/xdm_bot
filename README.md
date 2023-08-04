# XDM Bot Dart server

A server app built using [Shelf](https://pub.dev/packages/shelf),
configured to enable running with [Docker](https://www.docker.com/).

This server empowering the whatsapp XDM Bot and the Telegram XDM Bot too.

# Running the sample
You need to make a copy of the file tsrv.cfg with name srv.cfg and 
try replacing the "YOUR_TOKEN_HERE" with your Telegram Bot Token to makes it
works for you. Else the run will throw an erro so the file srv.cfg isn't provided.
<br> you need to make yours

## Running with the Dart SDK

You can run the example with the [Dart SDK](https://dart.dev/get-dart)
like this:

```
$ dart run bin/server.dart
Server listening on port 8185
```

And then from a second terminal:
```
$ curl http://0.0.0.0:8185/lessons
This month, lessons ...
```

## Running with Docker

If you have [Docker Desktop](https://www.docker.com/get-started) installed, you
can build and run with the `docker` command:

```
$ docker build . -t myserver
$ docker run -it -p 8185:8185 myserver
Server listening on port 8185
```

And then from a second terminal:
```
$ curl http://0.0.0.0:8185/lessons
This month, lessons ...
```

You should see the logging printed in the first terminal:
```
2021-05-06T15:47:04.620417  0:00:00.000158 GET     [200] /lessons
```
