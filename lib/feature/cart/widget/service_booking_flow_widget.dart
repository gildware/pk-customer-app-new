import 'package:demandium/common/widgets/address_selection_bottom_sheet.dart';
import 'package:demandium/feature/cart/model/service_booking_step.dart';
import 'package:demandium/feature/cart/widget/booking_date_time_picker.dart';
import 'package:demandium/helper/address_session_helper.dart';
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

class _AddressStep extends StatefulWidget {
  @override
  State<_AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends State<_AddressStep> {
  bool _loadingAddresses = true;

  @override
  void initState() {
    super.initState();
    _loadAddressesAndAutoSelect();
  }

  Future<void> _loadAddressesAndAutoSelect() async {
    final locationController = Get.find<LocationController>();
    final cartController = Get.find<CartController>();
    if (Get.find<AuthController>().isLoggedIn()) {
      if (locationController.addressList == null) {
        await locationController.getAddressList();
      }
    }
    _loadingAddresses = false;
    cartController.tryAutoSelectSingleBookingAddress();
    if (mounted) setState(() {});
  }

  Future<void> _refreshAddresses() async {
    final locationController = Get.find<LocationController>();
    final cartController = Get.find<CartController>();
    await locationController.getAddressList();
    cartController.tryAutoSelectSingleBookingAddress();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Get.find<AuthController>().isLoggedIn();
    return GetBuilder<CartController>(builder: (cartController) {
      return GetBuilder<LocationController>(builder: (locationController) {
        final hasSelection = cartController.pendingBookingAddress != null;
        final addressList = locationController.addressList ?? [];

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
                  await Get.toNamed(RouteHelper.getAddAddressRoute(false, fromBooking: true));
                  await _refreshAddresses();
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
                    await Get.toNamed(RouteHelper.getAddAddressRoute(false, fromBooking: true));
                    final saved = locationController.getUserAddress();
                    if (saved != null) {
                      final valid = await cartController.selectBookingAddress(saved);
                      if (!valid && mounted) setState(() {});
                    }
                  },
                ),
              ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: Get.height * 0.35),
              child: _loadingAddresses
                  ? const Center(child: CircularProgressIndicator())
                  : !isLoggedIn
                  ? const SizedBox.shrink()
                  : addressList.isEmpty
                  ? Center(child: Text('no_saved_address_fount'.tr, style: robotoRegular))
                  : AddressListContent(
                      locationController: locationController,
                      selectedAddressId: cartController.pendingBookingAddress?.id,
                      onAddressTap: (address) async {
                        await cartController.selectBookingAddress(address);
                      },
                      onAddressDeleted: (address) {
                        if (cartController.pendingBookingAddress?.id == address.id) {
                          cartController.clearPendingBookingAddress();
                        }
                      },
                    ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            _BookingNavButtons(
              backLabel: 'back'.tr,
              onBack: () => cartController.setBookingStep(ServiceBookingStep.variations),
              nextLabel: 'continue'.tr,
              nextEnabled: hasSelection,
              onNext: () async {
                if (!hasSelection) {
                  customSnackBar('add_address_first'.tr, type: ToasterMessageType.info, aboveOverlays: true);
                  return;
                }
                final pending = cartController.pendingBookingAddress!;
                final valid = await AddressSessionHelper.validateAddressForUse(
                  pending,
                  requireSessionZone: true,
                );
                if (!valid) {
                  return;
                }
                final address = AddressHelper.ensureContactPerson(pending);
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

class _ScheduleStep extends StatefulWidget {
  final Service service;
  const _ScheduleStep({required this.service});

  @override
  State<_ScheduleStep> createState() => _ScheduleStepState();
}

class _ScheduleStepState extends State<_ScheduleStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<CompanyAvailabilityConfigWatcher>()) {
        Get.find<CompanyAvailabilityConfigWatcher>().refreshNow();
      } else {
        Get.find<SplashController>().refreshConfigFromServer();
      }
      Get.find<ScheduleController>().initBookingScheduleForFlow();
    });
  }

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
    if (selected == null || !BookingDateTimePicker.isValidBookingDateTime(selected)) {
      return false;
    }
    final resolution = CompanyAvailabilityHelper.resolveCustomSchedule(selected);
    return CompanyAvailabilityHelper.isSelectableBookingTime(resolution.schedule);
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

  String _scheduleStepSubtitle(bool isAsap) {
    if (isAsap) {
      return CompanyAvailabilityHelper.minimumLeadTimeMessage();
    }
    return CompanyAvailabilityHelper.availabilityHoursNotice() ??
        CompanyAvailabilityHelper.minimumLeadTimeMessage();
  }

  String? _asapNoticeUnderBox(ScheduleController scheduleController) {
    if (scheduleController.scheduleTime == null) return null;
    final parsed = _parseScheduleTime(scheduleController.scheduleTime!);
    if (parsed == null) return null;
    return CompanyAvailabilityHelper.asapScheduleNotice(parsed);
  }

  Widget _buildScheduleTimeBox(
    BuildContext context, {
    required String displayTime,
    VoidCallback? onTap,
  }) {
    final box = Container(
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
          if (onTap != null)
            Image.asset(
              Images.scheduleIcon,
              width: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );

    if (onTap == null) return box;
    return InkWell(onTap: onTap, child: box);
  }

  void _selectAsapSchedule(
    ScheduleController scheduleController,
    CartController cartController,
  ) {
    scheduleController.applyAsapScheduleResolution();
    if (scheduleController.scheduleTime != null) {
      cartController.setPendingBookingSchedule(scheduleController.scheduleTime!);
    }
  }

  Widget? _scheduleAdjustmentNotice(BuildContext context, ScheduleController scheduleController) {
    final notice = scheduleController.scheduleAdjustmentNotice;
    if (!scheduleController.scheduleAdjustedForAvailability || notice == null) {
      return null;
    }
    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          notice,
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ScheduleController>(builder: (scheduleController) {
      final isAsap = scheduleController.selectedScheduleType == ScheduleType.asap &&
          scheduleController.initialSelectedScheduleType == ScheduleType.asap;
      final isCustom = _isCustomSelected(scheduleController);

      String displayTime = 'select_schedule_time'.tr;
      if (scheduleController.scheduleTime != null) {
        final parsed = _parseScheduleTime(scheduleController.scheduleTime!);
        if (parsed != null) {
          displayTime = DateConverter.dateMonthYearTimeTwentyFourFormat(parsed);
        } else if (isAsap) {
          displayTime = 'ASAP'.tr;
        } else {
          displayTime = scheduleController.scheduleTime!;
        }
      }

      return GetBuilder<CartController>(builder: (cartController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepHeader(
              title: 'preferable_time'.tr,
              subtitle: _scheduleStepSubtitle(isAsap),
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
                    onPressed: () => _selectAsapSchedule(scheduleController, cartController),
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
                      scheduleController.clearScheduleAdjustmentNotice();
                      scheduleController.updateScheduleType(
                        scheduleType: ScheduleType.schedule,
                        shouldUpdate: false,
                      );
                      final earliest = BookingDateTimePicker.earliestCustomBookableDateTime();
                      scheduleController.selectedDate = DateFormat('yyyy-MM-dd').format(earliest);
                      scheduleController.selectedTime = DateFormat('HH:mm:ss').format(earliest);
                      scheduleController.scheduleTime = null;
                      scheduleController.update();
                      _openDateTimePicker(context, cartController);
                    },
                  ),
                ),
              ],
            ),
            if (isAsap && scheduleController.scheduleTime != null) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              _buildScheduleTimeBox(context, displayTime: displayTime),
              if (_asapNoticeUnderBox(scheduleController) != null) ...[
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  _asapNoticeUnderBox(scheduleController)!,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ],
            if (isCustom) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              _buildScheduleTimeBox(
                context,
                displayTime: displayTime,
                onTap: () => _openDateTimePicker(context, cartController),
              ),
            ],
            if (isCustom && _scheduleAdjustmentNotice(context, scheduleController) != null) ...[
              _scheduleAdjustmentNotice(context, scheduleController)!,
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
                var scheduleToUse = schedule;
                if (scheduleController.selectedScheduleType == ScheduleType.asap ||
                    scheduleController.initialSelectedScheduleType == ScheduleType.asap) {
                  scheduleController.applyAsapScheduleResolution(shouldUpdate: false);
                  scheduleToUse = scheduleController.scheduleTime ?? schedule;
                } else if (scheduleController.selectedScheduleType != ScheduleType.asap &&
                    scheduleController.initialSelectedScheduleType != ScheduleType.asap) {
                  final selected = _parseScheduleTime(schedule);
                  if (selected == null) {
                    customSnackBar('select_your_preferable_booking_time'.tr, type: ToasterMessageType.info, aboveOverlays: true);
                    return;
                  }
                  if (!BookingDateTimePicker.isValidBookingDateTime(selected)) {
                    customSnackBar(CompanyAvailabilityHelper.minimumLeadTimeMessage(), type: ToasterMessageType.info, aboveOverlays: true);
                    return;
                  }
                  final resolution = scheduleController.applyCustomScheduleResolution(
                    selected,
                    shouldUpdate: false,
                  );
                  if (resolution.wasAdjusted) {
                    scheduleController.buildSchedule(
                      scheduleType: ScheduleType.schedule,
                      schedule:
                          '${scheduleController.selectedDate} ${scheduleController.selectedTime}',
                    );
                    scheduleToUse = scheduleController.scheduleTime ?? schedule;
                  }
                }
                cartController.setPendingBookingSchedule(scheduleToUse);
                cartController.loadProvidersForBooking(widget.service.subCategoryId ?? '');
                cartController.setBookingStep(ServiceBookingStep.provider);
              },
            ),
          ],
        );
      });
    });
  }

  Future<void> _openDateTimePicker(BuildContext context, CartController cartController) async {
    final scheduleController = Get.find<ScheduleController>();
    if (scheduleController.scheduleTime == null) {
      final earliest = BookingDateTimePicker.earliestCustomBookableDateTime();
      scheduleController.selectedDate = DateFormat('yyyy-MM-dd').format(earliest);
      scheduleController.selectedTime = DateFormat('HH:mm:ss').format(earliest);
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BookingDateTimePicker(),
    );
    if (scheduleController.scheduleTime != null) {
      cartController.setPendingBookingSchedule(scheduleController.scheduleTime!);
      scheduleController.update();
    }
  }
}

