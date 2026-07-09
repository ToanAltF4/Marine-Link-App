# HƯỚNG DẪN TÁCH UI THÀNH CÁC WIDGET NHỎ TRONG FLUTTER
Tài liệu hướng dẫn dành cho sinh viên phát triển ứng dụng Mobile bằng Flutter
| Môn học / Chủ đề | Flutter UI Development |
|---|---|
| Đối tượng sử dụng | Sinh viên thực hành project Mobile Application Development |
| Mục tiêu tài liệu | Hiểu lý do, nguyên tắc và cách tách giao diện Flutter thành các widget nhỏ, dễ bảo trì và dễ tái sử dụng. |

| Ý tưởng cốt lõi Một màn hình Flutter không nên là một khối code lớn. Nên chia màn hình thành nhiều widget nhỏ, mỗi widget phụ trách một phần giao diện hoặc một chức năng rõ ràng. |
|---|

# 1. Khái niệm: Tách UI thành các widget nhỏ là gì?
Trong Flutter, “tách UI thành các widget nhỏ” nghĩa là không viết toàn bộ giao diện trong một hàm build() quá dài, mà chia màn hình thành nhiều widget con. Mỗi widget con phụ trách một khu vực hoặc một chức năng cụ thể.
ProductDetailScreen
 ├── ProductImage
 ├── ProductInfo
 ├── PriceSection
 ├── ColorSelector
 ├── QuantitySelector
 └── AddToCartButton
Cách làm này giúp code dễ đọc, dễ sửa, dễ tái sử dụng và dễ kiểm thử hơn.
# 2. Vì sao cần tách UI thành widget nhỏ?
Ví dụ dưới đây viết toàn bộ màn hình chi tiết sản phẩm trong một hàm build(). Code vẫn chạy được, nhưng khi màn hình phức tạp hơn, việc bảo trì sẽ khó khăn.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết sản phẩm")),
      body: Column(
        children: [
          Image.network("https://example.com/iphone.jpg", height: 250),
          const Text(
            "iPhone 15 Pro Max",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text(
            "35.000.000đ",
            style: TextStyle(fontSize: 22, color: Colors.red),
          ),
          const Text("Điện thoại cao cấp của Apple với chip A17 Pro..."),
          ElevatedButton(
            onPressed: () {},
            child: const Text("Thêm vào giỏ hàng"),
          ),
        ],
      ),
    );
  }
}
Các vấn đề thường gặp khi không tách widget:
• Hàm build() quá dài và khó đọc.
• Khó tìm đúng phần cần sửa khi giao diện thay đổi.
• Khó tái sử dụng cùng một thành phần UI ở màn hình khác.
• Khó chia việc cho nhiều thành viên trong nhóm.
• Khó quản lý state khi màn hình có nhiều phần tương tác.
# 3. Nguyên tắc tách widget
## 3.1. Tách theo khu vực giao diện
Một màn hình nên được chia theo các vùng giao diện có ý nghĩa rõ ràng.
Ảnh sản phẩm        → ProductImage
Tên, giá, mô tả     → ProductInfo
Nút thêm giỏ hàng   → AddToCartButton
## 3.2. Tách theo chức năng
Với màn hình đăng nhập, mỗi thành phần có thể đảm nhận một chức năng riêng.
Ô nhập email        → EmailInput
Ô nhập mật khẩu     → PasswordInput
Nút đăng nhập       → LoginButton
Link quên mật khẩu  → ForgotPasswordLink
## 3.3. Tách phần lặp lại
Nếu nhiều màn hình đều dùng chung một kiểu card sản phẩm, nên tạo widget riêng như ProductCard, sau đó tái sử dụng ở Home, Search, Favorite hoặc Cart.
# 4. Ví dụ: Trước khi tách widget
Màn hình danh sách sản phẩm dưới đây viết trực tiếp Card và ListTile bên trong itemBuilder. Nếu sau này thêm giảm giá, đánh giá sao, nút yêu thích hoặc trạng thái còn hàng, itemBuilder sẽ rất rối.
import 'package:flutter/material.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = [
      {
        'name': 'iPhone 15 Pro Max',
        'price': '35.000.000đ',
        'image': 'https://example.com/iphone.jpg',
      },
      {
        'name': 'Samsung Galaxy S24 Ultra',
        'price': '28.000.000đ',
        'image': 'https://example.com/samsung.jpg',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách sản phẩm')),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              leading: Image.network(product['image']!, width: 60, height: 60, fit: BoxFit.cover),
              title: Text(product['name']!),
              subtitle: Text(product['price']!),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}
