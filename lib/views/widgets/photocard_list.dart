import 'package:flutter/material.dart';
import 'package:photocard/main.dart' as main;
import '../../models/photocard_model.dart';
import 'photocard_item.dart';

class PhotocardList extends StatelessWidget {
  final bool isLoading;
  final List<PhotocardModel> photocards;

  const PhotocardList({
    super.key,
    required this.isLoading,
    required this.photocards,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: main.colorPinkDark),
      );
    }

    if (photocards.isEmpty) {
      return const Center(
        child: Text("Tidak ada koleksi ditemukan"),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: photocards.length,
      itemBuilder: (context, index) {
        return PhotocardItem(
          pc: photocards[index],
          index: index,
          allPhotocards: photocards,
        );
      },
    );
  }
}
