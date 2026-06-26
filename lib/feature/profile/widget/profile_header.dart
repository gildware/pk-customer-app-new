import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class ProfileHeader extends GetView<UserController> {
  final UserInfoModel? userInfoModel;
  const ProfileHeader({super.key, required this.userInfoModel});

  String _formatAccountAgo(String accountAgo) {
    return accountAgo
        .replaceAll('days ago', 'days_ago'.tr)
        .replaceAll('a day ago', 'a_day_ago'.tr)
        .replaceAll('a moment ago', 'a_moment_ago'.tr)
        .replaceAll('a minute ago', 'a_minute_ago'.tr)
        .replaceAll('minutes ago', 'minutes_ago'.tr)
        .replaceAll('about a month ago', 'about_a_month_ago'.tr)
        .replaceAll('about an hour ago', 'about_an_hour_ago'.tr)
        .replaceAll('months ago', 'months_ago'.tr)
        .replaceAll('hours ago', 'hours_ago'.tr)
        .replaceAll('about a year ago', 'about_a_year_ago'.tr)
        .replaceAll('years ago', 'years_ago'.tr);
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Get.find<AuthController>().isLoggedIn();
    return GetBuilder<UserController>(builder: (userController) {
      final name = isLoggedIn &&
              userInfoModel?.fName != null &&
              userInfoModel?.lName != null
          ? "${userInfoModel!.fName!} ${userInfoModel!.lName!}"
          : 'guest_user'.tr;
      final phone = isLoggedIn && userInfoModel?.phone?.isNotEmpty == true
          ? userInfoModel!.phone!
          : null;
      final email = isLoggedIn && userInfoModel?.email?.isNotEmpty == true
          ? userInfoModel!.email!
          : null;
      final avgRating = userInfoModel?.receivedAvgRating ?? 0;
      final ratingCount = userInfoModel?.receivedRatingCount ?? 0;

      return Padding(
        padding: const EdgeInsets.fromLTRB(
          Dimensions.paddingSizeDefault,
          Dimensions.paddingSizeSmall,
          Dimensions.paddingSizeDefault,
          Dimensions.paddingSizeDefault,
        ),
        child: Column(
          children: [
            Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: Theme.of(context).hoverColor,
            boxShadow:
                Get.find<ThemeController>().darkTheme ? null : cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: CustomImage(
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  image: userController.userInfoModel?.imageFullPath ?? "",
                  placeholder: Images.userPlaceHolder,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                              color: isLoggedIn
                                  ? Theme.of(context).textTheme.bodyMedium!.color
                                  : Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .color!
                                      .withValues(alpha: .5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLoggedIn)
                          GestureDetector(
                            onTap: () =>
                                Get.toNamed(RouteHelper.getEditProfileRoute()),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'edit'.tr,
                                  style: robotoBold.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Get.isDarkMode
                                        ? Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color
                                        : Theme.of(context)
                                            .colorScheme
                                            .primary,
                                  ),
                                ),
                                const SizedBox(
                                    width: Dimensions.paddingSizeExtraSmall),
                                Icon(
                                  Icons.edit_outlined,
                                  size: Dimensions.fontSizeDefault,
                                  color: Get.isDarkMode
                                      ? Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (phone != null) ...[
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Text(
                        phone,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).hintColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (email != null) ...[
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Text(
                        email,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).hintColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (isLoggedIn) ...[
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Row(
                        children: [
                          if (userInfoModel?.bookingsCount != null) ...[
                            _ProfileStat(
                              value: '${userInfoModel!.bookingsCount}',
                              label: 'bookings'.tr,
                            ),
                            _verticalDivider(context),
                          ],
                          _ProfileStat(
                            value: _formatAccountAgo(
                              Get.find<UserController>().createdAccountAgo.tr,
                            ),
                            label: 'since_joined'.tr,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
            if (isLoggedIn) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              InkWell(
                onTap: () =>
                    Get.toNamed(RouteHelper.getCustomerReceivedRatingRoute()),
                borderRadius:
                    BorderRadius.circular(Dimensions.radiusDefault),
                child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                  vertical: Dimensions.paddingSizeSmall,
                ),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusDefault),
                  color: Theme.of(context).hoverColor,
                  boxShadow: Get.find<ThemeController>().darkTheme
                      ? null
                      : cardShadow,
                ),
                child: Row(
                  children: [
                    Text(
                      'rating'.tr,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          RatingBar(
                            rating: avgRating,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(
                              width: Dimensions.paddingSizeExtraSmall),
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Get.isDarkMode
                                  ? Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(
                              width: Dimensions.paddingSizeExtraSmall),
                          Flexible(
                            child: Text(
                              '($ratingCount ${'ratings'.tr})',
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).hintColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: Dimensions.fontSizeSmall,
                            color: Theme.of(context).hintColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _verticalDivider(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault),
      width: 1,
      height: 28,
      color: Theme.of(context).hintColor.withValues(alpha: 0.3),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Get.isDarkMode
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Theme.of(context).colorScheme.primary,
          ),
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeExtraSmall,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }
}
