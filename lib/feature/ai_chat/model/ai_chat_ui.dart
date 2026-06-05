import 'package:get/get.dart';

class AiChatUi {
  final String type;
  final String? step;
  final String? title;
  final String? subtitle;
  final String? layout;
  final String? helpTip;
  final List<AiChatFlowStep> flowSteps;
  final List<AiChatCard> cards;
  final List<AiChatAction> actions;
  final List<AiChatAction> footerActions;
  final List<AiChatSummaryLine> summaryLines;
  final bool compact;

  const AiChatUi({
    required this.type,
    this.step,
    this.title,
    this.subtitle,
    this.layout,
    this.helpTip,
    this.compact = false,
    this.flowSteps = const [],
    this.cards = const [],
    this.actions = const [],
    this.footerActions = const [],
    this.summaryLines = const [],
  });

  bool get isBookingWizard => type == 'booking_wizard' || type == 'booking_done';

  bool get hasInteractiveUi =>
      (isBookingWizard && _hasTappableContent) ||
      type == 'booking_status_list' ||
      type == 'booking_status_detail' ||
      type == 'assistant_actions' ||
      type == 'service_triage' ||
      type == 'cart_confirm' ||
      type == 'cart_summary' ||
      type == 'cart_line_pick' ||
      type == 'service_confirm' ||
      type == 'coupon_confirm' ||
      type == 'bid_confirm' ||
      type == 'booking_cancel_confirm' ||
      type == 'qty_confirm';

  bool get _hasTappableContent {
    if (layout == 'none' || layout == 'prompt') return false;
    return cards.isNotEmpty ||
        actions.isNotEmpty ||
        footerActions.isNotEmpty ||
        layout == 'summary' ||
        layout == 'actions';
  }

  /// In-chat quick actions shown under the welcome / help message (not in the app bar).
  factory AiChatUi.welcomeActions() {
    return AiChatUi(
      type: 'assistant_actions',
      layout: 'actions',
      actions: [
        AiChatAction(
          action: 'start_booking',
          label: 'ai_chat_suggest_book'.tr,
          style: 'primary',
          icon: 'home_repair_service',
        ),
        AiChatAction(
          action: 'booking_status',
          label: 'ai_chat_suggest_status'.tr,
          style: 'outline',
          icon: 'event',
        ),
        AiChatAction(
          action: 'troubleshoot',
          choice: 'app help',
          label: 'ai_chat_suggest_help'.tr,
          style: 'outline',
          icon: 'help_outline',
        ),
        AiChatAction(
          action: 'human_support',
          label: 'ai_chat_suggest_support'.tr,
          style: 'text',
          icon: 'support',
        ),
      ],
    );
  }

  factory AiChatUi.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const AiChatUi(type: 'none');
    }
    return AiChatUi(
      type: json['type']?.toString() ?? 'none',
      step: json['step']?.toString(),
      title: json['title']?.toString(),
      subtitle: _translateKey(json['subtitle']?.toString()),
      layout: json['layout']?.toString(),
      helpTip: json['help_tip']?.toString(),
      compact: json['compact'] == true || json['compact'] == 1,
      flowSteps: (json['flow_steps'] as List?)
              ?.map((e) => AiChatFlowStep.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      cards: (json['cards'] as List?)
              ?.map((e) => AiChatCard.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      actions: (json['actions'] as List?)
              ?.map((e) => AiChatAction.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      footerActions: (json['footer_actions'] as List?)
              ?.map((e) => AiChatAction.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      summaryLines: (json['summary_lines'] as List?)
              ?.map((e) => AiChatSummaryLine.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }

  static String? _translateKey(String? key) {
    if (key == null || key.isEmpty) return key;
    if (key.contains('_') && !key.contains(' ')) {
      return key.tr;
    }
    return key;
  }
}

class AiChatFlowStep {
  final String key;
  final String label;
  final bool active;
  final bool done;

  const AiChatFlowStep({
    required this.key,
    required this.label,
    required this.active,
    required this.done,
  });

  factory AiChatFlowStep.fromJson(Map<String, dynamic> json) {
    return AiChatFlowStep(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      active: json['active'] == true || json['active'] == 1,
      done: json['done'] == true || json['done'] == 1,
    );
  }
}

class AiChatCard {
  final String choice;
  final String title;
  final String? subtitle;
  final String? icon;
  final bool highlight;

  const AiChatCard({
    required this.choice,
    required this.title,
    this.subtitle,
    this.icon,
    this.highlight = false,
  });

  factory AiChatCard.fromJson(Map<String, dynamic> json) {
    return AiChatCard(
      choice: json['choice']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      icon: json['icon']?.toString(),
      highlight: json['highlight'] == true || json['highlight'] == 1,
    );
  }
}

class AiChatAction {
  final String action;
  final String? choice;
  final String label;
  final String? subtitle;
  final String style;
  final String? icon;

  const AiChatAction({
    required this.action,
    this.choice,
    required this.label,
    this.subtitle,
    this.style = 'primary',
    this.icon,
  });

  factory AiChatAction.fromJson(Map<String, dynamic> json) {
    return AiChatAction(
      action: json['action']?.toString() ?? '',
      choice: json['choice']?.toString(),
      label: json['label']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      style: json['style']?.toString() ?? 'primary',
      icon: json['icon']?.toString(),
    );
  }
}

class AiChatSummaryLine {
  final String label;
  final String value;

  const AiChatSummaryLine({required this.label, required this.value});

  factory AiChatSummaryLine.fromJson(Map<String, dynamic> json) {
    return AiChatSummaryLine(
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }
}
