import '../../../../core/utils/date_time_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/navigation/buyer_navigation.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/buyer_back_to_home_scope.dart';
import '../../../../shared/widgets/buyer_bottom_nav.dart';
import '../../domain/chat.dart';
import '../cubit/chat_rooms_cubit.dart';

/// Buyer "chat history": list of the user's conversations. Tapping one opens the
/// thread; the "New chat" button starts a fresh conversation. (ML-64)
class ChatRoomsListScreen extends StatelessWidget {
  const ChatRoomsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatRoomsCubit>(
      create: (_) => sl<ChatRoomsCubit>()..load(),
      child: const _ChatRoomsView(),
    );
  }
}

class _ChatRoomsView extends StatelessWidget {
  const _ChatRoomsView();

  Future<void> _createRoom(BuildContext context) async {
    final cubit = context.read<ChatRoomsCubit>();
    final roomId = await cubit.createRoom();
    if (roomId != null && roomId.isNotEmpty && context.mounted) {
      await _openRoom(context, roomId);
    } else if (context.mounted && cubit.state.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(cubit.state.errorMessage!)));
    }
  }

  /// Open a thread and refresh the history when it is popped, so the list shows
  /// the latest message/room without needing a re-login.
  Future<void> _openRoom(BuildContext context, String roomId) async {
    final cubit = context.read<ChatRoomsCubit>();
    await context.push(AppRoutes.chatRoomPath(roomId));
    if (context.mounted) {
      await cubit.load(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BuyerBackToHomeScope(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            key: const Key('chatRoomsBackButton'),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => BuyerNavigation.popOrGo(context, AppRoutes.home),
          ),
          title: const Text(AppStrings.chatHistoryTitle),
          centerTitle: true,
        ),
        bottomNavigationBar: const BuyerBottomNav(
          currentTab: BuyerBottomNavTab.chat,
        ),
        floatingActionButton: BlocBuilder<ChatRoomsCubit, ChatRoomsState>(
          buildWhen: (a, b) => a.creating != b.creating,
          builder: (context, state) => FloatingActionButton.extended(
            key: const Key('chatNewChatButton'),
            onPressed: state.creating ? null : () => _createRoom(context),
            icon: state.creating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add_comment_outlined),
            label: const Text(AppStrings.newConversation),
          ),
        ),
        body: BlocBuilder<ChatRoomsCubit, ChatRoomsState>(
          builder: (context, state) {
            switch (state.status) {
              case ChatRoomsStatus.initial:
              case ChatRoomsStatus.loading:
                return const Center(
                  key: Key('chatRoomsLoading'),
                  child: AppLoadingIndicator(
                    message: AppStrings.loadingChatHistory,
                  ),
                );
              case ChatRoomsStatus.failure:
                return AppErrorState(
                  message:
                      state.errorMessage ?? AppStrings.chatHistoryLoadFailed,
                  onRetry: () => context.read<ChatRoomsCubit>().load(),
                );
              case ChatRoomsStatus.empty:
                return AppEmptyState(
                  key: const Key('chatRoomsEmpty'),
                  icon: Icons.forum_outlined,
                  message: AppStrings.chatHistoryEmpty,
                  actionLabel: AppStrings.newConversation,
                  onAction: () => _createRoom(context),
                );
              case ChatRoomsStatus.success:
                return ListView.separated(
                  key: const Key('chatRoomsList'),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  itemCount: state.rooms.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _ChatRoomTile(
                    room: state.rooms[index],
                    onTap: () => _openRoom(context, state.rooms[index].roomId),
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoomSummary room;
  final VoidCallback onTap;

  const _ChatRoomTile({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('chatRoomTile_${room.roomId}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE3F0FF),
                child: Icon(
                  room.isClosed
                      ? Icons.check_circle_outline_rounded
                      : Icons.chat_bubble_outline_rounded,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (room.isClosed)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF3EA),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              AppStrings.chatClosedFilter,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        Text(
                          _formatTime(room.lastMessageAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return AppStrings.noChatMessagesYet;
    return DateTimeFormatter.timeThenDate(time);
  }
}
