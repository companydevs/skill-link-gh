import 'package:flutter_riverpod/legacy.dart';

import '../../domain/models/user_model.dart';

class RegistrationState {
  final bool isLoading;
  final String? errorMessage;

  RegistrationState({this.isLoading = false, this.errorMessage});
}

class RegistrationNotifier extends StateNotifier<RegistrationState> {
  RegistrationNotifier() : super(RegistrationState());

  Future<void> register(UserModel user) async {
    state = RegistrationState(isLoading: true);
    try {
      await Future.delayed(const Duration(seconds: 2));
      state = RegistrationState(isLoading: false);
    } catch (e) {
      state = RegistrationState(isLoading: false, errorMessage: e.toString());
    }
  }
}

final registrationProvider =
    StateNotifierProvider<RegistrationNotifier, RegistrationState>(
        (ref) => RegistrationNotifier());
