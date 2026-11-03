import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/user_bloc.dart';
import 'cubit/internet_cubit.dart';
import 'pages/home_page.dart';
import 'services/user_api_provider.dart';
import 'services/user_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _repository = UserRepository(UserApiProvider());

  @override
  void dispose() {
    _repository.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepositoryProvider.value(
    value: _repository,
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => UserBloc(context.read<UserRepository>()),
        ),
        BlocProvider(create: (_) => InternetCubit()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'User List',
        theme: ThemeData(
          useMaterial3: false,
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 4,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(64, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        home: const HomePage(),
      ),
    ),
  );
}
