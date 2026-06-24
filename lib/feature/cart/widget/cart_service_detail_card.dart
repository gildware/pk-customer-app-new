import 'package:demandium/feature/cart/widget/booking_date_time_picker.dart';
import 'package:demandium/helper/validation_helper.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;

class CartServiceDetailCard extends StatefulWidget {
  final CartModel cart;
  final int index;

  const CartServiceDetailCard({
    super.key,
    required this.cart,
    required this.index,
  });

  @override
  State<CartServiceDetailCard> createState() => _CartServiceDetailCardState();
}

class _CartServiceDetailCardState extends State<CartServiceDetailCard> {
  bool _isExpanded = false;

  CartModel get cart => widget.cart;

  String get _serviceName => cart.service?.name ?? 'service'.tr;

  String get _variationLabel => cart.variantKey.replaceAll('-', ' ').trim();

  String? get _thumbnail => cart.service?.thumbnailFullPath;

  String? get _slug => cart.service?.slug;

  String get _providerLabel {
    final name = cart.provider?.companyName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return '${'let'.tr} ${AppConstants.appName} ${'choose_for_you'.tr}';
  }

  AddressModel? get _bookingAddress => CartBookingDisplayHelper.resolveAddressForCartItem(cart);

  String? get _addressLine {
    final address = _bookingAddress?.address?.trim();
    if (address == null || address.isEmpty) return null;
    return address;
  }

  List<Widget> _buildPriceDetailLines(BuildContext context) {
    final lines = <Widget>[];
    final subtotal = cart.lineSubtotal.toDouble();
    final discount = cart.discountedPrice.toDouble();
    final campaignDiscount = cart.campaignDiscountPrice.toDouble();
    final couponDiscount = cart.couponDiscountPrice.toDouble();
    final tax = cart.taxAmount.toDouble();

    lines.add(const SizedBox(height: Dimensions.paddingSizeSmall));
    lines.add(_MetaLine(
      icon: Icons.shopping_bag_outlined,
      label: 'sub_total'.tr,
      value: PriceConverter.convertPrice(subtotal),
    ));

    if (discount > 0) {
      lines.add(const SizedBox(height: Dimensions.paddingSizeSmall));
      lines.add(_MetaLine(
        icon: Icons.local_offer_outlined,
        label: 'discount'.tr,
        value: '(-) ${PriceConverter.convertPrice(discount)}',
      ));
    }
    if (campaignDiscount > 0) {
      lines.add(const SizedBox(height: Dimensions.paddingSizeSmall));
      lines.add(_MetaLine(
        icon: Icons.campaign_outlined,
        label: 'campaign_discount'.tr,
        value: '(-) ${PriceConverter.convertPrice(campaignDiscount)}',
      ));
    }
    if (couponDiscount > 0) {
      lines.add(const SizedBox(height: Dimensions.paddingSizeSmall));
      lines.add(_MetaLine(
        icon: Icons.confirmation_number_outlined,
        label: 'coupon_discount'.tr,
        value: '(-) ${PriceConverter.convertPrice(couponDiscount)}',
      ));
    }
    if (tax > 0) {
      lines.add(const SizedBox(height: Dimensions.paddingSizeSmall));
      lines.add(_MetaLine(
        icon: Icons.receipt_long_outlined,
        label: 'tax'.tr,
        value: '(+) ${PriceConverter.convertPrice(tax)}',
      ));
    }
    for (final charge in cart.additionalChargeLines) {
      if (charge.amount <= 0) continue;
      lines.add(const SizedBox(height: Dimensions.paddingSizeSmall));
      lines.add(_MetaLine(
        icon: Icons.add_circle_outline_rounded,
        label: charge.name.isNotEmpty ? charge.name : 'service_charge'.tr,
        value: '(+) ${PriceConverter.convertPrice(charge.amount)}',
      ));
    }
    if (cart.additionalChargeLines.isEmpty && cart.additionalChargeTotal > 0) {
      lines.add(const SizedBox(height: Dimensions.paddingSizeSmall));
      lines.add(_MetaLine(
        icon: Icons.add_circle_outline_rounded,
        label: 'service_charge'.tr,
        value: '(+) ${PriceConverter.convertPrice(cart.additionalChargeTotal)}',
      ));
    }

    return lines;
  }

  List<Widget> _buildBookingDetailLines(BuildContext context) {
    final scheduleLabel = CartBookingDisplayHelper.resolveScheduleLabelForCartItem(cart);
    final lines = <Widget>[];

    if (scheduleLabel != null && scheduleLabel.isNotEmpty) {
      final hasInvalidSchedule = CartBookingDisplayHelper.isCartItemScheduleInvalid(cart);
      lines.add(const SizedBox(height: Dimensions.paddingSizeSmall));
      lines.add(_MetaLine(
        icon: Icons.schedule_rounded,
        label: 'preferable_time'.tr,
        value: scheduleLabel,
        subtitle: hasInvalidSchedule
            ? CartBookingDisplayHelper.invalidScheduleMessageForCartItem(cart)
            : null,
        valueColor: hasInvalidSchedule ? Theme.of(context).colorScheme.error : null,
        trailing: InkWell(
          onTap: () => _openScheduleEditor(context),
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.edit_outlined,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ));
      if (hasInvalidSchedule) {
        lines.add(const SizedBox(height: Dimensions.paddingSizeSmall));
        lines.add(
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _openScheduleEditor(context),
              icon: const Icon(Icons.update_rounded, size: 18),
              label: Text('update_schedule_time'.tr),
            ),
          ),
        );
      }
    }

