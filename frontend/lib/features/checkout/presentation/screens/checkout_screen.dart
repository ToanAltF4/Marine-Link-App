import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_back_exit_scope.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../cart/domain/cart.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../orders/domain/order.dart';
import '../../domain/checkout_repository.dart';
import '../../domain/shipping_address.dart';
import '../../domain/shipping_address_repository.dart';
import '../bloc/checkout_bloc.dart';

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
            return _CheckoutScaffold(
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
      return _CheckoutSuccessView(result: checkoutState.result);
    }

    final isSubmitting =
        checkoutState is CheckoutSubmitting || _isSavingAddress;
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        final cart = cartState.cart;
        if (!cartState.canCheckout) {
          return AppEmptyState(
            message: 'Gi\u1ecf h\u00e0ng \u0111ang tr\u1ed1ng',
            actionLabel: 'Ch\u1ecdn s\u1ea3n ph\u1ea9m',
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
                  _CheckoutSummaryCard(cart: cart),
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

    return _CheckoutCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Th\u00f4ng tin nh\u1eadn h\u00e0ng',
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
                labelText: 'T\u00ean g\u1ee3i nh\u1edb',
                prefixIcon: Icon(Icons.bookmark_border_rounded),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('checkoutReceiverNameField'),
              controller: _receiverNameController,
              decoration: const InputDecoration(
                labelText: 'Ng\u01b0\u1eddi nh\u1eadn',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) => Validators.required(
                value,
                fieldName: 'Ng\u01b0\u1eddi nh\u1eadn',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('checkoutReceiverPhoneField'),
              controller: _receiverPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'S\u1ed1 \u0111i\u1ec7n tho\u1ea1i',
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
                labelText: '\u0110\u1ecba ch\u1ec9 giao h\u00e0ng',
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
                          ? 'L\u01b0u \u0111\u1ecba ch\u1ec9'
                          : 'C\u1eadp nh\u1eadt',
                    ),
                  ),
                ),
                if (_selectedAddress != null) ...[
                  const SizedBox(width: 10),
                  IconButton.outlined(
                    key: const Key('checkoutDeleteAddressButton'),
                    onPressed: isSubmitting ? null : _deleteSelectedAddress,
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'X\u00f3a \u0111\u1ecba ch\u1ec9',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Ph\u01b0\u01a1ng th\u1ee9c thanh to\u00e1n',
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
                  label: Text('COD'),
                ),
                ButtonSegment<PaymentMethod>(
                  value: PaymentMethod.bankTransfer,
                  icon: Icon(Icons.account_balance_outlined),
                  label: Text('Chuy\u1ec3n kho\u1ea3n'),
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
                labelText: 'Ghi ch\u00fa',
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
                isSubmitting
                    ? '\u0110ang t\u1ea1o \u0111\u01a1n'
                    : '\u0110\u1eb7t h\u00e0ng',
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
      context.read<CartCubit>().clearCart();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '\u0110\u00e3 t\u1ea1o \u0111\u01a1n ${state.result.order.orderCode}',
          ),
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
                '\u0110\u1ecba ch\u1ec9 \u0111\u00e3 l\u01b0u',
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
              label: const Text('Th\u00eam'),
            ),
          ],
        ),
        if (_shippingAddresses.isEmpty)
          Text(
            'Ch\u01b0a c\u00f3 \u0111\u1ecba ch\u1ec9. \u0110\u1eb7t h\u00e0ng l\u1ea7n \u0111\u1ea7u s\u1ebd t\u1ef1 l\u01b0u.',
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingAddresses = false);
      _showMessage(
        'Kh\u00f4ng th\u1ec3 t\u1ea3i \u0111\u1ecba ch\u1ec9 giao h\u00e0ng',
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
          response.message ??
              'Kh\u00f4ng th\u1ec3 c\u1eadp nh\u1eadt \u0111\u1ecba ch\u1ec9',
        );
        return;
      }
      _replaceAddress(response.data!);
      _selectAddress(response.data!);
      _showMessage(
        '\u0110\u00e3 l\u01b0u \u0111\u1ecba ch\u1ec9 giao h\u00e0ng',
      );
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Kh\u00f4ng th\u1ec3 c\u1eadp nh\u1eadt \u0111\u1ecba ch\u1ec9',
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
          response.message ??
              'Kh\u00f4ng th\u1ec3 l\u01b0u \u0111\u1ecba ch\u1ec9 giao h\u00e0ng',
        );
        return null;
      }
      setState(() {
        _shippingAddresses = [..._shippingAddresses, response.data!];
      });
      _selectAddress(response.data!);
      return response.data!;
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Kh\u00f4ng th\u1ec3 l\u01b0u \u0111\u1ecba ch\u1ec9 giao h\u00e0ng',
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
          response.message ??
              'Kh\u00f4ng th\u1ec3 x\u00f3a \u0111\u1ecba ch\u1ec9',
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
      _showMessage(
        '\u0110\u00e3 x\u00f3a \u0111\u1ecba ch\u1ec9 giao h\u00e0ng',
      );
    } catch (_) {
      if (mounted) {
        _showMessage('Kh\u00f4ng th\u1ec3 x\u00f3a \u0111\u1ecba ch\u1ec9');
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
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    GoRouter.maybeOf(context)?.go(AppRoutes.cart);
  }

  void _goToProducts(BuildContext context) {
    GoRouter.maybeOf(context)?.go(AppRoutes.productList);
  }
}

