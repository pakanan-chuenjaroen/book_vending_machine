import 'package:flutter/material.dart';
import '../models/models.dart';
import 'seed_data.dart';

/// ข้อผิดพลาดที่ต้องการแสดงให้ผู้ใช้อ่าน 
class StoreException implements Exception {
  final String message;
  StoreException(this.message);
}


class StoreService extends ChangeNotifier {
  static const String adminPin = '1234'; // รหัสเข้าหลังบ้าน
  // พร้อมเพย์ของร้าน (เบอร์โทร 10 หลัก หรือเลข 13 หลัก) 
  static const String promptPayId = '0935453038';

  // ---------- ข้อมูล ----------
  final List<Category> categories = const [
    Category('thai', 'วรรณกรรมไทย', Icons.local_library, Colors.red),
    Category('novel', 'นิยาย', Icons.favorite, Colors.pink),
    Category('fantasy', 'แฟนตาซี', Icons.auto_awesome, Colors.deepPurple),
    Category('mystery', 'สืบสวน', Icons.search, Colors.teal),
    Category('self', 'พัฒนาตนเอง', Icons.psychology, Color(0xFF0E7490)),
    Category('science', 'ความรู้/วิทย์', Icons.science, Colors.green),
    Category('scifi', 'ไซไฟ', Icons.rocket_launch, Colors.blue),
    Category('business', 'ธุรกิจ/การเงิน', Icons.trending_up, Color(0xFFB45309)),
    Category('comic', 'การ์ตูน/มังงะ', Icons.emoji_emotions, Colors.cyan),
    Category('kids', 'เด็ก', Icons.child_care, Colors.orange),
  ];

  // คลังสินค้าเริ่มต้นอยู่ในไฟล์ seed_data.dart
  final List<Product> _products = buildSeedProducts();

  final List<CartItem> _cart = [];
  final List<Order> _orders = [];
  int _nextOrderId = 1;

  // ---------- อ่านข้อมูล (หน้าบ้านใช้) ----------
  List<Product> get products => List.unmodifiable(_products);
  List<CartItem> get cart => List.unmodifiable(_cart);
  List<Order> get orders => List.unmodifiable(_orders);

  Category categoryOf(String id) => categories.firstWhere((c) => c.id == id);

  /// ค้นหาสินค้า: กรองตามแนว (null = ทุกแนว) และคำค้น
  List<Product> search({String? categoryId, String query = ''}) {
    final q = query.trim().toLowerCase();
    return _products.where((p) {
      final okCategory = categoryId == null || p.categoryId == categoryId;
      final okQuery = q.isEmpty || p.name.toLowerCase().contains(q);
      return okCategory && okQuery;
    }).toList();
  }

  // ---------- ตะกร้า ----------
  int get cartCount => _cart.fold(0, (s, c) => s + c.qty);
  int get cartTotal => _cart.fold(0, (s, c) => s + c.total);

  void addToCart(Product p) {
    if (p.outOfStock) throw StoreException('${p.name} หมดแล้ว');
    final index = _cart.indexWhere((c) => c.product.id == p.id);
    final inCart = index == -1 ? 0 : _cart[index].qty;
    if (inCart >= p.stock) throw StoreException('${p.name} เหลือแค่ ${p.stock} เล่ม');
    if (index == -1) {
      _cart.add(CartItem(p, 1));
    } else {
      _cart[index].qty++;
    }
    notifyListeners();
  }

  void decreaseFromCart(Product p) {
    final index = _cart.indexWhere((c) => c.product.id == p.id);
    if (index == -1) return;
    _cart[index].qty--;
    if (_cart[index].qty <= 0) _cart.removeAt(index);
    notifyListeners();
  }

  // ---------- ชำระเงิน ----------
  /// ชำระเงินทั้งตะกร้า: ตรวจเงิน/สต็อก -> ตัดสต็อก -> สร้างออเดอร์
  Order checkout({required bool byQr, int cash = 0}) {
    if (_cart.isEmpty) throw StoreException('ตะกร้าว่างเปล่า');
    final total = cartTotal;
    if (!byQr && cash < total) throw StoreException('เงินไม่พอ (ขาดอีก ${total - cash} บาท)');
    for (final c in _cart) {
      if (c.qty > c.product.stock) throw StoreException('${c.product.name} เหลือไม่พอ');
    }

    for (final c in _cart) {
      c.product.stock -= c.qty; // ตัดสต็อก
    }
    final order = Order(
      id: _nextOrderId++,
      time: DateTime.now(),
      lines: _cart.map((c) => OrderLine(c.product.name, c.product.price, c.qty)).toList(),
      method: byQr ? 'QR' : 'เงินสด',
      paid: byQr ? total : cash,
    );
    _orders.insert(0, order);
    _cart.clear();
    notifyListeners();
    return order;
  }

  // ---------- หลังบ้าน (แอดมิน) ----------
  bool verifyPin(String pin) => pin == adminPin;

  /// เพิ่มสินค้าใหม่ หรือแก้ไขสินค้าเดิม (ดูจาก id)
  void saveProduct(Product p) {
    final index = _products.indexWhere((x) => x.id == p.id);
    if (index == -1) {
      _products.add(p);
    } else {
      _products[index] = p;
    }
    _cart.removeWhere((c) => c.product.id == p.id && c.qty > p.stock);
    notifyListeners();
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    _cart.removeWhere((c) => c.product.id == id);
    notifyListeners();
  }

  void restock(Product p, int amount) {
    p.stock += amount;
    notifyListeners();
  }

  String newProductId() => 'p${DateTime.now().millisecondsSinceEpoch}';

  // ---------- สรุปยอด ----------
  int get totalRevenue => _orders.fold(0, (s, o) => s + o.total);
  int get totalSold => _orders.fold(0, (s, o) => s + o.itemCount);
  List<Product> get lowStock => _products.where((p) => p.stock <= 2).toList();
}