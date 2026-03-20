import 'package:flutter/material.dart';
import '../constants/colors.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: kTextMuted),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(color: kTextSecondary, fontSize: 16),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
