import 'package:demandium/feature/cart/model/service_booking_step.dart';
import 'package:demandium/feature/cart/widget/booking_date_time_picker.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ServiceBookingFlowWidget extends StatefulWidget {
  final Service service;
  final VoidCallback onComplete;

  const ServiceBookingFlowWidget({
    super.key,
    required this.service,
    required this.onComplete,
  });

  @override
  State<ServiceBookingFlowWidget> createState() => _ServiceBookingFlowWidgetState();
}

class _ServiceBookingFlowWidgetState extends State<ServiceBookingFlowWidget> {
  @override
  void initState() {
    super.initState();
    if (Get.find<AuthController>().isLoggedIn()) {
      Get.find<LocationController>().getAddressList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      switch (cartController.bookingStep) {
        case ServiceBookingStep.address:
          return _AddressStep();
        case ServiceBookingStep.schedule:
          return _ScheduleStep(service: widget.service);
        case ServiceBookingStep.provider:
          return _ProviderStep(service: widget.service);
        case ServiceBookingStep.preview:
          return _PreviewStep(service: widget.service, onComplete: widget.onComplete);
        case ServiceBookingStep.variations:
          return const SizedBox.shrink();
      }
    });
  }
}

class _StepHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _StepHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge), textAlign: TextAlign.center),
        const SizedBox(height: Dimensions.paddingSizeMini),
        Text(
          subtitle,
          style: robotoRegular.copyWith(
            color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: .5),
            fontSize: Dimensions.fontSizeSmall,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),
      ],
    );
  }
}

class _AddressStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Get.find<AuthController>().isLoggedIn();
    return GetBuilder<CartController>(builder: (cartController) {
      return GetBuilder<LocationController>(builder: (locationController) {
        final addresses = locationController.addressList ?? [];
        final hasSelection = cartController.pendingBookingAddress != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepHeader(
              title: 'select_your_address'.tr,
              subtitle: 'where_you_want_to_take_the_service'.tr,
            ),
            if (isLoggedIn)
              InkWell(
                onTap: () async {
                  await Get.toNamed(RouteHelper.getAddAddressRoute(false));
                  locationController.getAddressList();
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: Theme.of(context).colorScheme.primary, size: 20),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      Text('add_new_address_plus'.tr, style: robotoMedium.copyWith(color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                ),
              ),
            if (!isLoggedIn)
              Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                child: CustomButton(
                  buttonText: 'pick_an_address'.tr,
                  onPressed: () async {
                    await Get.toNamed(RouteHelper.getAddAddressRoute(false));
                    final saved = locationController.getUserAddress();
                    if (saved != null) {
                      cartController.setPendingBookingAddress(saved);
                    }
                  },
                ),
              ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: Get.height * 0.35),
              child: addresses.isEmpty
                  ? Center(child: Text('no_saved_address_fount'.tr, style: robotoRegular))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: addresses.length,
                      itemBuilder: (context, index) {
                        final address = addresses[index];
                        final isSelected = cartController.pendingBookingAddress?.id == address.id;
                        return GestureDetector(
                          onTap: () => cartController.setPendingBookingAddress(address),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              border: Border.all(
                                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).hintColor.withValues(alpha: 0.3),
                                width: isSelected ? 1.5 : 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 22),
                                const SizedBox(width: Dimensions.paddingSizeSmall),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(address.addressLabel ?? '', style: robotoMedium),
                                      Text(
                                        address.address ?? '',
                                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (address.landmark != null && address.landmark!.trim().isNotEmpty)
                                        Text(
                                          address.landmark!,
                                          style: robotoRegular.copyWith(
                                            fontSize: Dimensions.fontSizeExtraSmall,
                                            color: Theme.of(context).hintColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                if (isSelected) Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            _BookingNavButtons(
              backLabel: 'back'.tr,
              onBack: () => cartController.setBookingStep(ServiceBookingStep.variations),
              nextLabel: 'continue'.tr,
              nextEnabled: hasSelection,
              onNext: () {
                if (!hasSelection) {
                  customSnackBar('add_address_first'.tr, type: ToasterMessageType.info, aboveOverlays: true);
                  return;
                }
                final address = AddressHelper.ensureContactPerson(cartController.pendingBookingAddress!);
                cartController.setPendingBookingAddress(address);
                if (!AddressHelper.hasValidContactPerson(address)) {
                  customSnackBar(
                    'please_input_contact_person_name_and_phone_number'.tr,
                    type: ToasterMessageType.info,
                    aboveOverlays: true,
                  );
                  return;
                }
                cartController.setBookingStep(ServiceBookingStep.schedule);
              },
            ),
          ],
        );
      });
    });
  }
}

class _ScheduleStep extends StatelessWidget {
  final Service service;
  const _ScheduleStep({required this.service});

