import 'package:flutter/material.dart';
import 'package:photocard/main.dart' as main;
import '../../controllers/collection_controller.dart';
import '../../models/collection_item_model.dart';
import 'widgets/collection_bottom_nav.dart';

class CollectPhotocardPage extends StatefulWidget {
  const CollectPhotocardPage({super.key});

  @override
  State<CollectPhotocardPage> createState() => _CollectPhotocardPageState();
}

class _CollectPhotocardPageState extends State<CollectPhotocardPage> {
  final CollectionController _controller = CollectionController();

  @override
  void initState() {
    super.initState();
    _controller.loadCollections().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDelete(int id) async {
    await _controller.deleteCollection(id);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Photocard dihapus.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F8),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: main.colorPinkDark),
        title: Text(
          "My Collection",
          style: TextStyle(
            color: main.colorPinkDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _controller.collectedList.isEmpty
              ? Center(
                  child: Text(
                    "Belum ada photocard 💗",
                    style: TextStyle(
                        color: main.colorPinkDark, fontSize: 16),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _controller.collectedList.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder: (context, index) {
                    final item = _controller.collectedList[index];
                    return _CollectionCard(
                      item: item,
                      onDelete: () => _handleDelete(item.id),
                    );
                  },
                ),

      bottomNavigationBar: const CollectionBottomNav(),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final CollectionItemModel item;
  final VoidCallback onDelete;

  const _CollectionCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(blurRadius: 8, color: Colors.black12, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: const Color(0xFFFFE4EA),
                      child: Icon(Icons.image,
                          color: main.colorPinkDark, size: 40),
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: main.colorPinkDark,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(item.formattedPrice,
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: main.colorPinkDark,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onDelete,
                    child: const Text("Hapus",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
