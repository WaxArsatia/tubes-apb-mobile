import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/models.dart';

class TransactionLocationPicker extends StatefulWidget {
  const TransactionLocationPicker({
    super.key,
    this.initialLocation,
    this.fallbackLocation = const TransactionLocation(
      latitude: -6.2,
      longitude: 106.816666,
      source: TransactionLocationSource.manual,
    ),
  });

  final TransactionLocation? initialLocation;
  final TransactionLocation fallbackLocation;

  @override
  State<TransactionLocationPicker> createState() =>
      _TransactionLocationPickerState();
}

class _TransactionLocationPickerState extends State<TransactionLocationPicker> {
  late LatLng selected = LatLng(
    (widget.initialLocation ?? widget.fallbackLocation).latitude,
    (widget.initialLocation ?? widget.fallbackLocation).longitude,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih lokasi'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              TransactionLocation(
                latitude: selected.latitude,
                longitude: selected.longitude,
                source: TransactionLocationSource.manual,
              ),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: selected,
          initialZoom: 16,
          onTap: (_, point) => setState(() => selected = point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.tubes_apb_mobile',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: selected,
                width: 48,
                height: 48,
                child: Icon(
                  Icons.location_pin,
                  color: scheme.primary,
                  size: 44,
                ),
              ),
            ],
          ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () => launchUrl(
                  Uri.parse('https://openstreetmap.org/copyright'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
