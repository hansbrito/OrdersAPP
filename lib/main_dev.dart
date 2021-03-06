import 'package:flutter/material.dart';

import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orders_app/services/user_repository.dart';

import 'app_config.dart';
import 'authentication/authentication.dart';
import 'splash/splash.dart';
import 'login/login.dart';
import 'home/home.dart';
import 'common/common.dart';

class SimpleBlocDelegate extends BlocDelegate {
  @override
  void onEvent(Bloc bloc, Object event) {
    super.onEvent(bloc, event);
    print(event);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    print(transition);
  }

  @override
  void onError(Bloc bloc, Object error, StackTrace stacktrace) {
    super.onError(bloc, error, stacktrace);
    print(error);
  }
}

void main() async {
  AppConfig().setAppConfig(
      appEnvironment: AppEnvironment.DEV,
      apiUrl: 'http://localhost:3000/api/v1/',
      loginUrl: 'http://localhost:3000/api/v1/authenticate');
  
  String userTheme = await UserRepository().getTheme();
  print('MainDev - 41');
  print(userTheme);
  AppConfig().setThemeConfig(userTheme);

  BlocSupervisor.delegate = SimpleBlocDelegate();
  runApp(App(userRepository: UserRepository()));
}

class App extends StatefulWidget {
  final UserRepository userRepository;

  App({Key key, @required this.userRepository}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  AuthenticationBloc _authenticationBloc;
  UserRepository get _userRepository => widget.userRepository;

  @override
  void initState() {
    _authenticationBloc = AuthenticationBloc(userRepository: _userRepository);
    _authenticationBloc.dispatch(AppStarted());
    super.initState();
  }

  @override
  void dispose() {
    _authenticationBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthenticationBloc>(
        bloc: _authenticationBloc,
        child: StreamBuilder<ThemeData>(
          initialData: AppConfig().themeData,
          stream: _authenticationBloc.outTheme,
          builder: (BuildContext context, AsyncSnapshot<ThemeData> snapshot) {
            UserRepository().persistTheme(AppConfig().themeName);
            return MaterialApp(
              theme: snapshot.data,
              home: BlocBuilder<AuthenticationEvent, AuthenticationState>(
                bloc: _authenticationBloc,
                builder: (BuildContext context, AuthenticationState state) {
                  if (state is AuthenticationUninitialized) {
                    return SplashPage();
                  }
                  if (state is AuthenticationAuthenticated) {
                    return HomePage();
                  }
                  if (state is AuthenticationUnauthenticated) {
                    return LoginPage(userRepository: _userRepository);
                  }
                  if (state is AuthenticationLoading) {
                    return LoadingIndicator();
                  }
                },
              ),
            );
          },
        ));
  }
}
