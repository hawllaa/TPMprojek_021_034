import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'map_picker_screen.dart';

const colorPinkDark = Color(0xFFCF7486);

class AdminEditScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const AdminEditScreen({super.key, required this.item});

  @override
  State<AdminEditScreen> createState() => _AdminEditScreenState();
}

class _AdminEditScreenState extends State<AdminEditScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _longCtrl;
  
  File? _newImageFile; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item['name']?.toString() ?? '');
    _priceCtrl = TextEditingController(text: widget.item['price']?.toString() ?? '');
    _latCtrl = TextEditingController(text: widget.item['lat']?.toString() ?? '');
    _longCtrl = TextEditingController(text: widget.item['long']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _latCtrl.dispose();
    _longCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _newImageFile = File(pickedFile.path));
  }

  Future<void> _updateData() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nama dan Harga tidak boleh kosong!")));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;
      String? finalImageUrl = widget.item['image_url'];

      if (_newImageFile != null) {
        final fileName = 'pc_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('photocard_images').upload(fileName, _newImageFile!);
        final rawUrl = supabase.storage.from('photocard_images').getPublicUrl(fileName);
        finalImageUrl = Uri.encodeFull(rawUrl);
      }

      final response = await supabase
          .from('pc_collections')
          .update({
            'name': _nameCtrl.text,
            'price': double.tryParse(_priceCtrl.text) ?? 0.0,
            'lat': double.tryParse(_latCtrl.text),
            'long': double.tryParse(_longCtrl.text),
            'image_url': finalImageUrl, 
          })
          .eq('id', widget.item['id'])
          .select();

      if (response.isEmpty) throw "Gagal update database. Cek RLS Policy UPDATE.";

      if (_newImageFile != null && widget.item['image_url'] != null) {
        final String oldUrl = widget.item['image_url'];
        if (oldUrl.startsWith('http')) {
          try {
            final oldFileName = oldUrl.split('/').last.split('?').first;
            await supabase.storage.from('photocard_images').remove([oldFileName]);
          } catch (e) {
            debugPrint("Abaikan: Gagal hapus file lama di storage.");
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Koleksi Berhasil Diperbarui!")));
        Navigator.pop(context, true); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal Update: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteData() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Photocard?"),
        content: const Text("Tindakan ini akan menghapus data permanen dari database dan storage."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Hapus", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      await supabase.from('pc_collections').delete().eq('id', widget.item['id']);

      if (widget.item['image_url'] != null) {
        final String imageUrl = widget.item['image_url'];
        if (imageUrl.startsWith('http')) {
          final fileName = imageUrl.split('/').last.split('?').first;
          await supabase.storage.from('photocard_images').remove([fileName]);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Berhasil menghapus photocard!")));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error Hapus: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: colorPinkDark, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Edit Photocard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: colorPinkDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 28),
            onPressed: _isLoading ? null : _deleteData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/bg_home.png', fit: BoxFit.cover)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              height: 180, width: 150,
                              decoration: BoxDecoration(
                                color: Colors.white, 
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)]
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Builder(
                                  builder: (context) {
                                    if (_newImageFile != null) {
                                      return Image.file(_newImageFile!, fit: BoxFit.cover);
                                    }
 
                                    final String? imageUrl = widget.item['image_url']?.toString();
                                    final bool isLinkValid = imageUrl != null && imageUrl.trim().isNotEmpty && imageUrl.startsWith('http');

                                    if (isLinkValid) {
                                      return Image.network(
                                        imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => 
                                            const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                      );
                                    }

                                    return const Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey);
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: CircleAvatar(
                                backgroundColor: colorPinkDark,
                                radius: 18,
                                child: const Icon(Icons.edit, color: Colors.white, size: 18),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField("Nama Photocard", _nameCtrl),
                    _buildTextField("Harga (Dalam KRW)", _priceCtrl, isNumber: true),
                    Row(
                      children: [
                        Expanded(child: _buildTextField("Latitude", _latCtrl, isNumber: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField("Longitude", _longCtrl, isNumber: true)),
                      ],
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.map, color: colorPinkDark),
                      label: const Text("Pilih Dari Peta"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorPinkDark,
                        side: const BorderSide(color: colorPinkDark),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () async {
                        final picked = await Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPickerScreen()));
                        if (picked != null) {
                          setState(() {
                            _latCtrl.text = picked.latitude.toString();
                            _longCtrl.text = picked.longitude.toString();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: colorPinkDark))
                        : SizedBox(
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _updateData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorPinkDark,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text("Simpan Perubahan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}