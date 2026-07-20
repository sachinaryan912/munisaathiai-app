import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/nav/nav_items.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/loading_view.dart';
import '../../models/ai_chat_message.dart';
import '../../models/ai_conversation.dart';
import '../auth/data/auth_provider.dart';
import 'ai_chat_repository.dart';

/// The chat UI with no Scaffold/AppBar of its own — embeds inside AppShell
/// or standalone page with transparent top headers.
class AiChatBody extends StatefulWidget {
  const AiChatBody({super.key});

  @override
  State<AiChatBody> createState() => _AiChatBodyState();
}

class _AiChatBodyState extends State<AiChatBody> {
  final _repo = AiChatRepository();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<AiConversation> _conversations = [];
  int? _activeConversationId;
  List<AiChatMessage> _messages = [];
  bool _loadingHistory = true;
  bool _switchingChat = false;
  bool _creatingChat = false;
  bool _historyOpen = false;
  bool _sending = false;
  File? _attachedFile;
  String? _error;
  final Set<int> _animatedMessageIds = {};

  // The backend always seeds a welcome assistant message into every conversation (both the
  // very first one and every "New chat"), so `_messages` is never literally empty — treat a
  // conversation holding only that single seeded greeting as "fresh" too, so the suggestion
  // welcome screen actually gets a chance to show instead of being permanently dead code.
  bool get _showWelcome => _messages.isEmpty || (_messages.length == 1 && !_messages.first.isUser);

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await _repo.getConversations();
      final first = conversations.isNotEmpty ? conversations.first : null;
      final messages = first != null ? await _repo.getConversationMessages(first.id) : <AiChatMessage>[];
      setState(() {
        _conversations = conversations;
        _activeConversationId = first?.id;
        _messages = messages;
        _animatedMessageIds.addAll(messages.map((m) => m.id));
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

  Future<void> _startNewChat() async {
    if (_creatingChat) return;
    setState(() => _creatingChat = true);
    try {
      final conv = await _repo.createConversation();
      final messages = await _repo.getConversationMessages(conv.id);
      setState(() {
        _conversations = [conv, ..._conversations];
        _activeConversationId = conv.id;
        _messages = messages;
        _animatedMessageIds
          ..clear()
          ..addAll(messages.map((m) => m.id));
        _historyOpen = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      setState(() => _creatingChat = false);
    }
  }

  Future<void> _selectConversation(int id) async {
    setState(() => _historyOpen = false);
    if (id == _activeConversationId) return;
    setState(() {
      _switchingChat = true;
      _activeConversationId = id;
    });
    try {
      final messages = await _repo.getConversationMessages(id);
      setState(() {
        _messages = messages;
        _animatedMessageIds
          ..clear()
          ..addAll(messages.map((m) => m.id));
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      setState(() => _switchingChat = false);
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
    final conversationId = _activeConversationId;
    if ((text.isEmpty && _attachedFile == null) || _sending || conversationId == null) return;

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
      final reply = await _repo.sendMessage(conversationId, content: text.isEmpty ? null : text, file: fileToSend);
      setState(() {
        _messages = [..._messages, reply];
        _sending = false;
      });
      _scrollToBottom();
      _repo.getConversations().then((list) {
        if (mounted) setState(() => _conversations = list);
      }).catchError((_) {});
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

  Widget _buildTopBar(BuildContext context) {
    final s = context.surface;
    final activeTitle = _conversations
        .where((c) => c.id == _activeConversationId)
        .map((c) => c.title)
        .cast<String?>()
        .firstOrNull;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _historyOpen = true),
              icon: Icon(LucideIcons.menu, color: s.textSecondary, size: 21),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Vidya', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: s.textPrimary)),
                      const SizedBox(width: 4),
                      ShaderMask(
                        shaderCallback: (bounds) => AppColors.aiGradient.createShader(bounds),
                        child: const Icon(LucideIcons.bot, color: Colors.white, size: 13),
                      ),
                    ],
                  ),
                  Text(
                    activeTitle ?? 'Muni Model Study Buddy',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: s.textMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _creatingChat ? null : _startNewChat,
              icon: _creatingChat
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: s.textSecondary))
                  : Icon(LucideIcons.plus, color: s.textSecondary, size: 21),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryDrawer(BuildContext context) {
    final s = context.surface;
    final canPop = Navigator.of(context).canPop();
    final role = context.watch<AuthProvider>().user?.role;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => setState(() => _historyOpen = false),
          child: Container(color: Colors.black.withValues(alpha: 0.4)),
        ).animate().fadeIn(duration: 180.ms),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: double.infinity,
            color: s.card,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        Expanded(child: Text('Chats', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: s.textPrimary))),
                        IconButton(
                          onPressed: () => setState(() => _historyOpen = false),
                          icon: Icon(LucideIcons.x, color: s.textMuted, size: 19),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: AppRadius.mdAll,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(gradient: AppColors.aiGradient),
                          child: ElevatedButton.icon(
                            onPressed: _creatingChat ? null : _startNewChat,
                            icon: _creatingChat
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(LucideIcons.plus, size: 16),
                            label: const Text('New chat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _conversations.isEmpty
                        ? Center(
                            child: Text('No chats yet.', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: s.textMuted)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: _conversations.length,
                            itemBuilder: (context, i) {
                              final c = _conversations[i];
                              final active = c.id == _activeConversationId;
                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _selectConversation(c.id),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: active
                                        ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: AppColors.aiGradient.colors.map((c) => c.withValues(alpha: 0.1)).toList(),
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      active
                                          ? ShaderMask(
                                              shaderCallback: (bounds) => AppColors.aiGradient.createShader(bounds),
                                              child: const Icon(LucideIcons.messageSquare, size: 16, color: Colors.white),
                                            )
                                          : Icon(LucideIcons.messageSquare, size: 16, color: s.textMuted),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: active ? const Color(0xFF7C4DFF) : s.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(timeAgo(c.updatedAt), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: s.textMuted)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        if (canPop) {
                          Navigator.of(context).maybePop();
                        } else if (role != null) {
                          setState(() => _historyOpen = false);
                          context.go(roleBasePath(role));
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Icon(LucideIcons.arrowLeft, size: 16, color: s.textSecondary),
                            const SizedBox(width: 10),
                            Text(
                              canPop ? 'Back' : 'Back to Dashboard',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: s.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().slideX(begin: -1, end: 0, duration: 260.ms, curve: Curves.easeOutCubic),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Glowing background blobs matching mockup styling
        Positioned(
          top: -80,
          left: -40,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.saffron500.withValues(alpha: dark ? 0.08 : 0.04),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.25, 1.25),
                duration: 4.seconds,
                curve: Curves.easeInOut,
              ),
        ),
        Positioned(
          bottom: 120,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1).withValues(alpha: dark ? 0.08 : 0.03),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.2, 1.2),
                duration: 5.seconds,
                curve: Curves.easeInOut,
              ),
        ),

        // Main content
        Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: _loadingHistory
                  ? const LoadingView(message: 'Waking up Vidya...')
                  : _error != null
                      ? Center(child: Text(_error!, style: TextStyle(color: s.textMuted)))
                      : _switchingChat
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)))
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: _showWelcome && !_sending
                                  ? 1
                                  : _messages.length + (_sending ? 1 : 0),
                              itemBuilder: (context, i) {
                                if (_showWelcome && !_sending) {
                                  return _WelcomeView(
                                    onSelectPrompt: (prompt) {
                                      _controller.text = prompt;
                                      _send();
                                    },
                                  );
                                }
                                if (i == _messages.length) return const _TypingBubble();

                                final message = _messages[i];
                                final isNewAssistantMessage = !message.isUser &&
                                    i == _messages.length - 1 &&
                                    !_animatedMessageIds.contains(message.id);

                                return _ChatBubble(
                                  message: message,
                                  typewriter: isNewAssistantMessage,
                                  onTypewriterComplete: () {
                                    setState(() {
                                      _animatedMessageIds.add(message.id);
                                    });
                                  },
                                );
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
        ),

        if (_historyOpen) Positioned.fill(child: _buildHistoryDrawer(context)),
      ],
    );
  }
}

