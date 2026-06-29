import 'package:demandium/feature/booking/widget/booking_screen_shimmer.dart';
import 'package:demandium/feature/booking/widget/payment_info_widget.dart';
import 'package:demandium/feature/booking/widget/regular/loss_making_settlement_widget.dart';
import 'package:demandium/helper/booking_helper.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class BookingPaymentsWidget extends StatelessWidget {
  final String? id;
  final bool isSubBooking;

  const BookingPaymentsWidget({super.key, this.id, required this.isSubBooking});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        if (id == null) {
          return;
        }
        if (isSubBooking) {
          await Get.find<BookingDetailsController>().getSubBookingDetails(bookingId: id!);
        } else {
          await Get.find<BookingDetailsController>().getBookingDetails(bookingId: id!);
        }
      },
      child: GetBuilder<BookingDetailsController>(
        builder: (controller) {
          final bookingDetails = isSubBooking
              ? controller.subBookingDetailsContent
              : controller.bookingDetailsContent;

          if (bookingDetails == null) {
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: BookingScreenShimmer(),
            );
          }

          final payment = bookingDetails.paymentDetails;
          var ledger = bookingDetails.paymentLedger;
          var installments = ledger?.installments ?? [];
          final refunds = ledger?.refunds ?? [];

                  if (installments.isEmpty) {
                    final fallbackLedger = bookingDetails.buildPaymentLedgerFallback();
                    if (fallbackLedger != null) {
                      ledger = fallbackLedger;
                      installments = fallbackLedger.installments ?? [];
                    }
                  }

          final sortedInstallments = List<BookingPaymentLedgerEntry>.from(installments)
            ..sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));
          final sortedRefunds = List<BookingRefundLedgerEntry>.from(refunds)
            ..sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall,
                vertical: Dimensions.paddingSizeDefault,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (payment != null)
                    _PaymentSummaryCard(
                      payment: payment,
                      bookingDetails: bookingDetails,
                      isSubBooking: isSubBooking,
                    )
                  else
                    _PaymentSummaryFallbackCard(
                      bookingDetails: bookingDetails,
                      isSubBooking: isSubBooking,
                    ),
                  if (bookingDetails.lossMakingSettlement?.isLossMaking == true
                      && !BookingHelper.hasDisputedSettlement(bookingDetails)) ...[
                    Gaps.verticalGapOf(Dimensions.paddingSizeDefault),
                    LossMakingSettlementWidget(bookingDetails: bookingDetails),
                  ],
                  Gaps.verticalGapOf(Dimensions.paddingSizeDefault),
                  _LedgerSection(
                    title: 'payment_history'.tr,
                    child: sortedInstallments.isEmpty
                        ? _EmptyLedgerMessage()
                        : Column(
                            children: sortedInstallments
                                .map((entry) => _InstallmentLedgerCard(entry: entry))
                                .toList(),
                          ),
                  ),
                  if (sortedRefunds.isNotEmpty) ...[
                    Gaps.verticalGapOf(Dimensions.paddingSizeDefault),
                    _LedgerSection(
                      title: 'refunds_to_customer'.tr,
                      child: Column(
                        children: sortedRefunds
                            .map((entry) => _RefundLedgerCard(entry: entry))
                            .toList(),
                      ),
                    ),
                  ],
                  Gaps.verticalGapOf(Dimensions.paddingSizeExtraLarge),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  final BookingPaymentDetailsSummary payment;
  final BookingDetailsContent bookingDetails;
  final bool isSubBooking;

  const _PaymentSummaryCard({
    required this.payment,
    required this.bookingDetails,
    required this.isSubBooking,
  });

  @override
  Widget build(BuildContext context) {
    final isWriteoffSettled = BookingHelper.isWriteoffSettledBooking(bookingDetails);
    final isLossMaking = bookingDetails.lossMakingSettlement?.isLossMaking == true;
    final isDisputed = BookingHelper.hasDisputedSettlement(bookingDetails);
    final statusLabel = isWriteoffSettled
        ? BookingHelper.displayLabel(payment.statusLabel ?? 'settled')
        : isLossMaking
            ? (BookingHelper.getDueBalanceAmount(bookingDetails) > 0.009
                ? BookingHelper.displayLabel('partially_paid')
                : BookingHelper.displayLabel('paid'))
            : BookingHelper.displayLabel(
                payment.statusLabel ?? (bookingDetails.isPaid == 1 ? 'paid' : 'unpaid'),
              );
    final lower = statusLabel.toLowerCase();
    Color statusColor = Theme.of(context).textTheme.bodyLarge!.color!;
    if (lower.contains('settled')) {
      statusColor = Colors.green.shade700;
    } else if (lower.contains('paid') && !lower.contains('un') && !lower.contains('partial')) {
      statusColor = Colors.green;
    } else if (lower.contains('partial')) {
      statusColor = Theme.of(context).colorScheme.primary;
    } else if (lower.contains('unpaid') || lower.contains('refund')) {
      statusColor = Theme.of(context).colorScheme.error;
    }

    final totalAmount = isDisputed
        ? (BookingHelper.resolveDisputedFinalBookingAmount(bookingDetails) ?? BookingHelper.resolveCustomerPayableTotal(bookingDetails))
        : BookingHelper.resolveCustomerPayableTotal(bookingDetails);
    final amountPaid = isDisputed
        ? (BookingHelper.resolveDisputedCustomerPaidTotal(bookingDetails) ?? BookingHelper.resolveCustomerAmountPaid(bookingDetails))
        : BookingHelper.resolveCustomerAmountPaid(bookingDetails);
    final refundedAmount = BookingHelper.resolveRefundedAmount(bookingDetails);
    final pendingRefund = BookingHelper.resolvePendingRefundAmount(bookingDetails);
    final settlementAmount = BookingHelper.getWriteoffSettlementAmount(bookingDetails);
    final dueBalance = BookingHelper.getDueBalanceAmount(bookingDetails);
    final refundBreakdown = BookingHelper.resolveRefundChannelBreakdown(bookingDetails);
    final bookingStatus = (bookingDetails.bookingStatus ?? '').toLowerCase();
    final showRefundBreakdown = refundBreakdown.hasAnyRefundable
        && (bookingStatus == 'canceled' || bookingStatus == 'cancelled' || bookingStatus == 'refunded'
            || pendingRefund != null && pendingRefund > 0.009);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: Get.find<ThemeController>().darkTheme ? null : searchBoxShadow,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'payment_info'.tr,
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          Gaps.verticalGapOf(Dimensions.paddingSizeSmall),
          _SummaryRow(
            title: 'payment_status'.tr,
            value: statusLabel,
            valueColor: statusColor,
          ),
          if (isDisputed) ...[
            _SummaryRow(
              title: 'customer_paid_total'.tr,
              value: PriceConverter.convertPrice(amountPaid, isShowLongPrice: true),
            ),
            if (refundedAmount != null && refundedAmount > 0.009)
              _SummaryRow(
                title: 'refunded_amount'.tr,
                value: PriceConverter.convertPrice(refundedAmount, isShowLongPrice: true),
                valueColor: Theme.of(context).colorScheme.error,
              ),
            _SummaryRow(
              title: 'final_booking_amount'.tr,
              value: PriceConverter.convertPrice(totalAmount, isShowLongPrice: true),
              valueColor: Get.isDarkMode
                  ? Theme.of(context).textTheme.bodyLarge?.color
                  : Theme.of(context).colorScheme.primary,
            ),
            _SummaryRow(
              title: 'due_balance'.tr,
              value: PriceConverter.convertPrice(dueBalance, isShowLongPrice: true),
              valueColor: dueBalance > 0.009
                  ? Theme.of(context).colorScheme.error
                  : Colors.green,
            ),
            if (pendingRefund != null && pendingRefund > 0.009)
              _SummaryRow(
                title: 'pending_refund'.tr,
                value: PriceConverter.convertPrice(pendingRefund, isShowLongPrice: true),
                valueColor: Colors.orange.shade800,
              ),
          ] else ...[
            _SummaryRow(
              title: 'total_amount'.tr,
              value: PriceConverter.convertPrice(totalAmount, isShowLongPrice: true),
            ),
            _SummaryRow(
              title: 'amount_paid'.tr,
              value: PriceConverter.convertPrice(amountPaid, isShowLongPrice: true),
              valueColor: Colors.green,
            ),
            if (refundedAmount != null && refundedAmount > 0.009)
              _SummaryRow(
                title: 'refunded_amount'.tr,
                value: PriceConverter.convertPrice(refundedAmount, isShowLongPrice: true),
                valueColor: Theme.of(context).colorScheme.error,
              ),
            if (pendingRefund != null && pendingRefund > 0.009)
              _SummaryRow(
                title: 'pending_refund'.tr,
                value: PriceConverter.convertPrice(pendingRefund, isShowLongPrice: true),
                valueColor: Colors.orange.shade800,
              ),
            if (showRefundBreakdown) ...[
              if (refundBreakdown.hasWalletPaid)
                _SummaryRow(
                  title: 'paid_via_wallet'.tr,
                  value: PriceConverter.convertPrice(refundBreakdown.walletPaid, isShowLongPrice: true),
                ),
              if (refundBreakdown.hasDigitalPaid)
                _SummaryRow(
                  title: 'paid_via_digital'.tr,
                  value: PriceConverter.convertPrice(refundBreakdown.digitalPaid, isShowLongPrice: true),
                ),
            ],
            if (isWriteoffSettled && settlementAmount > 0.009)
              _SummaryRow(
                title: 'settlement_amount'.tr,
                value: PriceConverter.convertPrice(settlementAmount, isShowLongPrice: true),
                valueColor: Colors.green.shade700,
              )
            else if (!isWriteoffSettled)
              _SummaryRow(
                title: 'due_balance'.tr,
                value: PriceConverter.convertPrice(dueBalance, isShowLongPrice: true),
                valueColor: Theme.of(context).colorScheme.error,
              ),
          ],
          BookingDueBalancePayButton(
            bookingDetails: bookingDetails,
            isSubBooking: isSubBooking,
          ),
        ],
      ),
    );
  }
}

