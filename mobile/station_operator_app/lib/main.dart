import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const StationOperatorApp());

const navy = Color(0xFF152238);
const teal = Color(0xFF087E8B);
const canvas = Color(0xFFF4F7FB);

class ApiConfig {
  // Chạy Chrome/Desktop: giữ localhost. Chạy Android Emulator: đổi thành 10.0.2.2
  static const String backend = 'http://localhost:5139';
}

const statusVi = {
  'Pending': 'Chờ duyệt',
  'Approved': 'Chờ bắt đầu giao',
  'Rejected': 'Từ chối',
  'Scheduled': 'Chờ bắt đầu giao',
  'InTransit': 'Đang giao',
  'Completed': 'Hoàn tất',
  'Failed': 'Thất bại',
};

class Api {
  final String token;
  Api(this.token);

  Map<String, String> get _h => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<http.Response> get(String path) => http.get(Uri.parse('${ApiConfig.backend}$path'), headers: _h);

  Future<http.Response> post(String path, [Object? body]) =>
      http.post(Uri.parse('${ApiConfig.backend}$path'), headers: _h, body: body == null ? null : jsonEncode(body));
}

class StationOperatorApp extends StatelessWidget {
  const StationOperatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartDrone Station',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: teal),
        scaffoldBackgroundColor: canvas,
        appBarTheme: const AppBarTheme(backgroundColor: canvas, foregroundColor: navy),
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
  final _email = TextEditingController(text: 'operator@smartdrone.vn');
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
      if (data['role'] != 'StationOperator') {
        setState(() => _error = 'Ứng dụng này dành cho nhân viên trạm. Vai trò ${data['role']} hãy dùng trang web.');
        return;
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StationHome(name: data['fullName'].toString(), api: Api(data['token'].toString())),
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
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('SmartDrone Station',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: navy)),
                  const SizedBox(height: 4),
                  const Text('Dành cho nhân viên trạm'),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder()),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
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
class StationHome extends StatefulWidget {
  final String name;
  final Api api;
  const StationHome({super.key, required this.name, required this.api});

  @override
  State<StationHome> createState() => _StationHomeState();
}

