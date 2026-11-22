import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const DroneApp());

class ApiConfig {
  // Chạy Chrome/Desktop: giữ localhost. Chạy Android Emulator: đổi thành 10.0.2.2
  static const String backend = 'http://localhost:5139';
  static const String ai = 'http://localhost:8000';
  // Đường dẫn API hủy đơn. Nếu backend của bạn đặt tên khác thì chỉ cần sửa dòng này.
  static String cancelPath(int id) => '/api/orders/$id/cancel';
}

const statusVi = {
  'Pending': 'Chờ duyệt',
  'Approved': 'Đã duyệt',
  'Rejected': 'Từ chối',
  'Scheduled': 'Đã xếp lịch',
  'InTransit': 'Đang giao',
  'Completed': 'Hoàn tất',
  'Failed': 'Thất bại',
  'Cancelled': 'Đã hủy',
};

Color statusColor(String s) {
  switch (s) {
    case 'Completed':
      return const Color(0xFF15803D);
    case 'Rejected':
    case 'Failed':
      return const Color(0xFFB91C1C);
    case 'Cancelled':
      return const Color(0xFF6B7280);
    case 'InTransit':
      return const Color(0xFF1D4ED8);
    case 'Pending':
      return const Color(0xFFB45309);
    default:
      return const Color(0xFF087E8B);
  }
}

class Session {
  final String token;
  final String name;
  Session(this.token, this.name);
  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
}

