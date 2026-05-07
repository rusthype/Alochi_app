import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_app_bar.dart';
import 'message_compose_provider.dart';

class MessageComposeScreen extends ConsumerWidget {
  const MessageComposeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messageComposeProvider);
    final notifier = ref.read(messageComposeProvider.notifier);

    ref.listen<MessageComposeState>(messageComposeProvider, (prev, next) {
      if (next.sentSuccessfully && !(prev?.sentSuccessfully ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xabar yuborildi'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AlochiAppBar(
        title: 'Yangi xabar',
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text(
            'Bekor',
            style: AppTextStyles.body.copyWith(color: AppColors.brandMuted),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.m),
            child: TextButton(
              onPressed: state.isSending ? null : () => notifier.send(),
              child: Text(
                'Yuborish',
                style: AppTextStyles.button.copyWith(
                  color: (state.recipients.isNotEmpty && state.body.isNotEmpty)
                      ? AppColors.brand
                      : AppColors.brandMuted,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _ModeSelector(
            current: state.mode,
            onChanged: notifier.setMode,
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _RecipientInput(
            recipients: state.recipients,
            onRemove: notifier.removeRecipient,
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                children: [
                  TextField(
                    onChanged: notifier.setSubject,
                    style: AppTextStyles.titleM,
                    decoration: InputDecoration(
                      hintText: 'Mavzu (ixtiyoriy)',
                      hintStyle: AppTextStyles.titleM
                          .copyWith(color: AppColors.brandMuted),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextField(
                    onChanged: notifier.setBody,
                    maxLines: null,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Matnni kiriting...',
                      hintStyle: AppTextStyles.body
                          .copyWith(color: AppColors.brandMuted),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _ComposerToolbar(),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final ComposeMode current;
  final ValueChanged<ComposeMode> onChanged;

  const _ModeSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l, vertical: AppSpacing.m),
      child: Row(
        children: [
          _ModeItem(
            label: 'Bitta',
            isSelected: current == ComposeMode.single,
            onTap: () => onChanged(ComposeMode.single),
          ),
          const SizedBox(width: AppSpacing.m),
          _ModeItem(
            label: 'Sinfga',
            isSelected: current == ComposeMode.group,
            onTap: () => onChanged(ComposeMode.group),
          ),
          const SizedBox(width: AppSpacing.m),
          _ModeItem(
            label: 'Bir nechta',
            isSelected: current == ComposeMode.multiple,
            onTap: () => onChanged(ComposeMode.multiple),
          ),
        ],
      ),
    );
  }
}

class _ModeItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.round),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isSelected ? AppColors.brand : AppColors.brandMuted,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _RecipientInput extends StatelessWidget {
  final List<RecipientRef> recipients;
  final ValueChanged<String> onRemove;

  const _RecipientInput({required this.recipients, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l, vertical: AppSpacing.s),
      child: Row(
        children: [
          Text(
            'Kimga:',
            style: AppTextStyles.bodyS.copyWith(color: AppColors.brandMuted),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...recipients.map((r) => _RecipientChip(
                      ref: r,
                      onDelete: () => onRemove(r.id),
                    )),
                if (recipients.isEmpty)
                  Text(
                    'Tanlanmagan',
                    style: AppTextStyles.bodyS
                        .copyWith(color: AppColors.brandMuted),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.brand),
            onPressed: () {
              // In real app, open recipient picker
            },
          ),
        ],
      ),
    );
  }
}

class _RecipientChip extends StatelessWidget {
  final RecipientRef ref;
  final VoidCallback onDelete;

  const _RecipientChip({required this.ref, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(AppRadii.round),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(ref.name, style: AppTextStyles.label),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close_rounded,
                size: 14, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

class _ComposerToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l,
          MediaQuery.of(context).padding.bottom + AppSpacing.s),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file_rounded,
                color: AppColors.brandMuted),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.image_outlined, color: AppColors.brandMuted),
            onPressed: () {},
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(AppRadii.round),
            ),
            child: Row(
              children: [
                const Icon(Icons.send_rounded,
                    color: Color(0xFF0EA5E9), size: 14),
                const SizedBox(width: 4),
                Text(
                  'Telegram orqali',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF0EA5E9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
