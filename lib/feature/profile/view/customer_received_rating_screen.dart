import 'package:demandium/common/widgets/custom_pop_widget.dart';
import 'package:demandium/feature/profile/controller/customer_received_rating_controller.dart';
import 'package:demandium/feature/profile/widget/received_customer_review_item.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class CustomerReceivedRatingScreen extends StatefulWidget {
  const CustomerReceivedRatingScreen({super.key});

  @override
  State<CustomerReceivedRatingScreen> createState() =>
      _CustomerReceivedRatingScreenState();
}

class _CustomerReceivedRatingScreenState
    extends State<CustomerReceivedRatingScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Get.find<CustomerReceivedRatingController>()
        .getReceivedRatings(1, reload: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPopWidget(
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'ratings_and_reviews'.tr,
          centerTitle: true,
          bgColor: Theme.of(context).primaryColor,
          isBackButtonExist: true,
        ),
        body: GetBuilder<CustomerReceivedRatingController>(
          builder: (controller) {
            if (controller.isLoading && controller.reviewList.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final summary = controller.ratingSummary;
            final avgRating = summary?.averageRating ?? 0;
            final ratingCount = summary?.ratingCount ?? 0;

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
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
                        avgRating.toStringAsFixed(1),
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeOverLarge,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RatingBar(
                            rating: avgRating,
                            size: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                          Text(
                            '$ratingCount ${'ratings'.tr}',
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: controller.reviewList.isEmpty
                      ? const Center(child: EmptyReviewWidget())
                      : PaginatedListView(
                          scrollController: _scrollController,
                          totalSize: controller.totalSize,
                          offset: controller.currentPage,
                          onPaginate: (int offset) async {
                            await controller.getReceivedRatings(
                              offset,
                              reload: false,
                            );
                          },
                          itemView: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault,
                            ),
                            itemCount: controller.reviewList.length,
                            itemBuilder: (context, index) {
                              return ReceivedCustomerReviewItem(
                                review: controller.reviewList[index],
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
