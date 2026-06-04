package com.marinelink.users;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record ShippingAddressRequest(
        @Size(max = 80, message = "Ten goi dia chi toi da 80 ky tu")
        String label,

        @NotBlank(message = "Nguoi nhan khong duoc de trong")
        @Size(max = 120, message = "Nguoi nhan toi da 120 ky tu")
        String receiverName,

        @NotBlank(message = "So dien thoai khong duoc de trong")
        @Pattern(regexp = "^(0|\\+84)[0-9]{9,10}$", message = "So dien thoai khong hop le")
        String receiverPhone,

        @NotBlank(message = "Dia chi giao hang khong duoc de trong")
        @Size(max = 500, message = "Dia chi giao hang toi da 500 ky tu")
        String addressLine,

        @JsonProperty("default")
        boolean isDefault) {
}
