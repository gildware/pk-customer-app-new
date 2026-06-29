import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CallHistoryListView extends StatefulWidget {
  const CallHistoryListView({super.key});

  @override
  State<CallHistoryListView> createState() => _CallHistoryListViewState();
}

class _CallHistoryListViewState extends State<CallHistoryListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final controller = Get.find<InAppCallController>();
    if (controller.callHistoryList == null) {
      controller.getCallHistory(1, reload: true);
    }
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final controller = Get.find<InAppCallController>();
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 120 &&
        !controller.callHistoryLoading &&
        controller.callHistoryLastPage != null &&
        controller.callHistoryOffset < controller.callHistoryLastPage!) {
      controller.getCallHistory(controller.callHistoryOffset + 1);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ended':
        return const Color(0xFF2E7D32);
      case 'accepted':
        return const Color(0xFF1565C0);
      case 'ringing':
        return const Color(0xFFEF6C00);
      case 'missed':
      case 'declined':
      case 'cancelled':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF757575);
    }
  }

  Color _directionColor(bool isCaller) {
    return isCaller ? const Color(0xFF2E7D32) : const Color(0xFF1565C0);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InAppCallController>(builder: (controller) {
      if (controller.callHistoryList == null && controller.callHistoryLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final items = controller.callHistoryList ?? [];
      if (items.isEmpty) {
        return Center(
          child: Text(
            'no_call_history'.tr,
            style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.getCallHistory(1, reload: true),
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          itemCount: items.length + (controller.callHistoryLoading ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              return const Padding(
                padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final call = items[index];
            final peerName = call.peer.name?.trim().isNotEmpty == true
                ? call.peer.name!
                : 'unknown'.tr;
            final startedAt = _formatStartedAt(call.startedAt);
            final statusColor = _statusColor(call.status);
            final directionColor = _directionColor(call.isCaller);
            final subtitle = call.status == 'ended' && call.formattedDuration.isNotEmpty
                ? '${call.statusLabelKey.tr} • ${call.formattedDuration}'
                : call.statusLabelKey.tr;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: directionColor.withValues(alpha: 0.12),
                child: call.isCaller
                    ? Icon(Icons.call_made, color: directionColor, size: 20)
                    : Icon(Icons.call_received, color: directionColor, size: 20),
              ),
              title: Text(peerName, style: robotoMedium),
              subtitle: RichText(
                text: TextSpan(
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                  children: [
                    TextSpan(
                      text: call.directionLabelKey.tr,
                      style: TextStyle(color: directionColor, fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: ' • '),
                    TextSpan(
                      text: subtitle,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              trailing: Text(
                startedAt,
                style: robotoLight.copyWith(fontSize: Dimensions.fontSizeSmall),
              ),
              onTap: call.channelId.isNotEmpty
                  ? () => Get.toNamed(RouteHelper.getChatScreenRoute(
                        call.channelId,
                        peerName,
                        call.peer.image ?? '',
                        call.peer.phone ?? '',
                        call.peer.userType ?? '',
                      ))
                  : null,
            );
          },
        ),
      );
    });
  }

  String _formatStartedAt(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM, hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }
}
