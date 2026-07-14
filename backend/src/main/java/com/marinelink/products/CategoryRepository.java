package com.marinelink.products;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CategoryRepository extends JpaRepository<Category, Long> {

    @Query("select c from Category c where c.publicId = :publicId and c.active = true")
    Optional<Category> findActiveByPublicId(@Param("publicId") UUID publicId);

    Optional<Category> findFirstByActiveTrueOrderByDisplayOrderAscNameAsc();

    @Query("""
            select c from Category c
            left join fetch c.parent
            where c.active = true
            order by c.displayOrder asc, c.name asc
            """)
    List<Category> findAllActiveOrdered();
}
