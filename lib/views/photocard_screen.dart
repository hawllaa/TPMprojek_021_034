import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../main.dart' as main;
import '../controllers/photocard_controller.dart';

class PhotocardPage extends StatefulWidget {
  final Map<String, dynamic> pcData;

  const PhotocardPage({super.key, required this.pcData});

  @override
  State<PhotocardPage> createState() => _PhotocardPageState();
}

class _PhotocardPageState extends State<PhotocardPage> {
  final double figmaWidth = 402;
  final double figmaHeight = 874;
  late double scaleW;
  late double scaleH;

  final PhotocardController _controller = PhotocardController();

  @override
  void initState() {
    super.initState();
    _controller.initData(widget.pcData).then((_) {
      if (mounted) {
        setState(() {});
        _controller.startShakeSensor(_onShake);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onShake() async {
    final msg = await _controller.tryCollectPhotocard();
    _controller.resetShakeFlag();

    if (msg != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 3),
        ));
      setState(() {});
    }
  }

  Future<void> _handleGetRoute() async {
    final msg = await _controller.getRoute();
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
      setState(() {});
    }
  }

  Future<void> _handleConvert() async {
    await _controller.convertPrice();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    scaleW = screen.width / figmaWidth;
    scaleH = screen.height / figmaHeight;

    if (_controller.isLoading || _controller.pcLat == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.white)),

          Positioned(
            left: 30 * scaleW,
            top: 0,
            width: 343 * scaleW,
            height: 801 * scaleH,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: main.colorPinkDark, width: 1.5),
              ),
            ),
          ),

          Positioned(
            left: 50 * scaleW,
            top: 100 * scaleH,
            width: 300 * scaleW,
            height: 420 * scaleH,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: FlutterMap(
                mapController: _controller.mapController,
                options: MapOptions(
                  initialCenter:
                      LatLng(_controller.pcLat!, _controller.pcLng!),
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: "com.koleksikertas.app",
                  ),
                  MarkerLayer(
                    markers: [
                      if (_controller.userLat != null)
                        Marker(
                          point: LatLng(
                              _controller.userLat!, _controller.userLng!),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.my_location,
                              color: Color.fromARGB(255, 163, 214, 255)),
                        ),
                      Marker(
                        point:
                            LatLng(_controller.pcLat!, _controller.pcLng!),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on,
                            color: Color.fromARGB(255, 240, 120, 160)),
                      ),
                    ],
                  ),
                  if (_controller.route.points.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _controller.route.points,
                          strokeWidth: 5,
                          color: main.colorPinkDark,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 40 * scaleW,
            top: 50 * scaleH,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_ios_new,
                      color: main.colorPinkDark, size: 20 * scaleW),
                ),
                Text(
                  "Detail Photocard",
                  style: TextStyle(
                    fontSize: 20 * scaleW,
                    fontWeight: FontWeight.w600,
                    color: main.colorPinkDark,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 50 * scaleW,
            top: 570 * scaleH,
            width: 161 * scaleW,
            height: 190 * scaleH,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEF),
                borderRadius: BorderRadius.circular(10),
                image: _controller.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_controller.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
          ),

          Positioned(
            left: 229 * scaleW,
            top: 576 * scaleH,
            child: SizedBox(
              width: 120 * scaleW,
              child: Text(
                _controller.name,
                maxLines: 3,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12 * scaleW,
                  color: const Color.fromARGB(255, 172, 81, 117),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Positioned(
            left: 229 * scaleW,
            top: 616 * scaleH,
            child: Text(
              "Harga: ${_controller.formatCurrency(_controller.price, _controller.originalCurrency)}",
              style: TextStyle(
                fontSize: 12 * scaleW,
                color: const Color.fromARGB(255, 172, 81, 117),
              ),
            ),
          ),

          Positioned(
            left: 230 * scaleW,
            top: 640 * scaleH,
            width: 120 * scaleW,
            height: 120 * scaleH,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text("Konversi",
                      style: TextStyle(fontSize: 14 * scaleW)),
                  DropdownButton<String>(
                    value: _controller.selectedCurrency,
                    isDense: true,
                    items: ["IDR", "USD", "JPY"]
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        _controller.setSelectedCurrency(val);
                        setState(() {});
                      }
                    },
                  ),
                  Text(_controller.convertedPrice),
                ],
              ),
            ),
          ),

          Positioned(
            left: 69 * scaleW,
            top: 722 * scaleH,
            child: GestureDetector(
              onTap: _handleGetRoute,
              child: Container(
                width: 121 * scaleW,
                height: 22 * scaleH,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: main.colorPinkDark,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text("Mulai cari",
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
          ),

          Positioned(
            left: 238 * scaleW,
            top: 720 * scaleH,
            child: GestureDetector(
              onTap: _handleConvert,
              child: Container(
                width: 104 * scaleW,
                height: 22 * scaleH,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: main.colorPinkDark,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text("Ubah",
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
