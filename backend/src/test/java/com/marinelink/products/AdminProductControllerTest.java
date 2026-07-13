package com.marinelink.products;

import com.marinelink.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AdminProductControllerTest {

    private final AdminProductService adminProductService = mock(AdminProductService.class);
    private final MockMvc mockMvc = MockMvcBuilders
            .standaloneSetup(new AdminProductController(adminProductService))
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();

    @Test
    void listProductsReturnsPaginatedEnvelope() throws Exception {
        UUID categoryId = UUID.fromString("550e8400-e29b-41d4-a716-446655440021");
        ProductListItemResponse product = new ProductListItemResponse(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440031"),
                "Muc kho loai 1",
                "muc-kho-loai-1",
                "Muc kho size lon cho don si",
                "Ca Mau",
                "https://example.com/muc-kho.png",
                new BigDecimal("450000"),
                "kg",
                2,
                120,
                ProductStatus.ACTIVE,
                true,
                new CategoryResponse(categoryId, "Muc kho"));

        when(adminProductService.listProducts(0, 20, "muc", categoryId, ProductStatus.ACTIVE, true, "stock_desc"))
                .thenReturn(new PageImpl<>(List.of(product), PageRequest.of(0, 20), 1));

        mockMvc.perform(get("/api/admin/products")
                        .queryParam("page", "0")
                        .queryParam("size", "20")
                        .queryParam("q", "muc")
                        .queryParam("categoryId", categoryId.toString())
                        .queryParam("status", "ACTIVE")
                        .queryParam("featured", "true")
                        .queryParam("sort", "stock_desc")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].slug").value("muc-kho-loai-1"))
                .andExpect(jsonPath("$.data[0].shortDescription").value("Muc kho size lon cho don si"))
                .andExpect(jsonPath("$.data[0].stockQuantity").value(120))
                .andExpect(jsonPath("$.pagination.page").value(0));
    }

    @Test
    void createProductReturnsCreatedEnvelope() throws Exception {
        UUID productId = UUID.fromString("550e8400-e29b-41d4-a716-446655440041");
        when(adminProductService.createProduct(org.mockito.ArgumentMatchers.any(AdminProductRequest.class)))
                .thenReturn(detail(productId));

        mockMvc.perform(post("/api/admin/products")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validRequestJson()))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Product created"))
                .andExpect(jsonPath("$.data.id").value(productId.toString()))
                .andExpect(jsonPath("$.data.priceTiers[0].minQuantity").value(2));
    }

    @Test
    void updateProductReturnsUpdatedEnvelope() throws Exception {
        UUID productId = UUID.fromString("550e8400-e29b-41d4-a716-446655440041");
        when(adminProductService.updateProduct(
                org.mockito.ArgumentMatchers.eq(productId),
                org.mockito.ArgumentMatchers.any(AdminProductRequest.class)))
                .thenReturn(detail(productId));

        mockMvc.perform(put("/api/admin/products/{id}", productId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validRequestJson()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Product updated"))
                .andExpect(jsonPath("$.data.slug").value("muc-kho-loai-1"));
    }

    @Test
    void deleteProductReturnsOkEnvelope() throws Exception {
        UUID productId = UUID.fromString("550e8400-e29b-41d4-a716-446655440041");

        mockMvc.perform(delete("/api/admin/products/{id}", productId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Product deleted"));

        verify(adminProductService).deleteProduct(productId);
    }

    @Test
    void updateProductBindsExistingPriceTierIds() throws Exception {
        UUID productId = UUID.fromString("550e8400-e29b-41d4-a716-446655440041");
        UUID tierId = UUID.fromString("550e8400-e29b-41d4-a716-446655440043");
        when(adminProductService.updateProduct(
                org.mockito.ArgumentMatchers.eq(productId),
                org.mockito.ArgumentMatchers.any(AdminProductRequest.class)))
                .thenReturn(detail(productId));

        mockMvc.perform(put("/api/admin/products/{id}", productId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Muc kho loai 1",
                                  "slug": "muc-kho-loai-1",
                                  "shortDescription": "",
                                  "description": "",
                                  "origin": "",
                                  "imageUrl": "",
                                  "basePrice": 450000,
                                  "unit": "kg",
                                  "minOrderQuantity": 2,
                                  "stockQuantity": 120,
                                  "status": "ACTIVE",
                                  "isFeatured": true,
                                  "priceTiers": [
                                    {"id": "550e8400-e29b-41d4-a716-446655440043",
                                     "minQuantity": 2, "maxQuantity": 9, "unitPrice": 450000},
                                    {"minQuantity": 10, "maxQuantity": null, "unitPrice": 420000}
                                  ]
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        ArgumentCaptor<AdminProductRequest> captor = ArgumentCaptor.forClass(AdminProductRequest.class);
        verify(adminProductService).updateProduct(org.mockito.ArgumentMatchers.eq(productId), captor.capture());
        AdminProductRequest request = captor.getValue();
        // Mức giá đã tồn tại gửi kèm id -> backend cập nhật tại chỗ; mức giá mới có id null.
        assertEquals(tierId, request.priceTiers().get(0).id());
        assertNull(request.priceTiers().get(1).id());
        // Trường tuỳ chọn để trống vẫn qua được validation (không 400).
        assertEquals("", request.shortDescription());
    }

    @Test
    void createProductRejectsInvalidPayload() throws Exception {
        mockMvc.perform(post("/api/admin/products")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "categoryId": "550e8400-e29b-41d4-a716-446655440021",
                                  "slug": "muc-kho-loai-1",
                                  "basePrice": 450000,
                                  "unit": "kg",
                                  "minOrderQuantity": 2,
                                  "stockQuantity": 120,
                                  "status": "ACTIVE",
                                  "isFeatured": true
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errors[0].field").value("name"));
    }

    private ProductDetailResponse detail(UUID productId) {
        UUID categoryId = UUID.fromString("550e8400-e29b-41d4-a716-446655440021");
        return new ProductDetailResponse(
                productId,
                "Muc kho loai 1",
                "muc-kho-loai-1",
                "Muc kho size lon cho don si",
                "Muc kho phuc vu don si",
                "Ca Mau",
                "https://example.com/muc-kho.png",
                new BigDecimal("450000"),
                "kg",
                2,
                120,
                ProductStatus.ACTIVE,
                true,
                new CategoryResponse(categoryId, "Muc kho"),
                List.of(new ProductImageResponse(
                        UUID.fromString("550e8400-e29b-41d4-a716-446655440042"),
                        "https://example.com/muc-kho.png",
                        "Muc kho loai 1",
                        0)),
                List.of(new PriceTierResponse(
                        UUID.fromString("550e8400-e29b-41d4-a716-446655440043"),
                        2,
                        9,
                        new BigDecimal("450000"))));
    }

    private String validRequestJson() {
        return """
                {
                  "categoryId": "550e8400-e29b-41d4-a716-446655440021",
                  "name": "Muc kho loai 1",
                  "slug": "muc-kho-loai-1",
                  "shortDescription": "Muc kho size lon cho don si",
                  "description": "Muc kho phuc vu don si",
                  "origin": "Ca Mau",
                  "basePrice": 450000,
                  "unit": "kg",
                  "minOrderQuantity": 2,
                  "stockQuantity": 120,
                  "status": "ACTIVE",
                  "isFeatured": true,
                  "priceTiers": [
                    {"minQuantity": 2, "maxQuantity": 9, "unitPrice": 450000},
                    {"minQuantity": 10, "maxQuantity": null, "unitPrice": 420000}
                  ]
                }
                """;
    }
}
