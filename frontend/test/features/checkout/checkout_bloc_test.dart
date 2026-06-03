import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/cart/domain/cart.dart';
import 'package:marinelink/features/checkout/domain/checkout_repository.dart';
import 'package:marinelink/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:marinelink/features/orders/domain/order.dart';

void main() {
  group('CheckoutBloc', () {
    late _FakeCheckoutRepository repository;

    setUp(() {
      repository = _FakeCheckoutRepository();
    });

    blocTest<CheckoutBloc, CheckoutState>(
      'rejects empty active cart before calling repository',
      build: () => CheckoutBloc(checkoutRepository: repository),
      act: (bloc) => bloc.add(
        CheckoutSubmitted(request: _request(), activeCart: const Cart()),
      ),
      expect: () => [
        const CheckoutFailure('\u0110\u01a1n h\u00e0ng c\u1ea7n c\u00f3 \u00edt nh\u1ea5t m\u1ed9t s\u1ea3n ph\u1ea9m'),
      ],
      verify: (_) => expect(repository.createOrderCallCount, 0),
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'creates order from active cart and exposes checkout result',
      build: () => CheckoutBloc(checkoutRepository: repository),
      act: (bloc) => bloc.add(
        CheckoutSubmitted(request: _request(), activeCart: _activeCart()),
      ),
      expect: () => [
        const CheckoutSubmitting(),
        isA<CheckoutSuccess>()
            .having((state) => state.result.order.orderCode, 'orderCode', 'ML-TEST-0001')
            .having((state) => state.result.subtotalAmount, 'subtotal', 180000)
            .having((state) => state.result.totalItemCount, 'itemCount', 2),
      ],
      verify: (_) {
        expect(repository.createOrderCallCount, 1);
        expect(repository.lastRequest?.receiverName, 'Nguyen Van A');
        expect(repository.lastCart?.selectedItems.length, 1);
      },
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'emits failure when repository rejects checkout',
      build: () {
        repository.response = const ApiResponse<CheckoutResult>(
          success: false,
          message: 'Kh\u00f4ng th\u1ec3 t\u1ea1o \u0111\u01a1n h\u00e0ng',
        );
        return CheckoutBloc(checkoutRepository: repository);
      },
      act: (bloc) => bloc.add(
        CheckoutSubmitted(request: _request(), activeCart: _activeCart()),
      ),
      expect: () => [
        const CheckoutSubmitting(),
        const CheckoutFailure('Kh\u00f4ng th\u1ec3 t\u1ea1o \u0111\u01a1n h\u00e0ng'),
      ],
    );
  });
}

CheckoutRequest _request() {
  return const CheckoutRequest(
    receiverName: 'Nguyen Van A',
    receiverPhone: '0912345678',
    shippingAddress: '123 Tran Hung Dao, Can Tho',
    paymentMethod: PaymentMethod.cod,
    note: 'Giao buoi sang',
  );
}

Cart _activeCart() {
  return const Cart(
    items: [
      CartItem(
        productId: 'prod-001',
        productName: 'Muc kho loai 1',
        productImageUrl: '',
        unit: 'kg',
        quantity: 2,
        unitPrice: 90000,
        minOrderQuantity: 2,
        stockQuantity: 10,
      ),
    ],
  );
}

class _FakeCheckoutRepository implements CheckoutRepository {
  int createOrderCallCount = 0;
  CheckoutRequest? lastRequest;
  Cart? lastCart;
  ApiResponse<CheckoutResult>? response;

  @override
  Future<ApiResponse<CheckoutResult>> createOrder({
    required CheckoutRequest request,
    required Cart activeCart,
  }) async {
    createOrderCallCount += 1;
    lastRequest = request;
    lastCart = activeCart;

    return response ??
        ApiResponse<CheckoutResult>(
          success: true,
          message: 'Order created',
          data: CheckoutResult(
            order: Order(
              id: 'order-001',
              orderCode: 'ML-TEST-0001',
              status: OrderStatus.pending,
              totalAmount: activeCart.subtotalAmount,
              createdAt: DateTime(2026, 6, 3),
            ),
            subtotalAmount: activeCart.subtotalAmount,
            totalItemCount: activeCart.totalSelectedItemCount,
          ),
        );
  }
}
