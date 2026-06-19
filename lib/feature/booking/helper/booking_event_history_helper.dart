import 'package:demandium/common/models/user_model.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

enum BookingEventViewer { customer, provider }

enum BookingEventType { status, schedule, provider, service, payment, other }

class BookingTimelineEvent {
  final String title;
  final String description;
  final String? timestamp;
  final BookingEventType eventType;
  final int tieRank;

  const BookingTimelineEvent({
    required this.title,
    required this.description,
    this.timestamp,
    required this.eventType,
    this.tieRank = 0,
  });
}

class _BookingEventActorResolver {
  final BookingEventViewer viewer;
  final BookingDetailsContent booking;
  final String? currentUserId;

  const _BookingEventActorResolver({
    required this.viewer,
    required this.booking,
    this.currentUserId,
  });

  String resolveUser(User? user, {String? fallbackName}) {
    if (user != null && _isAdmin(user.userType)) return _panunKaergar;

    final userId = user?.id?.toString();
    if (userId != null &&
        currentUserId != null &&
        userId == currentUserId &&
        viewer == BookingEventViewer.customer) {
      return 'you'.tr;
    }

    if (user != null) {
      final type = user.userType?.toLowerCase() ?? '';
      if (type == 'provider-admin' || type.contains('provider')) {
        return BookingEventHistoryHelper.formatServiceProviderName(_providerDisplayName());
      }
      if (type == 'customer' || type.contains('customer')) {
        return _customerDisplayName(user);
      }
      final name = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
      if (name.isNotEmpty) return name;
    }

    final fallback = fallbackName?.trim();
    if (fallback != null && fallback.isNotEmpty) {
      if (_looksLikeAdminName(fallback)) return _panunKaergar;
      return fallback;
    }
    return '';
  }

  String resolveChangeLog(BookingChangeLog log) =>
      resolveUser(log.changedByUser, fallbackName: log.actorDisplayName);

  String resolvePaymentReceiver(String? label) {
    final normalized = label?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return '';
    if (normalized == 'company' || normalized.contains('admin')) return _panunKaergar;
    if (normalized == 'provider') {
      final name = viewer == BookingEventViewer.provider
          ? 'you'.tr
          : BookingEventHistoryHelper.formatServiceProviderName(_providerDisplayName());
      return name;
    }
    return label!.trim();
  }

  String _providerDisplayName() {
    final company = booking.provider?.companyName?.trim();
    if (company != null && company.isNotEmpty) return company;
    return 'provider'.tr;
  }

  String _customerDisplayName(User? user) {
    if (user != null) {
      final name = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
      if (name.isNotEmpty) return name;
    }
    final customer = booking.customer;
    final name = '${customer?.firstName ?? ''} ${customer?.lastName ?? ''}'.trim();
    if (name.isNotEmpty) return name;
    return 'customer'.tr;
  }

  bool _isAdmin(String? userType) {
    final type = userType?.toLowerCase() ?? '';
    return type == 'super-admin' ||
        type == 'admin-employee' ||
        type == 'admin' ||
        type == 'staff';
  }

  bool _looksLikeAdminName(String name) {
    final lower = name.toLowerCase();
    return lower.contains('admin') || lower == 'system';
  }

  String resolvePlacedActor() {
    if (viewer == BookingEventViewer.customer && currentUserId != null) {
      return 'you'.tr;
    }
    return _customerDisplayName(null);
  }

  String get _panunKaergar => 'panun_kaergar'.tr;
}

