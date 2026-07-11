import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../cubit/admin_product_cubit.dart';

/// Ô tìm kiếm sản phẩm theo tên, slug hoặc xuất xứ.
class AdminProductSearch extends StatefulWidget {
  final String initialQuery;

  const AdminProductSearch({super.key, required this.initialQuery});

  @override
  State<AdminProductSearch> createState() => _AdminProductSearchState();
}

class _AdminProductSearchState extends State<AdminProductSearch> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('adminProductSearchField'),
      controller: _controller,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: AppStrings.adminProductSearchHint,
      ),
      onChanged: context.read<AdminProductCubit>().setQuery,
    );
  }
}
