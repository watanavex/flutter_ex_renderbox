import 'dart:typed_data';

import 'package:bitmap/bitmap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> implements Listener {
  int _counter = 0;
  Uint8List? _rawImage;
  bool _flag = false;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void callBack(ui.Image image) async {
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    setState(() {
      if (byteData == null) {
        _rawImage = null;
      } else {
        _rawImage = byteData.buffer.asUint8List();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dots(
      listener: this,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'You have pushed the button this many times:',
              ),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headline4,
              ),
              TextButton(
                onPressed: () {
                  debugPrint("press");
                },
                child: Text("hoge"),
              ),
              TextButton(
                onPressed: () {
                  debugPrint("press");
                },
                child: Text("fuga"),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.ac_unit_sharp),
              ),
              Switch(
                value: _flag,
                onChanged: (v) {
                  setState(() {
                    _flag = !_flag;
                  });
                },
              ),
              if (_rawImage != null) Image.memory(_rawImage!)
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}

class RenderDots extends RenderConstrainedBox {
  RenderDots(this.listener)
      : super(additionalConstraints: const BoxConstraints.expand());

  Listener listener;
  // BuildContext context;
  static const platform = MethodChannel('samples.flutter.dev/image');

  // Makes this render box hittable so that we'll get pointer events.
  @override
  bool hitTestSelf(Offset position) => true;
  BoxHitTestResult? hitTestResult;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    hitTestResult = result;
    return super.hitTest(result, position: position);
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) async {
    if (event is! PointerUpEvent) {
      return;
    }

    debugPrint("handleEvent");

    final htr = hitTestResult;
    if (htr == null) {
      return;
    }

    final RenderRepaintBoundary renderRepaintBoundary = htr.path
        .map((element) {
          return element.target;
        })
        .whereType<RenderRepaintBoundary>()
        .first;

    htr.path.map((element) {
      return element.target;
    }).forEach((element) {
      debugPrint("$element");
    });
    // final renderBoxes = htr.path
    //     .map((element) {
    //       return element.target;
    //     })
    //     .whereType<MaterialInkController>()
    //     .whereType<RenderBox>();
    final renderBoxes = htr.path.map((element) {
      return element.target;
    }).whereType<RenderMouseRegion>();

    // if (renderBoxes.length < 2) {
    //   debugPrint("Skip");
    //   return;
    // }

    final target = renderBoxes.first;
    final renderBox = target as RenderBox;
    final size = renderBox.size;
    final x = renderBox.localToGlobal(Offset.zero).dx;
    final y = renderBox.localToGlobal(Offset.zero).dy;

    print("Image!, ${renderBox}");
    Future.delayed(
      Duration(milliseconds: 20),
      () async {
        final image = await renderRepaintBoundary.toImage();
        final byteData = await image.toByteData();
        final byteArray = byteData!.buffer.asUint8List();
        platform.invokeMethod("crop", [
          byteArray,
          image.width,
          image.height,
          x,
          y,
          size.width,
          size.height,
        ]);

        // listener.callBack(image);
      },
    );
  }
}

abstract class Listener {
  void callBack(ui.Image image);
}

class Dots extends SingleChildRenderObjectWidget {
  Dots({Key? key, Widget? child, required Listener this.listener})
      : super(key: key, child: child);

  // Dots.initialize({Key? key, Widget? child, required Listener this.listener}) {
  //   RenderRepaintBoundary(

  //   )
  // }

  Listener listener;

  @override
  RenderDots createRenderObject(BuildContext context) {
    debugPrint("createRenderObject");

    return RenderDots(listener);
  }
}
