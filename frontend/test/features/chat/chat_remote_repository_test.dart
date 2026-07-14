import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_client.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/chat/data/chat_remote_repository.dart';
import 'package:marinelink/features/chat/domain/chat.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient apiClient;
  late ChatRemoteRepository repository;

  final threadJson = {
    'roomId': 'room-001',
    'isClosed': false,
    'messages': <Map<String, dynamic>>[],
  };

  setUp(() {
    apiClient = _MockApiClient();
    repository = ChatRemoteRepository(apiClient: apiClient);
  });

  test('getMyRoom calls the buyer support room endpoint', () async {
    when(
      () => apiClient.get<ChatThread>(any(), fromJson: any(named: 'fromJson')),
    ).thenAnswer((invocation) async {
      final fromJson =
          invocation.namedArguments[#fromJson] as ChatThread Function(dynamic);
      return ApiResponse(
        success: true,
        message: 'OK',
        data: fromJson(threadJson),
      );
    });

    final result = await repository.getMyRoom();

    expect(result.success, true);
    expect(result.data?.roomId, 'room-001');
    expect(result.data?.messages, isEmpty);
    verify(
      () => apiClient.get<ChatThread>(
        '/api/chat/room',
        fromJson: any(named: 'fromJson'),
      ),
    ).called(1);
  });

  test('getOrderRoom calls the completed order complaint endpoint', () async {
    when(
      () => apiClient.get<ChatThread>(any(), fromJson: any(named: 'fromJson')),
    ).thenAnswer((invocation) async {
      final fromJson =
          invocation.namedArguments[#fromJson] as ChatThread Function(dynamic);
      return ApiResponse(
        success: true,
        message: 'OK',
        data: fromJson(threadJson),
      );
    });

    final result = await repository.getOrderRoom('order-004');

    expect(result.success, true);
    expect(result.data?.roomId, 'room-001');
    verify(
      () => apiClient.get<ChatThread>(
        '/api/chat/orders/order-004/room',
        fromJson: any(named: 'fromJson'),
      ),
    ).called(1);
  });

  test('sendMessage posts to chat send with roomId and content', () async {
    final messageJson = {
      'id': 'message-001',
      'roomId': 'room-001',
      'senderType': 'USER',
      'content': 'Tôi cần hỗ trợ.',
      'createdAt': '2026-05-28T08:30:00Z',
      'attachments': <Map<String, dynamic>>[],
    };
    when(
      () => apiClient.post<ChatMessage>(
        any(),
        data: any(named: 'data'),
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer((invocation) async {
      final fromJson =
          invocation.namedArguments[#fromJson] as ChatMessage Function(dynamic);
      return ApiResponse(
        success: true,
        message: 'Message sent',
        data: fromJson(messageJson),
      );
    });

    final result = await repository.sendMessage(
      roomId: 'room-001',
      content: 'Tôi cần hỗ trợ.',
    );

    expect(result.success, true);
    expect(result.data?.content, 'Tôi cần hỗ trợ.');
    verify(
      () => apiClient.post<ChatMessage>(
        '/api/chat/send',
        data: {
          'roomId': 'room-001',
          'content': 'Tôi cần hỗ trợ.',
          'attachments': const <Map<String, dynamic>>[],
        },
        fromJson: any(named: 'fromJson'),
      ),
    ).called(1);
  });
}
