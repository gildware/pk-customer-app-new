import 'package:demandium/common/model/booking_status_ui_model.dart';
import 'package:demandium/common/models/user_model.dart';
import 'package:demandium/helper/booking_helper.dart';
import 'package:demandium/util/core_export.dart';

class BookingDetailsModel {
  String? responseCode;
  String? message;
  BookingDetailsContent? content;

  BookingDetailsModel({this.responseCode, this.message, this.content});

  BookingDetailsModel.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code'];
    message = json['message'];
    content = json['content'] != null ? BookingDetailsContent.fromJson(json['content']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['response_code'] = responseCode;
    data['message'] = message;
    if (content != null) {
      data['content'] = content!.toJson();
    }
    return data;
  }
}

class BookingDetailsContent {
  String? id;
  String? bookingId;
  String? readableId;
  String? customerId;
  String? providerId;
  String? zoneId;
  String? bookingStatus;
  int? isPaid;
  String? paymentMethod;
  String? transactionId;
  double? totalBookingAmount;
  double? totalTaxAmount;
  double? totalDiscountAmount;
  String? serviceSchedule;
  String? serviceAddressId;
  String? createdAt;
  String? updatedAt;
  String? categoryId;
  String? subCategoryId;
  BookingCategoryInfo? category;
  BookingCategoryInfo? subCategory;
  List<ItemService>? bookingDetails;
  List<ScheduleHistories>? scheduleHistories;
  List<StatusHistories>? statusHistories;
  List<PartialPayment>? partialPayments;
  ServiceAddress? serviceAddress;
  Customer? customer;
  ProviderData? provider;
  Serviceman? serviceman;
  double? totalCampaignDiscountAmount;
  double? totalCouponDiscountAmount;
  String? bookingOtp;
  List<String>? photoEvidence;
  List<String>? photoEvidenceFullPath;
  double? extraFee;
  double ? additionalCharge;
  double ? totalReferralDiscountAmount;
  int? isRepeatBooking;
  String? time;
  String? startDate;
  String? endDate;
  int? totalCount;
  String? bookingType;
  List<String>? weekNames;
  int? completedCount;
  int? canceledCount;
  RepeatBooking ? nextService;
  List<RepeatBooking>? repeatBookingList;
  List<RepeatHistory>? repeatEditHistory;
  BookingDetailsContent? subBooking;
  List<BookingOfflinePayment>? bookingOfflinePayment;
  String? offlinePaymentId;
  String? offlinePaymentStatus;
  String? offlinePaymentDeniedNote;
  String? offlinePaymentMethodName;
  String? serviceLocation;
  bool? isCustomizeBooking;
  List<CartAdditionalChargeLine>? additionalChargesDisplay;
  List<BookingExtraServiceLine>? extraServiceLines;
  double? payableGrandTotal;
  double? listDisplayTotal;
  BookingPaymentDetailsSummary? paymentDetails;
  BookingPaymentLedger? paymentLedger;
  BookingSummaryPayload? bookingSummary;
  List<BookingChangeLog>? changeLogs;
  BookingStatusUiFields? statusUi;
  LossMakingSettlement? lossMakingSettlement;
  SpecialFinancialSettlement? specialFinancialSettlement;
  DisputedSettlement? disputedSettlement;


  BookingDetailsContent(
      {this.id,
        this.readableId,
        this.customerId,
        this.providerId,
        this.zoneId,
        this.bookingStatus,
        this.isPaid,
        this.paymentMethod,
        this.transactionId,
        this.totalBookingAmount,
        this.totalTaxAmount,
        this.totalDiscountAmount,
        this.serviceSchedule,
        this.serviceAddressId,
        this.createdAt,
        this.updatedAt,
        this.categoryId,
        this.subCategoryId,
        this.category,
        this.subCategory,
        this.bookingDetails,
        this.scheduleHistories,
        this.statusHistories,
        this.partialPayments,
        this.serviceAddress,
        this.customer,
        this.provider,
        this.serviceman,
        this.totalCampaignDiscountAmount,
        this.totalCouponDiscountAmount,
        this.bookingOtp,
        this.photoEvidence,
        this.photoEvidenceFullPath,
        this.extraFee,
        this.additionalCharge,
        this.totalReferralDiscountAmount,
        this.time,
        this.startDate,
        this.endDate,
        this.totalCount,
        this.bookingType,
        this.completedCount,
        this.canceledCount,
        this.nextService,
        this.isRepeatBooking,
        this.weekNames,
        this.repeatBookingList,
        this.subBooking,
        this.repeatEditHistory,
        this.bookingId,
        this.bookingOfflinePayment,
        this.offlinePaymentId,
        this.offlinePaymentStatus,
        this.offlinePaymentDeniedNote,
        this.offlinePaymentMethodName,
        this.serviceLocation,
        this.isCustomizeBooking,
        this.additionalChargesDisplay,
        this.extraServiceLines,
        this.payableGrandTotal,
        this.listDisplayTotal,
        this.paymentDetails,
        this.paymentLedger,
        this.bookingSummary,
        this.changeLogs,
        this.statusUi,
        this.lossMakingSettlement,
        this.specialFinancialSettlement,
      });

