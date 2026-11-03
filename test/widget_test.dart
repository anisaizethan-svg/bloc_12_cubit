import 'dart:async';

import 'package:bloc_12_cubit/bloc/user_bloc.dart';
import 'package:bloc_12_cubit/bloc/user_event.dart';
import 'package:bloc_12_cubit/bloc/user_state.dart';
import 'package:bloc_12_cubit/cubit/internet_cubit.dart';
import 'package:bloc_12_cubit/pages/home_page.dart';
import 'package:bloc_12_cubit/services/user_api_provider.dart';
import 'package:bloc_12_cubit/services/user_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const payload =
    '[{"id":1,"name":"Test User","email":"test@example.com","phone":"123"}]';
Future<void> settleEvents() => Future<void>.delayed(Duration.zero);

void main() {
  test('API validates HTTP status and malformed data', () async {
    for (final response in [
      http.Response('error', 500),
      http.Response('{}', 200),
      http.Response('[{}]', 200),
    ]) {
      final api = UserApiProvider(client: MockClient((_) async => response));
      await expectLater(api.getUsers(), throwsA(isA<UserApiException>()));
      api.close();
    }
  });

  test(
    'Clear invalidates pending results and duplicate loads are ignored',
    () async {
      var calls = 0;
      final pending = Completer<http.Response>();
      final repository = UserRepository(
        UserApiProvider(
          client: MockClient((_) {
            calls++;
            return pending.future;
          }),
        ),
      );
      final bloc = UserBloc(repository);
      bloc.add(const UserLoadEvent());
      bloc.add(const UserLoadEvent());
      await settleEvents();
      expect(calls, 1);
      expect(bloc.state, isA<UserLoadingState>());
      bloc.add(const UserClearEvent());
      await settleEvents();
      pending.complete(http.Response(payload, 200));
      await settleEvents();
      expect(bloc.state, isA<UserInitialState>());
      await bloc.close();
      repository.close();
    },
  );

  test('failure can be retried successfully', () async {
    var calls = 0;
    final repository = UserRepository(
      UserApiProvider(
        client: MockClient(
          (_) async => ++calls == 1
              ? http.Response('', 503)
              : http.Response(payload, 200),
        ),
      ),
    );
    final bloc = UserBloc(repository);
    bloc.add(const UserLoadEvent());
    await settleEvents();
    expect(bloc.state, isA<UserErrorState>());
    bloc.add(const UserLoadEvent());
    await settleEvents();
    expect((bloc.state as UserLoadedState).users.single.name, 'Test User');
    await bloc.close();
    repository.close();
  });

  testWidgets('Load, Clear, reload, and connectivity title work', (
    tester,
  ) async {
    final changes = StreamController<List<ConnectivityResult>>();
    var reachable = true;
    final internet = InternetCubit(
      changes: changes.stream,
      checkConnectivity: () async => [ConnectivityResult.wifi],
      checkReachability: () async => reachable,
    );
    final repository = UserRepository(
      UserApiProvider(
        client: MockClient((_) async => http.Response(payload, 200)),
      ),
    );
    final bloc = UserBloc(repository);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: internet),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('User List (в сети)'), findsOneWidget);
    expect(find.text('Test User'), findsNothing);
    await tester.tap(find.text('Load'));
    await tester.pumpAndSettle();
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('Email: test@example.com'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Test User'), findsNothing);
    await tester.tap(find.text('Load'));
    await tester.pumpAndSettle();
    expect(find.text('Test User'), findsOneWidget);
    reachable = false;
    changes.add([ConnectivityResult.wifi]);
    await tester.pumpAndSettle();
    expect(find.text('User List (нет сети)'), findsOneWidget);
    reachable = true;
    changes.add([ConnectivityResult.wifi]);
    await tester.pumpAndSettle();
    expect(find.text('User List (в сети)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await internet.close();
      expect(changes.hasListener, isFalse);
      await changes.close();
      await bloc.close();
      repository.close();
    });
  });
}