# 5. Ví dụ: Sau khi tách thành widget nhỏ
Ta tách phần hiển thị từng sản phẩm thành widget riêng ProductCard. Khi đó ProductListScreen chỉ còn nhiệm vụ quản lý màn hình danh sách, còn ProductCard phụ trách giao diện của một sản phẩm.
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = [
      {'name': 'iPhone 15 Pro Max', 'price': '35.000.000đ', 'image': 'https://example.com/iphone.jpg'},
      {'name': 'Samsung Galaxy S24 Ultra', 'price': '28.000.000đ', 'image': 'https://example.com/samsung.jpg'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách sản phẩm')),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            name: product['name']!,
            price: product['price']!,
            imageUrl: product['image']!,
            onTap: () {
              // Chuyển sang màn hình chi tiết sản phẩm
            },
          );
        },
      ),
    );
  }
}
class ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String imageUrl;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        leading: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
        title: Text(name),
        subtitle: Text(price),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
# 6. Ví dụ tách UI trong màn hình Login
## 6.1. Cách viết chưa tốt
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Đăng nhập", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(obscureText: true, decoration: const InputDecoration(labelText: "Mật khẩu", border: OutlineInputBorder())),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () {}, child: const Text("Đăng nhập")),
          ],
        ),
      ),
    );
  }
}
## 6.2. Cách viết tốt hơn
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            LoginTitle(),
            SizedBox(height: 24),
            EmailInput(),
            SizedBox(height: 16),
            PasswordInput(),
            SizedBox(height: 24),
            LoginButton(),
          ],
        ),
      ),
    );
  }
}
class LoginTitle extends StatelessWidget {
  const LoginTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      "Đăng nhập",
      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    );
  }
}

class EmailInput extends StatelessWidget {
  const EmailInput({super.key});

  @override
  Widget build(BuildContext context) {
    return const TextField(
      decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder()),
    );
  }
}

class PasswordInput extends StatelessWidget {
  const PasswordInput({super.key});

  @override
  Widget build(BuildContext context) {
    return const TextField(
      obscureText: true,
      decoration: InputDecoration(labelText: "Mật khẩu", border: OutlineInputBorder()),
    );
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      child: const Text("Đăng nhập"),
    );
  }
}
# 7. Khi nào nên tạo widget riêng?
Nên tách widget khi một phần UI có nhiều dòng code, được dùng lại ở nhiều nơi, có chức năng riêng, có state riêng hoặc làm cho hàm build() của màn hình quá dài.
• ProductCard: hiển thị một sản phẩm.
• SearchBarWidget: hiển thị ô tìm kiếm.
• CategoryChip: hiển thị một danh mục hoặc thể loại.
• CartItem: hiển thị một sản phẩm trong giỏ hàng.
• OrderSummary: hiển thị tổng tiền đơn hàng.
• LoginForm: hiển thị form đăng nhập.
Không nhất thiết phải tách những widget quá đơn giản chỉ dùng một lần, ví dụ const SizedBox(height: 16) hoặc const Text("Xin chào").
# 8. Tách thành method hay tách thành widget class?
## 8.1. Tách thành method
Cách này nhanh, phù hợp với UI nhỏ hoặc phần giao diện chỉ dùng trong một màn hình.
Widget buildTitle() {
  return const Text(
    "Đăng nhập",
    style: TextStyle(fontSize: 28),
  );
}
## 8.2. Tách thành widget class
Cách này chuyên nghiệp hơn, dễ tái sử dụng, dễ test và phù hợp với project lớn.
class LoginTitle extends StatelessWidget {
  const LoginTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      "Đăng nhập",
      style: TextStyle(fontSize: 28),
    );
  }
}
| Khuyến nghị Với project môn học, sinh viên nên ưu tiên tách thành widget class đối với các phần UI quan trọng như ProductCard, LoginForm, CartItem, SearchBarWidget hoặc OrderSummary. |
|---|

