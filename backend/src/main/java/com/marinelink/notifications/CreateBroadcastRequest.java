package com.marinelink.notifications;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Admin/staff creating a broadcast notification for all dealers. */
public record CreateBroadcastRequest(
        @NotBlank(message = "Tiêu đề không được để trống")
        @Size(max = 200, message = "Tiêu đề tối đa 200 ký tự")
        String title,

        @NotBlank(message = "Nội dung không được để trống")
        String body
) {
}