class _Suggestion {
  final IconData icon;
  final String title;
  final String prompt;
  const _Suggestion(this.icon, this.title, this.prompt);
}

// Mirrors the role personas AiCompanionService.rolePersona() grounds Vidya in on the
// backend, so the very first thing a user sees is already on-topic for their role and
// the Muni Model methodologies, not a generic assistant demo.
const Map<String, List<_Suggestion>> _kSuggestionsByRole = {
  'STUDENT': [
    _Suggestion(LucideIcons.bookOpen, 'UPLC Help', 'Help me do UPLC self-study for my next chapter — walk me through Understand, Problem, Learning and Communicate.'),
    _Suggestion(LucideIcons.users, 'Buddy Study Tips', 'Give me 3 tips to make my next Buddy Study session with my study buddy more effective.'),
    _Suggestion(LucideIcons.calculator, 'Vedic Math Trick', 'Teach me a quick Vedic Math trick for multiplication.'),
    _Suggestion(LucideIcons.landmark, 'Child Parliament', 'Explain what the Child Parliament is and how I can get more involved.'),
  ],
  'TEACHER': [
    _Suggestion(LucideIcons.presentation, 'Lesson Plan', "Help me plan tomorrow's lesson using Guided Discovery for my class."),
    _Suggestion(LucideIcons.users, 'Buddy System Setup', 'Give me a step-by-step plan to start the Buddy System in my class this week.'),
    _Suggestion(LucideIcons.camera, 'Evidence Tips', 'What kind of evidence should I upload today to show GRS is being implemented well?'),
    _Suggestion(LucideIcons.notebookPen, 'Daily Reflection', "Help me write today's self-reflection on how UPLC went in my class."),
  ],
  'PRINCIPAL': [
    _Suggestion(LucideIcons.chartNoAxesCombined, 'MII Score Help', "What can I do this month to improve my school's MII score?"),
    _Suggestion(LucideIcons.userCheck, 'Support a Teacher', 'Suggest how to support a teacher who is weak in implementing UPLC.'),
    _Suggestion(LucideIcons.clipboardCheck, 'Plan Observations', "Help me plan this week's classroom observations across methodologies."),
    _Suggestion(LucideIcons.calendarCheck, 'Corrective Meeting', "Draft an agenda for a corrective meeting with a teacher who's behind on evidence uploads."),
  ],
  'TRAINER': [
    _Suggestion(LucideIcons.presentation, 'Training Plan', "Help me plan this week's training session on the Buddy System."),
    _Suggestion(LucideIcons.clipboardList, 'Pre/Post Test', 'Suggest 5 questions for a pre/post test on GRS for teachers.'),
    _Suggestion(LucideIcons.messageSquare, 'Teacher Feedback', 'Help me draft constructive feedback for a teacher who needs re-training in UPLC.'),
    _Suggestion(LucideIcons.school, 'Follow-up Plan', 'What follow-up actions should I take for a school with weak Buddy System implementation?'),
  ],
  'MANAGEMENT': [
    _Suggestion(LucideIcons.chartNoAxesCombined, 'MII Overview', 'Give me a summary of which schools need urgent intervention right now.'),
    _Suggestion(LucideIcons.triangleAlert, 'Flag Weak Schools', 'Which schools are showing weak Buddy System or GRS implementation this week?'),
    _Suggestion(LucideIcons.fileText, 'Report Insight', "Summarize the network's overall implementation trend this month."),
    _Suggestion(LucideIcons.userCog, 'Trainer Assignment', 'Suggest how to reassign trainers to better support low-MII schools.'),
  ],
  'PARENT': [
    _Suggestion(LucideIcons.house, 'Ghar Ek Pathshala', 'Suggest a fun Ghar Ek Pathshala home activity I can do with my child this week.'),
    _Suggestion(LucideIcons.heart, 'Support at Home', "How can I support my child's Growth Habits at home?"),
    _Suggestion(LucideIcons.bookOpen, 'Understand Muni Model', 'Explain the Muni Model in simple terms so I can understand what my child is learning.'),
    _Suggestion(LucideIcons.trendingUp, "My Child's Progress", "Help me understand my child's recent progress and what I should focus on."),
  ],
};

