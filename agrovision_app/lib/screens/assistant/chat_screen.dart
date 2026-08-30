import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../models/chat_message.dart';
import '../../models/chat_conversation.dart';
import '../../services/chat_service.dart';
import '../../services/chat_supabase_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChatScreen — AI Farmer Assistant
// ─────────────────────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final ScanContext? scanContext;
  final String? initialMessage;
  final ChatConversation? existingConversation;

  const ChatScreen({
    super.key,
    this.scanContext,
    this.initialMessage,
    this.existingConversation,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService();
  final _supabaseService = ChatSupabaseService();

  late ChatConversation _conversation;
  bool _isLoading = false;
  bool _showSuggestions = true;
  String? _pendingUserMessage;

  @override
  void initState() {
    super.initState();
    if (widget.existingConversation != null) {
      _conversation = widget.existingConversation!;
      _showSuggestions = _conversation.messages.isEmpty;
    } else {
      final langCode = context.read<AppProvider>().languageCode;
      _conversation = ChatConversation.create(langCode);
    }

    if (widget.scanContext != null) {
      _showSuggestions = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendContextIntro());
    } else if (widget.initialMessage != null && widget.initialMessage!.trim().isNotEmpty) {
      _showSuggestions = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendMessage(widget.initialMessage!));
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Context intro when opened from scan result ─────────────────────────────

  void _sendContextIntro() {
    final ctx = widget.scanContext!;
    final l10n = AppLocalizations.of(context);
    final introMsg = l10n.scanContextIntro(ctx.crop, ctx.disease, ctx.severity);
    _sendMessage(introMsg);
  }

  // ── Send message ───────────────────────────────────────────────────────────

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _showSuggestions = false;
      _isLoading = true;
    });

    final userMsg = ChatMessage.user(trimmed);
    setState(() => _conversation.messages.add(userMsg));
    // Persist locally and to Supabase asynchronously without blocking chat
    _supabaseService.saveConversation(_conversation).catchError((_) {});
    _supabaseService.saveMessage(_conversation.id, userMsg).catchError((_) {});
    _scrollToBottom();

    final langCode = context.read<AppProvider>().languageCode;
    final result = await _chatService.sendMessage(
      message: trimmed,
      language: langCode,
      conversationId: _conversation.id,
      history: _conversation.messages,
      scanContext: widget.scanContext,
    );

    ChatMessage assistantMsg;
    if (result['success'] == true) {
      assistantMsg = ChatMessage.assistant(result['answer'] as String? ?? '');
    } else {
      assistantMsg = ChatMessage.error(result['message'] as String? ?? 'An error occurred. Please try again.');
    }

    setState(() {
      _conversation.messages.add(assistantMsg);
      _isLoading = false;
    });
    _supabaseService.saveMessage(_conversation.id, assistantMsg).catchError((_) {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Retry last message ─────────────────────────────────────────────────────

  Future<void> _retryLastMessage() async {
    if (_conversation.messages.isEmpty) return;
    // Find last user message
    final userMsgs = _conversation.messages.where((m) => m.isUser).toList();
    if (userMsgs.isEmpty) return;
    final lastUser = userMsgs.last;
    // Remove the last error message if present
    if (_conversation.messages.isNotEmpty && _conversation.messages.last.isError) {
      setState(() => _conversation.messages.removeLast());
    }
    await _sendMessage(lastUser.content);
  }

  // ── New conversation ───────────────────────────────────────────────────────

  void _newConversation() {
    final langCode = context.read<AppProvider>().languageCode;
    setState(() {
      _conversation = ChatConversation.create(langCode);
      _showSuggestions = true;
      _isLoading = false;
    });
  }

  // ── Clear confirmation ─────────────────────────────────────────────────────

  void _showClearDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.clearConversation, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(l10n.clearConversationConfirm, style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _newConversation();
            },
            child: Text(l10n.clearConversation, style: const TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4),
      body: Column(
        children: [
          _buildHeader(context, isDark, l10n),
          if (widget.scanContext != null) _buildScanContextBanner(context, isDark, l10n),
          Expanded(
            child: _conversation.messages.isEmpty
                ? _buildEmptyState(context, isDark, l10n)
                : _buildMessageList(context, isDark, l10n),
          ),
          if (_showSuggestions && _conversation.messages.isEmpty)
            _buildSuggestions(context, isDark, l10n),
          _buildInputBar(context, isDark, l10n),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF064E3B), const Color(0xFF1E293B)]
              : [AppTheme.emeraldGreen, const Color(0xFF059669)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.emeraldGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 8, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.agriculture_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiAssistantTitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      l10n.aiAssistantSubtitle,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Clear button
              if (_conversation.messages.isNotEmpty)
                IconButton(
                  onPressed: _showClearDialog,
                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 20),
                  tooltip: l10n.clearConversation,
                ),
              // New conversation
              IconButton(
                onPressed: _newConversation,
                icon: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 20),
                tooltip: l10n.newConversation,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Scan context banner ────────────────────────────────────────────────────

  Widget _buildScanContextBanner(BuildContext context, bool isDark, AppLocalizations l10n) {
    final ctx = widget.scanContext!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.emeraldGreen.withOpacity(isDark ? 0.2 : 0.1),
        border: Border(bottom: BorderSide(color: AppTheme.emeraldGreen.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          const Icon(Icons.biotech_rounded, size: 16, color: AppTheme.emeraldGreen),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
                children: [
                  TextSpan(
                    text: l10n.scanContextLabel + ' ',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.emeraldGreen),
                  ),
                  TextSpan(
                    text: '${ctx.crop} • ${ctx.disease} • ${ctx.severity}',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state with suggestions ───────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, bool isDark, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.emeraldGreen, const Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.emeraldGreen.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.agriculture_rounded, color: Colors.white, size: 40),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(
            l10n.aiAssistantWelcome,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            l10n.aiAssistantWelcomeSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  // ── Message list ───────────────────────────────────────────────────────────

  Widget _buildMessageList(BuildContext context, bool isDark, AppLocalizations l10n) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _conversation.messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (ctx, index) {
        if (index == _conversation.messages.length && _isLoading) {
          return _buildTypingIndicator(isDark);
        }
        final msg = _conversation.messages[index];
        final isLast = index == _conversation.messages.length - 1;
        return _buildMessageBubble(msg, isDark, l10n, isLast: isLast);
      },
    );
  }

  // ── Message bubble ─────────────────────────────────────────────────────────

  Widget _buildMessageBubble(ChatMessage msg, bool isDark, AppLocalizations l10n, {bool isLast = false}) {
    final isUser = msg.isUser;

    Widget bubble = Container(
      margin: EdgeInsets.only(
        top: 6,
        bottom: 6,
        left: isUser ? 60 : 0,
        right: isUser ? 0 : 60,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.emeraldGreen, const Color(0xFF059669)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.agriculture_rounded, size: 16, color: Colors.white),
            ),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.messageCopied, style: const TextStyle(fontFamily: 'Poppins')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser
                      ? AppTheme.emeraldGreen
                      : msg.isError
                          ? const Color(0xFFFEF2F2)
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  border: Border.all(
                    color: isUser
                        ? Colors.transparent
                        : msg.isError
                            ? const Color(0xFFFCA5A5)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.isError)
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                          const SizedBox(width: 4),
                          Text(
                            'Error',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    if (msg.isError) const SizedBox(height: 4),
                    Text(
                      msg.content,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        height: 1.5,
                        color: isUser
                            ? Colors.white
                            : msg.isError
                                ? const Color(0xFF991B1B)
                                : (isDark ? Colors.white.withOpacity(0.87) : const Color(0xFF1F2937)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(msg.createdAt),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: isUser
                                ? Colors.white60
                                : (isDark ? Colors.white38 : Colors.black38),
                          ),
                        ),
                        if (msg.isError) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _retryLastMessage,
                            child: Text(
                              l10n.chatRetry,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.emeraldGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );

    if (isLast) {
      return bubble.animate().slideY(begin: 0.2, duration: 300.ms).fadeIn();
    }
    return bubble;
  }

  // ── Typing indicator ───────────────────────────────────────────────────────

  Widget _buildTypingIndicator(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 6, right: 60),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.emeraldGreen, const Color(0xFF059669)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.agriculture_rounded, size: 16, color: Colors.white),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  child: _DotIndicator(delay: Duration(milliseconds: i * 200)),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Suggested questions ────────────────────────────────────────────────────

  Widget _buildSuggestions(BuildContext context, bool isDark, AppLocalizations l10n) {
    final suggestions = l10n.chatSuggestions;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.suggestionsLabel,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) {
              return GestureDetector(
                onTap: () => _sendMessage(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.emeraldGreen.withOpacity(0.3)),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.emeraldGreen,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Input bar ──────────────────────────────────────────────────────────────

  Widget _buildInputBar(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              decoration: InputDecoration(
                hintText: l10n.typeYourQuestion,
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppTheme.emeraldGreen, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (v) => _sendMessage(v),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: () => _sendMessage(_textController.text),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoading
                        ? [Colors.grey, Colors.grey]
                        : [AppTheme.emeraldGreen, const Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.emeraldGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Animated typing dot ────────────────────────────────────────────────────

class _DotIndicator extends StatefulWidget {
  final Duration delay;
  const _DotIndicator({required this.delay});
  @override
  State<_DotIndicator> createState() => _DotIndicatorState();
}

class _DotIndicatorState extends State<_DotIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, -4 * _anim.value),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.emeraldGreen.withOpacity(0.4 + 0.6 * _anim.value),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
