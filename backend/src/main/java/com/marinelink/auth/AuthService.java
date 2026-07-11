package com.marinelink.auth;

import com.marinelink.auth.google.GoogleTokenVerifier;
import com.marinelink.auth.google.GoogleUserInfo;
import com.marinelink.auth.otp.EmailOtpService;
import com.marinelink.common.exception.BusinessException;
import com.marinelink.common.exception.ConflictException;
import com.marinelink.common.security.JwtTokenProvider;
import com.marinelink.users.Role;
import com.marinelink.users.RoleRepository;
import com.marinelink.users.User;
import com.marinelink.users.UserRepository;
import com.marinelink.users.UserStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthService {

    private static final String DEFAULT_ROLE = "USER";
    private static final String INVALID_CREDENTIALS =
            "Email/số điện thoại hoặc mật khẩu không đúng";

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final EmailOtpService emailOtpService;
    private final GoogleTokenVerifier googleTokenVerifier;

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        String emailOrPhone = request.emailOrPhone().trim();
        User user = userRepository.findActiveByEmailOrPhone(emailOrPhone)
                .orElseThrow(() -> unauthorized(INVALID_CREDENTIALS));

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw unauthorized(INVALID_CREDENTIALS);
        }

        requireLoginAllowed(user);

        List<String> roles = List.of(user.getRoleCode());
        String token = jwtTokenProvider.generateToken(user.getPublicId(), roles);

        return new LoginResponse(
                token,
                "Bearer",
                jwtTokenProvider.getExpirationSeconds(),
                AuthUserResponse.from(user));
    }

    /**
     * Sign in (or sign up) with Google. The Google ID token is verified, then
     * the account is matched by email — created as ACTIVE if new (Google already
     * verified the email), or logged in if it exists. Returns an app JWT.
     */
    @Transactional
    public LoginResponse googleLogin(GoogleLoginRequest request) {
        GoogleUserInfo info = googleTokenVerifier.verify(request.idToken().trim());
        if (!info.emailVerified()) {
            throw new BusinessException("Email Google chưa được xác thực", HttpStatus.FORBIDDEN);
        }
        String email = info.email().trim().toLowerCase(Locale.ROOT);

        User user = userRepository.findActiveByEmailOrPhone(email)
                .map(existing -> reconcileGoogleUser(existing))
                .orElseGet(() -> createGoogleUser(info, email));

        List<String> roles = List.of(user.getRoleCode());
        String token = jwtTokenProvider.generateToken(user.getPublicId(), roles);

        return new LoginResponse(
                token,
                "Bearer",
                jwtTokenProvider.getExpirationSeconds(),
                AuthUserResponse.from(user));
    }

    private User reconcileGoogleUser(User user) {
        if (user.getStatus() == UserStatus.DISABLED) {
            throw new BusinessException("Tài khoản không hoạt động", HttpStatus.FORBIDDEN);
        }
        if (user.getStatus() == UserStatus.PENDING_APPROVAL) {
            throw new BusinessException("Tài khoản đang chờ duyệt", HttpStatus.FORBIDDEN);
        }
        // Google has verified the email — clear a pending-verification state.
        if (user.getStatus() == UserStatus.PENDING_VERIFICATION) {
            user.setStatus(UserStatus.ACTIVE);
            return userRepository.save(user);
        }
        return user;
    }

    private User createGoogleUser(GoogleUserInfo info, String email) {
        Role userRole = roleRepository.findByCode(DEFAULT_ROLE)
                .orElseThrow(() -> new BusinessException(
                        "Role USER chưa được cấu hình",
                        HttpStatus.INTERNAL_SERVER_ERROR));

        User user = User.builder()
                .publicId(UUID.randomUUID())
                .role(userRole)
                .fullName(resolveGoogleName(info, email))
                .email(email)
                .phone(null) // Google does not provide a phone; user completes profile later
                .passwordHash(passwordEncoder.encode(UUID.randomUUID().toString())) // unusable
                .status(UserStatus.ACTIVE)
                .avatarUrl(info.picture())
                .build();
        return userRepository.save(user);
    }

    private String resolveGoogleName(GoogleUserInfo info, String email) {
        if (info.name() != null && !info.name().isBlank()) {
            return info.name().trim();
        }
        int at = email.indexOf('@');
        return at > 0 ? email.substring(0, at) : email;
    }

    @Transactional
    public RegisterResponse register(RegisterRequest request) {
        String email = request.email().trim().toLowerCase(Locale.ROOT);
        String phone = request.phone().trim();

        return userRepository.findByEmailAndStatus(email, UserStatus.PENDING_VERIFICATION)
                .map(user -> refreshPendingRegistration(user, request, email, phone))
                .orElseGet(() -> createPendingRegistration(request, email, phone));
    }

    @Transactional(readOnly = true)
    public EmailAvailabilityResponse emailAvailability(String requestedEmail) {
        String email = requestedEmail.trim().toLowerCase(Locale.ROOT);
        boolean available = !userRepository.existsVerifiedByEmail(email);
        String message = available ? "Email có thể sử dụng" : "Email đã được sử dụng";
        return new EmailAvailabilityResponse(available, message);
    }

    @Transactional(readOnly = true)
    public PhoneAvailabilityResponse phoneAvailability(String requestedPhone, String requestedEmail) {
        String phone = requestedPhone.trim();
        String email = trimToNull(requestedEmail);

        boolean available = false;
        if (email != null) {
            available = userRepository.findByEmailAndStatus(
                            email.toLowerCase(Locale.ROOT),
                            UserStatus.PENDING_VERIFICATION)
                    .map(user -> !userRepository.existsActiveByPhoneAndPublicIdNot(phone, user.getPublicId()))
                    .orElse(false);
        }
        if (email == null || !available) {
            available = !userRepository.existsActiveByPhone(phone);
        }

        String message = available ? "Số điện thoại có thể sử dụng" : "Số điện thoại đã được sử dụng";
        return new PhoneAvailabilityResponse(available, message);
    }

    private RegisterResponse refreshPendingRegistration(
            User user,
            RegisterRequest request,
            String email,
            String phone) {
        if (userRepository.existsActiveByPhoneAndPublicIdNot(phone, user.getPublicId())) {
            throw new ConflictException("Số điện thoại đã được sử dụng");
        }

        user.setRole(findDefaultUserRole());
        user.setFullName(request.fullName().trim());
        user.setEmail(email);
        user.setPhone(phone);
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setStatus(UserStatus.PENDING_VERIFICATION);
        user.setStoreName(trimToNull(request.storeName()));
        user.setBusinessAddress(trimToNull(request.businessAddress()));
        user.setTaxCode(trimToNull(request.taxCode()));

        User savedUser = persistPendingRegistrationAndSendOtp(user, email);
        return RegisterResponse.from(savedUser);
    }

    private RegisterResponse createPendingRegistration(
            RegisterRequest request,
            String email,
            String phone) {
        if (userRepository.existsVerifiedByEmail(email)) {
            throw new ConflictException("Email đã được sử dụng");
        }
        if (userRepository.existsActiveByPhone(phone)) {
            throw new ConflictException("Số điện thoại đã được sử dụng");
        }

        Role userRole = findDefaultUserRole();
        User user = User.builder()
                .publicId(UUID.randomUUID())
                .role(userRole)
                .fullName(request.fullName().trim())
                .email(email)
                .phone(phone)
                .passwordHash(passwordEncoder.encode(request.password()))
                .status(UserStatus.PENDING_VERIFICATION)
                .storeName(trimToNull(request.storeName()))
                .businessAddress(trimToNull(request.businessAddress()))
                .taxCode(trimToNull(request.taxCode()))
                .build();

        User savedUser = persistPendingRegistrationAndSendOtp(user, email);
        return RegisterResponse.from(savedUser);
    }

    private User persistPendingRegistrationAndSendOtp(User user, String email) {
        User savedUser = userRepository.saveAndFlush(user); // flush immediately so the user row
                                                            // is visible to the REQUIRES_NEW OTP transaction

        // sendOtp runs in its own REQUIRES_NEW transaction, committing the OTP record
        // independently so it is readable by the client's verify request right away.
        // If email sending fails the user record is already persisted (outer tx commits later).
        emailOtpService.sendOtp(email);

        return savedUser;
    }

    private Role findDefaultUserRole() {
        return roleRepository.findByCode(DEFAULT_ROLE)
                .orElseThrow(() -> new BusinessException(
                        "Role USER chưa được cấu hình",
                        HttpStatus.INTERNAL_SERVER_ERROR));
    }

    /**
     * Verifies the OTP code for the given email and activates the user account.
     */
    @Transactional
    public void verifyEmail(VerifyEmailRequest request) {
        String email = request.email().trim().toLowerCase(Locale.ROOT);

        // Validate OTP first (throws BusinessException on failure)
        emailOtpService.verifyOtp(email, request.otpCode());

        User user = userRepository.findByEmailAndStatus(email, UserStatus.PENDING_VERIFICATION)
                .orElseThrow(() -> new BusinessException(
                        "Không tìm thấy tài khoản đang chờ xác thực với email này",
                        HttpStatus.NOT_FOUND));

        user.setStatus(UserStatus.PENDING_APPROVAL);
        userRepository.save(user);
    }

    /**
     * Resends a new OTP to the given email if the account is still pending verification.
     */
    @Transactional
    public void resendOtp(ResendOtpRequest request) {
        String email = request.email().trim().toLowerCase(Locale.ROOT);

        userRepository.findByEmailAndStatus(email, UserStatus.PENDING_VERIFICATION)
                .orElseThrow(() -> new BusinessException(
                        "Không tìm thấy tài khoản đang chờ xác thực với email này",
                        HttpStatus.NOT_FOUND));

        emailOtpService.sendOtp(email);
    }

    @Transactional
    public void changePassword(UUID publicId, ChangePasswordRequest request) {
        User user = userRepository.findActiveByPublicId(publicId)
                .orElseThrow(() -> new BusinessException("Không tìm thấy người dùng", HttpStatus.NOT_FOUND));

        if (!passwordEncoder.matches(request.oldPassword(), user.getPasswordHash())) {
            throw new BusinessException("Mật khẩu hiện tại không chính xác", HttpStatus.BAD_REQUEST);
        }

        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);
    }

    /**
     * Quên mật khẩu: gửi OTP đặt lại tới email nếu có tài khoản đang hoạt động.
     * Luôn trả về thành công để không tiết lộ email có tồn tại hay không.
     */
    @Transactional
    public void forgotPassword(ForgotPasswordRequest request) {
        String email = request.email().trim().toLowerCase(Locale.ROOT);
        userRepository.findActiveByEmailOrPhone(email)
                .ifPresent(user -> emailOtpService.sendOtp(email));
    }

    /** Đặt lại mật khẩu bằng OTP hợp lệ đã gửi tới email. */
    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        String email = request.email().trim().toLowerCase(Locale.ROOT);

        // Xác thực OTP trước (ném BusinessException nếu sai/hết hạn).
        emailOtpService.verifyOtp(email, request.otpCode());

        User user = userRepository.findActiveByEmailOrPhone(email)
                .orElseThrow(() -> new BusinessException(
                        "Không tìm thấy tài khoản với email này", HttpStatus.NOT_FOUND));

        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);
    }

    private void requireLoginAllowed(User user) {
        if (user.getStatus() == UserStatus.PENDING_VERIFICATION) {
            throw new BusinessException("Tài khoản chưa được xác thực email", HttpStatus.FORBIDDEN);
        }
        // Allow login for PENDING_APPROVAL so they can browse products
        if (user.getStatus() == UserStatus.DISABLED) {
            throw new BusinessException("Tài khoản không hoạt động", HttpStatus.FORBIDDEN);
        }
    }

    private BusinessException unauthorized(String message) {
        return new BusinessException(message, HttpStatus.UNAUTHORIZED);
    }

    private String trimToNull(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        return value.trim();
    }
}