  bool _isCustomSelected(ScheduleController scheduleController) {
    return scheduleController.initialSelectedScheduleType == ScheduleType.schedule ||
        (scheduleController.selectedScheduleType == ScheduleType.schedule &&
            scheduleController.initialSelectedScheduleType != ScheduleType.asap);
  }

  bool _canContinue(ScheduleController scheduleController) {
    if (scheduleController.scheduleTime == null) return false;
    if (scheduleController.selectedScheduleType == ScheduleType.asap ||
        scheduleController.initialSelectedScheduleType == ScheduleType.asap) {
      return true;
    }
    final selected = _parseScheduleTime(scheduleController.scheduleTime!);
    return selected != null && BookingDateTimePicker.isValidBookingDateTime(selected);
  }

  DateTime? _parseScheduleTime(String schedule) {
    try {
      return DateConverter.dateTimeStringToDate(schedule);
    } catch (_) {
      return BookingDateTimePicker.parseSelectedSchedule(
        Get.find<ScheduleController>(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ScheduleController>(builder: (scheduleController) {
      final isAsap = scheduleController.selectedScheduleType == ScheduleType.asap &&
          scheduleController.initialSelectedScheduleType == ScheduleType.asap;
      final isCustom = _isCustomSelected(scheduleController);

      String displayTime = 'select_schedule_time'.tr;
      if (isAsap && scheduleController.scheduleTime != null) {
        displayTime = 'ASAP'.tr;
      } else if (isCustom && scheduleController.scheduleTime != null) {
        final parsed = _parseScheduleTime(scheduleController.scheduleTime!);
        displayTime = parsed != null
            ? DateConverter.dateMonthYearTimeTwentyFourFormat(parsed)
            : scheduleController.scheduleTime!;
      }

      return GetBuilder<CartController>(builder: (cartController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepHeader(
              title: 'preferable_time'.tr,
              subtitle: 'choose_asap_or_custom_time'.tr,
            ),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    height: 42,
                    radius: Dimensions.radiusDefault,
                    buttonText: 'ASAP'.tr,
                    backgroundColor: isAsap
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).disabledColor.withValues(alpha: 0.4),
                    onPressed: () {
                      scheduleController.updateScheduleType(scheduleType: ScheduleType.asap);
                      scheduleController.buildSchedule(scheduleType: ScheduleType.asap);
                      if (scheduleController.scheduleTime != null) {
                        cartController.setPendingBookingSchedule(scheduleController.scheduleTime!);
                      }
                    },
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: CustomButton(
                    height: 42,
                    radius: Dimensions.radiusDefault,
                    buttonText: 'custom_date_and_time'.tr,
                    backgroundColor: isCustom
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).disabledColor.withValues(alpha: 0.4),
                    onPressed: () {
                      scheduleController.updateScheduleType(
                        scheduleType: ScheduleType.schedule,
                        shouldUpdate: false,
                      );
                      final min = BookingDateTimePicker.minimumScheduleTime();
                      scheduleController.selectedDate = DateFormat('yyyy-MM-dd').format(min);
                      scheduleController.selectedTime = DateFormat('HH:mm:ss').format(min);
                      scheduleController.scheduleTime = null;
                      scheduleController.update();
                      _openDateTimePicker(context);
                    },
                  ),
                ),
              ],
            ),
            if (isCustom) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              InkWell(
                onTap: () => _openDateTimePicker(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSeven),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                    color: Theme.of(context).hoverColor.withValues(alpha: 0.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(displayTime, style: robotoMedium)),
                      Image.asset(
                        Images.scheduleIcon,
                        width: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (isAsap && scheduleController.scheduleTime != null) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'asap_service_hint'.tr,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
            const SizedBox(height: Dimensions.paddingSizeLarge),
            _BookingNavButtons(
              backLabel: 'back'.tr,
              onBack: () => cartController.setBookingStep(ServiceBookingStep.address),
              nextLabel: 'continue'.tr,
              nextEnabled: _canContinue(scheduleController),
              onNext: () {
                final schedule = scheduleController.scheduleTime;
                if (schedule == null) {
                  customSnackBar('select_your_preferable_booking_time'.tr, type: ToasterMessageType.info, aboveOverlays: true);
                  return;
                }
                if (scheduleController.selectedScheduleType != ScheduleType.asap &&
                    scheduleController.initialSelectedScheduleType != ScheduleType.asap) {
                  final selected = _parseScheduleTime(schedule);
                  if (selected == null) {
                    customSnackBar('select_your_preferable_booking_time'.tr, type: ToasterMessageType.info, aboveOverlays: true);
                    return;
                  }
                  if (!BookingDateTimePicker.isValidBookingDateTime(selected)) {
                    customSnackBar('booking_minimum_two_hours_notice'.tr, type: ToasterMessageType.info, aboveOverlays: true);
                    return;
                  }
                }
                cartController.setPendingBookingSchedule(schedule);
                cartController.loadProvidersForBooking(service.subCategoryId ?? '');
                cartController.setBookingStep(ServiceBookingStep.provider);
              },
            ),
          ],
        );
      });
    });
  }

  void _openDateTimePicker(BuildContext context) {
    final scheduleController = Get.find<ScheduleController>();
    if (scheduleController.scheduleTime == null) {
      final min = BookingDateTimePicker.minimumScheduleTime();
      scheduleController.selectedDate = DateFormat('yyyy-MM-dd').format(min);
      scheduleController.selectedTime = DateFormat('HH:mm:ss').format(min);
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BookingDateTimePicker(),
    );
  }
}