class DroneApp extends StatelessWidget {
  const DroneApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF152238);
    const canvas = Color(0xFFF4F7FB);
    return MaterialApp(
      title: 'SmartDrone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087E8B)),
        scaffoldBackgroundColor: canvas,
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: navy,
          toolbarHeight: 72,
          titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: navy),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 58),
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          height: 84,
          labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
      builder: (context, child) => ColoredBox(
        color: canvas,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 2200),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.45)),
              child: child!,
            ),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ---------------------------------------------------------------- Đăng nhập
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'khachhang1@gmail.com');
  final _pass = TextEditingController(text: '123456');
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.backend}/api/Auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _email.text.trim(), 'password': _pass.text}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode != 200) {
        setState(() => _error = (data['message'] ?? 'Đăng nhập thất bại (${res.statusCode}).').toString());
        return;
      }
      if (data['role'] != 'Customer') {
        setState(() => _error = 'Ứng dụng này dành cho khách hàng. Vai trò ${data['role']} hãy dùng trang web.');
        return;
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(Session(data['token'].toString(), data['fullName'].toString())),
        ),
      );
    } catch (_) {
      setState(() => _error = 'Không kết nối được backend (${ApiConfig.backend}). Hãy kiểm tra backend đang chạy.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Card(
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(64),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('SmartDrone', style: TextStyle(fontSize: 54, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Gửi hàng bằng drone giữa các trạm', style: TextStyle(fontSize: 26)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 26),
                    decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(fontSize: 22), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass,
                    obscureText: true,
                    style: const TextStyle(fontSize: 26),
                    decoration: const InputDecoration(labelText: 'Mật khẩu', labelStyle: TextStyle(fontSize: 22), border: OutlineInputBorder()),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Đăng nhập'),
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

// ---------------------------------------------------------------- Màn hình chính
class HomeScreen extends StatefulWidget {
  final Session session;
  const HomeScreen(this.session, {super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  List<dynamic> _orders = [];
  List<dynamic> _stations = [];
  String? _error;
  Timer? _timer;

  Session get s => widget.session;

  @override
  void initState() {
    super.initState();
    _loadStations();
    _loadOrders();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.backend}/api/Orders/mine'), headers: s.headers);
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _orders = jsonDecode(res.body) as List<dynamic>;
          _error = null;
        });
      } else {
        setState(() => _error = 'Không tải được đơn hàng (${res.statusCode}).');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Không kết nối được backend.');
    }
  }

  Future<void> _loadStations() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.backend}/api/Stations'), headers: s.headers);
      if (res.statusCode == 200 && mounted) {
        setState(() => _stations = jsonDecode(res.body) as List<dynamic>);
      }
    } catch (_) {}
  }

  Future<void> _cancel(int id, String code) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hủy đơn hàng?'),
        content: Text('Bạn muốn hủy đơn $code?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Không')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hủy đơn')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.backend}${ApiConfig.cancelPath(id)}'),
        headers: s.headers,
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy đơn hàng.')));
        _loadOrders();
      } else {
        var m = 'Không hủy được đơn (${res.statusCode}).';
        try {
          m = (jsonDecode(res.body)['message'] ?? m).toString();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không kết nối được backend.')));
      }
    }
  }

  Widget _ordersPage() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.deepOrange)),
            ),
          if (_orders.isEmpty && _error == null)
            const Card(
              child: ListTile(
                leading: Icon(Icons.inventory_2_outlined),
                title: Text('Chưa có đơn hàng nào'),
                subtitle: Text('Mở tab Tạo đơn để gửi đơn đầu tiên.'),
              ),
            ),
          ..._orders.map((o) => _orderCard(o as Map<String, dynamic>)),
        ],
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> o) {
    final status = (o['trangThai'] ?? '').toString();
    final eta = o['thoiGianDuKienPhut'];
    final otp = (o['maOtp'] ?? '').toString();
    final active = status != 'Completed' && status != 'Failed' && status != 'Rejected' && status != 'Cancelled';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text((o['maVanDon'] ?? '').toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Chip(
                  backgroundColor: Colors.white,
                  label: Text(
                    statusVi[status] ?? status,
                    style: TextStyle(color: statusColor(status), fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  side: BorderSide(color: statusColor(status), width: 2),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Người nhận: ${o['tenNguoiNhan']}'),
            Text('Địa chỉ: ${o['diaChiGiao']}'),
            Text('Phí giao: ${o['phiGiaoHang']} đ  |  ${o['khoiLuongKg']} kg'),
            if (eta != null) Text('Dự kiến: $eta phút'),
            if (status == 'Pending') ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _cancel(o['maDon'] as int, (o['maVanDon'] ?? '').toString()),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Hủy đơn'),
              ),
            ],
            if (otp.isNotEmpty && active) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF087E8B), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.vpn_key, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Mã OTP, đọc cho nhân viên trạm khi nhận hàng')),
                    Text(otp, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latest = _orders.isNotEmpty ? _orders.first as Map<String, dynamic> : null;
    return Scaffold(
      appBar: AppBar(title: Text('SmartDrone  ${s.name}')),
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            minExtendedWidth: 260,
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFD6EEF2),
            selectedLabelTextStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF087E8B)),
            unselectedLabelTextStyle: const TextStyle(fontSize: 16, color: Colors.black87),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.list_alt), label: Text('Đơn hàng')),
              NavigationRailDestination(icon: Icon(Icons.add_box_outlined), label: Text('Tạo đơn')),
              NavigationRailDestination(icon: Icon(Icons.chat_bubble_outline), label: Text('Trợ lý AI')),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton.tonalIcon(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất'),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _ordersPage(),
                CreateOrderPage(
                  session: s,
                  stations: _stations,
                  onCreated: () {
                    _loadOrders();
                    setState(() => _tab = 0);
                  },
                ),
                ChatPage(
                  status: latest?['trangThai']?.toString(),
                  eta: latest?['thoiGianDuKienPhut'] as int?,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Tạo đơn
class CreateOrderPage extends StatefulWidget {
  final Session session;
  final List<dynamic> stations;
  final VoidCallback onCreated;
  const CreateOrderPage({super.key, required this.session, required this.stations, required this.onCreated});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  int? _from;
  int? _to;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _addr = TextEditingController();
  final _weight = TextEditingController(text: '1.0');
  bool _busy = false;
  String? _error;

  int _sid(dynamic st) => (st['id'] ?? st['stationId']) as int;
  String _sname(dynamic st) => (st['stationName'] ?? st['name'] ?? 'Trạm').toString();

  List<DropdownMenuItem<int>> get _items =>
      widget.stations.map((st) => DropdownMenuItem<int>(value: _sid(st), child: Text(_sname(st)))).toList();

  Future<void> _submit() async {
    if (_from == null || _to == null) {
      setState(() => _error = 'Hãy chọn trạm gửi và trạm nhận.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.backend}/api/SmartDroneOrder/create'),
        headers: widget.session.headers,
        body: jsonEncode({
          'pickupStationId': _from,
          'dropoffStationId': _to,
          'receiverName': _name.text.trim(),
          'receiverPhone': _phone.text.trim(),
          'receiverAddress': _addr.text.trim(),
          'packageWeightKg': double.tryParse(_weight.text.replaceAll(',', '.')) ?? 0,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã tạo đơn ${data['trackingCode']}: phí ${data['deliveryFee']} đ, dự kiến ${data['estimatedMinutes']} phút.'),
        ));
        _name.clear();
        _phone.clear();
        _addr.clear();
        widget.onCreated();
      } else {
        setState(() => _error = (data['message'] ?? 'Không tạo được đơn (${res.statusCode}).').toString());
      }
    } catch (_) {
      setState(() => _error = 'Không kết nối được backend.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Tạo đơn mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _from,
          items: _items,
          onChanged: (v) => setState(() => _from = v),
          decoration: const InputDecoration(labelText: 'Trạm gửi', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _to,
          items: _items,
          onChanged: (v) => setState(() => _to = v),
          decoration: const InputDecoration(labelText: 'Trạm nhận', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Tên người nhận', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Số điện thoại người nhận', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(controller: _addr, decoration: const InputDecoration(labelText: 'Địa chỉ nhận', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(
          controller: _weight,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Khối lượng (kg, tối đa 5)', border: OutlineInputBorder()),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _submit,
          icon: const Icon(Icons.send),
          label: Text(_busy ? 'Đang tạo đơn...' : 'Tạo đơn'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Trợ lý AI
class ChatPage extends StatefulWidget {
  final String? status;
  final int? eta;
  const ChatPage({super.key, this.status, this.eta});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _ctrl = TextEditingController();
  final List<({bool mine, String text})> _msgs = [
    (mine: false, text: 'Xin chào! Tôi là trợ lý giao hàng SmartDrone. Bạn cần hỏi gì về đơn hàng?'),
  ];
  bool _busy = false;

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() {
      _msgs.add((mine: true, text: text));
      _ctrl.clear();
      _busy = true;
    });
    String reply;
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.ai}/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': text,
          'order_status': widget.status ?? 'Pending',
          'estimated_minutes': widget.eta ?? 10,
        }),
      );
      reply = res.statusCode == 200
          ? (jsonDecode(res.body)['reply'] ?? res.body).toString()
          : 'Trợ lý AI đang gặp lỗi (${res.statusCode}).';
    } catch (_) {
      reply = 'Không kết nối được dịch vụ AI (${ApiConfig.ai}). Hãy bật AI service.';
    }
    if (!mounted) return;
    setState(() {
      _msgs.add((mine: false, text: reply));
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: _msgs
                  .map((m) => Align(
                        alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxWidth: 480),
                          decoration: BoxDecoration(
                            color: m.mine ? const Color(0xFFD6EEF2) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(m.text),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(hintText: 'Hỏi về đơn hàng của bạn', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _busy ? null : _send, icon: const Icon(Icons.send)),
            ],
          ),
        ],
      ),
    );
  }
}