import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_model.dart';

class PhotocardController extends ChangeNotifier {
  String name = "";
  double price = 0;
  String originalCurrency = "KRW";
  String imageUrl = "";
  double? pcLat;
  double? pcLng;
  int? pcId;

  double? userLat;
  double? userLng;
  double? distance;

  String selectedCurrency = "IDR";
  String convertedPrice = "-";

  RouteModel route = const RouteModel();
  final MapController mapController = MapController();

  bool isLoading = true;
  bool alreadyCollected = false;

  StreamSubscription? _accelSub;
  double _lastX = 0, _lastY = 0, _lastZ = 0;
  DateTime _lastShake = DateTime.now();
  bool _isHandlingShake = false; 

  static const double collectRadius = 1000; 

  Future<void> initData(Map<String, dynamic> pcData) async {
    await _getUserLocation();

    name = pcData["name"] ?? "";
    price = _normalizePrice((pcData["price"] as num).toDouble());
    originalCurrency = pcData["currency"] ?? "KRW";
    pcLat = (pcData["lat"] as num?)?.toDouble();
    pcLng = (pcData["long"] as num?)?.toDouble();
    imageUrl = pcData["image_url"] ?? "";
    pcId = pcData["id"] is int
        ? pcData["id"] as int
        : int.tryParse(pcData["id"].toString().split('.').first);

    _calculateDistance();

    isLoading = false;
    notifyListeners();
  }

  void startShakeSensor(VoidCallback onShake) {
    _accelSub?.cancel();
    _isHandlingShake = false;
    _accelSub = accelerometerEventStream().listen((event) {
      if (!_isHandlingShake && _detectShake(event.x, event.y, event.z)) {
        _isHandlingShake = true;
        onShake();
      }
    });
  }

  bool _detectShake(double x, double y, double z) {
    double dx = (x - _lastX).abs();
    double dy = (y - _lastY).abs();
    double dz = (z - _lastZ).abs();

    _lastX = x;
    _lastY = y;
    _lastZ = z;

    final force = dx + dy + dz;

    if (force > 22) {
      final now = DateTime.now();
      if (now.difference(_lastShake).inMilliseconds > 1200) {
        _lastShake = now;
        return true;
      }
    }
    return false;
  }

  void cancelShakeSensor() {
    _accelSub?.cancel();
  }

  void resetShakeFlag() {
    _isHandlingShake = false;
  }

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    userLat = pos.latitude;
    userLng = pos.longitude;
  }

  void _calculateDistance() {
    if (userLat != null && userLng != null && pcLat != null && pcLng != null) {
      distance = Geolocator.distanceBetween(
        userLat!, userLng!, pcLat!, pcLng!,
      );
    }
  }

  Future<String?> getRoute() async {
    if (userLat == null || userLng == null || pcLat == null || pcLng == null) {
      return null;
    }

    final url =
        "https://router.project-osrm.org/route/v1/driving/"
        "$userLng,$userLat;$pcLng,$pcLat"
        "?overview=full&geometries=geojson";

    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    final coords = data["routes"][0]["geometry"]["coordinates"];
    final List<LatLng> points = (coords as List)
        .map<LatLng>((c) => LatLng(c[1], c[0]))
        .toList();

    route = RouteModel(points: points, isStarted: true);
    notifyListeners();

    mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(30),
      ),
    );

    return "Datangi lokasi lalu goyangkan HP untuk collect 💗";
  }

  Future<String?> tryCollectPhotocard() async {
    if (alreadyCollected) return "$name sudah ada di koleksimu 💗";
    if (!route.isStarted) return "Tekan 'Mulai cari' dulu ya! 💗";

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return "User tidak ditemukan, coba login ulang.";
    if (pcLat == null || pcLng == null) return "Data lokasi photocard tidak lengkap.";
    if (pcId == null) return "Data photocard tidak lengkap.";

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    final meter = Geolocator.distanceBetween(
      pos.latitude, pos.longitude, pcLat!, pcLng!,
    );

    if (meter > collectRadius) {
      return "Terlalu jauh (${meter.toStringAsFixed(0)} m)";
    }

    try {
      final existing = await Supabase.instance.client
          .from("collect_requests")
          .select("id, status")
          .eq("user_id", user.id)
          .eq("pc_id", pcId!)
          .maybeSingle();

      if (existing != null) {
        final status = existing['status'];
        if (status == 'pending') {
          return "Permintaan sudah dikirim, tunggu konfirmasi admin 💗";
        } else if (status == 'approved') {
          final inCollection = await Supabase.instance.client
              .from("collections")
              .select("id")
              .eq("user_id", user.id)
              .eq("pc_id", pcId!)
              .maybeSingle();

          if (inCollection != null) {
            alreadyCollected = true;
            notifyListeners();
            return "$name sudah ada di koleksimu 💗";
          }
          await Supabase.instance.client
              .from("collect_requests")
              .delete()
              .eq("user_id", user.id)
              .eq("pc_id", pcId!);
        } else if (status == 'rejected') {
          await Supabase.instance.client
              .from("collect_requests")
              .delete()
              .eq("user_id", user.id)
              .eq("pc_id", pcId!);
        }
      }

      await Supabase.instance.client.from("collect_requests").insert({
        "user_id": user.id,
        "pc_id": pcId,
        "pc_name": name,
        "status": "pending",
        "created_at": DateTime.now().toIso8601String(),
      });

      alreadyCollected = true;
      notifyListeners();
      return "Permintaan dikirim! Tunggu konfirmasi admin 💗";
    } catch (_) {
      return "Gagal mengirim permintaan, coba lagi.";
    }
  }

  void setSelectedCurrency(String currency) {
    selectedCurrency = currency;
    notifyListeners();
  }

  Future<void> convertPrice() async {
    try {
      final url =
          "https://api.frankfurter.app/latest"
          "?amount=$price"
          "&from=$originalCurrency"
          "&to=$selectedCurrency";

      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      final result =
          (data["rates"][selectedCurrency] as num).toDouble();

      convertedPrice = formatCurrency(result, selectedCurrency);
    } catch (_) {
      convertedPrice = "Error";
    }
    notifyListeners();
  }

  String formatCurrency(double value, String currency) {
    switch (currency) {
      case "IDR":
        return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
            .format(value);
      case "USD":
        return NumberFormat.currency(
            locale: 'en_US', symbol: '\$', decimalDigits: 2)
            .format(value);
      case "JPY":
        return NumberFormat.currency(
            locale: 'ja_JP', symbol: '¥', decimalDigits: 0)
            .format(value);
      case "KRW":
        return NumberFormat.currency(
            locale: 'ko_KR', symbol: '₩', decimalDigits: 0)
            .format(value);
      default:
        return value.toString();
    }
  }

  double _normalizePrice(double value) {
    return value >= 100 ? value * 1000 : value * 10000;
  }

  @override
  void dispose() {
    cancelShakeSensor();
    super.dispose();
  }
}