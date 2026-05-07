import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../theme/spacing.dart';
import '../../../theme/radii.dart';
import '../../../shared/widgets/alochi_card.dart';
import '../../../core/api/teacher_api.dart';
import '../dashboard/dashboard_provider.dart';
import '../groups/groups_provider.dart';

class TelegramBroadcastScreen extends ConsumerStatefulWidget {
  const TelegramBroadcastScreen({super.key});

  @override
  ConsumerState<TelegramBroadcastScreen> createState() => _TelegramBroadcastScreenState();
}

class _TelegramBroadcastScreenState extends ConsumerState<TelegramBroadcastScreen> {
  String _selectedGroupId = 'all';
  String _messageType = 'text';
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _updateTemplate(String type, String groupName) {
    setState(() {
      _messageType = type;
      if (type == 'attendance') {
        _messageController.text = 
            "$groupName guruhining bugungi davomati:\nKeldi: 12 o'quvchi\nKelmadi: 2 o'quvchi";
      } else if (type == 'grades') {
        _messageController.text = 
            "$groupName guruhining so'nggi baholar:\nO'rtacha baho: 4.5";
      } else if (type == 'text') {
        _messageController.clear();
      }
    });
  }

  Future<void> _sendBroadcast() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Xabar matnini kiriting")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = ref.read(teacherApiProvider);
      await api.broadcastTelegramMessage(
        groupId: _selectedGroupId,
        message: _messageController.text.trim(),
        type: _messageType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Xabar yuborildi")),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('404')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Backend hali tayyor emas — V1.4 da to'liq")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Xatolik: $e")),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.ink, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Guruhga xabar yuborish",
          style: AppTextStyles.titleM.copyWith(color: AppColors.ink),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Selection
            Text("Guruhni tanlang", style: AppTextStyles.label.copyWith(color: AppColors.inkMuted)),
            const SizedBox(height: AppSpacing.s),
            groupsAsync.when(
              data: (groups) => Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.m),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGroupId,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text("Barcha guruhlar"),
                      ),
                      ...groups.map((g) => DropdownMenuItem(
                            value: g.id,
                            child: Text(g.name),
                          )),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedGroupId = val);
                    },
                  ),
                ),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text("Guruhlarni yuklab bo'lmadi", style: TextStyle(color: AppColors.danger)),
            ),
            const SizedBox(height: AppSpacing.l),

            // Message Type
            Text("Xabar turi", style: AppTextStyles.label.copyWith(color: AppColors.inkMuted)),
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: AppSpacing.s,
              children: [
                _TypeChip(
                  label: "Oddiy matn",
                  selected: _messageType == 'text',
                  onSelected: (val) => _updateTemplate('text', ''),
                ),
                _TypeChip(
                  label: "Davomat",
                  selected: _messageType == 'attendance',
                  onSelected: (val) {
                    final groupName = _selectedGroupId == 'all' 
                        ? 'Barcha' 
                        : groupsAsync.asData?.value.firstWhere((g) => g.id == _selectedGroupId).name ?? '';
                    _updateTemplate('attendance', groupName);
                  },
                ),
                _TypeChip(
                  label: "Baholar",
                  selected: _messageType == 'grades',
                  onSelected: (val) {
                    final groupName = _selectedGroupId == 'all' 
                        ? 'Barcha' 
                        : groupsAsync.asData?.value.firstWhere((g) => g.id == _selectedGroupId).name ?? '';
                    _updateTemplate('grades', groupName);
                  },
                ),
                _TypeChip(
                  label: "Maxsus",
                  selected: _messageType == 'special',
                  onSelected: (val) => setState(() => _messageType = 'special'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),

            // Message Field
            Text("Xabar matni", style: AppTextStyles.label.copyWith(color: AppColors.inkMuted)),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _messageController,
              maxLines: 6,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Xabarni shu yerga yozing...",
                contentPadding: const EdgeInsets.all(AppSpacing.m),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.m),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.m),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.m),
                  borderSide: const BorderSide(color: AppColors.brand, width: 2),
                ),
              ),
              style: AppTextStyles.bodyM,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Send Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendBroadcast,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.m),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text("Yuborish", style: AppTextStyles.titleS),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Function(bool) onSelected;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.brand.withOpacity(0.1),
      labelStyle: AppTextStyles.label.copyWith(
        color: selected ? AppColors.brand : AppColors.inkMuted,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.m),
        side: BorderSide(
          color: selected ? AppColors.brand : const Color(0xFFE5E7EB),
        ),
      ),
      backgroundColor: Colors.white,
      showCheckmark: false,
    );
  }
}
