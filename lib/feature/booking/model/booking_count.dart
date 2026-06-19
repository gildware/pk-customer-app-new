import 'package:demandium/helper/booking_list_filter_tabs.dart';

class BookingCount {
  int? all;
  int? pending;
  int? accepted;
  int? ongoing;
  int? onHold;
  int? completed;
  int? canceled;
  int? reopened;
  int? resolved;
  int? disputedCancelled;
  int? disputedCompleted;
  int? holdAfterVisit;
  int? completedNoOrLittle;
  int? cancelledAfterVisit;
  int? lossMakingPending;
  int? lossRecovered;
  int? lossSettled;

  BookingCount({
    this.all,
    this.pending,
    this.accepted,
    this.ongoing,
    this.onHold,
    this.completed,
    this.canceled,
    this.reopened,
    this.resolved,
    this.disputedCancelled,
    this.disputedCompleted,
    this.holdAfterVisit,
    this.completedNoOrLittle,
    this.cancelledAfterVisit,
    this.lossMakingPending,
    this.lossRecovered,
    this.lossSettled,
  });

  BookingCount.fromJson(Map<String, dynamic> json) {
    all = int.tryParse(json['all']?.toString() ?? '');
    pending = int.tryParse(json['pending']?.toString() ?? '');
    accepted = int.tryParse(json['accepted']?.toString() ?? '');
    ongoing = int.tryParse(json['ongoing']?.toString() ?? '');
    onHold = int.tryParse(json['on_hold']?.toString() ?? '');
    completed = int.tryParse(json['completed']?.toString() ?? '');
    canceled = int.tryParse(json['canceled']?.toString() ?? '');
    reopened = int.tryParse(json['reopened']?.toString() ?? '');
    resolved = int.tryParse(json['resolved']?.toString() ?? '');
    disputedCancelled = int.tryParse(json['disputed_cancelled']?.toString() ?? '');
    disputedCompleted = int.tryParse(json['disputed_completed']?.toString() ?? '');
    holdAfterVisit = int.tryParse(json['hold_after_visit']?.toString() ?? '');
    completedNoOrLittle = int.tryParse(json['completed_no_or_little']?.toString() ?? '');
    cancelledAfterVisit = int.tryParse(json['cancelled_after_visit']?.toString() ?? '');
    lossMakingPending = int.tryParse(json['loss_making_pending']?.toString() ?? '');
    lossRecovered = int.tryParse(json['loss_recovered']?.toString() ?? '');
    lossSettled = int.tryParse(json['loss_settled']?.toString() ?? '');
  }

  int countForTab(String tab) {
    switch (tab) {
      case 'all':
        return all ?? 0;
      case 'pending':
        return pending ?? 0;
      case 'accepted':
        return accepted ?? 0;
      case 'ongoing':
        return ongoing ?? 0;
      case 'on_hold':
        return onHold ?? 0;
      case 'completed':
        return completed ?? 0;
      case 'canceled':
        return canceled ?? 0;
      case 'reopened':
        return reopened ?? 0;
      case 'resolved':
        return resolved ?? 0;
      case 'disputed_cancelled':
        return disputedCancelled ?? 0;
      case 'disputed_completed':
        return disputedCompleted ?? 0;
      case 'hold_after_visit':
        return holdAfterVisit ?? 0;
      case 'completed_no_or_little':
        return completedNoOrLittle ?? 0;
      case 'cancelled_after_visit':
        return cancelledAfterVisit ?? 0;
      case 'loss_making_pending':
        return lossMakingPending ?? 0;
      case 'loss_recovered':
        return lossRecovered ?? 0;
      case 'loss_settled':
        return lossSettled ?? 0;
      default:
        return 0;
    }
  }

  List<String> get visibleTabs {
    final tabs = <String>['all'];
    for (final tab in bookingListFilterTabs) {
      if (tab == 'all') continue;
      if (countForTab(tab) > 0) tabs.add(tab);
    }
    return tabs;
  }
}