  BookingDetailsContent.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    bookingId = json['booking_id'];
    readableId = json['readable_id'].toString();
    customerId = json['customer_id'];
    providerId = json['provider_id'];
    zoneId = json['zone_id'];
    bookingStatus = json['booking_status'];
    isPaid = json['is_paid'];
    paymentMethod = json['payment_method'];
    transactionId = json['transaction_id'];
    totalBookingAmount = double.tryParse(json['total_booking_amount'].toString());
    totalTaxAmount = double.tryParse(json['total_tax_amount'].toString());
    totalDiscountAmount = double.tryParse(json['total_discount_amount'].toString());
    serviceSchedule = json['service_schedule'];
    serviceAddressId = json['service_address_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    categoryId = json['category_id'];
    subCategoryId = json['sub_category_id'];
    category = json['category'] != null
        ? BookingCategoryInfo.fromJson(json['category'])
        : null;
    subCategory = json['sub_category'] != null
        ? BookingCategoryInfo.fromJson(json['sub_category'])
        : null;
    if (json['detail'] != null) {
      bookingDetails = <ItemService>[];
      json['detail'].forEach((v) {
        bookingDetails!.add(ItemService.fromJson(v));
      });
    }
    if (json['schedule_histories'] != null || json['scheduleHistories'] != null) {
      scheduleHistories = <ScheduleHistories>[];
      (json['schedule_histories'] ?? json['scheduleHistories']).forEach((v) {
        scheduleHistories!.add(ScheduleHistories.fromJson(v));
      });
    }
    if (json['status_histories'] != null || json['statusHistories'] != null) {
      statusHistories = <StatusHistories>[];
      (json['status_histories'] ?? json['statusHistories']).forEach((v) {

        statusHistories!.add(StatusHistories.fromJson(v));
      });
    }

    if (json['booking_partial_payments'] != null) {
      partialPayments = <PartialPayment>[];
      json['booking_partial_payments'].forEach((v) {
        partialPayments!.add(PartialPayment.fromJson(v));
      });
    }

    serviceAddress = json['service_address'] != null
        ? ServiceAddress.fromJson(json['service_address'])
        : null;
    customer = json['customer'] != null
        ? Customer.fromJson(json['customer'])
        : null;
    provider = json['provider'] != null
        ? ProviderData.fromJson(json['provider'])
        : null;
    serviceman = json['serviceman'] != null
        ? Serviceman.fromJson(json['serviceman'])
        : null;
    totalCampaignDiscountAmount = double.tryParse(json['total_campaign_discount_amount'].toString());
    totalCouponDiscountAmount = double.tryParse(json['total_coupon_discount_amount'].toString());
    bookingOtp = json["booking_otp"].toString();
    photoEvidence = json["evidence_photos"]!=null? json["evidence_photos"].cast<String>(): [];
    photoEvidenceFullPath = json["evidence_photos_full_path"]!=null? json["evidence_photos_full_path"].cast<String>(): [];
    extraFee = double.tryParse(json["extra_fee"].toString());
    additionalCharge = double.tryParse(json['additional_charge'].toString());
    totalReferralDiscountAmount = double.tryParse(json['total_referral_discount_amount'].toString());
    isRepeatBooking = int.tryParse(json['is_repeated'].toString());
    time = json['time'];
    startDate = json['startDate'];
    endDate = json['endDate'];
    totalCount = json['totalCount'];
    bookingType = json['bookingType'];
    weekNames = json['weekNames']?.cast<String>();
    completedCount = json['completedCount'];
    canceledCount = json['canceledCount'];
    nextService = json['nextService'] != null
        ? RepeatBooking.fromJson(json['nextService'])
        : null;
    if (json['repeats'] != null) {
      repeatBookingList = <RepeatBooking>[];
      json['repeats'].forEach((v) {
        repeatBookingList!.add(RepeatBooking.fromJson(v));
      });
    }
    if (json['repeatHistory'] != null) {
      repeatEditHistory = <RepeatHistory>[];
      json['repeatHistory'].forEach((v) {
        repeatEditHistory!.add(RepeatHistory.fromJson(v));
      });
    }
    subBooking = json['booking'] != null
        ? BookingDetailsContent.fromJson(json['booking'])
        : null;
    if (json['booking_offline_payment'] != null) {
      bookingOfflinePayment = <BookingOfflinePayment>[];
      json['booking_offline_payment'].forEach((v) { bookingOfflinePayment!.add(
          BookingOfflinePayment.fromJson(v));
      });
    }
    offlinePaymentId = json['offline_payment_id'];
    offlinePaymentStatus = json['offline_payment_status'];
    offlinePaymentDeniedNote = json['offline_payment_denied_note'];
    offlinePaymentMethodName = json['booking_offline_payment_method'];
    serviceLocation = json['service_location'];
    isCustomizeBooking = '${json['is_customize_booking']}'.contains('1');
    payableGrandTotal = double.tryParse(json['payable_grand_total']?.toString() ?? '');
    listDisplayTotal = double.tryParse(json['list_display_total']?.toString() ?? '');
    paymentDetails = json['payment_details'] != null
        ? BookingPaymentDetailsSummary.fromJson(json['payment_details'])
        : null;
    paymentLedger = json['payment_ledger'] != null
        ? BookingPaymentLedger.fromJson(json['payment_ledger'])
        : null;
    if (json['change_logs'] != null) {
      changeLogs = <BookingChangeLog>[];
      json['change_logs'].forEach((v) {
        changeLogs!.add(BookingChangeLog.fromJson(v));
      });
    }
    statusUi = BookingStatusUiFields.fromJson(json);
    if (json['additional_charges_display'] != null) {
      additionalChargesDisplay = <CartAdditionalChargeLine>[];
      json['additional_charges_display'].forEach((v) {
        additionalChargesDisplay!.add(CartAdditionalChargeLine.fromJson(v));
      });
    }
    if (json['extra_service_lines'] != null) {
      extraServiceLines = <BookingExtraServiceLine>[];
      json['extra_service_lines'].forEach((v) {
        extraServiceLines!.add(BookingExtraServiceLine.fromJson(v));
      });
    }
    bookingSummary = json['booking_summary'] != null
        ? BookingSummaryPayload.fromJson(json['booking_summary'])
        : null;
    lossMakingSettlement = json['loss_making_settlement'] != null
        ? LossMakingSettlement.fromJson(Map<String, dynamic>.from(json['loss_making_settlement']))
        : null;
    specialFinancialSettlement = json['special_financial_settlement'] != null
        ? SpecialFinancialSettlement.fromJson(Map<String, dynamic>.from(json['special_financial_settlement']))
        : null;
    disputedSettlement = json['disputed_settlement'] != null
        ? DisputedSettlement.fromJson(Map<String, dynamic>.from(json['disputed_settlement']))
        : null;

    _applyBookingFinancialFallbacks(json);
  }

