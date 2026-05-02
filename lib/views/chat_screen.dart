import 'package:flutter/material.dart';
import '../../controllers/chat_controller.dart';
import '../../models/chat_message_model.dart';
import 'widgets/chat_bottom_nav.dart';
import 'widgets/typing_dots.dart';

const Color colorPinkDark = Color(0xFFCF7486);

class ChatiePage extends StatefulWidget {
  const ChatiePage({super.key});

  @override
  State<ChatiePage> createState() => _ChatiePageState();
}

class _ChatiePageState extends State<ChatiePage> {
  final TextEditingController _chatController = TextEditingController();
  final ChatController _controller = ChatController();

  @override
  void initState() {
    super.initState();
    _controller.loadChats().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _chatController.text;
    _chatController.clear();
    await _controller.sendChat(text);
    if (mounted) setState(() {});
  }

  void _showDeleteOption(ChatMessageModel item) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined),
              title: const Text("Hapus semua chat"),
              onTap: () {
                Navigator.pop(context);
                _controller.deleteAllChats().then((_) {
                  if (mounted) setState(() {});
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text("Batal"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _controller.groupChats();
    final dateKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/bg_chatie.jpeg",
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 18),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Chatie",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFBE5E71),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: Color(0xFFCF7486), size: 28),
                        onSelected: (value) {
                          _controller.setZone(value);
                          setState(() {});
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: "WIB", child: Text("WIB")),
                          PopupMenuItem(
                              value: "WITA", child: Text("WITA")),
                          PopupMenuItem(
                              value: "WIT", child: Text("WIT")),
                          PopupMenuItem(
                              value: "GMT", child: Text("GMT")),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    reverse: true, 
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    itemCount:
                        dateKeys.length + (_controller.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_controller.isTyping &&
                          index == dateKeys.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: TypingDots(),
                        );
                      }

                      final dateKey = dateKeys[index];
                      final messages = grouped[dateKey]!;

                      final parts = dateKey.split("-");
                      final date = DateTime(
                        int.parse(parts[0]),
                        int.parse(parts[1]),
                        int.parse(parts[2]),
                      );

                      return Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withOpacity(0.7),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Text(
                                _controller.formatDateLabel(date),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6A4550),
                                ),
                              ),
                            ),
                          ),

                          ...messages.map((item) {
                            final time = _controller
                                .convertTime(item.createdAt);

                            return GestureDetector(
                              onLongPress: () =>
                                  _showDeleteOption(item),
                              child: Align(
                                alignment: item.isUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  constraints: const BoxConstraints(
                                      maxWidth: 250),
                                  margin: const EdgeInsets.only(
                                      bottom: 14),
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.isUser
                                        ? const Color(0xFFCF7486)
                                        : const Color(0xFFEFC0CB),
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: item.isUser
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.message,
                                        style: TextStyle(
                                          color: item.isUser
                                              ? Colors.white
                                              : const Color(
                                                  0xFF6A4550),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _controller
                                            .formatTime(time),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: item.isUser
                                              ? Colors.white70
                                              : Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: const Color(0xFFEFC0CB), width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            decoration: const InputDecoration(
                              hintText:
                                  "Tuliskan komentarmu disini...",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _handleSend,
                          child: Container(
                            width: 62,
                            height: 54,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE3A3B1),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: const Icon(Icons.send,
                                color: Color(0xFFFFE6ED)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ChatBottomNav(),
    );
  }
}
