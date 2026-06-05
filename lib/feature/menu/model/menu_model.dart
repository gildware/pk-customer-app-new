class MenuModel {
  String? iconKey;
  String? icon;
  String? title;
  String? route;
  bool isLogout;

  MenuModel({this.iconKey, required this.icon, required this.title, required this.route, this.isLogout = false});
}