import 'package:flutter/material.dart';

void main() => runApp(const CustomerApp());

const navy = Color(0xFF152238);
const blue = Color(0xFF2878F0);
const canvas = Color(0xFFF4F7FB);

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SmartDrone Customer',
        theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: blue), scaffoldBackgroundColor: canvas, appBarTheme: const AppBarTheme(backgroundColor: canvas, foregroundColor: navy)),
        home: const CustomerHome(),
      );
}

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});
  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [const HomePanel(), const OrdersPanel(), const HelpPanel()];
    return Scaffold(
      appBar: AppBar(title: const Text('SmartDrone', style: TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded))]),
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'), NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Đơn hàng'), NavigationDestination(icon: Icon(Icons.support_agent), label: 'Trợ giúp')]),
    );
  }
}

class HomePanel extends StatelessWidget {
  const HomePanel({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Xin chào, khách hàng 👋', style: TextStyle(color: navy, fontSize: 23, fontWeight: FontWeight.w800)),
    const SizedBox(height: 6), const Text('Theo dõi đơn hàng của bạn theo thời gian thực.', style: TextStyle(color: Colors.black54)),
    const SizedBox(height: 22),
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(24)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 34), SizedBox(height: 18), Text('Đơn hàng đang giao', style: TextStyle(color: Colors.white70)), SizedBox(height: 5), Text('#SD-1024', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)), SizedBox(height: 15), Row(children: [Icon(Icons.schedule, color: Colors.white), SizedBox(width: 8), Text('ETA dự kiến: 6 phút', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))])])),
    const SizedBox(height: 20), const Text('Trạng thái giao hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navy)), const SizedBox(height: 12),
    const StatusStep(icon: Icons.check_circle, title: 'Đơn hàng đã xác nhận', subtitle: 'Trạm đang chuẩn bị gói hàng', done: true), const StatusStep(icon: Icons.local_shipping_outlined, title: 'Drone đang vận chuyển', subtitle: 'Cập nhật trạng thái sẽ hiển thị tại đây', done: false), const StatusStep(icon: Icons.home_outlined, title: 'Đã giao hàng', subtitle: 'Chưa hoàn tất', done: false),
    const SizedBox(height: 18), OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Tạo đơn hàng mới'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))
  ]);
}

class StatusStep extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final bool done;
  const StatusStep({super.key, required this.icon, required this.title, required this.subtitle, required this.done});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: done ? Colors.green : blue, size: 25), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: Colors.black54))]))]));
}

class OrdersPanel extends StatelessWidget {
  const OrdersPanel({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [const Text('Đơn hàng của tôi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: navy)), const SizedBox(height: 16), const OrderCard(code: '#SD-1024', status: 'Đang giao', eta: '6 phút'), const OrderCard(code: '#SD-1018', status: 'Đã giao', eta: 'Hoàn tất')]);
}
class OrderCard extends StatelessWidget { final String code, status, eta; const OrderCard({super.key, required this.code, required this.status, required this.eta}); @override Widget build(BuildContext context) => Card(color: Colors.white, elevation: 0, child: ListTile(leading: const CircleAvatar(backgroundColor: Color(0xFFE5EFFF), child: Icon(Icons.inventory_2_outlined, color: blue)), title: Text(code, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('$status • $eta'), trailing: const Icon(Icons.chevron_right))); }

class HelpPanel extends StatefulWidget { const HelpPanel({super.key}); @override State<HelpPanel> createState() => _HelpPanelState(); }
class _HelpPanelState extends State<HelpPanel> { final controller = TextEditingController(); final messages = <String>['Xin chào! Tôi có thể giúp gì cho bạn?']; @override void dispose() { controller.dispose(); super.dispose(); } @override Widget build(BuildContext context) => Column(children: [const Padding(padding: EdgeInsets.all(20), child: Row(children: [CircleAvatar(backgroundColor: Color(0xFFE5EFFF), child: Icon(Icons.smart_toy_outlined, color: blue)), SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Trợ lý SmartDrone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text('Chatbot demo', style: TextStyle(color: Colors.black54))])])), Expanded(child: ListView(padding: const EdgeInsets.all(16), children: messages.map((m) => Align(alignment: Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Text(m)))).toList()),), Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Nhập câu hỏi...', filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide.none)))), IconButton(onPressed: () { if (controller.text.trim().isEmpty) return; setState(() { messages.add('Bạn: ${controller.text.trim()}'); messages.add('Trợ lý demo: Vui lòng kiểm tra mục Đơn hàng để xem trạng thái mới nhất.'); controller.clear(); }); }, icon: const Icon(Icons.send_rounded, color: blue))]))]); }
