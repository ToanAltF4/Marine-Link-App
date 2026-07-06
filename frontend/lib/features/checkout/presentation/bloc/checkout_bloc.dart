// ignore_for_file: prefer_initializing_formals

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_facing_error.dart';
import '../../../cart/domain/cart.dart';
import '../../domain/checkout_repository.dart';

part 'checkout_event.dart';
part 'checkout_state.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final CheckoutRepository _checkoutRepository;

  CheckoutBloc({required CheckoutRepository checkoutRepository})
    : _checkoutRepository = checkoutRepository,
      super(const CheckoutInitial()) {
    on<CheckoutSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    CheckoutSubmitted event,
    Emitter<CheckoutState> emit,
  ) async {
    if (event.activeCart.selectedItems.isEmpty) {
      emit(
        const CheckoutFailure(
          '\u0110\u01a1n h\u00e0ng c\u1ea7n c\u00f3 \u00edt nh\u1ea5t m\u1ed9t s\u1ea3n ph\u1ea9m',
        ),
      );
      return;
    }

    emit(const CheckoutSubmitting());
    try {
      final response = await _checkoutRepository.createOrder(
        request: event.request,
        activeCart: event.activeCart,
      );

      if (!response.success || response.data == null) {
        emit(
          CheckoutFailure(
            userFacingResponseMessage(
              response.message,
              fallback: 'Kh\u00f4ng th\u1ec3 t\u1ea1o \u0111\u01a1n h\u00e0ng',
            ),
          ),
        );
        return;
      }

      emit(CheckoutSuccess(response.data!));
    } catch (error) {
      emit(
        CheckoutFailure(
          userFacingErrorMessage(
            error,
            fallback: 'Kh\u00f4ng th\u1ec3 t\u1ea1o \u0111\u01a1n h\u00e0ng',
          ),
        ),
      );
    }
  }
}