# 9. Gợi ý cấu trúc thư mục
Với app bán điện thoại, có thể tổ chức thư mục theo feature để mỗi màn hình và mỗi nhóm widget được quản lý rõ ràng.
lib/
  features/
    product/
      screens/
        product_list_screen.dart
        product_detail_screen.dart
      widgets/
        product_card.dart
        product_image.dart
        product_price.dart
        product_rating.dart

    auth/
      screens/
        login_screen.dart
      widgets/
        login_title.dart
        email_input.dart
        password_input.dart
        login_button.dart

    cart/
      screens/
        cart_screen.dart
      widgets/
        cart_item.dart
        order_summary.dart
# 10. Ví dụ hoàn chỉnh: Màn hình chi tiết sản phẩm
## 10.1. File product_detail_screen.dart
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const productName = "iPhone 15 Pro Max";
    const productPrice = "35.000.000đ";
    const productDescription =
        "Điện thoại cao cấp của Apple với chip A17 Pro, camera chất lượng cao và thiết kế sang trọng.";
    const imageUrl = "https://example.com/iphone.jpg";

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết sản phẩm")),
      body: SingleChildScrollView(
        child: Column(
          children: const [
            ProductImage(imageUrl: imageUrl),
            SizedBox(height: 16),
            ProductInfo(name: productName, price: productPrice, description: productDescription),
            SizedBox(height: 24),
            AddToCartButton(),
          ],
        ),
      ),
    );
  }
}
## 10.2. Widget ProductImage
class ProductImage extends StatelessWidget {
  final String imageUrl;

  const ProductImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      height: 260,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}
## 10.3. Widget ProductInfo
class ProductInfo extends StatelessWidget {
  final String name;
  final String price;
  final String description;

  const ProductInfo({
    super.key,
    required this.name,
    required this.price,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(price, style: const TextStyle(fontSize: 22, color: Colors.red, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
## 10.4. Widget AddToCartButton
class AddToCartButton extends StatelessWidget {
  const AddToCartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Đã thêm sản phẩm vào giỏ hàng")),
            );
          },
          child: const Text("Thêm vào giỏ hàng"),
        ),
      ),
    );
  }
}
# 11. Lỗi thường gặp khi tách widget
## 11.1. Tách quá nhỏ
Không nên tách mọi Text hoặc SizedBox nhỏ thành class riêng nếu chúng chỉ dùng một lần và không có ý nghĩa nghiệp vụ rõ ràng.
## 11.2. Widget con phụ thuộc quá nhiều vào widget cha
Nếu widget con phải nhận quá nhiều biến, nên cân nhắc truyền một model thay vì truyền từng thuộc tính riêng lẻ.
// Nên cân nhắc dùng model nếu tham số quá nhiều
ProductCard(product: product)
## 11.3. Đặt quá nhiều logic xử lý trong UI widget
Widget nên tập trung vào hiển thị. Các xử lý phức tạp như gọi API, tính toán giá, kiểm tra đăng nhập nên đặt ở service, provider, bloc hoặc controller.
# 12. Kết luận
“Tách UI thành các widget nhỏ” là kỹ thuật quan trọng trong Flutter. Sinh viên nên hiểu rằng một màn hình không nên là một khối code lớn, mà nên được chia thành nhiều thành phần nhỏ, rõ trách nhiệm.

| Nguyên tắc dễ nhớ Một widget chỉ nên làm một việc rõ ràng. |
|---|

Trong project Flutter, tách UI tốt sẽ giúp nhóm code nhanh hơn, ít lỗi hơn, dễ chia việc hơn và dễ bảo trì hơn.