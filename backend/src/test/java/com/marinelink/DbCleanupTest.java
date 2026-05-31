package com.marinelink;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

@SpringBootTest(properties = {
    "spring.flyway.enabled=false",
    "spring.jpa.hibernate.ddl-auto=none"
})
public class DbCleanupTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    public void cleanupFlywayHistory() {
        System.out.println("Dropping flyway_schema_history table if exists...");
        jdbcTemplate.execute("DROP TABLE IF EXISTS flyway_schema_history CASCADE");
        System.out.println("Successfully dropped flyway_schema_history!");
    }
}