  void _applyBookingFinancialFallbacks(Map<String, dynamic> json) {
    if ((additionalChargesDisplay == null || additionalChargesDisplay!.isEmpty)
        && json['additional_charges_breakdown'] is List) {
      additionalChargesDisplay = <CartAdditionalChargeLine>[];
      for (final line in json['additional_charges_breakdown'] as List) {
        if (line is Map) {
          final amount = double.tryParse(line['amount']?.toString() ?? '') ?? 0;
          if (amount > 0) {
            additionalChargesDisplay!.add(CartAdditionalChargeLine.fromJson(
              Map<String, dynamic>.from(line),
            ));
          }
        }
      }
    }

    if ((additionalChargesDisplay == null || additionalChargesDisplay!.isEmpty)
        && (extraFee ?? 0) > 0) {
      additionalChargesDisplay = [
        CartAdditionalChargeLine(
          id: 'extra_fee',
          name: 'Additional charges',
          amount: extraFee ?? 0,
        ),
      ];
    }

    payableGrandTotal ??= _computePayableGrandTotalFallback();

    paymentDetails ??= _buildPaymentDetailsFallback();
    _syncWriteoffFieldsOntoPaymentDetails();

    if (paymentLedger == null || (paymentLedger!.installments?.isEmpty ?? true)) {
      paymentLedger = buildPaymentLedgerFallback() ?? paymentLedger;
    }
    if (transactionId != null && transactionId!.isNotEmpty) {
      paymentLedger?.installments?.forEach((entry) {
        if (!BookingHelper.isPaymentReceivedByCompany(
          receivedBy: entry.receivedBy,
          receivedByLabel: entry.receivedByLabel,
        )) {
          return;
        }
        final methodLabel = (entry.paymentMethodLabel ?? '').toLowerCase();
        if (methodLabel.contains('wallet')) {
          return;
        }
        if (entry.transactionId == null || entry.transactionId!.isEmpty) {
          entry.transactionId = transactionId;
        }
      });
    }
    bookingSummary ??= _buildBookingSummaryFallback();
  }

  void _syncWriteoffFieldsOntoPaymentDetails() {
    final payment = paymentDetails;
    if (payment == null) {
      return;
    }

    final settlement = lossMakingSettlement;
    if ((payment.writeOffAmount ?? 0) <= 0.009 && (settlement?.writeOffAmount ?? 0) > 0.009) {
      payment.writeOffAmount = settlement!.writeOffAmount;
    }
    if (payment.isWriteoffSettled != true && settlement?.isWriteoffSettled == true) {
      payment.isWriteoffSettled = true;
    }
    if (payment.isWriteoffSettled != true
        && (statusUi?.tags?.any((tag) => tag.key == 'writeoff_settled') ?? false)) {
      payment.isWriteoffSettled = true;
    }

    final total = BookingHelper.resolveCustomerPayableTotal(this);
    final paid = BookingHelper.resolveCustomerAmountPaid(this);
    final gap = total - paid;
    final due = payment.dueBalance ?? gap.clamp(0.0, double.infinity).toDouble();
    if (payment.isWriteoffSettled != true
        && gap > 0.009
        && due <= 0.009
        && ((payment.statusLabel ?? '').toLowerCase().contains('settled')
            || (statusUi?.tags?.any((tag) => tag.key == 'writeoff_settled') ?? false))) {
      payment.isWriteoffSettled = true;
    }
    if ((payment.writeOffAmount ?? 0) <= 0.009
        && payment.isWriteoffSettled == true
        && gap > 0.009) {
      payment.writeOffAmount = gap;
    }
    if (payment.isWriteoffSettled == true) {
      payment.dueBalance = 0;
    }
  }

  double _computePayableGrandTotalFallback() {
    double total = totalBookingAmount ?? 0;
    total += extraFee ?? 0;
    if (extraServiceLines != null) {
      for (final line in extraServiceLines!) {
        total += line.amount ?? 0;
      }
    }
    return total;
  }

  BookingPaymentDetailsSummary? _buildPaymentDetailsFallback() {
    final payableTotal = BookingHelper.resolveCustomerPayableTotal(this);
    final paid = BookingHelper.resolveCustomerAmountPaid(this);
    final due = (payableTotal - paid).clamp(0, double.infinity).toDouble();
    final hasPartials = partialPayments != null && partialPayments!.isNotEmpty;
    String statusLabel = 'unpaid';
    if (isPaid == 1 || (paid > 0 && due <= 0.009)) {
      statusLabel = 'paid';
    } else if (hasPartials && paid > 0) {
      statusLabel = 'partially_paid';
    }

    return BookingPaymentDetailsSummary(
      total: payableTotal,
      amountPaidDisplay: paid,
      dueBalance: due,
      statusLabel: statusLabel,
      showAsAmountPaidLabel: bookingStatus == 'completed' || due <= 0.009,
      paymentMethodDisplay: paymentMethod,
    );
  }

  BookingPaymentLedger? buildPaymentLedgerFallback() {
    if (partialPayments == null || partialPayments!.isEmpty) {
      return null;
    }

    final cap = BookingHelper.resolveCustomerPayableTotal(this);
    var runningPaid = 0.0;
    final installments = <BookingPaymentLedgerEntry>[];

    for (var i = 0; i < partialPayments!.length; i++) {
      final partial = partialPayments![i];
      final amount = partial.paidAmount ?? 0;
      if (amount == 0) {
        continue;
      }
      runningPaid += amount;
      final receivedBy = partial.receivedBy;
      final isCompanyPayment = BookingHelper.isPaymentReceivedByCompany(
        receivedBy: receivedBy,
        receivedByLabel: partial.receivedByLabel,
      );
      installments.add(BookingPaymentLedgerEntry(
        serial: installments.length + 1,
        date: partial.createdAt,
        receivedBy: receivedBy,
        receivedByLabel: partial.receivedByLabel ?? partial.receivedBy,
        amount: amount,
        paymentMethodLabel: isCompanyPayment
            ? (partial.paymentMethodLabel ?? partial.paidWith)
            : null,
        transactionId: isCompanyPayment
            ? ((partial.transactionId != null && partial.transactionId!.isNotEmpty)
                ? partial.transactionId
                : (partial.paidWith == 'wallet' ? null : transactionId))
            : null,
        dueAfterPayment: (cap - runningPaid).clamp(0, double.infinity).toDouble(),
      ));
    }

    if (installments.isEmpty) {
      return null;
    }

    return BookingPaymentLedger(installments: installments, refunds: []);
  }

