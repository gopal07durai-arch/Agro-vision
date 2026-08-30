import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';

class ChatError {
  final String code;
  final String message;
  const ChatError({required this.code, required this.message});

  bool get isNetworkError => code == 'NETWORK_ERROR' || code == 'TIMEOUT';
  bool get isAiError => code == 'AI_SERVICE_UNAVAILABLE' || code == 'RATE_LIMIT_EXCEEDED';

  @override
  String toString() => 'ChatError[$code]: $message';
}

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  static const Duration _timeout = Duration(seconds: 60);

  List<String> get _candidateUrls {
    final configured = ApiConfig.baseUrl;
    final list = <String>[configured];
    if (!ApiConfig.isProduction) {
      if (!list.contains('http://10.0.2.2:8000')) {
        list.add('http://10.0.2.2:8000');
      }
      if (!list.contains('http://localhost:8000')) {
        list.add('http://localhost:8000');
      }
    }
    return list;
  }

  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required String language,
    String? conversationId,
    List<ChatMessage> history = const [],
    ScanContext? scanContext,
  }) async {
    // Filter out errors and avoid duplicate if current message is already in history
    final historyJson = history
        .where((m) => !m.isError)
        .toList();
    // If the last message in history is the current message, remove it from history
    if (historyJson.isNotEmpty && historyJson.last.content == message) {
      historyJson.removeLast();
    }

    final formattedHistory = historyJson
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    final body = <String, dynamic>{
      'message': message,
      'language': language,
      if (conversationId != null) 'conversation_id': conversationId,
      if (formattedHistory.isNotEmpty) 'history': formattedHistory,
      if (scanContext != null) 'scan_context': scanContext.toJson(),
    };

    for (final base in _candidateUrls) {
      // Try /api/ai/chat first, fallback to /api/chat
      for (final path in ['/api/ai/chat', '/api/chat']) {
        final uri = Uri.parse('$base$path');
        debugPrint('[ChatService] Sending message to $uri');

        try {
          final response = await http
              .post(
                uri,
                headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
                body: jsonEncode(body),
              )
              .timeout(_timeout);

          debugPrint('[ChatService] Status: ${response.statusCode}');
          final data = _parseJson(response.body);

          if (response.statusCode == 200 && data['success'] == true) {
            final ans = (data['answer'] ?? data['response']) as String? ?? '';
            return {
              'success': true,
              'conversation_id': data['conversation_id'] as String? ?? '',
              'answer': ans,
              'response': ans,
              'language': data['language'] as String? ?? language,
            };
          }

          // If 404 on /api/ai/chat, try /api/chat
          if (response.statusCode == 404 && path == '/api/ai/chat') {
            continue;
          }

          // If this URL gave a 502/503 (Render sleeping), continue to local fallback
          if (response.statusCode >= 500 && _candidateUrls.length > 1 && base != _candidateUrls.last) {
            debugPrint('[ChatService] Server returned ${response.statusCode}, trying fallback...');
            break;
          }

          final errorCode = data['error_code'] as String? ?? 'SERVER_ERROR';
          final errorMsg = data['message'] as String? ?? 'Service temporarily unavailable. Please try again.';
          return {'success': false, 'error_code': errorCode, 'message': errorMsg};

        } on SocketException catch (e) {
          debugPrint('[ChatService] SocketException on $base: $e');
          if (base != _candidateUrls.last) break;
          return {'success': false, 'error_code': 'NETWORK_ERROR', 'message': 'No internet connection. Please check your connection and try again.'};
        } on TimeoutException {
          if (base != _candidateUrls.last) break;
          return {'success': false, 'error_code': 'TIMEOUT', 'message': 'AI response timed out. Please try again.'};
        } catch (e) {
          debugPrint('[ChatService] Error on $base: $e');
          if (base != _candidateUrls.last) break;
          return {'success': false, 'error_code': 'SERVER_ERROR', 'message': 'An unexpected error occurred. Please try again.'};
        }
      }
    }

    return {'success': false, 'error_code': 'NETWORK_ERROR', 'message': 'Could not reach AI server. Please check your internet connection.'};
  }

  Future<bool> checkChatHealth() async {
    for (final base in _candidateUrls) {
      for (final path in ['/api/ai/health', '/api/chat/health']) {
        try {
          final response = await http
              .get(Uri.parse('$base$path'))
              .timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            final data = _parseJson(response.body);
            return data['chat_configured'] as bool? ?? false;
          }
        } catch (_) {}
      }
    }
    return false;
  }

  Map<String, dynamic> _parseJson(String body) {
    try {
      final d = jsonDecode(body);
      if (d is Map<String, dynamic>) return d;
    } catch (_) {}
    return {};
  }
}
