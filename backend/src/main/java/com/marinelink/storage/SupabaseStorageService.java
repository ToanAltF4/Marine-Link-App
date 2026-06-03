package com.marinelink.storage;

import com.marinelink.common.exception.BusinessException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@Service
@Slf4j
public class SupabaseStorageService implements StorageService {

    private final StorageProperties properties;
    private final RestClient restClient;

    public SupabaseStorageService(StorageProperties properties) {
        this.properties = properties;
        this.restClient = RestClient.builder()
                .baseUrl(properties.getUrl())
                .defaultHeader("Authorization", "Bearer " + properties.getKey())
                .defaultHeader("apikey", properties.getKey())
                .build();
        log.info("Initialized SupabaseStorageService with URL: {}", properties.getUrl());
    }

    @Override
    public String uploadFile(String bucketName, String path, byte[] bytes, String contentType) {
        log.info("Uploading file to Supabase Storage: bucket={}, path={}, contentType={}", bucketName, path, contentType);
        try {
            restClient.post()
                    .uri("/storage/v1/object/{bucket}/{path}", bucketName, path)
                    .header("x-upsert", "true")
                    .contentType(MediaType.valueOf(contentType))
                    .body(bytes)
                    .retrieve()
                    .toBodilessEntity();

            String publicUrl = properties.getUrl() + "/storage/v1/object/public/" + bucketName + "/" + path;
            log.info("File uploaded successfully. Public URL: {}", publicUrl);
            return publicUrl;
        } catch (Exception e) {
            log.error("Failed to upload file to Supabase Storage", e);
            throw new BusinessException("Loi khi upload file len Supabase Storage: " + e.getMessage());
        }
    }

    @Override
    public String uploadFile(String bucketName, String path, MultipartFile file) {
        try {
            String contentType = file.getContentType();
            if (contentType == null) {
                contentType = MediaType.APPLICATION_OCTET_STREAM_VALUE;
            }
            return uploadFile(bucketName, path, file.getBytes(), contentType);
        } catch (IOException e) {
            log.error("Failed to read bytes from multipart file", e);
            throw new BusinessException("Khong the doc du lieu file de upload: " + e.getMessage());
        }
    }

    @Override
    public void deleteFile(String bucketName, String path) {
        log.info("Deleting file from Supabase Storage: bucket={}, path={}", bucketName, path);
        try {
            restClient.delete()
                    .uri("/storage/v1/object/{bucket}/{path}", bucketName, path)
                    .retrieve()
                    .toBodilessEntity();
            log.info("File deleted successfully from Supabase Storage");
        } catch (Exception e) {
            log.error("Failed to delete file from Supabase Storage", e);
            throw new BusinessException("Loi khi xoa file khoi Supabase Storage: " + e.getMessage());
        }
    }
}