  BookingSummaryPayload? _buildBookingSummaryFallback() {
    final serviceAmount = BookingHelper.getSubTotalCost(this);
    final additionalLines = additionalChargesDisplay
        ?.map((line) => BookingSummaryLine(name: line.name, amount: line.amount))
        .toList();
    final extraLines = extraServiceLines
        ?.where((line) => line.type != 'spare_part')
        .map((line) => BookingSummaryLine(name: line.name, amount: line.amount))
        .toList();
    final spareLines = extraServiceLines
        ?.where((line) => line.type == 'spare_part')
        .map((line) => BookingSummaryLine(name: line.name, amount: line.amount))
        .toList();

    final additionalTotal = additionalLines?.fold<double>(0, (sum, line) => sum + (line.amount ?? 0)) ?? (extraFee ?? 0);
    final extraServiceTotal = extraLines?.fold<double>(0, (sum, line) => sum + (line.amount ?? 0)) ?? 0;
    final spareTotal = spareLines?.fold<double>(0, (sum, line) => sum + (line.amount ?? 0)) ?? 0;
    final grossTotal = serviceAmount + additionalTotal + extraServiceTotal + spareTotal;
    final payableTotal = BookingHelper.resolveCustomerPayableTotal(this);
    final paid = BookingHelper.resolveCustomerAmountPaid(this);
    final due = (payableTotal - paid).clamp(0.0, double.infinity).toDouble();

    return BookingSummaryPayload(
      serviceAmount: serviceAmount,
      extraServiceLines: extraLines,
      sparePartLines: spareLines,
      additionalChargeLines: additionalLines,
      grossTotal: grossTotal,
      serviceDiscount: totalDiscountAmount,
      couponDiscount: totalCouponDiscountAmount,
      campaignDiscount: totalCampaignDiscountAmount,
      referralDiscount: totalReferralDiscountAmount,
      tax: totalTaxAmount,
      hasTax: (totalTaxAmount ?? 0) > 0,
      grandTotal: BookingHelper.resolveInvoiceGrandTotal(this),
      totalPaid: paid,
      dueAmount: due,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['readable_id'] = readableId;
    data['customer_id'] = customerId;
    data['provider_id'] = providerId;
    data['zone_id'] = zoneId;
    data['booking_status'] = bookingStatus;
    data['is_paid'] = isPaid;
    data['payment_method'] = paymentMethod;
    data['transaction_id'] = transactionId;
    data['total_booking_amount'] = totalBookingAmount;
    data['total_tax_amount'] = totalTaxAmount;
    data['total_discount_amount'] = totalDiscountAmount;
    data['service_schedule'] = serviceSchedule;
    data['service_address_id'] = serviceAddressId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['category_id'] = categoryId;
    data['sub_category_id'] = subCategoryId;
    if (bookingDetails != null) {
      data['detail'] = bookingDetails!.map((v) => v.toJson()).toList();
    }
    if (scheduleHistories != null) {
      data['schedule_histories'] =
          scheduleHistories!.map((v) => v.toJson()).toList();
    }
    if (statusHistories != null) {
      data['status_histories'] =
          statusHistories!.map((v) => v.toJson()).toList();
    }

    if (partialPayments != null) {
      data['booking_partial_payments'] =
          partialPayments!.map((v) => v.toJson()).toList();
    }
    if (serviceAddress != null) {
      data['service_address'] = serviceAddress!.toJson();
    }
    if (customer != null) {
      data['customer'] = customer!.toJson();
    }
    if (provider != null) {
      data['provider'] = provider!.toJson();
    }
    if (serviceman != null) {
      data['serviceman'] = serviceman!.toJson();
    }
    data['time'] = time;
    data['startDate'] = startDate;
    data['endDate'] = endDate;
    data['totalCount'] = totalCount;
    data['bookingType'] = bookingType;
    data['completedCount'] = completedCount;
    data['canceledCount'] = canceledCount;
    data['is_customize_booking'] = isCustomizeBooking;
    return data;
  }
}

class ItemService {

  String? id;
  String? bookingId;
  String? serviceId;
  String? serviceName;
  String? variantKey;
  double? serviceCost;
  int? quantity;
  double? discountAmount;
  double? taxAmount;
  double? totalCost;
  String? createdAt;
  String? updatedAt;
  double? campaignDiscountAmount;
  double? overallCouponDiscountAmount;
  Service? service;

  ItemService.copy(ItemService value) {
    quantity = value.quantity;
  }


  ItemService(
      {
        this.id,
        this.bookingId,
        this.serviceId,
        this.serviceName,
        this.variantKey,
        this.serviceCost,
        this.quantity,
        this.discountAmount,
        this.taxAmount,
        this.totalCost,
        this.createdAt,
        this.updatedAt,
        this.service,
        this.campaignDiscountAmount,
        this.overallCouponDiscountAmount,});

  ItemService.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    bookingId = json['booking_id'];
    serviceId = json['service_id'];
    serviceName = json['service_name'];
    variantKey = json['variant_key'];
    serviceCost = double.tryParse(json['service_cost'].toString());
    quantity = int.tryParse(json['quantity'].toString());
    discountAmount = double.tryParse(json['discount_amount'].toString());
    taxAmount = double.tryParse(json['tax_amount'].toString());
    totalCost = double.tryParse(json['total_cost'].toString());
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    campaignDiscountAmount = double.tryParse(json['campaign_discount_amount'].toString());
    service = json['service'] != null ? Service.fromJson(json['service']) : null;
    overallCouponDiscountAmount = double.tryParse(json['overall_coupon_discount_amount'].toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['booking_id'] = bookingId;
    data['service_id'] = serviceId;
    data['service_name'] = serviceName;
    data['variant_key'] = variantKey;
    data['service_cost'] = serviceCost;
    data['quantity'] = quantity;
    data['discount_amount'] = discountAmount;
    data['tax_amount'] = taxAmount;
    data['total_cost'] = totalCost;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['campaign_discount_amount'] = campaignDiscountAmount;
    if (service != null) {
      data['service'] = service!.toJson();
    }
    return data;
  }
}

class ScheduleHistories {
  int? id;
  String? bookingId;
  String? changedBy;
  String? schedule;
  String? createdAt;
  String? updatedAt;
  User? user;

