import 'dart:io';

import 'package:flutter/material.dart';
import 'package:trackasia_gl/trackasia_gl.dart';
import 'package:path_provider/path_provider.dart';

import 'page.dart';

class LocalStylePage extends ExamplePage {
  LocalStylePage() : super(const Icon(Icons.map), 'Local style');

  @override
  Widget build(BuildContext context) {
    return const LocalStyle();
  }
}

class LocalStyle extends StatefulWidget {
  const LocalStyle();

  @override
  State createState() => LocalStyleState();
}

class LocalStyleState extends State<LocalStyle> {
  TrackasiaMapController? mapController;
  String? styleAbsoluteFilePath;

  @override
  initState() {
    super.initState();

    getApplicationDocumentsDirectory().then((dir) async {
      String documentDir = dir.path;
      String stylesDir = '$documentDir/styles';
      String styleJSON =
          '{"version":8,"name":"Demo style","center":[50,10],"zoom":4,"sources":{"demotiles":{"type":"vector","url":"https://demotiles.trackasia.org/tiles/tiles.json"}},"sprite":"","glyphs":"https://orangemug.github.io/font-glyphs/glyphs/{fontstack}/{range}.pbf","layers":[{"id":"background","type":"background","paint":{"background-color":"rgba(255, 255, 255, 1)"}},{"id":"countries","type":"line","source":"demotiles","source-layer":"countries","paint":{"line-color":"rgba(0, 0, 0, 1)","line-width":1,"line-opacity":1}}]}';

      await new Directory(stylesDir).create(recursive: true);

      File styleFile = new File('$stylesDir/style.json');

      await styleFile.writeAsString(styleJSON);

      setState(() {
        styleAbsoluteFilePath = styleFile.path;
      });
    });
  }

  void _onMapCreated(TrackasiaMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    if (styleAbsoluteFilePath == null) {
      return Scaffold(
        body: Center(child: Text('Creating local style file...')),
      );
    }

    return new Scaffold(
        body: TrackasiaMap(
      styleString: "https://tiles.track-asia.com/tiles/v3/style-streets.json?key=public",
      onMapCreated: _onMapCreated,
      initialCameraPosition: const CameraPosition(target: LatLng(0.0, 0.0)),
      onStyleLoadedCallback: onStyleLoadedCallback,
    ));
  }

  void onStyleLoadedCallback() {}
}
