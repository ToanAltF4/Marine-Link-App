import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../core/utils/validators.dart';
import '../../domain/auth_repository.dart';

enum AuthFieldStatus { pure, valid, invalid, checking, serverInvalid }

class AuthValidatedField extends Equatable {
  final String value;
  final bool dirty;
  final AuthFieldStatus status;
  final String? message;

  const AuthValidatedField({
    this.value = '',
    this.dirty = false,
    this.status = AuthFieldStatus.pure,
    this.message,
  });

  bool get isValid => status == AuthFieldStatus.valid;

  bool get isChecking => status == AuthFieldStatus.checking;

  String? get visibleMessage {
    if (!dirty) return null;
    if (status == AuthFieldStatus.invalid ||
        status == AuthFieldStatus.serverInvalid) {
      return message;
    }
    return null;
  }

  AuthValidatedField copyWith({
    String? value,
    bool? dirty,
    AuthFieldStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return AuthValidatedField(
      value: value ?? this.value,
      dirty: dirty ?? this.dirty,
      status: status ?? this.status,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [value, dirty, status, message];
}

class AuthFormState extends Equatable {
  final AuthValidatedField loginEmailOrPhone;
  final AuthValidatedField loginPassword;
  final AuthValidatedField fullName;
  final AuthValidatedField email;
  final AuthValidatedField phone;
  final AuthValidatedField password;
  final AuthValidatedField confirmPassword;
  final AuthValidatedField storeName;
  final AuthValidatedField address;
  final AuthValidatedField taxCode;

  const AuthFormState({
    this.loginEmailOrPhone = const AuthValidatedField(),
    this.loginPassword = const AuthValidatedField(),
    this.fullName = const AuthValidatedField(),
    this.email = const AuthValidatedField(),
    this.phone = const AuthValidatedField(),
    this.password = const AuthValidatedField(),
    this.confirmPassword = const AuthValidatedField(),
    this.storeName = const AuthValidatedField(status: AuthFieldStatus.valid),
    this.address = const AuthValidatedField(),
    this.taxCode = const AuthValidatedField(status: AuthFieldStatus.valid),
  });

  bool get canSubmitLogin => loginEmailOrPhone.isValid && loginPassword.isValid;

  bool get canSubmitRegister =>
      fullName.isValid &&
      email.isValid &&
      phone.isValid &&
      password.isValid &&
      confirmPassword.isValid &&
      storeName.isValid &&
      address.isValid &&
      taxCode.isValid &&
      !email.isChecking &&
      !phone.isChecking;

  AuthFormState copyWith({
    AuthValidatedField? loginEmailOrPhone,
    AuthValidatedField? loginPassword,
    AuthValidatedField? fullName,
    AuthValidatedField? email,
    AuthValidatedField? phone,
    AuthValidatedField? password,
    AuthValidatedField? confirmPassword,
    AuthValidatedField? storeName,
    AuthValidatedField? address,
    AuthValidatedField? taxCode,
  }) {
    return AuthFormState(
      loginEmailOrPhone: loginEmailOrPhone ?? this.loginEmailOrPhone,
      loginPassword: loginPassword ?? this.loginPassword,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      storeName: storeName ?? this.storeName,
      address: address ?? this.address,
      taxCode: taxCode ?? this.taxCode,
    );
  }

  @override
  List<Object?> get props => [
    loginEmailOrPhone,
    loginPassword,
    fullName,
    email,
    phone,
    password,
    confirmPassword,
    storeName,
    address,
    taxCode,
  ];
}

class AuthFormCubit extends Cubit<AuthFormState> {
  final AuthRepository? authRepository;
  final Duration emailDebounceDuration;
  final Duration phoneDebounceDuration;
  Timer? _emailDebounce;
  Timer? _phoneDebounce;
  int _emailCheckVersion = 0;
  int _phoneCheckVersion = 0;

  AuthFormCubit({
    this.authRepository,
    this.emailDebounceDuration = const Duration(milliseconds: 650),
    this.phoneDebounceDuration = const Duration(milliseconds: 650),
  }) : super(const AuthFormState());

  void loginEmailOrPhoneChanged(String value) {
    emit(
      state.copyWith(
        loginEmailOrPhone: _validateDirty(
          value,
          _validateLoginEmailOrPhone(value),
        ),
      ),
    );
  }

  void loginPasswordChanged(String value) {
    emit(
      state.copyWith(
        loginPassword: _validateDirty(value, Validators.password(value)),
      ),
    );
  }

  void registerFullNameChanged(String value) {
    emit(
      state.copyWith(
        fullName: _validateDirty(
          value,
          Validators.required(value, fieldName: AppStrings.fullNameField),
        ),
      ),
    );
  }

  void registerEmailChanged(String value) {
    _emailDebounce?.cancel();
    final version = ++_emailCheckVersion;
    final validationMessage = Validators.email(value);
    if (validationMessage != null) {
      emit(state.copyWith(email: _validateDirty(value, validationMessage)));
      _recheckDirtyPhone();
      return;
    }

    final normalized = value.trim().toLowerCase();
    if (authRepository == null) {
      emit(
        state.copyWith(
          email: AuthValidatedField(
            value: normalized,
            dirty: true,
            status: AuthFieldStatus.valid,
          ),
        ),
      );
      _recheckDirtyPhone();
      return;
    }

    emit(
      state.copyWith(
        email: AuthValidatedField(
          value: normalized,
          dirty: true,
          status: AuthFieldStatus.checking,
        ),
      ),
    );
    _recheckDirtyPhone();

    _emailDebounce = Timer(emailDebounceDuration, () async {
      try {
        final available = await authRepository!.isEmailAvailable(
          email: normalized,
        );
        if (isClosed || version != _emailCheckVersion) return;
        emit(
          state.copyWith(
            email: available
                ? AuthValidatedField(
                    value: normalized,
                    dirty: true,
                    status: AuthFieldStatus.valid,
                  )
                : AuthValidatedField(
                    value: normalized,
                    dirty: true,
                    status: AuthFieldStatus.serverInvalid,
                    message: AppStrings.emailAlreadyUsed,
                  ),
          ),
        );
      } catch (_) {
        if (isClosed || version != _emailCheckVersion) return;
        emit(
          state.copyWith(
            email: AuthValidatedField(
              value: normalized,
              dirty: true,
              status: AuthFieldStatus.valid,
            ),
          ),
        );
      }
    });
  }

  void registerPhoneChanged(String value) {
    _phoneDebounce?.cancel();
    final version = ++_phoneCheckVersion;
    final validationMessage = Validators.phone(value);
    if (validationMessage != null) {
      emit(state.copyWith(phone: _validateDirty(value, validationMessage)));
      return;
    }

    final normalized = value.trim();
    if (authRepository == null) {
      emit(
        state.copyWith(
          phone: AuthValidatedField(
            value: normalized,
            dirty: true,
            status: AuthFieldStatus.valid,
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        phone: AuthValidatedField(
          value: normalized,
          dirty: true,
          status: AuthFieldStatus.checking,
        ),
      ),
    );

    final email = _emailForPhoneAvailability();
    _phoneDebounce = Timer(phoneDebounceDuration, () async {
      try {
        final available = await authRepository!.isPhoneAvailable(
          phone: normalized,
          email: email,
        );
        if (isClosed || version != _phoneCheckVersion) return;
        emit(
          state.copyWith(
            phone: available
                ? AuthValidatedField(
                    value: normalized,
                    dirty: true,
                    status: AuthFieldStatus.valid,
                  )
                : AuthValidatedField(
                    value: normalized,
                    dirty: true,
                    status: AuthFieldStatus.serverInvalid,
                    message: AppStrings.phoneAlreadyUsed,
                  ),
          ),
        );
      } catch (_) {
        if (isClosed || version != _phoneCheckVersion) return;
        emit(
          state.copyWith(
            phone: AuthValidatedField(
              value: normalized,
              dirty: true,
              status: AuthFieldStatus.valid,
            ),
          ),
        );
      }
    });
  }

  void registerPasswordChanged(String value) {
    final password = _validateDirty(value, Validators.password(value));
    final confirmPassword = state.confirmPassword.dirty
        ? _validateDirty(
            state.confirmPassword.value,
            Validators.confirmPassword(state.confirmPassword.value, value),
          )
        : state.confirmPassword;
    emit(state.copyWith(password: password, confirmPassword: confirmPassword));
  }

  void registerConfirmPasswordChanged(String value) {
    emit(
      state.copyWith(
        confirmPassword: _validateDirty(
          value,
          Validators.confirmPassword(value, state.password.value),
        ),
      ),
    );
  }

  void registerStoreNameChanged(String value) {
    emit(
      state.copyWith(
        storeName: AuthValidatedField(
          value: value,
          dirty: value.trim().isNotEmpty,
          status: AuthFieldStatus.valid,
        ),
      ),
    );
  }

  void registerAddressChanged(String value) {
    emit(
      state.copyWith(address: _validateDirty(value, Validators.address(value))),
    );
  }

  void registerTaxCodeChanged(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      emit(
        state.copyWith(
          taxCode: const AuthValidatedField(status: AuthFieldStatus.valid),
        ),
      );
      return;
    }
    emit(
      state.copyWith(taxCode: _validateDirty(value, Validators.taxCode(value))),
    );
  }

  void registerEmailServerInvalid(String message) {
    emit(
      state.copyWith(
        email: state.email.copyWith(
          dirty: true,
          status: AuthFieldStatus.serverInvalid,
          message: message,
        ),
      ),
    );
  }

  void registerPhoneServerInvalid(String message) {
    emit(
      state.copyWith(
        phone: state.phone.copyWith(
          dirty: true,
          status: AuthFieldStatus.serverInvalid,
          message: message,
        ),
      ),
    );
  }

  String? _validateLoginEmailOrPhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return AppStrings.emailOrPhoneRequired;
    }
    if (RegExp(r'^\+?\d+$').hasMatch(trimmed)) {
      return Validators.phone(trimmed);
    }
    return Validators.email(trimmed);
  }

  AuthValidatedField _validateDirty(String value, String? message) {
    return AuthValidatedField(
      value: value,
      dirty: true,
      status: message == null ? AuthFieldStatus.valid : AuthFieldStatus.invalid,
      message: message,
    );
  }

  void _recheckDirtyPhone() {
    if (!state.phone.dirty) return;
    if (Validators.phone(state.phone.value) != null) return;
    registerPhoneChanged(state.phone.value);
  }

  String? _emailForPhoneAvailability() {
    final email = state.email.value.trim().toLowerCase();
    if (Validators.email(email) != null) return null;
    return email;
  }

  @override
  Future<void> close() {
    _emailDebounce?.cancel();
    _phoneDebounce?.cancel();
    return super.close();
  }
}
