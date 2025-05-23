// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:trackasia_gl/trackasia_gl.dart';

import 'page.dart';

final LatLngBounds sydneyBounds = LatLngBounds(
  southwest: const LatLng(-34.022631, 150.620685),
  northeast: const LatLng(-33.571835, 151.325952),
);

class MapUiPage extends ExamplePage {
  const MapUiPage({super.key}) : super(const Icon(Icons.map), 'User interface');

  @override
  Widget build(BuildContext context) {
    return const MapUiBody();
  }
}

class MapUiBody extends StatefulWidget {
  const MapUiBody({super.key});

  @override
  State<StatefulWidget> createState() => MapUiBodyState();
}

class MapUiBodyState extends State<MapUiBody> {
  MapUiBodyState();

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(-33.852, 151.211),
    zoom: 11.0,
  );

  TrackAsiaMapController? mapController;
  CameraPosition _position = _kInitialPosition;
  bool _isMoving = false;
  bool _compassEnabled = true;
  bool _mapExpanded = true;
  CameraTargetBounds _cameraTargetBounds = CameraTargetBounds.unbounded;
  MinMaxZoomPreference _minMaxZoomPreference = MinMaxZoomPreference.unbounded;
  int _styleStringIndex = 0;

  // Style string can a reference to a local or remote resources.
  // On Android the raw JSON can also be passed via a styleString, on iOS this is not supported.
  final List<String> _styleStrings = [TrackAsiaStyles.demo, "assets/style.json"];
  final List<String> _styleStringLabels = [
    "TrackAsia demo style",
    "Local style file"
  ];
  bool _rotateGesturesEnabled = true;
  bool _scrollGesturesEnabled = true;
  bool? _doubleClickToZoomEnabled;
  bool _tiltGesturesEnabled = true;
  bool _zoomGesturesEnabled = true;
  bool _myLocationEnabled = true;
  bool _telemetryEnabled = true;
  bool _countriesVisible = true;
  MyLocationTrackingMode _myLocationTrackingMode = MyLocationTrackingMode.none;
  MyLocationRenderMode _myLocationRenderMode = MyLocationRenderMode.normal;
  List<Object>? _featureQueryFilter;
  Fill? _selectedFill;

  void _onMapChanged() {
    setState(() {
      _extractMapInfo();
    });
  }

  void _extractMapInfo() {
    final position = mapController!.cameraPosition;
    if (position != null) _position = position;
    _isMoving = mapController!.isCameraMoving;
  }

  @override
  void dispose() {
    mapController?.removeListener(_onMapChanged);
    super.dispose();
  }

  Widget _myLocationTrackingModeCycler() {
    final nextType = MyLocationTrackingMode.values[
        (_myLocationTrackingMode.index + 1) %
            MyLocationTrackingMode.values.length];
    return TextButton(
      child: Text('change to $nextType'),
      onPressed: () {
        setState(() {
          _myLocationTrackingMode = nextType;
        });
      },
    );
  }

  Widget _myLocationRenderModeCycler() {
    final nextType = MyLocationRenderMode.values[
        (_myLocationRenderMode.index + 1) % MyLocationRenderMode.values.length];
    return TextButton(
      onPressed:
          _myLocationEnabled == true || nextType == MyLocationRenderMode.normal
              ? () {
                  setState(() {
                    _myLocationRenderMode = nextType;
                  });
                }
              : null,
      child: Text('change to $nextType'),
    );
  }

  Widget _queryFilterToggler() {
    return TextButton(
      child: Text(
          'filter zoo on click ${_featureQueryFilter == null ? 'disabled' : 'enabled'}'),
      onPressed: () {
        setState(() {
          if (_featureQueryFilter == null) {
            _featureQueryFilter = [
              "==",
              ["get", "type"],
              "zoo"
            ];
          } else {
            _featureQueryFilter = null;
          }
        });
      },
    );
  }

  Widget _mapSizeToggler() {
    return TextButton(
      child: Text('${_mapExpanded ? 'shrink' : 'expand'} map'),
      onPressed: () {
        setState(() {
          _mapExpanded = !_mapExpanded;
        });
      },
    );
  }

  Widget _compassToggler() {
    return TextButton(
      child: Text('${_compassEnabled ? 'disable' : 'enable'} compasss'),
      onPressed: () {
        setState(() {
          _compassEnabled = !_compassEnabled;
        });
      },
    );
  }

  Widget _latLngBoundsToggler() {
    return TextButton(
      child: Text(
        _cameraTargetBounds.bounds == null
            ? 'bound camera target'
            : 'release camera target',
      ),
      onPressed: () {
        setState(() {
          _cameraTargetBounds = _cameraTargetBounds.bounds == null
              ? CameraTargetBounds(sydneyBounds)
              : CameraTargetBounds.unbounded;
        });
      },
    );
  }

  Widget _zoomBoundsToggler() {
    return TextButton(
      child: Text(_minMaxZoomPreference.minZoom == null
          ? 'bound zoom'
          : 'release zoom'),
      onPressed: () {
        setState(() {
          _minMaxZoomPreference = _minMaxZoomPreference.minZoom == null
              ? const MinMaxZoomPreference(12.0, 16.0)
              : MinMaxZoomPreference.unbounded;
        });
      },
    );
  }

  Widget _setStyleToSatellite() {
    return TextButton(
      child: Text(
          'change map style to ${_styleStringLabels[(_styleStringIndex + 1) % _styleStringLabels.length]}'),
      onPressed: () {
        setState(() {
          _styleStringIndex = (_styleStringIndex + 1) % _styleStrings.length;
        });
      },
    );
  }

  Widget _rotateToggler() {
    return TextButton(
      child: Text('${_rotateGesturesEnabled ? 'disable' : 'enable'} rotate'),
      onPressed: () {
        setState(() {
          _rotateGesturesEnabled = !_rotateGesturesEnabled;
        });
      },
    );
  }

  Widget _scrollToggler() {
    return TextButton(
      child: Text('${_scrollGesturesEnabled ? 'disable' : 'enable'} scroll'),
      onPressed: () {
        setState(() {
          _scrollGesturesEnabled = !_scrollGesturesEnabled;
        });
      },
    );
  }

  Widget _doubleClickToZoomToggler() {
    final stateInfo = _doubleClickToZoomEnabled == null
        ? "disable"
        : _doubleClickToZoomEnabled!
            ? 'unset'
            : 'enable';
    return TextButton(
      child: Text('$stateInfo double click to zoom'),
      onPressed: () {
        setState(() {
          if (_doubleClickToZoomEnabled == null) {
            _doubleClickToZoomEnabled = false;
          } else if (!_doubleClickToZoomEnabled!) {
            _doubleClickToZoomEnabled = true;
          } else {
            _doubleClickToZoomEnabled = null;
          }
        });
      },
    );
  }

  Widget _tiltToggler() {
    return TextButton(
      child: Text('${_tiltGesturesEnabled ? 'disable' : 'enable'} tilt'),
      onPressed: () {
        setState(() {
          _tiltGesturesEnabled = !_tiltGesturesEnabled;
        });
      },
    );
  }

  Widget _zoomToggler() {
    return TextButton(
      child: Text('${_zoomGesturesEnabled ? 'disable' : 'enable'} zoom'),
      onPressed: () {
        setState(() {
          _zoomGesturesEnabled = !_zoomGesturesEnabled;
        });
      },
    );
  }

  Widget _myLocationToggler() {
    return TextButton(
      onPressed: _myLocationRenderMode == MyLocationRenderMode.normal
          ? () {
              setState(() {
                _myLocationEnabled = !_myLocationEnabled;
              });
            }
          : null,
      child: Text('${_myLocationEnabled ? 'disable' : 'enable'} my location'),
    );
  }

  Widget _telemetryToggler() {
    return TextButton(
      child: Text('${_telemetryEnabled ? 'disable' : 'enable'} telemetry'),
      onPressed: () {
        setState(() {
          _telemetryEnabled = !_telemetryEnabled;
        });
        mapController?.setTelemetryEnabled(_telemetryEnabled);
      },
    );
  }

  Widget _visibleRegionGetter() {
    return TextButton(
      child: const Text('get currently visible region'),
      onPressed: () async {
        final result = await mapController!.getVisibleRegion();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("SW: ${result.southwest} NE: ${result.northeast}"),
        ));
      },
    );
  }

  Widget _sourceFeaturesGetter() {
    return TextButton(
      child: const Text('get source features (trackasia)'),
      onPressed: () async {
        final result = await mapController!
            .querySourceFeatures("trackasia", "centroids", null);
        debugPrint(result.toString());
      },
    );
  }

  Widget _layerVisibilityToggler() {
    return TextButton(
      child: const Text('toggle layer visibility'),
      onPressed: () async {
        _countriesVisible = !_countriesVisible;
        mapController?.setLayerVisibility('countries-fill', _countriesVisible);
      },
    );
  }

  _clearFill() {
    if (_selectedFill != null) {
      mapController!.removeFill(_selectedFill!);
      setState(() {
        _selectedFill = null;
      });
    }
  }

  _drawFill(List<dynamic> features) async {
    final Map<String, dynamic>? feature =
        features.firstWhereOrNull((f) => f['geometry']['type'] == 'Polygon');

    if (feature != null) {
      final List<List<LatLng>> geometry = feature['geometry']['coordinates']
          .map(
              (ll) => ll.map((l) => LatLng(l[1], l[0])).toList().cast<LatLng>())
          .toList()
          .cast<List<LatLng>>();
      final fill = await mapController!.addFill(FillOptions(
        geometry: geometry,
        fillColor: "#FF0000",
        fillOutlineColor: "#FF0000",
        fillOpacity: 0.6,
      ));
      setState(() {
        _selectedFill = fill;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackasiaMap = TrackAsiaMap(
      onMapCreated: onMapCreated,
      initialCameraPosition: _kInitialPosition,
      trackCameraPosition: true,
      compassEnabled: _compassEnabled,
      cameraTargetBounds: _cameraTargetBounds,
      minMaxZoomPreference: _minMaxZoomPreference,
      styleString: _styleStrings[_styleStringIndex],
      rotateGesturesEnabled: _rotateGesturesEnabled,
      scrollGesturesEnabled: _scrollGesturesEnabled,
      tiltGesturesEnabled: _tiltGesturesEnabled,
      zoomGesturesEnabled: _zoomGesturesEnabled,
      doubleClickZoomEnabled: _doubleClickToZoomEnabled,
      myLocationEnabled: _myLocationEnabled,
      myLocationTrackingMode: _myLocationTrackingMode,
      myLocationRenderMode: _myLocationRenderMode,
      onMapClick: (point, latLng) async {
        debugPrint(
            "Map click: ${point.x},${point.y}   ${latLng.latitude}/${latLng.longitude}");
        debugPrint("Filter $_featureQueryFilter");
        final features = await mapController!
            .queryRenderedFeatures(point, [], _featureQueryFilter);
        if (!mounted) return;

        debugPrint('# features: ${features.length}');
        _clearFill();
        if (features.isEmpty && _featureQueryFilter != null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('QueryRenderedFeatures: No features found!')));
          }
        } else if (features.isNotEmpty) {
          _drawFill(features);
        }
      },
      onMapLongClick: (point, latLng) async {
        debugPrint(
            "Map long press: ${point.x},${point.y}   ${latLng.latitude}/${latLng.longitude}");
        final convertedPoint = await mapController!.toScreenLocation(latLng);
        final convertedLatLng = await mapController!.toLatLng(point);
        debugPrint(
            "Map long press converted: ${convertedPoint.x},${convertedPoint.y}   ${convertedLatLng.latitude}/${convertedLatLng.longitude}");
        final metersPerPixel =
            await mapController!.getMetersPerPixelAtLatitude(latLng.latitude);

        debugPrint(
            "Map long press The distance measured in meters at latitude ${latLng.latitude} is $metersPerPixel m");

        final features =
            await mapController!.queryRenderedFeatures(point, [], null);
        if (features.isNotEmpty) {
          debugPrint(features[0]);
        }
      },
      onCameraTrackingDismissed: () {
        setState(() {
          _myLocationTrackingMode = MyLocationTrackingMode.none;
        });
      },
      onUserLocationUpdated: (location) {
        debugPrint(
            "new location: ${location.position}, alt.: ${location.altitude}, bearing: ${location.bearing}, speed: ${location.speed}, horiz. accuracy: ${location.horizontalAccuracy}, vert. accuracy: ${location.verticalAccuracy}");
      },
    );

    final listViewChildren = <Widget>[];

    if (mapController != null) {
      listViewChildren.addAll(
        <Widget>[
          Text('camera bearing: ${_position.bearing}'),
          Text('camera target: ${_position.target.latitude.toStringAsFixed(4)},'
              '${_position.target.longitude.toStringAsFixed(4)}'),
          Text('camera zoom: ${_position.zoom}'),
          Text('camera tilt: ${_position.tilt}'),
          Text(_isMoving ? '(Camera moving)' : '(Camera idle)'),
          _mapSizeToggler(),
          _queryFilterToggler(),
          _compassToggler(),
          _myLocationTrackingModeCycler(),
          _myLocationRenderModeCycler(),
          _latLngBoundsToggler(),
          _setStyleToSatellite(),
          _zoomBoundsToggler(),
          _rotateToggler(),
          _scrollToggler(),
          _doubleClickToZoomToggler(),
          _tiltToggler(),
          _zoomToggler(),
          _myLocationToggler(),
          _telemetryToggler(),
          _visibleRegionGetter(),
          _layerVisibilityToggler(),
          _sourceFeaturesGetter(),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: SizedBox(
            width: _mapExpanded ? null : 300.0,
            height: 200.0,
            child: trackasiaMap,
          ),
        ),
        Expanded(
          child: ListView(
            children: listViewChildren,
          ),
        )
      ],
    );
  }

  void onMapCreated(TrackAsiaMapController controller) {
    mapController = controller;
    mapController!.addListener(_onMapChanged);
    _extractMapInfo();

    mapController!.getTelemetryEnabled().then((isEnabled) => setState(() {
          _telemetryEnabled = isEnabled;
        }));
  }
}
