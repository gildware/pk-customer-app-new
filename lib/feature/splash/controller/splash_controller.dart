import 'package:demandium/api/local/cache_response.dart';
import 'package:demandium/helper/data_sync_helper.dart';
import 'package:get/get.dart';
import 'package:demandium/util/core_export.dart';

class SplashController extends GetxController implements GetxService {
  final SplashRepo splashRepo;
  SplashController({required this.splashRepo});

  ConfigModel? _configModel = ConfigModel();
  bool _firstTimeConnectionCheck = true;
  bool _hasConnection = true;
  bool _isLoading = false;
  DataSourceEnum _currentDataSource = DataSourceEnum.local;


  bool get isLoading => _isLoading;
  ConfigModel get configModel => _configModel!;
  DateTime get currentTime => DateTime.now();
  bool get firstTimeConnectionCheck => _firstTimeConnectionCheck;
  bool get hasConnection => _hasConnection;
  DataSourceEnum get currentDataSource => _currentDataSource;

  bool savedCookiesData = false;

  Future<bool> getConfigData() async {
    _hasConnection = true;
    bool configLoaded = false;

    await DataSyncHelper.fetchAndSyncData(
      fetchFromLocal: ()=>  splashRepo.getConfigData<CacheResponseData>( source: DataSourceEnum.local),
      fetchFromClient: ()=>  splashRepo.getConfigData(source: DataSourceEnum.client),
      onResponse: (data, source) {
        configLoaded = true;
        _currentDataSource = source;

        try {
          _configModel = ConfigModel.fromJson(data);

          bool isWebMaintenanceDisabled = (_configModel?.content?.maintenanceMode?.maintenanceStatus == 0 || _configModel?.content?.maintenanceMode?.selectedMaintenanceSystem?.webApp == 0) && kIsWeb;
          bool isAppMaintenanceDisabled = (_configModel?.content?.maintenanceMode?.maintenanceStatus == 0 || _configModel?.content?.maintenanceMode?.selectedMaintenanceSystem?.mobileApp == 0) && !kIsWeb;

          if(_configModel?.content?.maintenanceMode?.maintenanceStatus == 1
              && _configModel?.content?.maintenanceMode?.selectedMaintenanceSystem?.mobileApp == 1 && source == DataSourceEnum.client  && !AppConstants.avoidMaintenanceMode && !kIsWeb ){
            runAfterFrame(() => Get.offAllNamed(RouteHelper.getMaintenanceRoute()));
          } else if(_configModel?.content?.maintenanceMode?.maintenanceStatus == 1
              && _configModel?.content?.maintenanceMode?.selectedMaintenanceSystem?.webApp == 1 && source == DataSourceEnum.client  && !AppConstants.avoidMaintenanceMode && kIsWeb ){
            runAfterFrame(() => Get.offAllNamed(RouteHelper.getMaintenanceRoute()));
          }
          else if((Get.currentRoute.contains(RouteHelper.maintenance) &&  (isAppMaintenanceDisabled || isWebMaintenanceDisabled))) {
            runAfterFrame(() => Get.offAllNamed(RouteHelper.getInitialRoute()));
          }
          else if(_configModel?.content?.maintenanceMode?.maintenanceStatus == 0){
            if((_configModel?.content?.maintenanceMode?.selectedMaintenanceSystem?.mobileApp == 1 && !kIsWeb) ||( _configModel?.content?.maintenanceMode?.selectedMaintenanceSystem?.webApp == 1 && kIsWeb)){
              final startDate = _configModel?.content?.maintenanceMode?.maintenanceTypeAndDuration?.startDate;
              if(_configModel?.content?.maintenanceMode?.maintenanceTypeAndDuration?.maintenanceDuration == 'customize'
                  && startDate != null && startDate.isNotEmpty){

                final now = DateTime.now();
                final specifiedDateTime = DateTime.tryParse(startDate);
                if (specifiedDateTime != null) {
                  final difference = specifiedDateTime.difference(now);
                  if(difference.inMinutes > 0 && (difference.inMinutes < 60 || difference.inMinutes == 60)){
                    _startTimer(specifiedDateTime);
                  }
                }
              }
            }
          }
        } catch (e, stack) {
          ErrorLogger.record(e, stack, reason: 'SplashController config onResponse');
        }

        update();
        update(['home_layout']);
        if (source == DataSourceEnum.client) {
          MobileAppIconHelper.invalidateCache();
          final context = Get.context;
          if (context != null && context.mounted) {
            unawaited(MobileAppIconHelper.ensureReady(context));
          }
        }
      },
      suppressErrorWhenLocalSucceeded: true,
    );

    if (!configLoaded) {
      _hasConnection = false;
      update();
      return false;
    }

    return true;
  }

