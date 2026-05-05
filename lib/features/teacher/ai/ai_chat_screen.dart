import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import 'ai_provider.dart';

// ─── Suggested prompts ───────────────────────────────────────────────────────

const _kSuggestedPrompts = [
  'Bugungi darslar',
  '5-guruh tahlili',
  'Vazifa yaratish',
  'Davomat hisoboti',
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    await ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);
    if (chatState.messages.isNotEmpty) _scrollToBottom();

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      appBar: _AiChatAppBar(),
      body: Column(
        children: [
          // Suggested prompts — show when no messages yet
          if (chatState.messages.isEmpty && !chatState.isLoadingHistory)
            _SuggestedPrompts(
              onTap: (prompt) {
                _controller.text = prompt;
                _send(prompt);
              },
            ),
          // Message list
          Expanded(
            child: chatState.isLoadingHistory
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.brand),
                  )
                : chatState.messages.isEmpty
                    ? const _WelcomePlaceholder()
                    : _AiMessagesList(
                        messages: chatState.messages,
                        isSending: chatState.isSending,
                        scrollController: _scrollController,
                      ),
          ),
          // Error banner
          if (chatState.errorMessage != null)
            _ErrorBanner(message: chatState.errorMessage!),
          // Composer
          _AiComposer(
            controller: _controller,
            isSending: chatState.isSending,
            onSend: () => _send(_controller.text),
          ),
        ],
      ),
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────

class _AiChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.ink, size: 20),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/teacher/dashboard');
          }
        },
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: AppSpacing.s),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AI Yordamchi',
                style: AppTextStyles.titleM
                    .copyWith(color: AppColors.ink, fontSize: 14),
              ),
              Text(
                'Pedagogik yordamchi',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.brandMuted),
              ),
            ],
          ),
        ],
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE5E7EB)),
      ),
    );
  }
}

// ─── Suggested prompts ───────────────────────────────────────────────────────

class _SuggestedPrompts extends StatelessWidget {
  final void Function(String) onTap;

  const _SuggestedPrompts({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m, vertical: AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tezkor savol:',
            style: AppTextStyles.caption.copyWith(color: AppColors.brandMuted),
          ),
          const SizedBox(height: AppSpacing.s),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _kSuggestedPrompts.map((prompt) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s),
                  child: GestureDetector(
                    onTap: () => onTap(prompt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m, vertical: AppSpacing.s),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(AppRadii.round),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        prompt,
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.accentInk),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
        ],
      ),
    );
  }
}

// ─── Welcome placeholder ─────────────────────────────────────────────────────

class _WelcomePlaceholder extends StatelessWidget {
  const _WelcomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 56,
              color: AppColors.accent.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              "Salom! Qanday yordam kerak?",
              style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              "Yuqoridagi tezkor savollandan birini tanlang yoki o'zingiz yozing",
              style: AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Messages list ────────────────────────────────────────────────────────────

class _AiMessagesList extends StatelessWidget {
  final List<AiChatMessage> messages;
  final bool isSending;
  final ScrollController scrollController;

  const _AiMessagesList({
    required this.messages,
    required this.isSending,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final count = messages.length + (isSending ? 1 : 0);
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m, vertical: AppSpacing.m),
      itemCount: count,
      itemBuilder: (context, index) {
        if (isSending && index == messages.length) {
          return const _AiTypingIndicator();
        }
        return _AiMessageBubble(message: messages[index]);
      },
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _AiMessageBubble extends StatelessWidget {
  final AiChatMessage message;

  const _AiMessageBubble({required this.message});

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: AppSpacing.s, bottom: 4),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: Colors.white, size: 14),
            ),
          ],
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                top: 2,
                bottom: 2,
                left: isUser ? 60 : 0,
                right: isUser ? 0 : 60,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: isUser ? AppColors.brand : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 18),
                ),
                border:
                    isUser ? null : Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: isUser
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.text,
                    style: AppTextStyles.body.copyWith(
                      color: isUser ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: AppTextStyles.caption.copyWith(
                      color: isUser
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.brandMuted,
                      fontSize: 10,
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
}

// ─── Typing indicator ─────────────────────────────────────────────────────────

class _AiTypingIndicator extends StatefulWidget {
  const _AiTypingIndicator();

  @override
  State<_AiTypingIndicator> createState() => _AiTypingIndicatorState();
}

class _AiTypingIndicatorState extends State<_AiTypingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: AppSpacing.s, bottom: 4),
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: Colors.white, size: 14),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2, bottom: 2),
            padding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: FadeTransition(
              opacity: _opacity,
              child: Text(
                "AI o'ylayapti...",
                style: AppTextStyles.bodyS
                    .copyWith(color: AppColors.brandMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m, vertical: AppSpacing.s),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m, vertical: AppSpacing.s),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(AppRadii.s),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 16),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(color: AppColors.danger),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Composer ─────────────────────────────────────────────────────────────────

class _AiComposer extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _AiComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  State<_AiComposer> createState() => _AiComposerState();
}

class _AiComposerState extends State<_AiComposer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.m,
        right: AppSpacing.m,
        top: AppSpacing.s,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.s,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: widget.controller,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: AppTextStyles.body.copyWith(color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Savolingizni yozing...',
                  hintStyle:
                      AppTextStyles.body.copyWith(color: AppColors.brandMuted),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.round),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.round),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.round),
                    borderSide: const BorderSide(
                        color: AppColors.accent, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          GestureDetector(
            onTap: (_hasText && !widget.isSending) ? widget.onSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hasText ? AppColors.accent : const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
              ),
              child: widget.isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color:
                          _hasText ? Colors.white : AppColors.brandMuted,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
