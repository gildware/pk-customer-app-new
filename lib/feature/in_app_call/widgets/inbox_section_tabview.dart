import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class InboxSectionTabview extends StatelessWidget {
  final TabController tabController;

  const InboxSectionTabview({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: TabBar(
        controller: tabController,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelColor: Theme.of(context).colorScheme.primary,
        labelStyle: robotoMedium,
        indicatorWeight: 1.5,
        tabs: [
          Tab(text: 'chat'.tr),
          Tab(text: 'calls'.tr),
        ],
      ),
    );
  }
}
