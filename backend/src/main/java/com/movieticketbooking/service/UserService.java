package com.movieticketbooking.service;

import com.movieticketbooking.model.User;
import com.movieticketbooking.request.user.CreateUserRequest;
import com.movieticketbooking.request.user.UpdateInfoUserRequest;
import com.movieticketbooking.response.UserResponse;

public interface UserService {
    User findUserById(int id);
    boolean existsByEmail(String email);
    UserResponse getUserById(int id);
    UserResponse addUser(CreateUserRequest createUserRequest);
    UserResponse updateUser(UpdateInfoUserRequest updateInfoUserRequest);
}
