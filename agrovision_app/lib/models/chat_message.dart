class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime createdAt;
  final bool isError;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isError = false,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory ChatMessage.user(String content) => ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'user',
        content: content,
        createdAt: DateTime.now(),
      );

  factory ChatMessage.assistant(String content) => ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_a',
        role: 'assistant',
        content: content,
        createdAt: DateTime.now(),
      );

  factory ChatMessage.error(String message) => ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_e',
        role: 'assistant',
        content: message,
        createdAt: DateTime.now(),
        isError: true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'is_error': isError,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id']?.toString() ?? '',
        role: json['role'] as String? ?? 'assistant',
        content: json['content'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isError: json['is_error'] as bool? ?? false,
      );
}