class _CheckoutScaffold extends StatelessWidget {
  final Widget child;
  final VoidCallback onBack;

  const _CheckoutScaffold({required this.child, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _CheckoutHeader(onBack: onBack),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _CheckoutHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _CheckoutHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SizedBox(
        height: 58,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                'Thanh to\u00e1n',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryDark,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              left: 6,
              top: 4,
              bottom: 4,
              child: IconButton(
                onPressed: onBack,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                color: AppColors.primaryDark,
                tooltip: 'Quay l\u1ea1i',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutSummaryCard extends StatelessWidget {
  final Cart cart;

  const _CheckoutSummaryCard({required this.cart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedItems = cart.selectedItems;

    return _CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'T\u00f3m t\u1eaft \u0111\u01a1n h\u00e0ng',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${cart.totalSelectedItemCount} m\u1ee5c',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < selectedItems.length; index++) ...[
            _CheckoutItemRow(item: selectedItems[index]),
            if (index != selectedItems.length - 1)
              const Divider(height: 1, color: Color(0xFFF0F4F8)),
          ],
          const Divider(height: 22, color: Color(0xFFEAF0F5)),
          Row(
            children: [
              Expanded(
                child: Text(
                  'T\u1ed5ng t\u1ea1m t\u00ednh',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    MoneyFormatter.format(cart.subtotalAmount),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutItemRow extends StatelessWidget {
  final CartItem item;

  const _CheckoutItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE4EEF5)),
            ),
            child: const Icon(
              Icons.set_meal_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} ${item.unit} x '
                  '${MoneyFormatter.format(item.unitPrice)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            MoneyFormatter.format(item.lineTotal),
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutSuccessView extends StatelessWidget {
  final CheckoutResult result;

  const _CheckoutSuccessView({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _CheckoutCard(
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
                  '\u0110\u1eb7t h\u00e0ng th\u00e0nh c\u00f4ng',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'M\u00e3 \u0111\u01a1n ${result.order.orderCode}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                _SuccessMetricRow(
                  label: 'S\u1ed1 l\u01b0\u1ee3ng',
                  value: '${result.totalItemCount} m\u1ee5c',
                ),
                const Divider(height: 18, color: Color(0xFFEAF0F5)),
                _SuccessMetricRow(
                  label: 'T\u1ed5ng t\u1ea1m t\u00ednh',
                  value: MoneyFormatter.format(result.subtotalAmount),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('checkoutViewOrdersButton'),
                  onPressed: () =>
                      GoRouter.maybeOf(context)?.go(AppRoutes.orders),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Xem \u0111\u01a1n h\u00e0ng'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () =>
                      GoRouter.maybeOf(context)?.go(AppRoutes.home),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('V\u1ec1 trang ch\u1ee7'),
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
}

class _SuccessMetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _SuccessMetricRow({required this.label, required this.value});

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

class _CheckoutCard extends StatelessWidget {
  final Widget child;

  const _CheckoutCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12052449),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: child,
      ),
    );
  }
}
