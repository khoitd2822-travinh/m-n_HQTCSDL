import 'package:flutter/material.dart';

void main() => runApp(const SmartDroneCustomerApp());

const blue = Color(0xFF2478F2);
const navy = Color(0xFF14233B);
const canvas = Color(0xFFF4F7FB);

class SmartDroneCustomerApp extends StatelessWidget {
  const SmartDroneCustomerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'SmartDrone Customer',
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: blue), scaffoldBackgroundColor: canvas, appBarTheme: const AppBarTheme(backgroundColor: canvas, foregroundColor: navy)),
    home: const AuthScreen(),
  );
}

class DeliveryOrder {
  final String id, pickup, destination, packageDescription, status;
  final double weight, distance;
  final DateTime createdAt;
  const DeliveryOrder({required this.id, required this.pickup, required this.destination, required this.packageDescription, required this.weight, required this.distance, required this.status, required this.createdAt});
}

class DemoStore {
  static String customerName = 'Khách hàng';
  static final List<DeliveryOrder> orders = [
    DeliveryOrder(id: 'SD-1024', pickup: 'Trạm Trung tâm', destination: 'Đại học Quốc gia', packageDescription: 'Tài liệu', weight: .5, distance: 3.2, status: 'Đang giao', createdAt: DateTime.now().subtract(const Duration(hours: 1))),
    DeliveryOrder(id: 'SD-1018', pickup: 'Trạm Linh Trung', destination: 'Khu dân cư', packageDescription: 'Đồ dùng cá nhân', weight: 1.0, distance: 2.1, status: 'Đã giao', createdAt: DateTime.now().subtract(const Duration(days: 1))),
  ];
}

class AuthScreen extends StatefulWidget { const AuthScreen({super.key}); @override State<AuthScreen> createState() => _AuthScreenState(); }
class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true, obscure = true;
  final name = TextEditingController(); final email = TextEditingController(); final password = TextEditingController();
  @override void dispose(){name.dispose(); email.dispose(); password.dispose(); super.dispose();}
  void submit(){
    if(email.text.trim().isEmpty || password.text.isEmpty || (!isLogin && name.text.trim().isEmpty)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin.'))); return; }
    DemoStore.customerName = isLogin ? (email.text.split('@').first) : name.text.trim();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const CustomerShell()));
  }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Container(width: 78, height: 78, decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 42)),
    const SizedBox(height: 24), const Text('SmartDrone', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: navy)),
    const SizedBox(height: 6), Text(isLogin ? 'Đăng nhập để quản lý đơn hàng của bạn.' : 'Tạo tài khoản để bắt đầu gửi hàng.', style: const TextStyle(color: Colors.black54)),
    const SizedBox(height: 28),
    if(!isLogin) ...[TextField(controller: name, decoration: const InputDecoration(labelText: 'Họ và tên', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())), const SizedBox(height: 14)],
    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder())),
    const SizedBox(height: 14), TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'Mật khẩu', prefixIcon: const Icon(Icons.lock_outline), border: const OutlineInputBorder(), suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => obscure = !obscure)))),
    const SizedBox(height: 22), FilledButton(onPressed: submit, style: FilledButton.styleFrom(backgroundColor: blue, padding: const EdgeInsets.all(16)), child: Text(isLogin ? 'Đăng nhập' : 'Đăng ký')),
    TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? 'Chưa có tài khoản? Đăng ký' : 'Đã có tài khoản? Đăng nhập')),
    const SizedBox(height: 12), const Text('Bản demo học tập: thông tin đăng nhập chưa được lưu hoặc xác thực trên máy chủ.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black45, fontSize: 12)),
  ]))))));
}

class CustomerShell extends StatefulWidget { const CustomerShell({super.key}); @override State<CustomerShell> createState() => _CustomerShellState(); }
class _CustomerShellState extends State<CustomerShell> {
  int tab = 0;
  void addOrder(DeliveryOrder order){ setState(() { DemoStore.orders.insert(0, order); tab = 1; }); }
  @override Widget build(BuildContext context) {
    final pages = [HomePage(onCreate: () async { final order = await Navigator.of(context).push<DeliveryOrder>(MaterialPageRoute(builder: (_) => const CreateOrderPage())); if(order != null) addOrder(order); }), const OrderHistoryPage(), const ProfilePage()];
    return Scaffold(appBar: AppBar(title: const Text('SmartDrone', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(tooltip: 'Đăng xuất', onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthScreen()), (_) => false), icon: const Icon(Icons.logout))]), body: SafeArea(child: pages[tab]), bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'), NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Lịch sử đơn'), NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Tài khoản') ]));
  }
}