class _PaymentSummaryFallbackCard extends StatelessWidget {
  final BookingDetailsContent bookingDetails;
  final bool isSubBooking;

  const _PaymentSummaryFallbackCard({
    required this.bookingDetails,
    required this.isSubBooking,
  });

  @override
  Widget build(BuildContext context) {
    final payment = bookingDetails.paymentDetails;
    if (payment != null) {
      return _PaymentSummaryCard(
        payment: payment,
        bookingDetails: bookingDetails,
        isSubBooking: isSubBooking,
      );
    }

    final payableTotal = BookingHelper.resolveCustomerPayableTotal(bookingDetails);
    final paid = BookingHelper.resolveCustomerAmountPaid(bookingDetails);
    final isWriteoffSettled = BookingHelper.isWriteoffSettledBooking(bookingDetails);
    final due = isWriteoffSettled ? 0.0 : BookingHelper.getDueBalanceAmount(bookingDetails);
    final settlementAmount = BookingHelper.getWriteoffSettlementAmount(bookingDetails);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: Get.find<ThemeController>().darkTheme ? null : searchBoxShadow,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('payment_info'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
          Gaps.verticalGapOf(Dimensions.paddingSizeSmall),
          _SummaryRow(
            title: 'payment_status'.tr,
            value: isWriteoffSettled
                ? 'settled'.tr
                : (bookingDetails.isPaid == 1 ? 'paid'.tr : (paid > 0 ? 'partially_paid'.tr : 'unpaid'.tr)),
          ),
          _SummaryRow(title: 'total_amount'.tr, value: PriceConverter.convertPrice(payableTotal, isShowLongPrice: true)),
          _SummaryRow(
            title: 'amount_paid'.tr,
            value: PriceConverter.convertPrice(paid, isShowLongPrice: true),
            valueColor: Colors.green,
          ),
          if (isWriteoffSettled && settlementAmount > 0.009)
            _SummaryRow(
              title: 'settlement_amount'.tr,
              value: PriceConverter.convertPrice(settlementAmount, isShowLongPrice: true),
              valueColor: Colors.green.shade700,
            )
          else if (!isWriteoffSettled)
            _SummaryRow(
              title: 'due_balance'.tr,
              value: PriceConverter.convertPrice(due, isShowLongPrice: true),
              valueColor: Theme.of(context).colorScheme.error,
            ),
          BookingDueBalancePayButton(
            bookingDetails: bookingDetails,
            isSubBooking: isSubBooking,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const _SummaryRow({required this.title, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              value,
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

class _LedgerSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _LedgerSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: Get.find<ThemeController>().darkTheme ? null : searchBoxShadow,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          Gaps.verticalGapOf(Dimensions.paddingSizeSmall),
          child,
        ],
      ),
    );
  }
}

class _InstallmentLedgerCard extends StatelessWidget {
  final BookingPaymentLedgerEntry entry;

