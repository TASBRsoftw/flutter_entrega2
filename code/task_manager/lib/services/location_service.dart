import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService instance = LocationService._init();
  LocationService._init();

  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('⚠️ Serviço de localização desabilitado');
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ Permissão de localização negada');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      print('❌ Permissão de localização negada permanentemente');
      return false;
    }
    return true;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print('❌ Erro ao obter localização: $e');
      return null;
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  String formatCoordinates(double lat, double lon) {
    return '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
  }

  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }

  Future<String?> getAddressFromCoordinates(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return '${p.street}, ${p.subLocality}, ${p.locality}, ${p.administrativeArea}';
      }
    } catch (e) {
      print('❌ Erro no geocoding: $e');
    }
    return null;
  }

  Future<Position?> getLocationFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        // Converter Location para Position
        return Position(
          latitude: loc.latitude,
          longitude: loc.longitude,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
      }
    } catch (e) {
      print('❌ Erro no reverse geocoding: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getCurrentLocationWithAddress() async {
    try {
      final pos = await getCurrentLocation();
      if (pos == null) return null;
      final address = await getAddressFromCoordinates(pos.latitude, pos.longitude);
      return {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'address': address,
      };
    } catch (e) {
      print('❌ Erro ao obter localização e endereço: $e');
      return null;
    }
  }
}
