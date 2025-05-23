import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trackasia_gl/trackasia_gl.dart';

import 'page.dart';

class LocalizedMapPage extends ExamplePage {
  const LocalizedMapPage({super.key})
      : super(const Icon(Icons.map), 'Localized screen map');

  @override
  Widget build(BuildContext context) {
    return const LocalizedMap();
  }
}

class LocalizedMap extends StatefulWidget {
  const LocalizedMap({super.key});

  @override
  State createState() => LocalizedMapState();
}

class LocalizedMapState extends State<LocalizedMap> {
  final _mapReadyCompleter = Completer<TrackAsiaMapController>();

  var _mapLanguage = "en";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          DropdownButton<String>(
            value: _mapLanguage,
            icon: const Icon(Icons.arrow_drop_down),
            elevation: 16,
            onChanged: (value) {
              if (value == null) return;

              setState(() => _mapLanguage = value);
              _setMapLanguage();
            },
            items: ["en", "de", "es", "pl"]
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          Expanded(
            child: TrackAsiaMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition:
                  const CameraPosition(target: LatLng(0.0, 0.0)),
              onStyleLoadedCallback: _onStyleLoadedCallback,
            ),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(TrackAsiaMapController controller) {
    _mapReadyCompleter.complete(controller);
  }

  void _onStyleLoadedCallback() {
    _setMapLanguage();
  }

  Future<void> _setMapLanguage() async {
    final controller = await _mapReadyCompleter.future;
    controller.setMapLanguage(_mapLanguage);
  }
}
