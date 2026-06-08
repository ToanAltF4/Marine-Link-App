import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/app_back_exit_scope.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/buyer_back_to_home_scope.dart';
import '../../../../shared/widgets/buyer_bottom_nav.dart';
import '../../../../shared/widgets/role_bottom_nav.dart';
import '../../domain/chat.dart';
import '../cubit/chat_cubit.dart';

class ChatScreen extends StatelessWidget {
  /// Khi null (buyer mở tab Chat): lấy/tạo phòng hỗ trợ của user hiện tại.
  /// Khi có giá trị (staff / deep-link): mở đúng phòng đó.
  final String? roomId;
  final String? orderId;
  final bool staffMode;
  final String staffBackLocation;

  const ChatScreen({
    super.key,
    this.roomId,
    this.orderId,
    this.staffMode = false,
    this.staffBackLocation = AppRoutes.staffDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatCubit>(
      create: (_) {
        final cubit = sl<ChatCubit>();
        final id = roomId;
        final complaintOrderId = orderId;
        if (complaintOrderId != null && complaintOrderId.isNotEmpty) {
          cubit.loadOrderRoom(complaintOrderId);
        } else if (id == null) {
          cubit.loadMyRoom();
        } else {
          cubit.load(id);
        }
        return cubit;
      },
      child: _ChatView(
        orderId: orderId,
        staffMode: staffMode,
        staffBackLocation: staffBackLocation,
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  final String? orderId;
  final bool staffMode;
  final String staffBackLocation;

  const _ChatView({
    this.orderId,
    required this.staffMode,
    required this.staffBackLocation,
  });

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  static const _refreshInterval = Duration(seconds: 4);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatState>(
      listenWhen: (previous, current) =>
          previous.sending != current.sending ||
          previous.messages.length != current.messages.length,
      listener: (context, state) {
        _scrollToBottom();
      },
      builder: (context, state) {
        final scaffold = Scaffold(
          key: const Key('chatScreen'),
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading:
                widget.staffMode &&
                    widget.staffBackLocation != AppRoutes.staffDashboard
                ? IconButton(
                    key: const Key('staffChatBackButton'),
                    tooltip: 'Quay l\u1ea1i',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go(widget.staffBackLocation),
                  )
                : null,
            title: Text(
              widget.staffMode
                  ? 'Tin nh\u1eafn kh\u00e1ch h\u00e0ng'
                  : 'Chat h\u1ed7 tr\u1ee3',
            ),
          ),
          bottomNavigationBar: widget.staffMode
              ? const StaffBottomNav(currentTab: StaffBottomNavTab.chat)
              : const BuyerBottomNav(currentTab: BuyerBottomNavTab.chat),
          body: Column(
            children: [
              Expanded(
                child: _ChatBody(
                  state: state,
                  controller: _scrollController,
                  orderId: widget.orderId,
                ),
              ),
              _ChatComposer(
                controller: _controller,
                sending: state.sending,
                canRetrySend: state.canRetrySend,
                closed: state.thread?.isClosed ?? false,
                errorMessage: state.sendErrorMessage,
                onSend: _send,
              ),
            ],
          ),
        );

        if (widget.staffMode) {
          return AppBackExitScope(
            onFirstBack: (context) => context.go(widget.staffBackLocation),
            child: scaffold,
          );
        }
        return BuyerBackToHomeScope(child: scaffold);
      },
    );
  }

  Future<void> _send() async {
    final cubit = context.read<ChatCubit>();
    await cubit.sendMessage(_controller.text, sendAsStaff: widget.staffMode);
    if (!mounted) return;
    if (cubit.state.sendErrorMessage == null) {
      _controller.clear();
    }
  }

  void _refresh() {
    if (!mounted) return;
    final cubit = context.read<ChatCubit>();
    if (cubit.state.sending) return;
    final complaintOrderId = widget.orderId;
    if (complaintOrderId != null && complaintOrderId.isNotEmpty) {
      cubit.loadOrderRoom(complaintOrderId);
      return;
    }
    final id = cubit.state.roomId;
    if (id == null || id.isEmpty) {
      cubit.loadMyRoom();
      return;
    }
    cubit.load(id);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }
}

class _ChatBody extends StatelessWidget {
  final ChatState state;
  final ScrollController controller;
  final String? orderId;

  const _ChatBody({
    required this.state,
    required this.controller,
    this.orderId,
  });

  void _reload(BuildContext context) {
    final cubit = context.read<ChatCubit>();
    final complaintOrderId = orderId;
    if (complaintOrderId != null && complaintOrderId.isNotEmpty) {
      cubit.loadOrderRoom(complaintOrderId);
      return;
    }
    final id = state.roomId;
    if (id == null || id.isEmpty) {
      cubit.loadMyRoom();
    } else {
      cubit.load(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (state.status) {
      ChatStatus.initial || ChatStatus.loading => const Center(
        key: Key('chatLoading'),
        child: CircularProgressIndicator(),
      ),
      ChatStatus.failure => _ChatError(
        message:
            state.errorMessage ??
            'Kh\u00f4ng t\u1ea3i \u0111\u01b0\u1ee3c l\u1ecbch s\u1eed chat.',
        onRetry: () => _reload(context),
      ),
      ChatStatus.empty => const Center(
        key: Key('chatEmpty'),
        child: AppEmptyState(
          icon: Icons.chat_bubble_outline_rounded,
          message:
              'Ch\u01b0a c\u00f3 tin nh\u1eafn trong ph\u00f2ng chat n\u00e0y.',
        ),
      ),
      ChatStatus.success => _ChatMessageList(
        controller: controller,
        messages: state.messages,
      ),
    };
    if (!state.offlineFallback) {
      return body;
    }
    return Column(
      children: [
        _OfflineFallbackBanner(
          message:
              state.errorMessage ??
              '\u0110ang hi\u1ec3n th\u1ecb d\u1eef li\u1ec7u chat g\u1ea7n nh\u1ea5t.',
          onRetry: () => _reload(context),
        ),
        Expanded(child: body),
      ],
    );
  }
}

class _OfflineFallbackBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _OfflineFallbackBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('chatOfflineFallbackBanner'),
      color: const Color(0xFFFFF7E6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.warning,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            TextButton.icon(
              key: const Key('chatOfflineRetryButton'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('T\u1ea3i l\u1ea1i'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ChatError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('chatError'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.error,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('chatRetryButton'),
              onPressed: onRetry,
              child: const Text('Th\u1eed l\u1ea1i'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessageList extends StatelessWidget {
  final ScrollController controller;
  final List<ChatMessage> messages;

  const _ChatMessageList({required this.controller, required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const Key('chatMessagesList'),
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      itemCount: messages.length,
      itemBuilder: (context, index) => _ChatBubble(message: messages[index]),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.senderType == ChatSenderType.user;
    final style = _bubbleStyle(message.senderType);
    return Align(
      key: Key('chatMessageBubble_${message.id}'),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 310),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(8),
              topRight: const Radius.circular(8),
              bottomLeft: Radius.circular(isUser ? 8 : 2),
              bottomRight: Radius.circular(isUser ? 2 : 8),
            ),
            border: Border.all(color: style.borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _senderLabel(message.senderType),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: style.labelColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.content,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatTime(message.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
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

class _ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool canRetrySend;
  final bool closed;
  final String? errorMessage;
  final VoidCallback onSend;

  const _ChatComposer({
    required this.controller,
    required this.sending,
    required this.canRetrySend,
    required this.closed,
    required this.errorMessage,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('chatMessageTextField'),
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      enabled: !closed,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: closed
                            ? 'Ph\u00f2ng chat \u0111\u00e3 x\u1eed l\u00fd'
                            : 'Nh\u1eadp tin nh\u1eafn...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: FilledButton(
                      key: const Key('chatSendButton'),
                      onPressed: sending || closed ? null : onSend,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
              if (closed) ...[
                const SizedBox(height: 8),
                Text(
                  'Ph\u00f2ng chat \u0111\u00e3 \u0111\u00f3ng. Staff c\u00f3 th\u1ec3 m\u1edf l\u1ea1i t\u1eeb danh s\u00e1ch chat.',
                  key: const Key('chatClosedNotice'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        errorMessage!,
                        key: const Key('chatInputError'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (canRetrySend) ...[
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        key: const Key('chatRetrySendButton'),
                        onPressed: sending || closed ? null : onSend,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Thử gửi lại'),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _senderLabel(ChatSenderType type) {
  return switch (type) {
    ChatSenderType.user => '\u0110\u1ea1i l\u00fd',
    ChatSenderType.staff => 'Nh\u00e2n vi\u00ean',
    ChatSenderType.aiSample => 'G\u1ee3i \u00fd m\u1eabu',
  };
}

String _formatTime(DateTime? value) {
  if (value == null) return '--:--';
  return DateFormat('HH:mm dd/MM').format(value.toLocal());
}

({Color backgroundColor, Color borderColor, Color labelColor}) _bubbleStyle(
  ChatSenderType type,
) {
  return switch (type) {
    ChatSenderType.user => (
      backgroundColor: const Color(0xFFEAF6FF),
      borderColor: const Color(0xFFD8E7EF),
      labelColor: AppColors.primary,
    ),
    ChatSenderType.staff => (
      backgroundColor: Colors.white,
      borderColor: AppColors.border,
      labelColor: AppColors.success,
    ),
    ChatSenderType.aiSample => (
      backgroundColor: const Color(0xFFFFF7E6),
      borderColor: const Color(0xFFFFE2A8),
      labelColor: AppColors.warning,
    ),
  };
}
