import 'package:demandium/feature/home/helper/home_provider_section_layout.dart';
import 'package:demandium/feature/provider/view/nearby_provider/widget/nearby_provider_list_item_view.dart';
import 'package:demandium/feature/provider/widgets/provider_item_view.dart';
import 'package:demandium/util/core_export.dart';

/// Plain home row: title + horizontal provider cards (no section background).
class HomeProviderHorizontalSection extends StatelessWidget {
  final String titleKey;
  final String? displayTitle;
  final VoidCallback? onSeeAll;
  final bool showSeeAll;
  final List<ProviderData>? providers;
  final bool useNearbyItem;
  final GlobalKey<CustomShakingWidgetState>? signInShakeKey;
  final double? height;

  const HomeProviderHorizontalSection({
    super.key,
    required this.titleKey,
    this.displayTitle,
    this.onSeeAll,
    this.showSeeAll = false,
    required this.providers,
    this.useNearbyItem = false,
    this.signInShakeKey,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final list = providers;
    if (list == null) {
      return HomeRecommendedProviderShimmer(
        height: height ?? HomeProviderSectionLayout.sectionHeight(context),
      );
    }
    if (list.isEmpty) {
      return const SizedBox();
    }

    final listHeight = HomeProviderSectionLayout.listHeight(context);
    final cardWidth = HomeProviderSectionLayout.cardWidth(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeExtraSmall,
          ),
          child: TitleWidget(
            textDecoration: TextDecoration.underline,
            title: titleKey,
            displayTitle: displayTitle,
            onTap: onSeeAll,
            isShowSeeAllButton: showSeeAll,
          ),
        ),
        SizedBox(
          height: listHeight,
          child: ListView.builder(
            physics: const ClampingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
            itemCount: list.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: HomeProviderSectionLayout.listItemPadding(),
                child: SizedBox(
                  width: cardWidth,
                  child: useNearbyItem
                      ? NearbyProviderListItemView(
                          providerData: list[index],
                          index: index,
                          signInShakeKey: signInShakeKey,
                        )
                      : ProviderItemView(
                          providerData: list[index],
                          index: index,
                          signInShakeKey: signInShakeKey,
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
