package com.marinelink.storage;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "app.supabase")
@Getter
@Setter
public class StorageProperties {
    private String url;
    private String key;
    private String defaultBucket = "product-images";
}
