package com.hidarahlab.manote.auth.dto;

import com.hidarahlab.manote.user.User;
import com.hidarahlab.manote.user.UserType;

public record UserResponse(String userId, String email, String fullName, UserType userType) {

	public static UserResponse from(User user) {
		return new UserResponse(user.getUserId(), user.getEmail(), user.getFullName(), user.getUserType());
	}

}
