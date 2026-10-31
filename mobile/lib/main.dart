import 'package:flutter/material.dart';

void main() => runApp(const SmartDroneApp());

const navy = Color(0xFF101827);
const blue = Color(0xFF1687F8);
const bg = Color(0xFFF4F7FB);

class SmartDroneApp extends StatelessWidget {
  const SmartDroneApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartDrone',
      theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: navy)),
      home: const RoleHome(),
    );
  }
}

class RoleHome extends StatefulWidget {
  const RoleHome({super.key});
  @override
  State<RoleHome> createState() => _RoleHomeState();
}
class _RoleHomeState extends State<RoleHome> {
  int role = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('SmartDrone', style: TextStyle(fontWeight: FontWeight.w800)),
      actions: [PopupMenuButton<int>(initialValue: role, onSelected: (v)=>setState(()=>role=v),
        itemBuilder: (_) => const [PopupMenuItem(value: 0, child: Text('Customer')),
          PopupMenuItem(value: 1, child: Text('Station Operator'))],
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
          Icon(role==0 ? Icons.person_outline : Icons.warehouse_outlined), const SizedBox(width: 5),
          Text(role==0 ? 'Customer' : 'Operator'), const Icon(Icons.arrow_drop_down)])))],
    ),
    body: role == 0 ? const CustomerScreen() : const OperatorScreen(),
  );
}

class CustomerScreen extends StatelessWidget {
  const CustomerScreen({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(22)),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Xin chào, Nguyễn Văn A 👋', style: TextStyle(color: Colors.white70)),
        SizedBox(height: 10), Text('Giao hàng nhanh hơn\ncùng SmartDrone', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 8), Text('Theo dõi chuyến giao hàng của bạn theo thời gian thực.', style: TextStyle(color: Colors.white70)),
      ])),
    const SizedBox(height: 20),
    const SectionTitle('Đơn hàng đang giao'),
    CardBox(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.inventory_2_outlined, color: blue, size: 30), const SizedBox(width: 10),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Đơn hàng #1024', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('Trạm A → Trạm B', style: TextStyle(color: Colors.black54))])),
        Chip(label: Text('Đang chuẩn bị', style: TextStyle(fontSize: 11)), backgroundColor: Color(0xFFE0F2FE))]),
      const Divider(height: 26),
      Row(children: [const Icon(Icons.schedule, color: blue), const SizedBox(width: 8),
        const Text('AI dự đoán thời gian giao', style: TextStyle(color: Colors.black54)),
        const Spacer(), const Text('6 phút', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: blue))]),
      const SizedBox(height: 14), const LinearProgressIndicator(value: .45, minHeight: 7, borderRadius: BorderRadius.all(Radius.circular(8))),
      const SizedBox(height: 8), const Text('Đơn hàng đã được xác nhận. Drone đang được chuẩn bị.', style: TextStyle(color: Colors.black54)),
    ])),
    const SizedBox(height: 18), const SectionTitle('Trợ lý SmartDrone AI'),
    CardBox(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [CircleAvatar(backgroundColor: Color(0xFFE0F2FE), child: Icon(Icons.smart_toy_outlined, color: blue)),
        SizedBox(width: 10), Expanded(child: Text('Xin chào! Tôi có thể giúp bạn kiểm tra trạng thái đơn hàng hoặc giải đáp thắc mắc.', style: TextStyle(height: 1.4)))]),
      const SizedBox(height: 14), SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: ()=>showDialog(context: context, builder: (ctx)=>AlertDialog(title: const Text('SmartDrone AI'),
          content: const Text('Bản giao diện mẫu: chatbot sẽ kết nối API AI ở bước tích hợp tiếp theo.'),
          actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Đóng'))])),
        icon: const Icon(Icons.chat_bubble_outline), label: const Text('Mở chatbot'))),
    ])),
    const SizedBox(height: 16), const SectionTitle('Lối tắt'),
    Row(children: const [Expanded(child: ShortcutCard(icon: Icons.add_box_outlined, title: 'Tạo đơn mới')),
      SizedBox(width: 10), Expanded(child: ShortcutCard(icon: Icons.location_on_outlined, title: 'Trạm gần đây'))]),
    const SizedBox(height: 20),
  ]);
}