class _ProviderStep extends StatefulWidget {
  final Service service;
  const _ProviderStep({required this.service});

  @override
  State<_ProviderStep> createState() => _ProviderStepState();
}

class _ProviderStepState extends State<_ProviderStep> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _providerSubtitle(CartController cartController, bool isLoadingProviders) {
    if (isLoadingProviders) return 'loading'.tr;
    final count = (cartController.filteredBookingProviders ?? []).length;
    if (count == 0) return 'no_provider_available_for_slot'.tr;
    return '$count ${count > 1 ? 'providers_available'.tr : 'provider_available'.tr}';
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      final isManual = cartController.bookingProviderSelectionMode == BookingProviderSelectionMode.manual;
      final isExpanded = cartController.isBookingProviderSheetExpanded;
      final isLoadingProviders = cartController.isLoadingBookingProviders;
      final providers = cartController.displayedBookingProviders;
      final canContinue = !isManual || cartController.selectedProviderIndex >= 0;
      final primary = Theme.of(context).colorScheme.primary;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (isManual)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'available_providers'.tr,
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                    ),
                  ),
                  Text(
                    _providerSubtitle(cartController, isLoadingProviders),
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            )
          else
            _StepHeader(
              title: 'available_providers'.tr,
              subtitle: _providerSubtitle(cartController, isLoadingProviders),
            ),
          if (isManual)
            Row(
              children: [
                _CompactSegmentButton(
                  label: '${'let'.tr} ${AppConstants.appName} ${'choose_for_you'.tr}',
                  isSelected: !isManual,
                  onTap: () {
                    _searchController.clear();
                    cartController.setBookingProviderSelectionMode(BookingProviderSelectionMode.auto);
                  },
                ),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                _CompactSegmentButton(
                  label: 'choose_yourself'.tr,
                  isSelected: isManual,
                  onTap: () => cartController.setBookingProviderSelectionMode(BookingProviderSelectionMode.manual),
                ),
              ],
            )
          else ...[
            _ProviderChoiceCard(
              isSelected: true,
              label: '${'let'.tr} ${AppConstants.appName} ${'choose_for_you'.tr}',
              onTap: () {
                _searchController.clear();
                cartController.setBookingProviderSelectionMode(BookingProviderSelectionMode.auto);
              },
            ),
            _ProviderChoiceCard(
              isSelected: false,
              label: 'choose_yourself'.tr,
              onTap: () => cartController.setBookingProviderSelectionMode(BookingProviderSelectionMode.manual),
            ),
          ],
          if (isManual) ...[
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        cartController.setBookingProviderSearchQuery(value);
                        setState(() {});
                      },
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        hintText: 'search_providers'.tr,
                        hintStyle: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).hintColor,
                        ),
                        prefixIcon: Icon(Icons.search, color: Theme.of(context).hintColor, size: 18),
                        prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? InkWell(
                                onTap: () {
                                  _searchController.clear();
                                  cartController.setBookingProviderSearchQuery('');
                                  setState(() {});
                                },
                                child: Icon(Icons.close, color: Theme.of(context).hintColor, size: 16),
                              )
                            : null,
                        suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 36),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          borderSide: BorderSide(color: Theme.of(context).hintColor.withValues(alpha: 0.25)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          borderSide: BorderSide(color: Theme.of(context).hintColor.withValues(alpha: 0.25)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          borderSide: BorderSide(color: primary),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                _ProviderSortButton(
                  sortBy: cartController.bookingProviderSortBy,
                  onSelected: cartController.setBookingProviderSortBy,
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            if (isExpanded)
              Expanded(
                child: _buildProviderList(context, cartController, isLoadingProviders, providers),
              )
            else
              _buildProviderList(context, cartController, isLoadingProviders, providers),
          ],
          SizedBox(height: isManual ? Dimensions.paddingSizeSmall : Dimensions.paddingSizeLarge),
          _BookingNavButtons(
            backLabel: 'back'.tr,
            onBack: () {
              if (isManual) {
                _searchController.clear();
                cartController.setBookingProviderSelectionMode(BookingProviderSelectionMode.auto);
              }
              cartController.setBookingStep(ServiceBookingStep.schedule);
            },
            nextLabel: 'continue'.tr,
            nextEnabled: canContinue,
            compact: isManual,
            onNext: () => cartController.setBookingStep(ServiceBookingStep.preview),
          ),
        ],
      );
    });
  }

  Widget _buildProviderList(
    BuildContext context,
    CartController cartController,
    bool isLoadingProviders,
    List<ProviderData> providers,
  ) {
    if (isLoadingProviders) {
      return const Center(child: SizedBox(height: 28, width: 28, child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (providers.isEmpty) {
      return Center(
        child: Text(
          'no_provider_found'.tr,
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).hintColor,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: !cartController.isBookingProviderSheetExpanded,
      physics: cartController.isBookingProviderSheetExpanded
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemCount: providers.length,
      itemBuilder: (context, index) => ProviderCartItemView(
        providerData: providers[index],
        index: index,
        compact: true,
      ),
    );
  }
}

class _ProviderChoiceCard extends StatelessWidget {
  final bool isSelected;
  final String label;
  final VoidCallback onTap;

  const _ProviderChoiceCard({
    required this.isSelected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).hintColor.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            const UnselectedProductWidget(),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Text(
                label,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _CompactSegmentButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactSegmentButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? primary.withValues(alpha: 0.1) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            border: Border.all(
              color: isSelected ? primary : Theme.of(context).hintColor.withValues(alpha: 0.25),
              width: isSelected ? 1 : 0.5,
            ),
          ),
          child: Text(
            label,
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall,
              color: isSelected ? primary : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _ProviderSortButton extends StatelessWidget {
  final BookingProviderSortBy sortBy;
  final ValueChanged<BookingProviderSortBy> onSelected;

  const _ProviderSortButton({
    required this.sortBy,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 36,
      width: 36,
      child: PopupMenuButton<BookingProviderSortBy>(
        padding: EdgeInsets.zero,
        tooltip: 'sort_by'.tr,
        icon: Icon(Icons.sort, size: 20, color: primary),
        onSelected: onSelected,
        itemBuilder: (context) => [
          _sortMenuItem(context, BookingProviderSortBy.rating, 'rating'.tr),
          _sortMenuItem(context, BookingProviderSortBy.distance, 'distance'.tr),
        ],
      ),
    );
  }

  PopupMenuItem<BookingProviderSortBy> _sortMenuItem(
    BuildContext context,
    BookingProviderSortBy value,
    String label,
  ) {
    final isSelected = sortBy == value;
    return PopupMenuItem(
      value: value,
      height: 40,
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: isSelected ? Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.primary) : null,
          ),
          Text(
            label,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewStep extends StatelessWidget {
  final Service service;
  final VoidCallback onComplete;
  const _PreviewStep({required this.service, required this.onComplete});

  String _formatPreviewSchedule(String schedule) {
    final parsed = DateConverter.tryParseScheduleDateTime(schedule);
    if (parsed == null) return schedule;

    final scheduleController = Get.find<ScheduleController>();
    final isAsap = scheduleController.selectedScheduleType == ScheduleType.asap ||
        scheduleController.initialSelectedScheduleType == ScheduleType.asap;

    if (isAsap) {
      return CartBookingDisplayHelper.formatAsapWithDateTime(parsed);
    }
    return DateConverter.dateMonthYearTimeTwentyFourFormat(parsed);
  }

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
                ? _formatPreviewSchedule(schedule)
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
  final bool compact;

  const _BookingNavButtons({
    required this.backLabel,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
    this.isLoading = false,
    this.nextEnabled = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final backText = backLabel.isNotEmpty
        ? '${backLabel[0].toUpperCase()}${backLabel.substring(1)}'
        : backLabel;
    final buttonHeight = compact ? 40.0 : null;

    return Row(
      children: [
        Expanded(
          child: CustomButton(
            onPressed: onBack,
            buttonText: backText,
            backgroundColor: Theme.of(context).disabledColor,
            height: buttonHeight,
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: CustomButton(
            onPressed: (isLoading || !nextEnabled) ? null : onNext,
            isLoading: isLoading,
            buttonText: nextLabel,
            height: buttonHeight,
          ),
        ),
      ],
    );
  }
}
