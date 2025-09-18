import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng initialLocation;
  final String title;
  const MapPickerPage({Key? key, required this.initialLocation, required this.title}) : super(key: key);

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng? selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.initialLocation,
          zoom: 15,
        ),
        onTap: (LatLng position) {
          setState(() {
            selectedLocation = position;
          });
        },
        markers: selectedLocation != null
            ? {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: selectedLocation!,
                ),
              }
            : {},
      ),
      floatingActionButton: selectedLocation != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context, selectedLocation);
              },
              label: const Text('Confirmar ubicación'),
              icon: const Icon(Icons.check),
            )
          : null,
    );
  }
}