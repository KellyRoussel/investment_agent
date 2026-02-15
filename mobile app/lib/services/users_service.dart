import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../core/storage/secure_storage.dart';
import '../models/user.dart';

class UsersService {
  final ApiClient _api;
  final SecureStorage _storage;

  UsersService(this._api, this._storage);

  Future<InvestmentProfile> updateInvestmentProfile(InvestmentProfileUpdate data) async {
    final response = await _api.patch(
      ApiConstants.investmentProfile,
      data: data.toJson(),
    );
    final profile = InvestmentProfile.fromJson(response.data as Map<String, dynamic>);
    await _storage.setInvestmentProfile(profile.toJson());
    return profile;
  }

  Future<InvestmentProfile> fetchProfile() async {
    final response = await _api.get(ApiConstants.investmentProfile);
    final profile = InvestmentProfile.fromJson(response.data as Map<String, dynamic>);
    await _storage.setInvestmentProfile(profile.toJson());
    return profile;
  }

  Future<InvestmentProfile?> getStoredProfile() async {
    final data = await _storage.getInvestmentProfile();
    if (data == null) return null;
    return InvestmentProfile.fromJson(data);
  }
}
