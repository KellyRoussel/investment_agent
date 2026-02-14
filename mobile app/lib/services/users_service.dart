import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/user.dart';

class UsersService {
  final ApiClient _api;

  UsersService(this._api);

  Future<User> updateUser(String userId, UserUpdate data) async {
    final response = await _api.patch(
      ApiConstants.updateUser(userId),
      data: data.toJson(),
    );
    return User.fromJson(response.data as Map<String, dynamic>);
  }
}
