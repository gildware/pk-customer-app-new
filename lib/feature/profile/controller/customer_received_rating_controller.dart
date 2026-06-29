import 'package:demandium/feature/profile/model/received_customer_rating_model.dart';
import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class CustomerReceivedRatingController extends GetxController implements GetxService {
  final UserRepo userRepo;

  CustomerReceivedRatingController({required this.userRepo});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ReceivedCustomerRatingSummary? _ratingSummary;
  ReceivedCustomerRatingSummary? get ratingSummary => _ratingSummary;

  final List<ReceivedCustomerReview> _reviewList = [];
  List<ReceivedCustomerReview> get reviewList => _reviewList;

  int? _currentPage;
  int? get currentPage => _currentPage;

  int? _totalSize;
  int? get totalSize => _totalSize;

  Future<void> getReceivedRatings(int offset, {bool reload = true}) async {
    if (reload) {
      _reviewList.clear();
      _ratingSummary = null;
      _currentPage = null;
      _totalSize = null;
    }

    _isLoading = true;
    update();

    try {
      final response = await userRepo.getReceivedCustomerRatings(offset);
      if (response.statusCode == 200) {
        final model = ReceivedCustomerRatingModel.fromJson(response.body);
        _ratingSummary = model.content?.rating;
        _currentPage = model.content?.reviews?.currentPage;
        _totalSize = model.content?.reviews?.total;

        final pageReviews = model.content?.reviews?.reviewList ?? [];
        for (final review in pageReviews) {
          _reviewList.add(review);
        }
      } else {
        ApiChecker.checkApi(response);
      }
    } finally {
      _isLoading = false;
      update();
    }
  }
}
