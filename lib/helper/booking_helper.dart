import 'package:demandium/common/model/booking_status_ui_model.dart';
import 'package:demandium/feature/booking/model/booking_details_model.dart';
import 'package:demandium/feature/booking/model/service_booking_model.dart';
import 'package:demandium/feature/splash/controller/splash_controller.dart';
import 'package:get/get.dart';

class BookingHelper {

  static double getSubTotalCost(BookingDetailsContent booking) {
    double subTotal = 0;
    final details = booking.bookingDetails;
    if (details == null || details.isEmpty) {
      return subTotal;
    }
    for (var element in details) {
      subTotal = subTotal + ((element.serviceCost ?? 1) * (element.quantity ?? 1));
    }
    return subTotal;
  }

  static double getBookingServiceUnitConst(ItemService? item) {
    return getBookingServiceLineSubtotal(item);
  }

  static double getBookingServiceLineSubtotal(ItemService? item) {
    return (item?.serviceCost ?? 0) * (item?.quantity ?? 1);
  }

  static double getBookingServiceItemDiscountTotal(ItemService? item) {
    return (item?.discountAmount ?? 0) +
        (item?.campaignDiscountAmount ?? 0) +
        (item?.overallCouponDiscountAmount ?? 0);
  }

  static double getBookingServiceDiscountedTotal(ItemService? item) {
    if (item?.totalCost != null && item!.totalCost! >= 0) {
      return item.totalCost!;
    }
    final subtotal = getBookingServiceLineSubtotal(item);
    final discount = getBookingServiceItemDiscountTotal(item);
    return (subtotal - discount).clamp(0, double.infinity).toDouble();
  }

  static bool bookingServiceHasDiscount(ItemService? item) {
    if (getBookingServiceItemDiscountTotal(item) > 0) {
      return true;
    }
    return getBookingServiceLineSubtotal(item) > getBookingServiceDiscountedTotal(item);
  }

  static double getExtraServiceLineQuantity(BookingExtraServiceLine line) {
    return (line.quantity == null || line.quantity! <= 0) ? 1 : line.quantity!.toDouble();
  }

  static double getExtraServiceLineSubtotal(BookingExtraServiceLine line) {
    final qty = getExtraServiceLineQuantity(line);
    if (line.price != null && line.price! > 0) {
      return line.price! * qty;
    }
    final discountedTotal = line.total ?? line.amount ?? 0;
    final discount = line.discount ?? 0;
    if (discount > 0) {
      return discountedTotal + discount;
    }
    return discountedTotal;
  }

  static double getExtraServiceLineDiscountTotal(BookingExtraServiceLine line) {
    return line.discount ?? 0;
  }

  static double getExtraServiceLineDiscountedTotal(BookingExtraServiceLine line) {
    final subtotal = getExtraServiceLineSubtotal(line);
    final discount = getExtraServiceLineDiscountTotal(line);
    return line.total ?? line.amount ?? (subtotal - discount).clamp(0, double.infinity).toDouble();
  }

  static bool extraServiceLineHasDiscount(BookingExtraServiceLine line) {
    if (getExtraServiceLineDiscountTotal(line) > 0) {
      return true;
    }
    return getExtraServiceLineSubtotal(line) > getExtraServiceLineDiscountedTotal(line);
  }

  static double getDiscountedSubTotal(BookingDetailsContent booking) {
    double total = 0;
    for (final item in booking.bookingDetails ?? []) {
      total += getBookingServiceDiscountedTotal(item);
    }
    for (final line in booking.extraServiceLines ?? []) {
      if ((line.total ?? line.amount ?? 0) > 0) {
        total += getExtraServiceLineDiscountedTotal(line);
      }
    }
    return total;
  }

  static double subTotalBeforeAdditionalCharges(BookingSummaryPayload summary) {
    final additionalTotal = (summary.additionalChargeLines ?? [])
        .where((line) => (line.amount ?? 0) > 0)
        .fold<double>(0, (sum, line) => sum + (line.amount ?? 0));

    if (summary.grossTotal != null) {
      return (summary.grossTotal! - additionalTotal).clamp(0, double.infinity).toDouble();
    }

    final extraServiceTotal = (summary.extraServiceLines ?? [])
        .fold<double>(0, (sum, line) => sum + (line.amount ?? 0));
    final spareTotal = (summary.sparePartLines ?? [])
        .fold<double>(0, (sum, line) => sum + (line.amount ?? 0));

    return (summary.serviceAmount ?? 0) + extraServiceTotal + spareTotal;
  }

