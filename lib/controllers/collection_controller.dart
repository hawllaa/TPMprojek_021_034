import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/collection_item_model.dart';

class CollectionController extends ChangeNotifier {
  List<CollectionItemModel> collectedList = [];
  bool isLoading = true;

  Future<void> loadCollections() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
        .from("collections")
        .select('''
          id,
          pc_id,
          pc_collections(
            id,
            name,
            price,
            currency,
            image_url
          )
        ''')
        .eq("user_id", user.id)
        .order("created_at", ascending: false);

      print("DATA = $data");
      print("JUMLAH = ${data.length}");

      collectedList = (data as List<dynamic>)
          .map((e) => CollectionItemModel.fromMap(
              Map<String, dynamic>.from(e)))
          .toList();

      print("COLLECTED LIST = $collectedList");
    } catch (e) {
      print("ERROR LOAD = $e");
    }

    isLoading = false;
    notifyListeners();
  }

    Future<void> deleteCollection(int id) async {
    try {
      print("DELETE ID = $id"); 
      await Supabase.instance.client
          .from("collections")
          .delete()
          .eq("id", id);

      print("DELETE BERHASIL");
      await loadCollections();
    } catch (e) {
      print("ERROR DELETE = $e"); 
    }
  }
}
