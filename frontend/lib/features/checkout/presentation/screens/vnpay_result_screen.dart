import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';

class VnpayResultScreen extends StatefulWidget {
  final Map<String, String> queryParameters;

  const VnpayResultScreen({super.key, required this.queryParameters});

  @override
  State<VnpayResultScreen> createState() => _VnpayResultScreenState();
}

class _VnpayResultScreenState extends State<VnpayResultScreen> {
  bool _cartCleared = false;

  bool get _success {
    final success = widget.queryParameters['success'];
    final paymentStatus = widget.queryParameters['paymentStatus'];
    return success == 'true' || paymentStatus == 'PAID';
  }

  String? get _orderCode => widget.queryParameters['orderCode'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_success || _cartCleared) return;
      _cartCleared = true;
      context.read<CartCubit>().clearCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _success
        ? 'Thanh toán VNPAY thành công'
        : 'Thanh toán VNPAY chưa hoàn tất';
    final message = _success
        ? 'Đơn hàng ${_orderCode ?? ''} đã ghi nhận thanh toán và sẽ được duyệt trong thời gian sớm nhất.'
        : 'Giao dịch chưa thành công hoặc đã bị hủy. Bạn có thể quay lại giỏ hàng để thử lại.';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE4EEF5)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14052449),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        _success
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        size: 64,
                        color: _success ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ResultDetailRow(
                        label: 'Mã đơn',
                        value: _orderCode ?? '-',
                      ),
                      _ResultDetailRow(
                        label: 'Trạng thái',
                        value: widget.queryParameters['paymentStatus'] ?? '-',
                      ),
                      _ResultDetailRow(
                        label: 'Mã phản hồi',
                        value: widget.queryParameters['responseCode'] ?? '-',
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.orders),
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('Xem đơn hàng'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => context.go(
                          _success ? AppRoutes.home : AppRoutes.cart,
                        ),
                        icon: Icon(
                          _success
                              ? Icons.home_outlined
                              : Icons.shopping_cart_outlined,
                        ),
                        label: Text(_success ? 'Về trang chủ' : 'Về giỏ hàng'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
