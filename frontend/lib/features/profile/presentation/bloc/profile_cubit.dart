import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../auth/domain/user.dart';
import '../../domain/profile_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository profileRepository;

  ProfileCubit({required this.profileRepository}) : super(const ProfileState());

  Future<void> loadProfile() async {
    emit(state.copyWith(status: ProfileStatus.loading));
    final response = await profileRepository.getProfile();
    
    if (response.success && response.data != null) {
      emit(state.copyWith(status: ProfileStatus.success, user: response.data));
    } else {
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: response.message,
      ));
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
    String? businessAddress,
  }) async {
    emit(state.copyWith(status: ProfileStatus.updating));
    final response = await profileRepository.updateProfile(
      fullName: fullName,
      phone: phone,
      businessAddress: businessAddress,
    );

    if (response.success && response.data != null) {
      emit(state.copyWith(status: ProfileStatus.updateSuccess, user: response.data));
    } else {
      emit(state.copyWith(
        status: ProfileStatus.updateFailure,
        errorMessage: response.message,
      ));
    }
  }
}
