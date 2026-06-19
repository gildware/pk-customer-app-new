import 'package:flutter/material.dart';

/// Admin web booking badge/tag colors (panun-admin admin-module CSS).
class BookingStatusVariantColors {
  BookingStatusVariantColors._();

  static const Color absoluteDark = Color(0xFF18181A);
  static const Color absoluteWhite = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFEFF1F4);

  static String normalizeVariant(String? variant) {
    return (variant ?? '').trim().toLowerCase().replaceAll('-', '_');
  }

  /// Soft badge background — matches admin `.badge-*` (main booking status).
  static Color softBadgeBackground(String variant) {
    switch (normalizeVariant(variant)) {
      case 'info':
        return const Color(0x1A2B95FF);
      case 'primary':
        return const Color(0x1A25274D);
      case 'success':
        return const Color(0x1A16B559);
      case 'secondary':
        return const Color(0x1A758590);
      case 'danger':
        return const Color(0x1AFF3737);
      case 'warning':
        return const Color(0x1AE4AE23);
      case 'warning_dark':
        return const Color(0x1EE6A832);
      case 'light':
        return const Color(0xFFF7F8F9);
      case 'dark':
        return absoluteDark;
      default:
        return const Color(0x1A2B95FF);
    }
  }

  /// Soft badge text — matches admin `.badge-*`.
  static Color softBadgeForeground(String variant) {
    switch (normalizeVariant(variant)) {
      case 'info':
        return const Color(0xFF2B95FF);
      case 'primary':
        return const Color(0xFF25274D);
      case 'success':
        return const Color(0xFF16B559);
      case 'secondary':
        return const Color(0xFF758590);
      case 'danger':
        return const Color(0xFFFF3737);
      case 'warning':
        return const Color(0xFFE4AE23);
      case 'warning_dark':
        return const Color(0xFFE6A832);
      case 'light':
        return absoluteDark;
      case 'dark':
        return absoluteWhite;
      default:
        return const Color(0xFF2B95FF);
    }
  }

  /// Solid tag background — matches admin `bg-*` tags.
  static Color solidTagBackground(String variant) {
    switch (normalizeVariant(variant)) {
      case 'warning':
        return const Color(0xFFFFBB38);
      case 'success':
        return const Color(0xFF04BB7B);
      case 'info':
        return const Color(0xFF3C76F1);
      case 'danger':
        return const Color(0xFFFF4040);
      case 'primary':
        return const Color(0xFF25274D);
      case 'secondary':
        return const Color(0xFF758590);
      case 'light':
        return const Color(0xFFF7F8F9);
      case 'dark':
        return absoluteDark;
      default:
        return const Color(0xFF758590);
    }
  }

  /// Solid tag text — matches admin `bg-*` tags.
  static Color solidTagForeground(String variant) {
    switch (normalizeVariant(variant)) {
      case 'warning':
      case 'light':
        return absoluteDark;
      default:
        return absoluteWhite;
    }
  }

  static bool solidTagHasBorder(String variant) {
    return normalizeVariant(variant) == 'light';
  }

  /// Map raw booking_status to admin list badge variant when API field is missing.
  static String variantForRawStatus(String? rawStatus) {
    switch ((rawStatus ?? '').toLowerCase()) {
      case 'ongoing':
        return 'warning';
      case 'on_hold':
        return 'secondary';
      case 'completed':
        return 'success';
      case 'canceled':
      case 'cancelled':
      case 'refunded':
        return 'danger';
      default:
        return 'info';
    }
  }

  static String resolveBadgeVariant({
    String? badgeVariant,
    String? rawStatus,
  }) {
    final normalized = normalizeVariant(badgeVariant);
    if (normalized.isNotEmpty) return normalized;
    return variantForRawStatus(rawStatus);
  }
}
