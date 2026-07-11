import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/errors/user_facing_error.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/navigation/buyer_navigation.dart';
import '../../../../shared/widgets/app_back_exit_scope.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../cart/domain/cart.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../orders/domain/order.dart';
import '../../domain/checkout_repository.dart';
import '../../domain/shipping_address.dart';
import '../../domain/shipping_address_repository.dart';
import '../bloc/checkout_bloc.dart';
import '../widgets/checkout_card.dart';
import '../widgets/checkout_header.dart';
import '../widgets/checkout_success_view.dart';
import '../widgets/checkout_summary_card.dart';

class CheckoutScreen extends StatefulWidget {
  final CheckoutRepository? checkoutRepository;
  final ShippingAddressRepository? shippingAddressRepository;

  const CheckoutScreen({
    super.key,
    this.checkoutRepository,
    this.shippingAddressRepository,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _shippingAddressController = TextEditingController();
  final _addressLabelController = TextEditingController();
  final _noteController = TextEditingController();

  late final CheckoutBloc _checkoutBloc;
  late final ShippingAddressRepository _shippingAddressRepository;
  List<ShippingAddress> _shippingAddresses = const [];
  ShippingAddress? _selectedAddress;
  PaymentMethod _paymentMethod = PaymentMethod.cod;
  bool _isLoadingAddresses = false;
  bool _isSavingAddress = false;

  @override
  void initState() {
    super.initState();
    _checkoutBloc = CheckoutBloc(
      checkoutRepository: widget.checkoutRepository ?? sl<CheckoutRepository>(),
    );
    _shippingAddressRepository =
        widget.shippingAddressRepository ?? sl<ShippingAddressRepository>();
    _loadShippingAddresses();
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _shippingAddressController.dispose();
    _addressLabelController.dispose();
    _noteController.dispose();
    _checkoutBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackExitScope(
      onFirstBack: _goBack,
      child: BlocProvider.value(
        value: _checkoutBloc,
        child: BlocConsumer<CheckoutBloc, CheckoutState>(
          listener: _handleCheckoutState,
          builder: (context, checkoutState) {
            return CheckoutScaffold(
              onBack: () => _goBack(context),
              child: _buildBody(context, checkoutState),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CheckoutState checkoutState) {
    if (checkoutState is CheckoutSuccess) {
      return CheckoutSuccessView(result: checkoutState.result);
    }

    final isSubmitting =
        checkoutState is CheckoutSubmitting || _isSavingAddress;
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        final cart = cartState.cart;
        if (!cartState.canCheckout) {
          return AppEmptyState(
            message: AppStrings.cartEmpty,
            actionLabel: AppStrings.chooseProduct,
            icon: Icons.shopping_cart_outlined,
            onAction: () => _goToProducts(context),
          );
        }

        return SingleChildScrollView(
          key: const Key('checkoutScrollView'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  CheckoutSummaryCard(cart: cart),
                  const SizedBox(height: 16),
                  _buildFormCard(context, cart, isSubmitting),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormCard(BuildContext context, Cart cart, bool isSubmitting) {
    final theme = Theme.of(context);

    return CheckoutCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.checkoutReceiverInfoTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _buildAddressBook(context, isSubmitting),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('checkoutAddressLabelField'),
              controller: _addressLabelController,
              decoration: const InputDecoration(
                labelText: AppStrings.addressLabelField,
                prefixIcon: Icon(Icons.bookmark_border_rounded),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('checkoutReceiverNameField'),
              controller: _receiverNameController,
              decoration: const InputDecoration(
                labelText: AppStrings.receiverNameLabel,
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) => Validators.required(
                value,
                fieldName: AppStrings.receiverNameLabel,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('checkoutReceiverPhoneField'),
              controller: _receiverPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: AppStrings.phoneLabel,
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              textInputAction: TextInputAction.next,
              validator: Validators.phone,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('checkoutShippingAddressField'),
              controller: _shippingAddressController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: AppStrings.shippingAddressLabel,
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              textInputAction: TextInputAction.next,
              validator: Validators.address,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('checkoutSaveAddressButton'),
                    onPressed: isSubmitting ? null : _saveCurrentAddress,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      _selectedAddress == null
                          ? AppStrings.saveAddress
                          : AppStrings.update,
                    ),
                  ),
                ),
                if (_selectedAddress != null) ...[
                  const SizedBox(width: 10),
                  IconButton.outlined(
                    key: const Key('checkoutDeleteAddressButton'),
                    onPressed: isSubmitting ? null : _deleteSelectedAddress,
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: AppStrings.deleteAddress,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            Text(
              AppStrings.paymentMethodTitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<PaymentMethod>(
              key: const Key('checkoutPaymentMethodSelector'),
              segments: const [
                ButtonSegment<PaymentMethod>(
                  value: PaymentMethod.cod,
                  icon: Icon(Icons.payments_outlined),
                  label: Text(AppStrings.paymentCod),
                ),
                ButtonSegment<PaymentMethod>(
                  value: PaymentMethod.vnpay,
                  icon: Icon(Icons.qr_code_rounded),
                  label: Text(AppStrings.paymentVnpay),
                ),
              ],
              selected: {_paymentMethod},
              onSelectionChanged: isSubmitting
                  ? null
                  : (selection) {
                      setState(() => _paymentMethod = selection.first);
                    },
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('checkoutNoteField'),
              controller: _noteController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: AppStrings.noteLabel,
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const Key('checkoutSubmitButton'),
              onPressed: isSubmitting ? null : () => _submit(cart),
              icon: isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                isSubmitting ? AppStrings.creatingOrder : AppStrings.placeOrder,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCheckoutState(BuildContext context, CheckoutState state) {
    if (state is CheckoutSuccess) {
      if (!state.result.order.isWaitingForPayment) {
        context.read<CartCubit>().clearCart();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.orderCreated(state.result.order.orderCode)),
        ),
      );
    }

    if (state is CheckoutFailure) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.message)));
    }
  }

  void _submit(Cart cart) {
    if (!_formKey.currentState!.validate()) return;

    _submitWithAddress(cart);
  }

  Future<void> _submitWithAddress(Cart cart) async {
    ShippingAddress? address = _selectedAddress;
    if (address == null) {
      final created = await _createAddressFromForm(forceDefault: true);
      if (created == null) return;
      address = created;
    }

    _checkoutBloc.add(
      CheckoutSubmitted(
        activeCart: cart,
        request: CheckoutRequest(
          receiverName: _receiverNameController.text.trim(),
          receiverPhone: _receiverPhoneController.text.trim(),
          shippingAddress: _shippingAddressController.text.trim(),
          shippingAddressId: address.id,
          paymentMethod: _paymentMethod,
          note: _trimOptional(_noteController.text),
        ),
      ),
    );
  }

  String? _trimOptional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Widget _buildAddressBook(BuildContext context, bool isSubmitting) {
    final theme = Theme.of(context);
    if (_isLoadingAddresses) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    return Column(
      key: const Key('checkoutSavedAddressesSection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.savedAddresses,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              key: const Key('checkoutNewAddressButton'),
              onPressed: isSubmitting ? null : _startNewAddress,
              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
              label: const Text(AppStrings.add),
            ),
          ],
        ),
        if (_shippingAddresses.isEmpty)
          Text(
            AppStrings.noSavedAddress,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else
          DropdownButtonFormField<String>(
            key: ValueKey(
              'checkoutSavedAddressSelector-${_selectedAddress?.id}',
            ),
            initialValue: _selectedAddress?.id,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            items: _shippingAddresses.map((address) {
              return DropdownMenuItem<String>(
                value: address.id,
                child: Text(
                  address.label?.isNotEmpty == true
                      ? address.label!
                      : address.addressLine,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: isSubmitting
                ? null
                : (id) {
                    final address = _shippingAddresses.firstWhere(
                      (item) => item.id == id,
                    );
                    _selectAddress(address);
                  },
          ),
      ],
    );
  }

  Future<void> _loadShippingAddresses() async {
    setState(() => _isLoadingAddresses = true);
    try {
      final response = await _shippingAddressRepository.listAddresses();
      if (!mounted) return;
      final addresses = response.data ?? const <ShippingAddress>[];
      setState(() {
        _shippingAddresses = addresses;
        _isLoadingAddresses = false;
      });
      if (addresses.isNotEmpty) {
        final defaultAddress = addresses.firstWhere(
          (address) => address.isDefault,
          orElse: () => addresses.first,
        );
        _selectAddress(defaultAddress);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingAddresses = false);
      _showMessage(
        userFacingErrorMessage(
          error,
          fallback: AppStrings.shippingAddressLoadFailed,
        ),
      );
    }
  }

  void _selectAddress(ShippingAddress address) {
    setState(() => _selectedAddress = address);
    _addressLabelController.text = address.label ?? '';
    _receiverNameController.text = address.receiverName;
    _receiverPhoneController.text = address.receiverPhone;
    _shippingAddressController.text = address.addressLine;
  }

  void _startNewAddress() {
    setState(() => _selectedAddress = null);
    _addressLabelController.clear();
    _receiverNameController.clear();
    _receiverPhoneController.clear();
    _shippingAddressController.clear();
  }

  Future<void> _saveCurrentAddress() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAddress == null) {
      await _createAddressFromForm(forceDefault: _shippingAddresses.isEmpty);
      return;
    }

    setState(() => _isSavingAddress = true);
    try {
      final response = await _shippingAddressRepository.updateAddress(
        id: _selectedAddress!.id,
        input: _addressInput(isDefault: _selectedAddress!.isDefault),
      );
      if (!mounted) return;
      if (!response.success || response.data == null) {
        _showMessage(
          userFacingResponseMessage(
            response.message,
            fallback: AppStrings.shippingAddressUpdateFailed,
          ),
        );
        return;
      }
      _replaceAddress(response.data!);
      _selectAddress(response.data!);
      _showMessage(AppStrings.shippingAddressSaved);
    } catch (error) {
      if (mounted) {
        _showMessage(
          userFacingErrorMessage(
            error,
            fallback: AppStrings.shippingAddressUpdateFailed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingAddress = false);
    }
  }

  Future<ShippingAddress?> _createAddressFromForm({
    required bool forceDefault,
  }) async {
    setState(() => _isSavingAddress = true);
    try {
      final response = await _shippingAddressRepository.createAddress(
        _addressInput(isDefault: forceDefault),
      );
      if (!mounted) return null;
      if (!response.success || response.data == null) {
        _showMessage(
          userFacingResponseMessage(
            response.message,
            fallback: AppStrings.shippingAddressSaveFailed,
          ),
        );
        return null;
      }
      setState(() {
        _shippingAddresses = [..._shippingAddresses, response.data!];
      });
      _selectAddress(response.data!);
      return response.data!;
    } catch (error) {
      if (mounted) {
        _showMessage(
          userFacingErrorMessage(
            error,
            fallback: AppStrings.shippingAddressSaveFailed,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isSavingAddress = false);
    }
  }

  Future<void> _deleteSelectedAddress() async {
    final address = _selectedAddress;
    if (address == null) return;

    setState(() => _isSavingAddress = true);
    try {
      final response = await _shippingAddressRepository.deleteAddress(
        address.id,
      );
      if (!mounted) return;
      if (!response.success) {
        _showMessage(
          userFacingResponseMessage(
            response.message,
            fallback: AppStrings.shippingAddressDeleteFailed,
          ),
        );
        return;
      }
      final nextAddresses = _shippingAddresses
          .where((item) => item.id != address.id)
          .toList();
      setState(() => _shippingAddresses = nextAddresses);
      if (nextAddresses.isEmpty) {
        _startNewAddress();
      } else {
        _selectAddress(nextAddresses.first);
      }
      _showMessage(AppStrings.shippingAddressDeleted);
    } catch (error) {
      if (mounted) {
        _showMessage(
          userFacingErrorMessage(
            error,
            fallback: AppStrings.shippingAddressDeleteFailed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingAddress = false);
    }
  }

  ShippingAddressInput _addressInput({required bool isDefault}) {
    return ShippingAddressInput(
      label: _trimOptional(_addressLabelController.text),
      receiverName: _receiverNameController.text.trim(),
      receiverPhone: _receiverPhoneController.text.trim(),
      addressLine: _shippingAddressController.text.trim(),
      isDefault: isDefault,
    );
  }

  void _replaceAddress(ShippingAddress address) {
    setState(() {
      _shippingAddresses = _shippingAddresses
          .map((item) => item.id == address.id ? address : item)
          .toList();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goBack(BuildContext context) {
    // The checkout flow is opened from the buyer profile page, so the header
    // back button returns the user to their profile rather than the cart.
    GoRouter.of(context).go(AppRoutes.profile);
  }

  void _goToProducts(BuildContext context) {
    BuyerNavigation.push(context, AppRoutes.productList);
  }
}
