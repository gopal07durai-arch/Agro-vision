import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';

class ChatSupabaseService {
  static final ChatSupabaseService _instance = ChatSupabaseService._internal();
  factory ChatSupabaseService() => _instance;
  ChatSupabaseService._internal();

  static const String _localKey = 'agrovision_chat_v1';

  SupabaseClient? get _client {
    try { return Supabase.instance.client; } catch (_) { return null; }
  }

  bool get isAvailable => _client != null;
  bool get isConfigured => _client != null;

  // ── Save a conversation (create or update) ──────────────────────────────

  Future<void> saveConversation(ChatConversation conv) async {
    await _saveLocalConversation(conv);
    final client = _client;
    if (client != null) {
      try {
        await client.from('chat_conversations').upsert({
          'id': conv.id,
          'session_id': conv.id,
          'title': conv.title,
          'language': conv.language,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('[ChatSupabase] upsert conv error: $e');
      }
    }
  }

  // ── Save a message ──────────────────────────────────────────────────────

  Future<void> saveMessage(String conversationId, ChatMessage msg) async {
    await _appendLocalMessage(conversationId, msg);
    final client = _client;
    if (client != null && !msg.isError) {
      try {
        await client.from('chat_messages').insert({
          'conversation_id': conversationId,
          'role': msg.role,
          'content': msg.content,
          'created_at': msg.createdAt.toIso8601String(),
        });
        await client.from('chat_conversations').update({
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', conversationId);
      } catch (e) {
        debugPrint('[ChatSupabase] insert msg error: $e');
      }
    }
  }

  // ── Load conversation with messages ────────────────────────────────────

  Future<ChatConversation?> loadConversation(String id) async {
    final local = await _loadLocalConversation(id);
    final client = _client;
    if (client != null) {
      try {
        final msgs = await client
            .from('chat_messages')
            .select()
            .eq('conversation_id', id)
            .order('created_at', ascending: true);
        if (msgs.isNotEmpty) {
          final remoteMessages = (msgs as List)
              .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
              .toList();
          if (local != null) {
            local.messages.clear();
            local.messages.addAll(remoteMessages);
          }
          return local;
        }
      } catch (e) {
        debugPrint('[ChatSupabase] load msgs error: $e');
      }
    }
    return local;
  }

  // ── List all conversations for session ─────────────────────────────────

  Future<List<ChatConversation>> listConversations(String sessionId) async {
    return await _loadAllLocalConversations();
  }

  Future<List<ChatConversation>> getAllConversations({int limit = 10}) async {
    final all = await _loadAllLocalConversations();
    if (all.length > limit) {
      return all.take(limit).toList();
    }
    return all;
  }

  // ── Delete conversation ─────────────────────────────────────────────────

  Future<void> deleteConversation(String id) async {
    await _deleteLocalConversation(id);
    final client = _client;
    if (client != null) {
      try {
        await client.from('chat_conversations').delete().eq('id', id);
      } catch (e) {
        debugPrint('[ChatSupabase] delete conv error: $e');
      }
    }
  }

  // ── Local Storage Helpers ───────────────────────────────────────────────

  Future<void> _saveLocalConversation(ChatConversation conv) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_localKey}_${conv.id}', jsonEncode(conv.toJson()));
      final ids = prefs.getStringList('${_localKey}_ids') ?? [];
      if (!ids.contains(conv.id)) {
        ids.insert(0, conv.id);
        await prefs.setStringList('${_localKey}_ids', ids);
      }
    } catch (_) {}
  }

  Future<void> _appendLocalMessage(String convId, ChatMessage msg) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('${_localKey}_$convId');
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final msgs = List<dynamic>.from(data['messages'] ?? []);
      msgs.add(msg.toJson());
      data['messages'] = msgs;
      data['updated_at'] = DateTime.now().toIso8601String();
      await prefs.setString('${_localKey}_$convId', jsonEncode(data));
    } catch (_) {}
  }

  Future<ChatConversation?> _loadLocalConversation(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('${_localKey}_$id');
      if (raw == null) return null;
      return ChatConversation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  Future<List<ChatConversation>> _loadAllLocalConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('${_localKey}_ids') ?? [];
      final result = <ChatConversation>[];
      for (final id in ids) {
        final c = await _loadLocalConversation(id);
        if (c != null) result.add(c);
      }
      return result;
    } catch (_) { return []; }
  }

  Future<void> _deleteLocalConversation(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_localKey}_$id');
      final ids = prefs.getStringList('${_localKey}_ids') ?? [];
      ids.remove(id);
      await prefs.setStringList('${_localKey}_ids', ids);
    } catch (_) {}
  }
}
