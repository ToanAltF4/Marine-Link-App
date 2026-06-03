part of 'checkout_bloc.dart';

sealed class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class CheckoutSubmitted extends CheckoutEvent {
  final CheckoutRequest request;
  final Cart activeCart;

  const CheckoutSubmitted({required this.request, required this.activeCart});

  @override
  List<Object?> get props => [request, activeCart];
}
