package com.marinelink.auth;

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

    @Transactional
    public RegisterResponse register(RegisterRequest request) {
        String email = request.email().trim().toLowerCase(Locale.ROOT);
        String phone = request.phone().trim();

        if (userRepository.existsActiveByEmail(email)) {
            throw new ConflictException("Email đã được sử dụng");
        }
        if (userRepository.existsActiveByPhone(phone)) {
            throw new ConflictException("Số điện thoại đã được sử dụng");
        }

        Role userRole = roleRepository.findByCode(DEFAULT_ROLE)
                .orElseThrow(() -> new BusinessException(
                        "Role USER chưa được cấu hình",
                        HttpStatus.INTERNAL_SERVER_ERROR));

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

        User savedUser = userRepository.save(user);

        // Send OTP after user is persisted so that a mail failure still keeps the user record
        emailOtpService.sendOtp(email);

        return RegisterResponse.from(savedUser);
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

        user.setStatus(UserStatus.ACTIVE);
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

    private void requireLoginAllowed(User user) {
        if (user.getStatus() == UserStatus.PENDING_VERIFICATION) {
            throw new BusinessException("Tài khoản chưa được xác thực email", HttpStatus.FORBIDDEN);
        }
        if (user.getStatus() == UserStatus.PENDING_APPROVAL) {
            throw new BusinessException("Tài khoản đang chờ duyệt", HttpStatus.FORBIDDEN);
        }
        if (!user.isActive()) {
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
