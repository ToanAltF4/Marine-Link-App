package com.marinelink.products;

import com.marinelink.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ProductControllerTest {

    private final ProductService productService = mock(ProductService.class);
    private final MockMvc mockMvc = MockMvcBuilders
            .standaloneSetup(new ProductController(productService))
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();

    @Test
    void listCategoriesReturnsHierarchyEnvelope() throws Exception {
        UUID fishId = UUID.fromString("550e8400-e29b-41d4-a716-446655460101");
        UUID driedFishId = UUID.fromString("550e8400-e29b-41d4-a716-446655450103");
        when(productService.listCategories()).thenReturn(List.of(
                new CategoryResponse(
                        fishId,
                        "Cá",
                        null,
                        null,
                        List.of(new CategoryResponse(
                                driedFishId,
                                "Cá khô",
                                fishId,
                                "Cá",
                                List.of())))));

        mockMvc.perform(get("/api/products/categories")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].name").value("Cá"))
                .andExpect(jsonPath("$.data[0].children[0].name").value("Cá khô"))
                .andExpect(jsonPath("$.data[0].children[0].parentId").value(fishId.toString()));
    }

    @Test
    void listProductsReturnsPaginatedEnvelope() throws Exception {
        UUID categoryId = UUID.fromString("550e8400-e29b-41d4-a716-446655440021");
        ProductListItemResponse product = new ProductListItemResponse(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440031"),
                "Muc kho loai 1",
                "muc-kho-loai-1",
                "Muc kho size lon cho don si",
                "Ca Mau",
                null,
                new BigDecimal("450000"),
                "kg",
                2,
                120,
                ProductStatus.ACTIVE,
                true,
                new CategoryResponse(categoryId, "Muc kho"));

        when(productService.listProducts(0, 20, "muc", categoryId, ProductStatus.ACTIVE, true, "price_asc"))
                .thenReturn(new PageImpl<>(List.of(product), PageRequest.of(0, 20), 1));

        mockMvc.perform(get("/api/products")
                        .queryParam("page", "0")
                        .queryParam("size", "20")
                        .queryParam("q", "muc")
                        .queryParam("categoryId", categoryId.toString())
                        .queryParam("status", "ACTIVE")
                        .queryParam("featured", "true")
                        .queryParam("sort", "price_asc")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].slug").value("muc-kho-loai-1"))
                .andExpect(jsonPath("$.data[0].shortDescription").value("Muc kho size lon cho don si"))
                .andExpect(jsonPath("$.data[0].category.name").value("Muc kho"))
                .andExpect(jsonPath("$.pagination.page").value(0))
                .andExpect(jsonPath("$.pagination.totalPages").value(1));
    }

    @Test
    void getProductDetailReturnsEnvelope() throws Exception {
        UUID productId = UUID.fromString("550e8400-e29b-41d4-a716-446655440041");
        ProductDetailResponse response = new ProductDetailResponse(
                productId,
                "Tom kho size lon",
                "tom-kho-size-lon",
                "Tom kho dong goi dep cho dai ly",
                "Tom kho phuc vu don si",
                "Bac Lieu",
                null,
                new BigDecimal("680000"),
                "kg",
                1,
                80,
                ProductStatus.ACTIVE,
                true,
                new CategoryResponse(
                        UUID.fromString("550e8400-e29b-41d4-a716-446655440042"),
                        "Tom kho"),
                List.of(new ProductImageResponse(
                        UUID.fromString("550e8400-e29b-41d4-a716-446655440043"),
                        "https://example.com/tom-kho.png",
                        "Tom kho size lon",
                        0)),
                List.of(new PriceTierResponse(
                        UUID.fromString("550e8400-e29b-41d4-a716-446655440044"),
                        1,
                        4,
                        new BigDecimal("680000"))));

        when(productService.getProductDetail(productId)).thenReturn(response);

        mockMvc.perform(get("/api/products/{id}", productId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.name").value("Tom kho size lon"))
                .andExpect(jsonPath("$.data.shortDescription").value("Tom kho dong goi dep cho dai ly"))
                .andExpect(jsonPath("$.data.priceTiers[0].minQuantity").value(1))
                .andExpect(jsonPath("$.data.images[0].displayOrder").value(0));
    }
}
