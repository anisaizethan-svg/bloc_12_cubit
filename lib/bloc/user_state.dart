import 'package:equatable/equatable.dart';

import '../model/user.dart';

abstract class UserState extends Equatable {
  const UserState();
  @override
  List<Object> get props => [];
}

class UserInitialState extends UserState {
  const UserInitialState();
}

class UserLoadingState extends UserState {
  const UserLoadingState();
}

class UserLoadedState extends UserState {
  UserLoadedState(List<User> users) : users = List.unmodifiable(users);
  final List<User> users;
  @override
  List<Object> get props => [users];
}

class UserErrorState extends UserState {
  const UserErrorState(this.message);
  final String message;
  @override
  List<Object> get props => [message];
}
