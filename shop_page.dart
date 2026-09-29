import 'package:flutter/material.dart';
import '../backend/store_service.dart';
import '../models/models.dart';
import 'book_cover.dart';
import 'cart_page.dart';

/// หน้าบ้าน: หน้าเลือกซื้อหนังสือของลูกค้า
class ShopPage extends StatefulWidget {
  final StoreService store;
  const ShopPage({super.key, required this.store});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  String? categoryId; // null = ทุกแนว
  String query = '';

  StoreService get store => widget.store;

  void showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void addToCart(Product p) {
    try {
      store.addToCart(p);
      showMessage('เพิ่ม ${p.name} ลงตะกร้าแล้ว');
    } on StoreException catch (e) {
      showMessage(e.message);
    }
  }

  void openDetail(Product p) {
    final cat = store.categoryOf(p.categoryId);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Chip(avatar: Icon(cat.icon, size: 16, color: cat.color), label: Text(cat.name)),
            const SizedBox(height: 8),
            Text(p.desc),
            const SizedBox(height: 8),
            Text('฿${p.price}  •  ${p.outOfStock ? "สินค้าหมด" : "เหลือ ${p.stock} เล่ม"}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: p.outOfStock
                    ? null
                    : () {
                        Navigator.pop(context);
                        addToCart(p);
                      },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('ใส่ตะกร้า'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder: store เปลี่ยน (สต็อก/ตะกร้า) แล้วหน้านี้วาดใหม่อัตโนมัติ
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final items = store.search(categoryId: categoryId, query: query);
        return Scaffold(
          appBar: AppBar(
            title: const Text('📚 ตู้ขายหนังสืออัตโนมัติ'),
            actions: [
              IconButton(
                tooltip: 'ตะกร้า',
                icon: Badge(
                  isLabelVisible: store.cartCount > 0,
                  label: Text('${store.cartCount}'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CartPage(store: store)),
                ),
              ),
              // 
            ],
          ),
          body: Column(
            children: [
              _buildSearchBox(),
              _buildCategoryBar(),
              Expanded(child: items.isEmpty ? const Center(child: Text('ไม่พบหนังสือ')) : _buildGrid(items)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        onChanged: (v) => setState(() => query = v),
        decoration: const InputDecoration(
          hintText: 'ค้นหาชื่อหนังสือ',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  /// แถบเลือกแนวหนังสือ (เลื่อนซ้าย-ขวาได้)
  Widget _buildCategoryBar() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _categoryChip(null, 'ทั้งหมด', Icons.apps),
          for (final c in store.categories) _categoryChip(c.id, c.name, c.icon),
        ],
      ),
    );
  }

  Widget _categoryChip(String? id, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        selected: categoryId == id,
        onSelected: (_) => setState(() => categoryId = id),
      ),
    );
  }

  Widget _buildGrid(List<Product> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildProductCard(items[i]),
    );
  }

  Widget _buildProductCard(Product p) {
    final cat = store.categoryOf(p.categoryId);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openDetail(p),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: BookCover(product: p, color: cat.color)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(child: Text('฿${p.price}', style: const TextStyle(fontWeight: FontWeight.bold))),
                  IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    onPressed: p.outOfStock ? null : () => addToCart(p),
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}