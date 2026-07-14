package com.marinelink.products;

import com.marinelink.common.api.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/products")
@RequiredArgsConstructor
public class ProductController {

    private final ProductService productService;

    @GetMapping("/categories")
    public ApiResponse<List<CategoryResponse>> listCategories() {
        return ApiResponse.ok(productService.listCategories());
    }

    @GetMapping
    public ApiResponse<List<ProductListItemResponse>> listProducts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(name = "q", required = false) String query,
            @RequestParam(required = false) UUID categoryId,
            @RequestParam(required = false) ProductStatus status,
            @RequestParam(required = false) Boolean featured,
            @RequestParam(defaultValue = "newest") String sort) {
        Page<ProductListItemResponse> products = productService.listProducts(
                page, size, query, categoryId, status, featured, sort);
        return ApiResponse.ok(products.getContent(), ApiResponse.PaginationMeta.of(products));
    }

    @GetMapping("/{id}")
    public ApiResponse<ProductDetailResponse> getProductDetail(@PathVariable("id") UUID productId) {
        return ApiResponse.ok(productService.getProductDetail(productId));
    }
}
