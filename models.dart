import 'package:flutter/material.dart';

/// หมวดหมู่หนังสือ (แนว)
class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  const Category(this.id, this.name, this.icon, this.color);
}

/// สินค้า 1 รายการ
class Product {
  final String id;
  String name;
  String categoryId;
  String desc;
  int price;
  int stock;
  String imageUrl; // ลิงก์รูปปก ไม่มีใช้สีแทนดิวะ

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.desc,
    required this.price,
    required this.stock,
    this.imageUrl = '',
  });

  bool get outOfStock => stock <= 0;
}

/// สินค้าในตะกร้า
class CartItem {
  final Product product;
  int qty;
  CartItem(this.product, this.qty);

  int get total => product.price * qty;
}

/// บรรทัดในออเดอร์ (เก็บชื่อ/ราคา ณ ตอนซื้อ)
class OrderLine {
  final String name;
  final int price;
  final int qty;
  const OrderLine(this.name, this.price, this.qty);

  int get total => price * qty;
}

/// ออเดอร์ที่ชำระเงินแล้ว
class Order {
  final int id;
  final DateTime time;
  final List<OrderLine> lines;
  final String method; // จ่ายด้วยอะไรวะเห้ยยยยยยยย
  final int paid;

  const Order({
    required this.id,
    required this.time,
    required this.lines,
    required this.method,
    required this.paid,
  });

  int get total => lines.fold(0, (sum, l) => sum + l.total);
  int get change => paid - total;
  int get itemCount => lines.fold(0, (sum, l) => sum + l.qty);
}