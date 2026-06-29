/// Temporary feature toggles. Set [servicemanEnabled] to true when serviceman support returns.
class AppFeatureFlags {
  AppFeatureFlags._();

  // SERVICEMAN_DISABLED: flip to true to restore serviceman flows in the customer app.
  static const bool servicemanEnabled = false;
}
