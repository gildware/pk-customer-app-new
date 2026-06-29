import 'package:demandium/util/core_export.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

class BookingCancelReasonDialog extends StatefulWidget {
  final String bookingId;
  final bool isSubBooking;
  final BookingDetailsContent? booking;
  final bool fromListScreen;

  const BookingCancelReasonDialog({
    super.key,
    required this.bookingId,
    this.isSubBooking = false,
    this.booking,
    this.fromListScreen = false,
  });

  static Future<void> show({
    required String bookingId,
    bool isSubBooking = false,
    BookingDetailsContent? booking,
    bool fromListScreen = false,
  }) {
    return Get.dialog(
      BookingCancelReasonDialog(
        bookingId: bookingId,
        isSubBooking: isSubBooking,
        booking: booking,
        fromListScreen: fromListScreen,
      ),
      barrierDismissible: true,
    );
  }

  @override
  State<BookingCancelReasonDialog> createState() => _BookingCancelReasonDialogState();
}

class _BookingCancelReasonDialogState extends State<BookingCancelReasonDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _noteController = TextEditingController();
  int? _selectedReasonId;
  String? _refundMethod;

  BookingDetailsContent? get _booking =>
      widget.booking ?? Get.find<BookingDetailsController>().bookingDetailsContent;

  CustomerRefundChannelBreakdown get _refundBreakdown {
    final booking = _booking;
    if (booking == null) {
      return const CustomerRefundChannelBreakdown();
    }
    return BookingHelper.resolveRefundChannelBreakdown(booking);
  }

  bool get _requiresDigitalRefundChoice => _refundBreakdown.requiresDigitalRefundChoice;

  bool get _showRefundBreakdown => _refundBreakdown.hasAnyRefundable;

  bool get _walletEnabled {
    return Get.find<SplashController>().configModel.content?.walletStatus == 1;
  }

  @override
  void initState() {
    super.initState();
    _refundMethod = _defaultRefundMethod();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final controller = Get.find<BookingDetailsController>();
      if (widget.booking == null && widget.bookingId.isNotEmpty) {
        await controller.getBookingDetails(bookingId: widget.bookingId, reload: false);
      }
      await controller.getCustomerCancellationReasons();
      if (mounted) {
        setState(() {
          _refundMethod ??= _defaultRefundMethod();
        });
      }
    });
  }

  String? _defaultRefundMethod() {
    if (!_requiresDigitalRefundChoice) {
      return null;
    }
    return 'transfer';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height - viewInsets.bottom - 40;

    return GetBuilder<BookingDetailsController>(
      builder: (controller) {
        final reasons = controller.customerCancellationReasons;
        final isLoadingReasons = controller.isLoadingCancellationReasons;
        final isSubmitting = controller.isCancelling;

        return Dialog(
          elevation: 0,
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
          backgroundColor: Theme.of(context).cardColor,
          child: Padding(
            padding: EdgeInsets.only(bottom: viewInsets.bottom),
            child: SizedBox(
              width: 420,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                            child: Image.asset(Images.warning, width: 50, height: 50),
                          ),
                          Text(
                            widget.isSubBooking
                                ? 'are_you_sure_to_cancel_your_order'.tr
                                : 'are_you_sure_to_cancel_this_full_booking'.tr,
                            textAlign: TextAlign.center,
                            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          Text(
                            'select_cancellation_reason_hint'.tr,
                            textAlign: TextAlign.center,
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          if (isLoadingReasons)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (reasons.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                              child: Column(
                                children: [
                                  Text(
                                    'no_cancellation_reasons_configured'.tr,
                                    textAlign: TextAlign.center,
                                    style: robotoRegular.copyWith(
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                  const SizedBox(height: Dimensions.paddingSizeSmall),
                                  TextButton(
                                    onPressed: () => controller.getCustomerCancellationReasons(forceReload: true),
                                    child: Text('try_again'.tr),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            Text(
                              'cancellation_reason'.tr,
                              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            DropdownButtonFormField<int>(
                              value: _selectedReasonId,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeDefault,
                                  vertical: Dimensions.paddingSizeSmall,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                ),
                              ),
                              hint: Text('select_cancellation_reason'.tr),
                              items: reasons.map((reason) {
                                return DropdownMenuItem<int>(
                                  value: reason.id,
                                  child: Text(reason.name ?? ''),
                                );
                              }).toList(),
                              onChanged: isSubmitting
                                  ? null
                                  : (value) => setState(() => _selectedReasonId = value),
                              validator: (value) {
                                if (value == null) {
                                  return 'select_cancellation_reason'.tr;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: Dimensions.paddingSizeDefault),
                            Text(
                              'additional_note_optional'.tr,
                              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            CustomTextFormField(
                              controller: _noteController,
                              hintText: 'cancellation_note_optional_hint'.tr,
                              inputType: TextInputType.multiline,
                              maxLines: 3,
                              capitalization: TextCapitalization.sentences,
                              isShowBorder: true,
                              outlineInputBorderRadius: Dimensions.radiusSmall,
                            ),
                            if (_showRefundBreakdown) ...[
                              const SizedBox(height: Dimensions.paddingSizeLarge),
                              _CancellationRefundBreakdown(breakdown: _refundBreakdown),
                            ],
                            if (_requiresDigitalRefundChoice) ...[
                              const SizedBox(height: Dimensions.paddingSizeLarge),
                              Text(
                                _refundBreakdown.hasMixedPayments
                                    ? 'digital_refund_choice_hint'.tr
                                    : 'how_do_you_want_refund'.tr,
                                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeSmall),
                              Row(
                                children: [
                                  if (_walletEnabled)
                                    Expanded(
                                      child: _RefundMethodOption(
                                        value: 'wallet',
                                        label: 'transfer_to_wallet'.tr,
                                        groupValue: _refundMethod,
                                        enabled: !isSubmitting,
                                        onChanged: (value) => setState(() => _refundMethod = value),
                                      ),
                                    ),
                                  Expanded(
                                    child: _RefundMethodOption(
                                      value: 'transfer',
                                      label: 'transfer_to_account'.tr,
                                      groupValue: _refundMethod,
                                      enabled: !isSubmitting,
                                      onChanged: (value) => setState(() => _refundMethod = value),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: isSubmitting ? null : () => Get.back(),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Theme.of(context).hintColor.withValues(alpha: 0.3),
                                    minimumSize: const Size(Dimensions.webMaxWidth, 40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                    ),
                                  ),
                                  child: Text(
                                    'not_now'.tr,
                                    style: robotoBold.copyWith(
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: Dimensions.paddingSizeDefault),
                              Expanded(
                                child: CustomButton(
                                  buttonText: 'yes_cancel'.tr,
                                  height: 40,
                                  radius: Dimensions.radiusSmall,
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  isLoading: isSubmitting,
                                  onPressed: reasons.isEmpty || isLoadingReasons || isSubmitting
                                      ? null
                                      : () => _submit(controller),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit(BookingDetailsController controller) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_requiresDigitalRefundChoice) {
      if (_refundMethod == null) {
        customSnackBar('select_refund_method'.tr);
        return;
      }
      if (_refundMethod == 'wallet' && !_walletEnabled) {
        customSnackBar('customer_wallet_not_available'.tr);
        return;
      }
    }

    final note = _noteController.text.trim();
    final isSuccess = widget.isSubBooking
        ? await controller.subBookingCancel(
            subBookingId: widget.bookingId,
            customerCancellationReasonId: _selectedReasonId!,
            statusChangeRemarks: note.isEmpty ? null : note,
          )
        : await controller.bookingCancel(
            bookingId: widget.bookingId,
            customerCancellationReasonId: _selectedReasonId!,
            statusChangeRemarks: note.isEmpty ? null : note,
            refundMethod: _requiresDigitalRefundChoice ? _refundMethod : null,
            fromListScreen: widget.fromListScreen,
          );

    if (isSuccess) {
      _dismissAfterSuccess();
    }
  }

  void _dismissAfterSuccess() {
    if (!mounted) {
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (navigator.canPop()) {
        navigator.pop();
      }
    });
  }
}

class _CancellationRefundBreakdown extends StatelessWidget {
  final CustomerRefundChannelBreakdown breakdown;

  const _CancellationRefundBreakdown({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).hintColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'cancellation_refund_breakdown'.tr,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          if (breakdown.hasWalletPaid)
            _RefundBreakdownRow(
              title: 'paid_via_wallet'.tr,
              amount: breakdown.walletPaid,
              subtitle: 'refund_to_wallet_automatically'.tr,
            ),
          if (breakdown.hasWalletPaid && breakdown.hasDigitalPaid)
            const SizedBox(height: Dimensions.paddingSizeSmall),
          if (breakdown.hasDigitalPaid)
            _RefundBreakdownRow(
              title: 'paid_via_digital'.tr,
              amount: breakdown.digitalPaid,
              subtitle: breakdown.hasMixedPayments
                  ? 'refund_via_bank_transfer'.tr
                  : null,
            ),
        ],
      ),
    );
  }
}

class _RefundBreakdownRow extends StatelessWidget {
  final String title;
  final double amount;
  final String? subtitle;

  const _RefundBreakdownRow({
    required this.title,
    required this.amount,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
              ),
            ),
            Text(
              PriceConverter.convertPrice(amount),
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ],
    );
  }
}

class _RefundMethodOption extends StatelessWidget {
  final String value;
  final String label;
  final String? groupValue;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  const _RefundMethodOption({
    required this.value,
    required this.label,
    required this.groupValue,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(value) : null,
      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: groupValue,
            onChanged: enabled ? onChanged : null,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Expanded(
            child: Text(
              label,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
          ),
        ],
      ),
    );
  }
}
