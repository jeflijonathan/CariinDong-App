import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({Key? key}) : super(key: key);

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng _center = const LatLng(-6.2088, 106.8456);
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      return;
    }

    // 1. Ambil koordinat GPS
    Position position = await Geolocator.getCurrentPosition();

    // 2. Jika ini adalah loading awal (peta belum nge-render),
    // cukup update koordinatnya saja, biarkan 'initialCenter' di FlutterMap yang bekerja.
    if (_isLoading) {
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _isLoading =
            false; // FlutterMap akan mulai dirender dengan pusat koordinat baru
      });
    } else {
      // 3. Jika peta SUDAH dirender (misal tombol GPS ditekan ulang oleh user),
      // maka aman menggunakan mapController lewat post frame callback.
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_center, 15.0);
      });
    }
  }

  Future<void> _selectLocation() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih lokasi terlebih dahulu di peta')),
      );
      return;
    }

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );

      String address = '';
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        address = '${place.street}, ${place.subLocality}, ${place.locality}';
      }

      if (mounted) {
        Navigator.pop(context, {
          'address': address.isNotEmpty ? address : '${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}',
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context, {
          'address': '${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}',
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _selectLocation),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 15.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedLocation = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.cariindong_app',
                ),
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40.0,
                        height: 40.0,
                        point: _selectedLocation!,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40.0,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _determinePosition,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
