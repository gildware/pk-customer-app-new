import 'package:flutter/material.dart';

/// Booking list filter tabs — same order and keys as admin web / mobile API.
const List<String> bookingListFilterTabs = [
  'all',
  'pending',
  'accepted',
  'canceled',
  'ongoing',
  'completed',
  'reopened',
  'resolved',
  'disputed_cancelled',
  'disputed_completed',
  'on_hold',
  'hold_after_visit',
  'completed_no_or_little',
  'cancelled_after_visit',
  'loss_making_pending',
  'loss_recovered',
  'loss_settled',
];

String bookingListFilterTabLabelKey(String tab) {
  switch (tab) {
    case 'disputed_cancelled':
      return 'disputed_and_cancelled';
    case 'disputed_completed':
      return 'disputed_and_completed';
    case 'completed_no_or_little':
      return 'booking_tag_complete_no_service';
    case 'cancelled_after_visit':
      return 'booking_tag_cancel_after_visit';
    case 'loss_making_pending':
      return 'bfs_list_badge_loss_making';
    case 'loss_recovered':
      return 'bfs_list_badge_loss_recovered';
    case 'loss_settled':
      return 'settled';
    default:
      return tab;
  }
}

IconData bookingListFilterTabIcon(String tab) {
  switch (tab) {
    case 'all':
      return Icons.apps_rounded;
    case 'pending':
      return Icons.schedule_rounded;
    case 'accepted':
      return Icons.check_circle_outline_rounded;
    case 'canceled':
      return Icons.cancel_outlined;
    case 'ongoing':
      return Icons.autorenew_rounded;
    case 'completed':
      return Icons.task_alt_rounded;
    case 'reopened':
      return Icons.replay_rounded;
    case 'resolved':
      return Icons.verified_outlined;
    case 'disputed_cancelled':
    case 'disputed_completed':
    case 'cancelled_after_visit':
      return Icons.gavel_rounded;
    case 'on_hold':
    case 'hold_after_visit':
      return Icons.pause_circle_outline_rounded;
    case 'completed_no_or_little':
      return Icons.home_repair_service_outlined;
    case 'loss_making_pending':
    case 'loss_recovered':
    case 'loss_settled':
      return Icons.trending_down_rounded;
    default:
      return Icons.label_outline_rounded;
  }
}
