import 'package:demandium/helper/booking_helper.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';
import 'package:universal_html/html.dart' as html;

class BookingDuePaymentAmountDialog extends StatefulWidget {
  final BookingDetailsContent bookingDetails;
  final bool isSubBooking;

  const BookingDuePaymentAmountDialog({
    super.key,
    required this.bookingDetails,
    required this.isSubBooking,
  });

  @override
  State<BookingDuePaymentAmountDialog> createState() => _BookingDuePaymentAmountDialogState();
}

class _BookingDuePaymentAmountDialogState extends State<BookingDuePaymentAmountDialog> {
  static const _payFull = 'full';
  static const _payOther = 'other';

  String _selectedType = _payFull;
  bool _isLaunchingPayment = false;
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _amountFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(_scrollAmountFieldIntoView);
  }

  @override
  void dispose() {
    _amountFocusNode.removeListener(_scrollAmountFieldIntoView);
    _amountController.dispose();
    _amountFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollAmountFieldIntoView() {
    if (!_amountFocusNode.hasFocus) {
      return;
    }
    Future.delayed(const Duration(milliseconds: 300), () {
      final fieldContext = _amountFieldKey.currentContext;
      if (fieldContext != null && mounted) {
        Scrollable.ensureVisible(
          fieldContext,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: 0.2,
        );
      }
    });
  }

  double get _dueBalance => BookingHelper.getDueBalanceAmount(widget.bookingDetails);

  String _formatAmountForInput(double amount) {
    if ((amount - amount.roundToDouble()).abs() < 0.001) {
      return amount.round().toString();
    }
    return amount.toStringAsFixed(2);
  }

  void _selectPayOther() {
    setState(() {
      _selectedType = _payOther;
      _amountController.text = _formatAmountForInput(_dueBalance);
    });
  }

  DigitalPaymentMethod? _resolveDigitalGateway() {
    final gateways = CheckoutHelper.enabledDigitalPaymentGateways();
    return gateways.isNotEmpty ? gateways.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(Dimensions.paddingSizeDefault),
          topRight: const Radius.circular(Dimensions.paddingSizeDefault),
          bottomLeft: ResponsiveHelper.isDesktop(context)
              ? const Radius.circular(Dimensions.paddingSizeDefault)
              : Radius.zero,
          bottomRight: ResponsiveHelper.isDesktop(context)
              ? const Radius.circular(Dimensions.paddingSizeDefault)
              : Radius.zero,
        ),
      ),
      child: SizedBox(
        width: ResponsiveHelper.isDesktop(context) ? Dimensions.webMaxWidth / 2.5 : double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  Center(
                    child: Text(
                      'choose_amount_to_pay'.tr,
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Center(
                    child: Text(
                      '${'due_amount'.tr}: ${PriceConverter.convertPrice(_dueBalance, isShowLongPrice: true)}',
                      style: robotoMedium.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  _AmountOptionTile(
                    title: 'pay_full_amount'.tr,
                    subtitle: 'pay_full_amount_subtitle'.tr,
                    amount: _dueBalance,
                    isSelected: _selectedType == _payFull,
                    onTap: () => setState(() => _selectedType = _payFull),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  _AmountOptionTile(
                    title: 'pay_other_amount'.tr,
                    subtitle: 'pay_other_amount_subtitle'.tr,
                    amount: null,
                    isSelected: _selectedType == _payOther,
                    onTap: _selectPayOther,
                  ),
                  if (_selectedType == _payOther) ...[
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Padding(
                      key: _amountFieldKey,
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                      child: TextFormField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.done,
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                        decoration: InputDecoration(
                          hintText: 'enter_amount'.tr,
                          hintStyle: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: Theme.of(context).hintColor.withValues(alpha: 0.6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeDefault,
                            vertical: Dimensions.paddingSizeDefault,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            borderSide: BorderSide(
                              color: Theme.of(context).hintColor.withValues(alpha: 0.25),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            borderSide: BorderSide(color: context.adaptivePrimaryColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    child: CustomButton(
                      buttonText: 'continue'.tr,
                      radius: Dimensions.radiusSeven,
                      isLoading: _isLaunchingPayment,
                      onPressed: _isLaunchingPayment ? null : _continueToPayment,
                    ),
                  ),
                  SizedBox(height: bottomPadding > 0 ? bottomPadding : Dimensions.paddingSizeDefault),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 0,
              child: InkWell(
                onTap: _isLaunchingPayment ? null : Get.back,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).hintColor.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeTine),
                  child: const Icon(Icons.close, size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Future<void> _continueToPayment() async {
    final paymentAmount = _resolvePaymentAmount();
    if (paymentAmount == null) {
      return;
    }

    final gateway = _resolveDigitalGateway();
    if (gateway == null) {
      customSnackBar(
        'no_payment_method_available'.tr,
        type: ToasterMessageType.info,
        showDefaultSnackBar: false,
      );
      return;
    }

    setState(() => _isLaunchingPayment = true);
    Get.back();
    await _launchDigitalPayment(
      paymentAmount: paymentAmount,
      gateway: gateway.gateway ?? '',
    );
  }

  double? _resolvePaymentAmount() {
    if (_selectedType == _payFull) {
      return _dueBalance;
    }

    final raw = _amountController.text.trim().replaceAll(',', '');
    if (raw.isEmpty) {
      customSnackBar('enter_amount'.tr, type: ToasterMessageType.info, showDefaultSnackBar: false);
      return null;
    }

    final amount = double.tryParse(raw);
    if (amount == null) {
      customSnackBar('please_enter_valid_amount'.tr, type: ToasterMessageType.info, showDefaultSnackBar: false);
      return null;
    }
    if (amount <= 0) {
      customSnackBar('amount_must_be_greater_than_zero'.tr, type: ToasterMessageType.info, showDefaultSnackBar: false);
      return null;
    }
    if (amount > _dueBalance + 0.009) {
      customSnackBar(
        '${'amount_cannot_exceed_due'.tr} ${PriceConverter.convertPrice(_dueBalance, isShowLongPrice: true)}',
        type: ToasterMessageType.info,
        showDefaultSnackBar: false,
      );
      return null;
    }

    return amount;
  }

  Future<void> _launchDigitalPayment({
    required double paymentAmount,
    required String gateway,
  }) async {
    final bookingId = widget.bookingDetails.id ?? '';
    if (bookingId.isEmpty) {
      return;
    }

    final userId =
        Get.find<UserController>().userInfoModel?.id ?? Get.find<SplashController>().getGuestId();
    final accessToken = await PaymentAccessTokenHelper.forSubject(userId);
    final platform = ResponsiveHelper.isWeb() ? 'web' : 'app';

    String url;
    if (GetPlatform.isWeb) {
      final hostname = html.window.location.hostname!;
      final protocol = html.window.location.protocol;
      final port = html.window.location.port;
      final callbackUrl = '$protocol//$hostname:$port${RouteHelper.bookingDetailsScreen}';
      url = _buildPaymentUrl(
        gateway: gateway,
        accessToken: accessToken,
        platform: platform,
        callbackUrl: callbackUrl,
        bookingId: bookingId,
        paymentAmount: paymentAmount,
      );
      html.window.open(url, '_self');
      return;
    }

    url = _buildPaymentUrl(
      gateway: gateway,
      accessToken: accessToken,
      platform: platform,
      callbackUrl: AppConstants.baseUrl,
      bookingId: bookingId,
      paymentAmount: paymentAmount,
    );

    await DigitalPaymentLauncher.start(
      paymentUrl: url,
      fromPage: 'booking-due-payment',
      gateway: gateway,
    );
  }

  String _buildPaymentUrl({
    required String gateway,
    required String accessToken,
    required String platform,
    required String callbackUrl,
    required String bookingId,
    required double paymentAmount,
  }) {
    final amount = paymentAmount.toStringAsFixed(2);
    if (widget.isSubBooking) {
      final repeatBookingId = widget.bookingDetails.id ?? '';
      final parentBookingId = widget.bookingDetails.bookingId ?? '';
      return '${AppConstants.baseUrl}/payment?payment_method=$gateway&access_token=$accessToken'
          '&callback=$callbackUrl&payment_platform=$platform&is_repeat_single_booking=1'
          '&booking_repeat_id=$repeatBookingId&booking_id=$parentBookingId&amount=$amount';
    }

    return '${AppConstants.baseUrl}/payment?payment_method=$gateway&access_token=$accessToken'
        '&booking_id=$bookingId&switch_offline_to_digital=1&callback=$callbackUrl&is_partial=0'
        '&payment_platform=$platform&amount=$amount';
  }
}

class _AmountOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double? amount;
  final bool isSelected;
  final VoidCallback onTap;

  const _AmountOptionTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: isSelected
                 ? context.tabSelectedColor
                : Theme.of(context).hintColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? context.tabSelectedColor : Theme.of(context).hintColor,
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: robotoMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
            if (amount != null)
              Text(
                PriceConverter.convertPrice(amount!, isShowLongPrice: true),
                style: robotoBold.copyWith(color: context.adaptivePrimaryColor),
              ),
          ],
        ),
      ),
    );
  }
}
