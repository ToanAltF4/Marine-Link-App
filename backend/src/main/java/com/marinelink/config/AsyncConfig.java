package com.marinelink.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

/**
 * Pool riêng cho các tác vụ {@code @Async} (gửi email, đẩy push).
 *
 * <p>Không có bean tên {@code taskExecutor}, Spring sẽ rơi về
 * SimpleAsyncTaskExecutor — tạo thread mới cho MỖI lần gửi, không giới hạn.
 * Pool có chặn trên dưới đây an toàn hơn và bỏ được cảnh báo lúc khởi động.
 */
@Configuration
public class AsyncConfig {

    @Bean(name = "taskExecutor")
    public ThreadPoolTaskExecutor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(5);
        executor.setQueueCapacity(50);
        executor.setThreadNamePrefix("async-mail-");
        executor.initialize();
        return executor;
    }
}
