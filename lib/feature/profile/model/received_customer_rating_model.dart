import 'package:demandium/feature/provider/model/provider_model.dart';

class ReceivedCustomerRatingModel {
  String? responseCode;
  String? message;
  ReceivedCustomerRatingContent? content;

  ReceivedCustomerRatingModel({this.responseCode, this.message, this.content});

  ReceivedCustomerRatingModel.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code'];
    message = json['message'];
    content = json['content'] != null
        ? ReceivedCustomerRatingContent.fromJson(json['content'])
        : null;
  }
}

class ReceivedCustomerRatingContent {
  ReceivedCustomerReviews? reviews;
  ReceivedCustomerRatingSummary? rating;

  ReceivedCustomerRatingContent({this.reviews, this.rating});

  ReceivedCustomerRatingContent.fromJson(Map<String, dynamic> json) {
    reviews = json['reviews'] != null
        ? ReceivedCustomerReviews.fromJson(json['reviews'])
        : null;
    rating = json['rating'] != null
        ? ReceivedCustomerRatingSummary.fromJson(json['rating'])
        : null;
  }
}

class ReceivedCustomerReviews {
  int? currentPage;
  List<ReceivedCustomerReview>? reviewList;
  int? lastPage;
  int? total;

  ReceivedCustomerReviews({
    this.currentPage,
    this.reviewList,
    this.lastPage,
    this.total,
  });

  ReceivedCustomerReviews.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page'];
    if (json['data'] != null) {
      reviewList = <ReceivedCustomerReview>[];
      json['data'].forEach((v) {
        reviewList!.add(ReceivedCustomerReview.fromJson(v));
      });
    }
    lastPage = json['last_page'];
    total = json['total'];
  }
}

class ReceivedCustomerReview {
  String? id;
  String? bookingId;
  String? providerId;
  int? reviewRating;
  String? reviewComment;
  String? bookingDate;
  String? createdAt;
  String? updatedAt;
  ProviderData? provider;
  ReceivedCustomerReviewBooking? booking;

  ReceivedCustomerReview({
    this.id,
    this.bookingId,
    this.providerId,
    this.reviewRating,
    this.reviewComment,
    this.bookingDate,
    this.createdAt,
    this.updatedAt,
    this.provider,
    this.booking,
  });

  ReceivedCustomerReview.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    bookingId = json['booking_id'];
    providerId = json['provider_id'];
    reviewRating = int.tryParse(json['review_rating'].toString());
    reviewComment = json['review_comment'];
    bookingDate = json['booking_date'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    provider = json['provider'] != null
        ? ProviderData.fromJson(json['provider'])
        : null;
    booking = json['booking'] != null
        ? ReceivedCustomerReviewBooking.fromJson(json['booking'])
        : null;
  }
}

class ReceivedCustomerReviewBooking {
  String? id;
  String? readableId;
  String? createdAt;

  ReceivedCustomerReviewBooking({this.id, this.readableId, this.createdAt});

  ReceivedCustomerReviewBooking.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    readableId = json['readable_id'];
    createdAt = json['created_at'];
  }
}

class ReceivedCustomerRatingSummary {
  double? averageRating;
  int? ratingCount;

  ReceivedCustomerRatingSummary({this.averageRating, this.ratingCount});

  ReceivedCustomerRatingSummary.fromJson(Map<String, dynamic> json) {
    averageRating = double.tryParse(json['average_rating'].toString());
    ratingCount = int.tryParse(json['rating_count'].toString());
  }
}
