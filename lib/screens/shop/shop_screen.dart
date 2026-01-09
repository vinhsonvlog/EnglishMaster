import 'package:flutter/material.dart';
import 'package:englishmaster/services/api_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _items = [];
  bool _isLoading = true;
  int _userGems = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final itemsFuture = _apiService.getShopItems();
      final profileFuture = _apiService.getUserProfile();

      final results = await Future.wait([itemsFuture, profileFuture]);

      if (mounted) {
        setState(() {
          _items = results[0] as List<dynamic>;
          final profile = results[1] as Map<String, dynamic>;
          // Xử lý data user profile linh hoạt
          final userData = profile['data'] ?? profile;

          // Lấy gems, hỗ trợ cả cấu trúc cũ (user.gem) và mới (user.gems.amount)
          if (userData['gems'] is Map) {
            _userGems = userData['gems']['amount'] ?? 0;
          } else {
            _userGems = int.tryParse(userData['gems']?.toString() ?? '') ??
                int.tryParse(userData['gem']?.toString() ?? '') ?? 0;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải shop: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm tiện ích để lấy giá an toàn
  int _getItemPrice(dynamic item) {
    if (item['price'] != null && item['price']['gems'] != null) {
      return int.tryParse(item['price']['gems'].toString()) ?? 0;
    }
    // Fallback cho trường hợp dữ liệu cũ dùng 'cost'
    return int.tryParse(item['cost']?.toString() ?? '0') ?? 0;
  }

  Future<void> _handleBuy(dynamic item) async {
    final int price = _getItemPrice(item);

    if (_userGems < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn không đủ đá quý!")),
      );
      return;
    }

    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("Mua ${item['name']}?"),
        content: Text("Giá: $price đá quý"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Mua")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final result = await _apiService.buyItem(item['_id']);

        if (result.success && result.data == true) {
          setState(() {
            _userGems -= price;
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Mua thành công!"), backgroundColor: Colors.green),
          );
        } else {
          if (!mounted) return;
          // Hiển thị message lỗi cụ thể từ Server (Vd: "Vật phẩm không tồn tại")
          String errorMsg = result.message ?? "Lỗi khi mua vật phẩm";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi kết nối"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Cửa Hàng", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.diamond, color: Colors.blue, size: 20),
                const SizedBox(width: 4),
                Text("$_userGems", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("Cửa hàng đang trống", style: TextStyle(color: Colors.grey, fontSize: 18)),
            TextButton(onPressed: _loadData, child: const Text("Tải lại")),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (c, i) => const Divider(),
        itemBuilder: (context, index) {
          final item = _items[index];
          final int price = _getItemPrice(item); // Lấy giá đã sửa

          return ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: Container(
              width: 60, height: 60,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Image.network(
                ApiService.getValidImageUrl(item['image'] ?? ''),
                errorBuilder: (c,e,s) => const Icon(Icons.shopping_bag, size: 30, color: Colors.orange),
              ),
            ),
            title: Text(item['name'] ?? 'Vật phẩm', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item['description'] ?? '', style: const TextStyle(color: Colors.grey)),
            trailing: ElevatedButton(
              onPressed: () => _handleBuy(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.diamond, size: 16),
                  const SizedBox(width: 4),
                  Text("$price"), // Hiển thị giá
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}