  /// Fetches the latest config from the server without waiting on local cache.
  Future<bool> refreshConfigFromServer() async {
    try {
      final clientResponse = await splashRepo.getConfigData(source: DataSourceEnum.client);
      if (!clientResponse.isSuccess || clientResponse.response?.statusCode != 200) {
        return false;
      }

      _currentDataSource = DataSourceEnum.client;
      _configModel = ConfigModel.fromJson(clientResponse.response?.body);
      update();
      update(['home_layout']);
      MobileAppIconHelper.invalidateCache();
      final context = Get.context;
      if (context != null && context.mounted) {
        unawaited(MobileAppIconHelper.ensureReady(context));
      }
      if (Get.isRegistered<CompanyAvailabilityConfigWatcher>()) {
        await Get.find<CompanyAvailabilityConfigWatcher>().onConfigRefreshed();
      }
      return true;
    } catch (e, stack) {
      ErrorLogger.record(e, stack, reason: 'SplashController refreshConfigFromServer');
      return false;
    }
  }


  void _startTimer (DateTime startTime){
    Timer.periodic(const Duration(seconds: 30), (Timer timer){
      DateTime now = DateTime.now();
      if (now.isAfter(startTime) || now.isAtSameMomentAs(startTime)) {
        timer.cancel();
        Get.offAllNamed(RouteHelper.getMaintenanceRoute());
      }
    });
  }


  Future<bool> initSharedData() {
    return splashRepo.initSharedData();
  }

  Future<void> setGuestId(String guestId) {
    return splashRepo.setGuestId(guestId);
  }

  String getGuestId (){
    return splashRepo.getGuestId();
  }




  void setFirstTimeConnectionCheck(bool isChecked) {
    _firstTimeConnectionCheck = isChecked;
  }



  void saveCookiesData(bool data) {
    splashRepo.saveCookiesData(data);
    savedCookiesData = true;
    update();
  }

  void getCookiesData(){
    savedCookiesData = splashRepo.getSavedCookiesData();
    update();
  }


  void cookiesStatusChange(String? data) {
    if(data != null){
      splashRepo.sharedPreferences!.setString(AppConstants.cookiesManagement, data);
    }
  }

  bool getAcceptCookiesStatus(String data) => splashRepo.sharedPreferences!.getString(AppConstants.cookiesManagement) != null
      && splashRepo.sharedPreferences!.getString(AppConstants.cookiesManagement) == data;

  void disableShowOnboardingScreen() {
    splashRepo.disableShowOnboardingScreen();
  }

  bool  isShowOnboardingScreen() {
    return splashRepo.isShowOnboardingScreen();
  }

  void  disableShowInitialLanguageScreen() {
    splashRepo.disableShowInitialLanguageScreen();
  }

  bool isShowInitialLanguageScreen() {
    return splashRepo.isShowInitialLanguageScreen();
  }


  Future<void> updateLanguage(bool isInitial) async {
    Response response = await splashRepo.updateLanguage(getGuestId());

    if(!isInitial){
      if(response.statusCode == 200 && response.body['response_code'] == "default_200"){

      }else{
        customSnackBar("${response.body['message']}");
      }
    }

  }

  Future<void> addError404UrlToServer(String url) async {
    Response response = await splashRepo.addError404UrlToServer(url);
    if (kDebugMode) {
      print("Error Url Add Response Status : ${response.statusCode}");
    }
  } 
  
  Future<ResponseModel> newsLetterSubscription({required String email}) async {
    _isLoading  = true;
    update();
    Response response = await splashRepo.newsLetterSubscription(email: email);
    if(response.statusCode == 200){
      _isLoading  = false;
      update();
      return ResponseModel(true, "successfully_subscribed".tr);
    }else if(response.statusCode == 400){
      _isLoading  = false;
      update();
      return ResponseModel(false, "${response.body['errors'][0]['message'] ?? ""}");
    }else{
      _isLoading  = false;
      update();
      return ResponseModel(false, "${response.body['message'] ?? ""}");
    }

  }

}
