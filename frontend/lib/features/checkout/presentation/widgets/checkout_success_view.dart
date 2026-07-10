import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/navigation/buyer_navigation.dart';
import '../../../cart/domain/cart_pricing.dart';
import '../../domain/checkout_repository.dart';
import '../../domain/vnpay_payment.dart';
import 'checkout_card.dart';

/// Màn hình kết quả sau khi đặt hàng thành công (bao gồm luồng chờ VNPAY).
class CheckoutSuccessView extends StatefulWidget {
  final CheckoutResult result;

  const CheckoutSuccessView({super.key, required this.result});

  @override
  State<CheckoutSuccessView> createState() => _CheckoutSuccessViewState();
}

class _CheckoutSuccessViewState extends State<CheckoutSuccessView> {
  static const _paymentTimeout = Duration(minutes: 15);

  Timer? _timer;
  Duration _remaining = _paymentTimeout;
  bool _isCancelling = false;
  bool _cancelled = false;

  CheckoutResult get result => widget.result;

  @override
  void initState() {
    super.initState();
    if (result.vnpayPayment != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), _handleTick);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payment = result.vnpayPayment;
    final isVnpay = payment != null;
    final fallbackDiscountRate = CartBulkDiscountPolicy.rateForQuantity(
      result.totalItemCount,
    );
    final fallbackTotal =
        result.subtotalAmount - (result.subtotalAmount * fallbackDiscountRate);
    final totalAmount = result.order.totalAmount > 0
        ? result.order.totalAmount
        : fallbackTotal;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: CheckoutCard(
            key: const Key('checkoutSuccessPanel'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: AppColors.success,
                ),
                const SizedBox(height: 14),
                Text(
                  isVnpay ? 'Chờ thanh toán VNPAY' : 'Đặt hàng thành công',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mã đơn ${result.order.orderCode}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                if (isVnpay) ...[
                  VnpayCountdownPanel(
                    remaining: _remaining,
                    cancelled: _cancelled,
                  ),
                  const SizedBox(height: 18),
                ],
                SuccessMetricRow(
                  label: 'Số lượng',
                  value: '${result.totalItemCount} mục',
                ),
                const Divider(height: 18, color: Color(0xFFEAF0F5)),
                SuccessMetricRow(
                  label: 'Tổng thanh toán',
                  value: MoneyFormatter.format(totalAmount),
                ),
                const SizedBox(height: 20),
                if (payment != null && !_cancelled) ...[
                  FilledButton.icon(
                    key: const Key('checkoutOpenVnpayButton'),
                    onPressed: () => _openVnpay(context),
                    icon: const Icon(Icons.qr_code_2_rounded),
                    label: const Text('Thanh toán qua VNPAY'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const Key('checkoutBackToCartButton'),
                    onPressed: () => context.go(AppRoutes.cart),
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Quay lại giỏ hàng'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const Key('checkoutCancelVnpayButton'),
                    onPressed: _isCancelling
                        ? null
                        : () => _cancelPayment(auto: false),
                    icon: _isCancelling
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close_rounded),
                    label: Text(_isCancelling ? 'Đang hủy' : 'Hủy thanh toán'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (payment != null && _cancelled) ...[
                  OutlinedButton.icon(
                    key: const Key('checkoutBackToCartButton'),
                    onPressed: () => context.go(AppRoutes.cart),
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Về giỏ hàng'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                FilledButton.icon(
                  key: const Key('checkoutViewOrdersButton'),
                  onPressed: () =>
                      GoRouter.maybeOf(context)?.go(AppRoutes.orders),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Xem đơn hàng'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => BuyerNavigation.push(context, AppRoutes.home),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Về trang chủ'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTick(Timer timer) {
    if (_cancelled) {
      timer.cancel();
      return;
    }
    final next = _remaining - const Duration(seconds: 1);
    if (next <= Duration.zero) {
      setState(() => _remaining = Duration.zero);
      timer.cancel();
      _cancelPayment(auto: true);
      return;
    }
    setState(() => _remaining = next);
  }

  Future<void> _openVnpay(BuildContext context) async {
    final payment = result.vnpayPayment;
    if (payment == null) return;
    final uri = Uri.tryParse(payment.paymentUrl);
    if (uri == null ||
        !await launchUrl(
          uri,
          mode: kIsWeb
              ? LaunchMode.platformDefault
              : LaunchMode.externalApplication,
          webOnlyWindowName: kIsWeb ? '_self' : null,
        )) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở VNPAY')),
        );
      }
    }
  }

  Future<void> _cancelPayment({required bool auto}) async {
    final payment = result.vnpayPayment;
    if (payment == null || _isCancelling || _cancelled) return;
    setState(() => _isCancelling = true);
    try {
      final repository = sl<VnpayPaymentRepository>();
      await repository.cancelPayment(orderId: payment.orderId);
      _timer?.cancel();
      if (!mounted) return;
      setState(() {
        _cancelled = true;
        _isCancelling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auto
                ? 'Thanh toán VNPAY đã tự hủy do quá hạn'
                : 'Đã hủy thanh toán VNPAY',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auto
                ? 'Không thể tự hủy thanh toán'
                : 'Không thể hủy thanh toán',
          ),
        ),
      );
    }
  }
}

/// Bảng đếm ngược thời gian hoàn tất thanh toán VNPAY.
class VnpayCountdownPanel extends StatelessWidget {
  final Duration remaining;
  final bool cancelled;

  const VnpayCountdownPanel({
    super.key,
    required this.remaining,
    required this.cancelled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cancelled ? const Color(0xFFFFF1F2) : const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cancelled ? const Color(0xFFFECACA) : const Color(0xFFCFE8FA),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              cancelled ? Icons.cancel_outlined : Icons.timer_outlined,
              color: cancelled ? AppColors.error : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                cancelled
                    ? 'Thanh toán VNPAY đã hủy'
                    : 'Hoàn tất thanh toán trong $minutes:$seconds',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dòng "nhãn — giá trị" trong thẻ kết quả đặt hàng.
class SuccessMetricRow extends StatelessWidget {
  final String label;
  final String value;

  const SuccessMetricRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