  ScheduleHistories(
      {this.id,
        this.bookingId,
        this.changedBy,
        this.schedule,
        this.createdAt,
        this.updatedAt,
        this.user});

  ScheduleHistories.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    bookingId = json['booking_id'];
    changedBy = json['changed_by'];
    schedule = json['schedule'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['booking_id'] = bookingId;
    data['changed_by'] = changedBy;
    data['schedule'] = schedule;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}

class BookingChangeLog {
  int? id;
  String? bookingId;
  String? changedBy;
  String? actorName;
  String? propertyKey;
  String? propertyLabel;
  String? oldValue;
  String? newValue;
  String? context;
  String? createdAt;
  String? eventTitle;
  String? eventDescription;
  String? eventType;
  User? changedByUser;

  BookingChangeLog({
    this.id,
    this.bookingId,
    this.changedBy,
    this.actorName,
    this.propertyKey,
    this.propertyLabel,
    this.oldValue,
    this.newValue,
    this.context,
    this.createdAt,
    this.eventTitle,
    this.eventDescription,
    this.eventType,
    this.changedByUser,
  });

  BookingChangeLog.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    bookingId = json['booking_id']?.toString();
    actorName = json['actor_name'];
    propertyKey = json['property_key'];
    propertyLabel = json['property_label'];
    oldValue = json['old_value']?.toString();
    newValue = json['new_value']?.toString();
    context = json['context'];
    createdAt = json['created_at'];
    eventTitle = json['event_title'];
    eventDescription = json['event_description'];
    eventType = json['event_type'];
    final changedByRaw = json['changed_by'];
    if (changedByRaw is Map<String, dynamic>) {
      changedByUser = User.fromJson(changedByRaw);
    } else {
      changedBy = changedByRaw?.toString();
    }
    if (json['changedBy'] is Map<String, dynamic>) {
      changedByUser = User.fromJson(json['changedBy']);
    }
  }

  String get actorDisplayName {
    if (changedByUser != null) {
      final name = '${changedByUser?.firstName ?? ''} ${changedByUser?.lastName ?? ''}'.trim();
      if (name.isNotEmpty) return name;
    }
    if (actorName != null && actorName!.trim().isNotEmpty) return actorName!.trim();
    return '';
  }
}

class StatusHistories {
  int? id;
  String? bookingId;
  String? changedBy;
  String? bookingStatus;
  String? schedule;
  String? createdAt;
  String? updatedAt;
  User? user;
  int? bookingHoldReopenReasonId;
  String? holdReopenReasonName;

  bool get isReopenStatusChange =>
      (bookingHoldReopenReasonId ?? 0) > 0 ||
      (holdReopenReasonName != null && holdReopenReasonName!.trim().isNotEmpty);

  StatusHistories(
      {this.id,
        this.bookingId,
        this.changedBy,
        this.bookingStatus,
        this.schedule,
        this.createdAt,
        this.updatedAt,
        this.user,
        this.bookingHoldReopenReasonId,
        this.holdReopenReasonName});

