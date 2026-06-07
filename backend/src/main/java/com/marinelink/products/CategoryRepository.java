package com.marinelink.products;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface CategoryRepository extends JpaRepository<Category, Long> {

    @Query("select c from Category c where c.publicId = :publicId and c.active = true")
    Optional<Category> findActiveByPublicId(@Param("publicId") UUID publicId);
}
