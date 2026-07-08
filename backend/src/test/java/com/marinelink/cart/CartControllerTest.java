package com.marinelink.cart;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.marinelink.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class CartControllerTest {

    private final CartService cartService = mock(CartService.class);
    private final MockMvc mockMvc = MockMvcBuilders
            .standaloneSetup(new CartController(cartService))
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void syncCartUsesCurrentUserAndReturnsCartEnvelope() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID productId = UUID.fromString("550e8400-e29b-41d4-a716-446655440012");
        UUID cartId = UUID.fromString("550e8400-e29b-41d4-a716-446655440031");
        UUID tierId = UUID.fromString("550e8400-e29b-41d4-a716-446655440051");
        CartSyncRequest request = new CartSyncRequest(List.of(
                new CartSyncItemRequest(productId, 2, true)));
        CartResponse response = new CartResponse(
                cartId,
                false,
                List.of(new CartItemResponse(
                        productId,
                        "Muc kho loai 1",
                        "https://example.com/muc-kho.png",
                        "kg",
                        2,
                        true,
                        tierId,
                        new BigDecimal("450000"),
                        new BigDecimal("425000"),
                        new BigDecimal("850000"),
                        2,
                        20,
                        List.of())),
                2,
                2,
                new BigDecimal("850000"));

        when(cartService.syncCart(eq(userId), any(CartSyncRequest.class)))
                .thenReturn(response);

        mockMvc.perform(post("/api/cart/sync")
                        .principal(new TestingAuthenticationToken(userId.toString(), null))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Cart synced"))
                .andExpect(jsonPath("$.data.cartId").value(cartId.toString()))
                .andExpect(jsonPath("$.data.items[0].productId").value(productId.toString()))
                .andExpect(jsonPath("$.data.items[0].lineTotal").value(850000))
                .andExpect(jsonPath("$.data.totalSelectedItemCount").value(2));
    }

    @Test
    void getActiveCartUsesCurrentUserAndReturnsCartEnvelope() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID productId = UUID.fromString("550e8400-e29b-41d4-a716-446655440012");
        UUID cartId = UUID.fromString("550e8400-e29b-41d4-a716-446655440031");
        CartResponse response = new CartResponse(
                cartId,
                false,
                List.of(new CartItemResponse(
                        productId,
                        "Muc kho loai 1",
                        "https://example.com/muc-kho.png",
                        "kg",
                        4,
                        true,
                        null,
                        new BigDecimal("450000"),
                        new BigDecimal("450000"),
                        new BigDecimal("1800000"),
                        2,
                        20,
                        List.of())),
                4,
                4,
                new BigDecimal("1800000"));

        when(cartService.getActiveCart(userId)).thenReturn(response);

        mockMvc.perform(get("/api/cart")
                        .principal(new TestingAuthenticationToken(userId.toString(), null)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Cart loaded"))
                .andExpect(jsonPath("$.data.cartId").value(cartId.toString()))
                .andExpect(jsonPath("$.data.items[0].productId").value(productId.toString()))
                .andExpect(jsonPath("$.data.items[0].quantity").value(4));
    }

    @Test
    void addItemUsesCurrentUserAndReturnsCartEnvelope() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID productId = UUID.fromString("550e8400-e29b-41d4-a716-446655440012");
        CartResponse response = cartResponse(productId, 3);

        when(cartService.addItem(eq(userId), any(CartItemCreateRequest.class)))
                .thenReturn(response);

        mockMvc.perform(post("/api/cart/items")
                        .principal(new TestingAuthenticationToken(userId.toString(), null))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                new CartItemCreateRequest(productId, 3, true))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Cart item added"))
                .andExpect(jsonPath("$.data.items[0].quantity").value(3));
    }

    @Test
    void updateItemUsesCurrentUserAndPathProduct() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID productId = UUID.fromString("550e8400-e29b-41d4-a716-446655440012");
        CartResponse response = cartResponse(productId, 5);

        when(cartService.updateItem(eq(userId), eq(productId), any(CartItemUpdateRequest.class)))
                .thenReturn(response);

        mockMvc.perform(patch("/api/cart/items/{productId}", productId)
                        .principal(new TestingAuthenticationToken(userId.toString(), null))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                new CartItemUpdateRequest(5, true))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Cart item updated"))
                .andExpect(jsonPath("$.data.items[0].quantity").value(5));
    }

    @Test
    void removeItemUsesCurrentUserAndPathProduct() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID productId = UUID.fromString("550e8400-e29b-41d4-a716-446655440012");
        CartResponse response = cartResponse(productId, 0);

        when(cartService.removeItem(userId, productId)).thenReturn(response);

        mockMvc.perform(delete("/api/cart/items/{productId}", productId)
                        .principal(new TestingAuthenticationToken(userId.toString(), null)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Cart item removed"));
    }

    @Test
    void clearItemsUsesCurrentUser() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        CartResponse response = new CartResponse(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440031"),
                true,
                List.of(),
                0,
                0,
                BigDecimal.ZERO);

        when(cartService.clearItems(userId)).thenReturn(response);

        mockMvc.perform(delete("/api/cart/items")
                        .principal(new TestingAuthenticationToken(userId.toString(), null)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Cart cleared"))
                .andExpect(jsonPath("$.data.isEmpty").value(true));
    }

    private CartResponse cartResponse(UUID productId, int quantity) {
        return new CartResponse(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440031"),
                quantity == 0,
                quantity == 0
                        ? List.of()
                        : List.of(new CartItemResponse(
                                productId,
                                "Muc kho loai 1",
                                "https://example.com/muc-kho.png",
                                "kg",
                                quantity,
                                true,
                                null,
                                new BigDecimal("450000"),
                                new BigDecimal("450000"),
                                new BigDecimal("450000").multiply(BigDecimal.valueOf(quantity)),
                                2,
                                20,
                                List.of())),
                quantity,
                quantity,
                new BigDecimal("450000").multiply(BigDecimal.valueOf(quantity)));
    }
}
