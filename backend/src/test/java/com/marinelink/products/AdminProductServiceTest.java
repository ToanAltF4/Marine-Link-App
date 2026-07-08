package com.marinelink.products;

import com.marinelink.common.exception.ConflictException;
import com.marinelink.common.exception.ResourceNotFoundException;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;

import java.math.BigDecimal;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AdminProductServiceTest {

    private final ProductRepository productRepository = mock(ProductRepository.class);
    private final CategoryRepository categoryRepository = mock(CategoryRepository.class);
    private final AdminProductService adminProductService =
            new AdminProductService(productRepository, categoryRepository);

    @Test
    void listProductsMapsAdminPage() {
        Product product = demoProduct();
        when(productRepository.findAll(any(Specification.class), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(product)));

        Page<ProductListItemResponse> result = adminProductService.listProducts(
                0,
                20,
                "muc",
                product.getCategory().getPublicId(),
                ProductStatus.ACTIVE,
                true,
                "stock_desc");

        assertEquals(1, result.getTotalElements());
        assertEquals("Muc kho loai 1", result.getContent().getFirst().name());
        verify(productRepository).findAll(any(Specification.class), any(Pageable.class));
    }

    @Test
    void createProductSavesProductWithPriceTiers() {
        Category category = demoCategory();
        AdminProductRequest request = request(category.getPublicId(), "muc-kho-loai-1");
        when(categoryRepository.findActiveByPublicId(category.getPublicId())).thenReturn(Optional.of(category));
        when(productRepository.existsBySlugIgnoreCaseAndDeletedAtIsNull("muc-kho-loai-1")).thenReturn(false);
        when(productRepository.save(any(Product.class))).thenAnswer(invocation -> invocation.getArgument(0));

        ProductDetailResponse result = adminProductService.createProduct(request);

        assertEquals("Muc kho loai 1", result.name());
        assertEquals("Muc kho size lon cho don si", result.shortDescription());
        assertEquals(ProductStatus.ACTIVE, result.status());
        assertEquals(2, result.priceTiers().size());
        assertNotNull(result.id());

        ArgumentCaptor<Product> productCaptor = ArgumentCaptor.forClass(Product.class);
        verify(productRepository).save(productCaptor.capture());
        Product saved = productCaptor.getValue();
        assertEquals(category, saved.getCategory());
        assertEquals(2, saved.getPriceTiers().size());
        assertTrue(saved.getPriceTiers().stream().allMatch(tier -> tier.getProduct() == saved));
    }

    @Test
    void updateProductReplacesEditableFieldsAndPriceTiers() {
        Product product = demoProduct();
        AdminProductRequest request = request(product.getCategory().getPublicId(), "muc-kho-cap-nhat");
        when(productRepository.findDetailByPublicId(product.getPublicId())).thenReturn(Optional.of(product));
        when(categoryRepository.findActiveByPublicId(product.getCategory().getPublicId()))
                .thenReturn(Optional.of(product.getCategory()));
        when(productRepository.existsActiveSlugExcluding("muc-kho-cap-nhat", product.getPublicId()))
                .thenReturn(false);
        when(productRepository.save(product)).thenReturn(product);

        ProductDetailResponse result = adminProductService.updateProduct(product.getPublicId(), request);

        assertEquals("muc-kho-cap-nhat", result.slug());
        assertEquals(new BigDecimal("450000"), result.basePrice());
        assertEquals(2, result.priceTiers().size());
        verify(productRepository).save(product);
    }

    @Test
    void createProductRejectsDuplicateSlug() {
        Category category = demoCategory();
        AdminProductRequest request = request(category.getPublicId(), "muc-kho-loai-1");
        when(productRepository.existsBySlugIgnoreCaseAndDeletedAtIsNull("muc-kho-loai-1")).thenReturn(true);

        assertThrows(ConflictException.class, () -> adminProductService.createProduct(request));
    }

    @Test
    void createProductRejectsOverlappingPriceTiers() {
        Category category = demoCategory();
        AdminProductRequest request = new AdminProductRequest(
                category.getPublicId(),
                "Muc kho loai 1",
                "muc-kho-loai-1",
                "Muc kho size lon cho don si",
                "Muc kho phuc vu don si",
                "Ca Mau",
                new BigDecimal("450000"),
                "kg",
                2,
                120,
                ProductStatus.ACTIVE,
                true,
                List.of(
                        new AdminPriceTierRequest(2, 9, new BigDecimal("450000")),
                        new AdminPriceTierRequest(9, null, new BigDecimal("420000"))));
        when(productRepository.existsBySlugIgnoreCaseAndDeletedAtIsNull("muc-kho-loai-1")).thenReturn(false);
        when(categoryRepository.findActiveByPublicId(category.getPublicId())).thenReturn(Optional.of(category));

        assertThrows(ConflictException.class, () -> adminProductService.createProduct(request));
    }

    @Test
    void createProductThrowsWhenCategoryMissing() {
        UUID categoryId = UUID.fromString("550e8400-e29b-41d4-a716-446655440099");
        AdminProductRequest request = request(categoryId, "muc-kho-loai-1");
        when(productRepository.existsBySlugIgnoreCaseAndDeletedAtIsNull("muc-kho-loai-1")).thenReturn(false);
        when(categoryRepository.findActiveByPublicId(categoryId)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> adminProductService.createProduct(request));
    }

    @Test
    void deleteProductSoftDisablesProduct() {
        Product product = demoProduct();
        when(productRepository.findByPublicIdIncludingDeleted(product.getPublicId())).thenReturn(Optional.of(product));
        when(productRepository.save(product)).thenReturn(product);

        adminProductService.deleteProduct(product.getPublicId());

        assertEquals(ProductStatus.DISABLED, product.getStatus());
        assertNotNull(product.getDeletedAt());
        verify(productRepository).save(product);
    }

    @Test
    void getProductThrowsWhenMissing() {
        UUID productId = UUID.fromString("550e8400-e29b-41d4-a716-446655440088");
        when(productRepository.findDetailByPublicId(productId)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> adminProductService.getProductDetail(productId));
    }

    private AdminProductRequest request(UUID categoryId, String slug) {
        return new AdminProductRequest(
                categoryId,
                "Muc kho loai 1",
                slug,
                "Muc kho size lon cho don si",
                "Muc kho phuc vu don si",
                "Ca Mau",
                new BigDecimal("450000"),
                "kg",
                2,
                120,
                ProductStatus.ACTIVE,
                true,
                List.of(
                        new AdminPriceTierRequest(2, 9, new BigDecimal("450000")),
                        new AdminPriceTierRequest(10, null, new BigDecimal("420000"))));
    }

    private Category demoCategory() {
        return Category.builder()
                .id(11L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440051"))
                .name("Muc kho")
                .slug("muc-kho")
                .active(true)
                .build();
    }

    private Product demoProduct() {
        Category category = demoCategory();
        Product product = Product.builder()
                .id(21L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440052"))
                .category(category)
                .name("Muc kho loai 1")
                .slug("muc-kho-loai-1")
                .shortDescription("Muc kho size lon cho don si")
                .description("Muc kho phuc vu don si")
                .origin("Ca Mau")
                .basePrice(new BigDecimal("450000"))
                .unit("kg")
                .minOrderQuantity(2)
                .stockQuantity(120)
                .status(ProductStatus.ACTIVE)
                .featured(true)
                .priceTiers(new LinkedHashSet<>())
                .build();
        product.getPriceTiers().add(PriceTier.builder()
                .id(41L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440054"))
                .product(product)
                .minQuantity(2)
                .maxQuantity(9)
                .unitPrice(new BigDecimal("450000"))
                .build());
        return product;
    }
}
