import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:trackasia_gl/trackasia_gl.dart';

import 'offline_region_map.dart';
import 'page.dart';

final LatLngBounds hawaiiBounds = LatLngBounds(
  southwest: const LatLng(17.26672, -161.14746),
  northeast: const LatLng(23.76523, -153.74267),
);

final LatLngBounds santiagoBounds = LatLngBounds(
  southwest: const LatLng(-33.5597, -70.49102),
  northeast: const LatLng(-33.33282, -153.74267),
);

final LatLngBounds aucklandBounds = LatLngBounds(
  southwest: const LatLng(-36.87838, 174.73205),
  northeast: const LatLng(-36.82838, 174.79745),
);

final List<OfflineRegionDefinition> regionDefinitions = [
  OfflineRegionDefinition(
    bounds: hawaiiBounds,
    minZoom: 3.0,
    maxZoom: 8.0,
    mapStyleUrl: TrackAsiaStyles.demo,
  ),
  OfflineRegionDefinition(
    bounds: santiagoBounds,
    minZoom: 10.0,
    maxZoom: 16.0,
    mapStyleUrl: TrackAsiaStyles.demo,
  ),
  OfflineRegionDefinition(
    bounds: aucklandBounds,
    minZoom: 13.0,
    maxZoom: 16.0,
    mapStyleUrl: TrackAsiaStyles.demo,
  ),
];

final List<String> regionNames = ['Hawaii', 'Santiago', 'Auckland'];

class OfflineRegionListItem {
  OfflineRegionListItem({
    required this.offlineRegionDefinition,
    required this.downloadedId,
    required this.isDownloading,
    required this.name,
    required this.estimatedTiles,
  });

  final OfflineRegionDefinition offlineRegionDefinition;
  final int? downloadedId;
  final bool isDownloading;
  final String name;
  final int estimatedTiles;

  OfflineRegionListItem copyWith({
    int? downloadedId,
    bool? isDownloading,
  }) =>
      OfflineRegionListItem(
        offlineRegionDefinition: offlineRegionDefinition,
        name: name,
        estimatedTiles: estimatedTiles,
        downloadedId: downloadedId,
        isDownloading: isDownloading ?? this.isDownloading,
      );

  bool get isDownloaded => downloadedId != null;
}

final List<OfflineRegionListItem> allRegions = [
  OfflineRegionListItem(
    offlineRegionDefinition: regionDefinitions[0],
    downloadedId: null,
    isDownloading: false,
    name: regionNames[0],
    estimatedTiles: 61,
  ),
  OfflineRegionListItem(
    offlineRegionDefinition: regionDefinitions[1],
    downloadedId: null,
    isDownloading: false,
    name: regionNames[1],
    estimatedTiles: 3580,
  ),
  OfflineRegionListItem(
    offlineRegionDefinition: regionDefinitions[2],
    downloadedId: null,
    isDownloading: false,
    name: regionNames[2],
    estimatedTiles: 202,
  ),
];

class OfflineRegionsPage extends ExamplePage {
  const OfflineRegionsPage({super.key})
      : super(const Icon(Icons.map), 'Offline Regions');

  @override
  Widget build(BuildContext context) {
    return const OfflineRegionBody();
  }
}

class OfflineRegionBody extends StatefulWidget {
  const OfflineRegionBody({super.key});

  @override
  State<OfflineRegionBody> createState() => _OfflineRegionsBodyState();
}

class _OfflineRegionsBodyState extends State<OfflineRegionBody> {
  final List<OfflineRegionListItem> _items = [];

  @override
  void initState() {
    super.initState();
    _updateListOfRegions();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          itemCount: _items.length,
          itemBuilder: (context, index) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.map),
                onPressed: () => _goToMap(_items[index]),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _items[index].name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Est. tiles: ${_items[index].estimatedTiles}',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (_items[index].isDownloading)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(),
                )
              else
                IconButton(
                  icon: Icon(
                    _items[index].isDownloaded
                        ? Icons.delete
                        : Icons.file_download,
                  ),
                  onPressed: _items[index].isDownloaded
                      ? () => _deleteRegion(_items[index], index)
                      : () => _downloadRegion(_items[index], index),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _updateListOfRegions() async {
    final offlineRegions = await getListOfRegions();
    final regionItems = <OfflineRegionListItem>[];
    for (final item in allRegions) {
      final offlineRegion = offlineRegions.firstWhereOrNull(
          (offlineRegion) => offlineRegion.metadata['name'] == item.name);
      if (offlineRegion != null) {
        regionItems.add(item.copyWith(downloadedId: offlineRegion.id));
      } else {
        regionItems.add(item);
      }
    }
    setState(() {
      _items.clear();
      _items.addAll(regionItems);
    });
  }

  Future<void> _downloadRegion(OfflineRegionListItem item, int index) async {
    setState(() {
      _items.removeAt(index);
      _items.insert(index, item.copyWith(isDownloading: true));
    });

    try {
      final downloadingRegion = await downloadOfflineRegion(
        item.offlineRegionDefinition,
        metadata: {
          'name': regionNames[index],
        },
      );
      setState(() {
        _items.removeAt(index);
        _items.insert(
            index,
            item.copyWith(
              isDownloading: false,
              downloadedId: downloadingRegion.id,
            ));
      });
    } on Exception catch (_) {
      setState(() {
        _items.removeAt(index);
        _items.insert(
            index,
            item.copyWith(
              isDownloading: false,
              downloadedId: null,
            ));
      });
      return;
    }
  }

  Future<void> _deleteRegion(OfflineRegionListItem item, int index) async {
    setState(() {
      _items.removeAt(index);
      _items.insert(index, item.copyWith(isDownloading: true));
    });

    await deleteOfflineRegion(
      item.downloadedId!,
    );

    setState(() {
      _items.removeAt(index);
      _items.insert(
          index,
          item.copyWith(
            isDownloading: false,
            downloadedId: null,
          ));
    });
  }

  _goToMap(OfflineRegionListItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OfflineRegionMap(item),
      ),
    );
  }
}