class OperatorScreen extends StatelessWidget {
  const OperatorScreen({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('Bảng điều khiển trạm', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: navy)),
    const SizedBox(height: 5), const Text('Theo dõi hoạt động và hỗ trợ bàn giao drone.', style: TextStyle(color: Colors.black54)),
    const SizedBox(height: 18),
    Row(children: const [Expanded(child: MetricCard(label: 'Đơn chờ xử lý', value: '03', icon: Icons.pending_actions, color: Color(0xFFFFA726))),
      SizedBox(width: 10), Expanded(child: MetricCard(label: 'Drone sẵn sàng', value: '12', icon: Icons.flight, color: Color(0xFF1687F8)))]),
    const SizedBox(height: 20), const SectionTitle('Công việc tại trạm'),
    const CardBox(child: Column(children: [
      TaskRow(code: 'ORD-1024', title: 'Kiểm tra gói hàng', subtitle: 'Trạm A · 09:30', status: 'Chờ xử lý', color: Color(0xFFFFF0D5)),
      Divider(height: 24), TaskRow(code: 'ORD-1023', title: 'Xác nhận bàn giao', subtitle: 'Trạm A · 09:25', status: 'Đang làm', color: Color(0xFFE0F2FE)),
      Divider(height: 24), TaskRow(code: 'ORD-1022', title: 'Kiểm tra pin drone', subtitle: 'Drone DR-001', status: 'Hoàn tất', color: Color(0xFFDDF7E8)),
    ])),
    const SizedBox(height: 20), const SectionTitle('Tóm tắt bằng AI'),
    CardBox(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Icon(Icons.auto_awesome, color: blue), SizedBox(width: 8),
        Text('Báo cáo ca trực', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
      const SizedBox(height: 10),
      const Text('• 3 đơn cần theo dõi trong ca hiện tại.\n• 1 drone đang chờ xác nhận bàn giao.\n• Ưu tiên kiểm tra gói ORD-1024 trước khi xuất phát.',
        style: TextStyle(height: 1.6, color: Colors.black87)),
      const SizedBox(height: 10), Align(alignment: Alignment.centerRight, child: FilledButton.icon(
        onPressed: ()=>ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bản mẫu: sẽ gọi AI Summary API khi tích hợp.'))),
        icon: const Icon(Icons.summarize_outlined), label: const Text('Tạo tóm tắt'))),
    ])),
    const SizedBox(height: 20),
  ]);
}

class SectionTitle extends StatelessWidget {
  final String text; const SectionTitle(this.text, {super.key});
  @override Widget build(BuildContext context)=>Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: navy)));
}
class CardBox extends StatelessWidget {
  final Widget child; const CardBox({required this.child, super.key});
  @override Widget build(BuildContext context)=>Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5EAF1))), child: child);
}
class ShortcutCard extends StatelessWidget {
  final IconData icon; final String title; const ShortcutCard({required this.icon, required this.title, super.key});
  @override Widget build(BuildContext context)=>CardBox(child: Column(children: [Icon(icon, color: blue, size: 28), const SizedBox(height: 8), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600))]));
}
class MetricCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const MetricCard({required this.label, required this.value, required this.icon, required this.color, super.key});
  @override Widget build(BuildContext context)=>CardBox(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: color, size: 26), const SizedBox(height: 10), Text(value, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: navy)),
    Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54))]));
}
class TaskRow extends StatelessWidget {
  final String code, title, subtitle, status; final Color color;
  const TaskRow({required this.code, required this.title, required this.subtitle, required this.status, required this.color, super.key});
  @override Widget build(BuildContext context)=>Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Icon(Icons.assignment_outlined, color: blue, size: 25), const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(code, style: const TextStyle(color: blue, fontSize: 11, fontWeight: FontWeight.bold)),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12))])),
    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)), child: Text(status, style: const TextStyle(fontSize: 10)))]);
}
