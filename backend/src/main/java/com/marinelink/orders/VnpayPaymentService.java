package com.marinelink.orders;

import com.marinelink.cart.CartItemRepository;
import com.marinelink.cart.CartRepository;
import com.marinelink.common.exception.BusinessException;
import com.marinelink.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.text.Normalizer;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.TreeMap;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class VnpayPaymentService {

    private static final ZoneId VIETNAM_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final DateTimeFormatter VNPAY_DATE_FORMAT =
            DateTimeFormatter.ofPattern("yyyyMMddHHmmss").withZone(VIETNAM_ZONE);

    private final OrderRepository orderRepository;
    private final PaymentRepository paymentRepository;
    private final PaymentMethodRepository paymentMethodRepository;
    private final OrderPaymentNotificationService orderPaymentNotificationService;
    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;

    @Value("${app.vnpay.tmn-code:}")
    private String tmnCode;

    @Value("${app.vnpay.hash-secret:}")
    private String hashSecret;

    @Value("${app.vnpay.payment-url:https://sandbox.vnpayment.vn/paymentv2/vpcpay.html}")
    private String paymentUrl;

    @Value("${app.vnpay.return-url:http://localhost:8080/api/payments/vnpay/return}")
    private String returnUrl;

    @Transactional
    public VnpayPaymentUrlResponse createPaymentUrl(
            UUID userPublicId,
            UUID orderPublicId,
            String bankCode,
            String ipAddress) {
        requireConfigured();
        Order order = orderRepository.findDetailByPublicId(orderPublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay don hang"));
        if (!order.getUser().getPublicId().equals(userPublicId)) {
            throw new ResourceNotFoundException("Khong tim thay don hang");
        }
        if (order.getPaymentMethod().getCode() != PaymentMethodCode.VNPAY) {
            throw new BusinessException("Don hang khong su dung VNPAY", HttpStatus.UNPROCESSABLE_ENTITY);
        }
        if (order.getPaymentStatus() == PaymentStatus.PAID) {
            throw new BusinessException("Don hang da thanh toan", HttpStatus.UNPROCESSABLE_ENTITY);
        }

        Payment payment = paymentRepository.findTopByOrderPublicIdOrderByCreatedAtDesc(orderPublicId)
                .filter(existing -> existing.getStatus() != PaymentStatus.FAILED)
                .orElseGet(() -> createPayment(order));
        payment.setStatus(PaymentStatus.PENDING);
        payment.setBankCode(trimToNull(bankCode));
        paymentRepository.save(payment);

        Instant now = Instant.now();
        TreeMap<String, String> params = new TreeMap<>();
        params.put("vnp_Version", "2.1.0");
        params.put("vnp_Command", "pay");
        params.put("vnp_TmnCode", tmnCode.trim());
        params.put("vnp_Amount", vnpayAmount(order.getTotalAmount()));
        params.put("vnp_CurrCode", "VND");
        params.put("vnp_TxnRef", payment.getTxnRef());
        params.put("vnp_OrderInfo", normalizeOrderInfo("Thanh toan don hang " + order.getOrderCode()));
        params.put("vnp_OrderType", "other");
        params.put("vnp_Locale", "vn");
        params.put("vnp_ReturnUrl", returnUrl.trim());
        params.put("vnp_IpAddr", ipAddress);
        params.put("vnp_CreateDate", VNPAY_DATE_FORMAT.format(now));
        params.put("vnp_ExpireDate", VNPAY_DATE_FORMAT.format(now.plusSeconds(15 * 60L)));
        String cleanBankCode = trimToNull(bankCode);
        if (cleanBankCode != null) {
            params.put("vnp_BankCode", cleanBankCode);
        }

        String query = buildQuery(params);
        String secureHash = hmacSha512(hashSecret.trim(), query);
        return new VnpayPaymentUrlResponse(
                order.getPublicId(),
                order.getOrderCode(),
                payment.getTxnRef(),
                paymentUrl.trim() + "?" + query + "&vnp_SecureHash=" + secureHash);
    }

    @Transactional
    public VnpayPaymentResultResponse handleReturn(Map<String, String> params) {
        VnpayProcessResult result = processCallback(params, false);
        return result.response();
    }

    @Transactional
    public VnpayIpnResponse handleIpn(Map<String, String> params) {
        VnpayProcessResult result = processCallback(params, true);
        return new VnpayIpnResponse(result.rspCode(), result.message());
    }

    @Transactional
    public VnpayPaymentResultResponse cancelPendingPayment(UUID userPublicId, UUID orderPublicId) {
        Order order = orderRepository.findDetailByPublicId(orderPublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay don hang"));
        if (!order.getUser().getPublicId().equals(userPublicId)) {
            throw new ResourceNotFoundException("Khong tim thay don hang");
        }
        if (order.getPaymentMethod().getCode() != PaymentMethodCode.VNPAY) {
            throw new BusinessException("Don hang khong su dung VNPAY", HttpStatus.UNPROCESSABLE_ENTITY);
        }
        if (order.getPaymentStatus() == PaymentStatus.PAID) {
            throw new BusinessException("Don hang da thanh toan, khong the huy", HttpStatus.CONFLICT);
        }
        if (order.getStatus() != OrderStatus.PENDING) {
            throw new BusinessException("Chi co the huy don dang cho thanh toan", HttpStatus.UNPROCESSABLE_ENTITY);
        }

        Payment payment = paymentRepository.findTopByOrderPublicIdOrderByCreatedAtDesc(orderPublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay giao dich thanh toan"));
        if (payment.getStatus() == PaymentStatus.PAID) {
            throw new BusinessException("Don hang da thanh toan, khong the huy", HttpStatus.CONFLICT);
        }

        order.setStatus(OrderStatus.CANCELLED);
        order.setCancelledAt(Instant.now());
        order.setPaymentStatus(PaymentStatus.FAILED);
        payment.setStatus(PaymentStatus.FAILED);
        payment.setResponseCode("USER_CANCELLED");
        payment.setRawResponse("VNPAY payment cancelled by user or timeout");
        paymentRepository.save(payment);
        orderRepository.save(order);

        return new VnpayPaymentResultResponse(
                payment.getTxnRef(),
                order.getOrderCode(),
                payment.getStatus(),
                payment.getResponseCode(),
                null,
                "Payment cancelled");
    }

    private VnpayProcessResult processCallback(Map<String, String> params, boolean enforcePending) {
        requireConfigured();
        if (!isValidSecureHash(params)) {
            return new VnpayProcessResult("97", "Invalid checksum", response(params, null, "Invalid checksum"));
        }

        String txnRef = params.get("vnp_TxnRef");
        Payment payment = paymentRepository.findByTxnRef(txnRef).orElse(null);
        if (payment == null) {
            return new VnpayProcessResult("01", "Order not found", response(params, null, "Order not found"));
        }
        if (!vnpayAmount(payment.getAmount()).equals(params.get("vnp_Amount"))) {
            return new VnpayProcessResult("04", "Invalid amount", response(params, payment, "Invalid amount"));
        }
        if (enforcePending && payment.getStatus() != PaymentStatus.PENDING) {
            return new VnpayProcessResult("02", "Order already confirmed", response(params, payment, "Order already confirmed"));
        }

        PaymentStatus previousStatus = payment.getStatus();
        String responseCode = params.get("vnp_ResponseCode");
        String transactionStatus = params.get("vnp_TransactionStatus");
        PaymentStatus nextStatus = "00".equals(responseCode) && "00".equals(transactionStatus)
                ? PaymentStatus.PAID
                : PaymentStatus.FAILED;

        payment.setStatus(nextStatus);
        payment.setResponseCode(responseCode);
        payment.setTransactionCode(params.get("vnp_TransactionNo"));
        payment.setBankCode(params.get("vnp_BankCode"));
        payment.setRawResponse(new TreeMap<>(params).toString());
        payment.setPaidAt(nextStatus == PaymentStatus.PAID ? Instant.now() : null);
        payment.getOrder().setPaymentStatus(nextStatus);
        paymentRepository.save(payment);
        if (previousStatus != PaymentStatus.PAID && nextStatus == PaymentStatus.PAID) {
            clearSelectedCartItems(payment.getOrder());
            orderPaymentNotificationService.notifyPaidOrderWaitingForApproval(payment.getOrder());
        }

        return new VnpayProcessResult("00", "Confirm Success", response(params, payment, "Confirm Success"));
    }

    private Payment createPayment(Order order) {
        PaymentMethod method = paymentMethodRepository.findByCodeAndActiveTrue(PaymentMethodCode.VNPAY)
                .orElseThrow(() -> new BusinessException("Phuong thuc thanh toan khong hop le",
                        HttpStatus.UNPROCESSABLE_ENTITY));
        return Payment.builder()
                .publicId(UUID.randomUUID())
                .order(order)
                .paymentMethod(method)
                .amount(order.getTotalAmount())
                .status(PaymentStatus.PENDING)
                .txnRef(UUID.randomUUID().toString().replace("-", ""))
                .build();
    }

    private VnpayPaymentResultResponse response(Map<String, String> params, Payment payment, String message) {
        return new VnpayPaymentResultResponse(
                params.get("vnp_TxnRef"),
                payment == null ? null : payment.getOrder().getOrderCode(),
                payment == null ? null : payment.getStatus(),
                params.get("vnp_ResponseCode"),
                params.get("vnp_TransactionStatus"),
                message);
    }

    private boolean isValidSecureHash(Map<String, String> params) {
        String secureHash = params.get("vnp_SecureHash");
        if (secureHash == null || secureHash.isBlank()) {
            return false;
        }
        TreeMap<String, String> sorted = new TreeMap<>(params);
        sorted.remove("vnp_SecureHash");
        sorted.remove("vnp_SecureHashType");
        return secureHash.equalsIgnoreCase(hmacSha512(hashSecret.trim(), buildQuery(sorted)));
    }

    private String buildQuery(Map<String, String> params) {
        StringBuilder builder = new StringBuilder();
        params.forEach((key, value) -> {
            if (value == null || value.isBlank()) {
                return;
            }
            if (!builder.isEmpty()) {
                builder.append('&');
            }
            builder.append(encode(key)).append('=').append(encode(value));
        });
        return builder.toString();
    }

    private String hmacSha512(String key, String data) {
        try {
            Mac hmac = Mac.getInstance("HmacSHA512");
            hmac.init(new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "HmacSHA512"));
            byte[] bytes = hmac.doFinal(data.getBytes(StandardCharsets.UTF_8));
            StringBuilder result = new StringBuilder(bytes.length * 2);
            for (byte value : bytes) {
                result.append(String.format("%02x", value));
            }
            return result.toString();
        } catch (Exception ex) {
            throw new IllegalStateException("Cannot create VNPAY secure hash", ex);
        }
    }

    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    private String vnpayAmount(BigDecimal amount) {
        return amount.multiply(BigDecimal.valueOf(100))
                .setScale(0, RoundingMode.HALF_UP)
                .toPlainString();
    }

    private String normalizeOrderInfo(String value) {
        String withoutAccents = Normalizer.normalize(value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "");
        return withoutAccents.replaceAll("[^A-Za-z0-9 ]", " ").replaceAll("\\s+", " ").trim();
    }

    private void requireConfigured() {
        if (tmnCode == null || tmnCode.isBlank() || hashSecret == null || hashSecret.isBlank()) {
            throw new BusinessException("Chua cau hinh VNPAY", HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    private void clearSelectedCartItems(Order order) {
        if (order.getUser() == null || order.getUser().getPublicId() == null) {
            return;
        }
        var cart = cartRepository.findActiveByUserPublicId(order.getUser().getPublicId());
        if (cart != null) {
            cart.ifPresent(activeCart -> cartItemRepository.deleteSelectedByCartId(activeCart.getId()));
        }
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private record VnpayProcessResult(
            String rspCode,
            String message,
            VnpayPaymentResultResponse response) {
    }
}
