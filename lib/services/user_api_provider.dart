import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/user.dart';

class UserApiException implements Exception {
  const UserApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class UserApiProvider {
  UserApiProvider({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static final usersUri = Uri.https('jsonplaceholder.typicode.com', '/users');

  Future<List<User>> getUsers() async {
    try {
      final response = await _client
          .get(usersUri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw UserApiException(
          'Server error (${response.statusCode}). Press Load to retry.',
        );
      }
      final json = jsonDecode(response.body) as List<dynamic>;
      return json
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw const UserApiException(
        'The request timed out. Press Load to retry.',
      );
    } on http.ClientException {
      throw const UserApiException(
        'Unable to connect. Check your internet and press Load.',
      );
    } on FormatException {
      throw const UserApiException(
        'The server returned invalid data. Press Load to retry.',
      );
    } on TypeError {
      throw const UserApiException(
        'The server returned unexpected user data. Press Load to retry.',
      );
    }
  }

  void close() => _client.close();
}