class BookingEventHistoryHelper {
  static String formatServiceProviderName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == 'you'.tr) return trimmed;
    final suffix = '(${ 'service_provider_title'.tr})';
    if (trimmed.endsWith(suffix)) return trimmed;
    return '$trimmed$suffix';
  }

  static List<BookingTimelineEvent> buildEvents(BookingDetailsContent booking) {
    final resolver = _BookingEventActorResolver(
      viewer: BookingEventViewer.customer,
      booking: booking,
      currentUserId: _currentUserId(),
    );
    return _build(booking, resolver);
  }

  static String? _currentUserId() {
    try {
      if (Get.find<AuthController>().isLoggedIn()) {
        return Get.find<UserController>().userInfoModel?.id?.toString();
      }
    } catch (_) {}
    return null;
  }

  static List<BookingTimelineEvent> _build(
    BookingDetailsContent booking,
    _BookingEventActorResolver resolver,
  ) {
    final events = <BookingTimelineEvent>[];
    var tieRank = 0;
    int nextRank() => tieRank++;

    final statusHistories = booking.statusHistories ?? <StatusHistories>[];
    final scheduleHistories = booking.scheduleHistories ?? <ScheduleHistories>[];
    final installments = booking.paymentLedger?.installments ?? <BookingPaymentLedgerEntry>[];
    final hasStatusHistory = statusHistories.isNotEmpty;
    final hasScheduleHistory = scheduleHistories.length > 1;
    final hasPaymentLedger = installments.isNotEmpty;

    final changeLogs = [...booking.changeLogs ?? <BookingChangeLog>[]];
    changeLogs.sort(_compareChangeLogsChronologically);

    for (final log in changeLogs) {
      final key = log.propertyKey ?? '';
      if (_isInternalChangeLog(log)) continue;
      if (hasStatusHistory && _isStatusChangeLog(key)) continue;
      if (hasStatusHistory && key == 'booking.reopened') continue;
      if (hasScheduleHistory && _isScheduleChangeLog(key)) continue;
      if (hasPaymentLedger && _isPaymentChangeLog(key)) continue;
      if (!hasPaymentLedger && _isPaymentChangeLog(key) && _hasPartialPaymentNear(booking, log.createdAt)) {
        continue;
      }
      final event = _fromChangeLog(log, resolver, booking);
      if (event != null) events.add(_withTieRank(event, nextRank()));
    }

    if ((booking.changeLogs ?? []).where((l) => _isServiceChangeLog(l.propertyKey ?? '')).isEmpty) {
      for (final edit in booking.repeatEditHistory ?? <RepeatHistory>[]) {
        for (final log in edit.repeatHistoryLogs ?? <RepeatHistoryLog>[]) {
          final serviceName = log.serviceName?.trim();
          if (serviceName == null || serviceName.isEmpty) continue;
          events.add(_withTieRank(
            _serviceEvent(
              title: 'service_updated_title'.tr,
              action: 'updated'.tr,
              detail: '$serviceName ×${log.quantity ?? 1}',
              actor: '',
              timestamp: edit.createdAt ?? edit.updatedAt,
            ),
            nextRank(),
          ));
        }
      }
    }

    if (booking.createdAt != null && !hasStatusHistory) {
      events.add(_withTieRank(
        _statusEvent(
          statusLabel: 'pending'.tr,
          rawStatusKey: 'pending',
          action: 'booking_placed'.tr,
          actor: resolver.resolvePlacedActor(),
          timestamp: booking.createdAt,
        ),
        nextRank(),
      ));
    }

    for (var i = 1; i < scheduleHistories.length; i++) {
      final history = scheduleHistories[i];
      events.add(_withTieRank(
        _scheduleEvent(
          schedule: history.schedule,
          actor: resolver.resolveUser(history.user),
          timestamp: history.createdAt ?? history.updatedAt,
        ),
        nextRank(),
      ));
    }

    for (final installment in installments) {
      events.add(_withTieRank(
        _paymentEvent(
          resolver: resolver,
          amount: installment.amount != null ? PriceConverter.convertPrice(installment.amount!) : null,
          receiver: resolver.resolvePaymentReceiver(installment.receivedByLabel),
          timestamp: installment.date,
        ),
        nextRank(),
      ));
    }

    if (!hasPaymentLedger) {
      for (final payment in booking.partialPayments ?? <PartialPayment>[]) {
        events.add(_withTieRank(
          _paymentEvent(
            resolver: resolver,
            amount: PriceConverter.convertPrice(payment.paidAmount ?? 0),
            receiver: resolver.resolvePaymentReceiver(payment.receivedByLabel),
            timestamp: payment.createdAt ?? payment.updatedAt,
          ),
          nextRank(),
        ));
      }
    }

    for (final refund in booking.paymentLedger?.refunds ?? <BookingRefundLedgerEntry>[]) {
      final amount = refund.amount != null ? PriceConverter.convertPrice(refund.amount!) : null;
      if (amount == null) continue;
      events.add(_withTieRank(
        BookingTimelineEvent(
          title: 'payments_title'.tr,
          description: '${'refund_of'.tr} $amount',
          timestamp: refund.date,
          eventType: BookingEventType.payment,
        ),
        nextRank(),
      ));
    }

    for (final history in statusHistories) {
      final rawStatus = history.bookingStatus ?? '';
      if (rawStatus.trim().isEmpty || _isMeaninglessAuditText(rawStatus)) continue;
      if (history.isReopenStatusChange) {
        events.add(_withTieRank(
          _reopenStatusEvent(
            rawStatusKey: rawStatus,
            actor: resolver.resolveUser(history.user),
            timestamp: history.createdAt ?? history.updatedAt,
            reasonName: history.holdReopenReasonName,
          ),
          nextRank(),
        ));
      } else {
        events.add(_withTieRank(
          _statusEvent(
            statusLabel: rawStatus.tr,
            rawStatusKey: rawStatus,
            actor: resolver.resolveUser(history.user),
            timestamp: history.createdAt ?? history.updatedAt,
          ),
          nextRank(),
        ));
      }
    }

    return _dedupeAndSort(events.where((event) => !_isMeaninglessEvent(event)).toList());
  }

  static BookingTimelineEvent _withTieRank(BookingTimelineEvent event, int rank) {
    return BookingTimelineEvent(
      title: event.title,
      description: event.description,
      timestamp: event.timestamp,
      eventType: event.eventType,
      tieRank: rank,
    );
  }

  static int _compareChangeLogsChronologically(BookingChangeLog a, BookingChangeLog b) {
    final aTime = DateTime.tryParse(a.createdAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = DateTime.tryParse(b.createdAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    final timeCompare = aTime.compareTo(bTime);
    if (timeCompare != 0) return timeCompare;
    return (a.id ?? 0).compareTo(b.id ?? 0);
  }

  static bool _isMeaninglessEvent(BookingTimelineEvent event) {
    final description = event.description.trim();
    if (description.isEmpty) return true;

    final updatedMarker = description.toLowerCase().indexOf(' ${'updated'.tr.toLowerCase()}');
    final byMarker = description.toLowerCase().indexOf(' ${'by'.tr.toLowerCase()} ');
    final cut = [
      if (updatedMarker > 0) updatedMarker,
      if (byMarker > 0) byMarker,
      description.length,
    ].reduce((a, b) => a < b ? a : b);
    final detailPart = description.substring(0, cut).trim();
    if (detailPart.isNotEmpty && _isMeaninglessAuditText(detailPart)) return true;

    return _isMeaninglessAuditText(description);
  }

  static BookingTimelineEvent _reopenStatusEvent({
    String? rawStatusKey,
    required String actor,
    String? timestamp,
    String? reasonName,
    String? detail,
  }) {
    final key = (rawStatusKey ?? '').toLowerCase().trim().replaceAll(' ', '_');
    final reopenedLabel = key.isNotEmpty && key != 'completed'
        ? ('reopened_and_$key'.tr)
        : 'booking_reopened'.tr;
    final reasonPart = (reasonName != null && reasonName.trim().isNotEmpty)
        ? ' — ${reasonName.trim()}'
        : '';
    final detailText = (detail != null && !_isGarbageDetail(detail) && !_looksLikeUuid(detail))
        ? detail.trim()
        : reopenedLabel;
    final date = _formatDate(timestamp);
    final byPart = actor.isNotEmpty ? ' ${'by'.tr} $actor' : '';
    return BookingTimelineEvent(
      title: 'history_booking_reopened'.tr,
      description: '$detailText$reasonPart$byPart${date.isNotEmpty ? ' ${'on'.tr} $date' : ''}',
      timestamp: timestamp,
      eventType: BookingEventType.status,
    );
  }

  static BookingTimelineEvent _statusEvent({
    required String statusLabel,
    String? rawStatusKey,
    String? action,
    required String actor,
    String? timestamp,
  }) {
    final date = _formatDate(timestamp);
    final byPart = actor.isNotEmpty ? ' ${'by'.tr} $actor' : '';
    final description = action != null
        ? '$action$byPart${date.isNotEmpty ? ' ${'on'.tr} $date' : ''}'
        : '${'changed_to'.tr} $statusLabel$byPart${date.isNotEmpty ? ' ${'on'.tr} $date' : ''}';

    return BookingTimelineEvent(
      title: _statusEventTitle(
        rawStatusKey: rawStatusKey,
        action: action,
        statusLabel: statusLabel,
      ),
      description: description,
      timestamp: timestamp,
      eventType: BookingEventType.status,
    );
  }

  static String _statusEventTitle({
    String? rawStatusKey,
    String? action,
    String? statusLabel,
  }) {
    if (action == 'booking_placed'.tr) {
      return 'booking_placed'.tr;
    }
    final key = (rawStatusKey ?? '').toLowerCase().trim().replaceAll(' ', '_');
    final label = statusLabel ?? _translateToken(key) ?? key.replaceAll('_', ' ');
    if (key == 'accepted') {
      return 'history_status_accepted'.tr;
    }
    return '${'history_status_changed_to'.tr} $label';
  }

  static BookingTimelineEvent _scheduleEvent({
    String? schedule,
    required String actor,
    String? timestamp,
  }) {
    final scheduleLabel = schedule != null && schedule.isNotEmpty
        ? _formatScheduleValue(schedule)
        : 'schedule'.tr;
    final date = _formatDate(timestamp);
    final byPart = actor.isNotEmpty ? ' ${'by'.tr} $actor' : '';
    return BookingTimelineEvent(
      title: 'booking_schedule_title'.tr,
      description: '${'rescheduled_to'.tr} $scheduleLabel$byPart${date.isNotEmpty ? ' ${'on'.tr} $date' : ''}',
      timestamp: timestamp,
      eventType: BookingEventType.schedule,
    );
  }

  static BookingTimelineEvent _providerEvent({
    required String providerName,
    required String actor,
    String? timestamp,
  }) {
    final date = _formatDate(timestamp);
    final byPart = actor.isNotEmpty ? ' ${'by'.tr} $actor' : '';
    final formattedName = formatServiceProviderName(providerName);
    return BookingTimelineEvent(
      title: 'service_provider_title'.tr,
      description: '${'assigned_to'.tr} $formattedName$byPart${date.isNotEmpty ? ' ${'on'.tr} $date' : ''}',
      timestamp: timestamp,
      eventType: BookingEventType.provider,
    );
  }

  static BookingTimelineEvent _serviceEvent({
    required String title,
    required String action,
    required String detail,
    required String actor,
    String? timestamp,
  }) {
    final date = _formatDate(timestamp);
    final byPart = actor.isNotEmpty ? ' ${'by'.tr} $actor' : '';
    return BookingTimelineEvent(
      title: title,
      description: '$detail $action$byPart${date.isNotEmpty ? ' ${'on'.tr} $date' : ''}',
      timestamp: timestamp,
      eventType: BookingEventType.service,
    );
  }

  static BookingTimelineEvent _paymentEvent({
    required _BookingEventActorResolver resolver,
    String? amount,
    required String receiver,
    String? timestamp,
  }) {
    final amountLabel = amount ?? 'payment'.tr;
    final date = _formatDate(timestamp);
    final description = receiver.isNotEmpty && date.isNotEmpty
        ? '$amountLabel ${'payment_received_by'.tr} $receiver ${'on'.tr} $date'
        : receiver.isNotEmpty
            ? '$amountLabel ${'payment_received_by'.tr} $receiver'
            : date.isNotEmpty
                ? '$amountLabel ${'payment_received'.tr} ${'on'.tr} $date'
                : '$amountLabel ${'payment_received'.tr}';

    return BookingTimelineEvent(
      title: 'payment_received_title'.tr,
      description: description,
      timestamp: timestamp,
      eventType: BookingEventType.payment,
    );
  }

  static BookingTimelineEvent? _fromChangeLog(
    BookingChangeLog log,
    _BookingEventActorResolver resolver,
    BookingDetailsContent booking,
  ) {
    final key = log.propertyKey ?? '';
    final actor = resolver.resolveChangeLog(log);
    final timestamp = log.createdAt;
    final detail = _resolveChangeLogDetail(log);

    if (key == 'booking.created') {
      return _statusEvent(
        statusLabel: 'pending'.tr,
        rawStatusKey: 'pending',
        action: 'booking_placed'.tr,
        actor: actor,
        timestamp: timestamp,
      );
    }

    if (key == 'booking.reopened') {
      final rawStatus = _extractStatusFromLog(log) ?? _extractStatusRaw(detail);
      return _reopenStatusEvent(
        rawStatusKey: rawStatus,
        actor: actor,
        timestamp: timestamp,
        detail: detail,
      );
    }

    if (_isStatusChangeLog(key)) {
      final rawStatus = _extractStatusFromLog(log) ?? _extractStatusRaw(detail);
      final status = _translateToken(rawStatus) ?? _translateToken(_extractStatus(detail));
      if (status == null || _isGarbageDetail(status)) return null;
      return _statusEvent(
        statusLabel: status,
        rawStatusKey: rawStatus,
        actor: actor,
        timestamp: timestamp,
      );
    }

    if (_isScheduleChangeLog(key)) {
      if (detail == null) return null;
      return _scheduleEvent(
        schedule: detail,
        actor: actor,
        timestamp: timestamp,
      );
    }

    if (_isPaymentChangeLog(key)) {
      return _paymentEvent(
        resolver: resolver,
        amount: _extractAmount(detail),
        receiver: actor,
        timestamp: timestamp,
      );
    }

    if (key.startsWith('booking.updated.assignment')) {
      return _providerEvent(
        providerName: _extractProvider(detail) ?? resolver.resolveUser(null),
        actor: actor,
        timestamp: timestamp,
      );
    }

    if (key.startsWith('booking_detail.created') || key.startsWith('booking_repeat_detail.created') || key.startsWith('booking_extra_service.created')) {
      return _serviceEvent(
        title: 'new_service_added_title'.tr,
        action: 'added'.tr,
        detail: detail ?? 'service'.tr,
        actor: actor,
        timestamp: timestamp,
      );
    }

    if (key.startsWith('booking_detail.deleted') || key.startsWith('booking_repeat_detail.deleted') || key.startsWith('booking_extra_service.deleted')) {
      return _serviceEvent(
        title: 'service_removed_title'.tr,
        action: 'removed'.tr,
        detail: detail ?? 'service'.tr,
        actor: actor,
        timestamp: timestamp,
      );
    }

    if (key.startsWith('booking_detail.updated') ||
        key.startsWith('booking_repeat_detail.updated') ||
        key.startsWith('booking_extra_service.updated') ||
        key.startsWith('booking.updated.service')) {
      final serviceDetail = _resolveServiceUpdateDetail(log, booking);
      return _serviceEvent(
        title: 'service_updated_title'.tr,
        action: 'updated'.tr,
        detail: serviceDetail ?? 'service'.tr,
        actor: actor,
        timestamp: timestamp,
      );
    }

    if (detail == null || _isGarbageDetail(detail)) return null;

    return BookingTimelineEvent(
      title: 'booking_status_title'.tr,
      description: '$detail ${'updated'.tr}${actor.isNotEmpty ? ' ${'by'.tr} $actor' : ''}',
      timestamp: timestamp,
      eventType: _eventTypeFromKey(key, log.eventType),
    );
  }

  static String _formatScheduleValue(String schedule) {
    if (DateTime.tryParse(schedule) != null) {
      return DateConverter.scheduleStringToDisplay(schedule);
    }
    return schedule;
  }

  static String _formatDate(String? timestamp) {
    if (timestamp == null || timestamp.trim().isEmpty) return '';
    try {
      return DateConverter.dateMonthYearTimeTwentyFourFormat(
        DateConverter.isoUtcStringToLocalDate(timestamp),
      );
    } catch (_) {
      final parsed = DateTime.tryParse(timestamp);
      if (parsed != null) return DateConverter.dateMonthYearTimeTwentyFourFormat(parsed);
    }
    return timestamp;
  }

  static String? _changeLogDetail(BookingChangeLog log) {
    final key = log.propertyKey ?? '';
    final old = _meaningfulValue(log.oldValue);
    final newVal = _meaningfulValue(log.newValue);
    if (key.endsWith('.deleted') || key == '_deleted') return old;
    if (key.endsWith('.created') || key == 'booking.created') return newVal;
    return newVal ?? old;
  }

  static String? _resolveServiceUpdateDetail(BookingChangeLog log, BookingDetailsContent booking) {
    final eventDesc = log.eventDescription?.trim();
    if (eventDesc != null && eventDesc.isNotEmpty && !_isGarbageDetail(eventDesc)) {
      return eventDesc;
    }

    final fromParsed = _resolveChangeLogDetail(log);
    if (fromParsed != null && !_isGarbageDetail(fromParsed)) return fromParsed;

    final fromLabel = _serviceNameFromPropertyLabel(log.propertyLabel);
    if (fromLabel != null) return fromLabel;

    final ctx = log.context?.trim();
    if (ctx != null && ctx.isNotEmpty) {
      for (final other in booking.changeLogs ?? <BookingChangeLog>[]) {
        if (other.context != ctx) continue;
        final otherKey = other.propertyKey ?? '';
        if (!otherKey.endsWith('.created') && !otherKey.endsWith('.deleted')) continue;
        final name = _serviceNameFromLogValue(other.newValue ?? other.oldValue ?? other.eventDescription);
        if (name != null) return name;
      }

      if (ctx.startsWith('booking_detail:')) {
        final detailId = ctx.substring('booking_detail:'.length);
        for (final item in booking.bookingDetails ?? <ItemService>[]) {
          if (item.id == detailId) return _formatServiceItemLabel(item);
        }
      }
      if (ctx.startsWith('booking_repeat_detail:')) {
        final detailId = ctx.substring('booking_repeat_detail:'.length);
        for (final item in booking.bookingDetails ?? <ItemService>[]) {
          if (item.id == detailId) return _formatServiceItemLabel(item);
        }
        for (final item in booking.subBooking?.bookingDetails ?? <ItemService>[]) {
          if (item.id == detailId) return _formatServiceItemLabel(item);
        }
      }
      if (ctx.startsWith('booking_extra_service:')) {
        final extraId = ctx.substring('booking_extra_service:'.length);
        for (final line in booking.extraServiceLines ?? <BookingExtraServiceLine>[]) {
          if (line.id == extraId) {
            final qty = line.quantity ?? 1;
            final name = line.name?.trim();
            if (name != null && name.isNotEmpty) return '$name ×$qty';
          }
        }
      }
    }

    return _serviceNameFromLogValue(log.newValue ?? log.oldValue);
  }

  static String? _serviceNameFromPropertyLabel(String? label) {
    if (label == null) return null;
    final trimmed = label.trim();
    if (trimmed.isEmpty) return null;
    final withoutUpdated = trimmed.split('—').first.split(' - ').first.trim();
    final name = _extractServiceName(withoutUpdated) ?? withoutUpdated;
    if (name.isEmpty || _isGarbageDetail(name)) return null;
    if (name.toLowerCase().startsWith('service line')) return null;
    return name;
  }

  static String? _serviceNameFromLogValue(String? raw) {
    if (raw == null) return null;
    final fromPattern = _extractServiceName(raw);
    if (fromPattern != null) return fromPattern;
    final cleaned = _cleanRawDetail(raw, propertyKey: '.created');
    if (cleaned != null && !_isGarbageDetail(cleaned)) return cleaned;
    return null;
  }

  static String _formatServiceItemLabel(ItemService item) {
    final name = item.service?.name ?? item.serviceName ?? 'service'.tr;
    final qty = item.quantity ?? 1;
    return '$name ×$qty';
  }

  static String? _resolveChangeLogDetail(BookingChangeLog log) {
    for (final raw in [log.eventDescription, log.newValue, log.oldValue]) {
      final cleaned = _cleanRawDetail(raw, propertyKey: log.propertyKey ?? '');
      if (cleaned != null && !_isGarbageDetail(cleaned)) return cleaned;
    }
    final fallback = _changeLogDetail(log);
    final cleaned = _cleanRawDetail(fallback, propertyKey: log.propertyKey ?? '');
    if (cleaned != null && !_isGarbageDetail(cleaned)) return cleaned;
    return null;
  }

  static String? _cleanRawDetail(String? raw, {required String propertyKey}) {
    if (raw == null) return null;
    final text = raw.trim();
    if (text.isEmpty || text == '—') return null;

    final serviceName = _extractServiceName(text);
    if (serviceName != null) return serviceName;

    if (text.contains(':')) {
      final parts = <String>[];
      for (final segment in text.split(';')) {
        final trimmed = segment.trim();
        final match = RegExp(r'^([^:]+):\s*(.+)$').firstMatch(trimmed);
        if (match == null) continue;
        final fieldRaw = match.group(1)!.trim();
        if (!RegExp(r'[a-zA-Z]').hasMatch(fieldRaw)) continue;
        final field = fieldRaw.toLowerCase().replaceAll(' ', '_');
        final value = match.group(2)!.trim();
        if (_isGarbageDetail(value)) continue;
        if (field.contains('evidence') || field.contains('json')) continue;
        if (_isInternalField(field)) continue;

        if (field.contains('status')) {
          final translated = _translateToken(value.replaceAll(' ', '_'));
          if (translated == null || _isGarbageDetail(translated)) continue;
          return translated;
        }
        if (field.contains('provider') || field.contains('serviceman')) {
          return value;
        }
        if (field.contains('schedule')) {
          return value;
        }
        if (!RegExp(r'^[\d.]+$').hasMatch(value)) {
          parts.add(value);
        }
      }
      if (parts.isNotEmpty) return parts.join(', ');
      return null;
    }

    if (_isGarbageDetail(text)) return null;
    return _translateEmbeddedTokens(text);
  }

  static bool _isInternalField(String field) {
    return field.contains('tax') ||
        field.contains('cost') ||
        field.contains('amount') ||
        field.contains('discount') ||
        field.contains('fee') ||
        field.contains('charge') ||
        field == 'quantity' ||
        field == 'is_paid' ||
        field == 'service_id';
  }

  static bool _isGarbageDetail(String text) {
    final t = text.trim();
    if (t.isEmpty) return true;
    if (_isMeaninglessAuditText(t)) return true;
    if (_looksLikeUuid(t)) return true;
    if (RegExp(r'^json\s*\(\d+\)$', caseSensitive: false).hasMatch(t)) return true;
    if (RegExp(r'^[\d.,;\s]+$').hasMatch(t)) return true;
    if (RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$').hasMatch(t)) return true;
    if (RegExp(r'^\d{4}-\d{2}-\d{2}\s+\d{1,2}:\d{2}').hasMatch(t)) return true;
    final segments = t.split(RegExp(r'[;,]')).map((e) => e.trim()).where((e) => e.isNotEmpty);
    if (segments.isNotEmpty && segments.every((s) => RegExp(r'^[\d.]+$').hasMatch(s))) return true;
    return false;
  }

  static String? _extractServiceName(String text) {
    final match = RegExp(r'^(.+?)\s*[×x]\s*\d+\s*$', caseSensitive: false).firstMatch(text.trim());
    if (match == null) return null;
    final name = match.group(1)!.trim();
    if (name.isEmpty || _isGarbageDetail(name)) return null;
    return name;
  }

  static String? _extractStatusFromLog(BookingChangeLog log) {
    for (final raw in [log.newValue, log.oldValue, log.eventDescription]) {
      if (raw == null) continue;
      final statusMatch = RegExp(r'booking[_\s]?status:\s*([a-z_]+)', caseSensitive: false).firstMatch(raw);
      if (statusMatch != null) return statusMatch.group(1);
    }
    return null;
  }

  static String _translateEmbeddedTokens(String text) {
    var result = text.replaceAll('_', ' ');
    for (final token in const [
      'pending', 'accepted', 'ongoing', 'completed', 'canceled', 'on_hold', 'paid', 'unpaid',
    ]) {
      result = result.replaceAll(RegExp('\\b$token\\b', caseSensitive: false), token.tr);
    }
    return result;
  }

  static String? _translateToken(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim().toLowerCase().replaceAll(' ', '_').tr;
  }

  static String? _extractStatus(String? detail) {
    if (detail == null) return null;
    final match = RegExp(r'\b(pending|accepted|ongoing|completed|canceled|on_hold|paid|unpaid)\b', caseSensitive: false)
        .firstMatch(detail);
    return match?.group(1);
  }

  static String? _extractStatusRaw(String? detail) {
    if (detail == null) return null;
    final match = RegExp(r'\b(pending|accepted|ongoing|completed|canceled|on_hold|paid|unpaid)\b', caseSensitive: false)
        .firstMatch(detail);
    return match?.group(1)?.toLowerCase();
  }

  static String? _extractProvider(String? detail) {
    if (detail == null) return null;
    final parts = detail.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty);
    return parts.isNotEmpty ? parts.last : detail;
  }

  static String? _extractAmount(String? detail) {
    if (detail == null) return null;
    final match = RegExp(r'([₹$€£]\s?[\d,]+(?:\.\d+)?)').firstMatch(detail);
    return match?.group(1);
  }

  static String? _meaningfulValue(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '—') return null;
    return trimmed;
  }

  static bool _isStatusChangeLog(String key) =>
      key.startsWith('booking.updated.status') || (key.startsWith('repeat.') && key.contains('status'));

  static bool _isInternalChangeLog(BookingChangeLog log) {
    final key = log.propertyKey ?? '';
    if (!_changeLogHasMeaningfulContent(log)) return true;
    if (key != 'booking.updated.other') return false;
    for (final raw in [log.newValue, log.oldValue, log.eventDescription]) {
      if (raw != null && _looksLikeUuid(raw.trim())) return true;
    }
    final combined = '${log.newValue ?? ''} ${log.oldValue ?? ''}'.toLowerCase();
    return combined.contains('reopened_by') ||
        combined.contains('last_reopen_event_at') ||
        combined.contains('reopen_resolved');
  }

  static bool _changeLogHasMeaningfulContent(BookingChangeLog log) {
    for (final raw in [log.eventDescription, log.newValue, log.oldValue]) {
      if (_auditTextHasMeaningfulContent(raw)) return true;
    }
    return false;
  }

  static bool _auditTextHasMeaningfulContent(String? text) {
    if (text == null) return false;
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isMeaninglessAuditText(trimmed)) return false;

    if (trimmed.contains(':')) {
      for (final segment in trimmed.split(';')) {
        final match = RegExp(r'^([^:]+):\s*(.+)$').firstMatch(segment.trim());
        final value = match?.group(2)?.trim() ?? segment.trim();
        if (value.isNotEmpty && !_isMeaninglessAuditText(value) && !_isGarbageDetail(value)) {
          return true;
        }
      }
      return false;
    }

    return !_isGarbageDetail(trimmed);
  }

  static bool _looksLikeUuid(String text) {
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(text.trim());
  }

  static bool _isMeaninglessAuditText(String text) {
    final stripped = text.replaceAll(RegExp(r'[\s,;—\-–−‐‑‒―]+'), '');
    if (stripped.isEmpty) return true;
    if (stripped.toLowerCase() == 'to') return true;
    return false;
  }

  static bool _isScheduleChangeLog(String key) =>
      key.startsWith('booking.updated.schedule') || (key.startsWith('repeat.') && key.contains('schedule'));

  static bool _isPaymentChangeLog(String key) => key.startsWith('booking.updated.payment');

  static bool _isServiceChangeLog(String key) =>
      key.contains('detail') || key.contains('extra_service') || key.startsWith('booking.updated.service');

  static bool _hasPartialPaymentNear(BookingDetailsContent booking, String? timestamp) {
    final eventTime = DateTime.tryParse(timestamp ?? '');
    if (eventTime == null) return false;
    for (final payment in booking.partialPayments ?? <PartialPayment>[]) {
      final paymentTime = DateTime.tryParse(payment.createdAt ?? payment.updatedAt ?? '');
      if (paymentTime != null && eventTime.difference(paymentTime).inMinutes.abs() <= 30) return true;
    }
    return false;
  }

  static BookingEventType _eventTypeFromKey(String key, [String? apiType]) {
    switch (apiType) {
      case 'status': return BookingEventType.status;
      case 'schedule': return BookingEventType.schedule;
      case 'provider': return BookingEventType.provider;
      case 'service': return BookingEventType.service;
      case 'payment': return BookingEventType.payment;
    }
    if (_isStatusChangeLog(key)) return BookingEventType.status;
    if (_isScheduleChangeLog(key)) return BookingEventType.schedule;
    if (key.contains('assignment')) return BookingEventType.provider;
    if (_isPaymentChangeLog(key)) return BookingEventType.payment;
    if (_isServiceChangeLog(key)) return BookingEventType.service;
    return BookingEventType.other;
  }

  static List<BookingTimelineEvent> _dedupeAndSort(List<BookingTimelineEvent> events) {
    final sorted = [...events]..sort((a, b) {
      final aTime = DateTime.tryParse(a.timestamp ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = DateTime.tryParse(b.timestamp ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timeCompare = bTime.compareTo(aTime);
      if (timeCompare != 0) return timeCompare;
      return b.tieRank.compareTo(a.tieRank);
    });

    final seen = <String>{};
    final deduped = <BookingTimelineEvent>[];
    for (final event in sorted) {
      final key = '${event.eventType.name}|${_timeBucket(event.timestamp)}|${_normalize(event.description)}';
      if (seen.add(key)) deduped.add(event);
    }
    return deduped;
  }

  static String _normalize(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String _timeBucket(String? timestamp) {
    final dateTime = DateTime.tryParse(timestamp ?? '');
    if (dateTime == null) return _normalize(timestamp ?? '');
    return '${dateTime.year}-${dateTime.month}-${dateTime.day}-${dateTime.hour}-${(dateTime.minute / 15).floor()}';
  }
}
