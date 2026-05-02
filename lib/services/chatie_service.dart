import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatieService {
  static const List<String> apiKeys = [
    "AIzaSyD0CoD8bY2N2XUn30uRdzd_pKJSsjKaAu0", 
    // "AIzaSyCVPnZCY1x6FBF-dVC9nzwgNlU3dpRal7I",
    // "AIzaSyCZKeo20ysul6wzVr7H_8FKnYQHHiWkvXs",
    // "AIzaSyCJPTEdwZBAmzPYxZqw-T-50_nlTOX80xA",
    // "AIzaSyB2zA85-vvadh8uTs173Ikyykd2r-s9koo",
    // "AIzaSyDyg_JQ2xT-bt3PJI0gw372zEmhLNuWlOU",
  ];

  static const String model = "gemini-flash-latest"; 

  static Future<String> askAI(String message) async {
    for (String key in apiKeys) {
      try {
        debugPrint("COBA KEY: $key");
        final result = await _sendRequest(message, key);
        debugPrint("HASIL: $result");
        if (result != "__LIMIT__") return result;
      } catch (e, st) {
        debugPrint("ERROR KEY: $key\n$e\n$st");
        continue;
      }
    }
    return "Chatie sedang ramai sekarang 💗 Coba lagi nanti ya.";
  }

  static Future<String> _sendRequest(String message, String apiKey) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "Kamu adalah Chatie, AI ahli photocard Kpop Indonesia. "
                    "Fokus pada harga market, ori/fake, kondisi photocard, "
                    "tips koleksi, printilan album."
                    "Jawablah dengan asik, ramah, singkat, dan pastikan kalimatmu selesai." 
                    "PENTING: Gunakan teks biasa (plain text) saja. JANGAN PERNAH menggunakan format markdown seperti bintang (**) untuk menebalkan teks.\n\n"
                    "User: $message",
              },
            ],
          },
        ],
        "generationConfig": {"maxOutputTokens": 1000, "temperature": 0.6},
      }),
    );

    final data = jsonDecode(response.body);
    debugPrint("KEY USED: $apiKey");
    debugPrint("${response.statusCode}");
    debugPrint(response.body);

    if (response.statusCode == 200 &&
        data["candidates"] != null &&
        (data["candidates"] as List).isNotEmpty) {
      return data["candidates"][0]["content"]["parts"][0]["text"];
    }

    final bodyText = response.body.toLowerCase();
    if (response.statusCode == 429 ||
        response.statusCode == 503 ||
        bodyText.contains("quota") ||
        bodyText.contains("limit") ||
        bodyText.contains("resource_exhausted") ||
        bodyText.contains("rate") ||
        bodyText.contains("exceeded")) {
      return "__LIMIT__";
    }

    return "Chatie error sementara 💗";
  }
}
