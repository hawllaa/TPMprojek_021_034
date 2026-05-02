import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_notification_screen.dart'; 
import 'admin_edit_screen.dart';

const colorPinkDark = Color(0xFFCF7486);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final supabase = Supabase.instance.client;

  String _sortBy = 'created_at';
  bool _isAscending = false;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Dashboard Admin",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: colorPinkDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Notifikasi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminNotificationScreen(),
                ),
              );
            },
          ),
          
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_home.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFFFFE6ED)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase(); 
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Cari nama photocard...",
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                          prefixIcon: const Icon(Icons.search, color: colorPinkDark),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: colorPinkDark, size: 20),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sort, color: colorPinkDark, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _sortBy,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: colorPinkDark),
                                  style: const TextStyle(
                                    color: colorPinkDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'created_at', child: Text('Waktu Upload')),
                                    DropdownMenuItem(value: 'price', child: Text('Harga (KRW)')),
                                    DropdownMenuItem(value: 'name', child: Text('Nama Photocard')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _sortBy = value);
                                    }
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                color: colorPinkDark,
                              ),
                              tooltip: _isAscending ? 'Ascending' : 'Descending',
                              onPressed: () {
                                setState(() => _isAscending = !_isAscending);
                              },
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: StreamBuilder(
                    stream: supabase
                        .from('pc_collections')
                        .stream(primaryKey: ['id'])
                        .order(_sortBy, ascending: _isAscending),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: colorPinkDark));
                      }

                      final data = snapshot.data!;

                      final filteredData = data.where((item) {
                        final namaPC = (item['name'] ?? '').toString().toLowerCase();
                        return namaPC.contains(_searchQuery);
                      }).toList();

                      if (filteredData.isEmpty) {
                        return Center(
                          child: Text(
                            _searchQuery.isEmpty 
                                ? "Belum ada koleksi photocard." 
                                : "Photocard tidak ditemukan.",
                            style: const TextStyle(color: Colors.black54),
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 0.75,
                        ),
                        
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          final item = filteredData[index];
                          final imageUrl = item['image_url'];

                          final bool isSoldOut = item['is_collected'] == true;

                        return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminEditScreen(item: item),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                          child: imageUrl != null && imageUrl.toString().startsWith('http')
                                              ? ColorFiltered(
                                                  colorFilter: isSoldOut
                                                      ? const ColorFilter.matrix([
                                                          0.2126, 0.7152, 0.0722, 0, 0,
                                                          0.2126, 0.7152, 0.0722, 0, 0,
                                                          0.2126, 0.7152, 0.0722, 0, 0,
                                                          0,      0,      0,      1, 0,
                                                        ])
                                                      : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                                  child: Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover),
                                                )
                                              : Container(
                                                  width: double.infinity,
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                                ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['name'] ?? 'Tanpa Nama',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: isSoldOut ? Colors.grey : Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              isSoldOut ? "Sold Out" : "${item['price']} KRW",
                                              style: TextStyle(
                                                  color: isSoldOut ? Colors.grey : colorPinkDark,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSoldOut)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.35),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            "SOLD OUT",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colorPinkDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Tambah PC"),
        onPressed: () => Navigator.pushNamed(context, '/admin_upload'),
      ),
      
    );
  }
}