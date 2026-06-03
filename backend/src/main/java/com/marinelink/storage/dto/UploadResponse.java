package com.marinelink.storage.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UploadResponse {
    private String url;
    private String path;
    private String bucket;
    private String fileName;
}