    return lines;
  }

  void _prepareScheduleControllerForEdit() {
    final scheduleController = Get.find<ScheduleController>();
    final raw = CartBookingDisplayHelper.resolveRawScheduleForCartItem(cart);
    final parsed = raw != null ? DateConverter.tryParseScheduleDateTime(raw) : null;

    scheduleController.updateScheduleType(
      scheduleType: ScheduleType.schedule,
      shouldUpdate: false,
    );

    if (parsed != null && !CartBookingDisplayHelper.isAsapSchedule(parsed)) {
      scheduleController.selectedDate = DateFormat('yyyy-MM-dd').format(parsed);
      scheduleController.selectedTime = DateFormat('HH:mm:ss').format(parsed);
      scheduleController.buildSchedule(
        shouldUpdate: false,
        scheduleType: ScheduleType.schedule,
        schedule: raw,
      );
      return;
    }

    final min = BookingDateTimePicker.minimumScheduleTime();
    scheduleController.selectedDate = DateFormat('yyyy-MM-dd').format(min);
    scheduleController.selectedTime = DateFormat('HH:mm:ss').format(min);
    scheduleController.buildSchedule(
      shouldUpdate: false,
      scheduleType: ScheduleType.schedule,
    );
  }

  ProviderData? get _assignedProvider {
    final provider = cart.provider;
    if (provider != null && ValidationHelper.isValidUuid(provider.id)) {
      return provider;
    }
    return null;
  }

  Future<void> _openScheduleEditor(BuildContext context) async {
    _prepareScheduleControllerForEdit();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingDateTimePicker(
        providerToValidate: _assignedProvider,
        onScheduleConfirmed: (scheduleTime, selected) {
          return Get.find<CartController>().updateCartItemBookingSchedule(
            cartId: cart.id,
            scheduleTime: scheduleTime,
            selectedDateTime: selected,
            provider: _assignedProvider,
            zoneId: cart.zoneId,
          );
        },
      ),
    );
  }

  Future<void> _confirmRemoveFromCart() async {
    await Get.dialog(
      ConfirmationDialog(
        icon: Images.deleteProfile,
        description: 'do_you_want_to_delete_from_cart',
        onYesPressed: () async {
          Get.back();
          Get.dialog(const CustomLoader(), barrierDismissible: false);
          await Get.find<CartController>().removeCartFromServer(cart);
          if (Get.isDialogOpen ?? false) {
            Get.back();
          }
        },
      ),
      useSafeArea: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      id: CompanyAvailabilityConfigWatcher.bookingConfigUpdateId,
      builder: (_) => _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hasInvalidSchedule = CartBookingDisplayHelper.isCartItemScheduleInvalid(cart);
    final borderColor = hasInvalidSchedule
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).dividerColor.withValues(alpha: 0.25);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            border: Border.all(
              color: borderColor,
              width: hasInvalidSchedule ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(Dimensions.radiusLarge),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ServiceThumbnail(
                        thumbnail: _thumbnail,
                        onTap: _slug != null
                            ? () => Get.toNamed(RouteHelper.getServiceRoute(_slug!))
                            : null,
                      ),
                      const SizedBox(width: Dimensions.paddingSizeDefault),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _serviceName,
                              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                            _ChipLabel(
                              icon: Icons.tune_rounded,
                              label: _variationLabel,
                            ),
                            if (_addressLine != null) ...[
                              const SizedBox(height: Dimensions.paddingSizeSmall),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: Theme.of(context).hintColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _addressLine!,
                                      style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: Theme.of(context).hintColor,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                        vertical: Dimensions.paddingSizeSmall,
                      ),
                      child: Column(
                        children: [
                          _MetaLine(
                            icon: Icons.storefront_outlined,
                            label: 'assigned_provider'.tr,
                            value: _providerLabel,
                          ),
                          ..._buildBookingDetailLines(context),
                          ..._buildPriceDetailLines(context),
                        ],
                      ),
                    ),
                  ],
                ),
                crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
                sizeCurve: Curves.easeInOut,
              ),
              if (!_isExpanded)
                Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                  vertical: Dimensions.paddingSizeSmall,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).hoverColor.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(Dimensions.radiusLarge),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'line_total'.tr,
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              PriceConverter.convertPrice(cart.lineTotalWithCharges.toDouble()),
                              style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeExtraLarge,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${'quantity'.tr}:',
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    if (cart.quantity > 1)
                      QuantityButton(
                        onTap: () => Get.find<CartController>().updateCartQuantityToApi(
                          cart.id,
                          cart.quantity - 1,
                        ),
                        isIncrement: false,
                      )
                    else
                      InkWell(
                        onTap: _confirmRemoveFromCart,
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 22,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        cart.quantity.toString(),
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                      ),
                    ),
                    QuantityButton(
                      onTap: () => Get.find<CartController>().updateCartQuantityToApi(
                        cart.id,
                        cart.quantity + 1,
                      ),
                      isIncrement: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _ServiceThumbnail extends StatelessWidget {
  final String? thumbnail;
  final VoidCallback? onTap;

  const _ServiceThumbnail({this.thumbnail, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = ClipRRect(
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: thumbnail != null && thumbnail!.isNotEmpty
          ? CustomImage(image: thumbnail!, height: 72, width: 72, fit: BoxFit.cover)
          : Container(
              height: 72,
              width: 72,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              child: Icon(
                Icons.home_repair_service_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ),
    );

    if (onTap == null) return child;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(Dimensions.radiusDefault), child: child);
  }
}

class _ChipLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ChipLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusSeven),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).colorScheme.primary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final Widget? trailing;

  const _MetaLine({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).hintColor),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: valueColor,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: Theme.of(context).hintColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
