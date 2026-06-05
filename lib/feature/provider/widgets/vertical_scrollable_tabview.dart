import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';



class VerticalScrollableTabBarStatus {
  static bool isOnTap = false;
  static int isOnTapIndex = 0;

  static void setIndex(int index) {
    VerticalScrollableTabBarStatus.isOnTap = true;
    VerticalScrollableTabBarStatus.isOnTapIndex = index;
  }
}

enum VerticalScrollPosition { begin, middle, end }

class VerticalScrollableTabView extends StatefulWidget {

  final TabController _tabController;

  final List<dynamic> _listItemData;

  final Widget Function(dynamic aaa, int index) _eachItemChild;
  final VerticalScrollPosition _verticalScrollPosition;

  final List<Widget> _slivers;
  final bool _useNestedScroll;

  const VerticalScrollableTabView({super.key, 
    required TabController tabController,
    required List<dynamic> listItemData,
    required Widget Function(dynamic aaa, int index) eachItemChild,
    VerticalScrollPosition verticalScrollPosition =
        VerticalScrollPosition.begin,
    required List<Widget> slivers,
    bool useNestedScroll = false,
  })  : _tabController = tabController,
        _listItemData = listItemData,

        _eachItemChild = eachItemChild,
        _verticalScrollPosition = verticalScrollPosition,
        _slivers = slivers,
        _useNestedScroll = useNestedScroll;

  @override
  VerticalScrollableTabViewState createState() => VerticalScrollableTabViewState();
}

class VerticalScrollableTabViewState extends State<VerticalScrollableTabView> with SingleTickerProviderStateMixin {

  AutoScrollController? _scrollController;

  bool pauseRectGetterIndex = false;

  final listViewKey = RectGetter.createGlobalKey();

  Map<int, dynamic> itemsKeys = {};