  static List<BookingSummaryLine> getAdditionalChargeLines(BookingDetailsContent booking) {
    final summaryLines = booking.bookingSummary?.additionalChargeLines
        ?.where((line) => (line.amount ?? 0) > 0)
        .toList();
    if (summaryLines != null && summaryLines.isNotEmpty) {
      return summaryLines;
    }

    if (booking.additionalChargesDisplay != null && booking.additionalChargesDisplay!.isNotEmpty) {
      return booking.additionalChargesDisplay!
          .where((line) => (line.amount ?? 0) > 0)
          .map((line) => BookingSummaryLine(name: line.name, amount: line.amount))
          .toList();
    }

    if ((booking.extraFee ?? 0) > 0) {
      return [BookingSummaryLine(amount: booking.extraFee)];
    }

    return [];
  }

  static String additionalChargeLineLabel(BookingSummaryLine line) {
    if (line.name != null && line.name!.trim().isNotEmpty) {
      return line.name!.trim();
    }

    final configLabel = Get.find<SplashController>().configModel.content?.additionalChargeLabelName;
    if (configLabel != null && configLabel.trim().isNotEmpty) {
      return configLabel.trim();
    }

    return 'additional_charges'.tr;
  }

  static RepeatBooking? getNextUpcomingRepeatBooking(BookingDetailsContent? bookingRequest) {

    if (bookingRequest  == null || bookingRequest.repeatBookingList == null || bookingRequest.repeatBookingList!.isEmpty || bookingRequest.bookingStatus == "pending") {
      return null;
    }
    for (var repeatBooking in bookingRequest.repeatBookingList!) {
      if (repeatBooking.bookingStatus == "ongoing") {
        return repeatBooking;
      }
    }
    for (var repeatBooking in bookingRequest.repeatBookingList!) {
      if (repeatBooking.bookingStatus == "accepted") {
        return repeatBooking;
      }
    }
    return null;
  }

  static String? getRepeatBookingCurrentSchedule(BookingModel bookingRequest) {
    if (bookingRequest.repeatBookingList == null || bookingRequest.repeatBookingList!.isEmpty ) {
      return bookingRequest.serviceSchedule;
    }

    final ongoingSchedule = bookingRequest.repeatBookingList?.firstWhere((repeatBooking) => repeatBooking.bookingStatus == "ongoing", orElse: () => RepeatBooking()).serviceSchedule;
    if (ongoingSchedule != null) return ongoingSchedule;

    final acceptedSchedule = bookingRequest.repeatBookingList?.firstWhere((repeatBooking) => repeatBooking.bookingStatus == "accepted", orElse: () => RepeatBooking()).serviceSchedule;
    if (acceptedSchedule != null) return acceptedSchedule;

    final completedSchedule = bookingRequest.repeatBookingList?.firstWhere((repeatBooking) => repeatBooking.bookingStatus == "completed", orElse: () => RepeatBooking()).serviceSchedule;
    if (completedSchedule != null) return completedSchedule;

    final canceledSchedule = bookingRequest.repeatBookingList?.firstWhere((repeatBooking) => repeatBooking.bookingStatus == "canceled", orElse: () => RepeatBooking()).serviceSchedule;
    if (canceledSchedule != null) return canceledSchedule;

    final pendingSchedule = bookingRequest.repeatBookingList?.firstWhere((repeatBooking) => repeatBooking.bookingStatus == "pending", orElse: () => RepeatBooking()).serviceSchedule;
    return pendingSchedule;

  }

  static double getRepeatBookingPaidAmount(BookingDetailsContent bookingDetails){

    double amount = 0;

    if(bookingDetails.repeatBookingList == null || bookingDetails.repeatBookingList!.isEmpty){
      return 0;
    }

    for(var repeatBooking in bookingDetails.repeatBookingList!){
      if(repeatBooking.isPaid ==1){
        amount = amount + (repeatBooking.totalBookingAmount ?? 0);
      }
    }
    return amount;
  }

