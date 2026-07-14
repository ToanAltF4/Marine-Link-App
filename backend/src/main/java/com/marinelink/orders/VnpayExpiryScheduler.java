package com.marinelink.orders;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Định kỳ tự hủy các đơn VNPAY còn chờ thanh toán quá hạn (mặc định 15 phút).
 * Chạy server-side nên đơn vẫn được hủy dù người dùng đã đóng app.
 */
@Component
@Slf4j
@RequiredArgsConstructor
public class VnpayExpiryScheduler {

    private final VnpayPaymentService vnpayPaymentService;

    @Scheduled(fixedDelayString = "${app.vnpay.expiry-check-ms:60000}")
    public void cancelExpiredVnpayOrders() {
        try {
            int cancelled = vnpayPaymentService.cancelExpiredVnpayOrders();
            if (cancelled > 0) {
                log.info("Đã tự hủy {} đơn VNPAY quá hạn thanh toán.", cancelled);
            }
        } catch (Exception ex) {
            // Không để lỗi scheduler làm dừng lịch chạy.
            log.warn("Kiểm tra hết hạn VNPAY thất bại: {}", ex.getMessage());
        }
    }
}
