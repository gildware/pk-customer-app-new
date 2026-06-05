import 'package:demandium/feature/ai_chat/model/ai_chat_ui.dart';

class AiChatMessage {
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final AiChatUi? ui;
  final bool awaitingInput;

  const AiChatMessage({
    required this.text,
    required this.isUser,
    required this.createdAt,
    this.ui,
    this.awaitingInput = false,
  });
}
