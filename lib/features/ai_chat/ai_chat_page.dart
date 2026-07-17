import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import 'ai_chat_screen.dart';

/// Standalone push destination for the floating AI FAB on non-Student roles
/// — has its own back button, unlike the Student "Vidya AI" tab which embeds
/// [AiChatBody] directly inside the persistent [AppShell].
class AiChatPage extends StatelessWidget {
  const AiChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.saffron400, AppColors.saffron600]), shape: BoxShape.circle),
              child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Vidya AI'),
          ],
        ),
      ),
      body: const AiChatBody(),
    );
  }
}
