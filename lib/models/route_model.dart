import 'package:latlong2/latlong.dart';

class RouteModel {
  final List<LatLng> points;
  final bool isStarted;

  const RouteModel({
    this.points = const [],
    this.isStarted = false,
  });

  RouteModel copyWith({
    List<LatLng>? points,
    bool? isStarted,
  }) {
    return RouteModel(
      points: points ?? this.points,
      isStarted: isStarted ?? this.isStarted,
    );
  }
}
