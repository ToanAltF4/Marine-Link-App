part of 'profile_cubit.dart';

enum ProfileStatus {
  initial,
  loading,
  success,
  failure,
  updating,
  updateSuccess,
  updateFailure,
}

class ProfileState extends Equatable {
  final ProfileStatus status;
  final Profile? profile;
  final String? errorMessage;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    Profile? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}
