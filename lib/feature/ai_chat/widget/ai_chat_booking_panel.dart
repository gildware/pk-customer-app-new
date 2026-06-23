import 'package:demandium/feature/ai_chat/model/ai_chat_ui.dart';
import 'package:demandium/feature/cart/widget/booking_date_time_picker.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
typedef AiBookingTap = void Function(
  String action, {
  String? choice,
  bool? asap,
  String? when,
  String? query,
});

class AiChatBookingPanel extends StatelessWidget {
  final AiChatUi ui;
  final AiBookingTap onTap;
  final bool enabled;

  const AiChatBookingPanel({
    super.key,
    required this.ui,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (ui.type == 'booking_done') {
      return _donePanel(context);
    }
    if (ui.type == 'service_triage'
        || ui.type == 'cart_confirm'
        || ui.type == 'cart_summary'
        || ui.type == 'cart_line_pick'
        || ui.type == 'service_confirm'
        || ui.type == 'coupon_confirm'
        || ui.type == 'bid_confirm'
        || ui.type == 'booking_cancel_confirm'
        || ui.type == 'qty_confirm'
        || (ui.hasInteractiveUi && !ui.isBookingWizard)) {
      return _generalAssistantPanel(context);
    }

    final showHeader = !ui.compact
        && (ui.flowSteps.isNotEmpty
            || (ui.title != null && ui.title!.isNotEmpty)
            || (ui.subtitle != null && ui.subtitle!.isNotEmpty)
            || (ui.helpTip != null && ui.helpTip!.isNotEmpty));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!ui.compact && ui.flowSteps.isNotEmpty) ...[
          _BookingStepIndicator(steps: ui.flowSteps),
          const SizedBox(height: Dimensions.paddingSizeDefault),
        ],
        if (!ui.compact && ui.title != null && ui.title!.isNotEmpty)
          Text(ui.title!, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
        if (!ui.compact && ui.subtitle != null && ui.subtitle!.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
            ui.subtitle!,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
        if (!ui.compact && ui.helpTip != null && ui.helpTip!.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Expanded(
                  child: Text(
                    ui.helpTip!,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (showHeader) const SizedBox(height: Dimensions.paddingSizeSmall),
        if (ui.layout == 'cards') ..._cardList(context),
        if (ui.layout == 'actions') ..._actionList(context),
        if (ui.layout == 'summary') ...[
          _summaryCard(context),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          ..._actionList(context, actions: ui.actions),
        ],
        if (ui.footerActions.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          ..._actionList(context, actions: ui.footerActions),
        ],
      ],
    );
  }

  Widget _donePanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _actionList(context, actions: ui.actions),
    );
  }

  List<Widget> _cardList(BuildContext context) {
    return ui.cards.map((card) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        child: Material(
          color: card.highlight
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.06)
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: InkWell(
            onTap: enabled ? () => _onCardTap(card) : null,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(
                  color: card.highlight
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).hintColor.withValues(alpha: 0.25),
                  width: card.highlight ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  _IconBadge(iconName: card.icon, highlight: card.highlight),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(card.title, style: robotoMedium),
                        if (card.subtitle != null && card.subtitle!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              card.subtitle!,
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).hintColor,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _onCardTap(AiChatCard card) {
    if (ui.type == 'cart_line_pick' || ui.type == 'cart_summary') {
      onTap('pick_cart_remove', choice: card.choice);
      return;
    }
    if (ui.type == 'booking_status_list') {
      onTap('booking_status', query: card.choice);
      return;
    }
    if (ui.step == 'schedule') return;
    if (ui.step == 'address' && card.choice == 'new') {
      onTap('pick', choice: 'new');
      return;
    }
    onTap('pick', choice: card.choice);
  }

  Widget _generalAssistantPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ui.title != null && ui.title!.isNotEmpty)
          Text(ui.title!, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
        if (ui.subtitle != null && ui.subtitle!.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
            ui.subtitle!,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
        const SizedBox(height: Dimensions.paddingSizeSmall),
        if (ui.layout == 'cards') ..._cardList(context),
        if (ui.layout == 'summary') ...[
          _summaryCard(context),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ],
        if (ui.actions.isNotEmpty) ..._actionList(context, actions: ui.actions),
        if (ui.footerActions.isNotEmpty) ..._actionList(context, actions: ui.footerActions),
      ],
    );
  }

  List<Widget> _actionList(BuildContext context, {List<AiChatAction>? actions}) {
    final list = actions ?? ui.actions;
    return list.map((act) {
      final isPrimary = act.style == 'primary';
      final isText = act.style == 'text';
      if (isText) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
          child: TextButton.icon(
            onPressed: enabled ? () => _onActionTap(act) : null,
            icon: Icon(_iconData(act.icon), size: 18),
            label: Text(act.label),
          ),
        );
      }
      final isOutline = act.style == 'outline';
      return Padding(
        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        child: CustomButton(
          height: 44,
          buttonText: act.label,
          backgroundColor: isPrimary
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).cardColor,
          textColor: isPrimary ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          showBorder: isOutline,
          transparent: isOutline,
          onPressed: enabled ? () => _onActionTap(act) : null,
        ),
      );
    }).toList();
  }

  void _onActionTap(AiChatAction act) {
    if (act.action == 'open_cart') {
      Get.toNamed(RouteHelper.getCartRoute());
      return;
    }
    if (act.action == 'open_bookings') {
      Get.offAllNamed('${RouteHelper.home}?page=booking');
      return;
    }
    if (act.action == 'open_biddings') {
      Get.offAllNamed('${RouteHelper.home}?page=biddings');
      return;
    }
    if (act.action == 'open_support') {
      Get.toNamed(RouteHelper.getSupportRoute());
      return;
    }
    if (act.action == 'call_support') {
      _callSupportPhone();
      return;
    }
    if (act.action == 'start_booking' || act.action == 'start') {
      onTap('start_booking');
      return;
    }
    if (act.action == 'booking_status') {
      onTap('booking_status', query: act.choice);
      return;
    }
    if (act.action == 'human_support') {
      onTap('human_support');
      return;
    }
    if (act.action == 'troubleshoot') {
      onTap('troubleshoot', query: act.choice);
      return;
    }
    if (act.action == 'more_triage_tips') {
      onTap('more_triage_tips');
      return;
    }
    if (act.action == 'confirm_cart_action') {
      onTap('confirm_cart_action', choice: act.choice);
      return;
    }
    if (act.action == 'cancel_cart_action') {
      onTap('cancel_cart_action', choice: act.choice);
      return;
    }
    if (act.action == 'confirm_coupon_action' || act.action == 'cancel_coupon_action'
        || act.action == 'confirm_bid_action' || act.action == 'cancel_bid_action'
        || act.action == 'confirm_booking_cancel_action' || act.action == 'cancel_booking_cancel_action'
        || act.action == 'confirm_cart_qty_action' || act.action == 'cancel_cart_qty_action') {
      onTap(act.action, choice: act.choice);
      return;
    }
    if (act.action == 'proceed_booking' || act.action == 'book_now') {
      onTap('proceed_booking');
      return;
    }
    if (act.action == 'confirm_service') {
      onTap('confirm_service', choice: act.choice);
      return;
    }
    if (act.action == 'show_service_options') {
      onTap('show_service_options', choice: act.choice);
      return;
    }
    if (act.action == 'search') {
      onTap('start_booking');
      return;
    }
    if (act.action == 'time' && act.choice == 'pick_datetime') {
      _openDateTimePicker();
      return;
    }
    if (act.action == 'time') {
      onTap('time', choice: act.choice, asap: act.choice == 'asap');
      return;
    }
    onTap(act.action, choice: act.choice);
  }

  void _openDateTimePicker() {
    final scheduleController = Get.find<ScheduleController>();
    scheduleController.updateScheduleType(scheduleType: ScheduleType.schedule, shouldUpdate: false);
    final min = BookingDateTimePicker.minimumScheduleTime();
    scheduleController.selectedDate = DateFormat('yyyy-MM-dd').format(min);
    scheduleController.selectedTime = DateFormat('HH:mm:ss').format(min);
    scheduleController.scheduleTime = null;
    scheduleController.update();

    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BookingDateTimePicker(),
    ).then((_) {
      final parsed = BookingDateTimePicker.parseSelectedSchedule(scheduleController);
      if (parsed == null || !BookingDateTimePicker.isValidBookingDateTime(parsed)) {
        customSnackBar(CompanyAvailabilityHelper.minimumLeadTimeMessage(), type: ToasterMessageType.info);
        return;
      }
      scheduleController.buildSchedule(scheduleType: ScheduleType.schedule, schedule: scheduleController.scheduleTime);
      final when = scheduleController.scheduleTime ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(parsed);
      onTap('time', when: when);
    });
  }

  Widget _summaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: ui.summaryLines.map((line) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    line.label,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                Expanded(child: Text(line.value, style: robotoMedium)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BookingStepIndicator extends StatelessWidget {
  final List<AiChatFlowStep> steps;
  const _BookingStepIndicator({required this.steps});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: steps.map((s) {
          final color = s.active
              ? Theme.of(context).colorScheme.primary
              : s.done
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                  : Theme.of(context).hintColor.withValues(alpha: 0.35);
          return Padding(
            padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                const SizedBox(width: 4),
                Text(
                  s.label,
                  style: robotoRegular.copyWith(
                    fontSize: 11,
                    color: s.active ? Theme.of(context).colorScheme.primary : Theme.of(context).hintColor,
                    fontWeight: s.active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final String? iconName;
  final bool highlight;
  const _IconBadge({this.iconName, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: (highlight ? Theme.of(context).colorScheme.primary : Theme.of(context).hintColor)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Icon(
        _iconData(iconName),
        color: highlight ? Theme.of(context).colorScheme.primary : Theme.of(context).hintColor,
        size: 22,
      ),
    );
  }
}

IconData _iconData(String? name) {
  switch (name) {
    case 'home_repair_service':
      return Icons.home_repair_service_outlined;
    case 'tune':
      return Icons.tune_rounded;
    case 'location_on':
      return Icons.location_on_outlined;
    case 'engineering':
      return Icons.engineering_outlined;
    case 'auto_awesome':
      return Icons.auto_awesome;
    case 'schedule':
      return Icons.schedule_rounded;
    case 'event':
      return Icons.event_outlined;
    case 'shopping_cart':
      return Icons.shopping_cart_outlined;
    case 'cart':
      return Icons.shopping_cart_outlined;
    case 'add':
      return Icons.add_location_alt_outlined;
    case 'close':
      return Icons.close_rounded;
    case 'support':
      return Icons.support_agent_outlined;
    case 'phone':
      return Icons.phone_outlined;
    case 'search':
      return Icons.search_rounded;
    default:
      return Icons.check_circle_outline;
  }
}

Future<void> _callSupportPhone() async {
  final phone = Get.find<SplashController>().configModel.content?.businessPhone?.toString();
  if (phone == null || phone.trim().isEmpty) {
    Get.toNamed(RouteHelper.getSupportRoute());
    return;
  }
  final uri = Uri(scheme: 'tel', path: phone.trim());
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    Get.toNamed(RouteHelper.getSupportRoute());
  }
}