  const _InstallmentLedgerCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isCompanyPayment = BookingHelper.isPaymentReceivedByCompany(
      receivedBy: entry.receivedBy,
      receivedByLabel: entry.receivedByLabel,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${entry.serial ?? ''}',
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  PriceConverter.convertPrice(entry.amount ?? 0, isShowLongPrice: true),
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
              ),
            ],
          ),
          if (entry.date != null) ...[
            Gaps.verticalGapOf(Dimensions.paddingSizeExtraSmall),
            _LedgerDetailRow(
              title: 'date'.tr,
              value: DateConverter.dateMonthYearTimeTwentyFourFormat(
                DateConverter.isoUtcStringToLocalDate(entry.date!),
              ),
            ),
          ],
          if (entry.receivedByLabel != null && entry.receivedByLabel!.isNotEmpty)
            _LedgerDetailRow(title: 'received_by'.tr, value: BookingHelper.displayLabel(entry.receivedByLabel)),
          if (isCompanyPayment &&
              entry.paymentMethodLabel != null &&
              entry.paymentMethodLabel!.isNotEmpty)
            _LedgerDetailRow(
              title: 'payment_method'.tr,
              value: BookingHelper.paymentMethodLabel(entry.paymentMethodLabel),
            ),
          if (isCompanyPayment &&
              entry.transactionId != null &&
              entry.transactionId!.isNotEmpty)
            _LedgerDetailRow(title: 'transaction_id'.tr, value: entry.transactionId!),
          if ((entry.dueAfterPayment ?? 0) >= 0)
            _LedgerDetailRow(
              title: 'due_after_this_payment'.tr,
              value: PriceConverter.convertPrice(entry.dueAfterPayment ?? 0, isShowLongPrice: true),
            ),
        ],
      ),
    );
  }
}

