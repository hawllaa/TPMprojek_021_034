import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/chat_message_model.dart';
import '../services/chatie_service.dart';

class ChatController extends ChangeNotifier {
  List<ChatMessageModel> chats = [];
  bool isTyping = false;
  String selectedZone = "WIB";

  Future<void> loadChats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = await Supabase.instance.client
        .from('chats')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: true);

    chats = (data as List<dynamic>)
        .map((e) => ChatMessageModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    notifyListeners();
  }

  Future<void> sendChat(String userText) async {
    if (userText.trim().isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client.from('chats').insert({
      "user_id": user.id,
      "message": userText,
      "is_user": true,
      "created_at": DateTime.now().toUtc().toIso8601String(),
    });

    await loadChats();

    isTyping = true;
    notifyListeners();

    final reply = await ChatieService.askAI(userText);

    isTyping = false;
    notifyListeners();

    await Supabase.instance.client.from('chats').insert({
      "user_id": user.id,
      "message": reply,
      "is_user": false,
      "created_at": DateTime.now().toUtc().toIso8601String(),
    });

    await loadChats();
  }

  Future<void> deleteSingleChat(int id) async {
    await Supabase.instance.client
        .from('chats')
        .delete()
        .eq('id', id);
    await loadChats();
  }

  Future<void> deleteAllChats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client
        .from('chats')
        .delete()
        .eq('user_id', user.id);

    await loadChats();
  }

  void setZone(String zone) {
    selectedZone = zone;
    notifyListeners();
  }

  tz.Location getLocation() {
    switch (selectedZone) {
      case "WITA":
        return tz.getLocation("Asia/Makassar");
      case "WIT":
        return tz.getLocation("Asia/Jayapura");
      case "GMT":
        return tz.getLocation("UTC");
      default:
        return tz.getLocation("Asia/Jakarta");
    }
  }

  DateTime convertTime(String raw) {
    final utc = DateTime.parse(raw).toUtc();
    return tz.TZDateTime.from(utc, getLocation());
  }

  Map<String, List<ChatMessageModel>> groupChats() {
    final Map<String, List<ChatMessageModel>> grouped = {};
    final loc = getLocation();

    for (var chat in chats) {
      final utc = DateTime.parse(chat.createdAt).toUtc();
      final local = tz.TZDateTime.from(utc, loc);
      final key = "${local.year}-${local.month}-${local.day}";

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(chat);
    }

    return grouped;
  }

  String formatDateLabel(DateTime date) {
    final loc = getLocation();
    final now = tz.TZDateTime.from(DateTime.now().toUtc(), loc);

    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";
    return "${date.day}/${date.month}/${date.year}";
  }

  String formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}
