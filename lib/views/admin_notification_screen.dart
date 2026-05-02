import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color colorPinkDark = Color(0xFFCF7486);

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;
  Map<String, dynamic>? _activeRequest;
  bool _isProcessing = false;

  StreamSubscription? _accelSub;
  double _lastX = 0, _lastY = 0, _lastZ = 0;
  DateTime _lastShake = DateTime.now();

  late AnimationController _shakeAnimController;
  late Animation<double> _shakeAnim;

  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();

    _shakeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _shakeAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _shakeAnimController, curve: Curves.elasticIn),
    );

    _loadPendingRequests();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _realtimeChannel?.unsubscribe();
    _shakeAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('collect_requests')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      setState(() {
        _pendingRequests = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error load requests: $e");
      setState(() => _isLoading = false);
    }
  }

  void _subscribeRealtime() {
    _realtimeChannel = supabase
        .channel('admin_collect_requests')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'collect_requests',
          callback: (payload) {
            final newReq =
                Map<String, dynamic>.from(payload.newRecord);
            if (newReq['status'] == 'pending') {
              setState(() => _pendingRequests.insert(0, newReq));
              _showNewRequestDialog(newReq);
            }
          },
        )
        .subscribe();
  }

  void _showNewRequestDialog(Map<String, dynamic> req) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.notifications_active, color: colorPinkDark),
            SizedBox(width: 8),
            Text("Request Baru!", style: TextStyle(color: colorPinkDark)),
          ],
        ),
        content: Text(
          "User ingin mengambil photocard:\n\"${req['pc_name'] ?? 'Unknown'}\"\n\nKetuk tombol di bawah untuk meninjau.",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Nanti", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorPinkDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _openShakeConfirmation(req);
            },
            child: const Text("Tinjau Sekarang",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openShakeConfirmation(Map<String, dynamic> req) {
    setState(() => _activeRequest = req);
    _startShakeSensor();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text("Konfirmasi Collect",
                style: TextStyle(
                    color: colorPinkDark, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Photocard: \"${req['pc_name'] ?? 'Unknown'}\"",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(_shakeAnim.value, 0),
                    child: child,
                  ),
                  child: const Icon(Icons.phone_android,
                      size: 60, color: colorPinkDark),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Goyangkan HP untuk\nmenyetujui permintaan ini 💗",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                if (_isProcessing) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(color: colorPinkDark),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: _isProcessing
                    ? null
                    : () {
                        _stopShakeSensor();
                        setState(() => _activeRequest = null);
                        Navigator.pop(ctx);
                      },
                child: const Text("Tolak",
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      _stopShakeSensor();
      setState(() => _activeRequest = null);
    });
  }

  void _startShakeSensor() {
    _accelSub?.cancel();
    _accelSub = accelerometerEventStream().listen((event) {
      if (_detectShake(event.x, event.y, event.z) && _activeRequest != null) {
        _approveRequest(_activeRequest!);
      }
    });
  }

  void _stopShakeSensor() {
    _accelSub?.cancel();
    _accelSub = null;
  }

  bool _detectShake(double x, double y, double z) {
    double dx = (x - _lastX).abs();
    double dy = (y - _lastY).abs();
    double dz = (z - _lastZ).abs();
    _lastX = x;
    _lastY = y;
    _lastZ = z;

    final force = dx + dy + dz;
    if (force > 22) {
      final now = DateTime.now();
      if (now.difference(_lastShake).inMilliseconds > 1200) {
        _lastShake = now;
        return true;
      }
    }
    return false;
  }

  Future<void> _approveRequest(Map<String, dynamic> req) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    _stopShakeSensor();

    try {
      final requestId = req['id'];
      final userId = req['user_id'];
      final pcId = req['pc_id'];
      final pcName = req['pc_name'] ?? 'Photocard';

      await supabase
          .from('collect_requests')
          .update({'status': 'approved'})
          .eq('id', requestId);

      await supabase.from('collections').insert({
        'user_id': userId,
        'pc_id': pcId,
        'created_at': DateTime.now().toIso8601String(),
      });

      await supabase
          .from('pc_collections')
          .update({'is_collected': true})
          .eq('id', pcId);

      await supabase.from('notifications').insert({
        'target_user_id': userId,
        'title': 'Yeay, Photocard Berhasil! 💗',
        'message':
            'Admin telah menyetujui permintaanmu. "$pcName" sekarang ada di koleksimu!',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _pendingRequests.removeWhere((r) => r['id'] == requestId);
        _activeRequest = null;
        _isProcessing = false;
      });

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("\"$pcName\" berhasil di-approve! 💗"),
            backgroundColor: colorPinkDark,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error approve: $e");
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal approve: $e")),
        );
      }
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> req) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tolak Request?"),
        content: Text(
            "Yakin ingin menolak permintaan \"${req['pc_name']}\"?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Tolak",
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase
          .from('collect_requests')
          .update({'status': 'rejected'})
          .eq('id', req['id']);

      await supabase.from('notifications').insert({
        'target_user_id': req['user_id'],
        'title': 'Permintaan Ditolak',
        'message':
            'Maaf, permintaan collect "${req['pc_name']}" tidak dapat disetujui saat ini.',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() =>
          _pendingRequests.removeWhere((r) => r['id'] == req['id']));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request ditolak.")),
        );
      }
    } catch (e) {
      debugPrint("Error reject: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF4F6),
      appBar: AppBar(
        title: const Text("Notifikasi Admin",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: colorPinkDark,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingRequests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: colorPinkDark))
          : _pendingRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        "Semua Beres!",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Tidak ada permintaan collect yang menunggu.",
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorPinkDark.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: colorPinkDark.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: colorPinkDark, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${_pendingRequests.length} permintaan menunggu konfirmasi",
                              style: const TextStyle(
                                  color: colorPinkDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingRequests.length,
                        itemBuilder: (context, index) {
                          final req = _pendingRequests[index];
                          final createdAt = req['created_at'] != null
                              ? DateTime.tryParse(
                                      req['created_at'].toString())
                                  ?.toLocal()
                              : null;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          colorPinkDark.withOpacity(0.15),
                                      child: const Icon(
                                          Icons.person_outline,
                                          color: colorPinkDark),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            req['pc_name'] ?? 'Unknown PC',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "User ID: ${(req['user_id'] ?? '').toString().substring(0, 8)}...",
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        "Pending",
                                        style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                if (createdAt != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    "Dikirim: ${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}",
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.close,
                                            size: 16),
                                        label: const Text("Tolak"),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.redAccent,
                                          side: const BorderSide(
                                              color: Colors.redAccent),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                        onPressed: () =>
                                            _rejectRequest(req),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(
                                            Icons.phone_android,
                                            size: 16),
                                        label: const Text("Shake Approve"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorPinkDark,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                        onPressed: () =>
                                            _openShakeConfirmation(req),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