class _ProviderStep extends StatelessWidget {
  final Service service;
  const _ProviderStep({required this.service});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      if (cartController.isLoading) {
        return const Padding(
          padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final providers = cartController.filteredBookingProviders ?? [];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepHeader(
            title: 'available_providers'.tr,
            subtitle: providers.isEmpty
                ? 'no_provider_available_for_slot'.tr
                : '${providers.length} ${providers.length > 1 ? 'providers_available'.tr : 'provider_available'.tr}',
          ),
          GestureDetector(
            onTap: () {
              cartController.setPendingBookingProvider(null);
              cartController.updateProviderSelectedIndex(-1);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(
                  color: cartController.selectedProviderIndex == -1
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).hintColor.withValues(alpha: 0.3),
                  width: cartController.selectedProviderIndex == -1 ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  const UnselectedProductWidget(),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  Expanded(
                    child: Text(
                      '${'let'.tr} ${AppConstants.appName} ${'choose_for_you'.tr}',
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                    ),
                  ),
                  if (cartController.selectedProviderIndex == -1)
                    Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: Get.height * 0.3),
            child: providers.isEmpty
                ? const SizedBox()
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: providers.length,
                    itemBuilder: (context, index) => ProviderCartItemView(
                      providerData: providers[index],
                      index: index,
                    ),
                  ),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          _BookingNavButtons(
            backLabel: 'back'.tr,
            onBack: () => cartController.setBookingStep(ServiceBookingStep.schedule),
            nextLabel: 'continue'.tr,
            nextEnabled: true,
            onNext: () => cartController.setBookingStep(ServiceBookingStep.preview),
          ),
        ],
      );
    });
  }
}

class _PreviewStep extends StatelessWidget {
  final Service service;
  final VoidCallback onComplete;
  const _PreviewStep({required this.service, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      final address = cartController.pendingBookingAddress;
      final schedule = cartController.pendingBookingSchedule;
      final provider = cartController.pendingBookingProvider;
      final items = cartController.initialCartList.where((c) => c.quantity > 0).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepHeader(
            title: 'booking_preview_title'.tr,
            subtitle: 'booking_preview_subtitle'.tr,
          ),
          _PreviewRow(icon: Icons.home_repair_service, label: service.name ?? ''),
          ...items.map((item) => _PreviewRow(
                icon: Icons.check_circle_outline,
                label: '${item.variantKey.replaceAll('-', ' ')} x${item.quantity} — ${PriceConverter.convertPrice(item.price.toDouble())}',
              )),
          _PreviewRow(icon: Icons.location_on, label: address?.address ?? ''),
          _PreviewRow(
            icon: Icons.calendar_today,
            label: schedule != null
                ? DateConverter.dateMonthYearTimeTwentyFourFormat(DateConverter.dateTimeStringToDate(schedule))
                : '',
          ),
          _PreviewRow(
            icon: Icons.person,
            label: provider?.companyName ?? '${'let'.tr} ${AppConstants.appName} ${'choose_for_you'.tr}',
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          _BookingNavButtons(
            backLabel: 'back'.tr,
            onBack: () => cartController.setBookingStep(ServiceBookingStep.provider),
            nextLabel: 'add_to_cart'.tr,
            isLoading: cartController.isLoading,
            nextEnabled: true,
            onNext: () async {
              await cartController.completeBookingAndAddToCart(
                service: service,
                onSuccess: onComplete,
              );
            },
          ),
        ],
      );
    });
  }
}

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PreviewRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: Text(label, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall))),
        ],
      ),
    );
  }
}

class _BookingNavButtons extends StatelessWidget {
  final String backLabel;
  final String nextLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool isLoading;
  final bool nextEnabled;

  const _BookingNavButtons({
    required this.backLabel,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
    this.isLoading = false,
    this.nextEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final backText = backLabel.isNotEmpty
        ? '${backLabel[0].toUpperCase()}${backLabel.substring(1)}'
        : backLabel;

    return Row(
      children: [
        Expanded(
          child: CustomButton(
            onPressed: onBack,
            buttonText: backText,
            backgroundColor: Theme.of(context).disabledColor,
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: CustomButton(
            onPressed: (isLoading || !nextEnabled) ? null : onNext,
            isLoading: isLoading,
            buttonText: nextLabel,
          ),
        ),
      ],
    );
  }
}
