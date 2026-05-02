import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:photocard/main.dart' as main;
import 'package:latlong2/latlong.dart';
import '../../models/photocard_model.dart';

const colorPinkDark = Color(0xFFCF7486);

class HomeMapView extends StatelessWidget {
  final Position? currentPosition;
  final List<PhotocardModel> photocards;

  const HomeMapView({
    super.key,
    required this.currentPosition,
    required this.photocards,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: currentPosition == null
            ? Container(
                color: const Color.fromARGB(255, 255, 253, 254)
                    .withOpacity(0.8),
                child: const Center(
                  child: CircularProgressIndicator(color: main.colorPinkDark),
                ),
              )
            : FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                    currentPosition!.latitude,
                    currentPosition!.longitude,
                  ),
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.koleksikertas.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          currentPosition!.latitude,
                          currentPosition!.longitude,
                        ),
                        width: 45,
                        height: 45,
                        child: const Icon(
                          Icons.location_on,
                          color: main.colorPinkDark,
                          size: 42,
                        ),
                      ),

                      ...photocards.map((pc) {
                        return Marker(
                          point: LatLng(pc.lat, pc.lng),
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: main.colorPinkDark,
                              size: 24,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
