import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:marinelink/core/constants/app_strings.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/errors/user_facing_error.dart';
import '../../domain/profile.dart';
import '../../domain/profile_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository profileRepository;

  ProfileCubit({required this.profileRepository}) : super(const ProfileState());

  Future<void> loadProfile() async {
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    try {
      final response = await profileRepository.getProfile();

      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            status: ProfileStatus.success,
            profile: response.data,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ProfileStatus.failure,
            errorMessage: userFacingResponseMessage(
              response.message,
              fallback: AppStrings.profileLoadFailed,
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: userFacingErrorMessage(
            error,
            fallback: AppStrings.profileLoadFailed,
          ),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: AppStrings.profileLoadUnexpected,
        ),
      );
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
    String? businessAddress,
    String? avatarUrl,
  }) async {
    emit(state.copyWith(status: ProfileStatus.updating, clearError: true));
    try {
      final response = await profileRepository.updateProfile(
        fullName: fullName,
        phone: phone,
        businessAddress: businessAddress,
        avatarUrl: avatarUrl,
      );

      if (response.success && response.data != null) {
        emit(
          state.copyWith(
            status: ProfileStatus.updateSuccess,
            profile: response.data,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ProfileStatus.updateFailure,
            errorMessage: userFacingResponseMessage(
              response.message,
              fallback: AppStrings.profileUpdateFailedFallback,
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.updateFailure,
          errorMessage: userFacingErrorMessage(
            error,
            fallback: AppStrings.profileUpdateFailedFallback,
          ),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.updateFailure,
          errorMessage: AppStrings.profileUpdateUnexpected,
        ),
      );
    }
  }
}
