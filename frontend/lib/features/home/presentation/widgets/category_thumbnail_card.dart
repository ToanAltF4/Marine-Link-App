import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../products/domain/product.dart';
import '../../../products/presentation/widgets/product_visuals.dart';

/// Tóm tắt một danh mục sản phẩm hiển thị ở trang chủ (kèm ảnh xem trước).
class HomeCategorySummary {
  final Category category;
  final String? previewPath;

  const HomeCategorySummary({
    required this.category,
    required this.previewPath,
  });
}

/// Thẻ hình thu nhỏ của một danh mục trong dải danh mục ngang ở trang chủ.
class CategoryThumbnailCard extends StatelessWidget {
  final HomeCategorySummary summary;
  final VoidCallback onTap;

  const CategoryThumbnailCard({
    super.key,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final previewProvider = _imageProvider(summary.previewPath);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12052449),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
                image: previewProvider != null
                    ? DecorationImage(image: previewProvider, fit: BoxFit.cover)
                    : null,
              ),
              child: previewProvider == null
                  ? Icon(
                      categorySymbolIcon(summary.category.id),
                      color: const Color(0xFF006A7C),
                      size: 28,
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              displayCategoryName(summary.category),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider<Object>? _imageProvider(String? path) {
    if (path == null || path.isEmpty) {
      return null;
    }
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return null;
  }
}
