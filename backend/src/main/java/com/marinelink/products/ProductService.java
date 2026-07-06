package com.marinelink.products;

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
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ProductService {

    private final ProductRepository productRepository;

    @Transactional(readOnly = true)
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
            predicates.add(cb.isNull(root.get("deletedAt")));
            predicates.add(cb.isTrue(root.get("category").get("active")));

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
                predicates.add(cb.equal(root.get("category").get("publicId"), categoryId));
            }

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            } else {
                predicates.add(cb.notEqual(root.get("status"), ProductStatus.DISABLED));
            }

            if (featured != null) {
                predicates.add(featured
                        ? cb.isTrue(root.get("featured"))
                        : cb.isFalse(root.get("featured")));
            }

            return cb.and(predicates.toArray(Predicate[]::new));
        };

        return productRepository.findAll(specification, pageable)
                .map(ProductListItemResponse::from);
    }

    @Transactional(readOnly = true)
    public ProductDetailResponse getProductDetail(UUID productId) {
        Product product = productRepository.findDetailByPublicId(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay san pham"));
        return ProductDetailResponse.from(product);
    }

    private Sort resolveSort(String sort) {
        if (sort == null || sort.isBlank()) {
            return Sort.by(
                    Sort.Order.desc("featured"),
                    Sort.Order.desc("updatedAt"));
        }

        return switch (sort.trim().toLowerCase(Locale.ROOT)) {
            case "price_asc" -> Sort.by(Sort.Order.asc("basePrice"), Sort.Order.asc("name"));
            case "price_desc" -> Sort.by(Sort.Order.desc("basePrice"), Sort.Order.asc("name"));
            case "name_asc" -> Sort.by(Sort.Order.asc("name"));
            case "name_desc" -> Sort.by(Sort.Order.desc("name"));
            case "newest" -> Sort.by(Sort.Order.desc("createdAt"));
            default -> Sort.by(
                    Sort.Order.desc("featured"),
                    Sort.Order.desc("updatedAt"));
        };
    }
}
