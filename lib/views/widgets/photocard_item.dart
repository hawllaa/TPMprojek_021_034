import 'package:flutter/material.dart';
import 'package:photocard/main.dart' as main;
import 'package:photocard/views/photocard_screen.dart';
import '../../models/photocard_model.dart';

class PhotocardItem extends StatelessWidget {
  final PhotocardModel pc;
  final int index;
  final List<PhotocardModel> allPhotocards;

  const PhotocardItem({
    super.key,
    required this.pc,
    required this.index,
    required this.allPhotocards,
  });

  TextStyle _tx(double s, Color c, [FontWeight w = FontWeight.normal]) =>
      TextStyle(fontSize: s, color: c, fontWeight: w, fontFamily: 'sans-serif');

  @override
  Widget build(BuildContext context) {
    final bool isSoldOut = pc.isCollected;

    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 245, 243, 243),
                        borderRadius: BorderRadius.circular(10),
                        image: pc.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(pc.imageUrl),
                                fit: BoxFit.cover,
                                colorFilter: isSoldOut
                                    ? const ColorFilter.matrix([
                                        0.2126, 0.7152, 0.0722, 0, 0,
                                        0.2126, 0.7152, 0.0722, 0, 0,
                                        0.2126, 0.7152, 0.0722, 0, 0,
                                        0,      0,      0,      1, 0,
                                      ])
                                    : null,
                              )
                            : null,
                      ),
                      child: pc.imageUrl.isEmpty
                          ? const Center(
                              child: Icon(Icons.image_outlined,
                                  color: Colors.grey))
                          : null,
                    ),
                    if (!isSoldOut)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: main.colorPinkDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${pc.distance ?? '0'} km",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pc.name,
                      style: _tx(
                        12,
                        isSoldOut ? Colors.grey : main.colorTextDark,
                        FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pc.priceWithCurrency,
                          style: _tx(
                            11,
                            isSoldOut ? Colors.grey : main.colorPinkDark,
                            FontWeight.bold,
                          ),
                        ),
                        if (!isSoldOut)
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PhotocardPage(
                                    pcData: {
                                      'id': allPhotocards[index].id,
                                      'name': pc.name,
                                      'image_url': pc.imageUrl,
                                      'price': pc.price,
                                      'lat': pc.lat,
                                      'long': pc.lng,
                                    },
                                  ),
                                ),
                              );
                            },
                            child: const Icon(Icons.add_circle,
                                color: main.colorPinkDark, size: 22),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (isSoldOut)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "SOLD OUT",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
  }
}
