import 'package:flutter/material.dart';
import '../models/models.dart';

/// ปกหนังสือมีรูปก็แสดงรูป ถ้าไม่มี/โหลดไม่ได้ ก็แสดงปกสีพร้อมชื่อเล่ม
class BookCover extends StatelessWidget {
  final Product product;
  final Color color;
  const BookCover({super.key, required this.product, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (product.imageUrl.isEmpty)
          _colorCover()
        else if (product.imageUrl.startsWith('assets/'))
          // รูปที่เก็บในโปรเจกต์ (ไม่ต้องใช้เน็ต)
          Image.asset(product.imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stack) => _colorCover())
        else
          Image.network(
            product.imageUrl,
            fit: BoxFit.cover,
            // ระหว่างโหลด
            loadingBuilder: (context, child, progress) => progress == null ? child : Container(color: color.withValues(alpha: 0.3), child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
            // โหลดไม่สำเร็จ -> ปกสี
            errorBuilder: (context, error, stack) => _colorCover(),
          ),
        if (product.outOfStock)
          Container(color: Colors.black54, child: const Center(child: Chip(label: Text('หมด')))),
      ],
    );
  }

  Widget _colorCover() {
    return Container(
      color: color,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(product.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}