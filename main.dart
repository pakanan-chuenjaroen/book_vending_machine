import 'package:flutter/material.dart';
import 'backend/store_service.dart';
import 'frontend/shop_page.dart';

// สร้าง "หลังบ้าน" ตัวเดียว แล้วส่งให้ทุกหน้าใช้ร่วมกัน
final StoreService store = StoreService();

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ตู้ขายหนังสืออัตโนมัติ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: ShopPage(store: store),
    );
  }
}