class _StationHomeState extends State<StationHome> {
  int tab = 0;
  List<Map<String, dynamic>> orders = [];
  Map<int, String> stations = {};
  String? error;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _loadStations().then((_) => _loadOrders());
    timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadOrders());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _loadStations() async {
    try {
      final res = await widget.api.get('/api/Stations');
      if (res.statusCode == 200) {
        final m = <int, String>{};
        for (final s in jsonDecode(res.body) as List<dynamic>) {
          m[(s['id'] ?? s['stationId']) as int] = (s['stationName'] ?? s['name'] ?? 'Trạm').toString();
        }
        if (mounted) setState(() => stations = m);
      }
    } catch (_) {}
  }

  Future<void> _loadOrders() async {
    try {
      final res = await widget.api.get('/api/Orders');
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          orders = (jsonDecode(res.body) as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
          error = null;
        });
      } else {
        setState(() => error = 'Không tải được đơn hàng (${res.statusCode}).');
      }
    } catch (_) {
      if (mounted) setState(() => error = 'Không kết nối được backend.');
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _act(int id, String kind, String otp) async {
    try {
      if (kind == 'otp' && otp.isEmpty) {
        _snack('Hãy nhập mã OTP mà người nhận đọc.');
        return;
      }
      final res = kind == 'otp'
          ? await widget.api.post('/api/SmartDroneOrder/$id/confirm-delivery', {'otpCode': otp})
          : await widget.api.post('/api/orders/$id/$kind');
      if (!mounted) return;
      if (res.statusCode == 200) {
        _snack('Đã cập nhật đơn hàng.');
        await _loadOrders();
      } else {
        final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        _snack((data['message'] ?? 'Không thực hiện được (${res.statusCode}).').toString());
      }
    } catch (_) {
      if (mounted) _snack('Không kết nối được backend.');
    }
  }

  String _route(Map<String, dynamic> o) =>
      '${stations[o['pickupStationId']] ?? 'Trạm ${o['pickupStationId']}'} → ${stations[o['dropoffStationId']] ?? 'Trạm ${o['dropoffStationId']}'}';

  int _count(Set<String> st) => orders.where((o) => st.contains(o['status'])).length;

  List<Map<String, dynamic>> get _tasks {
    final t = orders.where((o) => {'Approved', 'Scheduled', 'InTransit'}.contains(o['status'])).toList();
    t.sort((a, b) => (a['status'] == 'InTransit' ? 0 : 1).compareTo(b['status'] == 'InTransit' ? 0 : 1));
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_overview(), _tasksPage(), _summary()];
    return Scaffold(
      appBar: AppBar(
        title: Text('Nhân viên trạm: ${widget.name}', style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          ),
        ],
      ),
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Tổng quan'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Công việc'),
          NavigationDestination(icon: Icon(Icons.summarize_outlined), label: 'Tóm tắt'),
        ],
      ),
    );
  }

  Widget _errorLine() => error == null
      ? const SizedBox.shrink()
      : Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(error!, style: const TextStyle(color: Colors.deepOrange)));

  Widget _overview() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Tổng quan trạm', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: navy)),
          const SizedBox(height: 16),
          _errorLine(),
          Row(children: [
            Expanded(child: MetricCard(title: 'Chờ bắt đầu giao', value: '${_count({'Approved', 'Scheduled'})}', icon: Icons.inventory_2_outlined)),
            const SizedBox(width: 12),
            Expanded(child: MetricCard(title: 'Đang giao', value: '${_count({'InTransit'})}', icon: Icons.route)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: MetricCard(title: 'Hoàn tất', value: '${_count({'Completed'})}', icon: Icons.task_alt)),
            const SizedBox(width: 12),
            Expanded(child: MetricCard(title: 'Thất bại', value: '${_count({'Failed'})}', icon: Icons.warning_amber_rounded)),
          ]),
          const SizedBox(height: 24),
          const Text('Cần xác nhận khi drone tới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          if (_tasks.where((o) => o['status'] == 'InTransit').isEmpty)
            const Text('Hiện không có đơn nào đang giao.'),
          ..._tasks.where((o) => o['status'] == 'InTransit').map((o) => Card(
                color: Colors.white,
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.flight, color: teal),
                  title: Text(o['trackingCode'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_route(o)),
                ),
              )),
        ],
      ),
    );
  }

  Widget _tasksPage() {
    final tasks = _tasks;
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Danh sách công việc', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: navy)),
          const SizedBox(height: 16),
          _errorLine(),
          if (tasks.isEmpty && error == null) const Text('Chưa có đơn nào cần xử lý.'),
          ...tasks.map((o) => TaskCard(
                key: ValueKey(o['id']),
                order: o,
                route: _route(o),
                onAct: (kind, otp) => _act(o['id'] as int, kind, otp),
              )),
        ],
      ),
    );
  }

  Widget _summary() {
    final inTransit = _tasks.where((o) => o['status'] == 'InTransit').map((o) => o['trackingCode']).join(', ');
    final lines = [
      '${_count({'Approved', 'Scheduled'})} đơn đã duyệt, đang chờ bắt đầu giao.',
      '${_count({'InTransit'})} đơn đang giao${inTransit.isEmpty ? '' : ': $inTransit'}. Cần nhập OTP khi giao xong.',
      '${_count({'Completed'})} đơn đã hoàn tất, ${_count({'Failed'})} đơn thất bại.',
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Tóm tắt ca trực', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: navy)),
        const SizedBox(height: 8),
        const Text('Tạo từ dữ liệu đơn hàng thật trong hệ thống.'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, color: teal, size: 30),
              const SizedBox(height: 12),
              ...lines.map((l) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('• $l'))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: _loadOrders, icon: const Icon(Icons.refresh), label: const Text('Làm mới')),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  const MetricCard({super.key, required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: teal, size: 25),
            const SizedBox(height: 15),
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: navy)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      );
}

// ---------------------------------------------------------------- Thẻ công việc
class TaskCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final String route;
  final void Function(String kind, String otp) onAct;
  const TaskCard({super.key, required this.order, required this.route, required this.onAct});

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  final _otp = TextEditingController();

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final status = o['status'].toString();
    final moving = status == 'InTransit';
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(o['trackingCode'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              Text(statusVi[status] ?? status, style: TextStyle(color: moving ? teal : Colors.deepOrange, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 4),
            Text(widget.route),
            Text('Người nhận: ${o['receiverName']}, ${o['receiverPhone']}'),
            Text('${o['packageWeightKg']} kg'),
            const SizedBox(height: 10),
            if (!moving)
              FilledButton.icon(
                onPressed: () => widget.onAct('start', ''),
                icon: const Icon(Icons.flight_takeoff),
                label: const Text('Bắt đầu giao'),
              ),
            if (moving) ...[
              TextField(
                controller: _otp,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Mã OTP người nhận đọc',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => widget.onAct('otp', _otp.text.trim()),
                    icon: const Icon(Icons.verified),
                    label: const Text('Xác nhận giao'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(onPressed: () => widget.onAct('fail', ''), child: const Text('Giao thất bại')),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}