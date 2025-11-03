import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final Function(double lat, double lon, String? address) onLocationSelected;

  const LocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    required this.onLocationSelected,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _addressController = TextEditingController();
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;
  String? _address;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    _addressController.text = widget.initialAddress ?? '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    final result = await LocationService.instance.getCurrentLocationWithAddress();
    if (result != null) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _address = result['address'];
        _addressController.text = _address ?? '';
      });
      widget.onLocationSelected(_latitude!, _longitude!, _address);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _searchAddress() async {
    if (_addressController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final pos = await LocationService.instance.getLocationFromAddress(_addressController.text.trim());
    if (pos != null) {
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _address = _addressController.text.trim();
      });
      widget.onLocationSelected(_latitude!, _longitude!, _address);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Endereço',
              hintText: 'Digite o endereço',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.location_searching),
                  label: const Text('Usar localização atual'),
                  onPressed: _isLoading ? null : _getCurrentLocation,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar endereço'),
                  onPressed: _isLoading ? null : _searchAddress,
                ),
              ),
            ],
          ),
          if (_latitude != null && _longitude != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text('Coordenadas: ${LocationService.instance.formatCoordinates(_latitude!, _longitude!)}'),
            ),
        ],
      ),
    );
  }
}
