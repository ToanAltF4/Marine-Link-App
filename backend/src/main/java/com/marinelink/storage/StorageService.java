package com.marinelink.storage;

import org.springframework.web.multipart.MultipartFile;

public interface StorageService {
    
    /**
     * Upload raw bytes to Supabase Storage.
     *
     * @param bucketName The name of the storage bucket
     * @param path The file path inside the bucket
     * @param bytes The raw file bytes
     * @param contentType The mime type of the file
     * @return The public URL of the uploaded file
     */
    String uploadFile(String bucketName, String path, byte[] bytes, String contentType);

    /**
     * Upload a MultipartFile to Supabase Storage.
     *
     * @param bucketName The name of the storage bucket
     * @param path The file path inside the bucket
     * @param file The multipart file
     * @return The public URL of the uploaded file
     */
    String uploadFile(String bucketName, String path, MultipartFile file);

    /**
     * Delete a file from Supabase Storage.
     *
     * @param bucketName The name of the storage bucket
     * @param path The file path inside the bucket
     */
    void deleteFile(String bucketName, String path);
}