  static double getRepeatBookingCanceledAmount(BookingDetailsContent bookingDetails){

    double amount = 0;

    if(bookingDetails.repeatBookingList == null || bookingDetails.repeatBookingList!.isEmpty){
      return 0;
    }

    for(var repeatBooking in bookingDetails.repeatBookingList!){
      if(repeatBooking.bookingStatus == "canceled"){
        amount = amount + (repeatBooking.totalBookingAmount ?? 0);
      }
    }
    return amount;
  }

  static int getRepeatPaidBookingCount(BookingDetailsContent bookingDetails){

    int count = 0;
    if(bookingDetails.repeatBookingList == null || bookingDetails.repeatBookingList!.isEmpty){
      return 0;
    }
    for(var repeatBooking in bookingDetails.repeatBookingList!){
      if(repeatBooking.isPaid == 1){
        count ++;
      }
    }
    return count;
  }

  static int getRepeatCanceledBookingCount(BookingDetailsContent bookingDetails){

    int count = 0;
    if(bookingDetails.repeatBookingList == null || bookingDetails.repeatBookingList!.isEmpty){
      return 0;
    }
    for(var repeatBooking in bookingDetails.repeatBookingList!){
      if(repeatBooking.bookingStatus == "canceled"){
        count ++;
      }
    }
    return count;
  }

  /// Converts API keys (snake_case) or backend labels into user-facing text.
  static String displayLabel(String? raw) {
    if (raw == null) {
      return '';
    }
    final value = raw.trim();
    if (value.isEmpty) {
      return '';
    }

    if (value.contains('—')) {
      return value;
    }

    final translationKey = value.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    final translated = translationKey.tr;
    if (translated != translationKey) {
      return translated;
    }

    if (value.contains('_') || value.contains('-')) {
      return value
          .replaceAll('_', ' ')
          .replaceAll('-', ' ')
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .map((part) => part.length == 1
              ? part.toUpperCase()
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
          .join(' ');
    }

    return value;
  }

  static String paymentMethodLabel(String? raw, {String? bookingPaymentMethod}) {
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }
    final paidWith = raw.trim();
    if (paidWith.contains('—')) {
      return paidWith;
    }

    switch (paidWith) {
      case 'wallet':
        return displayLabel('wallet_payment');
      case 'digital':
        if (bookingPaymentMethod == 'offline_payment') {
          return displayLabel('offline_payment');
        }
        return displayLabel(bookingPaymentMethod ?? 'digital_payment');
      case 'offline':
        return displayLabel('offline_payment');
      default:
        return displayLabel(paidWith);
    }
  }

  /// Customer payment obligation (final settled amount when applicable; otherwise invoice grand total).
  static double resolveCustomerPayableTotal(BookingDetailsContent booking) {
    final disputedFinal = resolveDisputedFinalBookingAmount(booking);
    if (disputedFinal != null) {
      return disputedFinal;
    }
    final finalFromSettlement = booking.specialFinancialSettlement?.finalBookingAmount;
    if (finalFromSettlement != null && finalFromSettlement > 0.009) {
      return finalFromSettlement;
    }
    if (booking.lossMakingSettlement?.isLossMaking == true) {
      final lossTotal = booking.lossMakingSettlement?.totalBookingAmount;
      if (lossTotal != null && lossTotal > 0.009) {
        return lossTotal;
      }
    }
    if (booking.listDisplayTotal != null && booking.listDisplayTotal! > 0.009) {
      return booking.listDisplayTotal!;
    }
    final paymentTotal = booking.paymentDetails?.total;
    if (paymentTotal != null && paymentTotal > 0.009) {
      return paymentTotal;
    }
    return resolveInvoiceGrandTotal(booking);
  }

  static double resolveCustomerAmountPaid(BookingDetailsContent booking) {
    final fromPayment = booking.paymentDetails?.amountPaidDisplay;
    if (fromPayment != null && fromPayment >= 0) {
      return fromPayment;
    }
    final fromSettlement = booking.lossMakingSettlement?.amountPaid;
    if (fromSettlement != null && fromSettlement >= 0) {
      return fromSettlement;
    }
    final fromSummary = booking.bookingSummary?.totalPaid;
    if (fromSummary != null && fromSummary >= 0) {
      return fromSummary;
    }
    var paid = 0.0;
    if (booking.partialPayments != null && booking.partialPayments!.isNotEmpty) {
      for (final partial in booking.partialPayments!) {
        paid += partial.paidAmount ?? 0;
      }
    } else if (booking.isPaid == 1) {
      paid = resolveCustomerPayableTotal(booking);
    }
    return paid;
  }