class HomePage extends StatelessWidget { final VoidCallback onCreate; const HomePage({super.key, required this.onCreate}); @override Widget build(BuildContext context) { final active = DemoStore.orders.where((o) => o.status != 'Đã giao').toList(); return ListView(padding: const EdgeInsets.all(20), children: [Text('Xin chào, ${DemoStore.customerName} 👋', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: navy)), const SizedBox(height: 6), const Text('Gửi hàng nhanh chóng cùng SmartDrone.', style: TextStyle(color: Colors.black54)), const SizedBox(height: 22), Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(24)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.flight_takeoff, color: Colors.white, size: 34), SizedBox(height: 14), Text('Giao hàng thông minh', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)), SizedBox(height: 6), Text('Tạo đơn mới và theo dõi hành trình drone.', style: TextStyle(color: Colors.white70))])), const SizedBox(height: 16), FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Tạo đơn hàng mới'), style: FilledButton.styleFrom(padding: const EdgeInsets.all(16))), const SizedBox(height: 24), const Text('Đơn hàng đang xử lý', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navy)), const SizedBox(height: 10), if(active.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Bạn chưa có đơn hàng đang xử lý.'))) else ...active.take(3).map((o) => OrderTile(order: o)), const SizedBox(height: 8), const Text('ETA và trạng thái hiện là dữ liệu demo.', style: TextStyle(fontSize: 12, color: Colors.black45))]); } }

class CreateOrderPage extends StatefulWidget { const CreateOrderPage({super.key}); @override State<CreateOrderPage> createState() => _CreateOrderPageState(); }
class _CreateOrderPageState extends State<CreateOrderPage> {
  final description = TextEditingController(); final weight = TextEditingController(text: '0.5');
  String pickup = 'Trạm Trung tâm', destination = 'Đại học Quốc gia';
  final places = const ['Trạm Trung tâm', 'Trạm Linh Trung', 'Đại học Quốc gia', 'Khu dân cư', 'Khu Công nghệ cao', 'Bưu cục Thủ Đức'];
  @override void dispose(){description.dispose(); weight.dispose(); super.dispose();}
  Future<void> choosePlace(bool isPickup) async { final selected = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => LocationPickerPage(title: isPickup ? 'Chọn điểm lấy hàng' : 'Chọn điểm giao hàng', places: places, selected: isPickup ? pickup : destination))); if(selected != null) setState(() { if(isPickup) pickup = selected; else destination = selected; }); }
  void create(){ final w = double.tryParse(weight.text.trim()); if(description.text.trim().isEmpty || w == null || w <= 0){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập mô tả hàng và tải trọng hợp lệ.'))); return; } if(pickup == destination){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Điểm lấy và điểm giao phải khác nhau.'))); return; } final order = DeliveryOrder(id: 'SD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}', pickup: pickup, destination: destination, packageDescription: description.text.trim(), weight: w, distance: 2.0 + (places.indexOf(pickup) - places.indexOf(destination)).abs() * 1.4, status: 'Chờ xác nhận', createdAt: DateTime.now()); Navigator.pop(context, order); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Tạo đơn hàng mới')), body: ListView(padding: const EdgeInsets.all(20), children: [const Text('Thông tin giao hàng', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: navy)), const SizedBox(height: 6), const Text('Chọn điểm lấy và điểm giao hàng trên bản đồ minh họa.', style: TextStyle(color: Colors.black54)), const SizedBox(height: 18), LocationCard(label: 'Điểm lấy hàng', value: pickup, icon: Icons.trip_origin, onTap: () => choosePlace(true)), const SizedBox(height: 12), LocationCard(label: 'Điểm giao hàng', value: destination, icon: Icons.location_on_outlined, onTap: () => choosePlace(false)), const SizedBox(height: 18), TextField(controller: description, decoration: const InputDecoration(labelText: 'Mô tả gói hàng', hintText: 'Ví dụ: tài liệu, đồ dùng cá nhân', prefixIcon: Icon(Icons.inventory_2_outlined), border: OutlineInputBorder())), const SizedBox(height: 14), TextField(controller: weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Tải trọng (kg)', prefixIcon: Icon(Icons.scale_outlined), border: OutlineInputBorder())), const SizedBox(height: 18), Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Row(children: [const Icon(Icons.route_outlined, color: blue, size: 30), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Ước tính sơ bộ', style: TextStyle(fontWeight: FontWeight.bold)), Text('Khoảng cách minh họa • ETA sẽ tính qua API sau khi tích hợp', style: TextStyle(color: Colors.black54, fontSize: 12))]))])), const SizedBox(height: 20), FilledButton.icon(onPressed: create, icon: const Icon(Icons.check_circle_outline), label: const Text('Tạo đơn hàng'), style: FilledButton.styleFrom(padding: const EdgeInsets.all(16))) ]));
}

class LocationCard extends StatelessWidget { final String label, value; final IconData icon; final VoidCallback onTap; const LocationCard({super.key, required this.label, required this.value, required this.icon, required this.onTap}); @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE1E8F0))), child: Row(children: [Icon(icon, color: blue, size: 28), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))])), const Icon(Icons.map_outlined, color: blue), const SizedBox(width: 5), const Text('Chọn', style: TextStyle(color: blue, fontWeight: FontWeight.bold))]))); } }

