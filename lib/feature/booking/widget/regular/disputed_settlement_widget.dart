import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class DisputedSettlementWidget extends StatelessWidget {
  final DisputedSettlement settlement;

  const DisputedSettlementWidget({super.key, required this.settlement});

  @override
  Widget build(BuildContext context) {
    if (settlement.hasDisputedSettlement != true) {
      return const SizedBox.shrink();
    }

    final primaryColor = Theme.of(context).primaryColor;
    final customerPaid = settlement.customerPaidTotal ?? 0;
    final refundTotal = settlement.refundTotal ?? 0;
    final finalAmount = settlement.finalBookingAmount ?? settlement.retainedFromCustomer ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.35)),
        boxShadow: Get.find<ThemeController>().darkTheme ? null : searchBoxShadow,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel_outlined, size: 18, color: primaryColor),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Expanded(
                child: Text(
                  'disputed_settlement'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              if (settlement.isFullRefund == true)
                _badge(context, 'booking_tag_refund_full'.tr, Colors.red.shade700)
              else if (settlement.isPartialRefund == true)
                _badge(context, 'booking_tag_refund_partial'.tr, Colors.orange.shade800),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          const Divider(height: 1),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _AmountRow(title: 'customer_paid_total'.tr, amount: customerPaid),
          if (refundTotal > 0.009)
            _AmountRow(
              title: 'refunded_amount'.tr,
              amount: refundTotal,
              prefix: '- ',
              valueColor: Theme.of(context).colorScheme.error,
            ),
          if ((settlement.pendingRefund ?? 0) > 0.009)
            _AmountRow(
              title: 'pending_refund'.tr,
              amount: settlement.pendingRefund ?? 0,
              valueColor: Colors.orange.shade800,
            ),
          _AmountRow(
            title: 'final_booking_amount'.tr,
            amount: finalAmount,
            valueStyle: robotoBold,
          ),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Text(
        label,
        style: robotoMedium.copyWith(
          fontSize: Dimensions.fontSizeExtraSmall,
          color: color,
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String title;
  final double amount;
  final String prefix;
  final TextStyle? valueStyle;
  final Color? valueColor;

  const _AmountRow({
    required this.title,
    required this.amount,
    this.prefix = '',
    this.valueStyle,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.9),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              '$prefix${PriceConverter.convertPrice(amount, isShowLongPrice: true)}',
              style: (valueStyle ?? robotoMedium).copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
