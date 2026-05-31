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
    @EntityGraph(attributePaths = {"category"})
    org.springframework.data.domain.Page<Product> findAll(Specification<Product> spec,
                                                         org.springframework.data.domain.Pageable pageable);

    @EntityGraph(attributePaths = {"category", "images", "priceTiers"})
    @Query("select p from Product p where p.publicId = :publicId and p.deletedAt is null")
    Optional<Product> findDetailByPublicId(@Param("publicId") UUID publicId);
}