  static bool isWriteoffSettledBooking(BookingDetailsContent booking) {
    final payment = booking.paymentDetails;
    if (payment?.isWriteoffSettled == true) {
      return true;
    }
    if ((payment?.writeOffAmount ?? 0) > 0.009) {
      return true;
    }
    final statusLabel = (payment?.statusLabel ?? '').toLowerCase();
    if (statusLabel.contains('settled') || statusLabel == 'settled'.tr.toLowerCase()) {
      return true;
    }
    final settlement = booking.lossMakingSettlement;
    if (settlement?.isWriteoffSettled == true) {
      return true;
    }
    if ((settlement?.writeOffAmount ?? 0) > 0.009) {
      return true;
    }
    if (booking.statusUi?.tags?.any((tag) => tag.key == 'writeoff_settled') ?? false) {
      return true;
    }

    return _hasWriteoffGapWithZeroDue(booking);
  }

  static bool _hasWriteoffGapWithZeroDue(BookingDetailsContent booking) {
    final payment = booking.paymentDetails;
    final total = resolveCustomerPayableTotal(booking);
    final paid = resolveCustomerAmountPaid(booking);
    final gap = total - paid;
    if (gap <= 0.009) {
      return false;
    }

    if (payment?.dueBalance != null) {
      return payment!.dueBalance! <= 0.009;
    }

    return (total - paid) <= 0.009;
  }

  static double getWriteoffSettlementAmount(BookingDetailsContent booking) {
    final payment = booking.paymentDetails;
    if ((payment?.writeOffAmount ?? 0) > 0.009) {
      return payment!.writeOffAmount!;
    }
    final settlement = booking.lossMakingSettlement;
    if ((settlement?.writeOffAmount ?? 0) > 0.009) {
      return settlement!.writeOffAmount!;
    }
    final total = resolveCustomerPayableTotal(booking);
    final paid = resolveCustomerAmountPaid(booking);
    final gap = (total - paid).clamp(0.0, double.infinity);
    if (isWriteoffSettledBooking(booking) && gap > 0.009) {
      return gap;
    }
    return 0;
  }

  static double getDueBalanceAmount(BookingDetailsContent booking) {
    if (hasDisputedSettlement(booking)) {
      return 0;
    }
    if (isWriteoffSettledBooking(booking)) {
      return 0;
    }

    final paymentDue = booking.paymentDetails?.dueBalance;
    if (paymentDue != null) {
      return paymentDue.clamp(0.0, double.infinity);
    }

    final cap = resolveCustomerPayableTotal(booking);
    final paid = resolveCustomerAmountPaid(booking);
    return (cap - paid).clamp(0.0, double.infinity);
  }

  /// Review is blocked while a loss-making booking still has unsettled loss.
  static bool canLeaveReview(BookingDetailsContent booking) {
    if (booking.lossMakingSettlement?.isLossMaking == true) {
      return false;
    }
    return canLeaveReviewFromStatusUi(booking.statusUi);
  }

  static bool canLeaveReviewFromStatusUi(BookingStatusUiFields? statusUi) {
    final tags = statusUi?.tags ?? const [];
    return !tags.any((tag) => tag.key == 'loss_making');
  }

  static bool canCustomerPayDueBalance(BookingDetailsContent booking) {
    if (hasDisputedSettlement(booking)) {
      return false;
    }
    if (isWriteoffSettledBooking(booking)) {
      return false;
    }

    if (getDueBalanceAmount(booking) <= 0.009) {
      return false;
    }

    final status = (booking.bookingStatus ?? '').toLowerCase();
    return status != 'canceled' && status != 'cancelled' && status != 'refunded';
  }

  /// Final settled amount for disputed reopen close bookings.
  static double? resolveDisputedFinalBookingAmount(BookingDetailsContent booking) {
    final disputed = booking.disputedSettlement;
    if (disputed?.hasDisputedSettlement == true) {
      final amount = disputed?.finalBookingAmount ?? disputed?.retainedFromCustomer;
      if (amount != null) {
        return amount;
      }
    }
    final payment = booking.paymentDetails;
    if (payment?.isDisputedSettlement == true) {
      return payment?.finalBookingAmount ?? payment?.retainedAmount ?? payment?.total;
    }
    return null;
  }

