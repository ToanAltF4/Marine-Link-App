import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Thẻ giới thiệu chính sách giá sỉ theo bậc số lượng ở đầu danh sách sản phẩm.
class WholesalePolicyCard extends StatelessWidget {
  final String? categoryName;

  const WholesalePolicyCard({super.key, this.categoryName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F0FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB5DDF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFBFE9F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_offer_outlined,
                  color: Color(0xFF006A7C),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chính sách giá sỉ',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      categoryName == null
                          ? 'Áp dụng cho toàn bộ danh mục hải sản khô'
                          : 'Áp dụng cho các mặt hàng $categoryName',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: TierMiniCard(
                  lineOne: '10-49kg',
                  lineTwo: 'Giá gốc',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TierMiniCard(
                  lineOne: '50-99kg',
                  lineTwo: 'Giảm 5%',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TierMiniCard(
                  lineOne: '100kg+',
                  lineTwo: 'Giảm 10%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ô nhỏ hiển thị một bậc giá sỉ (khoảng khối lượng và mức ưu đãi).
class TierMiniCard extends StatelessWidget {
  final String lineOne;
  final String lineTwo;

  const TierMiniCard({super.key, required this.lineOne, required this.lineTwo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF95CBE5)),
      ),
      child: Column(
        children: [
          Text(
            lineOne,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lineTwo,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
