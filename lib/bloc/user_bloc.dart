import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/user_api_provider.dart';
import '../services/user_repository.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc(this.repository) : super(const UserInitialState()) {
    on<UserLoadEvent>(_load);
    on<UserClearEvent>((event, emit) {
      // Invalidate pending results so Clear remains effective during a request.
      _requestId++;
      emit(const UserInitialState());
    });
  }
  final UserRepository repository;
  int _requestId = 0;

  Future<void> _load(UserLoadEvent event, Emitter<UserState> emit) async {
    if (state is UserLoadingState) return;
    final requestId = ++_requestId;
    emit(const UserLoadingState());
    try {
      final users = await repository.getUsers();
      if (!emit.isDone && requestId == _requestId) emit(UserLoadedState(users));
    } catch (error) {
      if (!emit.isDone && requestId == _requestId) {
        emit(
          UserErrorState(
            error is UserApiException
                ? error.message
                : 'Unable to load users. Press Load to retry.',
          ),
        );
      }
    }
  }
}