  static bool hasDisputedSettlement(BookingDetailsContent booking) {
    if (booking.disputedSettlement?.hasDisputedSettlement == true) {
      return true;
    }
    return booking.paymentDetails?.isDisputedSettlement == true;
  }

  static double? resolveDisputedCustomerPaidTotal(BookingDetailsContent booking) {
    final disputed = booking.disputedSettlement;
    if (disputed?.hasDisputedSettlement == true && disputed?.customerPaidTotal != null) {
      return disputed!.customerPaidTotal;
    }
    return booking.paymentDetails?.customerPaidTotal ?? booking.paymentDetails?.amountPaidDisplay;
  }

  static double? resolveDisputedRefundTotal(BookingDetailsContent booking) {
    final disputed = booking.disputedSettlement;
    if (disputed?.hasDisputedSettlement == true && disputed?.refundTotal != null) {
      return disputed!.refundTotal;
    }
    return booking.paymentDetails?.refundedAmount ?? booking.paymentDetails?.refundTotal;
  }

  static double? resolvePendingRefundAmount(BookingDetailsContent booking) {
    final disputed = booking.disputedSettlement;
    if (disputed?.hasDisputedSettlement == true) {
      final pending = disputed?.pendingRefund;
      if (pending != null && pending > 0.009) {
        return pending;
      }
      return null;
    }
    final pending = booking.paymentDetails?.pendingRefund ?? booking.paymentDetails?.refundableRemaining;
    if (pending != null && pending > 0.009) {
      return pending;
    }
    return null;
  }

  static double? resolveRefundedAmount(BookingDetailsContent booking) {
    final disputedRefund = resolveDisputedRefundTotal(booking);
    if (disputedRefund != null && disputedRefund > 0.009) {
      return disputedRefund;
    }
    final refunded = booking.paymentDetails?.refundedAmount;
    if (refunded != null && refunded > 0.009) {
      return refunded;
    }
    return null;
  }

  /// Invoice grand total for overview/summary (original catalog total). Use [resolveListDisplayTotal] in lists.
  static double resolveInvoiceGrandTotal(BookingDetailsContent booking) {
    final summary = booking.bookingSummary;
    if (summary?.grandTotal != null && summary!.grandTotal! > 0.009) {
      return summary.grandTotal!;
    }
    if (booking.payableGrandTotal != null && booking.payableGrandTotal! > 0.009) {
      return booking.payableGrandTotal!;
    }
    double total = getDiscountedSubTotal(booking);
    final additionalLines = summary?.additionalChargeLines ?? getAdditionalChargeLines(booking);
    for (final line in additionalLines) {
      total += line.amount ?? 0;
    }
    final taxAmount = summary?.tax ?? booking.totalTaxAmount ?? 0;
    if (summary?.hasTax == true || taxAmount > 0.009) {
      total += taxAmount;
    }
    if (total > 0.009) {
      return total;
    }
    return booking.totalBookingAmount ?? 0;
  }

  /// Final settled amount for booking lists (special scenarios use reduced totals).
  static double resolveListDisplayTotal(BookingDetailsContent booking) {
    return resolveCustomerPayableTotal(booking);
  }

  /// True when the customer payment was received by the company (not the service provider).
  static bool isPaymentReceivedByCompany({String? receivedBy, String? receivedByLabel}) {
    final normalized = (receivedBy ?? '').trim().toLowerCase();
    if (normalized == 'company') {
      return true;
    }
    if (normalized == 'provider') {
      return false;
    }

    final label = (receivedByLabel ?? '').trim().toLowerCase();
    if (label.contains('provider')) {
      return false;
    }
    if (label.contains('company')) {
      return true;
    }

    return normalized.isEmpty;
  }

  static String partialPaymentRowLabel(String? paidWith, String? bookingPaymentMethod) {
    final paid = (paidWith ?? '').trim();
    if (paid == 'cash_after_service') {
      return '${'paid_amount'.tr} (${displayLabel('cash_after_service')})';
    }
    if (paid == 'digital' && bookingPaymentMethod == 'offline_payment') {
      return displayLabel('offline_payment');
    }
    if (paid == 'digital') {
      return "${'paid_by'.tr} ${displayLabel(bookingPaymentMethod)}";
    }
    if (paid.isNotEmpty) {
      return "${'paid_by'.tr} ${paymentMethodLabel(paid, bookingPaymentMethod: bookingPaymentMethod)}";
    }
    return '';
  }
}