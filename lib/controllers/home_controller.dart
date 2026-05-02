import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/photocard_model.dart';

class HomeController extends ChangeNotifier {
  Position? _currentPosition;
  List<PhotocardModel> _photocards = [];
  bool _isLoading = true;
  String _addressLabel = "Mencari lokasi...";

  Position? get currentPosition => _currentPosition;
  List<PhotocardModel> get photocards => _photocards;
  bool get isLoading => _isLoading;
  String get addressLabel => _addressLabel;

  double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> initData() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position? position;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 15),
          );

          _currentPosition = position;

          _addressLabel =
              "${position.latitude.toStringAsFixed(4)}, "
              "${position.longitude.toStringAsFixed(4)}";
        } catch (e) {
          debugPrint("ERROR LOCATION: $e");
        }
      }

      final data = await Supabase.instance.client
          .from('pc_collections')
          .select();

      List<PhotocardModel> cards = (data as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['lat'] != null && e['long'] != null)
          .map((e) => PhotocardModel.fromMap(e))
          .toList();

      if (position != null) {
        cards = cards.map((card) {
          final dist = calculateDistance(
            position!.latitude,
            position.longitude,
            card.lat,
            card.lng,
          );
          return card.copyWith(
            distanceVal: dist,
            distance: dist.toStringAsFixed(1),
          );
        }).toList();

        cards.sort((a, b) =>
            (a.distanceVal ?? 0).compareTo(b.distanceVal ?? 0));
      }

      _photocards = cards.take(3).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("ERROR INITDATA: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await Supabase.instance.client.auth.signOut();
  }
}