  StatusHistories.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    bookingId = json['booking_id'];
    changedBy = json['changed_by'];
    bookingStatus = json['booking_status'];
    schedule = json['schedule'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    bookingHoldReopenReasonId = int.tryParse(json['booking_hold_reopen_reason_id']?.toString() ?? '');
    final reason = json['hold_reopen_reason'];
    if (reason is Map) {
      holdReopenReasonName = reason['name']?.toString();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['booking_id'] = bookingId;
    data['changed_by'] = changedBy;
    data['booking_status'] = bookingStatus;
    data['schedule'] = schedule;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}

class Serviceman {
  String? id;
  String? providerId;
  String? userId;
  String? createdAt;
  String? updatedAt;
  User? user;


  Serviceman(
      {this.id,
        this.providerId,
        this.userId,
        this.createdAt,
        this.updatedAt,
        this.user,
      });

  Serviceman.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    providerId = json['provider_id'];
    userId = json['user_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['provider_id'] = providerId;
    data['user_id'] = userId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}



class ServiceAddress {
  int? id;
  String? userId;
  double? lat;
  double? lon;
  String? city;
  String? street;
  String? zipCode;
  String? country;
  String? address;
  String? createdAt;
  String? updatedAt;
  String? addressType;
  String? contactPersonName;
  String? contactPersonNumber;
  String? addressLabel;

  ServiceAddress(
      {this.id,
        this.userId,
        this.lat,
        this.lon,
        this.city,
        this.street,
        this.zipCode,
        this.country,
        this.address,
        this.createdAt,
        this.updatedAt,
        this.addressType,
        this.contactPersonName,
        this.contactPersonNumber,
        this.addressLabel});

  ServiceAddress.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    lat = double.tryParse(json['lat'].toString());
    lon = double.tryParse(json['lon'].toString());
    city = json['city'];
    street = json['street'];
    zipCode = json['zip_code'];
    country = json['country'];
    address = json['address'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    addressType = json['address_type'];
    contactPersonName = json['contact_person_name'];
    contactPersonNumber = json['contact_person_number'];
    addressLabel = json['address_label'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['lat'] = lat;
    data['lon'] = lon;
    data['city'] = city;
    data['street'] = street;
    data['zip_code'] = zipCode;
    data['country'] = country;
    data['address'] = address;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['address_type'] = addressType;
    data['contact_person_name'] = contactPersonName;
    data['contact_person_number'] = contactPersonNumber;
    data['address_label'] = addressLabel;
    return data;
  }
}

class PartialPayment {
  String? id;
  String? bookingId;
  String? paidWith;
  double? paidAmount;
  double? dueAmount;
  String? createdAt;
  String? updatedAt;
  String? receivedBy;
  String? receivedByLabel;
  String? paymentMethodLabel;
  String? transactionId;
  double? dueAfterPayment;

  PartialPayment(
      {this.id,
        this.bookingId,
        this.paidWith,
        this.paidAmount,
        this.dueAmount,
        this.createdAt,
        this.updatedAt,
        this.receivedBy,
        this.receivedByLabel,
        this.paymentMethodLabel,
        this.transactionId,
        this.dueAfterPayment});

  PartialPayment.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    bookingId = json['booking_id'];
    paidWith = json['paid_with'];
    paidAmount = double.tryParse(json['paid_amount'].toString());
    dueAmount = double.tryParse(json['due_amount'].toString());
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    receivedBy = json['received_by'];
    receivedByLabel = json['received_by_label'];
    paymentMethodLabel = json['payment_method_label'];
    transactionId = json['transaction_id'];
    dueAfterPayment = double.tryParse(json['due_after_payment']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['booking_id'] = bookingId;
    data['paid_with'] = paidWith;
    data['paid_amount'] = paidAmount;
    data['due_amount'] = dueAmount;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class RepeatHistory {
  int? id;
  String? bookingId;
  String? bookingRepeatId;
  String? bookingRepeatDetailsId;
  String? readableId;
  int? oldQuantity;
  int? newQuantity;
  int? isMultiple;
  double? totalBookingAmount;
  double? totalTaxAmount;
  double? totalDiscountAmount;
  double? extraFee;
  String? createdAt;
  String? updatedAt;
  List<RepeatHistoryLog>? repeatHistoryLogs;

  RepeatHistory({this.id,
    this.bookingId,
    this.bookingRepeatId,
    this.bookingRepeatDetailsId,
    this.readableId,
    this.oldQuantity,
    this.newQuantity,
    this.isMultiple,
    this.createdAt,
    this.updatedAt,
    this.repeatHistoryLogs,
    this.totalBookingAmount,
    this.totalDiscountAmount,
    this.totalTaxAmount,
    this.extraFee
  });

  RepeatHistory.fromJson(Map<String, dynamic> json) {
    id = int.tryParse(json['id'].toString());
    bookingId = json['booking_id'];
    bookingRepeatId = json['booking_repeat_id'];
    bookingRepeatDetailsId = json['booking_repeat_details_id'];
    readableId = json['readable_id'];
    oldQuantity = int.tryParse(json['old_quantity'].toString());
    newQuantity = int.tryParse(json['new_quantity'].toString());
    isMultiple = int.tryParse(json['is_multiple'].toString());
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    totalBookingAmount = double.tryParse(json['total_booking_amount'].toString());
    totalTaxAmount = double.tryParse(json['total_tax_amount'].toString());
    totalDiscountAmount = double.tryParse(json['total_discount_amount'].toString());
    extraFee = double.tryParse(json['extra_fee'].toString());
    if (json['log_details'] != null) {
      repeatHistoryLogs = <RepeatHistoryLog>[];
      json['log_details'].forEach((v) {
        repeatHistoryLogs!.add(RepeatHistoryLog.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['booking_id'] = bookingId;
    data['booking_repeat_id'] = bookingRepeatId;
    data['booking_repeat_details_id'] = bookingRepeatDetailsId;
    data['readable_id'] = readableId;
    data['old_quantity'] = oldQuantity;
    data['new_quantity'] = newQuantity;
    data['is_multiple'] = isMultiple;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class RepeatHistoryLog {
  String? serviceId;
  int? quantity;
  String? variantKey;
  String? serviceName;
  double? serviceCost;
  double? discountAmount;
  double? taxAmount;
  double? totalCost;
  String? repeatDetailsId;

  RepeatHistoryLog(
      {this.serviceId,
        this.quantity,
        this.variantKey,
        this.serviceName,
        this.serviceCost,
        this.discountAmount,
        this.taxAmount,
        this.totalCost,
        this.repeatDetailsId});

  RepeatHistoryLog.fromJson(Map<String, dynamic> json) {
    serviceId = json['service_id'];
    quantity = json['quantity'];
    variantKey = json['variant_key'].toString();
    serviceName = json['service_name'];
    serviceCost = double.tryParse(json['service_cost'].toString());
    discountAmount = double.tryParse(json['discount_amount'].toString());
    taxAmount = double.tryParse(json['tax_amount'].toString());
    totalCost = double.tryParse(json['total_cost'].toString());
    repeatDetailsId = json['repeat_details_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['service_id'] = serviceId;
    data['quantity'] = quantity;
    data['variant_key'] = variantKey;
    data['service_name'] = serviceName;
    data['service_cost'] = serviceCost;
    data['discount_amount'] = discountAmount;
    data['tax_amount'] = taxAmount;
    data['total_cost'] = totalCost;
    data['repeat_details_id'] = repeatDetailsId;
    return data;
  }
}

class BookingOfflinePayment {
  String? key;
  String? value;

  BookingOfflinePayment({String? key, String? value}) {
    if (key != null) {
      key = key;
    }
    if (value != null) {
      value = value;
    }
  }


  BookingOfflinePayment.fromJson(Map<String, dynamic> json) {
    key = json['key'];
    value = json['value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['key'] = key;
    data['value'] = value;
    return data;
  }
}

class BookingCategoryInfo {
  String? id;
  String? name;

  BookingCategoryInfo({this.id, this.name});

  BookingCategoryInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}

class BookingExtraServiceLine {
  String? id;
  String? name;
  double? amount;
  String? type;
  String? details;
  double? price;
  int? quantity;
  double? discount;
  double? total;

  BookingExtraServiceLine({
    this.id,
    this.name,
    this.amount,
    this.type,
    this.details,
    this.price,
    this.quantity,
    this.discount,
    this.total,
  });

  BookingExtraServiceLine.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    name = json['name']?.toString();
    amount = double.tryParse(json['amount']?.toString() ?? '');
    type = json['type']?.toString();
    details = json['details']?.toString();
    price = double.tryParse(json['price']?.toString() ?? '');
    quantity = int.tryParse(json['quantity']?.toString() ?? '');
    discount = double.tryParse(json['discount']?.toString() ?? '');
    total = double.tryParse(json['total']?.toString() ?? '');
  }

  bool get isSparePart => type == 'spare_part';
}

class BookingPaymentDetailsSummary {
  double? total;
  double? amountPaidDisplay;
  double? dueBalance;
  String? statusLabel;
  String? amountRowLabel;
  bool? showAsAmountPaidLabel;
  String? paymentMethodDisplay;
  String? offlineVerifyStatus;
  double? writeOffAmount;
  bool? isWriteoffSettled;
  bool? isDisputedSettlement;
  double? customerPaidTotal;
  double? refundedAmount;
  double? refundTotal;
  double? finalBookingAmount;
  double? retainedAmount;
  double? refundableAmount;
  double? refundableRemaining;
  double? pendingRefund;

  BookingPaymentDetailsSummary({
    this.total,
    this.amountPaidDisplay,
    this.dueBalance,
    this.statusLabel,
    this.amountRowLabel,
    this.showAsAmountPaidLabel,
    this.paymentMethodDisplay,
    this.offlineVerifyStatus,
    this.writeOffAmount,
    this.isWriteoffSettled,
    this.isDisputedSettlement,
    this.customerPaidTotal,
    this.refundedAmount,
    this.refundTotal,
    this.finalBookingAmount,
    this.retainedAmount,
    this.refundableAmount,
    this.refundableRemaining,
    this.pendingRefund,
  });

  BookingPaymentDetailsSummary.fromJson(Map<String, dynamic> json) {
    total = double.tryParse(json['total']?.toString() ?? '');
    amountPaidDisplay = double.tryParse(json['amount_paid_display']?.toString() ?? '');
    dueBalance = double.tryParse(json['due_balance']?.toString() ?? '');
    statusLabel = json['status_label'];
    amountRowLabel = json['amount_row_label'];
    showAsAmountPaidLabel = json['show_as_amount_paid_label'] == true;
    paymentMethodDisplay = json['payment_method_display'];
    offlineVerifyStatus = json['offline_verify_status'];
    writeOffAmount = double.tryParse(json['write_off_amount']?.toString() ?? '')
        ?? double.tryParse(json['settlement_amount']?.toString() ?? '');
    isWriteoffSettled = json['is_writeoff_settled'] == true
        || ((writeOffAmount ?? 0) > 0.009);
    isDisputedSettlement = json['is_disputed_settlement'] == true;
    customerPaidTotal = double.tryParse(json['customer_paid_total']?.toString() ?? '');
    refundedAmount = double.tryParse(json['refunded_amount']?.toString() ?? '');
    refundTotal = double.tryParse(json['refund_total']?.toString() ?? '');
    finalBookingAmount = double.tryParse(json['final_booking_amount']?.toString() ?? '');
    retainedAmount = double.tryParse(json['retained_amount']?.toString() ?? '');
    refundableAmount = double.tryParse(json['refundable_amount']?.toString() ?? '');
    refundableRemaining = double.tryParse(json['refundable_remaining']?.toString() ?? '');
    pendingRefund = double.tryParse(json['pending_refund']?.toString() ?? '');
  }
}

class BookingPaymentLedger {
  List<BookingPaymentLedgerEntry>? installments;
  List<BookingRefundLedgerEntry>? refunds;

  BookingPaymentLedger({this.installments, this.refunds});

  BookingPaymentLedger.fromJson(Map<String, dynamic> json) {
    if (json['installments'] != null) {
      installments = <BookingPaymentLedgerEntry>[];
      json['installments'].forEach((v) {
        installments!.add(BookingPaymentLedgerEntry.fromJson(v));
      });
    }
    if (json['refunds'] != null) {
      refunds = <BookingRefundLedgerEntry>[];
      json['refunds'].forEach((v) {
        refunds!.add(BookingRefundLedgerEntry.fromJson(v));
      });
    }
  }
}

class BookingPaymentLedgerEntry {
  int? serial;
  String? date;
  String? receivedBy;
  String? receivedByLabel;
  double? amount;
  String? paymentMethodLabel;
  String? transactionId;
  double? dueAfterPayment;

  BookingPaymentLedgerEntry({
    this.serial,
    this.date,
    this.receivedBy,
    this.receivedByLabel,
    this.amount,
    this.paymentMethodLabel,
    this.transactionId,
    this.dueAfterPayment,
  });

  BookingPaymentLedgerEntry.fromJson(Map<String, dynamic> json) {
    serial = int.tryParse(json['serial']?.toString() ?? '');
    date = json['date'];
    receivedBy = json['received_by'];
    receivedByLabel = json['received_by_label'];
    amount = double.tryParse(json['amount']?.toString() ?? '');
    paymentMethodLabel = json['payment_method_label'];
    transactionId = json['transaction_id'];
    dueAfterPayment = double.tryParse(json['due_after_payment']?.toString() ?? '');
  }
}

class BookingRefundLedgerEntry {
  int? serial;
  String? date;
  double? amount;
  String? transactionId;
  String? referenceNote;

  BookingRefundLedgerEntry({
    this.serial,
    this.date,
    this.amount,
    this.transactionId,
    this.referenceNote,
  });

  BookingRefundLedgerEntry.fromJson(Map<String, dynamic> json) {
    serial = int.tryParse(json['serial']?.toString() ?? '');
    date = json['date'];
    amount = double.tryParse(json['amount']?.toString() ?? '');
    transactionId = json['transaction_id'];
    referenceNote = json['reference_note'];
  }
}

class BookingSummaryLine {
  String? name;
  double? amount;

  BookingSummaryLine({this.name, this.amount});

  BookingSummaryLine.fromJson(Map<String, dynamic> json) {
    name = json['name']?.toString();
    amount = double.tryParse(json['amount']?.toString() ?? '');
  }
}

class BookingSummaryPayload {
  double? serviceAmount;
  List<BookingSummaryLine>? extraServiceLines;
  List<BookingSummaryLine>? sparePartLines;
  List<BookingSummaryLine>? additionalChargeLines;
  double? grossTotal;
  double? serviceDiscount;
  double? couponDiscount;
  double? campaignDiscount;
  double? referralDiscount;
  double? tax;
  bool? hasTax;
  double? grandTotal;
  double? totalPaid;
  double? dueAmount;

  BookingSummaryPayload({
    this.serviceAmount,
    this.extraServiceLines,
    this.sparePartLines,
    this.additionalChargeLines,
    this.grossTotal,
    this.serviceDiscount,
    this.couponDiscount,
    this.campaignDiscount,
    this.referralDiscount,
    this.tax,
    this.hasTax,
    this.grandTotal,
    this.totalPaid,
    this.dueAmount,
  });

  BookingSummaryPayload.fromJson(Map<String, dynamic> json) {
    serviceAmount = double.tryParse(json['service_amount']?.toString() ?? '');
    grossTotal = double.tryParse(json['gross_total']?.toString() ?? '');
    serviceDiscount = double.tryParse(json['service_discount']?.toString() ?? '');
    couponDiscount = double.tryParse(json['coupon_discount']?.toString() ?? '');
    campaignDiscount = double.tryParse(json['campaign_discount']?.toString() ?? '');
    referralDiscount = double.tryParse(json['referral_discount']?.toString() ?? '');
    tax = double.tryParse(json['tax']?.toString() ?? '');
    hasTax = json['has_tax'] == true;
    grandTotal = double.tryParse(json['grand_total']?.toString() ?? '');
    totalPaid = double.tryParse(json['total_paid']?.toString() ?? '');
    dueAmount = double.tryParse(json['due_amount']?.toString() ?? '');

    if (json['extra_service_lines'] is List) {
      extraServiceLines = (json['extra_service_lines'] as List)
          .map((v) => BookingSummaryLine.fromJson(Map<String, dynamic>.from(v)))
          .toList();
    }
    if (json['spare_part_lines'] is List) {
      sparePartLines = (json['spare_part_lines'] as List)
          .map((v) => BookingSummaryLine.fromJson(Map<String, dynamic>.from(v)))
          .toList();
    }
    if (json['additional_charge_lines'] is List) {
      additionalChargeLines = (json['additional_charge_lines'] as List)
          .map((v) => BookingSummaryLine.fromJson(Map<String, dynamic>.from(v)))
          .toList();
    }
  }
}

class SpecialFinancialSettlement {
  bool? hasSpecialSettlement;
  String? settlementOutcome;
  String? scenarioLabelKey;
  double? finalBookingAmount;
  String? notes;

  SpecialFinancialSettlement({
    this.hasSpecialSettlement,
    this.settlementOutcome,
    this.scenarioLabelKey,
    this.finalBookingAmount,
    this.notes,
  });

  SpecialFinancialSettlement.fromJson(Map<String, dynamic> json) {
    hasSpecialSettlement = json['has_special_settlement'] == true;
    settlementOutcome = json['settlement_outcome']?.toString();
    scenarioLabelKey = json['scenario_label_key']?.toString();
    finalBookingAmount = double.tryParse(json['final_booking_amount']?.toString() ?? '');
    notes = json['notes']?.toString();
  }
}

class DisputedSettlement {
  bool? hasDisputedSettlement;
  double? customerPaidTotal;
  double? refundTotal;
  double? finalBookingAmount;
  double? retainedFromCustomer;
  double? pendingRefund;
  bool? isFullRefund;
  bool? isPartialRefund;

  DisputedSettlement({
    this.hasDisputedSettlement,
    this.customerPaidTotal,
    this.refundTotal,
    this.finalBookingAmount,
    this.retainedFromCustomer,
    this.pendingRefund,
    this.isFullRefund,
    this.isPartialRefund,
  });

  DisputedSettlement.fromJson(Map<String, dynamic> json) {
    hasDisputedSettlement = json['has_disputed_settlement'] == true;
    customerPaidTotal = double.tryParse(json['customer_paid_total']?.toString() ?? '');
    refundTotal = double.tryParse(json['refund_total']?.toString() ?? '');
    finalBookingAmount = double.tryParse(json['final_booking_amount']?.toString() ?? '');
    retainedFromCustomer = double.tryParse(json['retained_from_customer']?.toString() ?? '');
    pendingRefund = double.tryParse(json['pending_refund']?.toString() ?? '');
    isFullRefund = json['is_full_refund'] == true;
    isPartialRefund = json['is_partial_refund'] == true;
  }
}

class LossMakingSettlement {
  bool? isLossMaking;
  double? totalBookingAmount;
  double? amountPaid;
  double? pendingBalance;
  double? writeOffAmount;
  bool? isWriteoffSettled;
  double? amountPaidByCustomer;
  double? lossAmount;
  double? lossToCompany;
  double? lossToProvider;
  double? companyCommissionFullBooking;
  double? providerShareBeforeLossFullBooking;
  double? netCompanyShareAfterLoss;
  double? netProviderShareAfterLoss;
  String? notes;

  LossMakingSettlement({
    this.isLossMaking,
    this.totalBookingAmount,
    this.amountPaid,
    this.pendingBalance,
    this.writeOffAmount,
    this.isWriteoffSettled,
    this.amountPaidByCustomer,
    this.lossAmount,
    this.lossToCompany,
    this.lossToProvider,
    this.companyCommissionFullBooking,
    this.providerShareBeforeLossFullBooking,
    this.netCompanyShareAfterLoss,
    this.netProviderShareAfterLoss,
    this.notes,
  });

  LossMakingSettlement.fromJson(Map<String, dynamic> json) {
    isLossMaking = json['is_loss_making'] == true;
    totalBookingAmount = double.tryParse(json['total_booking_amount']?.toString() ?? '');
    amountPaid = double.tryParse(json['amount_paid']?.toString() ?? '');
    pendingBalance = double.tryParse(json['pending_balance']?.toString() ?? '');
    writeOffAmount = double.tryParse(json['write_off_amount']?.toString() ?? '')
        ?? double.tryParse(json['settlement_amount']?.toString() ?? '');
    isWriteoffSettled = json['is_writeoff_settled'] == true
        || ((writeOffAmount ?? 0) > 0.009);
    amountPaidByCustomer = double.tryParse(json['amount_paid_by_customer']?.toString() ?? '');
    lossAmount = double.tryParse(json['loss_amount']?.toString() ?? '');
    lossToCompany = double.tryParse(json['loss_to_company']?.toString() ?? '');
    lossToProvider = double.tryParse(json['loss_to_provider']?.toString() ?? '');
    companyCommissionFullBooking = double.tryParse(json['company_commission_full_booking']?.toString() ?? '');
    providerShareBeforeLossFullBooking = double.tryParse(json['provider_share_before_loss_full_booking']?.toString() ?? '');
    netCompanyShareAfterLoss = double.tryParse(json['net_company_share_after_loss']?.toString() ?? '');
    netProviderShareAfterLoss = double.tryParse(json['net_provider_share_after_loss']?.toString() ?? '');
    notes = json['notes'];
  }
}


