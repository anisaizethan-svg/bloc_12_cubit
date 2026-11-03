import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../services/user_api_provider.dart';

enum InternetState { connected, disconnected }

class InternetCubit extends Cubit<InternetState> {
  InternetCubit({
    Connectivity? connectivity,
    http.Client? client,
    Stream<List<ConnectivityResult>>? changes,
    Future<List<ConnectivityResult>> Function()? checkConnectivity,
    Future<bool> Function()? checkReachability,
    Duration interval = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       super(InternetState.disconnected) {
    final network = connectivity ?? Connectivity();
    _checkConnectivity = checkConnectivity ?? network.checkConnectivity;
    _checkReachability = checkReachability ?? _probe;
    _subscription = (changes ?? network.onConnectivityChanged).listen(
      (results) => unawaited(_refresh(results)),
      onError: (Object error) => unawaited(_refresh([ConnectivityResult.none])),
    );
    _timer = Timer.periodic(interval, (_) => unawaited(refresh()));
    unawaited(refresh());
  }

  final http.Client _client;
  late final Future<List<ConnectivityResult>> Function() _checkConnectivity;
  late final Future<bool> Function() _checkReachability;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  late final Timer _timer;
  int _revision = 0;

  Future<bool> _probe() async {
    // Check the actual API host over HTTPS; Wi-Fi alone is insufficient.
    final uri = UserApiProvider.usersUri.replace(
      path: '/users/1',
      queryParameters: {
        '_connectivity': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    final response = await _client
        .get(uri, headers: {'Cache-Control': 'no-cache'})
        .timeout(const Duration(seconds: 5));
    return response.statusCode == 200 &&
        response.body.contains('Leanne Graham');
  }

  Future<void> refresh() async {
    final revision = ++_revision;
    try {
      final results = await _checkConnectivity();
      if (!isClosed && revision == _revision) await _refresh(results);
    } catch (_) {
      if (!isClosed && revision == _revision) emit(InternetState.disconnected);
    }
  }

  Future<void> _refresh(List<ConnectivityResult> results) async {
    final revision = ++_revision;
    var connected = false;
    if (results.any((result) => result != ConnectivityResult.none)) {
      try {
        connected = await _checkReachability();
      } catch (_) {
        connected = false;
      }
    }
    if (!isClosed && revision == _revision) {
      emit(connected ? InternetState.connected : InternetState.disconnected);
    }
  }

  @override
  Future<void> close() async {
    _revision++;
    _timer.cancel();
    await _subscription.cancel();
    _client.close();
    return super.close();
  }
}
