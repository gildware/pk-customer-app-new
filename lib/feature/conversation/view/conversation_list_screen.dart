import 'package:demandium/common/widgets/custom_pop_widget.dart';
import 'package:demandium/feature/conversation/widgets/conversation_list_shimmer.dart';
import 'package:demandium/feature/conversation/widgets/conversation_listview.dart';
import 'package:demandium/feature/conversation/widgets/conversation_search_shimmer.dart';
import 'package:demandium/feature/conversation/widgets/conversation_search_widget.dart';
import 'package:demandium/feature/conversation/widgets/conversation_tabview.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';
import 'package:demandium/common/widgets/address_selection_drawer.dart';

class ConversationListScreen extends StatefulWidget {
  final String? fromNotification;
  const ConversationListScreen({super.key, this.fromNotification});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> with TickerProviderStateMixin {
  late final TabController _inboxTabController;

  @override
  void initState() {
    super.initState();
    _inboxTabController = TabController(length: 2, vsync: this);
    _inboxTabController.addListener(_onInboxTabChanged);
    Get.find<ConversationController>().clearSearchController(shouldUpdate: false);
    _loadData();
  }

  void _onInboxTabChanged() {
    if (_inboxTabController.index == 1 && !_inboxTabController.indexIsChanging) {
      Get.find<InAppCallController>().getCallHistory(1, reload: true);
    }
  }

  Future<void> _loadData() async {
    await Get.find<ConversationController>().getChannelList(1, type: "provider");
    if (AppFeatureFlags.servicemanEnabled) {
      await Get.find<ConversationController>().getChannelList(1, type: "serviceman");
    }
  }

  @override
  void dispose() {
    _inboxTabController.removeListener(_onInboxTabChanged);
    _inboxTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPopWidget(
      onPopInvoked: () {
        Get.offNamed(RouteHelper.getMainRoute(RouteHelper.chatInbox));
      },
      child: Scaffold(
        drawer: ResponsiveHelper.isDesktop(context) ? const AddressSelectionDrawer() : null,
        endDrawer: ResponsiveHelper.isDesktop(context) ? const MenuDrawer() : null,
        appBar: CustomAppBar(
          title: 'inbox'.tr,
          isBackButtonExist: true,
          onBackPressed: () {
            if (widget.fromNotification == "fromNotification" || !Navigator.canPop(context)) {
              Get.offNamed(RouteHelper.getMainRoute(RouteHelper.chatInbox));
            } else {
              final conversationController = Get.find<ConversationController>();
              if (conversationController.isActiveSuffixIcon && conversationController.isSearchComplete) {
                conversationController.clearSearchController();
              } else {
                Get.back();
              }
            }
          },
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: TabBar(
                controller: _inboxTabController,
                unselectedLabelColor: Colors.grey,
                indicatorColor: context.tabIndicatorColor,
                labelColor: context.tabSelectedColor,
                labelStyle: robotoMedium,
                tabs: [
                  Tab(text: 'chat'.tr),
                  Tab(text: 'calls'.tr),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _inboxTabController,
                children: [
                  _buildChatTab(),
                  const CallHistoryListView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTab() {
    return GetBuilder<ConversationController>(
      builder: (conversationController) {
        return FooterBaseView(
          isScrollView: true,
          child: conversationController.providerChannelList != null
              ? Center(
                  child: SizedBox(
                    height: ResponsiveHelper.isDesktop(context) ? Get.height * 0.8 : Get.height,
                    width: Dimensions.webMaxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        const ConversationSearchWidget(),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              conversationController.adminConversationModel != null
                                  ? ChannelItem(
                                      channelData: conversationController.adminConversationModel!,
                                      isAdmin: true,
                                    )
                                  : const SizedBox(),
                              if (conversationController.adminConversationModel != null)
                                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                              if (AppFeatureFlags.servicemanEnabled)
                                ConversationListTabview(tabController: conversationController.tabController),
                              if (AppFeatureFlags.servicemanEnabled)
                                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                              Expanded(
                                child: AppFeatureFlags.servicemanEnabled
                                    ? TabBarView(
                                        controller: conversationController.tabController,
                                        children: [
                                          conversationController.searchedChannelList == null &&
                                                  !conversationController.isSearchComplete
                                              ? const ConversationSearchShimmer()
                                              : ConversationListView(
                                                  channelList: conversationController.isSearchComplete
                                                      ? conversationController.searchedProviderChannelList!
                                                      : conversationController.providerChannelList ?? [],
                                                  tabIndex: 0,
                                                ),
                                          conversationController.searchedChannelList == null &&
                                                  !conversationController.isSearchComplete
                                              ? const ConversationSearchShimmer()
                                              : ConversationListView(
                                                  channelList: conversationController.isSearchComplete
                                                      ? conversationController.searchedServicemanChannelList!
                                                      : conversationController.servicemanChannelList ?? [],
                                                  tabIndex: 1,
                                                ),
                                        ],
                                      )
                                    : (conversationController.searchedChannelList == null &&
                                            !conversationController.isSearchComplete
                                        ? const ConversationSearchShimmer()
                                        : ConversationListView(
                                            channelList: conversationController.isSearchComplete
                                                ? conversationController.searchedProviderChannelList!
                                                : conversationController.providerChannelList ?? [],
                                            tabIndex: 0,
                                          )),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const ConversationListShimmer(),
        );
      },
    );
  }
}
