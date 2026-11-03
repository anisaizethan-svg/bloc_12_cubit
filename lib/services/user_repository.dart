import '../model/user.dart';
import 'user_api_provider.dart';

class UserRepository {
  UserRepository(this.apiProvider);
  final UserApiProvider apiProvider;
  Future<List<User>> getUsers() => apiProvider.getUsers();
  void close() => apiProvider.close();
}
