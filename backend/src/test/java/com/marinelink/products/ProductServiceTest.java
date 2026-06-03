package com.marinelink.products;

import com.marinelink.common.exception.ResourceNotFoundException;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ProductServiceTest {

    private final ProductRepository productRepository = mock(ProductRepository.class);
    private final ProductService productService = new ProductService(productRepository);

    @Test
    void listProductsMapsPageAndUsesRequestedSort() {
        Product product = demoProduct();
        when(productRepository.findAll(any(Specification.class), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(product), PageRequest.of(0, 20), 1));

        Page<ProductListItemResponse> result = productService.listProducts(
                0,
                20,
                "muc",
                product.getCategory().getPublicId(),
                ProductStatus.ACTIVE,
                true,
                "price_asc");

        assertEquals(1, result.getTotalElements());
        assertEquals("Muc kho loai 1", result.getContent().getFirst().name());
        assertEquals("Muc kho", result.getContent().getFirst().category().name());
        verify(productRepository).findAll(
                any(Specification.class),
                argThat((Pageable pageable) ->
                        pageable.getSort().toString().contains("basePrice: ASC")));
    }

    @Test
    void getProductDetailReturnsImagesAndPriceTiers() {
        Product product = demoProduct();
        when(productRepository.findDetailByPublicId(product.getPublicId()))
                .thenReturn(Optional.of(product));

        ProductDetailResponse result = productService.getProductDetail(product.getPublicId());

        assertEquals("Muc kho loai 1", result.name());
        assertEquals(1, result.images().size());
        assertEquals(2, result.priceTiers().size());
    }

    @Test
    void getProductDetailThrowsWhenProductMissing() {
        UUID productId = UUID.fromString("550e8400-e29b-41d4-a716-446655440099");
        when(productRepository.findDetailByPublicId(productId)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> productService.getProductDetail(productId));
    }

    private Product demoProduct() {
        Category category = Category.builder()
                .id(11L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440051"))
                .name("Muc kho")
                .slug("muc-kho")
                .build();

        Product product = Product.builder()
                .id(21L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440052"))
                .category(category)
                .name("Muc kho loai 1")
                .slug("muc-kho-loai-1")
                .description("Muc kho phuc vu don si")
                .origin("Ca Mau")
                .basePrice(new BigDecimal("450000"))
                .unit("kg")
                .minOrderQuantity(2)
                .stockQuantity(120)
                .status(ProductStatus.ACTIVE)
                .featured(true)
                .build();

        ProductImage image = ProductImage.builder()
                .id(31L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440053"))
                .product(product)
                .imageUrl("https://example.com/muc-kho.png")
                .altText("Muc kho loai 1")
                .displayOrder(0)
                .build();

        PriceTier firstTier = PriceTier.builder()
                .id(41L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440054"))
                .product(product)
                .minQuantity(2)
                .maxQuantity(9)
                .unitPrice(new BigDecimal("450000"))
                .build();

        PriceTier secondTier = PriceTier.builder()
                .id(42L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440055"))
                .product(product)
                .minQuantity(10)
                .maxQuantity(null)
                .unitPrice(new BigDecimal("420000"))
                .build();

        product.setImages(Set.of(image));
        product.setPriceTiers(Set.of(firstTier, secondTier));
        return product;
    }
}
