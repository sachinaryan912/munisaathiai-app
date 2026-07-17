import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/loading_view.dart';
import '../../models/ai_chat_message.dart';
import 'ai_chat_repository.dart';

/// The chat UI with no Scaffold/AppBar of its own — embed inside [AppShell]
/// for the Student "Vidya AI" tab, or inside [AiChatPage] when pushed as a
/// standalone screen from the floating AI FAB on other roles.
class AiChatBody extends StatefulWidget {
  const AiChatBody({super.key});

  @override
  State<AiChatBody> createState() => _AiChatBodyState();
}

class _AiChatBodyState extends State<AiChatBody> {
  final _repo = AiChatRepository();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<AiChatMessage> _messages = [];
  bool _loadingHistory = true;
  bool _sending = false;
  File? _attachedFile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _repo.getHistory();
      setState(() {
        _messages = history;
        _loadingHistory = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('ApiException: ', '');
        _loadingHistory = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf']);
    if (result?.files.single.path != null) {
      setState(() => _attachedFile = File(result!.files.single.path!));
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachedFile == null) return;
    if (_sending) return;

    final userMsg = AiChatMessage(id: -DateTime.now().millisecondsSinceEpoch, role: 'user', content: text.isEmpty ? '📎 ${_attachedFile!.path.split(Platform.pathSeparator).last}' : text, timestamp: DateTime.now());
    final fileToSend = _attachedFile;
    setState(() {
      _messages = [..._messages, userMsg];
      _controller.clear();
      _attachedFile = null;
      _sending = true;
    });
    _scrollToBottom();

    try {
      final reply = await _repo.send(content: text.isEmpty ? null : text, file: fileToSend);
      setState(() {
        _messages = [..._messages, reply];
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _sending = false;
        _messages = [
          ..._messages,
          AiChatMessage(
            id: -DateTime.now().millisecondsSinceEpoch,
            role: 'assistant',
            content: "Sorry, I couldn't respond right now — ${e.toString().replaceFirst('ApiException: ', '')}",
            timestamp: DateTime.now(),
          ),
        ];
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Column(
      children: [
        Expanded(
          child: _loadingHistory
              ? const LoadingView(message: 'Waking up Vidya...')
              : _error != null
                  ? Center(child: Text(_error!, style: TextStyle(color: s.textMuted)))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_sending ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == _messages.length) return const _TypingBubble();
                        return _ChatBubble(message: _messages[i]);
                      },
                    ),
        ),
        _Composer(
          controller: _controller,
          attachedFile: _attachedFile,
          onClearAttachment: () => setState(() => _attachedFile = null),
          onAttach: _pickFile,
          onSend: _send,
          sending: _sending,
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final AiChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          gradient: isUser ? const LinearGradient(colors: [AppColors.saffron500, AppColors.saffron400]) : null,
          color: isUser ? null : s.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: isUser ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: isUser
            ? Text(message.content, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4))
            : MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: s.textPrimary, fontSize: 14, height: 1.5),
                  strong: TextStyle(color: s.textPrimary, fontWeight: FontWeight.w800),
                  listBullet: TextStyle(color: s.textSecondary),
                ),
              ),
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.08, end: 0);
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: s.card, borderRadius: BorderRadius.circular(18)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              width: 6,
              height: 6,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
              decoration: BoxDecoration(color: s.textMuted, shape: BoxShape.circle),
            ).animate(onPlay: (c) => c.repeat(reverse: true), delay: (i * 150).ms).fadeIn(duration: 500.ms);
          }),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final File? attachedFile;
  final VoidCallback onClearAttachment;
  final VoidCallback onAttach;
  final VoidCallback onSend;
  final bool sending;

  const _Composer({
    required this.controller,
    required this.attachedFile,
    required this.onClearAttachment,
    required this.onAttach,
    required this.onSend,
    required this.sending,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(color: s.bg, border: Border(top: BorderSide(color: s.border))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attachedFile != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.paperclip, size: 13, color: AppColors.saffron600),
                      const SizedBox(width: 6),
                      Text(attachedFile!.path.split(Platform.pathSeparator).last, style: const TextStyle(fontSize: 11.5, color: AppColors.saffron700, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      GestureDetector(onTap: onClearAttachment, child: const Icon(LucideIcons.x, size: 13, color: AppColors.saffron700)),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                IconButton(onPressed: onAttach, icon: Icon(LucideIcons.paperclip, color: s.textSecondary)),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'Ask Vidya anything...', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: sending ? Colors.grey : AppColors.saffron500,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: sending ? null : onSend,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(11),
                      child: sending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                          : const Icon(LucideIcons.send, color: Colors.white, size: 17),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
