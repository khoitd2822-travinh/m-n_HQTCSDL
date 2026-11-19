import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SmartDroneCustomerApp());
}

class SmartDroneCustomerApp extends StatelessWidget {
  const SmartDroneCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartDrone Customer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0EA5E9),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1220),
      ),
      home: const LoginScreen(),
    );
  }
}

class ApiConfig {
  // Dùng localhost:5139 khi chạy Chrome/Desktop; đổi thành 10.0.2.2:5139 nếu chạy Android Emulator
  static const String backendBaseUrl = 'http://localhost:5139';
  static const String aiBaseUrl = 'http://localhost:8000';
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController(text: 'admin');
  final _passCtrl = TextEditingController(text: '123');
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.backendBaseUrl}/api/Auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _userCtrl.text.trim(),
          'password': _passCtrl.text.trim(),
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = (data['token'] ?? data['accessToken'] ?? '').toString();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              username: _userCtrl.text.trim(),
              token: token,
            ),
          ),
        );
      } else {
        setState(() => _error = 'Đăng nhập thất bại (${res.statusCode}): kiểm tra tài khoản/mật khẩu.');
      }
    } catch (e) {
      setState(() => _error = 'Không kết nối được Backend (${ApiConfig.backendBaseUrl}): $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            color: const Color(0xFF111C33),
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flight_takeoff, size: 48, color: Color(0xFF38BDF8)),
                  const SizedBox(height: 12),
                  const Text(
                    'SmartDrone Customer',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tài khoản',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Đăng nhập'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String username;
  final String token;

  const HomeScreen({super.key, required this.username, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (widget.token.isNotEmpty) 'Authorization': 'Bearer ${widget.token}',
      };

  // Tab 1: Danh sách đơn hàng
  List<dynamic> _orders = [];
  bool _loadingOrders = false;
  String _orderStatusMsg = '';

  // Tab 2: Ước lượng ETA AI
  final _distanceCtrl = TextEditingController(text: '3.5');
  final _weightCtrl = TextEditingController(text: '1.2');
  String _etaResult = 'Nhập thông số và bấm ước lượng thời gian giao.';

  // Tab 3: Chatbot AI
  final _chatCtrl = TextEditingController(text: 'Đơn hàng của tôi bao lâu tới nơi?');
  String _chatReply = 'Xin chào! Tôi là trợ lý giao hàng SmartDrone.';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _loadingOrders = true;
      _orderStatusMsg = '';
    });

    // Thử lần lượt các endpoint đơn hàng phổ biến trong backend
    final candidatePaths = ['/api/Orders', '/api/SmartDroneOrder'];
    for (final path in candidatePaths) {
      try {
        final res = await http.get(
          Uri.parse('${ApiConfig.backendBaseUrl}$path'),
          headers: _authHeaders,
        );
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          setState(() {
            _orders = decoded is List ? decoded : (decoded['items'] ?? decoded['data'] ?? []);
            _loadingOrders = false;
          });
          return;
        }
      } catch (_) {}
    }

    setState(() {
      _loadingOrders = false;
      _orderStatusMsg = 'Chưa tải được danh sách đơn (kiểm tra route /api/Orders hoặc CORS trên backend).';
    });
  }

  Future<void> _estimateEta() async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.aiBaseUrl}/ai/eta'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'distance_km': double.tryParse(_distanceCtrl.text) ?? 3.0,
          'package_weight_kg': double.tryParse(_weightCtrl.text) ?? 1.0,
          'drone_battery_pct': 85,
          'weather_delay_min': 0,
          'station_delay_min': 2,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _etaResult = 'Thời gian dự kiến: ${data['estimated_minutes']} phút\n'
              'Tốc độ ước tính: ${data['estimated_speed_kmh'] ?? 45} km/h';
        });
      } else {
        setState(() => _etaResult = 'Lỗi AI Service (${res.statusCode})');
      }
    } catch (e) {
      setState(() => _etaResult = 'Không gọi được AI Service: $e');
    }
  }

  Future<void> _sendChat() async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.aiBaseUrl}/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': _chatCtrl.text.trim(),
          'order_status': 'In-Transit',
          'estimated_minutes': 12,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _chatReply = (data['reply'] ?? data.toString()).toString());
      } else {
        setState(() => _chatReply = 'Lỗi Chatbot (${res.statusCode})');
      }
    } catch (e) {
      setState(() => _chatReply = 'Không kết nối được AI Service: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      // Trang 1: Đơn hàng
      RefreshIndicator(
        onRefresh: _fetchOrders,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Đơn hàng của bạn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(onPressed: _fetchOrders, icon: const Icon(Icons.refresh)),
              ],
            ),
            if (_loadingOrders) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            if (_orderStatusMsg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_orderStatusMsg, style: const TextStyle(color: Colors.amber)),
              ),
            if (!_loadingOrders && _orders.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.inventory_2_outlined),
                  title: Text('Chưa có đơn hàng nào'),
                  subtitle: Text('Tạo đơn từ Web Dashboard hoặc Swagger rồi bấm làm mới.'),
                ),
              ),
            ..._orders.map((item) {
              final map = item is Map<String, dynamic> ? item : <String, dynamic>{};
              final code = map['orderCode'] ?? map['code'] ?? 'ORD-${map['id'] ?? ''}';
              final status = map['status'] ?? 'Pending';
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.local_shipping, color: Color(0xFF38BDF8)),
                  title: Text(code.toString()),
                  subtitle: Text('Trạng thái: $status'),
                ),
              );
            }),
          ],
        ),
      ),

      // Trang 2: AI ETA
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ước lượng thời gian giao (AI ETA)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _distanceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Khoảng cách (km)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Khối lượng kiện hàng (kg)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _estimateEta,
              icon: const Icon(Icons.speed),
              label: const Text('Tính ETA bằng AI'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_etaResult, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),

      // Trang 3: Chatbot AI
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Trợ lý AI Khách hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(child: Text(_chatReply, style: const TextStyle(fontSize: 16))),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatCtrl,
                    decoration: const InputDecoration(hintText: 'Nhập câu hỏi...', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _sendChat, icon: const Icon(Icons.send)),
              ],
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('SmartDrone • ${widget.username}')),
      body: pages[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Đơn hàng'),
          NavigationDestination(icon: Icon(Icons.timer), label: 'AI ETA'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'AI Chat'),
        ],
      ),
    );
  }
}