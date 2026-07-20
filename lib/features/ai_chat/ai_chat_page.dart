import 'package:flutter/material.dart';
import 'ai_chat_screen.dart';

/// Standalone push destination for the floating AI FAB on non-Student roles
/// — has its own back button, unlike the Student "Vidya AI" tab which embeds
/// [AiChatBody] directly inside the persistent [AppShell].
class AiChatPage extends StatelessWidget {
  const AiChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AiChatBody(),
    );
  }
}
