import 'package:flutter/material.dart';
import 'package:photocard/main.dart' as main;
import 'package:photocard/views/info_screen.dart';
import '../../controllers/home_controller.dart';
import 'widgets/home_bottom_nav.dart';
import 'widgets/home_map_view.dart';
import 'widgets/photocard_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController _controller = HomeController();

  @override
  void initState() {
    super.initState();
    _controller.initData();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    await _controller.handleLogout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const main.MyApp()),
        (route) => false,
      );
    }
  }

  TextStyle tx(double s, Color c, [FontWeight w = FontWeight.normal]) =>
      TextStyle(
          fontSize: s, color: c, fontWeight: w, fontFamily: 'sans-serif');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_home.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color.fromARGB(255, 255, 255, 255)),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 20, left: 30, right: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: main.colorPinkDark, size: 28),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Lokasi anda",
                                    style: tx(10,
                                        const Color.fromARGB(255, 255, 170, 211))),
                                Text(
                                  _controller.addressLabel,
                                  style:
                                      tx(12, main.colorPinkDark, FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.menu,
                              color: main.colorPinkDark),
                          onSelected: (value) {
                            if (value == "logout") {
                              _handleLogout();
                            } else if (value == "info") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const InfoPage()),
                              );
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: "info",
                              child: Row(children: [
                                Icon(Icons.info_outline,
                                    size: 18, color: Colors.black54),
                                SizedBox(width: 10),
                                Text("Info"),
                              ]),
                            ),
                            PopupMenuItem(
                              value: "logout",
                              child: Row(children: [
                                Icon(Icons.logout,
                                    size: 18, color: Colors.black54),
                                SizedBox(width: 10),
                                Text("Logout"),
                              ]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Selamat datang!",
                          hintStyle: tx(20, const Color.fromARGB(255, 215, 166, 177)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        ),
                      ),
                    ),
                  ),

                  HomeMapView(
                    currentPosition: _controller.currentPosition,
                    photocards: _controller.photocards,
                  ),

                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(30, 25, 30, 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Koleksi Terdekat",
                            style: tx(16, main.colorPinkDark, FontWeight.bold)),
                        Text("Lihat Semua >",
                            style: tx(12, const Color(0xFFE3A3B1))),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: 250,
                    child: PhotocardList(
                      isLoading: _controller.isLoading,
                      photocards: _controller.photocards,
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const HomeBottomNav(),
    );
  }
}