class _RefundLedgerCard extends StatelessWidget {
  final BookingRefundLedgerEntry entry;

  const _RefundLedgerCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${entry.serial ?? ''}',
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  PriceConverter.convertPrice(entry.amount ?? 0, isShowLongPrice: true),
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          if (entry.date != null) ...[
            Gaps.verticalGapOf(Dimensions.paddingSizeExtraSmall),
            _LedgerDetailRow(
              title: 'date'.tr,
              value: DateConverter.dateMonthYearTimeTwentyFourFormat(
                DateConverter.isoUtcStringToLocalDate(entry.date!),
              ),
            ),
          ],
          _LedgerDetailRow(
            title: 'refund_method'.tr,
            value: entry.displayRefundMethodLabel,
          ),
          if (entry.transactionId != null && entry.transactionId!.isNotEmpty)
            _LedgerDetailRow(title: 'transaction_id'.tr, value: entry.transactionId!),
          if (entry.referenceNote != null && entry.referenceNote!.isNotEmpty)
            _LedgerDetailRow(title: 'reference_note'.tr, value: entry.referenceNote!),
        ],
      ),
    );
  }
}

class _LedgerDetailRow extends StatelessWidget {
  final String title;
  final String value;

  const _LedgerDetailRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLedgerMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      child: Center(
        child: Text(
          'no_data_found'.tr,
          style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
        ),
      ),
    );
  }
}
