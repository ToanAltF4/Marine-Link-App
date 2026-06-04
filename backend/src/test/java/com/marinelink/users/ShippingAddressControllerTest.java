package com.marinelink.users;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.marinelink.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ShippingAddressControllerTest {

    private final ShippingAddressService shippingAddressService = mock(ShippingAddressService.class);
    private final MockMvc mockMvc = MockMvcBuilders
            .standaloneSetup(new ShippingAddressController(shippingAddressService))
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void listCurrentUserShippingAddressesReturnsSavedAddresses() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID addressId = UUID.fromString("550e8400-e29b-41d4-a716-446655440071");
        ShippingAddressResponse address = new ShippingAddressResponse(
                addressId,
                "Kho Can Tho",
                "Nguyen Van A",
                "0912345678",
                "123 Tran Hung Dao, Can Tho",
                true,
                Instant.parse("2026-06-04T01:00:00Z"),
                Instant.parse("2026-06-04T01:00:00Z"));
        when(shippingAddressService.listForUser(userId)).thenReturn(List.of(address));

        mockMvc.perform(get("/api/users/me/shipping-addresses")
                        .principal(new TestingAuthenticationToken(userId.toString(), null)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].id").value(addressId.toString()))
                .andExpect(jsonPath("$.data[0].addressLine").value("123 Tran Hung Dao, Can Tho"))
                .andExpect(jsonPath("$.data[0].default").value(true));
    }

    @Test
    void createCurrentUserShippingAddressPersistsFirstDefaultAddress() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID addressId = UUID.fromString("550e8400-e29b-41d4-a716-446655440072");
        ShippingAddressRequest request = new ShippingAddressRequest(
                "Kho Can Tho",
                "Nguyen Van A",
                "0912345678",
                "123 Tran Hung Dao, Can Tho",
                false);
        ShippingAddressResponse response = new ShippingAddressResponse(
                addressId,
                "Kho Can Tho",
                "Nguyen Van A",
                "0912345678",
                "123 Tran Hung Dao, Can Tho",
                true,
                Instant.parse("2026-06-04T01:00:00Z"),
                Instant.parse("2026-06-04T01:00:00Z"));
        when(shippingAddressService.createForUser(eq(userId), any(ShippingAddressRequest.class)))
                .thenReturn(response);

        mockMvc.perform(post("/api/users/me/shipping-addresses")
                        .principal(new TestingAuthenticationToken(userId.toString(), null))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(addressId.toString()))
                .andExpect(jsonPath("$.data.default").value(true));
    }

    @Test
    void updateAndDeleteUseCurrentUserScope() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID addressId = UUID.fromString("550e8400-e29b-41d4-a716-446655440073");
        ShippingAddressRequest request = new ShippingAddressRequest(
                "Chi nhanh moi",
                "Nguyen Van B",
                "0987654321",
                "45 Nguyen Trai, Ca Mau",
                true);
        ShippingAddressResponse response = new ShippingAddressResponse(
                addressId,
                "Chi nhanh moi",
                "Nguyen Van B",
                "0987654321",
                "45 Nguyen Trai, Ca Mau",
                true,
                Instant.parse("2026-06-04T01:00:00Z"),
                Instant.parse("2026-06-04T02:00:00Z"));
        when(shippingAddressService.updateForUser(eq(userId), eq(addressId), any(ShippingAddressRequest.class)))
                .thenReturn(response);

        mockMvc.perform(put("/api/users/me/shipping-addresses/{id}", addressId)
                        .principal(new TestingAuthenticationToken(userId.toString(), null))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.receiverName").value("Nguyen Van B"));

        mockMvc.perform(delete("/api/users/me/shipping-addresses/{id}", addressId)
                        .principal(new TestingAuthenticationToken(userId.toString(), null)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        verify(shippingAddressService).deleteForUser(userId, addressId);
    }
}
