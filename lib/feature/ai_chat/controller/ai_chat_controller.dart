import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/feature/ai_chat/model/ai_chat_message.dart';
import 'package:demandium/feature/ai_chat/model/ai_chat_ui.dart';

class AiChatController extends GetxController implements GetxService {
  AiChatRepo get aiChatRepo => Get.find<AiChatRepo>();

  final List<AiChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isLoading = false;
  bool _enabled = true;
  bool _showOpenCartHint = false;

  List<AiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get isLoading => _isLoading;
  bool get enabled => _enabled;
  bool get showOpenCartHint => _showOpenCartHint;

  Future<void> loadConversation() async {
    if (!Get.find<AuthController>().isLoggedIn()) {
      _setWelcomeOnly();
      update();
      return;
    }

    _isLoading = true;
    update();

    final response = await aiChatRepo.getConversation();
    if (response.statusCode == 200 && response.body['content'] != null) {
      final content = response.body['content'];
      _enabled = content['enabled'] == true || content['enabled'] == 1;
      _applyMessagesFromContent(content);
    } else {
      if (response.statusCode != 403) {
        ApiChecker.checkApi(response);
      }
      _setWelcomeOnly();
    }

    _isLoading = false;
    update();
  }

  bool get isAwaitingServiceDescription {
    for (var i = _messages.length - 1; i >= 0; i--) {
      if (!_messages[i].isUser) {
        return _messages[i].awaitingInput;
      }
    }
    return false;
  }

  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _isTyping || !_enabled) return;

    if (!Get.find<AuthController>().isLoggedIn()) {
      Get.toNamed(RouteHelper.getSignInRoute(redirectUrl: RouteHelper.home));
      return;
    }

    // Always use the server AI endpoint so booking, Hinglish, and wizard steps
    // are handled in one place (panun-admin mobile app AI).
    _messages.add(AiChatMessage(text: text, isUser: true, createdAt: DateTime.now()));
    _isTyping = true;
    update();

    final response = await aiChatRepo.sendMessage(text);
    _isTyping = false;

    if (response.statusCode == 200 && response.body['content'] != null) {
      _applyMessagesFromContent(response.body['content']);
    } else {
      if (response.statusCode != 403) {
        ApiChecker.checkApi(response);
      }
      _messages.add(AiChatMessage(
        text: _apiErrorMessage(response) ?? 'ai_chat_send_failed'.tr,
        isUser: false,
        createdAt: DateTime.now(),
      ));
    }

    update();
  }

  Future<void> startBooking({String? query}) async {
    await performBookingAction(
      action: query != null && query.trim().isNotEmpty ? 'search' : 'start',
      query: query?.trim(),
    );
  }

  Future<void> performQuickIntent(String intent, {String? query}) async {
    if (_isTyping || !_enabled) return;
    if (!Get.find<AuthController>().isLoggedIn()) {
      Get.toNamed(RouteHelper.getSignInRoute(redirectUrl: RouteHelper.home));
      return;
    }

    _isTyping = true;
    update();

    final response = await aiChatRepo.quickIntent(intent, query: query);
    _isTyping = false;

    if (response.statusCode == 200 && response.body['content'] != null) {
      _applyMessagesFromContent(response.body['content']);
    } else {
      if (response.statusCode != 403) {
        ApiChecker.checkApi(response);
      }
    }
    update();
  }

  Future<void> handlePanelAction(
    String action, {
    String? choice,
    bool? asap,
    String? when,
    String? query,
  }) async {
    switch (action) {
      case 'start_booking':
        await startBooking();
        break;
      case 'booking_status':
        await performQuickIntent('booking_status', query: query ?? choice);
        break;
      case 'human_support':
        await performQuickIntent('human_support');
        break;
      case 'troubleshoot':
        await performQuickIntent('troubleshoot', query: query ?? choice);
        break;
      case 'more_triage_tips':
        await performBookingAction(action: 'more_triage_tips');
        break;
      case 'confirm_cart_action':
        await performBookingAction(action: 'confirm_cart_action', choice: choice);
        break;
      case 'cancel_cart_action':
        await performBookingAction(action: 'cancel_cart_action', choice: choice);
        break;
      case 'proceed_booking':
      case 'book_now':
        await performBookingAction(action: 'proceed_booking');
        break;
      default:
        await performBookingAction(
          action: action,
          choice: choice,
          asap: asap,
          when: when,
          query: query,
          message: query,
        );
    }
  }

  Future<void> performBookingAction({
    required String action,
    String? choice,
    String? query,
    String? message,
    bool? asap,
    String? when,
  }) async {
    if (_isTyping || !_enabled) return;

    if (!Get.find<AuthController>().isLoggedIn()) {
      Get.toNamed(RouteHelper.getSignInRoute(redirectUrl: RouteHelper.home));
      return;
    }

    if (action == 'pick' && choice == 'new') {
      await Get.toNamed(RouteHelper.getAddAddressRoute(false));
      await performBookingAction(action: 'pick', choice: 'done');
      return;
    }

    _isTyping = true;
    update();

    final body = <String, dynamic>{'action': action};
    if (choice != null && choice.isNotEmpty) body['choice'] = choice;
    if (query != null && query.isNotEmpty) body['query'] = query;
    if (message != null && message.isNotEmpty) body['message'] = message;
    if (asap == true) body['asap'] = true;
    if (when != null && when.isNotEmpty) body['when'] = when;

    final response = await aiChatRepo.bookingAction(body);
    _isTyping = false;

    if (response.statusCode == 200 && response.body['content'] != null) {
      _applyMessagesFromContent(response.body['content']);
    } else {
      if (response.statusCode != 403) {
        ApiChecker.checkApi(response);
      }
      _messages.add(AiChatMessage(
        text: _apiErrorMessage(response) ?? 'ai_chat_send_failed'.tr,
        isUser: false,
        createdAt: DateTime.now(),
      ));
    }

    update();
  }

  void _applyMessagesFromContent(Map content) {
    _enabled = content['enabled'] == true || content['enabled'] == 1;
    final cartUpdated = content['cart_updated'] == true || content['cart_updated'] == 1;
    if (cartUpdated) {
      _showOpenCartHint = true;
      if (Get.isRegistered<CartController>()) {
        Get.find<CartController>().getCartListFromServer(
          shouldUpdate: true,
          forceFromServer: true,
        );
      }
    }

    final list = content['messages'];
    if (list is List) {
      _messages.clear();
      if (list.isEmpty) {
        _setWelcomeOnly();
        return;
      }
      for (final item in list) {
        if (item is Map) {
          _messages.add(_messageFromApi(item));
        }
      }
      return;
    }

    final reply = content['reply']?.toString();
    if (reply != null && reply.isNotEmpty) {
      AiChatUi? ui;
      if (content['ui'] is Map) {
        ui = AiChatUi.fromJson(Map<String, dynamic>.from(content['ui'] as Map));
      }
      _messages.add(AiChatMessage(
        text: reply,
        isUser: false,
        createdAt: DateTime.now(),
        ui: ui,
      ));
    }
  }

  String? _apiErrorMessage(Response response) {
    final body = response.body;
    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    return response.statusText;
  }

  void dismissOpenCartHint() {
    _showOpenCartHint = false;
    update();
  }

  Future<void> clearChat() async {
    if (!Get.find<AuthController>().isLoggedIn()) {
      _setWelcomeOnly();
      update();
      return;
    }

    _isLoading = true;
    update();

    final response = await aiChatRepo.clearConversation();
    if (response.statusCode == 200) {
      _showOpenCartHint = false;
      _messages.clear();
      _setWelcomeOnly();
    } else {
      ApiChecker.checkApi(response);
    }

    _isLoading = false;
    update();
  }

  void ensureWelcomeMessage() {
    if (_messages.isEmpty) {
      _setWelcomeOnly();
      update();
    }
  }

  void _setWelcomeOnly() {
    _messages.clear();
    _messages.add(AiChatMessage(
      text: 'ai_chat_welcome'.tr,
      isUser: false,
      createdAt: DateTime.now(),
      ui: AiChatUi.welcomeActions(),
    ));
  }

  AiChatMessage _messageFromApi(Map item) {
    final role = item['role']?.toString() ?? 'assistant';
    AiChatUi? ui;
    if (item['ui'] is Map) {
      ui = AiChatUi.fromJson(Map<String, dynamic>.from(item['ui'] as Map));
    }
    return AiChatMessage(
      text: item['body']?.toString() ?? '',
      isUser: role == 'user',
      createdAt: DateTime.tryParse(item['created_at']?.toString() ?? '') ?? DateTime.now(),
      ui: ui,
      awaitingInput: item['awaiting_input'] == true || item['awaiting_input'] == 1,
    );
  }
}
