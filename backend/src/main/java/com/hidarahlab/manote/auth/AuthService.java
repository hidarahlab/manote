package com.hidarahlab.manote.auth;

import com.hidarahlab.manote.auth.dto.LoginRequest;
import com.hidarahlab.manote.auth.dto.LoginResponse;
import com.hidarahlab.manote.auth.dto.UserResponse;
import com.hidarahlab.manote.common.ApiException;
import com.hidarahlab.manote.common.ErrorCode;
import com.hidarahlab.manote.user.User;
import com.hidarahlab.manote.user.UserRepository;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class AuthService {

	private final UserRepository userRepository;

	private final PasswordEncoder passwordEncoder;

	private final JwtService jwtService;

	private final LoginAttemptService loginAttemptService;

	public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtService jwtService,
			LoginAttemptService loginAttemptService) {
		this.userRepository = userRepository;
		this.passwordEncoder = passwordEncoder;
		this.jwtService = jwtService;
		this.loginAttemptService = loginAttemptService;
	}

	public LoginResponse login(LoginRequest request) {
		String username = request.username().trim();
		loginAttemptService.assertNotLocked(username);

		User user = userRepository.findByUserIdIgnoreCaseOrEmailIgnoreCase(username, username)
			.filter((found) -> passwordEncoder.matches(request.password(), found.getPasswordHash()))
			.orElse(null);
		if (user == null) {
			loginAttemptService.recordFailure(username);
			throw new ApiException(ErrorCode.INVALID_CREDENTIALS);
		}

		loginAttemptService.reset(username);
		return new LoginResponse(jwtService.createAccessToken(user), jwtService.expiresInSeconds(),
				UserResponse.from(user));
	}

	public UserResponse currentUser(String userId) {
		return userRepository.findByUserId(userId)
			.map(UserResponse::from)
			.orElseThrow(() -> new ApiException(ErrorCode.TOKEN_INVALID));
	}

}
