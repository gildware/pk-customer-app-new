import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class SpecialFinancialSettlementWidget extends StatelessWidget {
  final SpecialFinancialSettlement settlement;

  const SpecialFinancialSettlementWidget({super.key, required this.settlement});

  @override
  Widget build(BuildContext context) {
    if (settlement.hasSpecialSettlement != true) {
      return const SizedBox.shrink();
    }

    final primaryColor = Theme.of(context).primaryColor;
    final scenarioLabel = _scenarioLabel(settlement.scenarioLabelKey);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.35),
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
                color: primaryColor,
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Expanded(
                child: Text(
                  'special_financial_settlement'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              if (scenarioLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  ),
                  child: Text(
                    scenarioLabel,
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          const Divider(height: 1),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _AmountRow(
            title: 'final_booking_amount'.tr,
            amount: settlement.finalBookingAmount ?? 0,
            valueStyle: robotoBold,
          ),
          if (settlement.notes != null && settlement.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              '${'notes'.tr}: ${settlement.notes!.trim()}',
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _scenarioLabel(String? key) {
    if (key == null || key.trim().isEmpty) {
      return null;
    }
    return key.tr;
  }
}

class _AmountRow extends StatelessWidget {
  final String title;
  final double amount;
  final TextStyle? valueStyle;

  const _AmountRow({
    required this.title,
    required this.amount,
    this.valueStyle,
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
              style: (valueStyle ?? robotoMedium).copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