  @override
  void initState() {
    widget._tabController.addListener(() {
      if (VerticalScrollableTabBarStatus.isOnTap) {
        animateAndScrollTo(VerticalScrollableTabBarStatus.isOnTapIndex);
        VerticalScrollableTabBarStatus.isOnTap = false;
      }
    });
    if (!widget._useNestedScroll) {
      _scrollController = AutoScrollController();
    }
    super.initState();
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slivers = <Widget>[
      if (widget._useNestedScroll)
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
      ...widget._slivers,
      buildVerticalSliverList(),
    ];

    return RectGetter(
      key: listViewKey,

      child: NotificationListener<ScrollNotification>(
        onNotification: onScrollNotification,
        child: CustomScrollView(
          shrinkWrap: !widget._useNestedScroll,
          physics: widget._useNestedScroll
              ? const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics())
              : null,
          controller: widget._useNestedScroll ? null : _scrollController,
          slivers: slivers,
        ),
      ),
    );
  }


  SliverList buildVerticalSliverList() {
    return SliverList(
      delegate: SliverChildListDelegate(List.generate(
        widget._listItemData.length,
            (index) {

          itemsKeys[index] = RectGetter.createGlobalKey();
          return buildItem(index);
        },
      )),
    );
  }

  Widget buildItem(int index) {
    dynamic category = widget._listItemData[index];
    final child = widget._eachItemChild(category, index);

    if (widget._useNestedScroll) {
      return RectGetter(
        key: itemsKeys[index],
        child: child,
      );
    }

    return RectGetter(
      key: itemsKeys[index],
      child: AutoScrollTag(
        key: ValueKey(index),
        index: index,
        controller: _scrollController!,
        child: child,
      ),
    );
  }

  double _nestedScrollAlignment() {
    switch (widget._verticalScrollPosition) {
      case VerticalScrollPosition.begin:
        return 0;
      case VerticalScrollPosition.middle:
        return 0.5;
      case VerticalScrollPosition.end:
        return 1;
    }
  }

  void animateAndScrollTo(int index) async {
    pauseRectGetterIndex = true;
    widget._tabController.animateTo(index);

    if (widget._useNestedScroll) {
      final key = itemsKeys[index];
      final itemContext = key?.currentContext;
      if (itemContext != null) {
        await Scrollable.ensureVisible(
          itemContext,
          duration: const Duration(milliseconds: 300),
          alignment: _nestedScrollAlignment(),
        );
      }
      pauseRectGetterIndex = false;
      return;
    }

    final controller = _scrollController!;
    switch (widget._verticalScrollPosition) {
      case VerticalScrollPosition.begin:
        controller
            .scrollToIndex(index, preferPosition: AutoScrollPosition.begin)
            .then((value) => pauseRectGetterIndex = false);
        break;
      case VerticalScrollPosition.middle:
        controller
            .scrollToIndex(index, preferPosition: AutoScrollPosition.middle)
            .then((value) => pauseRectGetterIndex = false);
        break;
      case VerticalScrollPosition.end:
        controller
            .scrollToIndex(index, preferPosition: AutoScrollPosition.end)
            .then((value) => pauseRectGetterIndex = false);
        break;
    }
  }

  void _safeAnimateTabTo(int index) {
    if (widget._tabController.length == 0) return;
    final safeIndex = index.clamp(0, widget._tabController.length - 1);
    if (widget._tabController.index != safeIndex) {
      widget._tabController.animateTo(safeIndex);
    }
  }

  int _visibleTabIndex(List<int> visibleItems, int fallback) {
    if (visibleItems.isEmpty) return fallback;
    return visibleItems.first.clamp(0, widget._tabController.length - 1);
  }

  int _secondVisibleTabIndex(List<int> visibleItems) {
    if (visibleItems.length > 1) {
      return visibleItems[1].clamp(0, widget._tabController.length - 1);
    }
    if (widget._tabController.length > 1) return 1;
    return _visibleTabIndex(visibleItems, 0);
  }

  bool onScrollNotification(ScrollNotification notification) {
    if (widget._useNestedScroll && !notification.metrics.hasPixels) {
      return false;
    }

    List<int> visibleItems = getVisibleItemsIndex();
    if (visibleItems.isEmpty && widget._useNestedScroll) {
      return false;
    }

    if(notification is UserScrollNotification){

      final categoryCount = Get.find<ProviderBookingController>().categoryItemList.length;

      if(categoryCount == 2){
        if(notification.metrics.pixels <= 5){
          _safeAnimateTabTo(_visibleTabIndex(visibleItems, 0));
        }else{
          _safeAnimateTabTo(1);
        }
      }
      else if(categoryCount > 2){
          double previousPixels = (notification.metrics).pixels;


          WidgetsBinding.instance.addPostFrameCallback((_) {
            double currentPixels = (notification.metrics).pixels;
            if(currentPixels <= 5){
              _safeAnimateTabTo(_visibleTabIndex(visibleItems, 0));
            }else{
              if (currentPixels < previousPixels) {
                _safeAnimateTabTo(_visibleTabIndex(visibleItems, 0));
              } else {
                _safeAnimateTabTo(_secondVisibleTabIndex(visibleItems));
              }
            }


          });

      }

    }


    return false;
  }

  List<int> getVisibleItemsIndex() {
    if (listViewKey.currentContext?.findRenderObject()?.attached != true) {
      return [];
    }

    Rect? rect;
    try {
      rect = RectGetter.getRectFromKey(listViewKey);
    } catch (_) {
      return [];
    }

    List<int> items = [];
    final bounds = rect;
    if (bounds == null || bounds.isEmpty) return items;


    bool isHoriontalScroll = false;
    itemsKeys.forEach((index, key) {
      Rect? itemRect;
      try {
        itemRect = RectGetter.getRectFromKey(key);
      } catch (_) {
        return;
      }
      if (itemRect == null || itemRect.isEmpty) return;

      switch (isHoriontalScroll) {
        case true:
          if (itemRect.left > bounds.right) return;
          if (itemRect.right < bounds.left) return;
          break;
        default:
          if (itemRect.top > bounds.bottom) return;
          if (itemRect.bottom <
              bounds.top +
                  MediaQuery.of(context).viewPadding.top +
                  kToolbarHeight+200) {
            return;
          }
      }

      items.add(index);
    });
    return items;
  }
}
