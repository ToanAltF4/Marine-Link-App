package com.marinelink;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableScheduling
@SpringBootApplication
public class MarineLinkApplication {

    public static void main(String[] args) {
        SpringApplication.run(MarineLinkApplication.class, args);
    }
}
