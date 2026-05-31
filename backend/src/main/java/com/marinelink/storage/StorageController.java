package com.marinelink.storage;

import com.marinelink.common.api.ApiResponse;
import com.marinelink.common.exception.BusinessException;
import com.marinelink.storage.dto.UploadResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

@RestController
@RequestMapping("/api/storage")
@RequiredArgsConstructor
@Slf4j
public class StorageController {

    private final StorageService storageService;
    private final StorageProperties storageProperties;

    @PostMapping("/upload")
    public ApiResponse<UploadResponse> uploadFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "bucket", required = false) String bucket) {
        
        if (file.isEmpty()) {
            throw new BusinessException("File upload khong duoc de trong");
        }

        String bucketName = (bucket == null || bucket.isBlank()) ? storageProperties.getDefaultBucket() : bucket;
        String originalFilename = file.getOriginalFilename();
        String extension = "";
        
        if (originalFilename != null && originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        
        // Generate a unique path using UUID to prevent duplicates
        String path = UUID.randomUUID() + extension;
        log.info("Receiving upload request: fileName={}, size={}, bucket={}", originalFilename, file.getSize(), bucketName);

        String publicUrl = storageService.uploadFile(bucketName, path, file);

        UploadResponse response = UploadResponse.builder()
                .url(publicUrl)
                .path(path)
                .bucket(bucketName)
                .fileName(originalFilename)
                .build();

        return ApiResponse.ok(response);
    }
}
