package com.hidarahlab.manote.auth.dto;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(@NotBlank(message = "User ID atau email wajib diisi") String username,
		@NotBlank(message = "Password wajib diisi") String password) {
}
