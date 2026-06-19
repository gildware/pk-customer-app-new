import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class LossMakingSettlementWidget extends StatelessWidget {
  final BookingDetailsContent bookingDetails;

  const LossMakingSettlementWidget({super.key, required this.bookingDetails});

  @override
  Widget build(BuildContext context) {
    final settlement = bookingDetails.lossMakingSettlement;
    if (settlement?.isLossMaking != true) {
      return const SizedBox.shrink();
    }

    final payment = bookingDetails.paymentDetails;
    final isSettled = BookingHelper.isWriteoffSettledBooking(bookingDetails);
    final totalAmount = payment?.total ?? BookingHelper.resolveCustomerPayableTotal(bookingDetails);
    final amountPaid = payment?.amountPaidDisplay ?? BookingHelper.resolveCustomerAmountPaid(bookingDetails);
    final dueBalance = isSettled ? 0.0 : BookingHelper.getDueBalanceAmount(bookingDetails);
    final settlementAmount = BookingHelper.getWriteoffSettlementAmount(bookingDetails);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.35),
        ),
        boxShadow: Get.find<ThemeController>().darkTheme ? null : searchBoxShadow,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Expanded(
                child: Text(
                  'financial_settlement'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
                child: Text(
                  isSettled ? 'settled'.tr : 'bfs_list_badge_loss_making'.tr,
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: isSettled ? Colors.green.shade700 : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          const Divider(height: 1),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _AmountRow(
            title: 'total_amount'.tr,
            amount: totalAmount,
          ),
          _AmountRow(
            title: 'amount_paid'.tr,
            amount: amountPaid,
          ),
          if (isSettled)
            _AmountRow(
              title: 'settlement_amount'.tr,
              amount: settlementAmount,
              valueColor: Colors.green.shade700,
            )
          else
            _AmountRow(
              title: 'due_balance'.tr,
              amount: dueBalance,
              valueColor: Theme.of(context).colorScheme.error,
            ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String title;
  final double amount;
  final Color? valueColor;

  const _AmountRow({
    required this.title,
    required this.amount,
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
              PriceConverter.convertPrice(amount, isShowLongPrice: true),
              style: robotoMedium.copyWith(
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