class _WelcomeView extends StatelessWidget {
  final ValueChanged<String> onSelectPrompt;

  const _WelcomeView({required this.onSelectPrompt});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final user = context.watch<AuthProvider>().user;
    final fullName = user?.fullName.trim() ?? 'there';
    final firstName = fullName.split(RegExp(r'\s+')).first;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        _buildOrb(),
        const SizedBox(height: 20),
        // Welcome greeting matching mockup
        Text(
          'Hello, $firstName',
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8B5CF6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'How can I assist you today?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: s.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 32),
        _buildSuggestionsGrid(context, user?.role),
      ],
    );
  }

  Widget _buildOrb() {
    return SizedBox(
      height: 140,
      width: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow pulsing
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFC084FC).withValues(alpha: 0.25),
                  const Color(0xFFC084FC).withValues(alpha: 0.0),
                ],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
                duration: 2500.ms,
                curve: Curves.easeInOut,
              ),

          // Vidya mascot, clipped into the glowing circle
          Container(
            width: 80,
            height: 80,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC084FC).withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/divya.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              cacheWidth: 160,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: 1600.ms,
                curve: Curves.easeInOut,
              ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsGrid(BuildContext context, String? role) {
    final suggestions = _kSuggestionsByRole[role] ?? _kSuggestionsByRole['STUDENT']!;
    return Column(
      children: [
        for (var i = 0; i < suggestions.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSuggestionCard(context: context, suggestion: suggestions[i])),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < suggestions.length
                    ? _buildSuggestionCard(context: context, suggestion: suggestions[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildSuggestionCard({required BuildContext context, required _Suggestion suggestion}) {
    final s = context.surface;
    return GestureDetector(
      onTap: () => onSelectPrompt(suggestion.prompt),
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: s.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: s.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.aiGradient.createShader(bounds),
              child: Icon(suggestion.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: s.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Expanded(
              child: Text(
                suggestion.prompt,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: s.textMuted,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final AiChatMessage message;
  final bool typewriter;
  final VoidCallback? onTypewriterComplete;

  const _ChatBubble({
    required this.message,
    this.typewriter = false,
    this.onTypewriterComplete,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final isUser = message.isUser;

    if (isUser) {
      // User bubble - shrink-wraps exactly to message text width (no Row/Expanded)
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.76,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.aiGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF7722).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ).animate().fadeIn(
            duration: 350.ms,
            curve: Curves.easeOut,
          ).slideY(
            begin: 0.15,
            end: 0,
            duration: 350.ms,
            curve: Curves.easeOutCubic,
          ).scaleXY(
            begin: 0.95,
            end: 1,
            duration: 350.ms,
            curve: Curves.easeOutBack,
          );
    } else {
      // Assistant bubble - no avatar, wraps to content dynamically
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: s.card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: s.border.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left-side gradient accent strip
                Container(
                  width: 3.5,
                  height: 24,
                  margin: const EdgeInsets.only(right: 10, top: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: AppColors.aiGradient.colors,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Flexible(
                  child: typewriter
                      ? _TypewriterText(
                          text: message.content,
                          style: TextStyle(
                            color: s.textPrimary,
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                          onComplete: onTypewriterComplete,
                        )
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: s.textPrimary,
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                            strong: TextStyle(
                              color: s.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                            listBullet: TextStyle(color: s.textSecondary),
                            a: const TextStyle(color: Color(0xFF7C4DFF), decoration: TextDecoration.underline),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(
            duration: 350.ms,
            curve: Curves.easeOut,
          ).slideY(
            begin: 0.15,
            end: 0,
            duration: 350.ms,
            curve: Curves.easeOutCubic,
          ).scaleXY(
            begin: 0.95,
            end: 1,
            duration: 350.ms,
            curve: Curves.easeOutBack,
          );
    }
  }
}

class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final VoidCallback? onComplete;

  const _TypewriterText({
    required this.text,
    required this.style,
    this.onComplete,
  });

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _displayedText = "";
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    if (widget.text.isEmpty) {
      widget.onComplete?.call();
      return;
    }

    // fast fluid typewriter effect (2 chars per 15ms)
    const charsPerStep = 2;
    _timer = Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (!mounted) return;
      if (_currentIndex < widget.text.length) {
        setState(() {
          final nextIndex = (_currentIndex + charsPerStep).clamp(0, widget.text.length);
          _displayedText += widget.text.substring(_currentIndex, nextIndex);
          _currentIndex = nextIndex;
        });
      } else {
        _timer?.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: _displayedText,
      styleSheet: MarkdownStyleSheet(
        p: widget.style,
        strong: widget.style.copyWith(fontWeight: FontWeight.w800),
        listBullet: TextStyle(color: widget.style.color?.withValues(alpha: 0.7)),
        a: const TextStyle(color: Color(0xFF7C4DFF), decoration: TextDecoration.underline),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: s.card,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: s.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return Container(
                width: 6,
                height: 6,
                margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                decoration: BoxDecoration(
                  color: AppColors.aiGradient.colors[i],
                  shape: BoxShape.circle,
                ),
              ).animate(
                onPlay: (c) => c.repeat(reverse: true),
                delay: (i * 120).ms,
              ).scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1.2, 1.2),
                duration: 400.ms,
                curve: Curves.easeInOut,
              );
            }),
          ),
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
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attachedFile != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(left: 12, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.saffron500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.saffron500.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.paperclip, size: 12, color: AppColors.saffron600),
                      const SizedBox(width: 6),
                      Text(
                        attachedFile!.path.split(Platform.pathSeparator).last,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.saffron700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onClearAttachment,
                        child: const Icon(LucideIcons.x, size: 12, color: AppColors.saffron700),
                      ),
                    ],
                  ),
                ),
              ),
            // Transparent capsule pill input container — border-only, no fill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: s.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      cursorColor: const Color(0xFF7C4DFF),
                      style: TextStyle(fontSize: 14.5, color: s.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Ask me anything...',
                        hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14.5),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onAttach,
                    child: Icon(LucideIcons.paperclip, color: s.textSecondary, size: 19),
                  ),
                  const SizedBox(width: 10),
                  // Gradient send circle button
                  Material(
                    color: sending ? s.disabled : Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: sending ? null : onSend,
                      customBorder: const CircleBorder(),
                      child: Ink(
                        decoration: sending ? null : const BoxDecoration(gradient: AppColors.aiGradient, shape: BoxShape.circle),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: sending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Icon(LucideIcons.arrowUp, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
