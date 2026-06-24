import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class WalletRepo{
  final ApiClient apiClient;
  WalletRepo({required this.apiClient});

  Future<Response> getWalletTransactionData(int offset, String type) async {
    return await apiClient.getData("${AppConstants.walletTransactionData}?limit=10&offset=$offset&type=$type");
  }

  Future<Response> getBonusList() async {
    return await apiClient.getData(AppConstants.bonusUri);
  }

  Future<void> setWalletAccessToken(String token){
    return SecureTokenStorage.writeWalletPaymentToken(token);
  }

  Future<String> getWalletAccessToken(){
    return SecureTokenStorage.readWalletPaymentToken();
  }

  String getWalletAccessTokenSync(){
    return SecureTokenStorage.cachedWalletPaymentToken();
  }
}
