class ProviderShowcaseItem {
  String? id;
  String? providerId;
  String? title;
  String? description;
  String? mediaType;
  String? fileName;
  String? mediaFullPath;
  int? sortOrder;

  ProviderShowcaseItem({
    this.id,
    this.providerId,
    this.title,
    this.description,
    this.mediaType,
    this.fileName,
    this.mediaFullPath,
    this.sortOrder,
  });

  bool get isVideo => mediaType == 'video';

  ProviderShowcaseItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    providerId = json['provider_id'];
    title = json['title'];
    description = json['description'];
    mediaType = json['media_type'];
    fileName = json['file_name'];
    mediaFullPath = json['media_full_path'];
    sortOrder = int.tryParse(json['sort_order']?.toString() ?? '');
  }
}
