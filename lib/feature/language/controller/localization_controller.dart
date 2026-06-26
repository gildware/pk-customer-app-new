import 'dart:convert';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class LocalizationController extends GetxController implements GetxService {
  late SharedPreferences sharedPreferences;
  late ApiClient apiClient;

  LocalizationController({required this.sharedPreferences, required this.apiClient}) {
    loadCurrentLanguage();
  }

  Locale _locale = Locale(AppConstants.languages[0].languageCode!, AppConstants.languages[0].countryCode);
  bool _isLtr = true;
  List<LanguageModel>  _localLanguages = [];

  Locale get locale => _locale;
  bool get isLtr => _isLtr;
  List<LanguageModel> get languages =>  _localLanguages;

  void setLanguage(Locale locale, {bool isInitial = false}) {
    Get.updateLocale(locale);
    _locale = locale;
    if(_locale.languageCode == 'ar') {
      _isLtr = false;
    }else {
      _isLtr = true;
    }
    AddressModel? addressModel;
    try {
      final addressJson = sharedPreferences.getString(AppConstants.userAddress);
      if (addressJson != null && addressJson.isNotEmpty) {
        addressModel = AddressModel.fromJson(jsonDecode(addressJson));
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    ///pick zone id to update header
    apiClient.updateHeader(
      SecureTokenStorage.cachedToken().isEmpty ? null : SecureTokenStorage.cachedToken(),
      addressModel?.zoneId,
      locale.languageCode, Get.find<SplashController>().getGuestId(),
    );
    saveLanguage(_locale);
    if(AddressSessionHelper.hasValidActiveAddress()) {
      Get.find<ServiceAreaController>().getZoneList();
    }
    Get.find<SplashController>().updateLanguage(isInitial);
    update();
  }

  void loadCurrentLanguage() async {
    if (!AppConstants.enableLanguageSelection) {
      _applyEnglishOnly();
      update();
      return;
    }
    _localLanguages = [];
    _localLanguages.addAll(AppConstants.languages);
    filterLanguage(isInitial: true);
    update();
  }

  void _applyEnglishOnly() {
    final english = AppConstants.languages.first;
    _localLanguages = [english];
    _selectedIndex = 0;
    _locale = Locale(english.languageCode!, english.countryCode);
    _isLtr = true;
    sharedPreferences.setString(AppConstants.languageCode, english.languageCode!);
    sharedPreferences.setString(AppConstants.countryCode, english.countryCode!);
    apiClient.updateHeader(
      SecureTokenStorage.cachedToken().isEmpty ? null : SecureTokenStorage.cachedToken(),
      null,
      english.languageCode,
      Get.isRegistered<SplashController>() ? Get.find<SplashController>().getGuestId() : '',
    );
    _scheduleLocaleUpdate(_locale);
  }

  void _scheduleLocaleUpdate(Locale locale) {
    if (Get.locale?.languageCode == locale.languageCode &&
        Get.locale?.countryCode == locale.countryCode) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.locale?.languageCode != locale.languageCode ||
          Get.locale?.countryCode != locale.countryCode) {
        Get.updateLocale(locale);
      }
    });
  }

  void saveLanguage(Locale locale) async {
    sharedPreferences.setString(AppConstants.languageCode, locale.languageCode);
    sharedPreferences.setString(AppConstants.countryCode, locale.countryCode!);
    update();
  }

  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;
  void setSelectIndex(int index, {bool shouldUpdate = true}) {
    _selectedIndex = index;
    if(shouldUpdate){
      update();
    }
  }

  void filterLanguage({bool shouldUpdate = true, bool isChooseLanguage = false, bool isInitial = false, String? fromPage = ""}) {
    if (!AppConstants.enableLanguageSelection) {
      _applyEnglishOnly();
      if (shouldUpdate) {
        update();
      }
      return;
    }

    List<Language>  adminLanguageList = isInitial ? [] : Get.find<SplashController>().configModel.content?.languageList ?? [];

    bool showAllLocalLanguage = (AppConstants.languageCode.length == 1 || adminLanguageList.isEmpty) ? true : false;

    String? defaultLanguageCode;

    List<String> localLanguageCode = [];
    for (var element in AppConstants.languages) {
      localLanguageCode.add(element.languageCode!);
    }

    if( ((isChooseLanguage || isInitial) && fromPage != "menuDrawer" ) && adminLanguageList.length == 1 && localLanguageCode.contains(adminLanguageList[0].languageCode)){

      int index = AppConstants.languages.indexWhere((element) => element.languageCode == adminLanguageList[0].languageCode);

      if(index != -1){
        _locale = Locale( AppConstants.languages[index].languageCode!,AppConstants.languages[index].countryCode);
        _isLtr = _locale.languageCode != 'ar';
        Future.delayed(const Duration(milliseconds: 10), (){
          setLanguage(_locale, isInitial: true);
          Get.find<SplashController>().disableShowInitialLanguageScreen();
          if(Get.find<SplashController>().isShowOnboardingScreen()){
            Get.offAllNamed(RouteHelper.onBoardScreen);
          }else{
            Get.offAllNamed(RouteHelper.getInitialRoute());
          }
        });
      }

    } else{
      for (var defaultLanguage in adminLanguageList) {
        if(!localLanguageCode.contains(defaultLanguage.languageCode)){
          showAllLocalLanguage = true;
          break;
        }
        if(defaultLanguage.isDefault == true){
          defaultLanguageCode = defaultLanguage.languageCode;
        }
      }

      if(!showAllLocalLanguage){
        _localLanguages = [];
        _selectedIndex = 0;
        for (var element in adminLanguageList) {
          int index = AppConstants.languages.indexWhere((language) => language.languageCode == element.languageCode);
          if(index > -1){
            _localLanguages.add(AppConstants.languages[index]);
          }
        }


        if(isChooseLanguage && fromPage != "menuDrawer"){
          if(_localLanguages.indexWhere((e) => e.languageCode == defaultLanguageCode) != -1){
            _selectedIndex = _localLanguages.indexWhere((e) => e.languageCode == defaultLanguageCode);
          }else{
            _selectedIndex = 0;
          }
        }else{
          for(int index = 0; index< _localLanguages.length; index++) {
            if(_localLanguages[index].languageCode == sharedPreferences.getString(AppConstants.languageCode)) {
              _selectedIndex = index;
              break;
            }
          }
        }

      } else{


        if(defaultLanguageCode !=null && isChooseLanguage && fromPage != "menuDrawer"){
          for(int index = 0; index< _localLanguages.length; index++) {
            if(_localLanguages[index].languageCode == defaultLanguageCode) {
              _selectedIndex = index;
              break;
            }
          }

        }else{
          for(int index = 0; index< _localLanguages.length; index++) {
            if(_localLanguages[index].languageCode == sharedPreferences.getString(AppConstants.languageCode)) {
              _selectedIndex = index;
              break;
            }
          }
        }
      }
      _locale = Locale( _localLanguages[_selectedIndex].languageCode!, _localLanguages[_selectedIndex].countryCode);
      _isLtr = _locale.languageCode != 'ar';


      if(fromPage != "menuDrawer" && !isChooseLanguage){
        Future.delayed(const Duration(milliseconds: 1000), (){
          setLanguage(_locale, isInitial: true);
        });
      }
    }
  }

}