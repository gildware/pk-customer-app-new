import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/feature/ai_chat/model/ai_chat_message.dart';
import 'package:demandium/feature/ai_chat/widget/ai_chat_booking_panel.dart';
import 'package:demandium/feature/ai_chat/widget/ai_chat_markdown_text.dart';

class AiChatScreen extends StatefulWidget {
  final bool embedInBottomNav;
  const AiChatScreen({super.key, this.embedInBottomNav = false});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<AiChatRepo>()) {
      Get.lazyPut(() => AiChatRepo(apiClient: Get.find()));
    }
    if (!Get.isRegistered<AiChatController>()) {
      Get.lazyPut(() => AiChatController());
    }
    Get.find<AiChatController>().loadConversation();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'ai_chat'.tr,
        isBackButtonExist: !widget.embedInBottomNav,
        centerTitle: !widget.embedInBottomNav,
        actionWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'ai_chat_clear'.tr,
              onPressed: () => Get.find<AiChatController>().clearChat(),
              icon: Icon(Icons.refresh, color: Theme.of(context).primaryColorLight),
            ),
            IconButton(
              tooltip: 'help_&_support'.tr,
              onPressed: () => Get.toNamed(RouteHelper.getSupportRoute()),
              icon: Icon(Icons.support_agent, color: Theme.of(context).primaryColorLight),
            ),
          ],
        ),
      ),
      body: GetBuilder<AiChatController>(
        builder: (controller) {
          _scrollToBottom();
          if (controller.isLoading && controller.messages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              if (!controller.enabled)
                Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Text(
                    'ai_chat_disabled'.tr,
                    style: robotoRegular.copyWith(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (controller.showOpenCartHint)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeSmall,
                    Dimensions.paddingSizeDefault,
                    0,
                  ),
                  child: Material(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: ListTile(
                      leading: Icon(Icons.shopping_cart_outlined, color: Theme.of(context).colorScheme.primary),
                      title: Text('ai_chat_open_cart_hint'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
                      trailing: TextButton(
                        onPressed: () {
                          controller.dismissOpenCartHint();
                          Get.toNamed(RouteHelper.getCartRoute());
                        },
                        child: Text('my_cart'.tr),
                      ),
                      onTap: () {
                        controller.dismissOpenCartHint();
                        Get.toNamed(RouteHelper.getCartRoute());
                      },
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  itemCount: controller.messages.length + (controller.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (controller.isTyping && index == controller.messages.length) {
                      return _TypingBubble();
                    }
                    final message = controller.messages[index];
                    return _ChatBubble(
                      message: message,
                      bookingEnabled: controller.enabled && !controller.isTyping,
                      onBookingTap: (action, {choice, asap, when, query}) {
                        Get.find<AiChatController>().handlePanelAction(
                          action,
                          choice: choice,
                          asap: asap,
                          when: when,
                          query: query,
                        );
                      },
                    );
                  },
                ),
              ),
              _ChatInputBar(
                controller: _inputController,
                isLoading: controller.isTyping,
                hintText: controller.isAwaitingServiceDescription
                    ? 'ai_chat_booking_service_hint'.tr
                    : 'ai_chat_hint'.tr,
                onSend: (text) {
                  Get.find<AiChatController>().sendMessage(text);
                  _inputController.clear();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final AiChatMessage message;
  final bool bookingEnabled;
  final AiBookingTap onBookingTap;

  const _ChatBubble({
    required this.message,
    required this.bookingEnabled,
    required this.onBookingTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final hasUi = !isUser && message.ui != null && message.ui!.hasInteractiveUi;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).cardColor;
    final textColor = isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color;
    final maxWidth = hasUi
        ? MediaQuery.sizeOf(context).width * 0.92
        : MediaQuery.sizeOf(context).width * 0.78;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: hasUi ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeSmall,
        ),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(Dimensions.radiusDefault),
            topRight: const Radius.circular(Dimensions.radiusDefault),
            bottomLeft: Radius.circular(isUser ? Dimensions.radiusDefault : 0),
            bottomRight: Radius.circular(isUser ? 0 : Dimensions.radiusDefault),
          ),
          border: isUser ? null : Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    child: Icon(Icons.auto_awesome, size: 16, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                ],
                Flexible(
                  child: isUser
                      ? Text(
                          message.text,
                          style: robotoRegular.copyWith(color: textColor, fontSize: Dimensions.fontSizeDefault),
                        )
                      : AiChatMarkdownText(
                          text: message.text,
                          color: textColor,
                        ),
                ),
              ],
            ),
            if (hasUi) ...[
              const SizedBox(height: Dimensions.paddingSizeDefault),
              AiChatBookingPanel(
                ui: message.ui!,
                enabled: bookingEnabled,
                onTap: onBookingTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        child: Text('ai_chat_thinking'.tr, style: robotoRegular.copyWith(
          color: Theme.of(context).hintColor,
          fontStyle: FontStyle.italic,
        )),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final String hintText;
  final ValueChanged<String> onSend;

  const _ChatInputBar({
    required this.controller,
    required this.isLoading,
    required this.hintText,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          Dimensions.paddingSizeDefault,
          Dimensions.paddingSizeSmall,
          Dimensions.paddingSizeDefault,
          Dimensions.paddingSizeDefault,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: isLoading ? null : onSend,
                decoration: InputDecoration(
                  hintText: hintText,
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: Dimensions.paddingSizeSmall,
                  ),
                ),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Material(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              child: InkWell(
                onTap: isLoading ? null : () => onSend(controller.text),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).primaryColorLight,
                          ),
                        )
                      : Icon(Icons.send_rounded, color: Theme.of(context).primaryColorLight),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
