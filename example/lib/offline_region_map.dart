import 'package:flutter/material.dart';
import 'package:trackasia_gl/trackasia_gl.dart';

import 'offline_regions.dart';

class OfflineRegionMap extends StatefulWidget {
  OfflineRegionMap(this.item);

  final OfflineRegionListItem item;

  @override
  _OfflineRegionMapState createState() => _OfflineRegionMapState();
}

class _OfflineRegionMapState extends State<OfflineRegionMap> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Offline Region: ${widget.item.name}'),
      ),
      body: TrackasiaMap(
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: widget.item.offlineRegionDefinition.minZoom,
        ),
        minMaxZoomPreference: MinMaxZoomPreference(
          widget.item.offlineRegionDefinition.minZoom,
          widget.item.offlineRegionDefinition.maxZoom,
        ),
        styleString: "https://tiles.track-asia.com/tiles/v3/style-streets.json?key=public",
        cameraTargetBounds: CameraTargetBounds(
          widget.item.offlineRegionDefinition.bounds,
        ),
      ),
    );
  }

  LatLng get _center {
    final bounds = widget.item.offlineRegionDefinition.bounds;
    final lat = (bounds.southwest.latitude + bounds.northeast.latitude) / 2;
    final lng = (bounds.southwest.longitude + bounds.northeast.longitude) / 2;
    return LatLng(lat, lng);
  }
}