class LocationPickerPage extends StatefulWidget { final String title, selected; final List<String> places; const LocationPickerPage({super.key, required this.title, required this.places, required this.selected}); @override State<LocationPickerPage> createState() => _LocationPickerPageState(); }
class _LocationPickerPageState extends State<LocationPickerPage> { late String selected = widget.selected; @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.title)), body: Column(children: [Container(height: 245, margin: const EdgeInsets.all(16), clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: const Color(0xFFE4F0E8), borderRadius: BorderRadius.circular(22)), child: Stack(children: [Positioned.fill(child: CustomPaint(painter: DemoMapPainter())), const Positioned(left: 22, top: 18, child: Chip(avatar: Icon(Icons.map_outlined, size: 18), label: Text('BẢN ĐỒ MINH HỌA'))), const Positioned(left: 70, top: 105, child: Icon(Icons.location_on, size: 38, color: blue)), const Positioned(right: 62, bottom: 58, child: Icon(Icons.location_on, size: 38, color: Color(0xFFE15B64))), const Positioned(left: 24, bottom: 18, child: Text('Chọn địa điểm từ danh sách bên dưới', style: TextStyle(fontWeight: FontWeight.w600, color: navy)))])), const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Align(alignment: Alignment.centerLeft, child: Text('Địa điểm khả dụng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))), Expanded(child: ListView(children: widget.places.map((p) => RadioListTile<String>(value: p, groupValue: selected, onChanged: (v) => setState(() => selected = v!), title: Text(p), secondary: const Icon(Icons.place_outlined, color: blue))).toList())), Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context, selected), child: const Text('Xác nhận địa điểm'))))])); } }

class DemoMapPainter extends CustomPainter { @override void paint(Canvas canvas, Size size) { final road = Paint()..color = Colors.white..strokeWidth = 10..strokeCap = StrokeCap.round; final thin = Paint()..color = const Color(0xFFB8D4C0)..strokeWidth = 2; for(double y=35; y<size.height; y+=52){canvas.drawLine(Offset(0,y), Offset(size.width,y+18), road);} for(double x=20; x<size.width; x+=72){canvas.drawLine(Offset(x,0), Offset(x+20,size.height), road);} for(double y=20; y<size.height; y+=24){canvas.drawLine(Offset(0,y), Offset(size.width,y+7), thin);} } @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false; }

class OrderHistoryPage extends StatelessWidget { const OrderHistoryPage({super.key}); @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [const Text('Lịch sử đơn hàng', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: navy)), const SizedBox(height: 6), const Text('Các đơn được tạo trong phiên demo này.', style: TextStyle(color: Colors.black54)), const SizedBox(height: 14), if(DemoStore.orders.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Chưa có đơn hàng nào.'))) else ...DemoStore.orders.map((o) => OrderTile(order: o))]); } }
class OrderTile extends StatelessWidget { final DeliveryOrder order; const OrderTile({super.key, required this.order}); @override Widget build(BuildContext context) => Card(color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const CircleAvatar(backgroundColor: Color(0xFFE5EFFF), child: Icon(Icons.inventory_2_outlined, color: blue)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(order.id, style: const TextStyle(fontWeight: FontWeight.w800)), Text(order.status, style: TextStyle(color: order.status == 'Đã giao' ? Colors.green : blue, fontWeight: FontWeight.w600))])), Text('${order.weight.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold))]), const Divider(height: 22), Text('Lấy hàng: ${order.pickup}'), const SizedBox(height: 5), Text('Giao đến: ${order.destination}'), const SizedBox(height: 5), Text('Gói hàng: ${order.packageDescription}', style: const TextStyle(color: Colors.black54)), const SizedBox(height: 8), Text('Khoảng cách mẫu: ${order.distance.toStringAsFixed(1)} km • ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}', style: const TextStyle(color: Colors.black45, fontSize: 12))]))); } }

class ProfilePage extends StatelessWidget { const ProfilePage({super.key}); @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [const CircleAvatar(radius: 38, backgroundColor: Color(0xFFE5EFFF), child: Icon(Icons.person, color: blue, size: 42)), const SizedBox(height: 12), Center(child: Text(DemoStore.customerName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: navy))), const Center(child: Text('Tài khoản demo', style: TextStyle(color: Colors.black54))), const SizedBox(height: 24), const Card(child: ListTile(leading: Icon(Icons.shield_outlined, color: blue), title: Text('Bảo mật tài khoản'), subtitle: Text('Đăng nhập và đăng ký hiện chỉ mô phỏng trên thiết bị.'))), const Card(child: ListTile(leading: Icon(Icons.map_outlined, color: blue), title: Text('Địa điểm giao hàng'), subtitle: Text('Bản đồ hiện là minh họa, chưa dùng bản đồ trực tuyến/GPS.')))]); }
