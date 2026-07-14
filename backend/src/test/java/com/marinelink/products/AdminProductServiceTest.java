package com.marinelink.products;

import com.marinelink.common.exception.ConflictException;
import com.marinelink.common.exception.ResourceNotFoundException;
import jakarta.validation.Validation;
import jakarta.validation.ValidatorFactory;
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
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
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
    void createProductAssignsDefaultCategoryWhenCategoryIdNull() {
        Category defaultCategory = demoCategory();
        AdminProductRequest request = requestWithoutCategory("muc-kho-loai-1");
        when(productRepository.existsBySlugIgnoreCaseAndDeletedAtIsNull("muc-kho-loai-1")).thenReturn(false);
        when(categoryRepository.findFirstByActiveTrueOrderByDisplayOrderAscNameAsc())
                .thenReturn(Optional.of(defaultCategory));
        when(productRepository.save(any(Product.class))).thenAnswer(invocation -> invocation.getArgument(0));

        ProductDetailResponse result = adminProductService.createProduct(request);

        assertNotNull(result.id());
        ArgumentCaptor<Product> productCaptor = ArgumentCaptor.forClass(Product.class);
        verify(productRepository).save(productCaptor.capture());
        assertEquals(defaultCategory, productCaptor.getValue().getCategory());
        verify(categoryRepository).findFirstByActiveTrueOrderByDisplayOrderAscNameAsc();
        verify(categoryRepository, never()).findActiveByPublicId(any());
    }

    @Test
    void updateProductKeepsExistingCategoryWhenCategoryIdNull() {
        Product product = demoProduct();
        Category originalCategory = product.getCategory();
        AdminProductRequest request = requestWithoutCategory("muc-kho-cap-nhat");
        when(productRepository.findDetailByPublicId(product.getPublicId())).thenReturn(Optional.of(product));
        when(productRepository.existsActiveSlugExcluding("muc-kho-cap-nhat", product.getPublicId()))
                .thenReturn(false);
        when(productRepository.save(product)).thenReturn(product);

        ProductDetailResponse result = adminProductService.updateProduct(product.getPublicId(), request);

        assertEquals("muc-kho-cap-nhat", result.slug());
        assertEquals(originalCategory, product.getCategory());
        verify(categoryRepository, never()).findActiveByPublicId(any());
        verify(categoryRepository, never()).findFirstByActiveTrueOrderByDisplayOrderAscNameAsc();
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
                null,
                new BigDecimal("450000"),
                "kg",
                2,
                120,
                ProductStatus.ACTIVE,
                true,
                List.of(
                        new AdminPriceTierRequest(null, 2, 9, new BigDecimal("450000")),
                        new AdminPriceTierRequest(null, 9, null, new BigDecimal("420000"))));
        when(productRepository.existsBySlugIgnoreCaseAndDeletedAtIsNull("muc-kho-loai-1")).thenReturn(false);
        when(categoryRepository.findActiveByPublicId(category.getPublicId())).thenReturn(Optional.of(category));

        assertThrows(ConflictException.class, () -> adminProductService.createProduct(request));
    }

    @Test
    void updateProductKeepsExistingTierRowsWhenIdsAreSentBack() {
        Product product = demoProduct();
        PriceTier existingTier = product.getPriceTiers().iterator().next();
        Long existingRowId = existingTier.getId();
        UUID existingPublicId = existingTier.getPublicId();
        AdminProductRequest request = requestWithTiers(
                product.getCategory().getPublicId(),
                "muc-kho-loai-1",
                List.of(new AdminPriceTierRequest(existingPublicId, 3, 12, new BigDecimal("430000"))));
        stubUpdate(product);

        ProductDetailResponse result = adminProductService.updateProduct(product.getPublicId(), request);

        // Dòng cũ được cập nhật tại chỗ: giữ nguyên id (bigint) và public id.
        assertEquals(1, product.getPriceTiers().size());
        PriceTier tier = product.getPriceTiers().iterator().next();
        assertEquals(existingRowId, tier.getId());
        assertEquals(existingPublicId, tier.getPublicId());
        assertEquals(3, tier.getMinQuantity());
        assertEquals(12, tier.getMaxQuantity());
        assertEquals(new BigDecimal("430000"), tier.getUnitPrice());
        assertEquals(1, result.priceTiers().size());
        assertEquals(existingPublicId, result.priceTiers().getFirst().id());
    }

    @Test
    void updateProductAddsNewTiersWithoutTouchingExistingOnes() {
        Product product = demoProduct();
        PriceTier existingTier = product.getPriceTiers().iterator().next();
        UUID existingPublicId = existingTier.getPublicId();
        AdminProductRequest request = requestWithTiers(
                product.getCategory().getPublicId(),
                "muc-kho-loai-1",
                List.of(
                        new AdminPriceTierRequest(existingPublicId, 2, 9, new BigDecimal("450000")),
                        new AdminPriceTierRequest(null, 10, null, new BigDecimal("420000"))));
        stubUpdate(product);

        ProductDetailResponse result = adminProductService.updateProduct(product.getPublicId(), request);

        assertEquals(2, product.getPriceTiers().size());
        assertTrue(product.getPriceTiers().stream()
                .anyMatch(tier -> existingPublicId.equals(tier.getPublicId()) && tier.getId() != null));
        PriceTier added = product.getPriceTiers().stream()
                .filter(tier -> !existingPublicId.equals(tier.getPublicId()))
                .findFirst()
                .orElseThrow();
        assertNull(added.getId());
        assertNotNull(added.getPublicId());
        assertEquals(product, added.getProduct());
        assertEquals(2, result.priceTiers().size());
    }

    @Test
    void updateProductRemovesOnlyTiersAbsentFromRequest() {
        Product product = demoProduct();
        UUID keptPublicId = product.getPriceTiers().iterator().next().getPublicId();
        UUID droppedPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440055");
        product.getPriceTiers().add(PriceTier.builder()
                .id(42L)
                .publicId(droppedPublicId)
                .product(product)
                .minQuantity(10)
                .maxQuantity(null)
                .unitPrice(new BigDecimal("420000"))
                .build());
        AdminProductRequest request = requestWithTiers(
                product.getCategory().getPublicId(),
                "muc-kho-loai-1",
                List.of(new AdminPriceTierRequest(keptPublicId, 2, 9, new BigDecimal("450000"))));
        stubUpdate(product);

        adminProductService.updateProduct(product.getPublicId(), request);

        assertEquals(1, product.getPriceTiers().size());
        assertEquals(keptPublicId, product.getPriceTiers().iterator().next().getPublicId());
    }

    @Test
    void updateProductSucceedsWhenOptionalFieldsAreBlank() {
        Product product = demoProduct();
        UUID existingPublicId = product.getPriceTiers().iterator().next().getPublicId();
        AdminProductRequest request = new AdminProductRequest(
                null,
                "Muc kho loai 1",
                "muc-kho-loai-1",
                "   ",
                "",
                "  ",
                "",
                new BigDecimal("450000"),
                "kg",
                2,
                120,
                ProductStatus.ACTIVE,
                true,
                List.of(new AdminPriceTierRequest(existingPublicId, 2, 9, new BigDecimal("450000"))));
        when(productRepository.findDetailByPublicId(product.getPublicId())).thenReturn(Optional.of(product));
        when(productRepository.existsActiveSlugExcluding("muc-kho-loai-1", product.getPublicId())).thenReturn(false);
        when(productRepository.save(product)).thenReturn(product);

        ProductDetailResponse result = adminProductService.updateProduct(product.getPublicId(), request);

        // Trường tuỳ chọn để trống -> lưu null, không chặn cập nhật.
        assertNull(result.shortDescription());
        assertNull(result.description());
        assertNull(result.origin());
        // imageUrl để trống -> giữ nguyên ảnh cũ thay vì xoá mất.
        assertEquals("https://cdn.marinelink.vn/muc-kho.png", result.imageUrl());
        assertEquals(1, result.priceTiers().size());
        verify(productRepository).save(product);
    }

    @Test
    void adminProductRequestAcceptsBlankOptionalFields() {
        try (ValidatorFactory factory = Validation.buildDefaultValidatorFactory()) {
            AdminProductRequest request = new AdminProductRequest(
                    null,
                    "Muc kho loai 1",
                    "muc-kho-loai-1",
                    "",
                    "",
                    "",
                    "",
                    new BigDecimal("450000"),
                    "kg",
                    2,
                    120,
                    ProductStatus.ACTIVE,
                    false,
                    List.of());

            assertTrue(factory.getValidator().validate(request).isEmpty());
        }
    }

    private void stubUpdate(Product product) {
        when(productRepository.findDetailByPublicId(product.getPublicId())).thenReturn(Optional.of(product));
        when(categoryRepository.findActiveByPublicId(product.getCategory().getPublicId()))
                .thenReturn(Optional.of(product.getCategory()));
        when(productRepository.existsActiveSlugExcluding(anyString(), eq(product.getPublicId()))).thenReturn(false);
        when(productRepository.save(product)).thenReturn(product);
    }

    private AdminProductRequest requestWithTiers(UUID categoryId, String slug, List<AdminPriceTierRequest> tiers) {
        return new AdminProductRequest(
                categoryId,
                "Muc kho loai 1",
                slug,
                "Muc kho size lon cho don si",
                "Muc kho phuc vu don si",
                "Ca Mau",
                null,
                new BigDecimal("450000"),
                "kg",
                2,
                120,
                ProductStatus.ACTIVE,
                true,
                tiers);
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
                null,
                new BigDecimal("450000"),
                "kg",
                2,
                120,
                ProductStatus.ACTIVE,
                true,
                List.of(
                        new AdminPriceTierRequest(null, 2, 9, new BigDecimal("450000")),
                        new AdminPriceTierRequest(null, 10, null, new BigDecimal("420000"))));
    }

    private AdminProductRequest requestWithoutCategory(String slug) {
        return new AdminProductRequest(
                null,
                "Muc kho loai 1",
                slug,
                "Muc kho size lon cho don si",
                "Muc kho phuc vu don si",
                "Ca Mau",
                null,
                new BigDecimal("450000"),
                "kg",
                2,
                120,
                ProductStatus.ACTIVE,
                true,
                List.of(
                        new AdminPriceTierRequest(null, 2, 9, new BigDecimal("450000")),
                        new AdminPriceTierRequest(null, 10, null, new BigDecimal("420000"))));
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
                .imageUrl("https://cdn.marinelink.vn/muc-kho.png")
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
