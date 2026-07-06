package com.marinelink.products;

import com.marinelink.common.exception.ConflictException;
import com.marinelink.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AdminProductService {

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;

    public Page<ProductListItemResponse> listProducts(
            int page,
            int size,
            String query,
            UUID categoryId,
            ProductStatus status,
            Boolean featured,
            String sort) {
        Pageable pageable = PageRequest.of(
                Math.max(page, 0),
                Math.max(1, Math.min(size, 100)),
                resolveSort(sort));

        Specification<Product> specification = (root, ignoredQuery, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            Join<Product, Category> category = root.join("category");
            Join<Category, Category> parentCategory = category.join("parent", JoinType.LEFT);

            predicates.add(cb.isNull(root.get("deletedAt")));

            if (query != null && !query.isBlank()) {
                String keyword = "%" + query.trim().toLowerCase(Locale.ROOT) + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(root.get("name")), keyword),
                        cb.like(cb.lower(root.get("slug")), keyword),
                        cb.like(cb.lower(root.get("origin")), keyword),
                        cb.like(cb.lower(root.get("shortDescription")), keyword),
                        cb.like(cb.lower(root.get("description")), keyword)));
            }
            if (categoryId != null) {
                predicates.add(cb.or(
                        cb.equal(category.get("publicId"), categoryId),
                        cb.equal(parentCategory.get("publicId"), categoryId)));
            }
            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }
            if (featured != null) {
                predicates.add(featured ? cb.isTrue(root.get("featured")) : cb.isFalse(root.get("featured")));
            }

            return cb.and(predicates.toArray(Predicate[]::new));
        };

        return productRepository.findAll(specification, pageable)
                .map(ProductListItemResponse::from);
    }

    public ProductDetailResponse getProductDetail(UUID productId) {
        Product product = productRepository.findDetailByPublicId(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy sản phẩm"));
        return ProductDetailResponse.from(product);
    }

    @Transactional
    public ProductDetailResponse createProduct(AdminProductRequest request) {
        ensureSlugAvailable(request.slug(), null);
        Product product = Product.builder()
                .publicId(UUID.randomUUID())
                .category(findCategory(request.categoryId()))
                .build();
        applyRequest(product, request);
        return ProductDetailResponse.from(productRepository.save(product));
    }

    @Transactional
    public ProductDetailResponse updateProduct(UUID productId, AdminProductRequest request) {
        Product product = productRepository.findDetailByPublicId(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy sản phẩm"));
        ensureSlugAvailable(request.slug(), productId);
        applyRequest(product, request);
        return ProductDetailResponse.from(productRepository.save(product));
    }

    @Transactional
    public void deleteProduct(UUID productId) {
        Product product = productRepository.findByPublicIdIncludingDeleted(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy sản phẩm"));

        product.setStatus(ProductStatus.DISABLED);
        if (product.getDeletedAt() == null) {
            product.setDeletedAt(Instant.now());
        }
        productRepository.save(product);
    }

    private void applyRequest(Product product, AdminProductRequest request) {
        validatePriceTiers(request.priceTiers());

        product.setCategory(findCategory(request.categoryId()));
        product.setName(request.name().trim());
        product.setSlug(request.slug().trim());
        product.setShortDescription(trimToNull(request.shortDescription()));
        product.setDescription(trimToNull(request.description()));
        product.setOrigin(trimToNull(request.origin()));
        product.setBasePrice(request.basePrice());
        product.setUnit(request.unit().trim());
        product.setMinOrderQuantity(request.minOrderQuantity());
        product.setStockQuantity(request.stockQuantity());
        product.setStatus(request.status());
        product.setFeatured(request.isFeatured());

        product.getPriceTiers().clear();
        for (AdminPriceTierRequest tierRequest : safeTiers(request.priceTiers())) {
            product.getPriceTiers().add(PriceTier.builder()
                    .publicId(UUID.randomUUID())
                    .product(product)
                    .minQuantity(tierRequest.minQuantity())
                    .maxQuantity(tierRequest.maxQuantity())
                    .unitPrice(tierRequest.unitPrice())
                    .build());
        }
    }

    private Category findCategory(UUID categoryId) {
        return categoryRepository.findActiveByPublicId(categoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy danh mục"));
    }

    private void ensureSlugAvailable(String slug, UUID excludedPublicId) {
        boolean exists = excludedPublicId == null
                ? productRepository.existsBySlugIgnoreCaseAndDeletedAtIsNull(slug.trim())
                : productRepository.existsActiveSlugExcluding(slug.trim(), excludedPublicId);
        if (exists) {
            throw new ConflictException("Slug sản phẩm đã tồn tại");
        }
    }

    private void validatePriceTiers(List<AdminPriceTierRequest> priceTiers) {
        List<AdminPriceTierRequest> tiers = safeTiers(priceTiers).stream()
                .sorted(Comparator.comparingInt(AdminPriceTierRequest::minQuantity))
                .toList();

        Integer previousMax = null;
        for (int index = 0; index < tiers.size(); index++) {
            AdminPriceTierRequest tier = tiers.get(index);
            if (tier.maxQuantity() != null && tier.maxQuantity() < tier.minQuantity()) {
                throw new ConflictException("Khoảng giá sỉ không hợp lệ");
            }
            if (previousMax != null && tier.minQuantity() <= previousMax) {
                throw new ConflictException("Khoảng giá sỉ bị trùng nhau");
            }
            if (previousMax == null && index > 0) {
                throw new ConflictException("Khoảng giá sỉ bị trùng nhau");
            }
            previousMax = tier.maxQuantity();
        }
    }

    private List<AdminPriceTierRequest> safeTiers(List<AdminPriceTierRequest> tiers) {
        return tiers == null ? List.of() : tiers;
    }

    private String trimToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private Sort resolveSort(String sort) {
        if (sort == null || sort.isBlank()) {
            return Sort.by(Sort.Order.desc("updatedAt"), Sort.Order.asc("name"));
        }

        return switch (sort.trim().toLowerCase(Locale.ROOT)) {
            case "price_asc" -> Sort.by(Sort.Order.asc("basePrice"), Sort.Order.asc("name"));
            case "price_desc" -> Sort.by(Sort.Order.desc("basePrice"), Sort.Order.asc("name"));
            case "name_asc" -> Sort.by(Sort.Order.asc("name"));
            case "name_desc" -> Sort.by(Sort.Order.desc("name"));
            case "stock_asc" -> Sort.by(Sort.Order.asc("stockQuantity"), Sort.Order.asc("name"));
            case "stock_desc" -> Sort.by(Sort.Order.desc("stockQuantity"), Sort.Order.asc("name"));
            case "newest" -> Sort.by(Sort.Order.desc("createdAt"));
            default -> Sort.by(Sort.Order.desc("updatedAt"), Sort.Order.asc("name"));
        };
    }
}
