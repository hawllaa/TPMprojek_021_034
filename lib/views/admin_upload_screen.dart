import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'map_picker_screen.dart'; 

const colorPinkDark = Color(0xFFCF7486);

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _longCtrl = TextEditingController();
  
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _upload() async {
    if (_imageFile == null || _nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mohon lengkapi foto, nama, dan harga!")));
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage
          .from('photocard_images')
          .upload(fileName, _imageFile!);
      final imageUrl = supabase.storage
          .from('photocard_images')
          .getPublicUrl(fileName);

      await supabase.from('pc_collections').insert({
        'name': _nameCtrl.text,
        'price': double.tryParse(_priceCtrl.text) ?? 0.0, 
        'currency': 'KRW', 
        'lat': double.tryParse(_latCtrl.text),
        'long': double.tryParse(_longCtrl.text),
        'image_url': imageUrl,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
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
        title: const Text("Tambah Photocard"),
        backgroundColor: Colors.transparent,
        foregroundColor: colorPinkDark,
        elevation: 0,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7), 
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 180,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.file(_imageFile!, fit: BoxFit.cover),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, size: 40, color: colorPinkDark),
                                    SizedBox(height: 8),
                                    Text("Upload Foto", style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
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
                    const SizedBox(height: 5),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.map, color: colorPinkDark),
                      label: const Text("Pilih Langsung dari Peta"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorPinkDark,
                        side: const BorderSide(color: colorPinkDark),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        backgroundColor: Colors.white.withOpacity(0.5),
                      ),
                      onPressed: () async {
                        final LatLng? pickedLocation = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MapPickerScreen()),
                        );

                        if (pickedLocation != null) {
                          setState(() {
                            _latCtrl.text = pickedLocation.latitude.toString();
                            _longCtrl.text = pickedLocation.longitude.toString();
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
                              onPressed: _upload,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorPinkDark,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                "Simpan Photocard",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
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