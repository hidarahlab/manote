package com.hidarahlab.manote.auth.dto;

public record LoginResponse(String accessToken, long expiresIn, UserResponse user) {
}
