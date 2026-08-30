import 'chat_message.dart';

class ScanContext {
  final String crop;
  final String disease;
  final String severity;

  const ScanContext({
    required this.crop,
    required this.disease,
    required this.severity,
  });

  Map<String, dynamic> toJson() => {
        'crop': crop,
        'disease': disease,
        'severity': severity,
      };
}

class ChatConversation {
  final String id;
  final String title;
  final String language;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.title,
    required this.language,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversation.create(String language) {
    final now = DateTime.now();
    return ChatConversation(
      id: now.millisecondsSinceEpoch.toString(),
      title: 'New Conversation',
      language: language,
      messages: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'language': language,
        'messages': messages.map((m) => m.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final msgs = (json['messages'] as List? ?? [])
        .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList();
    return ChatConversation(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Conversation',
      language: json['language'] as String? ?? 'en',
      messages: msgs,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
