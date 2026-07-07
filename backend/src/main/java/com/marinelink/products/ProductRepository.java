package com.marinelink.products;

import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface ProductRepository extends JpaRepository<Product, Long>, JpaSpecificationExecutor<Product> {

    @Override
    @EntityGraph(attributePaths = {"category", "category.parent"})
    org.springframework.data.domain.Page<Product> findAll(Specification<Product> spec,
                                                         org.springframework.data.domain.Pageable pageable);

    @EntityGraph(attributePaths = {"category", "category.parent", "images", "priceTiers"})
    @Query("select p from Product p where p.publicId = :publicId and p.deletedAt is null")
    Optional<Product> findDetailByPublicId(@Param("publicId") UUID publicId);

    @Query("select count(p) from Product p where p.deletedAt is null "
            + "and p.status = com.marinelink.products.ProductStatus.ACTIVE "
            + "and p.stockQuantity < :threshold")
    long countLowStock(@Param("threshold") int threshold);

    @Query("select p from Product p where p.publicId = :publicId")
    Optional<Product> findByPublicIdIncludingDeleted(@Param("publicId") UUID publicId);

    boolean existsBySlugIgnoreCaseAndDeletedAtIsNull(String slug);

    @Query("select case when count(p) > 0 then true else false end from Product p "
            + "where lower(p.slug) = lower(:slug) and p.deletedAt is null "
            + "and p.publicId <> :excludedPublicId")
    boolean existsActiveSlugExcluding(
            @Param("slug") String slug,
            @Param("excludedPublicId") UUID excludedPublicId);
}
