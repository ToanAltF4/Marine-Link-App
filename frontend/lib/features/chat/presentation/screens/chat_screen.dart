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
import '../../data/chat_mock_repository.dart';
import '../../domain/chat.dart';
import '../cubit/chat_cubit.dart';

class ChatScreen extends StatelessWidget {
  final String roomId;
  final bool staffMode;

  const ChatScreen({
    super.key,
    this.roomId = ChatMockRepository.defaultRoomId,
    this.staffMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatCubit>(
      create: (_) => sl<ChatCubit>()..load(roomId),
      child: _ChatView(staffMode: staffMode),
    );
  }
}

class _ChatView extends StatefulWidget {
  final bool staffMode;

  const _ChatView({required this.staffMode});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
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
        if (!state.sending && state.sendErrorMessage == null) {
          _controller.clear();
        }
        _scrollToBottom();
      },
      builder: (context, state) {
        final scaffold = Scaffold(
          key: const Key('chatScreen'),
          backgroundColor: AppColors.background,
          appBar: AppBar(
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
                child: _ChatBody(state: state, controller: _scrollController),
              ),
              _ChatComposer(
                controller: _controller,
                sending: state.sending,
                errorMessage: state.sendErrorMessage,
                onSend: _send,
              ),
            ],
          ),
        );

        if (widget.staffMode) {
          return AppBackExitScope(
            onFirstBack: (context) => context.go(AppRoutes.staffDashboard),
            child: scaffold,
          );
        }
        return BuyerBackToHomeScope(child: scaffold);
      },
    );
  }

  Future<void> _send() async {
    await context.read<ChatCubit>().sendMessage(
      _controller.text,
      sendAsStaff: widget.staffMode,
    );
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

  const _ChatBody({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      ChatStatus.initial || ChatStatus.loading => const Center(
        key: Key('chatLoading'),
        child: CircularProgressIndicator(),
      ),
      ChatStatus.failure => _ChatError(
        message:
            state.errorMessage ??
            'Kh\u00f4ng t\u1ea3i \u0111\u01b0\u1ee3c l\u1ecbch s\u1eed chat.',
        onRetry: () => context.read<ChatCubit>().load(
          state.roomId ?? ChatMockRepository.defaultRoomId,
        ),
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
  final String? errorMessage;
  final VoidCallback onSend;

  const _ChatComposer({
    required this.controller,
    required this.sending,
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
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Nh\u1eadp tin nh\u1eafn...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: FilledButton(
                      key: const Key('chatSendButton'),
                      onPressed: sending ? null : onSend,
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
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  key: const Key('chatInputError'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
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
