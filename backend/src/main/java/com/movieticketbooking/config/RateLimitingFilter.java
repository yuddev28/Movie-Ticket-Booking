package com.movieticketbooking.config;

import java.io.IOException;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import tools.jackson.databind.ObjectMapper;
import com.movieticketbooking.response.ApiResponse;
import com.movieticketbooking.service.RedisService;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;

@Component 
@RequiredArgsConstructor
public class RateLimitingFilter extends OncePerRequestFilter {
    @Value("${rate.limit.requests:20}")
    private int DEFAULT_LIMIT; // default limit for requests per minute
    @Value("${rate.limit.requests.auth:10}")
    private int AUTH_LIMIT; // limit for authenticated users per minute
    @Value("${rate.limit.window:60}")
    private int WINDOW_SECONDS; // time window in seconds

    private final RedisService redisService;
    private final ObjectMapper objectMapper;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String path = request.getRequestURI();

        // skip rate limiting for swagger docs
        if (path.startsWith("/v3/api-docs") || path.startsWith("/swagger-ui")) {
            filterChain.doFilter(request, response);
            return;
        }
        
        // if the request is for auth endpoints, apply auth limit, otherwise apply default limit
        int limit = DEFAULT_LIMIT;
        if(path.startsWith("/api/auth")) {
            limit = AUTH_LIMIT;
        }

        String clientIp = request.getRemoteAddr();
        String key = "rate_limit:" + clientIp;

        Long requestCount = redisService.increment(key, 1);
        if (requestCount != null && requestCount == 1) {
            redisService.expire(key, WINDOW_SECONDS, java.util.concurrent.TimeUnit.SECONDS);
        }
        if (requestCount != null && requestCount > limit) {
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.setCharacterEncoding("UTF-8");
            ApiResponse apiResponse = new ApiResponse("Too Many Requests. Please try again later.", null);
            response.getWriter().write(objectMapper.writeValueAsString(apiResponse));
            return;
        }
        filterChain.doFilter(request, response);
    }

}
