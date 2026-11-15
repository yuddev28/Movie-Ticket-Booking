package com.movieticketbooking;

import io.github.cdimascio.dotenv.Dotenv;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.movieticketbooking.service.*;
import com.movieticketbooking.request.user.CreateUserRequest;
import com.movieticketbooking.model.Role;

@SpringBootApplication
@EnableCaching
@EnableScheduling
public class MovieTicketBookingApplication {

	public static void main(String[] args) {
		try {
			Dotenv dotenv = Dotenv.configure().ignoreIfMissing().load();
			dotenv.entries().forEach(entry -> System.setProperty(entry.getKey(), entry.getValue()));
		} catch (Exception e) {
			// Ignore if .env is missing in production environments
		}
		SpringApplication.run(MovieTicketBookingApplication.class, args);
	}

	@Bean
	public CommandLineRunner initAdminUser(
			com.movieticketbooking.repository.UserRepository userRepository,
			org.springframework.security.crypto.password.PasswordEncoder passwordEncoder) {
		return args -> {
			String adminEmail = "yudcoder@gmail.com";
			String rawPassword = "yudcoder";
			if(!userRepository.existsByEmail(adminEmail)) {
				com.movieticketbooking.model.User user = userRepository.findByEmail(adminEmail)
					.orElse(new com.movieticketbooking.model.User());
				user.setName("Yudcoder");
				user.setEmail(adminEmail);
				user.setPassword(passwordEncoder.encode(rawPassword)); // Luôn encode BCrypt chuẩn
				user.setPhoneNumber("0123456789");
				user.setRole(com.movieticketbooking.model.Role.ADMIN);
			userRepository.save(user);
			} else {
				System.out.println("Hello world");
			}
			
		};
	}

}
