import 'dart:io';

import 'package:flutter/material.dart';
import 'package:trackasia_gl/trackasia_gl.dart';
import 'package:path_provider/path_provider.dart';

import 'page.dart';

class LocalStylePage extends ExamplePage {
  const LocalStylePage({super.key})
      : super(const Icon(Icons.map), 'Local style');

  @override
  Widget build(BuildContext context) {
    return const LocalStyle();
  }
}

class LocalStyle extends StatefulWidget {
  const LocalStyle({super.key});

  @override
  State createState() => LocalStyleState();
}

class LocalStyleState extends State<LocalStyle> {
  TrackAsiaMapController? mapController;
  String? styleAbsoluteFilePath;

  @override
  initState() {
    super.initState();

    getApplicationDocumentsDirectory().then((dir) async {
      final documentDir = dir.path;
      final stylesDir = '$documentDir/styles';
      const styleJSON =
          '{"version":8,"name":"Demo style","center":[50,10],"zoom":4,"sources":{"demotiles":{"type":"vector","url":"https://maps.track-asia.com/tiles/tiles.json"}},"sprite":"","glyphs":"https://orangemug.github.io/font-glyphs/glyphs/{fontstack}/{range}.pbf","layers":[{"id":"background","type":"background","paint":{"background-color":"rgba(255, 255, 255, 1)"}},{"id":"countries","type":"line","source":"demotiles","source-layer":"countries","paint":{"line-color":"rgba(0, 0, 0, 1)","line-width":1,"line-opacity":1}}]}';

      await Directory(stylesDir).create(recursive: true);

      final styleFile = File('$stylesDir/style.json');

      await styleFile.writeAsString(styleJSON);

      setState(() {
        styleAbsoluteFilePath = styleFile.path;
      });
    });
  }

  void _onMapCreated(TrackAsiaMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final styleAbsoluteFilePath = this.styleAbsoluteFilePath;

    if (styleAbsoluteFilePath == null) {
      return const Scaffold(
        body: Center(child: Text('Creating local style file...')),
      );
    }

    return Scaffold(
        body: TrackAsiaMap(
      styleString: styleAbsoluteFilePath,
      onMapCreated: _onMapCreated,
      initialCameraPosition: const CameraPosition(target: LatLng(0.0, 0.0)),
      onStyleLoadedCallback: onStyleLoadedCallback,
    ));
  }

  void onStyleLoadedCallback() {}
}
