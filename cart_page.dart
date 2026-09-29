import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../backend/promptpay.dart';
import '../backend/store_service.dart';
import '../models/models.dart';

/// หน้าตะกร้า + ชำระเงิน (เงินสด / QR)
class CartPage extends StatefulWidget {
  final StoreService store;
  const CartPage({super.key, required this.store});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final cashController = TextEditingController();
  bool payByQr = false;

  StoreService get store => widget.store;

  @override
  void dispose() {
    cashController.dispose();
    super.dispose();
  }

  void pay() {
    try {
      final order = store.checkout(byQr: payByQr, cash: int.tryParse(cashController.text) ?? 0);
      showReceipt(order);
    } on StoreException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void showReceipt(Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('ชำระเงินสำเร็จ (ออเดอร์ #${order.id})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final l in order.lines) Text('${l.name} x${l.qty}  ฿${l.total}'),
            const Divider(),
            Text('รวม ฿${order.total}  (${order.method})'),
            if (order.change > 0) Text('เงินทอน ฿${order.change}'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // ปิดใบเสร็จ
              Navigator.pop(context); // กลับหน้าร้าน
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final cart = store.cart;
        return Scaffold(
          appBar: AppBar(title: const Text('ตะกร้าของฉัน')),
          body: cart.isEmpty
              ? const Center(child: Text('ยังไม่มีสินค้าในตะกร้า'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(children: [for (final c in cart) _buildCartRow(c)]),
                    ),
                    _buildPaymentBox(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildCartRow(CartItem c) {
    return ListTile(
      title: Text(c.product.name),
      subtitle: Text('฿${c.product.price} x ${c.qty} = ฿${c.total}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => store.decreaseFromCart(c.product)),
          Text('${c.qty}'),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              try {
                store.addToCart(c.product);
              } on StoreException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBox() {
    return Material(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('รวมทั้งหมด ฿${store.cartTotal}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('เงินสด'), icon: Icon(Icons.payments_outlined)),
                ButtonSegment(value: true, label: Text('QR'), icon: Icon(Icons.qr_code)),
              ],
              selected: {payByQr},
              onSelectionChanged: (s) => setState(() => payByQr = s.first),
            ),
            const SizedBox(height: 12),
            if (payByQr)
              Column(children: [
                QrImageView(
                  data: promptPayPayload(StoreService.promptPayId, amount: store.cartTotal.toDouble()),
                  size: 200,
                ),
                Text('สแกนด้วยแอปธนาคาร ยอด ฿${store.cartTotal}', style: const TextStyle(fontSize: 12)),
              ])
            else
              TextField(
                controller: cashController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'จำนวนเงินที่ใส่ (บาท)', border: OutlineInputBorder()),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: pay, child: Text(payByQr ? 'ฉันจ่ายแล้ว' : 'ยืนยันการชำระเงิน')),
            ),
          ],
        ),
      ),
    );
  }
}