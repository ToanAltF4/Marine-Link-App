import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/orders/data/order_dto.dart';
import 'package:marinelink/features/orders/domain/order.dart';

void main() {
  group('Order DTOs', () {
    test('maps order list JSON to domain order', () {
      final orders = orderListFromJson([
        {
          'id': '550e8400-e29b-41d4-a716-446655440102',
          'orderCode': 'ML-20260604-0002',
          'status': 'SHIPPING',
          'paymentMethod': 'BANK_TRANSFER',
          'paymentStatus': 'PAID',
          'totalAmount': 1250000,
          'createdAt': '2026-06-04T02:00:00Z',
        },
      ]);

      expect(orders, hasLength(1));
      expect(orders.single.orderCode, 'ML-20260604-0002');
      expect(orders.single.status, OrderStatus.shipping);
      expect(orders.single.paymentMethod, PaymentMethod.bankTransfer);
      expect(orders.single.paymentStatus, 'PAID');
      expect(orders.single.totalAmount, 1250000);
    });

    test('labels unpaid bank and VNPAY orders as waiting for payment', () {
      final bankOrder = Order(
        id: 'order-001',
        orderCode: 'ML-20260615-0001',
        status: OrderStatus.pending,
        paymentMethod: PaymentMethod.bankTransfer,
        paymentStatus: 'PENDING',
        totalAmount: 850000,
        createdAt: DateTime(2026, 6, 15),
      );
      final paidVnpayOrder = Order(
        id: 'order-002',
        orderCode: 'ML-20260615-0002',
        status: OrderStatus.pending,
        paymentMethod: PaymentMethod.vnpay,
        paymentStatus: 'PAID',
        totalAmount: 850000,
        createdAt: DateTime(2026, 6, 15),
      );

      expect(bankOrder.displayStatusLabel, 'Chờ thanh toán');
      expect(paidVnpayOrder.displayStatusLabel, 'Chờ duyệt');
    });

    test('maps order detail JSON with items and timeline', () {
      final order = orderDetailFromJson({
        'id': '550e8400-e29b-41d4-a716-446655440103',
        'orderCode': 'ML-20260604-0003',
        'status': 'PENDING',
        'paymentMethod': 'BANK_TRANSFER',
        'paymentStatus': 'UNPAID',
        'receiverName': 'Nguyen Van A',
        'receiverPhone': '0912345678',
        'shippingAddress': 'Can Tho',
        'subtotalAmount': 850000,
        'shippingFee': 0,
        'discountAmount': 0,
        'totalAmount': 850000,
        'note': 'Giao buoi sang',
        'createdAt': '2026-06-04T03:00:00Z',
        'items': [
          {
            'productId': '550e8400-e29b-41d4-a716-446655440203',
            'productNameSnapshot': 'Muc kho loai 1',
            'productUnitSnapshot': 'kg',
            'productImageUrl': 'https://example.com/muc.png',
            'unitPrice': 425000,
            'quantity': 2,
            'lineTotal': 850000,
          },
        ],
        'statusHistory': [
          {
            'fromStatus': null,
            'toStatus': 'PENDING',
            'note': 'Order created',
            'createdAt': '2026-06-04T03:00:00Z',
          },
        ],
      });

      expect(order.orderCode, 'ML-20260604-0003');
      expect(order.paymentMethod, PaymentMethod.bankTransfer);
      expect(order.items.single.productNameSnapshot, 'Muc kho loai 1');
      expect(order.items.single.productImageUrl, 'https://example.com/muc.png');
      expect(order.items.single.lineTotal, 850000);
      expect(order.statusHistory.single.toStatus, 'PENDING');
    });

    test('maps VNPAY payment method', () {
      expect(PaymentMethod.fromString('VNPAY'), PaymentMethod.vnpay);
      expect(PaymentMethod.vnpay.apiValue, 'VNPAY');
      expect(PaymentMethod.vnpay.displayLabel, 'VNPAY QR');
    });
  });
}
