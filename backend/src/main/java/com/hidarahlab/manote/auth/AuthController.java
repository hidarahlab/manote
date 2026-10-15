package com.hidarahlab.manote.auth;

import com.hidarahlab.manote.auth.dto.LoginRequest;
import com.hidarahlab.manote.auth.dto.LoginResponse;
import com.hidarahlab.manote.auth.dto.UserResponse;
import com.hidarahlab.manote.common.ApiResponse;
import jakarta.validation.Valid;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

	private final AuthService authService;

	public AuthController(AuthService authService) {
		this.authService = authService;
	}

	@PostMapping("/login")
	public ApiResponse<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
		return ApiResponse.ok(authService.login(request));
	}

	@GetMapping("/me")
	public ApiResponse<UserResponse> me(@AuthenticationPrincipal Jwt jwt) {
		return ApiResponse.ok(authService.currentUser(jwt.getSubject()));
	}

}
