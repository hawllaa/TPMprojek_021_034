import 'package:flutter/material.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F8),
      appBar: AppBar(
        title: const Text("Info Kelompok"),
        backgroundColor: const Color(0xFFE3A3B1),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: const AssetImage("assets/images/foto.jpeg"),
                backgroundColor: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Kelompok TPM - Koleksi Kertas",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFBE5E71),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Kesan & Pesan:",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Project ini memberikan pengalaman yang cukup kompleks dan realistis dalam membangun sebuah aplikasi mobile berbasis Flutter dari nol hingga menjadi aplikasi yang cukup lengkap.\n\n"
              "Untuk ke depannya, akan lebih baik jika alur pengerjaan tugas dibuat lebih bertahap dan terstruktur, sehingga setiap fitur bisa dipahami dan diimplementasikan secara lebih matang sebelum masuk ke fitur berikutnya. Dengan begitu, proses pembelajaran akan lebih optimal dan tidak terasa terlalu menumpuk di akhir.\n\n"
              "Secara keseluruhan, proyek ini sangat bermanfaat karena memberikan gambaran nyata tentang pengembangan aplikasi.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              "Anggota Kelompok:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _member("Hawla Khufyatul Qolbu", "NIM 123230021"),
            _member("Riska Salsabila La Jia", "NIM 123230034"),
          ],
        ),
      ),
    );
  }

  static Widget _member(String name, String nim) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Text(nim, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}